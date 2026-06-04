export const PLAN_FEATURES = {
  FREE: {
    name: "Free",
    price: 0,
    color: "bg-white",
    features: ["1 Site", "Max 2 Supervisors", "Basic Reports", "Limited Storage"],
  },
  PREMIUM: {
    name: "Premium",
    price: 4999,
    color: "bg-white ring-2 ring-[#F97316]",
    features: [
      "Unlimited Sites",
      "Unlimited Supervisors",
      "Full Reports",
      "Client Portal",
      "Material Tracking",
      "Financial Reports",
      "AI Insights",
    ],
  },
  ENTERPRISE: {
    name: "Enterprise",
    price: 14999,
    color: "bg-[#171717] text-white",
    features: ["ERP Integration", "Dedicated Support", "Team Hierarchy", "White-label Branding"],
  },
};

export const SITE_STATUS_COLOR = {
  PLANNING: "bg-yellow-100 text-yellow-800 border border-yellow-200",
  ACTIVE: "bg-emerald-100 text-emerald-800 border border-emerald-200",
  ON_HOLD: "bg-orange-100 text-orange-800 border border-orange-200",
  COMPLETED: "bg-gray-100 text-gray-800 border border-gray-200",
};

export const MATERIAL_CATEGORIES = ["Cement", "Steel", "Sand", "Bricks", "Electrical", "Plumbing", "Tiles", "Paint", "Other"];

export function inr(n) {
  if (n === null || n === undefined) return "₹0";
  const v = Number(n);
  if (v >= 10000000) return `₹${(v / 10000000).toFixed(2)} Cr`;
  if (v >= 100000) return `₹${(v / 100000).toFixed(2)} L`;
  if (v >= 1000) return `₹${(v / 1000).toFixed(1)}K`;
  return `₹${v.toLocaleString("en-IN")}`;
}

export function fmtDate(s) {
  if (!s) return "—";
  try {
    return new Date(s).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
  } catch {
    return s;
  }
}
