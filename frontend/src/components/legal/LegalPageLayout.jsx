import React from "react";
import { Link } from "react-router-dom";
import { ChevronRight, Mail, ShieldCheck } from "lucide-react";
import PublicFooter from "@/components/PublicFooter";
import PublicNav from "@/components/PublicNav";

export const LAST_UPDATED = "25 November 2026";

export function LegalSection({ id, title, children }) {
  return <section id={id} className="scroll-mt-28 border-b border-white/10 py-8 last:border-0"><h2 className="font-display text-2xl font-bold tracking-tight text-white sm:text-3xl">{title}</h2><div className="mt-4 space-y-4 text-sm leading-7 text-slate-300 sm:text-base">{children}</div></section>;
}

export default function LegalPageLayout({ title, description, sections, children }) {
  React.useEffect(() => {
    document.title = `${title} | Site Seva Pro`;
    const descriptionTag = document.querySelector('meta[name="description"]');
    if (descriptionTag) descriptionTag.setAttribute("content", description);
    const setOpenGraph = (property, value) => {
      let tag = document.querySelector(`meta[property="${property}"]`);
      if (!tag) { tag = document.createElement("meta"); tag.setAttribute("property", property); document.head.appendChild(tag); }
      tag.setAttribute("content", value);
    };
    setOpenGraph("og:title", `${title} | Site Seva Pro`);
    setOpenGraph("og:description", description);
    setOpenGraph("og:url", `https://sitesevapro.in${window.location.pathname}`);
    return () => { document.title = "Site Seva Pro"; };
  }, [title, description]);

  return <div className="landing-shell min-h-screen ss-mesh">
    <PublicNav />
    <main>
      <section className="border-b border-white/10 bg-[#090a0c]/70 py-14 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="max-w-4xl">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-300">Site Seva Pro legal information</p>
            <h1 className="mt-3 font-display text-4xl font-extrabold tracking-tight text-white sm:text-5xl">{title}</h1>
            <p className="mt-5 max-w-3xl text-base leading-7 text-slate-300 sm:text-lg">{description}</p>
            <p className="mt-5 text-sm text-slate-400">Last updated: {LAST_UPDATED}</p>
          </div>
        </div>
      </section>
      <section className="py-10 sm:py-14">
        <div className="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[250px_minmax(0,1fr)] lg:px-8">
          <aside className="lg:sticky lg:top-24 lg:self-start">
            <nav aria-label="On this page" className="rounded-2xl border border-white/10 bg-[#101217]/90 p-5">
              <p className="text-xs font-bold uppercase tracking-[0.16em] text-blue-300">On this page</p>
              <ul className="mt-3 space-y-1">
                {sections.map((section) => <li key={section.id}><a href={`#${section.id}`} className="flex items-start gap-2 rounded-lg px-2 py-1.5 text-sm text-slate-400 transition hover:bg-white/5 hover:text-white"><ChevronRight className="mt-0.5 h-3.5 w-3.5 shrink-0 text-blue-300" />{section.title}</a></li>)}
              </ul>
            </nav>
          </aside>
          <article className="rounded-3xl border border-white/10 bg-[#101217]/90 p-6 shadow-2xl shadow-black/15 sm:p-9">
            {children}
            <div className="mt-10 rounded-2xl border border-blue-400/20 bg-blue-500/10 p-5 text-sm leading-6 text-slate-300">
              <div className="flex items-center gap-2 font-semibold text-white"><ShieldCheck className="h-4 w-4 text-blue-300" />Related information</div>
              <p className="mt-2">See our <Link className="text-blue-300 hover:text-white" to="/privacy-policy">Privacy Policy</Link>, <Link className="text-blue-300 hover:text-white" to="/terms">Terms of Service</Link>, and <Link className="text-blue-300 hover:text-white" to="/data-deletion">Account &amp; Data Deletion</Link> page. For questions, email <a className="text-blue-300 hover:text-white" href="mailto:support@sitesevapro.in"><Mail className="mr-1 inline h-3.5 w-3.5" />support@sitesevapro.in</a>.</p>
            </div>
          </article>
        </div>
      </section>
    </main>
    <PublicFooter />
  </div>;
}
