import React from "react";
import { useLocation } from "react-router-dom";
import { metaPixel } from "@/lib/metaPixel";
import { useMarketingConsent } from "@/components/marketing/MarketingConsent";

export default function MetaPixelTracker() {
  const location = useLocation();
  const { configured, consent } = useMarketingConsent();

  React.useEffect(() => {
    if (!configured || consent !== "accepted") return;
    metaPixel.trackPageView(location, location.key);
    metaPixel.trackPricingView(location, location.key);
  }, [configured, consent, location]);

  return null;
}
