import React from "react";
import { CheckCircle2, Coins, XCircle } from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api";
import { EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate, inr } from "@/lib/constants";

const statusStyle = {
  PENDING: "bg-blue-500/15 text-blue-300",
  APPROVED: "bg-emerald-500/15 text-emerald-300",
  REJECTED: "bg-red-500/15 text-red-300",
};

export default function DesignCreditRequests() {
  const [status, setStatus] = React.useState("PENDING");
  const [requests, setRequests] = React.useState([]);
  const load = React.useCallback(async () => {
    const response = await api.get("/design-wallet/purchase/admin", { params: { status } });
    setRequests(response.data || []);
  }, [status]);
  React.useEffect(() => { load().catch(() => toast.error("Unable to load credit requests")); }, [load]);
  const act = async (id, action) => {
    try { await api.post(`/design-wallet/purchase/${id}/${action}`); toast.success(action === "approve" ? "Credits added to wallet" : "Request rejected"); load(); }
    catch (error) { toast.error(error?.response?.data?.detail || "Unable to process request"); }
  };

  return <div className="space-y-6 ss-fade-in">
    <div className="flex flex-wrap items-end justify-between gap-4"><div><p className="text-xs font-semibold uppercase tracking-[.18em] text-blue-400">Design Studio</p><h1 className="mt-1 font-display text-3xl font-extrabold tracking-tight">Credit verification</h1><p className="mt-1 text-sm text-gray-500">Verify UPI references before credits are released to a contractor wallet.</p></div><div className="flex gap-2">{["PENDING", "APPROVED", "REJECTED"].map((item) => <button key={item} onClick={() => setStatus(item)} className={`rounded-lg px-3 py-2 text-xs font-semibold ${status === item ? "bg-blue-500 text-white" : "bg-white/5 text-gray-400 hover:bg-white/10"}`}>{item}</button>)}</div></div>
    {!requests.length ? <EmptyState icon={Coins} title={`No ${status.toLowerCase()} credit requests`} description="New UPI submissions will appear here." /> : <div className="ss-card overflow-x-auto"><table className="ss-table"><thead><tr><th>Company</th><th>Pack</th><th>Credits</th><th>Amount</th><th>UTR</th><th>Submitted</th><th className="text-right">Action</th></tr></thead><tbody>{requests.map((request) => <tr key={request.id}><td><p className="font-semibold">{request.company_name || "—"}</p><p className="text-xs text-gray-500">{request.user_email}</p></td><td><span className={`ss-chip ${statusStyle[request.status]}`}>{request.pack}</span></td><td className="font-bold text-blue-400">{request.credits}</td><td>{inr(request.amount)}</td><td className="font-mono text-xs">{request.utr}</td><td className="text-gray-500">{fmtDate(request.created_at)}</td><td className="text-right">{request.status === "PENDING" ? <div className="flex justify-end gap-2"><button onClick={() => act(request.id, "approve")} className="ss-chip bg-emerald-500/15 text-emerald-300 hover:bg-emerald-500/25"><CheckCircle2 className="h-3.5 w-3.5" />Approve</button><button onClick={() => act(request.id, "reject")} className="ss-chip bg-red-500/15 text-red-300 hover:bg-red-500/25"><XCircle className="h-3.5 w-3.5" />Reject</button></div> : <span className={`ss-chip ${statusStyle[request.status]}`}>{request.status}</span>}</td></tr>)}</tbody></table></div>}
  </div>;
}
