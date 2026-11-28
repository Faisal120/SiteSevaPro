const CONSENT_KEY = "siteseva.marketing-consent";
const PIXEL_SCRIPT_ID = "siteseva-meta-pixel";

// This is deliberately an explicit allowlist. Account and workspace pages
// must never be added here without a privacy review.
export const MARKETING_PATHS = new Set(["/", "/pricing", "/about", "/contact", "/register"]);

export function pixelConfig(env = process.env) {
  const pixelId = String(env.REACT_APP_META_PIXEL_ID || "").trim();
  return {
    pixelId,
    // Marketing tracking must be explicitly enabled in a production build.
    enabled: env.NODE_ENV === "production"
      && env.REACT_APP_META_PIXEL_ENABLED === "true"
      && /^\d+$/.test(pixelId),
  };
}

function browserStorage(windowRef = typeof window !== "undefined" ? window : null) {
  try {
    return windowRef?.localStorage || null;
  } catch {
    return null;
  }
}

export function readMarketingConsent(storage = browserStorage()) {
  try {
    const value = storage?.getItem(CONSENT_KEY);
    return value === "accepted" || value === "rejected" ? value : null;
  } catch {
    return null;
  }
}

export function writeMarketingConsent(value, storage = browserStorage()) {
  try {
    if (value === "accepted" || value === "rejected") storage?.setItem(CONSENT_KEY, value);
  } catch {
    // Consent UI remains usable even when browser storage is unavailable.
  }
}

export function isSafeMarketingLocation(location) {
  return Boolean(
    location
    && MARKETING_PATHS.has(location.pathname)
    && !location.search
    && !location.hash,
  );
}

function removePixelCookies(documentRef) {
  for (const name of ["_fbp", "_fbc"]) {
    documentRef.cookie = `${name}=; Max-Age=0; Path=/; SameSite=Lax`;
    documentRef.cookie = `${name}=; Max-Age=0; Path=/; Domain=.sitesevapro.in; SameSite=Lax`;
  }
}

export function createMetaPixelService({ config = pixelConfig(), windowRef, documentRef } = {}) {
  const win = windowRef || (typeof window !== "undefined" ? window : null);
  const doc = documentRef || (typeof document !== "undefined" ? document : null);
  const seenNavigations = new Set();
  const seenRegistrations = new Set();
  let initialized = false;

  function available() {
    return Boolean(config.enabled && config.pixelId && win && doc);
  }

  function fbq() {
    return typeof win?.fbq === "function" ? win.fbq : null;
  }

  function hasConsent() {
    return readMarketingConsent(browserStorage(win)) === "accepted";
  }

  function isOnApprovedPublicPath() {
    return isSafeMarketingLocation({
      pathname: win?.location?.pathname,
      search: win?.location?.search,
      hash: win?.location?.hash,
    });
  }

  function initialize() {
    // Loading the Meta browser script itself is consent-gated.
    if (!available() || !hasConsent()) return false;
    if (initialized) return true;
    try {
      if (!fbq()) {
        // Equivalent to Meta's browser base-code queue. Once the external
        // script supplies callMethod, future events are dispatched rather
        // than remaining in the local queue.
        const queue = function pixelQueue(...args) {
          if (queue.callMethod) queue.callMethod.apply(queue, args);
          else queue.queue.push(args);
        };
        queue.queue = [];
        queue.loaded = true;
        queue.version = "2.0";
        win.fbq = queue;
        win._fbq = queue;
      }
      if (!doc.getElementById(PIXEL_SCRIPT_ID)) {
        const script = doc.createElement("script");
        script.id = PIXEL_SCRIPT_ID;
        script.async = true;
        script.src = "https://connect.facebook.net/en_US/fbevents.js";
        script.referrerPolicy = "no-referrer";
        // A blocked Meta CDN must not affect navigation or forms.
        script.onerror = () => { script.dataset.failed = "true"; };
        doc.head.appendChild(script);
      }
      const tracker = fbq();
      tracker("set", "autoConfig", false, config.pixelId);
      tracker("init", config.pixelId);
      initialized = true;
      return true;
    } catch {
      return false;
    }
  }

  function track(name, key) {
    if (!hasConsent() || !initialize() || !key || seenNavigations.has(`${name}:${key}`)) return false;
    try {
      fbq()("track", name);
      seenNavigations.add(`${name}:${key}`);
      return true;
    } catch {
      return false;
    }
  }

  return {
    isEnabled: () => available(),
    initialize,
    trackPageView(location, navigationKey) {
      if (!isSafeMarketingLocation(location)) return false;
      return track("PageView", `${navigationKey || "initial"}:${location.pathname}`);
    },
    trackPricingView(location, navigationKey) {
      if (!isSafeMarketingLocation(location) || location.pathname !== "/pricing") return false;
      return track("ViewContent", `${navigationKey || "initial"}:pricing`);
    },
    trackCompleteRegistration(applicationId) {
      if (!available() || !hasConsent() || !isOnApprovedPublicPath() || !applicationId || seenRegistrations.has(applicationId)) return false;
      try {
        if (!initialize()) return false;
        // Deliberately do not send the application id or any personal data.
        fbq()("track", "CompleteRegistration");
        seenRegistrations.add(applicationId);
        return true;
      } catch {
        return false;
      }
    },
    grant() {
      if (!hasConsent() || !initialize()) return false;
      try {
        fbq()("consent", "grant");
        return true;
      } catch {
        return false;
      }
    },
    revoke() {
      try {
        if (initialized && fbq()) fbq()("consent", "revoke");
        writeMarketingConsent("rejected", browserStorage(win));
        if (doc) removePixelCookies(doc);
      } catch {
        // Analytics cleanup must never interrupt the user experience.
      }
    },
  };
}

export const metaPixel = createMetaPixelService();
export const MARKETING_CONSENT_KEY = CONSENT_KEY;
