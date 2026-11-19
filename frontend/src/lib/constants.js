export const PLAN_FEATURES = {
  FREE: {
    name: "Free",
    price: 0,
    color: "bg-white",
    features: ["1 active site", "2 supervisor accounts", "Basic estimates", "Daily reports", "Core material and labour tracking"],
  },
  PREMIUM: {
    name: "Pro",
    price: 2999,
    color: "bg-white ring-2 ring-[#3B82F6]",
    features: [
      "Unlimited sites & supervisors",
      "BOQ generation & PDF export",
      "Detailed estimate creation",
      "2D floor-plan generation",
      "10 monthly design credits",
      "Labour Wallet & Ledger",
      "Advanced Analytics",
      "Client Portal",
      "Material & Vendor Tracking",
      "Branded PDF Export",
    ],
  },
  ENTERPRISE: {
    name: "Enterprise",
    price: 4999,
    color: "bg-[#171717] text-white",
    features: [
      "Everything in Pro",
      "Furnished 3D plan renderer",
      "50 monthly design credits",
      "Electrical, plumbing & structure overlays",
      "AI Construction Assistant",
      "AI Cost Overrun Prediction",
      "AI Consumption Analysis",
      "AI Daily Reports & Client Updates",
      "Priority Support",
      "Branded PDF Export",
    ],
  },
};

export const UPI_ID = "fk1571515@ybl";
export const UPI_PAYEE_NAME = "Site Seva Pro";

export const SITE_STATUS_COLOR = {
  PLANNING: "bg-yellow-100 text-yellow-800 border border-yellow-200",
  ACTIVE: "bg-emerald-100 text-emerald-800 border border-emerald-200",
  ON_HOLD: "bg-blue-100 text-blue-800 border border-blue-200",
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
