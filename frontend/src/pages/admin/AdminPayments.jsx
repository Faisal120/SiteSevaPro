import React from "react";
import { api } from "@/lib/api";
import { Chip, EmptyState } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Wallet, CheckCircle2, XCircle, ExternalLink } from "lucide-react";
import ErrorState from "@/components/common/ErrorState";

const STATUS = {
  PENDING: "bg-yellow-100 text-yellow-800",
  APPROVED: "bg-emerald-100 text-emerald-700",
  REJECTED: "bg-red-100 text-red-700",
  FAILED: "bg-red-100 text-red-700",
  PROCESSING: "bg-blue-100 text-blue-700",
};

export default function AdminPayments() {
  const [list, setList] = React.useState([]);
  const [filter, setFilter] = React.useState("PENDING");
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState(false);
  const load = React.useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      const { data } = await api.get(`/admin/payments?status=${filter}`);
      setList(data);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, [filter]);
  React.useEffect(() => { load(); }, [load]);
  const approve = async (id) => {
    try {
      const { data } = await api.post(`/admin/payments/${id}/approve`);
      const status = data.whatsapp_delivery?.status;
      if (["ACCEPTED", "SENT", "DELIVERED", "READ"].includes(status)) toast.success("Approved and WhatsApp notification submitted");
      else toast.warning(`Approved; WhatsApp status: ${status || "UNKNOWN"}`);
      load();
    } catch (e) {
      toast.error(e?.response?.data?.detail || "Approval failed");
    }
  };
  const reject = async (id) => {
    const reason = prompt("Rejection reason?");
    if (reason === null) return;
    try {
      await api.post(`/admin/payments/${id}/reject?reason=${encodeURIComponent(reason)}`);
      toast.success("Rejected");
      load();
    } catch (e) {
      toast.error(e?.response?.data?.detail || "Rejection failed");
    }
  };
  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Subscription Payments</h1>
          <p className="text-sm text-gray-500 mt-1">Verify UPI payments and activate plans.</p>
        </div>
        <div className="flex gap-2">
          {["PENDING", "PROCESSING", "APPROVED", "REJECTED", "FAILED"].map((s) => (
            <button key={s} onClick={() => setFilter(s)} className={`ss-chip ${filter === s ? STATUS[s] : "bg-gray-100 text-gray-600"}`} data-testid={`apay-filter-${s}`}>{s}</button>
          ))}
        </div>
      </div>
      {error ? (
        <ErrorState title="Payments unavailable" description="Payment requests load nahi ho paayi." onRetry={load} />
      ) : loading ? (
        <div className="p-10 text-center text-gray-500">Loading…</div>
      ) : list.length === 0 ? (
        <EmptyState icon={Wallet} title={`No ${filter.toLowerCase()} payments`} />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Company</th><th>Email</th><th>Plan</th><th>Amount</th><th>UTR</th><th>Screenshot</th><th>Date</th><th className="text-right">Action</th></tr></thead>
            <tbody>
              {list.map((p) => (
                <tr key={p.id} data-testid={`apay-row-${p.id}`}>
                  <td className="font-semibold">{p.company_name}</td>
                  <td>{p.user_email}</td>
                  <td><Chip className="bg-blue-100 text-blue-700">{p.plan}</Chip></td>
                  <td className="font-bold">{inr(p.amount)}</td>
                  <td className="font-mono text-xs">{p.utr}</td>
                  <td>{p.screenshot_url ? <a className="text-[#3B82F6] text-xs font-semibold flex items-center gap-1" href={p.screenshot_url} target="_blank" rel="noreferrer">View <ExternalLink className="h-3 w-3" /></a> : "—"}</td>
                  <td className="text-gray-500">{fmtDate(p.created_at)}</td>
                  <td className="text-right">
                    {p.status === "PENDING" ? (
                      <div className="flex gap-2 justify-end">
                        <button onClick={() => approve(p.id)} className="ss-chip bg-emerald-100 text-emerald-700 hover:bg-emerald-200" data-testid={`apay-approve-${p.id}`}><CheckCircle2 className="h-3.5 w-3.5" /> Approve</button>
                        <button onClick={() => reject(p.id)} className="ss-chip bg-red-100 text-red-700 hover:bg-red-200" data-testid={`apay-reject-${p.id}`}><XCircle className="h-3.5 w-3.5" /> Reject</button>
                      </div>
                    ) : (
                      <Chip className={STATUS[p.status]}>{p.status}</Chip>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
