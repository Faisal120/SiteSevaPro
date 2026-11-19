import React from "react";
import { Link } from "react-router-dom";
import { CheckCircle2 } from "lucide-react";
import PublicNav from "@/components/PublicNav";
import PublicFooter from "@/components/PublicFooter";
import { PLAN_FEATURES } from "@/lib/constants";

export default function Pricing() {
  return (
    <div className="min-h-screen ss-mesh">
      <PublicNav />
      <section className="py-16 lg:py-24">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto">
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#3B82F6]">Plans</span>
            <h1 className="mt-2 text-4xl sm:text-5xl lg:text-6xl font-extrabold font-display tracking-tight">
              Pricing that scales <span className="text-[#3B82F6]">with your sites</span>.
            </h1>
            <p className="mt-4 text-gray-600">Start free. Pay only when you add more sites and supervisors.</p>
          </div>

          <div className="mt-12 grid gap-6 md:grid-cols-3">
            {Object.entries(PLAN_FEATURES).map(([k, p]) => (
              <div key={k} className={`rounded-2xl p-7 ${p.color} ${k === "PREMIUM" ? "shadow-lg" : "shadow-sm border border-gray-200"}`}>
                {k === "PREMIUM" && (
                  <span className="ss-chip bg-[#3B82F6] text-white mb-4">Most Popular</span>
                )}
                <h3 className={`font-display text-2xl font-extrabold ${k === "ENTERPRISE" ? "text-white" : "text-[#171717]"}`}>{p.name}</h3>
                <div className={`mt-3 text-4xl font-extrabold font-display ${k === "ENTERPRISE" ? "text-white" : "text-[#171717]"}`}>
                  {p.price === 0 ? "₹0" : `₹${p.price.toLocaleString("en-IN")}`}
                  <span className={`text-sm font-medium ${k === "ENTERPRISE" ? "text-gray-300" : "text-gray-500"}`}>/month</span>
                </div>
                <ul className={`mt-6 space-y-2 text-sm ${k === "ENTERPRISE" ? "text-gray-200" : "text-gray-700"}`}>
                  {p.features.map((f) => (
                    <li key={f} className="flex items-start gap-2">
                      <CheckCircle2 className={`h-4 w-4 mt-0.5 ${k === "ENTERPRISE" ? "text-[#3B82F6]" : "text-emerald-500"}`} /> {f}
                    </li>
                  ))}
                </ul>
                <Link
                  to="/register"
                  className={`mt-7 inline-flex justify-center w-full rounded-lg px-5 py-2.5 text-sm font-semibold transition-all ${
                    k === "PREMIUM" ? "bg-[#3B82F6] text-white hover:bg-[#2563EB]" :
                    k === "ENTERPRISE" ? "bg-[#3B82F6] text-white hover:bg-[#2563EB]" :
                    "bg-[#171717] text-white hover:bg-[#262626]"
                  }`}
                  data-testid={`pricing-page-cta-${k.toLowerCase()}`}
                >
                  {k === "FREE" ? "Start Free" : k === "PREMIUM" ? "Choose Premium" : "Contact Sales"}
                </Link>
              </div>
            ))}
          </div>

          <div className="mt-12 ss-card p-6">
            <h3 className="font-display text-xl font-bold">Compare plans</h3>
            <div className="mt-4 overflow-x-auto">
              <table className="ss-table min-w-[600px]">
                <thead>
                  <tr>
                    <th>Feature</th>
                    <th>Free</th>
                    <th className="text-[#3B82F6]">Premium</th>
                    <th>Enterprise</th>
                  </tr>
                </thead>
                <tbody>
                  {[
                    ["Sites", "1", "Unlimited", "Unlimited"],
                    ["Supervisors", "2", "Unlimited", "Unlimited"],
                    ["Client Portal", "—", "✓", "✓"],
                    ["Material Tracking", "Basic", "Full", "Full"],
                    ["AI Insights", "—", "✓", "✓"],
                    ["White-label", "—", "—", "✓"],
                    ["Dedicated Support", "—", "Email", "Priority"],
                  ].map((r) => (
                    <tr key={r[0]}>
                      <td className="font-semibold text-[#171717]">{r[0]}</td>
                      <td>{r[1]}</td>
                      <td className="text-[#3B82F6] font-semibold">{r[2]}</td>
                      <td>{r[3]}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>
      <PublicFooter />
    </div>
  );
}
