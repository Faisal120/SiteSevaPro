"""Authenticated, workspace-grounded AI assistant conversations."""
from __future__ import annotations

import json
import logging
import os
from typing import Any

from fastapi import HTTPException
from openai import AsyncOpenAI

from core import db, new_id, now_iso

logger = logging.getLogger("siteseva.ai")


class AiAssistantService:
    async def conversation(self, user: dict) -> dict:
        messages = await (
            db.ai_conversations.find(
                {"user_id": user["id"]},
                {"_id": 0},
            )
            .sort("created_at", -1)
            .limit(50)
            .to_list(50)
        )
        messages.reverse()
        return {"messages": messages}

    async def send_message(self, text: str, user: dict) -> dict:
        prompt = text.strip()
        if not prompt:
            raise HTTPException(422, "Message is required")
        if len(prompt) > 2000:
            raise HTTPException(422, "Message must be 2000 characters or less")

        user_message = self._message(user, "USER", prompt)
        await db.ai_conversations.insert_one(dict(user_message))
        history = await (
            db.ai_conversations.find(
                {"user_id": user["id"]},
                {"_id": 0, "role": 1, "content": 1},
            )
            .sort("created_at", -1)
            .limit(12)
            .to_list(12)
        )
        history.reverse()
        context = await self._workspace_context(user)
        answer = await self._complete(
            user=user,
            context=context,
            history=history,
        )
        assistant_message = self._message(user, "ASSISTANT", answer)
        await db.ai_conversations.insert_one(dict(assistant_message))
        return {"message": assistant_message}

    async def generate_insight(
        self,
        kind: str,
        requested_context: dict[str, Any],
        user: dict,
    ) -> str:
        workspace = await self._workspace_context(user)
        instructions = {
            "material_estimate": "Estimate likely material quantities and state assumptions.",
            "progress_summary": "Summarize progress, blockers, and a practical seven-day plan.",
            "delay_prediction": "Identify the top delay risks, likelihood, and mitigation.",
            "expense_analysis": "Analyze cash flow and give concrete cost-control actions.",
        }
        request = instructions.get(kind, instructions["progress_summary"])
        return await self._complete(
            user=user,
            context={
                "workspace": workspace,
                "request_context": requested_context,
            },
            history=[{"role": "USER", "content": request}],
        )

    async def _complete(
        self,
        *,
        user: dict,
        context: dict[str, Any],
        history: list[dict],
    ) -> str:
        api_key = os.getenv("OPENAI_API_KEY", "").strip()
        if not api_key:
            raise HTTPException(503, "AI provider is not configured")
        model = os.getenv("OPENAI_CHAT_MODEL", "gpt-4o-mini").strip()
        system = (
            "You are SiteSeva AI, a concise construction operations assistant. "
            "Use only the authenticated workspace context supplied below. Never "
            "invent project facts, approvals, measurements, costs, or compliance "
            "claims. Clearly label assumptions and recommend qualified architects "
            "or engineers for structural decisions. Respond in the user's language.\n\n"
            f"User role: {user.get('role')}\n"
            f"Workspace context: {json.dumps(context, default=str)}"
        )
        messages = [{"role": "system", "content": system}]
        for item in history:
            role = "assistant" if str(item.get("role", "")).upper() == "ASSISTANT" else "user"
            content = str(item.get("content") or "").strip()
            if content:
                messages.append({"role": role, "content": content})
        try:
            response = await AsyncOpenAI(api_key=api_key, timeout=60).chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.2,
                max_tokens=900,
            )
            answer = (response.choices[0].message.content or "").strip()
            if not answer:
                raise ValueError("Empty AI response")
            return answer
        except HTTPException:
            raise
        except Exception as exc:
            logger.exception("AI assistant request failed")
            raise HTTPException(502, "AI assistant could not complete the request") from exc

    async def _workspace_context(self, user: dict) -> dict[str, Any]:
        site_query: dict[str, Any] = {}
        company_id = user.get("company_id")
        if user.get("role") != "SUPER_ADMIN":
            site_query["company_id"] = company_id
        if user.get("role") == "SUPERVISOR":
            site_query["id"] = {"$in": user.get("site_ids", [])}
        elif user.get("role") == "CLIENT":
            site_query["$or"] = [
                {"client_id": user["id"]},
                {"client_email": user.get("email")},
            ]
        sites = await db.sites.find(
            site_query,
            {
                "_id": 0,
                "id": 1,
                "name": 1,
                "status": 1,
                "progress": 1,
                "budget": 1,
                "start_date": 1,
                "end_date": 1,
            },
        ).limit(30).to_list(30)
        site_ids = [item["id"] for item in sites if item.get("id")]
        scoped = {"site_id": {"$in": site_ids}}
        materials = await db.materials.find(
            scoped,
            {"_id": 0, "name": 1, "stock": 1, "min_stock": 1, "unit": 1},
        ).limit(100).to_list(100)
        low_stock = [
            item
            for item in materials
            if float(item.get("stock") or 0) <= float(item.get("min_stock") or 0)
        ][:20]
        payments = await db.payments.find(
            scoped,
            {"_id": 0, "type": 1, "amount": 1, "date": 1},
        ).sort("date", -1).limit(100).to_list(100)
        reports = await db.reports.find(
            scoped,
            {"_id": 0, "title": 1, "summary": 1, "date": 1, "status": 1},
        ).sort("date", -1).limit(10).to_list(10)
        return {
            "sites": sites,
            "site_count": len(sites),
            "low_stock": low_stock,
            "recent_reports": reports,
            "recent_payment_total": round(
                sum(float(item.get("amount") or 0) for item in payments),
                2,
            ),
        }

    @staticmethod
    def _message(user: dict, role: str, content: str) -> dict:
        return {
            "id": new_id(),
            "user_id": user["id"],
            "company_id": user.get("company_id"),
            "role": role,
            "content": content,
            "created_at": now_iso(),
        }


ai_assistant_service = AiAssistantService()
