import React from "react";
import { Activity } from "lucide-react";
import { api } from "@/lib/api";
import { SectionTitle, Chip, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";

const ACTION_COLOR = {
  CREATE: "bg-emerald-100 text-emerald-700",
  UPDATE: "bg-blue-100 text-blue-700",
  DELETE: "bg-red-100 text-red-700",
  APPROVE: "bg-purple-100 text-purple-700",
  REJECT: "bg-orange-100 text-orange-700",
  PAY: "bg-yellow-100 text-yellow-800",
};

export default function AuditLogs() {
  const [list, setList] = React.useState([]);
  const [filter, setFilter] = React.useState("");
  React.useEffect(() => { api.get(`/admin/audit?limit=300${filter ? `&entity=${filter}` : ""}`).then((r) => setList(r.data)); }, [filter]);
  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Audit Logs</h1>
          <p className="text-sm text-gray-500 mt-1">Complete activity trail across the platform.</p>
        </div>
        <input className="ss-input w-56" placeholder="Filter entity (site, labour…)" value={filter} onChange={(e)=>setFilter(e.target.value)} data-testid="audit-filter" />
      </div>
      {list.length === 0 ? (
        <EmptyState icon={Activity} title="No activity yet" />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Time</th><th>User</th><th>Role</th><th>Action</th><th>Entity</th><th>ID</th><th>Meta</th></tr></thead>
            <tbody>
              {list.map((l) => (
                <tr key={l.id}>
                  <td className="text-xs text-gray-500">{fmtDate(l.ts)} {l.ts.slice(11, 16)}</td>
                  <td className="font-semibold">{l.user_email}</td>
                  <td><Chip className="bg-gray-100 text-gray-700">{l.user_role}</Chip></td>
                  <td><Chip className={ACTION_COLOR[l.action] || "bg-gray-100 text-gray-700"}>{l.action}</Chip></td>
                  <td className="capitalize">{l.entity}</td>
                  <td className="font-mono text-xs text-gray-500">{l.entity_id?.slice(0, 8)}…</td>
                  <td className="font-mono text-xs text-gray-600">{Object.keys(l.meta || {}).length ? JSON.stringify(l.meta) : "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
