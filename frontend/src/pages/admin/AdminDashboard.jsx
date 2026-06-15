import React from "react";
import { Users, Building2, TrendingUp, CreditCard, Briefcase, AlertCircle } from "lucide-react";
import { api } from "@/lib/api";
import { StatCard, SectionTitle } from "@/components/dashboard/Primitives";
import { inr } from "@/lib/constants";
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, CartesianGrid } from "recharts";

export default function AdminDashboard() {
  const [s, setS] = React.useState(null);
  React.useEffect(() => { api.get("/admin/stats").then((r) => setS(r.data)); }, []);
  if (!s) return <div className="p-10 text-center text-gray-500">Loading…</div>;
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Platform Overview</h1>
        <p className="text-sm text-gray-500 mt-1">All contractors, sites and revenue in real time.</p>
      </div>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard label="Total Contractors" value={s.total_contractors} icon={Users} accent="ink" testId="admin-stat-contractors" />
        <StatCard label="Active Sites" value={s.active_sites} icon={Building2} accent="orange" testId="admin-stat-sites" />
        <StatCard label="Monthly Revenue" value={inr(s.monthly_revenue)} icon={TrendingUp} accent="yellow" testId="admin-stat-revenue" />
        <StatCard label="Pending Apps" value={s.pending_applications} icon={Briefcase} accent="soft" testId="admin-stat-apps" />
      </div>
      <div className="grid lg:grid-cols-3 gap-5">
        <div className="ss-card p-5 lg:col-span-2">
          <SectionTitle title="Revenue Trend" subtitle="Last 6 months" />
          <div className="h-72">
            <ResponsiveContainer>
              <AreaChart data={s.revenue_trend} margin={{ top: 5, right: 10, left: -10, bottom: 5 }}>
                <defs>
                  <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#F97316" stopOpacity={0.45} />
                    <stop offset="95%" stopColor="#F97316" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: "#525252" }} />
                <YAxis tick={{ fontSize: 11, fill: "#525252" }} />
                <Tooltip contentStyle={{ background: "#fff", border: "1px solid #E5E7EB", borderRadius: 8 }} formatter={(v) => inr(v)} />
                <Area dataKey="revenue" stroke="#F97316" strokeWidth={2} fill="url(#rev)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="ss-card p-5 flex flex-col gap-4">
          <SectionTitle title="Quick Stats" />
          <div className="flex items-center gap-3"><div className="h-9 w-9 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center"><Users className="h-4 w-4" /></div><div><div className="text-xs text-gray-500">Active Users</div><div className="font-bold">{s.active_users}</div></div></div>
          <div className="flex items-center gap-3"><div className="h-9 w-9 rounded-lg bg-orange-100 text-[#F97316] flex items-center justify-center"><AlertCircle className="h-4 w-4" /></div><div><div className="text-xs text-gray-500">Expiring Soon</div><div className="font-bold">{s.expiring_subscriptions}</div></div></div>
          <div className="flex items-center gap-3"><div className="h-9 w-9 rounded-lg bg-yellow-100 text-yellow-700 flex items-center justify-center"><CreditCard className="h-4 w-4" /></div><div><div className="text-xs text-gray-500">Revenue (MTD)</div><div className="font-bold">{inr(s.monthly_revenue)}</div></div></div>
        </div>
      </div>
    </div>
  );
}
