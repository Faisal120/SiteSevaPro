import React from "react";
import { CreditCard, Calendar, Building2 } from "lucide-react";
import { api } from "@/lib/api";
import { Chip, EmptyState } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";

const PLAN_CHIP = {
  FREE: "bg-gray-100 text-gray-700",
  PREMIUM: "bg-[#F97316]/15 text-[#F97316]",
  ENTERPRISE: "bg-purple-100 text-purple-700",
};
const STATUS_CHIP = {
  ACTIVE: "bg-emerald-100 text-emerald-700",
  EXPIRED: "bg-red-100 text-red-700",
  CANCELLED: "bg-gray-100 text-gray-700",
};

export default function Subscriptions() {
  const [list, setList] = React.useState([]);
  const [filter, setFilter] = React.useState("ALL");
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    api.get("/admin/subscriptions")
      .then((r) => setList(r.data))
      .catch(() => toast.error("Failed to load subscriptions"))
      .finally(() => setLoading(false));
  }, []);

  const filtered = filter === "ALL" ? list : list.filter((s) => s.plan === filter);
  const counts = list.reduce((acc, s) => ({ ...acc, [s.plan]: (acc[s.plan] || 0) + 1 }), { ALL: list.length });
  const mrr = list
    .filter((s) => s.status === "ACTIVE" && s.plan !== "FREE")
    .reduce((a, s) => a + (s.amount || 0), 0);

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Subscriptions</h1>
          <p className="text-sm text-gray-500 mt-1">
            All tenant subscriptions · <span className="font-bold text-[#F97316]">{inr(mrr)}</span> active MRR
          </p>
        </div>
        <div className="flex gap-2">
          {["ALL", "FREE", "PREMIUM", "ENTERPRISE"].map((p) => (
            <button key={p} onClick={() => setFilter(p)} className={`ss-chip px-3 py-1.5 ${filter === p ? (PLAN_CHIP[p] || "bg-[#171717] text-white") : "bg-gray-100 text-gray-600 hover:bg-gray-200"}`} data-testid={`subs-filter-${p}`}>
              {p} ({counts[p] || 0})
            </button>
          ))}
        </div>
      </div>
      {loading ? (
        <div className="p-10 text-center text-gray-500">Loading…</div>
      ) : filtered.length === 0 ? (
        <EmptyState icon={CreditCard} title="No subscriptions yet" />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Company</th><th>Plan</th><th>Status</th><th>Amount</th><th>Started</th><th>Expires</th></tr></thead>
            <tbody>
              {filtered.map((s) => (
                <tr key={s.id} data-testid={`subs-row-${s.id}`}>
                  <td className="font-semibold flex items-center gap-2"><Building2 className="h-4 w-4 text-gray-400" /> {s.company_name || s.company_id?.slice(0, 8) + "…"}</td>
                  <td><Chip className={PLAN_CHIP[s.plan]}>{s.plan}</Chip></td>
                  <td><Chip className={STATUS_CHIP[s.status] || "bg-gray-100 text-gray-700"}>{s.status}</Chip></td>
                  <td className="font-bold">{inr(s.amount || 0)}</td>
                  <td className="text-gray-500">{fmtDate(s.started_at)}</td>
                  <td className="text-gray-500 flex items-center gap-1"><Calendar className="h-3 w-3" /> {fmtDate(s.expires_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
