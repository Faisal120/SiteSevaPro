import React from "react";
import { Bot, RefreshCcw, Send, Sparkles } from "lucide-react";
import { api } from "@/lib/api";

const suggestedPrompts = ["Summarise the project status and current risks.", "Which materials need attention?", "Suggest a practical seven-day execution plan.", "Summarise recent costs and payments."];

export default function AITab({ insights = [], actions = {} }) {
  const [messages, setMessages] = React.useState([]);
  const [question, setQuestion] = React.useState("");
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState("");
  const loadConversation = React.useCallback(async () => {
    setError("");
    try { const { data } = await api.get("/ai-assistant/conversation"); setMessages(data.messages || []); }
    catch (requestError) { setError(requestError?.response?.data?.detail || "AI Assistant is unavailable right now."); }
  }, []);
  React.useEffect(() => { loadConversation(); }, [loadConversation]);
  const send = async (message = question) => {
    const text = message.trim(); if (!text || loading) return;
    setLoading(true); setError("");
    try { const { data } = await api.post("/ai-assistant/messages", { message: text }); setMessages((current) => [...current, { id: `local-${Date.now()}`, role: "USER", content: text }, data.message]); setQuestion(""); }
    catch (requestError) { setError(requestError?.response?.data?.detail || "AI Assistant could not complete this request."); }
    finally { setLoading(false); }
  };
  return <div className="space-y-6">
    <div className="rounded-3xl bg-gradient-to-r from-slate-900 via-blue-900 to-blue-700 p-8 text-white shadow-xl"><div className="flex flex-wrap items-center justify-between gap-4"><div><div className="flex items-center gap-3"><Sparkles className="text-cyan-300" /><h2 className="text-3xl font-bold">AI Construction Command Center</h2></div><p className="mt-3 text-blue-100">Workspace-grounded guidance based on your authorised project data.</p></div><button type="button" onClick={() => { actions.refreshAI?.(); loadConversation(); }} className="flex h-11 items-center gap-2 rounded-xl bg-white px-5 text-slate-900"><RefreshCcw size={18} /> Refresh</button></div></div>
    <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">{insights.length ? insights.map((item, index) => <div key={item.id || `${item.title}-${index}`} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm"><Sparkles className="text-blue-500" size={20} /><h3 className="mt-5 text-lg font-bold">{item.title || "AI insight"}</h3><p className="mt-3 text-slate-500">{item.description || item.message}</p></div>) : <div className="rounded-3xl border border-dashed border-slate-300 bg-slate-50 p-6 text-sm text-slate-600 xl:col-span-3">No generated insights yet. Ask the assistant a question or use the project AI action when available.</div>}</div>
    <div className="rounded-3xl border border-slate-200 bg-white shadow-sm"><div className="flex items-center gap-3 border-b p-6"><Bot className="text-blue-600" /><div><h2 className="text-xl font-bold">Construction AI Assistant</h2><p className="text-slate-500">Answers use authorised workspace data. Verify engineering decisions with a qualified professional.</p></div></div><div className="space-y-3 p-6"><div className="h-80 space-y-3 overflow-auto rounded-2xl bg-slate-50 p-4">{messages.length ? messages.map((message) => <div key={message.id} className={`max-w-[85%] rounded-2xl px-4 py-3 ${message.role === "USER" ? "ml-auto bg-blue-600 text-white" : "bg-white text-slate-800 shadow-sm"}`}>{message.content}</div>) : <p className="text-sm text-slate-500">Start a conversation about this workspace.</p>}</div>{error && <p className="text-sm text-red-600">{error}</p>}<div className="flex gap-3"><input value={question} onChange={(event) => setQuestion(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter") send(); }} placeholder="Ask about labour, materials, delays or costs…" className="h-12 flex-1 rounded-xl border px-4" /><button type="button" onClick={() => send()} disabled={loading} className="h-12 rounded-xl bg-blue-600 px-6 text-white disabled:opacity-50"><Send /></button></div></div></div>
    <div className="rounded-3xl border border-slate-200 bg-white p-6"><h2 className="mb-5 font-bold">Suggested questions</h2><div className="flex flex-wrap gap-3">{suggestedPrompts.map((prompt) => <button type="button" key={prompt} onClick={() => send(prompt)} disabled={loading} className="rounded-full border px-4 py-2 hover:bg-blue-50 disabled:opacity-50">{prompt}</button>)}</div></div>
  </div>;
}
