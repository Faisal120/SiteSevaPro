import React from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, MapPin, Calendar, Users, Package, Wallet, FileText, Camera, Sparkles, Loader2 } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { Chip, SectionTitle } from "@/components/dashboard/Primitives";
import { inr, fmtDate, SITE_STATUS_COLOR } from "@/lib/constants";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { toast } from "sonner";

export default function SiteDetail() {
  const { siteId } = useParams();
  const { user } = useAuth();
  const nav = useNavigate();
  const [site, setSite] = React.useState(null);
  const [labour, setLabour] = React.useState([]);
  const [materials, setMaterials] = React.useState([]);
  const [payments, setPayments] = React.useState([]);
  const [reports, setReports] = React.useState([]);
  const [team, setTeam] = React.useState([]);
  const [selectedSupervisor, setSelectedSupervisor] = React.useState("");
  const [selectedClient, setSelectedClient] = React.useState("");
  const [insight, setInsight] = React.useState(null);
  const [aiBusy, setAiBusy] = React.useState(false);

  React.useEffect(() => {
    (async () => {
      const s = await api.get(`/sites/${siteId}`);
      setSite(s.data);
      if (user.role === "CONTRACTOR") {
        const teamRes = await api.get("/team");
        setTeam(teamRes.data);
      }
      const calls = [api.get(`/daily-reports?site_id=${siteId}`)];
      if (user.role !== "CLIENT") {
        calls.push(api.get(`/labour?site_id=${siteId}`));
        calls.push(api.get(`/materials?site_id=${siteId}`));
      }
      calls.push(api.get(`/payments?site_id=${siteId}`));
      const results = await Promise.all(calls);
      setReports(results[0].data);
      if (user.role !== "CLIENT") {
        setLabour(results[1].data);
        setMaterials(results[2].data);
        setPayments(results[3].data);
      } else {
        setPayments(results[1].data);
      }
    })();
  }, [siteId, user.role]);

  const assignSupervisor = async () => {
    try {
      await api.post(`/sites/${siteId}/assign-supervisor`, {
        supervisor_id: selectedSupervisor,
      });

      toast.success("Supervisor assigned");
    } catch (e) {
      toast.error("Assignment failed");
    }
  };

  const assignClient = async () => {
    try {
      await api.post(`/sites/${siteId}/assign-client`, {
        client_id: selectedClient,
      });

      toast.success("Client assigned");
    } catch (e) {
      toast.error("Assignment failed");
    }
  };

  const runAI = async (kind) => {
    setAiBusy(true);
    setInsight(null);
    try {
      const ctx = {
        site_name: site.name, location: site.location, budget: site.budget, progress: site.progress, status: site.status,
        material_count: materials.length, labour_count: labour.length, payment_count: payments.length,
        materials: materials.map(m => ({ name: m.name, category: m.category, stock: m.stock, unit: m.unit })),
        recent_payments: payments.slice(0, 5).map(p => ({ type: p.type, amount: p.amount, description: p.description })),
      };
      const { data } = await api.post("/ai/insight", { kind, context: ctx });
      setInsight({ kind, text: data.insight });
    } catch (e) {
      toast.error(e?.response?.data?.detail || "AI service error");
    } finally { setAiBusy(false); }
  };

  if (!site) return <div className="p-10 text-center text-gray-500">Loading…</div>;

  return (
    <div className="space-y-6 ss-fade-in">
      <button onClick={() => nav(-1)} className="text-sm text-gray-500 hover:text-[#171717] flex items-center gap-1" data-testid="site-back">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div className="ss-card overflow-hidden">
        <div className="h-44 relative">
          <img src="https://images.pexels.com/photos/1816030/pexels-photo-1816030.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=400&w=1200" alt="" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-[#171717]/80 via-[#171717]/30 to-transparent" />
          <div className="absolute bottom-4 left-6 right-6 flex items-end justify-between text-white">
            <div>
              <Chip className={`${SITE_STATUS_COLOR[site.status]} mb-2`}>{site.status}</Chip>
              <h1 className="font-display text-3xl font-extrabold">{site.name}</h1>
              <p className="text-sm text-gray-200 flex items-center gap-2 mt-1"><MapPin className="h-3.5 w-3.5" /> {site.location}</p>
            </div>
            <div className="hidden md:flex gap-6 text-right">
              <div>
                <div className="text-[10px] uppercase tracking-wider text-gray-300">Budget</div>
                <div className="text-xl font-extrabold">{inr(site.budget)}</div>
              </div>
              <div>
                <div className="text-[10px] uppercase tracking-wider text-gray-300">Progress</div>
                <div className="text-xl font-extrabold">{site.progress}%</div>
                <div className="w-48 h-2 bg-white/20 rounded-full mt-2">
                  <div
                    className="h-full bg-[#F97316] rounded-full"
                    style={{
                      width: `${site.progress}%`
                    }}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-6 bg-gray-50 border-t">
          <div className="bg-white rounded-xl p-4 shadow-sm">
            <p className="text-xs text-gray-500">Budget</p>
            <h3 className="text-lg font-bold">{inr(site.budget)}</h3>
          </div>

          <div className="bg-white rounded-xl p-4 shadow-sm">
            <p className="text-xs text-gray-500">Progress</p>
            <h3 className="text-lg font-bold">{site.progress}%</h3>
          </div>

          <div className="bg-white rounded-xl p-4 shadow-sm">
            <p className="text-xs text-gray-500">Supervisor</p>
            <h3 className="text-lg font-bold">
              {site.supervisor_name || "Not Assigned"}
            </h3>
          </div>

          <div className="bg-white rounded-xl p-4 shadow-sm">
            <p className="text-xs text-gray-500">Client</p>
            <h3 className="text-lg font-bold">
              {site.client_name || "Not Assigned"}
            </h3>
          </div>
        </div>
        <div className="px-6 py-4 grid md:grid-cols-4 gap-4 text-sm">
          {user.role === "CONTRACTOR" && (
            <div className="px-6 pb-6">
              <div className="bg-white border rounded-2xl p-6 shadow-sm">

                <h2 className="text-xl font-bold mb-5">
                  Team Assignment
                </h2>

                <div className="grid md:grid-cols-2 gap-6">

                  <div>
                    <label className="text-sm font-semibold">
                      Supervisor
                    </label>

                    <select
                      className="ss-input mt-2"
                      value={selectedSupervisor}
                      onChange={(e) =>
                        setSelectedSupervisor(e.target.value)
                      }
                    >
                      <option value="">
                        Select Supervisor
                      </option>

                      {team
                        .filter((u) => u.role === "SUPERVISOR")
                        .map((u) => (
                          <option key={u.id} value={u.id}>
                            {u.full_name}
                          </option>
                        ))}
                    </select>

                    <button
                      className="ss-btn-accent mt-3 w-full"
                      onClick={assignSupervisor}
                    >
                      Save Supervisor
                    </button>
                  </div>

                  <div>
                    <label className="text-sm font-semibold">
                      Client
                    </label>

                    <select
                      className="ss-input mt-2"
                      value={selectedClient}
                      onChange={(e) =>
                        setSelectedClient(e.target.value)
                      }
                    >
                      <option value="">
                        Select Client
                      </option>

                      {team
                        .filter((u) => u.role === "CLIENT")
                        .map((u) => (
                          <option key={u.id} value={u.id}>
                            {u.full_name}
                          </option>
                        ))}
                    </select>

                    <button
                      className="ss-btn-accent mt-3 w-full"
                      onClick={assignClient}
                    >
                      Save Client
                    </button>
                  </div>

                </div>
              </div>
            </div>
          )}
          <div><span className="text-gray-500">Client:</span> <span className="font-semibold">{site.client_name}</span></div>
          <div><span className="text-gray-500">Email:</span> <span className="font-semibold">{site.client_email || "—"}</span></div>
          <div><span className="text-gray-500">Start:</span> <span className="font-semibold">{fmtDate(site.start_date)}</span></div>
          <div><span className="text-gray-500">End:</span> <span className="font-semibold">{fmtDate(site.end_date)}</span></div>
        </div>
      </div>

      <Tabs defaultValue="overview">
        <TabsList className="bg-white border border-gray-200 p-1">
          <TabsTrigger value="overview" data-testid="tab-overview">Overview</TabsTrigger>
          {user.role !== "CLIENT" && <TabsTrigger value="labour" data-testid="tab-labour">Labour</TabsTrigger>}
          {user.role !== "CLIENT" && <TabsTrigger value="materials" data-testid="tab-materials">Materials</TabsTrigger>}
          <TabsTrigger value="payments" data-testid="tab-payments">Payments</TabsTrigger>
          <TabsTrigger value="reports" data-testid="tab-reports">Daily Reports</TabsTrigger>
          {user.role === "CONTRACTOR" && <TabsTrigger value="ai" data-testid="tab-ai">AI Insights</TabsTrigger>}
        </TabsList>

        <TabsContent value="overview" className="mt-5">
          <div className="ss-card p-6">
            <SectionTitle title="Project Overview" />
            <p className="text-sm text-gray-600 leading-relaxed">{site.description || "No description yet."}</p>
            <div className="grid md:grid-cols-3 gap-4 mt-6">

              <div className="border rounded-xl p-4">
                <p className="text-xs text-gray-500">
                  Start Date
                </p>

                <h4 className="font-semibold">
                  {fmtDate(site.start_date)}
                </h4>
              </div>

              <div className="border rounded-xl p-4">
                <p className="text-xs text-gray-500">
                  End Date
                </p>

                <h4 className="font-semibold">
                  {fmtDate(site.end_date)}
                </h4>
              </div>

              <div className="border rounded-xl p-4">
                <p className="text-xs text-gray-500">
                  Status
                </p>

                <h4 className="font-semibold">
                  {site.status}
                </h4>
              </div>

            </div>
          </div>
        </TabsContent>

        <TabsContent value="labour" className="mt-5">
          <div className="ss-card p-5 overflow-x-auto">
            <SectionTitle title={`Labour (${labour.length})`} />
            <table className="ss-table">
              <thead><tr><th>Name</th><th>Role</th><th>Daily Wage</th><th>Mobile</th></tr></thead>
              <tbody>
                {labour.map((l) => (
                  <tr key={l.id}><td className="font-semibold">{l.name}</td><td>{l.role}</td><td>{inr(l.daily_wage)}</td><td>{l.mobile || "—"}</td></tr>
                ))}
                {labour.length === 0 && <tr><td colSpan={4} className="text-center text-gray-500 py-6">No labour records.</td></tr>}
              </tbody>
            </table>
          </div>
        </TabsContent>

        <TabsContent value="materials" className="mt-5">
          <div className="ss-card p-5 overflow-x-auto">
            <SectionTitle title={`Materials (${materials.length})`} />
            <table className="ss-table">
              <thead><tr><th>Name</th><th>Category</th><th>Stock</th><th>Rate</th><th>Status</th></tr></thead>
              <tbody>
                {materials.map((m) => (
                  <tr key={m.id}>
                    <td className="font-semibold">{m.name}</td>
                    <td>{m.category}</td>
                    <td>{m.stock} {m.unit}</td>
                    <td>{inr(m.rate)}/{m.unit}</td>
                    <td>{m.stock < m.low_stock_threshold ? <Chip className="bg-red-100 text-red-700">Low</Chip> : <Chip className="bg-emerald-100 text-emerald-700">OK</Chip>}</td>
                  </tr>
                ))}
                {materials.length === 0 && <tr><td colSpan={5} className="text-center text-gray-500 py-6">No materials.</td></tr>}
              </tbody>
            </table>
          </div>
        </TabsContent>

        <TabsContent value="payments" className="mt-5">
          <div className="ss-card p-5 overflow-x-auto">
            <SectionTitle title={`Payments (${payments.length})`} />
            <table className="ss-table">
              <thead><tr><th>Date</th><th>Type</th><th>Description</th><th>Party</th><th className="text-right">Amount</th></tr></thead>
              <tbody>
                {payments.map((p) => (
                  <tr key={p.id}>
                    <td>{fmtDate(p.date)}</td>
                    <td><Chip className={p.type === "CLIENT_RECEIVED" ? "bg-emerald-100 text-emerald-700" : "bg-orange-100 text-orange-700"}>{p.type.replace("_", " ")}</Chip></td>
                    <td>{p.description}</td>
                    <td>{p.party || "—"}</td>
                    <td className="text-right font-bold">{inr(p.amount)}</td>
                  </tr>
                ))}
                {payments.length === 0 && <tr><td colSpan={5} className="text-center text-gray-500 py-6">No payments.</td></tr>}
              </tbody>
            </table>
          </div>
        </TabsContent>

        <TabsContent value="reports" className="mt-5">
          <div className="space-y-4">
            {reports.map((r) => (
              <div key={r.id} className="ss-card p-5">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="text-xs font-bold uppercase tracking-wider text-[#F97316]">{fmtDate(r.date)}</div>
                    <h3 className="font-display font-bold text-lg mt-1">{r.created_by_name || "Supervisor"}</h3>
                  </div>
                </div>
                <p className="mt-3 text-sm text-gray-700">{r.notes}</p>
                {r.completed_tasks?.length > 0 && (
                  <div className="mt-4">
                    <div className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-1">Completed</div>
                    <ul className="text-sm text-gray-700 list-disc list-inside space-y-0.5">{r.completed_tasks.map((t, i) => <li key={i}>{t}</li>)}</ul>
                  </div>
                )}
                {r.issues?.length > 0 && (
                  <div className="mt-4">
                    <div className="text-xs font-bold uppercase tracking-wider text-red-600 mb-1">Issues</div>
                    <ul className="text-sm text-gray-700 list-disc list-inside space-y-0.5">{r.issues.map((t, i) => <li key={i}>{t}</li>)}</ul>
                  </div>
                )}
                {r.media_urls?.length > 0 && (
                  <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-2">
                    {r.media_urls.map((m, i) => (
                      m.type === "video" ? (
                        <video key={m.public_id || m.url} src={m.url} controls className="rounded-lg h-32 w-full object-cover" />
                      ) : (
                        <img key={m.public_id || m.url} src={m.url} alt="" className="rounded-lg h-32 w-full object-cover" />
                      )
                    ))}
                  </div>
                )}
              </div>
            ))}
            {reports.length === 0 && <div className="ss-card p-10 text-center text-gray-500">No daily reports yet.</div>}
          </div>
        </TabsContent>

        {user.role === "CONTRACTOR" && (
          <TabsContent value="ai" className="mt-5">
            <div className="ss-card p-6">
              <div className="flex items-center gap-2">
                <Sparkles className="h-5 w-5 text-[#F97316]" />
                <h3 className="font-display text-lg font-bold">AI Insights</h3>
              </div>
              <p className="text-sm text-gray-500 mt-1">Powered by Claude Sonnet 4.5</p>
              <div className="mt-4 flex flex-wrap gap-2">
                {[
                  ["material_estimate", "Material Estimation"],
                  ["progress_summary", "Progress Summary"],
                  ["delay_prediction", "Delay Prediction"],
                  ["expense_analysis", "Expense Analysis"],
                ].map(([k, l]) => (
                  <button key={k} disabled={aiBusy} onClick={() => runAI(k)} className="ss-btn-outline" data-testid={`ai-${k}`}>
                    {aiBusy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />} {l}
                  </button>
                ))}
              </div>
              {insight && (
                <div className="mt-5 p-5 bg-gray-50 rounded-lg border border-gray-200">
                  <div className="text-xs font-bold uppercase tracking-wider text-[#F97316] mb-2">{insight.kind.replace("_", " ")}</div>
                  <pre className="text-sm text-gray-700 whitespace-pre-wrap font-sans leading-relaxed">{insight.text}</pre>
                </div>
              )}
            </div>
          </TabsContent>
        )}
      </Tabs>
    </div>
  );
}
