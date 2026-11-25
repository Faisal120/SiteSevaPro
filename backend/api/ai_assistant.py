from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from core import get_current_user
from services.ai_assistant_service import ai_assistant_service
from services.rate_limit import rate_limit

router = APIRouter(prefix="/api/ai-assistant", tags=["AI Assistant"])


class AssistantMessageIn(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


@router.get("/conversation")
async def get_conversation(user=Depends(get_current_user)):
    return await ai_assistant_service.conversation(user)


@router.post("/messages")
async def send_message(
    body: AssistantMessageIn,
    user=Depends(get_current_user),
    _: None = Depends(rate_limit("ai-assistant", 20, 3600)),
):
    return await ai_assistant_service.send_message(body.message, user)
