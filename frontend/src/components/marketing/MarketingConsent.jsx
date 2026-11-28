import React from "react";
import { Link, useLocation } from "react-router-dom";
import { MARKETING_PATHS, metaPixel, pixelConfig, readMarketingConsent, writeMarketingConsent } from "@/lib/metaPixel";

const MarketingConsentContext = React.createContext(null);

export function MarketingConsentProvider({ children }) {
  const location = useLocation();
  const configured = pixelConfig().enabled;
  const [consent, setConsent] = React.useState(() => configured ? readMarketingConsent() : "rejected");
  const [showChoices, setShowChoices] = React.useState(() => configured && !readMarketingConsent());

  const choose = React.useCallback((value) => {
    writeMarketingConsent(value);
    setConsent(value);
    setShowChoices(false);
    if (value === "accepted") metaPixel.grant();
    else metaPixel.revoke();
  }, []);
  const withdraw = React.useCallback(() => choose("rejected"), [choose]);
  const openChoices = React.useCallback(() => setShowChoices(true), []);

  return <MarketingConsentContext.Provider value={{ configured, consent, choose, withdraw, openChoices }}>
    {children}
    {configured && showChoices && MARKETING_PATHS.has(location.pathname) && <MarketingConsentBanner onAccept={() => choose("accepted")} onReject={() => choose("rejected")} />}
  </MarketingConsentContext.Provider>;
}

export function useMarketingConsent() {
  return React.useContext(MarketingConsentContext) || { configured: false, consent: "rejected", withdraw: () => {}, openChoices: () => {} };
}

function MarketingConsentBanner({ onAccept, onReject }) {
  return <aside role="dialog" aria-label="Marketing tracking preference" className="fixed inset-x-4 bottom-4 z-[100] mx-auto max-w-2xl rounded-xl border border-blue-400/30 bg-[#101b30] p-5 text-sm text-blue-50 shadow-2xl">
    <p className="font-semibold">Marketing measurement preference</p>
    <p className="mt-2 leading-6 text-blue-100/80">With your permission, we use Meta Pixel on public marketing pages to measure page visits, pricing interest, and completed contractor applications. It is not used in dashboards or account-security flows.</p>
    <p className="mt-2 text-xs text-blue-100/70">Read our <Link className="underline hover:text-white" to="/privacy-policy">Privacy Policy</Link>. You can withdraw consent later from the public footer.</p>
    <div className="mt-4 flex flex-wrap gap-3"><button type="button" onClick={onAccept} className="rounded-lg bg-blue-500 px-4 py-2 font-semibold text-white hover:bg-blue-600">Accept marketing tracking</button><button type="button" onClick={onReject} className="rounded-lg border border-white/25 px-4 py-2 font-semibold text-white hover:bg-white/10">Reject</button></div>
  </aside>;
}
