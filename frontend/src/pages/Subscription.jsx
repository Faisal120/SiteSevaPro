import React from "react";
import { CheckCircle2, Crown, Sparkles, Calendar } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { SectionTitle } from "@/components/dashboard/Primitives";
import { PLAN_FEATURES, fmtDate } from "@/lib/constants";
import { toast } from "sonner";

export default function Subscription() {
  const { user, setUser } = useAuth();
  const [sub, setSub] = React.useState(null);
  const [busy, setBusy] = React.useState("");

  const load = async () => { const { data } = await api.get("/subscription"); setSub(data); };
  React.useEffect(() => { load(); }, []);

  const upgrade = async (plan) => {
    setBusy(plan);
    try {
      await api.post(`/subscription/upgrade?plan=${plan}`);
      const me = await api.get("/auth/me");
      setUser(me.data);
      localStorage.setItem("ss_user", JSON.stringify(me.data));
      await load();
      toast.success(`Upgraded to ${plan}. Payment simulated.`);
    } catch (e) { toast.error("Upgrade failed"); }
    finally { setBusy(""); }
  };

  const current = sub?.plan || user.plan || "FREE";

  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Subscription</h1>
        <p className="text-sm text-gray-500 mt-1">Manage your plan and billing.</p>
      </div>

      <div className="ss-card p-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="h-14 w-14 rounded-xl bg-[#F97316] text-white flex items-center justify-center">
              <Crown className="h-6 w-6" />
            </div>
            <div>
              <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Current plan</div>
              <div className="font-display text-2xl font-extrabold">{current}</div>
              {sub?.expires_at && <div className="text-xs text-gray-500 flex items-center gap-1 mt-0.5"><Calendar className="h-3 w-3" /> Renews {fmtDate(sub.expires_at)}</div>}
            </div>
          </div>
          <div className="text-xs text-gray-500 max-w-xs">
            Razorpay integration is simulated for this build. Click upgrade to test the flow.
          </div>
        </div>
      </div>

      <div className="grid md:grid-cols-3 gap-5">
        {Object.entries(PLAN_FEATURES).map(([k, p]) => {
          const isCurrent = current === k;
          return (
            <div key={k} className={`rounded-2xl p-6 ${p.color} ${k === "PREMIUM" ? "shadow-lg" : "shadow-sm border border-gray-200"}`}>
              <div className="flex items-center justify-between">
                <h3 className={`font-display text-xl font-extrabold ${k === "ENTERPRISE" ? "text-white" : "text-[#171717]"}`}>{p.name}</h3>
                {isCurrent && <span className="ss-chip bg-emerald-100 text-emerald-700">Active</span>}
              </div>
              <div className={`mt-3 text-3xl font-extrabold font-display ${k === "ENTERPRISE" ? "text-white" : "text-[#171717]"}`}>
                {p.price === 0 ? "₹0" : `₹${p.price.toLocaleString("en-IN")}`}
                <span className={`text-sm font-medium ${k === "ENTERPRISE" ? "text-gray-300" : "text-gray-500"}`}>/mo</span>
              </div>
              <ul className={`mt-5 space-y-1.5 text-sm ${k === "ENTERPRISE" ? "text-gray-200" : "text-gray-700"}`}>
                {p.features.map((f) => (<li key={f} className="flex items-start gap-2"><CheckCircle2 className={`h-4 w-4 mt-0.5 ${k === "ENTERPRISE" ? "text-[#F97316]" : "text-emerald-500"}`} /> {f}</li>))}
              </ul>
              <button
                disabled={isCurrent || !!busy}
                onClick={() => upgrade(k)}
                className={`mt-5 w-full rounded-lg px-5 py-2.5 text-sm font-semibold transition-all ${
                  isCurrent ? "bg-gray-100 text-gray-400 cursor-not-allowed" :
                  k === "ENTERPRISE" ? "bg-[#F97316] text-white hover:bg-[#EA580C]" :
                  k === "PREMIUM" ? "bg-[#F97316] text-white hover:bg-[#EA580C]" :
                  "bg-[#171717] text-white hover:bg-[#262626]"
                }`}
                data-testid={`sub-upgrade-${k.toLowerCase()}`}
              >
                {isCurrent ? "Current plan" : busy === k ? "Processing…" : "Switch to " + p.name}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}
