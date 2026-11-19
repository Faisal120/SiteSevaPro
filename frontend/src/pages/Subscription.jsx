import React from "react";
import { CheckCircle2, Crown, Calendar, Copy, Upload, Loader2, AlertCircle, ExternalLink } from "lucide-react";
import { api, uploadToCloudinary } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { PLAN_FEATURES, inr, fmtDate, UPI_PAYEE_NAME } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Chip } from "@/components/dashboard/Primitives";

export default function Subscription() {
  const { user, setUser } = useAuth();
  const [sub, setSub] = React.useState(null);
  const [cfg, setCfg] = React.useState(null);
  const [my, setMy] = React.useState([]);
  const [payOpen, setPayOpen] = React.useState({ open: false, plan: null });

  const load = async () => {
    const [s, c, m] = await Promise.all([
      api.get("/subscription"),
      api.get("/payment/config"),
      api.get("/payment/my"),
    ]);
    setSub(s.data); setCfg(c.data); setMy(m.data);
  };
  React.useEffect(() => { load(); }, []);

  const current = sub?.plan || user.plan || "FREE";
  const hasPending = my.some(p => p.status === "PENDING");

  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Subscription</h1>
        <p className="text-sm text-gray-500 mt-1">Manage your plan via UPI payment.</p>
      </div>

      <div className="ss-card p-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="h-14 w-14 rounded-xl bg-[#3B82F6] text-white flex items-center justify-center"><Crown className="h-6 w-6" /></div>
            <div>
              <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Current plan</div>
              <div className="font-display text-2xl font-extrabold">{PLAN_FEATURES[current]?.name || current}</div>
              {sub?.expires_at && <div className="text-xs text-gray-500 flex items-center gap-1 mt-0.5"><Calendar className="h-3 w-3" /> Renews {fmtDate(sub.expires_at)}</div>}
            </div>
          </div>
          {hasPending && (
            <div className="ss-chip bg-yellow-100 text-yellow-800 px-3 py-1.5"><Loader2 className="h-3.5 w-3.5 animate-spin" /> Payment under verification</div>
          )}
        </div>
      </div>

      <div className="grid md:grid-cols-3 gap-5">
        {Object.entries(PLAN_FEATURES).map(([k, p]) => {
          const isCurrent = current === k;
          return (
            <div key={k} className={`rounded-2xl border p-6 ${k === "PREMIUM" ? "border-blue-400 bg-[#101b30]" : "border-[#30323a] bg-[#111214]"}`}>
              <div className="flex items-center justify-between">
                <h3 className="font-display text-xl font-extrabold text-white">{p.name}</h3>
                {isCurrent && <span className="ss-chip bg-blue-500/15 text-blue-200">Active</span>}
              </div>
              <div className="mt-3 font-display text-3xl font-extrabold text-white">
                {p.price === 0 ? "₹0" : `₹${p.price.toLocaleString("en-IN")}`}
                <span className="text-sm font-medium text-gray-400">/mo</span>
              </div>
              <ul className="mt-5 space-y-1.5 text-sm text-gray-300">
                {p.features.map((f) => (<li key={f} className="flex items-start gap-2"><CheckCircle2 className="mt-0.5 h-4 w-4 text-blue-400" /> {f}</li>))}
              </ul>
              <button
                disabled={isCurrent || hasPending || k === "FREE"}
                onClick={() => setPayOpen({ open: true, plan: k })}
                className={`mt-5 w-full rounded-lg px-5 py-2.5 text-sm font-semibold transition-all ${
                  isCurrent || k === "FREE" ? "cursor-not-allowed border border-[#363941] bg-[#1b1d22] text-slate-400" :
                  "bg-blue-500 text-white hover:bg-blue-600"
                }`}
                data-testid={`sub-upgrade-${k.toLowerCase()}`}
              >
                {isCurrent ? (k === "ENTERPRISE" ? "Renew Enterprise" : "Current plan") : k === "FREE" ? "Default plan" : hasPending ? "Pending verification" : "Pay via UPI"}
              </button>
            </div>
          );
        })}
      </div>

      {my.length > 0 && (
        <div className="ss-card p-5 overflow-x-auto">
          <div className="font-display text-lg font-bold mb-3">Payment History</div>
          <table className="ss-table">
            <thead><tr><th>Date</th><th>Plan</th><th>Amount</th><th>UTR</th><th>Status</th></tr></thead>
            <tbody>
              {my.map((p) => (
                <tr key={p.id}>
                  <td>{fmtDate(p.created_at)}</td>
                  <td>{p.plan}</td>
                  <td className="font-bold">{inr(p.amount)}</td>
                  <td className="font-mono text-xs">{p.utr}</td>
                  <td><Chip className={p.status === "APPROVED" ? "bg-emerald-100 text-emerald-700" : p.status === "REJECTED" ? "bg-red-100 text-red-700" : "bg-yellow-100 text-yellow-800"}>{p.status}</Chip></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Dialog open={payOpen.open} onOpenChange={(o) => setPayOpen({ ...payOpen, open: o })}>
        {payOpen.plan && cfg && <UpiPayDialog plan={payOpen.plan} cfg={cfg} onDone={() => { setPayOpen({ open: false, plan: null }); load(); }} />}
      </Dialog>
    </div>
  );
}

function UpiPayDialog({ plan, cfg, onDone }) {
  const amount = cfg.prices[plan];
  const upi = cfg.upi_id;
  const upiUrl = `upi://pay?pa=${encodeURIComponent(upi)}&pn=${encodeURIComponent(cfg.payee_name)}&am=${amount}&cu=INR&tn=${encodeURIComponent(plan + " plan")}`;
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(upiUrl)}`;
  const [step, setStep] = React.useState(1);
  const [utr, setUtr] = React.useState("");
  const [shot, setShot] = React.useState("");
  const [uploading, setUploading] = React.useState(false);
  const [busy, setBusy] = React.useState(false);
  const handleFile = async (file) => {
    if (!file) return;
    setUploading(true);
    try {
      const u = await uploadToCloudinary(file, "siteseva/payments");
      setShot(u.url);
      toast.success("Screenshot uploaded");
    } catch { toast.error("Upload failed"); }
    finally { setUploading(false); }
  };
  const submit = async () => {
    if (!utr.trim() || utr.trim().length < 4) { toast.error("Enter the UTR / Transaction ID"); return; }
    setBusy(true);
    try {
      await api.post("/payment/request", { plan, utr: utr.trim(), screenshot_url: shot });
      toast.success("Submitted! Admin will verify shortly.");
      onDone();
    } catch (e) { toast.error(e?.response?.data?.detail || "Failed"); }
    finally { setBusy(false); }
  };
  return (
    <DialogContent className="max-w-2xl">
      <DialogHeader><DialogTitle>Pay ₹{amount.toLocaleString("en-IN")} for {plan === "PREMIUM" ? "Pro" : "Pro Plus"}</DialogTitle></DialogHeader>
      <div className="grid md:grid-cols-2 gap-6 mt-2">
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-2">Step 1 · Pay via UPI</div>
          <div className="ss-card p-4 flex flex-col items-center">
            <img src={qrUrl} alt="UPI QR" className="w-56 h-56 rounded-lg" />
            <a href={upiUrl} className="ss-btn-accent w-full mt-3 text-center justify-center" data-testid="upi-pay-link">
              Open in UPI app <ExternalLink className="h-4 w-4" />
            </a>
            <div className="mt-3 w-full bg-gray-50 rounded-lg p-2.5 flex items-center justify-between">
              <span className="text-xs font-mono">{upi}</span>
              <button onClick={() => { navigator.clipboard.writeText(upi); toast.success("Copied"); }} className="text-gray-500 hover:text-[#171717]"><Copy className="h-3.5 w-3.5" /></button>
            </div>
          </div>
        </div>
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-2">Step 2 · Confirm payment</div>
          <div className="ss-card p-4 space-y-3">
            <div>
              <label className="text-xs font-bold uppercase text-gray-500">UTR / Transaction ID</label>
              <input className="ss-input mt-1" placeholder="123456789012" value={utr} onChange={(e) => setUtr(e.target.value)} data-testid="upi-utr" />
              <p className="text-[11px] text-gray-500 mt-1">Find this in your UPI app after payment.</p>
            </div>
            <div>
              <label className="text-xs font-bold uppercase text-gray-500">Screenshot (optional)</label>
              <label className="mt-1 flex flex-col items-center justify-center border-2 border-dashed border-gray-300 rounded-lg p-4 cursor-pointer hover:border-[#3B82F6] hover:bg-blue-50/30">
                {uploading ? <Loader2 className="h-5 w-5 text-[#3B82F6] animate-spin" /> : <Upload className="h-5 w-5 text-gray-500" />}
                <span className="text-xs text-gray-500 mt-2">Upload payment screenshot</span>
                <input type="file" accept="image/*" hidden onChange={(e) => handleFile(e.target.files[0])} data-testid="upi-screenshot" />
              </label>
              {shot && <div className="mt-2 text-xs text-emerald-600">✓ Uploaded</div>}
            </div>
            <button disabled={busy || uploading} onClick={submit} className="ss-btn-accent w-full" data-testid="upi-submit">
              {busy ? "Submitting…" : "Submit for verification"}
            </button>
            <div className="text-[11px] text-gray-500 flex items-start gap-1.5">
              <AlertCircle className="h-3.5 w-3.5 text-[#3B82F6] shrink-0 mt-0.5" />
              <span>Admin verifies within 24 hours. Plan activates immediately after approval.</span>
            </div>
          </div>
        </div>
      </div>
    </DialogContent>
  );
}
