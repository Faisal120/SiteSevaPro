import React from "react";
import { Plus, Fuel, Truck, Wrench, Coffee, MoreHorizontal, Receipt } from "lucide-react";
import { api, uploadToCloudinary } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { StatCard, SectionTitle, EmptyState, Chip } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid } from "recharts";

const CAT_ICON = { FUEL: Fuel, TRANSPORT: Truck, EQUIPMENT: Wrench, FOOD: Coffee, MISC: MoreHorizontal };
const CAT_COLOR = { FUEL: "bg-blue-100 text-blue-700", TRANSPORT: "bg-blue-100 text-blue-700", EQUIPMENT: "bg-purple-100 text-purple-700", FOOD: "bg-yellow-100 text-yellow-800", MISC: "bg-gray-100 text-gray-700" };
const COLORS = ["#3B82F6", "#171717", "#2563EB", "#22C55E", "#94A3B8"];

export default function Expenses() {
  const { user } = useAuth();
  const [list, setList] = React.useState([]);
  const [report, setReport] = React.useState(null);
  const [sites, setSites] = React.useState([]);
  const [filter, setFilter] = React.useState({ site: "ALL", period: "ALL" });
  const [open, setOpen] = React.useState(false);

  const load = async () => {
    const params = new URLSearchParams();
    if (filter.site !== "ALL") params.set("site_id", filter.site);
    if (filter.period !== "ALL") params.set("period", filter.period);
    const [e, s] = await Promise.all([
      api.get(`/expenses?${params}`),
      api.get("/sites"),
    ]);
    setList(e.data); setSites(s.data);
    if (user.role === "CONTRACTOR") {
      const r = await api.get("/expenses/report" + (filter.site !== "ALL" ? `?site_id=${filter.site}` : ""));
      setReport(r.data);
    }
  };
  React.useEffect(() => { load(); /* eslint-disable-next-line */ }, [filter]);

  const total = list.reduce((a, b) => a + b.amount, 0);
  const today = list.filter(e => e.date === new Date().toISOString().slice(0,10)).reduce((a,b)=>a+b.amount,0);
  const cnt = list.length;

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Site Expenses</h1>
          <p className="text-sm text-gray-500 mt-1">Fuel, transport, equipment, food & miscellaneous.</p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={filter.site} onValueChange={(v) => setFilter({ ...filter, site: v })}>
            <SelectTrigger className="w-44" data-testid="exp-site"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">All sites</SelectItem>
              {sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}
            </SelectContent>
          </Select>
          <Select value={filter.period} onValueChange={(v) => setFilter({ ...filter, period: v })}>
            <SelectTrigger className="w-36" data-testid="exp-period"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">All time</SelectItem>
              <SelectItem value="today">Today</SelectItem>
              <SelectItem value="month">This month</SelectItem>
            </SelectContent>
          </Select>
          {user.role !== "CLIENT" && (
            <Dialog open={open} onOpenChange={setOpen}>
              <DialogTrigger asChild>
                <button className="ss-btn-accent" data-testid="exp-add"><Plus className="h-4 w-4" /> Add Expense</button>
              </DialogTrigger>
              <ExpenseForm sites={sites} onDone={() => { setOpen(false); load(); }} />
            </Dialog>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <StatCard label="Total Expenses" value={inr(total)} icon={Receipt} accent="blue" testId="exp-stat-total" />
        <StatCard label="Today" value={inr(today)} icon={Receipt} accent="ink" testId="exp-stat-today" />
        <StatCard label="Entries" value={cnt} icon={Receipt} accent="soft" testId="exp-stat-count" />
      </div>

      {report && (report.by_category?.length > 0 || report.monthly?.length > 0) && (
        <div className="grid lg:grid-cols-2 gap-5">
          <div className="ss-card p-5">
            <SectionTitle title="By Category" />
            <div className="h-64">
              <ResponsiveContainer>
                <PieChart>
                  <Pie data={report.by_category.map(c => ({ name: c._id, value: c.total }))} dataKey="value" nameKey="name" outerRadius={80} innerRadius={40} paddingAngle={3}>
                    {report.by_category.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                  </Pie>
                  <Tooltip formatter={(v) => inr(v)} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>
          <div className="ss-card p-5">
            <SectionTitle title="Monthly Trend" />
            <div className="h-64">
              <ResponsiveContainer>
                <BarChart data={report.monthly.map(m => ({ month: m._id, total: m.total }))}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
                  <XAxis dataKey="month" tick={{ fontSize: 11, fill: "#525252" }} />
                  <YAxis tick={{ fontSize: 11, fill: "#525252" }} />
                  <Tooltip contentStyle={{ background: "#fff", border: "1px solid #E5E7EB", borderRadius: 8 }} formatter={(v) => inr(v)} />
                  <Bar dataKey="total" fill="#3B82F6" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      )}

      {list.length === 0 ? (
        <EmptyState icon={Receipt} title="No expenses logged" description="Track fuel, transport, equipment, food and misc costs." />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Date</th><th>Category</th><th>Description</th><th>Paid by</th><th>Receipt</th><th className="text-right">Amount</th></tr></thead>
            <tbody>
              {list.map((e) => {
                const Icon = CAT_ICON[e.category] || MoreHorizontal;
                return (
                  <tr key={e.id} data-testid={`exp-row-${e.id}`}>
                    <td>{fmtDate(e.date)}</td>
                    <td><Chip className={CAT_COLOR[e.category]}><Icon className="h-3.5 w-3.5" /> {e.category}</Chip></td>
                    <td>{e.description}</td>
                    <td>{e.paid_by || "—"}</td>
                    <td>{e.receipt_url ? <a href={e.receipt_url} target="_blank" rel="noreferrer" className="text-[#3B82F6] text-xs font-semibold hover:underline">View</a> : "—"}</td>
                    <td className="text-right font-bold">{inr(e.amount)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function ExpenseForm({ sites, onDone }) {
  const [f, setF] = React.useState({
    site_id: sites[0]?.id || "", category: "FUEL", amount: 0,
    description: "", date: new Date().toISOString().slice(0, 10),
    paid_by: "", receipt_url: "",
  });
  const [uploading, setUploading] = React.useState(false);
  const handleFile = async (file) => {
    if (!file) return;
    setUploading(true);
    try {
      const u = await uploadToCloudinary(file, "siteseva/expenses");
      setF((p) => ({ ...p, receipt_url: u.url }));
      toast.success("Receipt uploaded");
    } catch { toast.error("Upload failed"); }
    finally { setUploading(false); }
  };
  const submit = async (e) => {
    e.preventDefault();
    try {
      await api.post("/expenses", { ...f, amount: Number(f.amount) });
      toast.success("Expense saved"); onDone();
    } catch (err) { toast.error(err?.response?.data?.detail || "Failed"); }
  };
  return (
    <DialogContent>
      <DialogHeader><DialogTitle>Add Expense</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4 md:grid-cols-2">
        <div className="md:col-span-2"><label className="text-xs font-bold uppercase text-gray-500">Site</label>
          <Select value={f.site_id} onValueChange={(v) => setF({ ...f, site_id: v })}>
            <SelectTrigger className="mt-1" data-testid="expf-site"><SelectValue /></SelectTrigger>
            <SelectContent>{sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Category</label>
          <Select value={f.category} onValueChange={(v) => setF({ ...f, category: v })}>
            <SelectTrigger className="mt-1" data-testid="expf-cat"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="FUEL">Fuel</SelectItem>
              <SelectItem value="TRANSPORT">Transport</SelectItem>
              <SelectItem value="EQUIPMENT">Equipment</SelectItem>
              <SelectItem value="FOOD">Tea & Food</SelectItem>
              <SelectItem value="MISC">Miscellaneous</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Amount</label><input type="number" required className="ss-input mt-1" value={f.amount} onChange={(e)=>setF({...f, amount:e.target.value})} data-testid="expf-amount" /></div>
        <div className="md:col-span-2"><label className="text-xs font-bold uppercase text-gray-500">Description</label><input required className="ss-input mt-1" value={f.description} onChange={(e)=>setF({...f, description:e.target.value})} data-testid="expf-desc" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Paid by</label><input className="ss-input mt-1" value={f.paid_by} onChange={(e)=>setF({...f, paid_by:e.target.value})} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Date</label><input type="date" required className="ss-input mt-1" value={f.date} onChange={(e)=>setF({...f, date:e.target.value})} /></div>
        <div className="md:col-span-2">
          <label className="text-xs font-bold uppercase text-gray-500">Receipt (optional)</label>
          <input type="file" accept="image/*,.pdf" className="ss-input mt-1" onChange={(e) => handleFile(e.target.files[0])} disabled={uploading} />
          {f.receipt_url && <div className="mt-2 text-xs text-emerald-600">✓ Uploaded</div>}
        </div>
        <button type="submit" disabled={uploading} className="ss-btn-accent md:col-span-2" data-testid="expf-submit">Save</button>
      </form>
    </DialogContent>
  );
}
