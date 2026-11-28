import React from "react";
import { Calendar, CheckCircle2, Crown, Download, Loader2, RefreshCw, ShieldCheck } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { PLAN_FEATURES, fmtDate, inr } from "@/lib/constants";
import { toast } from "sonner";
import { Chip } from "@/components/dashboard/Primitives";

const RAZORPAY_SRC = "https://checkout.razorpay.com/v1/checkout.js";
const activeStatuses = new Set(["CREATED", "PENDING", "AUTHORIZED", "FULFILLING", "FULFILLMENT_FAILED"]);

function loadCheckout() {
  if (window.Razorpay) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const existing = document.querySelector(`script[src="${RAZORPAY_SRC}"]`);
    if (existing) { existing.addEventListener("load", resolve, { once: true }); existing.addEventListener("error", reject, { once: true }); return; }
    const script = document.createElement("script");
    script.src = RAZORPAY_SRC; script.async = true;
    script.onload = resolve; script.onerror = reject;
    document.body.appendChild(script);
  });
}

async function downloadReceipt(payment) {
  const { data: receipt } = await api.get(`/payments/subscription/${payment.id}/receipt`);
  const rows = [
    ["Receipt", receipt.receipt_number || receipt.id], ["Plan", receipt.plan], ["Amount", inr(receipt.amount)],
    ["Status", receipt.status], ["Razorpay payment ID", receipt.razorpay_payment_id || "—"], ["Date", fmtDate(receipt.captured_at || receipt.created_at)],
  ];
  const content = `SiteSeva Pro payment receipt\n\n${rows.map(([k, v]) => `${k}: ${v}`).join("\n")}\n`;
  const anchor = document.createElement("a");
  anchor.href = URL.createObjectURL(new Blob([content], { type: "text/plain;charset=utf-8" }));
  anchor.download = `siteseva-receipt-${receipt.receipt_number || receipt.id}.txt`;
  anchor.click(); window.setTimeout(() => URL.revokeObjectURL(anchor.href), 0);
}

export default function Subscription() {
  const { user } = useAuth();
  const [sub, setSub] = React.useState(null);
  const [history, setHistory] = React.useState([]);
  const [wallet, setWallet] = React.useState(null);
  const [checkoutAvailability, setCheckoutAvailability] = React.useState({ status: "DISABLED", checkout_available: false });
  const [busyPlan, setBusyPlan] = React.useState("");
  const [loading, setLoading] = React.useState(true);

  const load = React.useCallback(async () => {
    setLoading(true);
    try {
      const [subscription, payments, availability, designWallet] = await Promise.all([
        api.get("/subscription"),
        api.get("/payments/subscription/history"),
        api.get("/payments/subscription/checkout-availability"),
        api.get("/design-wallet"),
      ]);
      setSub(subscription.data); setHistory(payments.data || []);
      setCheckoutAvailability(availability.data || { status: "NOT_CONFIGURED", checkout_available: false });
      setWallet(designWallet.data || null);
    } catch (error) { toast.error(error?.response?.data?.detail || "Unable to load subscription billing"); }
    finally { setLoading(false); }
  }, []);
  React.useEffect(() => { load(); }, [load]);

  const checkout = async (plan) => {
    if (!checkoutAvailability.checkout_available) {
      toast.message(checkoutAvailability.status === "RESTRICTED" ? "Checkout is not enabled for this account." : checkoutAvailability.status === "NOT_CONFIGURED" ? "Online payments are not configured." : "Online Payments Coming Soon");
      return;
    }
    setBusyPlan(plan);
    try {
      const { data: order } = await api.post("/payments/subscription/orders", { plan });
      await loadCheckout();
      if (!window.Razorpay) throw new Error("Secure checkout could not be loaded");
      const checkoutInstance = new window.Razorpay({
        key: order.key_id, amount: order.amount, currency: order.currency, order_id: order.order_id,
        name: "SiteSeva Pro", description: `${order.plan} monthly subscription`,
        theme: { color: "#3B82F6" },
        modal: { ondismiss: () => { toast.message("Checkout cancelled. No payment was recorded."); setBusyPlan(""); } },
        handler: async (response) => {
          try {
            const result = await api.post("/payments/subscription/verify", response);
            if (result.data?.status === "CAPTURED") { toast.success("Payment verified and subscription activated."); await load(); }
            else { toast.message("Payment is pending verification. Refresh status shortly."); await load(); }
          } catch (error) { toast.error(error?.response?.data?.detail || "Payment received but verification is pending. Do not pay again."); await load(); }
          finally { setBusyPlan(""); }
        },
      });
      checkoutInstance.on("payment.failed", () => { toast.error("Payment failed. No subscription was activated."); setBusyPlan(""); load(); });
      checkoutInstance.open();
    } catch (error) { toast.error(error?.response?.data?.detail || error.message || "Unable to start secure checkout"); setBusyPlan(""); }
  };

  const current = (sub?.plan || user?.plan || "FREE").toUpperCase();
  const pending = history.some((payment) => activeStatuses.has(payment.status));
  const checkoutAvailable = Boolean(checkoutAvailability.checkout_available);
  return <div className="space-y-6 ss-fade-in">
    <div className="flex flex-wrap items-end justify-between gap-3"><div><h1 className="font-display text-3xl font-extrabold tracking-tight">Subscription</h1><p className="mt-1 text-sm text-gray-500">{checkoutAvailable ? "Plans are activated only after secure Razorpay payment verification." : "Keep using your current plan while online payments are prepared for launch."}</p></div><button onClick={load} disabled={loading} className="ss-chip bg-white/5 text-gray-300 hover:bg-white/10"><RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} />Refresh</button></div>
    {!checkoutAvailable && <div role="status" className="rounded-xl border border-blue-400/30 bg-blue-500/10 px-4 py-3 text-sm font-semibold text-blue-100">{checkoutAvailability.status === "RESTRICTED" ? "Checkout is not enabled for this account." : checkoutAvailability.status === "NOT_CONFIGURED" ? "Online payments are not configured." : "Online Payments Coming Soon"}</div>}
    <div className="ss-card p-6"><div className="flex flex-wrap items-center gap-4"><div className="flex h-14 w-14 items-center justify-center rounded-xl bg-[#3B82F6] text-white"><Crown className="h-6 w-6" /></div><div><div className="text-xs font-bold uppercase tracking-wider text-gray-500">Current plan</div><div className="font-display text-2xl font-extrabold">{PLAN_FEATURES[current]?.name || current}</div>{sub?.expires_at && <div className="mt-0.5 flex items-center gap-1 text-xs text-gray-500"><Calendar className="h-3 w-3" />Valid through {fmtDate(sub.expires_at)}</div>}{wallet && <div className="mt-1 text-xs text-gray-500">AI credits available: {wallet.credits ?? 0}</div>}</div>{pending && <Chip className="ml-auto bg-yellow-500/15 text-yellow-300"><Loader2 className="h-3.5 w-3.5 animate-spin" />Pending verification</Chip>}</div></div>
    <div className="grid gap-5 md:grid-cols-3">{Object.entries(PLAN_FEATURES).map(([code, plan]) => { const isCurrent = current === code; const renew = isCurrent && code !== "FREE"; const purchaseDisabled = code === "FREE" || !checkoutAvailable || Boolean(busyPlan); return <div key={code} className={`rounded-2xl border p-6 ${code === "PREMIUM" ? "border-blue-400 bg-[#101b30]" : "border-[#30323a] bg-[#111214]"}`}><div className="flex items-center justify-between"><h2 className="font-display text-xl font-extrabold text-white">{plan.name}</h2>{isCurrent && <Chip className="bg-blue-500/15 text-blue-200">Current</Chip>}</div><div className="mt-3 font-display text-3xl font-extrabold text-white">{plan.price ? `₹${plan.price.toLocaleString("en-IN")}` : "₹0"}<span className="text-sm font-medium text-gray-400">/month</span></div><ul className="mt-5 space-y-1.5 text-sm text-gray-300">{plan.features.map((feature) => <li key={feature} className="flex gap-2"><CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-blue-400" />{feature}</li>)}</ul><button disabled={purchaseDisabled} onClick={() => checkout(code)} className="mt-5 w-full rounded-lg bg-blue-500 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-600 disabled:cursor-not-allowed disabled:opacity-60">{busyPlan === code ? <span className="inline-flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" />Opening checkout…</span> : code === "FREE" ? "Default plan" : !checkoutAvailable ? "Online Payments Coming Soon" : renew ? "Renew subscription" : `Upgrade to ${plan.name}`}</button></div>; })}</div>
    <section className="ss-card overflow-x-auto p-5"><div className="mb-3 flex items-center gap-2 font-display text-lg font-bold"><ShieldCheck className="h-5 w-5 text-blue-400" />Transaction history</div>{history.length ? <table className="ss-table"><thead><tr><th>Date</th><th>Plan</th><th>Amount</th><th>Payment ID</th><th>Status</th><th /></tr></thead><tbody>{history.map((payment) => <tr key={payment.id}><td>{fmtDate(payment.captured_at || payment.created_at)}</td><td>{payment.plan}</td><td className="font-bold">{inr(payment.amount)}</td><td className="font-mono text-xs">{payment.razorpay_payment_id || "—"}</td><td><Chip className={payment.status === "CAPTURED" ? "bg-emerald-500/15 text-emerald-300" : payment.status === "FAILED" ? "bg-red-500/15 text-red-300" : "bg-yellow-500/15 text-yellow-300"}>{payment.status === "FULFILLING" ? "PENDING VERIFICATION" : payment.status}</Chip></td><td>{["CAPTURED", "REFUNDED", "REFUND_REVIEW_REQUIRED"].includes(payment.status) && <button onClick={() => downloadReceipt(payment).catch(() => toast.error("Receipt is not available right now"))} className="inline-flex items-center gap-1 text-xs font-semibold text-blue-300 hover:text-white"><Download className="h-3.5 w-3.5" />Receipt</button>}</td></tr>)}</tbody></table> : <p className="py-6 text-sm text-gray-500">No online subscription transactions yet.</p>}</section>
  </div>;
}
