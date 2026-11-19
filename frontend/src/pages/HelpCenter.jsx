import React from "react";
import { Link } from "react-router-dom";
import { BookOpen, CircleHelp, CreditCard, FileText, LifeBuoy, Map, ShieldCheck, Users } from "lucide-react";

const topics = [
  [Map, "Planning & Design Studio", "Create a floor-wise 2D brief, approve a floor, then create its furnished 3D concept.", "/app/maps"],
  [FileText, "BOQ & estimates", "Build estimates, review materials and share a controlled BOQ with clients.", "/app/estimates"],
  [Users, "Sites & team", "Create a site, assign supervisors and keep daily reports accountable.", "/app/sites?create=1"],
  [CreditCard, "Subscription & credits", "Review plan access, design credits and renewal information.", "/app/subscription"],
];

export default function HelpCenter() {
  return <div className="mx-auto max-w-6xl space-y-6 ss-fade-in">
    <section className="rounded-2xl border border-[#30323a] bg-[#111214] p-7 sm:p-9"><div className="flex items-start gap-4"><div className="grid h-12 w-12 place-items-center rounded-xl bg-blue-500/15 text-blue-300"><LifeBuoy /></div><div><p className="text-xs font-bold uppercase tracking-[.18em] text-blue-300">Support centre</p><h1 className="mt-2 font-display text-3xl font-extrabold text-white">How can we help?</h1><p className="mt-3 max-w-2xl text-sm leading-6 text-slate-400">Practical guidance for contractors, supervisors and clients—built into the workspace where the work happens.</p></div></div></section>
    <section className="grid gap-4 sm:grid-cols-2">{topics.map(([Icon, title, copy, to]) => <Link key={title} to={to} className="group rounded-2xl border border-[#30323a] bg-[#111214] p-6 transition hover:border-blue-400 hover:bg-[#171b22]"><Icon className="h-5 w-5 text-blue-300" /><h2 className="mt-4 font-display text-lg font-bold text-white">{title}</h2><p className="mt-2 text-sm leading-6 text-slate-400">{copy}</p><span className="mt-4 inline-flex text-sm font-semibold text-blue-300 group-hover:text-white">Open workspace →</span></Link>)}</section>
    <section className="grid gap-4 md:grid-cols-2"><div className="rounded-2xl border border-[#30323a] bg-[#111214] p-6"><BookOpen className="h-5 w-5 text-blue-300" /><h2 className="mt-4 font-display text-lg font-bold text-white">Planning guidance</h2><p className="mt-2 text-sm leading-6 text-slate-400">Maps are overview and rough planning directions. Use approved architects and engineers for detailed, signed working drawings.</p></div><div className="rounded-2xl border border-[#30323a] bg-[#111214] p-6"><CircleHelp className="h-5 w-5 text-blue-300" /><h2 className="mt-4 font-display text-lg font-bold text-white">Need a hand?</h2><p className="mt-2 text-sm leading-6 text-slate-400">Write to support@sitesevapro.in with your workspace, site and a short description of the issue.</p><a className="mt-4 inline-flex text-sm font-semibold text-blue-300 hover:text-white" href="mailto:support@sitesevapro.in">Email support →</a></div></section>
  </div>;
}
