import React from "react";
import { Coins } from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api";
import { EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate, inr } from "@/lib/constants";

const statusStyle = {
  PENDING: "bg-blue-500/15 text-blue-300",
  APPROVED: "bg-emerald-500/15 text-emerald-300",
  REJECTED: "bg-red-500/15 text-red-300",
  FAILED: "bg-red-500/15 text-red-300",
  PROCESSING: "bg-blue-500/15 text-blue-300",
};

export default function DesignCreditRequests() {
  const [status, setStatus] = React.useState("PENDING");
  const [requests, setRequests] = React.useState([]);
  const load = React.useCallback(async () => {
    const response = await api.get("/design-wallet/purchase/admin", { params: { status } });
    setRequests(response.data || []);
  }, [status]);
  React.useEffect(() => { load().catch(() => toast.error("Unable to load credit requests")); }, [load]);
  return <div className="space-y-6 ss-fade-in">
    <div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-xs font-semibold uppercase tracking-[.18em] text-blue-400">Design Studio</p><h1 className="mt-1 font-display text-3xl font-extrabold tracking-tight">Legacy credit history</h1><p className="mt-1 text-sm text-gray-500">Manual UPI credit purchases are retired. This page is read-only for historical records.</p></div><div className="flex flex-wrap gap-2">{["PENDING", "PROCESSING", "APPROVED", "REJECTED", "FAILED"].map((item) => <button key={item} onClick={() => setStatus(item)} className={`rounded-lg px-3 py-2 text-xs font-semibold ${status === item ? "bg-blue-500 text-white" : "bg-white/5 text-gray-400 hover:bg-white/10"}`}>{item}</button>)}</div></div>
    {!requests.length ? <EmptyState icon={Coins} title={`No ${status.toLowerCase()} historical credit requests`} description="New manual credit requests cannot be submitted." /> : <div className="ss-card overflow-x-auto"><table className="ss-table"><thead><tr><th>Company</th><th>Pack</th><th>Credits</th><th>Amount</th><th>Submitted</th><th>Status</th></tr></thead><tbody>{requests.map((request) => <tr key={request.id}><td><p className="font-semibold">{request.company_name || "—"}</p><p className="text-xs text-gray-500">{request.user_email}</p></td><td><span className={`ss-chip ${statusStyle[request.status]}`}>{request.pack}</span></td><td className="font-bold text-blue-400">{request.credits}</td><td>{inr(request.amount)}</td><td className="text-gray-500">{fmtDate(request.created_at)}</td><td><span className={`ss-chip ${statusStyle[request.status]}`}>{request.status}</span></td></tr>)}</tbody></table></div>}
  </div>;
}
