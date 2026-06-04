import React from "react";
import { Plus, Wallet, TrendingUp, TrendingDown, Activity } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { StatCard, Chip, EmptyState, SectionTitle } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

const TYPE_CHIP = {
  CLIENT_RECEIVED: "bg-emerald-100 text-emerald-700",
  EXPENSE: "bg-orange-100 text-orange-700",
  LABOUR: "bg-blue-100 text-blue-700",
  MATERIAL: "bg-yellow-100 text-yellow-800",
  SUBSCRIPTION: "bg-purple-100 text-purple-700",
};

export default function Payments() {
  const { user } = useAuth();
  const [list, setList] = React.useState([]);
  const [open, setOpen] = React.useState(false);
  const [sites, setSites] = React.useState([]);

  const load = async () => {
    const [p, s] = await Promise.all([api.get("/payments"), api.get("/sites")]);
    setList(p.data); setSites(s.data);
  };
  React.useEffect(() => { load(); }, []);

  const sumBy = (t) => list.filter((p) => p.type === t).reduce((a, b) => a + b.amount, 0);
  const received = sumBy("CLIENT_RECEIVED");
  const expense = sumBy("EXPENSE") + sumBy("MATERIAL") + sumBy("LABOUR");
  const profit = received - expense;

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Payments</h1>
          <p className="text-sm text-gray-500 mt-1">Client receipts, labour, materials, expenses & P&L.</p>
        </div>
        {user.role === "CONTRACTOR" && (
          <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
              <button className="ss-btn-accent" data-testid="pay-add"><Plus className="h-4 w-4" /> New Entry</button>
            </DialogTrigger>
            <PaymentForm sites={sites} onDone={() => { setOpen(false); load(); }} />
          </Dialog>
        )}
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard label="Total Received" value={inr(received)} icon={TrendingUp} accent="ink" testId="pay-stat-received" />
        <StatCard label="Total Expenses" value={inr(expense)} icon={TrendingDown} accent="orange" testId="pay-stat-expense" />
        <StatCard label="Net Profit" value={inr(profit)} icon={Activity} accent="yellow" testId="pay-stat-profit" />
        <StatCard label="Entries" value={list.length} icon={Wallet} accent="soft" testId="pay-stat-count" />
      </div>

      {list.length === 0 ? (
        <EmptyState icon={Wallet} title="No transactions yet" description="Record your first client receipt or expense." />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <SectionTitle title="Recent Transactions" />
          <table className="ss-table">
            <thead><tr><th>Date</th><th>Type</th><th>Description</th><th>Party</th><th className="text-right">Amount</th></tr></thead>
            <tbody>
              {list.map((p) => (
                <tr key={p.id} data-testid={`pay-row-${p.id}`}>
                  <td>{fmtDate(p.date)}</td>
                  <td><Chip className={TYPE_CHIP[p.type] || "bg-gray-100 text-gray-700"}>{p.type.replace("_", " ")}</Chip></td>
                  <td>{p.description}</td>
                  <td>{p.party || "—"}</td>
                  <td className="text-right font-bold">{inr(p.amount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function PaymentForm({ sites, onDone }) {
  const [f, setF] = React.useState({
    site_id: sites[0]?.id || "", type: "CLIENT_RECEIVED", amount: 0,
    description: "", date: new Date().toISOString().slice(0, 10), party: "",
  });
  const submit = async (e) => {
    e.preventDefault();
    try {
      await api.post("/payments", { ...f, amount: Number(f.amount) });
      toast.success("Saved"); onDone();
    } catch (err) { toast.error(err?.response?.data?.detail || "Failed"); }
  };
  return (
    <DialogContent>
      <DialogHeader><DialogTitle>Add Transaction</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4 md:grid-cols-2">
        <div className="md:col-span-2"><label className="text-xs font-bold uppercase text-gray-500">Site</label>
          <Select value={f.site_id} onValueChange={(v) => setF({ ...f, site_id: v })}>
            <SelectTrigger className="mt-1" data-testid="payf-site"><SelectValue /></SelectTrigger>
            <SelectContent>{sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Type</label>
          <Select value={f.type} onValueChange={(v) => setF({ ...f, type: v })}>
            <SelectTrigger className="mt-1" data-testid="payf-type"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="CLIENT_RECEIVED">Client Received</SelectItem>
              <SelectItem value="EXPENSE">Expense</SelectItem>
              <SelectItem value="LABOUR">Labour Payment</SelectItem>
              <SelectItem value="MATERIAL">Material Purchase</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Amount</label><input type="number" required className="ss-input mt-1" value={f.amount} onChange={(e)=>setF({...f, amount:e.target.value})} data-testid="payf-amount" /></div>
        <div className="md:col-span-2"><label className="text-xs font-bold uppercase text-gray-500">Description</label><input required className="ss-input mt-1" value={f.description} onChange={(e)=>setF({...f, description:e.target.value})} data-testid="payf-desc" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Party</label><input className="ss-input mt-1" value={f.party} onChange={(e)=>setF({...f, party:e.target.value})} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Date</label><input type="date" required className="ss-input mt-1" value={f.date} onChange={(e)=>setF({...f, date:e.target.value})} /></div>
        <button type="submit" className="ss-btn-accent md:col-span-2" data-testid="payf-submit">Save</button>
      </form>
    </DialogContent>
  );
}
