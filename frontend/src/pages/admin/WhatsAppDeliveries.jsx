import React from "react";
import { AlertTriangle, CheckCircle2, MessageCircle, RefreshCw, Settings2 } from "lucide-react";
import { toast } from "sonner";

import { api } from "@/lib/api";
import { fmtDate } from "@/lib/constants";


const statusStyle = {
  READ: "bg-emerald-500/15 text-emerald-300",
  DELIVERED: "bg-emerald-500/15 text-emerald-300",
  SENT: "bg-blue-500/15 text-blue-300",
  ACCEPTED: "bg-blue-500/15 text-blue-300",
  PENDING: "bg-amber-500/15 text-amber-300",
  FAILED: "bg-red-500/15 text-red-300",
  NOT_CONFIGURED: "bg-red-500/15 text-red-300",
  NOT_SENT: "bg-amber-500/15 text-amber-300",
  RATE_LIMITED: "bg-amber-500/15 text-amber-300",
  NO_PHONE: "bg-red-500/15 text-red-300",
  INVALID_PHONE: "bg-red-500/15 text-red-300",
};

export default function WhatsAppDeliveries() {
  const [config, setConfig] = React.useState(null);
  const [deliveries, setDeliveries] = React.useState([]);
  const [status, setStatus] = React.useState("");
  const [loading, setLoading] = React.useState(true);
  const load = React.useCallback(async () => {
    setLoading(true);
    try {
      const [configResponse, deliveryResponse] = await Promise.all([
        api.get("/admin/whatsapp/status"),
        api.get("/admin/whatsapp/deliveries", { params: status ? { status } : {} }),
      ]);
      setConfig(configResponse.data);
      setDeliveries(deliveryResponse.data || []);
    } catch (error) {
      toast.error(error?.response?.data?.detail || "Unable to load WhatsApp operations");
    } finally { setLoading(false); }
  }, [status]);
  React.useEffect(() => { load(); }, [load]);

  return <div className="space-y-6 ss-fade-in">
    <div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-xs font-semibold uppercase tracking-[.18em] text-emerald-400">Messaging operations</p><h1 className="mt-1 font-display text-3xl font-extrabold">WhatsApp delivery</h1><p className="mt-1 text-sm text-gray-500">Monitor account approval, activation and password recovery notification delivery through Meta Cloud API.</p></div><button onClick={load} className="ss-btn-outline"><RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`}/>Refresh</button></div>

    <section className={`rounded-2xl border p-5 ${config?.configured ? "border-emerald-500/30 bg-emerald-500/5" : "border-amber-500/30 bg-amber-500/5"}`}><div className="flex gap-3">{config?.configured ? <CheckCircle2 className="h-5 w-5 text-emerald-400"/> : <AlertTriangle className="h-5 w-5 text-amber-400"/>}<div className="flex-1"><h2 className="font-semibold">{config?.configured ? "Meta Cloud API is configured" : "Configuration is incomplete"}</h2><p className="mt-1 text-sm text-gray-500">API {config?.api_version || "—"} · templates: {Object.values(config?.templates || {}).join(", ") || "—"}</p>{!config?.configured && <div className="mt-3 flex flex-wrap gap-2">{Object.entries(config?.requirements || {}).filter(([, ready]) => !ready).map(([name]) => <span key={name} className="rounded-full bg-amber-500/15 px-2.5 py-1 text-xs font-semibold text-amber-400">Missing {name.replaceAll("_", " ")}</span>)}</div>}</div><Settings2 className="h-5 w-5 text-gray-500"/></div></section>

    <section className="ss-card overflow-hidden"><div className="flex flex-wrap items-center justify-between gap-3 border-b border-white/10 p-5"><div><h2 className="font-display text-lg font-bold">Delivery log</h2><p className="text-sm text-gray-500">Accepted means Meta accepted the API request. Delivered and Read are provider webhook outcomes, not assumptions.</p></div><select className="ss-input w-48" value={status} onChange={(event) => setStatus(event.target.value)}><option value="">All statuses</option>{["NOT_CONFIGURED", "NOT_SENT", "ACCEPTED", "SENT", "DELIVERED", "READ", "FAILED", "RATE_LIMITED"].map((item) => <option key={item} value={item}>{item}</option>)}</select></div><div className="overflow-x-auto"><table className="ss-table min-w-[820px]"><thead><tr><th>Event</th><th>Recipient</th><th>Template</th><th>Status</th><th>Created</th><th>Error</th></tr></thead><tbody>{loading ? <tr><td colSpan="6" className="p-8 text-center text-gray-500">Loading…</td></tr> : deliveries.length ? deliveries.map((item, index) => <tr key={item.id || item.provider_message_id || `${item.event}-${item.created_at}-${index}`}><td><p className="flex items-center gap-2 font-semibold"><MessageCircle className="h-4 w-4 text-emerald-400"/>{item.event?.replaceAll("_", " ")}</p></td><td className="font-mono text-xs">{item.recipient}</td><td className="text-xs text-gray-500">{item.template_name}</td><td><span className={`ss-chip ${statusStyle[item.status] || "bg-white/5 text-gray-400"}`}>{item.status}</span></td><td className="text-gray-500">{fmtDate(item.created_at)}</td><td className="max-w-xs truncate text-xs text-red-400" title={item.last_error}>{item.last_error || "—"}</td></tr>) : <tr><td colSpan="6" className="p-8 text-center text-gray-500">No WhatsApp attempts yet.</td></tr>}</tbody></table></div></section>
  </div>;
}
