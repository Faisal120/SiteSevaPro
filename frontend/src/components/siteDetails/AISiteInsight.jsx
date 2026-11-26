import { Sparkles } from "lucide-react";

export default function AISiteInsights({ insights = [] }) {
  return <div className="rounded-3xl bg-gradient-to-br from-slate-900 via-blue-900 to-blue-700 text-white shadow-xl"><div className="border-b border-white/10 p-6"><div className="flex items-center gap-3"><Sparkles className="text-cyan-300" /><div><h2 className="text-xl font-bold">AI Site Insights</h2><p className="mt-1 text-sm text-blue-100">Generated only from current site data.</p></div></div></div><div className="space-y-4 p-6">{insights.length ? insights.map((item, index) => <div key={item.id || `${item.title}-${index}`} className="rounded-2xl bg-white/10 p-5"><h3 className="font-semibold">{item.title || "AI insight"}</h3><p className="mt-1 text-sm text-blue-100">{item.message || item.description}</p></div>) : <p className="rounded-2xl bg-white/10 p-5 text-sm text-blue-100">No generated insights are available for this site yet.</p>}</div></div>;
}
