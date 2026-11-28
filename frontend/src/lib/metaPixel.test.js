import {
  MARKETING_CONSENT_KEY,
  createMetaPixelService,
  pixelConfig,
  readMarketingConsent,
  writeMarketingConsent,
} from "./metaPixel";

const enabledConfig = { enabled: true, pixelId: "1461348082164441" };
const root = { pathname: "/", search: "", hash: "" };
const pricing = { pathname: "/pricing", search: "", hash: "" };

function pixelCalls() {
  return (window.fbq?.queue || []).filter((entry) => entry[0] === "track");
}

function makeService(config = enabledConfig) {
  return createMetaPixelService({ config, windowRef: window, documentRef: document });
}

beforeEach(() => {
  window.history.replaceState({}, "", "/");
  window.localStorage.clear();
  document.head.innerHTML = "";
  delete window.fbq;
  delete window._fbq;
});

afterEach(() => {
  window.localStorage.clear();
});

test("keeps the Pixel disabled by default outside production", () => {
  expect(pixelConfig({ NODE_ENV: "development", REACT_APP_META_PIXEL_ENABLED: "true", REACT_APP_META_PIXEL_ID: "1461348082164441" }).enabled).toBe(false);
  expect(pixelConfig({ NODE_ENV: "test", REACT_APP_META_PIXEL_ENABLED: "true", REACT_APP_META_PIXEL_ID: "1461348082164441" }).enabled).toBe(false);
  expect(makeService({ enabled: false, pixelId: "1461348082164441" }).trackPageView(root, "start")).toBe(false);
  expect(document.getElementById("siteseva-meta-pixel")).toBeNull();
});

test("does not initialize until marketing consent is accepted", () => {
  const service = makeService();
  expect(service.trackPageView(root, "start")).toBe(false);
  expect(window.fbq).toBeUndefined();

  writeMarketingConsent("accepted");
  expect(service.trackPageView(root, "start")).toBe(true);
  expect(document.getElementById("siteseva-meta-pixel")).not.toBeNull();
  expect(pixelCalls()).toEqual([["track", "PageView"]]);
});

test("rejecting or withdrawing consent prevents further tracking", () => {
  const service = makeService();
  writeMarketingConsent("rejected");
  expect(service.trackPageView(root, "start")).toBe(false);
  expect(window.fbq).toBeUndefined();

  writeMarketingConsent("accepted");
  expect(service.trackPageView(root, "start")).toBe(true);
  service.revoke();
  expect(readMarketingConsent()).toBe("rejected");
  expect(service.trackPricingView(pricing, "pricing")).toBe(false);
});

test("tracks allowed navigation once and records pricing content once", () => {
  const service = makeService();
  writeMarketingConsent("accepted");
  expect(service.trackPageView(root, "home-navigation")).toBe(true);
  expect(service.trackPageView(root, "home-navigation")).toBe(false);
  expect(service.trackPageView(pricing, "pricing-navigation")).toBe(true);
  expect(service.trackPricingView(pricing, "pricing-navigation")).toBe(true);
  expect(service.trackPricingView(pricing, "pricing-navigation")).toBe(false);
  expect(pixelCalls()).toEqual([
    ["track", "PageView"],
    ["track", "PageView"],
    ["track", "ViewContent"],
  ]);
});

test("excludes protected routes and marketing URLs with sensitive parameters", () => {
  const service = makeService();
  writeMarketingConsent("accepted");
  expect(service.trackPageView({ pathname: "/app/dashboard", search: "", hash: "" }, "dashboard")).toBe(false);
  expect(service.trackPageView({ pathname: "/pricing", search: "?token=secret", hash: "" }, "pricing-query")).toBe(false);
  expect(service.trackPageView({ pathname: "/pricing", search: "", hash: "#private" }, "pricing-hash")).toBe(false);
  expect(window.fbq).toBeUndefined();
});

test("fires a successful-registration conversion once without accepting failed submissions", () => {
  const service = makeService();
  writeMarketingConsent("accepted");
  window.history.replaceState({}, "", "/register");
  // A failed API request has no application id and must not be treated as a conversion.
  expect(service.trackCompleteRegistration()).toBe(false);
  expect(service.trackCompleteRegistration("application-123")).toBe(true);
  expect(service.trackCompleteRegistration("application-123")).toBe(false);
  expect(pixelCalls()).toEqual([["track", "CompleteRegistration"]]);
});

test("does not throw when the Meta script is blocked", () => {
  const service = makeService();
  writeMarketingConsent("accepted");
  expect(() => service.trackPageView(root, "start")).not.toThrow();
  const script = document.getElementById("siteseva-meta-pixel");
  expect(() => script.onerror()).not.toThrow();
  expect(script.dataset.failed).toBe("true");
});

test("does not keep an application id in browser storage or event arguments", () => {
  const service = makeService();
  writeMarketingConsent("accepted");
  window.history.replaceState({}, "", "/register");
  service.trackCompleteRegistration("application-456");
  expect(window.localStorage.getItem(MARKETING_CONSENT_KEY)).toBe("accepted");
  expect(JSON.stringify(window.fbq.queue)).not.toContain("application-456");
});
