import React from "react";
import { Link } from "react-router-dom";
import {
  ArrowRight, Building2, Users, Package, Wallet, FileText, Bell, Sparkles,
  CheckCircle2, ChevronRight, Star, Quote, Plus, Minus, HardHat, ShieldCheck, BarChart3, Camera,
} from "lucide-react";
import PublicNav from "@/components/PublicNav";
import PublicFooter from "@/components/PublicFooter";
import { PLAN_FEATURES, inr } from "@/lib/constants";

const FEATURES = [
  { icon: Building2, title: "Site Management", desc: "Track every site, drawing, milestone and progress in one place." },
  { icon: Users, title: "Labour & Attendance", desc: "Digital muster, daily wages, advances and monthly payroll exports." },
  { icon: Package, title: "Material Inventory", desc: "Inward / outward, vendor invoices, low-stock alerts across categories." },
  { icon: Wallet, title: "Payments & P&L", desc: "Client receipts, expense tracking, automatic profit-loss per site." },
  { icon: Camera, title: "Daily Site Reports", desc: "Supervisor uploads of photos, videos and tasks with a clean timeline." },
  { icon: Sparkles, title: "AI Insights", desc: "Material estimation, delay prediction and expense analysis on tap." },
];

const FAQS = [
  { q: "How does the contractor approval flow work?", a: "Fill the registration form on the site. Our admin reviews your application and manually generates a username and password sent to your email." },
  { q: "Can I run multiple sites on the Free plan?", a: "Free is limited to 1 site and 2 supervisors. Upgrade to Premium for unlimited sites and supervisors." },
  { q: "Do supervisors get a separate login?", a: "Yes. Each supervisor sees only the sites assigned by the contractor — attendance, materials and daily reports." },
  { q: "Can clients track project progress?", a: "Absolutely. Clients log in to a clean portal with timeline, photos, videos and payment history for their project." },
  { q: "Is GST invoicing supported?", a: "Yes. We auto-generate GST-compliant invoices for subscription billing and you can attach vendor invoices to material entries." },
];

function FAQItem({ q, a }) {
  const [open, setOpen] = React.useState(false);
  return (
    <button
      onClick={() => setOpen((v) => !v)}
      className="w-full text-left ss-card p-5"
      data-testid={`faq-${q.slice(0, 10)}`}
    >
      <div className="flex items-start justify-between gap-4">
        <span className="font-semibold text-[#171717]">{q}</span>
        {open ? <Minus className="h-5 w-5 text-[#F97316] shrink-0" /> : <Plus className="h-5 w-5 text-gray-500 shrink-0" />}
      </div>
      {open && <p className="mt-3 text-sm text-gray-600 leading-relaxed">{a}</p>}
    </button>
  );
}

export default function Landing() {
  return (
    <div className="min-h-screen ss-mesh">
      <PublicNav />

      {/* HERO */}
      <section className="relative">
        <div className="ss-grid-dots absolute inset-0 opacity-60" aria-hidden />
        <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-16 pb-20 lg:pt-24 lg:pb-28">
          <div className="grid lg:grid-cols-12 gap-10 items-center">
            <div className="lg:col-span-7 ss-fade-in">
              <span className="ss-chip bg-[#171717] text-[#F97316] uppercase tracking-[0.18em]">
                <HardHat className="h-3.5 w-3.5" /> Built for Indian construction
              </span>
              <h1 className="mt-5 text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight font-display text-[#171717]">
                Run your construction company like a <span className="text-[#F97316]">tech startup</span>.
              </h1>
              <p className="mt-5 text-base sm:text-lg text-gray-600 max-w-xl leading-relaxed">
                Site Seva Pro digitises everything — sites, supervisors, labour attendance, material inventory, payments and client updates — on one beautiful platform.
              </p>
              <div className="mt-8 flex flex-wrap gap-3">
                <Link to="/register" className="ss-btn-accent" data-testid="hero-cta-register">
                  Start Free <ArrowRight className="h-4 w-4" />
                </Link>
                <Link to="/pricing" className="ss-btn-outline" data-testid="hero-cta-pricing">
                  See Pricing
                </Link>
              </div>
              <div className="mt-8 flex flex-wrap items-center gap-6 text-sm text-gray-500">
                <div className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500" /> 1-site free forever</div>
                <div className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500" /> GST invoicing</div>
                <div className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500" /> AI insights included</div>
              </div>
            </div>

            <div className="lg:col-span-5">
              <div className="relative">
                <div className="absolute -inset-3 bg-gradient-to-tr from-[#F97316]/10 to-[#EAB308]/5 rounded-3xl blur-xl" aria-hidden />
                <div className="relative ss-card p-3 overflow-hidden">
                  <img
                    src="https://images.pexels.com/photos/1816030/pexels-photo-1816030.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940"
                    alt="Construction site"
                    className="w-full h-72 object-cover rounded-lg"
                  />
                  <div className="absolute top-6 left-6 ss-glass rounded-lg p-3 shadow-md border border-white">
                    <div className="text-[10px] font-bold uppercase tracking-wider text-gray-500">Active sites</div>
                    <div className="text-2xl font-extrabold text-[#171717]">14</div>
                  </div>
                  <div className="absolute bottom-6 right-6 ss-glass rounded-lg p-3 shadow-md border border-white">
                    <div className="text-[10px] font-bold uppercase tracking-wider text-gray-500">Net Profit</div>
                    <div className="text-xl font-extrabold text-emerald-600">{inr(8240000)}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* SOCIAL PROOF MARQUEE */}
      <section className="border-y border-gray-200 bg-white">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-6 overflow-hidden">
          <div className="flex items-center gap-4 mb-3">
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-gray-500">Trusted by 200+ contractors</span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>
          <div className="flex gap-12 ss-marquee whitespace-nowrap font-display text-2xl font-bold text-gray-300">
            {Array(2).fill(0).map((_, i) => (
              <div key={i} className="flex gap-12">
                <span>SHAPOORJI</span><span>L&amp;T</span><span>GODREJ</span><span>DLF</span><span>PRESTIGE</span>
                <span>OBEROI</span><span>RAHEJA</span><span>TATA HOUSING</span><span>HIRANANDANI</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FEATURES BENTO */}
      <section className="py-20 lg:py-28">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="max-w-2xl">
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#F97316]">Modules</span>
            <h2 className="mt-2 text-3xl sm:text-4xl lg:text-5xl font-extrabold font-display tracking-tight">
              Everything your site needs. Nothing it doesn't.
            </h2>
            <p className="mt-4 text-gray-600">From a single mason's attendance to a multi-crore P&amp;L — one platform, every workflow.</p>
          </div>

          <div className="mt-12 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((f, i) => (
              <div key={f.title} className="ss-card p-6 group relative overflow-hidden">
                <div className="h-10 w-10 rounded-lg bg-[#171717] text-[#F97316] flex items-center justify-center mb-4 group-hover:bg-[#F97316] group-hover:text-white transition-colors">
                  <f.icon className="h-5 w-5" />
                </div>
                <h3 className="font-display text-lg font-bold">{f.title}</h3>
                <p className="mt-1 text-sm text-gray-600 leading-relaxed">{f.desc}</p>
                <div className="mt-4 text-xs font-semibold text-[#F97316] flex items-center gap-1">
                  Module {String(i + 1).padStart(2, "0")} <ChevronRight className="h-3.5 w-3.5" />
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* DASHBOARD PREVIEW */}
      <section className="py-16 lg:py-20 bg-[#171717] text-white relative overflow-hidden">
        <div className="absolute inset-0 ss-grid-dots opacity-10" aria-hidden />
        <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-12 gap-10 items-center">
            <div className="lg:col-span-5">
              <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#F97316]">Dashboard</span>
              <h2 className="mt-3 text-3xl sm:text-4xl lg:text-5xl font-extrabold font-display tracking-tight">
                Numbers that move your business.
              </h2>
              <p className="mt-4 text-gray-300">
                Active sites, budgets, materials and net profit — beautifully laid out. Drill into any site for tasks, labour, photos and daily reports.
              </p>
              <div className="mt-6 grid grid-cols-2 gap-3 max-w-md">
                {[
                  { k: "Active Sites", v: "14" },
                  { k: "Net Profit", v: "₹82.4L" },
                  { k: "Pending", v: "₹21.0L" },
                  { k: "Material Cost", v: "₹38.6L" },
                ].map((s) => (
                  <div key={s.k} className="bg-white/5 border border-white/10 rounded-lg p-4">
                    <div className="text-[10px] font-bold uppercase tracking-wider text-gray-400">{s.k}</div>
                    <div className="mt-1 text-xl font-extrabold">{s.v}</div>
                  </div>
                ))}
              </div>
            </div>
            <div className="lg:col-span-7">
              <div className="ss-card p-2 bg-white">
                <img
                  src="https://images.unsplash.com/photo-1479839672679-a46483c0e7c8?crop=entropy&cs=srgb&fm=jpg&ixid=M3w4NTYxNzV8MHwxfHNlYXJjaHwxfHxtb2Rlcm4lMjBidWlsZGluZyUyMGFyY2hpdGVjdHVyZSUyMGNvbnN0cnVjdGlvbnxlbnwwfHx8fDE3Nzk4NjE1Njl8MA&ixlib=rb-4.1.0&q=85"
                  alt="Dashboard"
                  className="w-full h-80 object-cover rounded-lg"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* PRICING */}
      <section className="py-20 lg:py-24">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="max-w-2xl">
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#F97316]">Pricing</span>
            <h2 className="mt-2 text-3xl sm:text-4xl lg:text-5xl font-extrabold font-display tracking-tight">
              Simple plans. Pay only when you scale.
            </h2>
          </div>
          <div className="mt-12 grid gap-6 md:grid-cols-3">
            {Object.entries(PLAN_FEATURES).map(([k, p]) => (
              <div key={k} className={`rounded-2xl p-7 ${p.color} ${k === "PREMIUM" ? "shadow-lg" : "shadow-sm border border-gray-200"}`}>
                {k === "PREMIUM" && (
                  <span className="ss-chip bg-[#F97316] text-white mb-4">Most Popular</span>
                )}
                <h3 className={`font-display text-2xl font-extrabold ${k === "ENTERPRISE" ? "text-white" : "text-[#171717]"}`}>{p.name}</h3>
                <div className={`mt-3 text-4xl font-extrabold font-display ${k === "ENTERPRISE" ? "text-white" : "text-[#171717]"}`}>
                  {p.price === 0 ? "₹0" : `₹${p.price.toLocaleString("en-IN")}`}
                  <span className={`text-sm font-medium ${k === "ENTERPRISE" ? "text-gray-300" : "text-gray-500"}`}>/month</span>
                </div>
                <ul className={`mt-6 space-y-2 text-sm ${k === "ENTERPRISE" ? "text-gray-200" : "text-gray-700"}`}>
                  {p.features.map((f) => (
                    <li key={f} className="flex items-start gap-2">
                      <CheckCircle2 className={`h-4 w-4 mt-0.5 ${k === "ENTERPRISE" ? "text-[#F97316]" : "text-emerald-500"}`} /> {f}
                    </li>
                  ))}
                </ul>
                <Link
                  to="/register"
                  className={`mt-7 inline-flex justify-center w-full rounded-lg px-5 py-2.5 text-sm font-semibold transition-all ${
                    k === "PREMIUM" ? "bg-[#F97316] text-white hover:bg-[#EA580C]" :
                    k === "ENTERPRISE" ? "bg-[#F97316] text-white hover:bg-[#EA580C]" :
                    "bg-[#171717] text-white hover:bg-[#262626]"
                  }`}
                  data-testid={`pricing-cta-${k.toLowerCase()}`}
                >
                  {k === "FREE" ? "Start Free" : k === "PREMIUM" ? "Choose Premium" : "Contact Sales"}
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* TESTIMONIALS */}
      <section className="py-16 lg:py-20 bg-white">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="max-w-2xl">
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#F97316]">Testimonials</span>
            <h2 className="mt-2 text-3xl sm:text-4xl font-extrabold font-display tracking-tight">Loved by builders across India.</h2>
          </div>
          <div className="mt-10 grid gap-6 md:grid-cols-3">
            {[
              { q: "Cut our material wastage by 22% in 3 months. Worth every rupee.", n: "Rajesh Sharma", r: "MD, Sharma Constructions" },
              { q: "My supervisors actually upload daily updates now — clients love the photos.", n: "Priya Desai", r: "Director, Green Valley Developers" },
              { q: "Real-time P&L per site changed how we plan. Phenomenal product.", n: "Vikram Singh", r: "Founder, Coastal Builders" },
            ].map((t, i) => (
              <div key={i} className="ss-card p-6">
                <Quote className="h-6 w-6 text-[#F97316] mb-3" />
                <p className="text-[15px] text-gray-700 leading-relaxed">"{t.q}"</p>
                <div className="mt-5 flex items-center gap-3">
                  <div className="h-10 w-10 rounded-full bg-[#171717] text-white flex items-center justify-center font-bold">
                    {t.n.split(" ").map(x => x[0]).slice(0,2).join("")}
                  </div>
                  <div>
                    <div className="text-sm font-semibold">{t.n}</div>
                    <div className="text-xs text-gray-500">{t.r}</div>
                  </div>
                  <div className="ml-auto flex text-[#EAB308]">
                    {Array(5).fill(0).map((_,i)=><Star key={i} className="h-4 w-4 fill-current" />)}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20 lg:py-24">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto">
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#F97316]">FAQ</span>
            <h2 className="mt-2 text-3xl sm:text-4xl font-extrabold font-display tracking-tight">Questions, answered.</h2>
          </div>
          <div className="mt-10 space-y-3">
            {FAQS.map((f) => <FAQItem key={f.q} {...f} />)}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div className="rounded-3xl bg-[#171717] text-white p-10 lg:p-14 relative overflow-hidden">
            <div className="absolute -right-12 -top-12 h-64 w-64 rounded-full bg-[#F97316]/20 blur-3xl" aria-hidden />
            <div className="absolute -left-12 -bottom-12 h-64 w-64 rounded-full bg-[#EAB308]/10 blur-3xl" aria-hidden />
            <div className="relative grid md:grid-cols-2 gap-8 items-center">
              <div>
                <h2 className="text-3xl sm:text-4xl font-extrabold font-display">Stop juggling WhatsApp groups and Excel sheets.</h2>
                <p className="mt-3 text-gray-300">Start your first site free in under 2 minutes. No card required.</p>
              </div>
              <div className="flex flex-wrap gap-3 md:justify-end">
                <Link to="/register" className="ss-btn-accent" data-testid="bottom-cta-register">Get Started <ArrowRight className="h-4 w-4" /></Link>
                <Link to="/contact" className="inline-flex items-center justify-center gap-2 rounded-lg border-2 border-white/20 px-5 py-2.5 text-sm font-semibold text-white hover:bg-white/5">Talk to Sales</Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      <PublicFooter />
    </div>
  );
}
