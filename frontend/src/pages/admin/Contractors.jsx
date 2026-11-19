import React from "react";
import { Users, Ban, CheckCircle2 } from "lucide-react";
import { api } from "@/lib/api";
import { Chip, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";
import { toast } from "sonner";

export default function Contractors() {
  const [list, setList] = React.useState([]);
  React.useEffect(() => {
    const load = async () => { const { data } = await api.get("/admin/contractors"); setList(data); };
    load();
  }, []);
  const toggleBlock = async (u) => {
    try {
      await api.post(`/admin/contractors/${u.id}/block?blocked=${!u.blocked}`);
      toast.success(u.blocked ? "Unblocked" : "Blocked");
      const { data } = await api.get("/admin/contractors");
      setList(data);
    } catch { toast.error("Failed"); }
  };
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Contractors</h1>
        <p className="text-sm text-gray-500 mt-1">Manage all contractor accounts on the platform.</p>
      </div>
      {list.length === 0 ? (
        <EmptyState icon={Users} title="No contractors yet" />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Company</th><th>Owner</th><th>Email</th><th>Username</th><th>Plan</th><th>Status</th><th>Joined</th><th className="text-right">Action</th></tr></thead>
            <tbody>
              {list.map((u) => (
                <tr key={u.id} data-testid={`con-row-${u.id}`}>
                  <td className="font-semibold">{u.company_name}</td>
                  <td>{u.full_name}</td>
                  <td>{u.email}</td>
                  <td className="font-mono text-xs">{u.username}</td>
                  <td><Chip className="bg-blue-100 text-blue-700">{u.plan}</Chip></td>
                  <td>{u.blocked ? <Chip className="bg-red-100 text-red-700">Blocked</Chip> : <Chip className="bg-emerald-100 text-emerald-700">Active</Chip>}</td>
                  <td className="text-gray-500">{fmtDate(u.created_at)}</td>
                  <td className="text-right">
                    <button onClick={() => toggleBlock(u)} className={`ss-chip ${u.blocked ? "bg-emerald-100 text-emerald-700" : "bg-red-100 text-red-700"}`} data-testid={`con-toggle-${u.id}`}>
                      {u.blocked ? <><CheckCircle2 className="h-3.5 w-3.5" /> Unblock</> : <><Ban className="h-3.5 w-3.5" /> Block</>}
                    </button>
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
