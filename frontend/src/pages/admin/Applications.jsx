import React from "react";
import { Briefcase, CheckCircle2, XCircle, Copy } from "lucide-react";
import { api } from "@/lib/api";
import { SectionTitle, Chip, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";

const STATUS_CHIP = { PENDING: "bg-yellow-100 text-yellow-800", APPROVED: "bg-emerald-100 text-emerald-700", REJECTED: "bg-red-100 text-red-700" };

export default function Applications() {
  const [list, setList] = React.useState([]);
  const [creds, setCreds] = React.useState(null);
  const load = async () => { const { data } = await api.get("/admin/applications"); setList(data); };
  React.useEffect(() => { load(); }, []);

  const approve = async (id) => {
    try {
      const { data } = await api.post(`/admin/applications/${id}/approve`);
      setCreds(data);
      load();
    } catch { toast.error("Failed"); }
  };
  const reject = async (id) => {
    if (!confirm("Reject this application?")) return;
    try { await api.post(`/admin/applications/${id}/reject`); toast.success("Rejected"); load(); } catch { toast.error("Failed"); }
  };

  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Contractor Applications</h1>
        <p className="text-sm text-gray-500 mt-1">Review and approve new contractor registrations.</p>
      </div>
      {list.length === 0 ? (
        <EmptyState icon={Briefcase} title="No applications yet" />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Company</th><th>Owner</th><th>Email</th><th>City</th><th>Projects</th><th>Status</th><th>Date</th><th className="text-right">Actions</th></tr></thead>
            <tbody>
              {list.map((a) => (
                <tr key={a.id} data-testid={`app-row-${a.id}`}>
                  <td className="font-semibold">{a.company_name}</td>
                  <td>{a.owner_name}</td>
                  <td>{a.email}</td>
                  <td>{a.city}, {a.state}</td>
                  <td>{a.active_projects}</td>
                  <td><Chip className={STATUS_CHIP[a.status]}>{a.status}</Chip></td>
                  <td className="text-gray-500">{fmtDate(a.created_at)}</td>
                  <td className="text-right">
                    {a.status === "PENDING" && (
                      <div className="flex gap-2 justify-end">
                        <button onClick={() => approve(a.id)} className="ss-chip bg-emerald-100 text-emerald-700 hover:bg-emerald-200" data-testid={`app-approve-${a.id}`}><CheckCircle2 className="h-3.5 w-3.5" /> Approve</button>
                        <button onClick={() => reject(a.id)} className="ss-chip bg-red-100 text-red-700 hover:bg-red-200" data-testid={`app-reject-${a.id}`}><XCircle className="h-3.5 w-3.5" /> Reject</button>
                      </div>
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
              <button onClick={() => { navigator.clipboard.writeText(`Email: ${creds.email}\nUsername: ${creds.username}\nPassword: ${creds.password}`); toast.success("Copied"); }} className="ss-btn-accent w-full"><Copy className="h-4 w-4" /> Copy Credentials</button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
