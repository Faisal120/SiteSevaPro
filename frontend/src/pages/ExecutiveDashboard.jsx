import React from "react";
import { Building2, Wallet, TrendingUp, Package, Users, Activity, ArrowRight, BarChart3 } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { StatCard, SectionTitle } from "@/components/dashboard/Primitives";
import { inr } from "@/lib/constants";
import {
  ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, AreaChart, Area, Legend,
} from "recharts";

export default function ExecutiveDashboard() {
  const nav = useNavigate();
  const [d, setD] = React.useState(null);
  React.useEffect(() => { api.get("/dashboard/executive").then((r) => setD(r.data)); }, []);
  if (!d) return <div className="p-10 text-center text-gray-500">Loading…</div>;
  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Executive Dashboard</h1>
          <p className="text-sm text-gray-500 mt-1">Full P&amp;L, profitability and team strength.</p>
        </div>
        <button onClick={() => nav("/app/dashboard")} className="ss-btn-outline" data-testid="exec-back">Standard view</button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard label="Active Sites" value={`${d.active_sites}/${d.total_sites}`} icon={Building2} accent="ink" testId="exec-sites" />
        <StatCard label="Supervisors" value={d.supervisors} icon={Users} accent="blue" testId="exec-sup" />
        <StatCard label="Total Labour" value={d.total_labour} icon={Users} accent="yellow" testId="exec-lab" />
        <StatCard label="Net Profit" value={inr(d.profit)} icon={Activity} accent="soft" testId="exec-profit" />
      </div>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard label="Received" value={inr(d.received)} icon={TrendingUp} accent="soft" testId="exec-recv" />
        <StatCard label="Pending" value={inr(d.pending)} icon={Wallet} accent="soft" testId="exec-pending" />
        <StatCard label="Material Cost" value={inr(d.material_cost)} icon={Package} accent="soft" testId="exec-mat" />
        <StatCard label="Labour Cost" value={inr(d.labour_cost)} icon={Users} accent="soft" testId="exec-labcost" />
      </div>

      <div className="grid lg:grid-cols-3 gap-5">
        <div className="ss-card p-5 lg:col-span-2">
          <SectionTitle title="Cashflow Trend" subtitle="Received vs spent" />
          <div className="h-72">
            <ResponsiveContainer>
              <AreaChart data={d.trend}>
                <defs>
                  <linearGradient id="rec" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#22C55E" stopOpacity={0.4} /><stop offset="95%" stopColor="#22C55E" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="exp" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.4} /><stop offset="95%" stopColor="#3B82F6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: "#525252" }} />
                <YAxis tick={{ fontSize: 11, fill: "#525252" }} />
                <Tooltip contentStyle={{ background: "#fff", border: "1px solid #E5E7EB", borderRadius: 8 }} formatter={(v) => inr(v)} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                <Area dataKey="received" stroke="#22C55E" strokeWidth={2} fill="url(#rec)" />
                <Area dataKey="expense" stroke="#3B82F6" strokeWidth={2} fill="url(#exp)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="ss-card p-5">
          <SectionTitle title="P&L Snapshot" />
          <div className="space-y-3 text-sm">
            <Row label="Received" v={d.received} pos />
            <Row label="− Material" v={d.material_cost} />
            <Row label="− Labour" v={d.labour_cost} />
            <Row label="− Expenses" v={d.expenses} />
            <div className="border-t border-gray-200 pt-2 mt-2">
              <Row label="Net Profit" v={d.profit} pos bold />
            </div>
          </div>
        </div>
      </div>

      <div className="ss-card p-5">
        <SectionTitle title="Site Profitability" />
        <div className="h-80">
          <ResponsiveContainer>
            <BarChart data={d.site_profitability}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
              <XAxis dataKey="name" tick={{ fontSize: 11, fill: "#525252" }} />
              <YAxis tick={{ fontSize: 11, fill: "#525252" }} />
              <Tooltip contentStyle={{ background: "#fff", border: "1px solid #E5E7EB", borderRadius: 8 }} formatter={(v) => inr(v)} />
              <Legend wrapperStyle={{ fontSize: 12 }} />
              <Bar dataKey="received" fill="#171717" radius={[4, 4, 0, 0]} />
              <Bar dataKey="cost" fill="#3B82F6" radius={[4, 4, 0, 0]} />
              <Bar dataKey="profit" fill="#22C55E" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}

function Row({ label, v, pos, bold }) {
  return (
    <div className="flex justify-between">
      <span className={`text-gray-600 ${bold ? "font-bold text-[#171717]" : ""}`}>{label}</span>
      <span className={`${bold ? "font-extrabold text-[#171717]" : pos ? "text-emerald-600 font-semibold" : "text-[#3B82F6] font-semibold"}`}>{inr(v)}</span>
    </div>
  );
}
