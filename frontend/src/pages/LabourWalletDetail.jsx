import React from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, TrendingUp, TrendingDown, Wallet } from "lucide-react";
import { api } from "@/lib/api";
import { StatCard, SectionTitle, Chip } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";

const TYPE_CHIP = {
  EARNING: "bg-emerald-100 text-emerald-700",
  PAYMENT: "bg-blue-100 text-blue-700",
  ADVANCE: "bg-blue-100 text-blue-700",
  BONUS: "bg-yellow-100 text-yellow-800",
};

export default function LabourWalletDetail() {
  const { labourId } = useParams();
  const nav = useNavigate();
  const [data, setData] = React.useState(null);
  React.useEffect(() => { api.get(`/wallet/labour/${labourId}`).then((r) => setData(r.data)); }, [labourId]);
  if (!data) return <div className="p-10 text-center text-gray-500">Loading…</div>;
  const { labour, wallet, ledger } = data;
  return (
    <div className="space-y-6 ss-fade-in">
      <button onClick={() => nav(-1)} className="text-sm text-gray-500 hover:text-[#171717] flex items-center gap-1"><ArrowLeft className="h-4 w-4" /> Back</button>
      <div className="ss-card p-6 flex flex-wrap items-center gap-6">
        <div className="h-14 w-14 rounded-xl bg-[#3B82F6] text-white flex items-center justify-center font-display text-xl font-extrabold">{labour.name.slice(0,2).toUpperCase()}</div>
        <div className="flex-1">
          <h1 className="font-display text-2xl font-extrabold">{labour.name}</h1>
          <div className="text-sm text-gray-500 flex flex-wrap gap-3 mt-1">
            <span>{labour.role}</span>
            <span>· Daily wage {inr(labour.daily_wage)}</span>
            {labour.mobile && <span>· {labour.mobile}</span>}
          </div>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <StatCard label="Earned" value={inr(wallet.total_earned)} icon={TrendingUp} accent="ink" />
        <StatCard label="Paid" value={inr(wallet.total_paid)} icon={TrendingDown} accent="blue" />
        <StatCard label="Balance" value={inr(wallet.balance)} icon={Wallet} accent="yellow" />
      </div>
      <div className="ss-card p-5 overflow-x-auto">
        <SectionTitle title="Ledger" subtitle={`${ledger.length} entries`} />
        <table className="ss-table">
          <thead><tr><th>Date</th><th>Type</th><th>Note</th><th className="text-right">Amount</th></tr></thead>
          <tbody>
            {ledger.map((l) => (
              <tr key={l.id}>
                <td>{fmtDate(l.date)}</td>
                <td><Chip className={TYPE_CHIP[l.type] || "bg-gray-100 text-gray-700"}>{l.type}</Chip></td>
                <td>{l.note || "—"}</td>
                <td className={`text-right font-bold ${l.type === "EARNING" || l.type === "BONUS" ? "text-emerald-600" : "text-[#3B82F6]"}`}>
                  {l.type === "EARNING" || l.type === "BONUS" ? "+" : "−"}{inr(l.amount)}
                </td>
              </tr>
            ))}
            {ledger.length === 0 && <tr><td colSpan={4} className="text-center text-gray-500 py-6">No entries yet. Mark attendance to auto-generate earnings.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
