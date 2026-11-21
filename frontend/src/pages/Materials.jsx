import React from "react";
import { Plus, Package, AlertTriangle, ArrowDownToLine, ArrowUpFromLine } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { SectionTitle, EmptyState, Chip } from "@/components/dashboard/Primitives";
import { inr, fmtDate, MATERIAL_CATEGORIES } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid } from "recharts";

export default function Materials() {
  const { user } = useAuth();
  const [items, setItems] = React.useState([]);
  const [sites, setSites] = React.useState([]);
  const [siteId, setSiteId] = React.useState("");
  const [openMat, setOpenMat] = React.useState(false);
  const [openTxn, setOpenTxn] = React.useState({ open: false, material: null });

  React.useEffect(() => {
    api.get("/sites").then((sts) => {
      setSites(sts.data);
      setSiteId((current) => current || sts.data[0]?.id || "");
    });
  }, []);
  React.useEffect(() => {
    if (siteId) api.get(`/materials?site_id=${siteId}`).then((r) => setItems(r.data));
  }, [siteId, openMat, openTxn.open]);

  const stockChart = items.map((m) => ({ name: m.name.slice(0, 10), stock: m.stock }));
  const lowCount = items.filter((m) => m.stock < m.low_stock_threshold).length;

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Materials</h1>
          <p className="text-sm text-gray-500 mt-1">Inward, outward, stock & vendor invoices.</p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={siteId} onValueChange={setSiteId}>
            <SelectTrigger className="w-56" data-testid="mat-site"><SelectValue placeholder="Select site" /></SelectTrigger>
            <SelectContent>{sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent>
          </Select>
          {user.role !== "CLIENT" && siteId && (
            <Dialog open={openMat} onOpenChange={setOpenMat}>
              <DialogTrigger asChild>
                <button className="ss-btn-accent" data-testid="mat-add"><Plus className="h-4 w-4" /> Add Material</button>
              </DialogTrigger>
              <MaterialForm siteId={siteId} onDone={() => setOpenMat(false)} />
            </Dialog>
          )}
        </div>
      </div>

      {lowCount > 0 && (
        <div className="ss-card p-4 border-l-4 border-l-[#3B82F6] flex items-center gap-3">
          <AlertTriangle className="h-5 w-5 text-[#3B82F6]" />
          <span className="text-sm"><span className="font-bold">{lowCount}</span> material{lowCount > 1 && "s"} below stock threshold.</span>
        </div>
      )}

      {items.length > 0 && (
        <div className="ss-card p-5">
          <SectionTitle title="Stock Levels" />
          <div className="h-56">
            <ResponsiveContainer>
              <BarChart data={stockChart}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 11, fill: "#525252" }} />
                <YAxis tick={{ fontSize: 11, fill: "#525252" }} />
                <Tooltip contentStyle={{ background: "#fff", border: "1px solid #E5E7EB", borderRadius: 8 }} />
                <Bar dataKey="stock" fill="#171717" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {items.length === 0 ? (
        <EmptyState icon={Package} title="No materials yet" description="Track cement, steel, sand and more." />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <table className="ss-table">
            <thead><tr><th>Name</th><th>Category</th><th>Stock</th><th>Rate</th><th>Status</th><th className="text-right">Action</th></tr></thead>
            <tbody>
              {items.map((m) => (
                <tr key={m.id}>
                  <td className="font-semibold">{m.name}</td>
                  <td><Chip className="bg-gray-100 text-gray-700">{m.category}</Chip></td>
                  <td>{m.stock} {m.unit}</td>
                  <td>{inr(m.rate)}/{m.unit}</td>
                  <td>{m.stock < m.low_stock_threshold ? <Chip className="bg-red-100 text-red-700">Low stock</Chip> : <Chip className="bg-emerald-100 text-emerald-700">OK</Chip>}</td>
                  <td className="text-right">
                    {user.role !== "CLIENT" && (
                      <button onClick={() => setOpenTxn({ open: true, material: m })} className="text-xs font-semibold text-[#3B82F6] hover:underline" data-testid={`mat-txn-${m.id}`}>
                        Inward / Outward
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Dialog open={openTxn.open} onOpenChange={(o) => setOpenTxn({ ...openTxn, open: o })}>
        {openTxn.material && <TxnForm material={openTxn.material} siteId={siteId} onDone={() => setOpenTxn({ open: false, material: null })} />}
      </Dialog>
    </div>
  );
}

function MaterialForm({ siteId, onDone }) {
  const [f, setF] = React.useState({ name: "", category: "Cement", unit: "bags", stock: 0, low_stock_threshold: 10, rate: 0 });
  const submit = async (e) => {
    e.preventDefault();
    try {
      await api.post("/materials", { ...f, site_id: siteId, stock: Number(f.stock), low_stock_threshold: Number(f.low_stock_threshold), rate: Number(f.rate) });
      toast.success("Material added"); onDone();
    } catch { toast.error("Failed"); }
  };
  return (
    <DialogContent>
      <DialogHeader><DialogTitle>Add Material</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4 md:grid-cols-2">
        <div className="md:col-span-2"><label className="text-xs font-bold uppercase text-gray-500">Name</label><input required className="ss-input mt-1" value={f.name} onChange={(e)=>setF({...f, name:e.target.value})} data-testid="matf-name" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Category</label>
          <Select value={f.category} onValueChange={(v)=>setF({...f, category:v})}><SelectTrigger className="mt-1" data-testid="matf-category"><SelectValue /></SelectTrigger><SelectContent>{MATERIAL_CATEGORIES.map(c=><SelectItem key={c} value={c}>{c}</SelectItem>)}</SelectContent></Select>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Unit</label><input className="ss-input mt-1" value={f.unit} onChange={(e)=>setF({...f, unit:e.target.value})} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Stock</label><input type="number" className="ss-input mt-1" value={f.stock} onChange={(e)=>setF({...f, stock:e.target.value})} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Low Threshold</label><input type="number" className="ss-input mt-1" value={f.low_stock_threshold} onChange={(e)=>setF({...f, low_stock_threshold:e.target.value})} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Rate (₹/{f.unit})</label><input type="number" className="ss-input mt-1" value={f.rate} onChange={(e)=>setF({...f, rate:e.target.value})} /></div>
        <button type="submit" className="ss-btn-accent md:col-span-2" data-testid="matf-submit">Save</button>
      </form>
    </DialogContent>
  );
}

function TxnForm({ material, siteId, onDone }) {
  const [f, setF] = React.useState({ type: "INWARD", quantity: 0, rate: material.rate, vendor: "", note: "" });
  const submit = async (e) => {
    e.preventDefault();
    try {
      await api.post("/material-txns", { ...f, material_id: material.id, site_id: siteId, quantity: Number(f.quantity), rate: Number(f.rate || 0) });
      toast.success("Transaction recorded"); onDone();
    } catch { toast.error("Failed"); }
  };
  return (
    <DialogContent>
      <DialogHeader><DialogTitle>{material.name} — Transaction</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4">
        <div className="flex gap-2">
          <button type="button" onClick={()=>setF({...f, type:"INWARD"})} className={`flex-1 py-2 rounded-lg font-semibold text-sm flex items-center justify-center gap-2 ${f.type==="INWARD"?"bg-emerald-100 text-emerald-700 border-2 border-emerald-300":"bg-gray-50 text-gray-600 border-2 border-transparent"}`} data-testid="txn-inward"><ArrowDownToLine className="h-4 w-4" /> Inward</button>
          <button type="button" onClick={()=>setF({...f, type:"OUTWARD"})} className={`flex-1 py-2 rounded-lg font-semibold text-sm flex items-center justify-center gap-2 ${f.type==="OUTWARD"?"bg-blue-100 text-blue-700 border-2 border-blue-300":"bg-gray-50 text-gray-600 border-2 border-transparent"}`} data-testid="txn-outward"><ArrowUpFromLine className="h-4 w-4" /> Outward</button>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Quantity ({material.unit})</label><input type="number" required className="ss-input mt-1" value={f.quantity} onChange={(e)=>setF({...f, quantity:e.target.value})} data-testid="txn-qty" /></div>
        {f.type === "INWARD" && (
          <>
            <div><label className="text-xs font-bold uppercase text-gray-500">Rate (₹/{material.unit})</label><input type="number" className="ss-input mt-1" value={f.rate} onChange={(e)=>setF({...f, rate:e.target.value})} /></div>
            <div><label className="text-xs font-bold uppercase text-gray-500">Vendor</label><input className="ss-input mt-1" value={f.vendor} onChange={(e)=>setF({...f, vendor:e.target.value})} /></div>
          </>
        )}
        <div><label className="text-xs font-bold uppercase text-gray-500">Note</label><input className="ss-input mt-1" value={f.note} onChange={(e)=>setF({...f, note:e.target.value})} /></div>
        <button type="submit" className="ss-btn-accent" data-testid="txn-submit">Save Transaction</button>
      </form>
    </DialogContent>
  );
}
