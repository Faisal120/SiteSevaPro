import React from "react";
import { api } from "@/lib/api";
import { StatCard, SectionTitle } from "@/components/dashboard/Primitives";
import { TrendingUp, CreditCard, Users, Calendar } from "lucide-react";
import { inr } from "@/lib/constants";
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid } from "recharts";

export default function Revenue() {
  const [s, setS] = React.useState(null);
  React.useEffect(() => { api.get("/admin/stats").then((r) => setS(r.data)); }, []);
  if (!s) return <div className="p-10 text-center text-gray-500">Loading…</div>;
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Revenue</h1>
        <p className="text-sm text-gray-500 mt-1">Subscription revenue across all contractors.</p>
      </div>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard label="MTD Revenue" value={inr(s.monthly_revenue)} icon={TrendingUp} accent="orange" testId="rev-stat-mtd" />
        <StatCard label="Active Subs" value={s.total_contractors} icon={CreditCard} accent="ink" testId="rev-stat-subs" />
        <StatCard label="Expiring" value={s.expiring_subscriptions} icon={Calendar} accent="yellow" testId="rev-stat-expiring" />
        <StatCard label="Active Users" value={s.active_users} icon={Users} accent="soft" testId="rev-stat-users" />
      </div>
      <div className="ss-card p-5">
        <SectionTitle title="Revenue by Month" />
        <div className="h-80">
          <ResponsiveContainer>
            <BarChart data={s.revenue_trend}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: "#525252" }} />
              <YAxis tick={{ fontSize: 12, fill: "#525252" }} />
              <Tooltip contentStyle={{ background: "#fff", border: "1px solid #E5E7EB", borderRadius: 8 }} formatter={(v) => inr(v)} />
              <Bar dataKey="revenue" fill="#F97316" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
