import React from "react";
import { Users, Ban, CheckCircle2, Building2 } from "lucide-react";
import { api } from "@/lib/api";
import { Chip, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";
import { toast } from "sonner";

export default function Supervisors() {
  const [list, setList] = React.useState([]);
  const [loading, setLoading] = React.useState(true);
  const [search, setSearch] = React.useState("");

  const load = React.useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get("/admin/supervisors");
      setList(data);
    } catch { toast.error("Failed to load supervisors"); }
    finally { setLoading(false); }
  }, []);
  React.useEffect(() => { load(); }, [load]);

  const toggleBlock = async (u) => {
    try {
      await api.post(`/admin/contractors/${u.id}/block?blocked=${!u.blocked}`);
      toast.success(u.blocked ? "Unblocked" : "Blocked");
      load();
    } catch { toast.error("Failed"); }
  };

  const q = search.toLowerCase().trim();
  const filtered = !q ? list : list.filter((u) =>
    (u.full_name || "").toLowerCase().includes(q) ||
    (u.email || "").toLowerCase().includes(q) ||
    (u.company_name || "").toLowerCase().includes(q)
  );

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Supervisors</h1>
          <p className="text-sm text-gray-500 mt-1">
            All site supervisors across every contractor · <span className="font-bold text-[#171717]">{list.length}</span> total
          </p>
        </div>
        <input className="ss-input w-64" placeholder="Search name / email / company" value={search} onChange={(e) => setSearch(e.target.value)} data-testid="sup-search" />
      </div>
      {loading ? (
        <div className="p-10 text-center text-gray-500">Loading…</div>
      ) : filtered.length === 0 ? (
        <EmptyState icon={Users} title={search ? "No supervisors match your search" : "No supervisors yet"} description={search ? null : "Supervisors are added by contractors from their dashboard."} />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Supervisor</th><th>Email</th><th>Company</th><th>Sites Assigned</th><th>Status</th><th>Joined</th><th className="text-right">Action</th></tr></thead>
            <tbody>
              {filtered.map((u) => (
                <tr key={u.id} data-testid={`sup-row-${u.id}`}>
                  <td>
                    <div className="font-semibold">{u.full_name}</div>
                    <div className="text-xs text-gray-500 font-mono">{u.username}</div>
                  </td>
                  <td>{u.email}</td>
                  <td className="text-gray-700"><Chip className="bg-gray-100 text-gray-700"><Building2 className="h-3 w-3" /> {u.company_name || "—"}</Chip></td>
                  <td><span className="font-bold">{u.site_count}</span></td>
                  <td>{u.blocked ? <Chip className="bg-red-100 text-red-700">Blocked</Chip> : <Chip className="bg-emerald-100 text-emerald-700">Active</Chip>}</td>
                  <td className="text-gray-500">{fmtDate(u.created_at)}</td>
                  <td className="text-right">
                    <button onClick={() => toggleBlock(u)} className={`ss-chip ${u.blocked ? "bg-emerald-100 text-emerald-700" : "bg-red-100 text-red-700"}`} data-testid={`sup-toggle-${u.id}`}>
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
