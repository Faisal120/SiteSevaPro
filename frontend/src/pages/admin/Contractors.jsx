import React from "react";
import { Users, Ban, CheckCircle2, MessageCircle, RefreshCw } from "lucide-react";
import { api } from "@/lib/api";
import { Chip, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import ErrorState from "@/components/common/ErrorState";

function accountStatus(user) {
  const states = [user.account_status, user.status].filter(Boolean);
  if (user.blocked || states.some((state) => ["BLOCKED", "SUSPENDED", "DISABLED"].includes(state))) return ["Blocked", "bg-red-100 text-red-700"];
  if (states.includes("REJECTED")) return ["Rejected", "bg-red-100 text-red-700"];
  if (user.password_setup_required || states.includes("PASSWORD_SETUP_REQUIRED")) return ["Password setup required", "bg-amber-100 text-amber-800"];
  if (states.includes("PENDING")) return ["Pending approval", "bg-yellow-100 text-yellow-800"];
  return ["Active", "bg-emerald-100 text-emerald-700"];
}

export default function Contractors() {
  const [list, setList] = React.useState([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState(false);
  const load = React.useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      const { data } = await api.get("/admin/contractors");
      setList(data);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, []);
  React.useEffect(() => { load(); }, [load]);
  const toggleBlock = async (u) => {
    try {
      await api.post(`/admin/contractors/${u.id}/block?blocked=${!u.blocked}`);
      toast.success(u.blocked ? "Unblocked" : "Blocked");
      await load();
    } catch { toast.error("Failed"); }
  };
  const resendCredentials = async (u) => {
    if (!window.confirm(`Resend the account approval notification to ${u.email}? This will not change their password or send an OTP.`)) return;
    try {
      const { data } = await api.post(`/admin/contractors/${u.id}/resend-credentials`);
      const status = data.whatsapp_delivery?.status;
      if (data.success === false) toast.info(data.message || "This active account must use Forgot password. Its password was not changed.");
      else if (["ACCEPTED", "SENT", "DELIVERED", "READ"].includes(status)) toast.success("Approval notification accepted by WhatsApp");
      else toast.warning(`Account notification was not delivered: ${status || "UNKNOWN"}`);
      await load();
    } catch (error) { toast.error(error?.response?.data?.detail || "Unable to resend the account approval notification"); }
  };
  const updatePhone = async (u) => {
    const phone = window.prompt("WhatsApp number with country code", u.phone || u.whatsapp || "+91");
    if (!phone) return;
    try {
      await api.patch(`/admin/contractors/${u.id}/whatsapp`, { phone });
      toast.success("WhatsApp number updated");
      await load();
    } catch (error) { toast.error(error?.response?.data?.detail || "Unable to update number"); }
  };
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Contractors</h1>
        <p className="text-sm text-gray-500 mt-1">Manage all contractor accounts on the platform.</p>
      </div>
      {error ? (
        <ErrorState title="Contractors unavailable" description="Contractor accounts load nahi ho paaye." onRetry={load} />
      ) : loading ? (
        <div className="p-10 text-center text-gray-500">Loading…</div>
      ) : list.length === 0 ? (
        <EmptyState icon={Users} title="No contractors yet" />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Company</th><th>Owner</th><th>Email</th><th>WhatsApp</th><th>Plan</th><th>Status</th><th>Joined</th><th className="text-right">Action</th></tr></thead>
            <tbody>
              {list.map((u) => (
                <tr key={u.id} data-testid={`con-row-${u.id}`}>
                  <td className="font-semibold">{u.company_name}</td>
                  <td>{u.full_name}</td>
                  <td>{u.email}</td>
                  <td><p className="flex items-center gap-1.5 text-xs"><MessageCircle className="h-3.5 w-3.5 text-emerald-500"/>{u.phone || u.whatsapp || "—"}</p><p className="mt-1 text-[10px] text-gray-500">{u.credential_delivery_status || "NOT SENT"}</p></td>
                  <td><Chip className="bg-blue-100 text-blue-700">{u.plan}</Chip></td>
                  <td>{(() => { const [label, style] = accountStatus(u); return <Chip className={style}>{label}</Chip>; })()}</td>
                  <td className="text-gray-500">{fmtDate(u.created_at)}</td>
                  <td className="text-right">
                    <div className="flex justify-end gap-2"><button onClick={() => updatePhone(u)} className="ss-chip bg-gray-100 text-gray-700">Edit no.</button><button onClick={() => resendCredentials(u)} className="ss-chip bg-blue-100 text-blue-700" title="Resends the approval notification only"><RefreshCw className="h-3.5 w-3.5"/>Resend approval</button><button onClick={() => toggleBlock(u)} className={`ss-chip ${u.blocked ? "bg-emerald-100 text-emerald-700" : "bg-red-100 text-red-700"}`} data-testid={`con-toggle-${u.id}`}>
                      {u.blocked ? <><CheckCircle2 className="h-3.5 w-3.5" /> Unblock</> : <><Ban className="h-3.5 w-3.5" /> Block</>}
                    </button></div>
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
