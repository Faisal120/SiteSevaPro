import React from "react";
import { Wallet, TrendingUp, TrendingDown, IndianRupee, ArrowRight, X } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { StatCard, SectionTitle, EmptyState, Chip } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function LabourWallet() {
  const nav = useNavigate();
  const [data, setData] = React.useState(null);
  const [sites, setSites] = React.useState([]);
  const [siteId, setSiteId] = React.useState("ALL");
  const [payOpen, setPayOpen] = React.useState({ open: false, row: null });

  const load = React.useCallback(async () => {
    const params = siteId !== "ALL" ? `?site_id=${siteId}` : "";
    const [w, s] = await Promise.all([api.get(`/wallet/summary${params}`), api.get("/sites")]);
    setData(w.data); setSites(s.data);
  }, [siteId]);
  React.useEffect(() => { load(); }, [load]);

  if (!data) return <div className="p-10 text-center text-gray-500">Loading…</div>;

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Labour Wallet</h1>
          <p className="text-sm text-gray-500 mt-1">Earnings, payments and balance per worker — auto-updated from attendance.</p>
        </div>
        <Select value={siteId} onValueChange={setSiteId}>
          <SelectTrigger className="w-56" data-testid="wallet-site"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All sites</SelectItem>
            {sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <StatCard label="Total Earned" value={inr(data.total_earned)} icon={TrendingUp} accent="ink" testId="wallet-stat-earned" />
        <StatCard label="Total Paid" value={inr(data.total_paid)} icon={TrendingDown} accent="blue" testId="wallet-stat-paid" />
        <StatCard label="Outstanding Balance" value={inr(data.total_balance)} icon={Wallet} accent="yellow" testId="wallet-stat-balance" />
      </div>

      {data.rows.length === 0 ? (
        <EmptyState icon={Wallet} title="No labour records" description="Add labour and mark attendance to start tracking the wallet." />
      ) : (
        <div className="ss-card p-5 overflow-x-auto">
          <SectionTitle title="Per-worker balance" />
          <table className="ss-table">
            <thead><tr><th>Worker</th><th>Role</th><th>Daily wage</th><th>Earned</th><th>Paid</th><th>Balance</th><th className="text-right">Action</th></tr></thead>
            <tbody>
              {data.rows.map((r) => (
                <tr key={r.id} data-testid={`wallet-row-${r.id}`}>
                  <td className="font-semibold">{r.name}</td>
                  <td><Chip className="bg-gray-100 text-gray-700">{r.role}</Chip></td>
                  <td>{inr(r.daily_wage)}</td>
                  <td className="font-semibold text-emerald-600">{inr(r.wallet.total_earned)}</td>
                  <td className="text-gray-700">{inr(r.wallet.total_paid)}</td>
                  <td className={`font-bold ${r.wallet.balance > 0 ? "text-[#3B82F6]" : "text-gray-500"}`}>{inr(r.wallet.balance)}</td>
                  <td className="text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => nav(`/app/labour/wallet/${r.id}`)} className="text-xs font-semibold text-[#171717] hover:underline" data-testid={`wallet-view-${r.id}`}>
                        Ledger <ArrowRight className="inline h-3 w-3" />
                      </button>
                      <button onClick={() => setPayOpen({ open: true, row: r })} className="ss-chip bg-emerald-100 text-emerald-700 hover:bg-emerald-200" data-testid={`wallet-pay-${r.id}`}>
                        <IndianRupee className="h-3 w-3" /> Pay
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Dialog open={payOpen.open} onOpenChange={(o) => setPayOpen({ ...payOpen, open: o })}>
        {payOpen.row && <PayForm row={payOpen.row} onDone={() => { setPayOpen({ open: false, row: null }); load(); }} />}
      </Dialog>
    </div>
  );
}

function PayForm({ row, onDone }) {
  const [f, setF] = React.useState({ amount: row.wallet.balance || 0, type: "PAYMENT", note: "" });
  const submit = async (e) => {
    e.preventDefault();
    try {
      await api.post("/wallet/pay", { labour_id: row.id, amount: Number(f.amount), type: f.type, note: f.note });
      toast.success("Payment recorded"); onDone();
    } catch (err) { toast.error(err?.response?.data?.detail || "Failed"); }
  };
  return (
    <DialogContent>
      <DialogHeader><DialogTitle>Pay {row.name}</DialogTitle></DialogHeader>
      <div className="text-sm text-gray-500 mb-3">Outstanding: <span className="font-bold text-[#3B82F6]">{inr(row.wallet.balance)}</span></div>
      <form onSubmit={submit} className="grid gap-4">
        <div><label className="text-xs font-bold uppercase text-gray-500">Type</label>
          <Select value={f.type} onValueChange={(v) => setF({ ...f, type: v })}>
            <SelectTrigger className="mt-1" data-testid="payform-type"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="PAYMENT">Payment (settle wages)</SelectItem>
              <SelectItem value="ADVANCE">Advance</SelectItem>
              <SelectItem value="BONUS">Bonus (credit)</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Amount (₹)</label><input type="number" required className="ss-input mt-1" value={f.amount} onChange={(e)=>setF({...f, amount:e.target.value})} data-testid="payform-amount" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Note</label><input className="ss-input mt-1" value={f.note} onChange={(e)=>setF({...f, note:e.target.value})} /></div>
        <button type="submit" className="ss-btn-accent" data-testid="payform-submit">Record</button>
      </form>
    </DialogContent>
  );
}
