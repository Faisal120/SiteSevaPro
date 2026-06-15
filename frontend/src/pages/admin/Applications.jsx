import React from "react";
import { Briefcase, CheckCircle2, XCircle, Copy, RefreshCw } from "lucide-react";
import { api } from "@/lib/api";
import { Chip, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";

const STATUS_CHIP = {
  PENDING: "bg-yellow-100 text-yellow-800",
  APPROVED: "bg-emerald-100 text-emerald-700",
  REJECTED: "bg-red-100 text-red-700",
};

export default function Applications() {
  const [list, setList] = React.useState([]);
  const [filter, setFilter] = React.useState("PENDING");
  const [creds, setCreds] = React.useState(null);
  const [loading, setLoading] = React.useState(false);

  const load = React.useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get("/admin/applications");
      setList(data);
    } catch (e) {
      toast.error("Failed to load applications");
    } finally { setLoading(false); }
  }, []);
  React.useEffect(() => { load(); }, [load]);

  const counts = React.useMemo(() => {
    const c = { ALL: list.length, PENDING: 0, APPROVED: 0, REJECTED: 0 };
    list.forEach((a) => { c[a.status] = (c[a.status] || 0) + 1; });
    return c;
  }, [list]);

  const filtered = filter === "ALL" ? list : list.filter((a) => a.status === filter);

  const approve = async (id) => {
    try {
      const { data } = await api.post(`/admin/applications/${id}/approve`);
      setCreds(data);
      load();
    } catch { toast.error("Approve failed"); }
  };
  const reject = async (id) => {
    if (!window.confirm("Reject this application?")) return;
    try { await api.post(`/admin/applications/${id}/reject`); toast.success("Rejected"); load(); }
    catch { toast.error("Reject failed"); }
  };

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Contractor Applications</h1>
          <p className="text-sm text-gray-500 mt-1">
            {counts.PENDING > 0 ? (
              <>
                <span className="font-bold text-[#F97316]">{counts.PENDING}</span> awaiting your review · {counts.ALL} total
              </>
            ) : (
              <>No pending applications · {counts.ALL} total received</>
            )}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {["PENDING", "APPROVED", "REJECTED", "ALL"].map((s) => (
            <button
              key={s}
              onClick={() => setFilter(s)}
              className={`ss-chip px-3 py-1.5 ${filter === s ? (STATUS_CHIP[s] || "bg-[#171717] text-white") : "bg-gray-100 text-gray-600 hover:bg-gray-200"}`}
              data-testid={`apps-filter-${s}`}
            >
              {s} {counts[s] !== undefined && <span className="ml-1 opacity-70">({counts[s]})</span>}
            </button>
          ))}
          <button onClick={load} disabled={loading} className="p-2 rounded-lg hover:bg-gray-100 text-gray-600 disabled:opacity-50" aria-label="Refresh" data-testid="apps-refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
          </button>
        </div>
      </div>

      {filtered.length === 0 ? (
        <EmptyState
          icon={Briefcase}
          title={filter === "PENDING" ? "No pending applications" : filter === "ALL" ? "No applications yet" : `No ${filter.toLowerCase()} applications`}
          description={filter === "PENDING" ? "When a new contractor signs up via the public registration form, their application will land here for your review." : null}
        />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Company</th><th>Owner</th><th>Email</th><th>Mobile</th><th>City</th><th>Projects</th><th>Status</th><th>Date</th><th className="text-right">Actions</th></tr></thead>
            <tbody>
              {filtered.map((a) => (
                <tr key={a.id} data-testid={`app-row-${a.id}`}>
                  <td className="font-semibold">{a.company_name}</td>
                  <td>{a.owner_name}</td>
                  <td>{a.email}</td>
                  <td className="font-mono text-xs">{a.mobile}</td>
                  <td>{a.city}, {a.state}</td>
                  <td>{a.active_projects}</td>
                  <td><Chip className={STATUS_CHIP[a.status]}>{a.status}</Chip></td>
                  <td className="text-gray-500">{fmtDate(a.created_at)}</td>
                  <td className="text-right">
                    {a.status === "PENDING" ? (
                      <div className="flex gap-2 justify-end">
                        <button onClick={() => approve(a.id)} className="ss-chip bg-emerald-100 text-emerald-700 hover:bg-emerald-200" data-testid={`app-approve-${a.id}`}><CheckCircle2 className="h-3.5 w-3.5" /> Approve</button>
                        <button onClick={() => reject(a.id)} className="ss-chip bg-red-100 text-red-700 hover:bg-red-200" data-testid={`app-reject-${a.id}`}><XCircle className="h-3.5 w-3.5" /> Reject</button>
                      </div>
                    ) : (
                      <span className="text-xs text-gray-400">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Dialog open={!!creds} onOpenChange={(o) => !o && setCreds(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Contractor Approved 🎉</DialogTitle></DialogHeader>
          {creds && (
            <div className="space-y-3">
              <p className="text-sm text-gray-600">Share these credentials with the contractor via email:</p>
              <div className="bg-gray-50 rounded-lg p-4 space-y-2 font-mono text-sm">
                <div><span className="text-gray-500">Email:</span> {creds.email}</div>
                <div><span className="text-gray-500">Username:</span> {creds.username}</div>
                <div><span className="text-gray-500">Password:</span> {creds.password}</div>
              </div>
              <button
                onClick={() => { navigator.clipboard.writeText(`Email: ${creds.email}\nUsername: ${creds.username}\nPassword: ${creds.password}`); toast.success("Copied"); }}
                className="ss-btn-accent w-full"
                data-testid="creds-copy"
              >
                <Copy className="h-4 w-4" /> Copy Credentials
              </button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
