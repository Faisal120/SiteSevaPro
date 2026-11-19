import React from "react";
import { useNavigate } from "react-router-dom";
import {
  Building2,
  Crown,
  HardHat,
  ArrowUpRight,
} from "lucide-react";

export default function CompanyCard({ user, stats, branding, subscription }) {
  const navigate = useNavigate();
  const company = branding?.company_name || user?.company_name || "SiteSeva Construction";
  const owner = user?.full_name || "Contractor";
  const plan = (subscription?.plan || user?.plan || "FREE").toUpperCase();
  const planLabel = plan === "PREMIUM" ? "Pro" : plan === "ENTERPRISE" ? "Enterprise" : "Free";
  const isEnterprise = plan === "ENTERPRISE";

  return (
    <div
      className="
        rounded-2xl
        border
        border-[#30323a]
        bg-[#111214]
        p-4
      "
    >
      {/* Header */}

        <div className="flex min-w-0 items-center gap-3">

        <div
          className="
            h-12
            w-12
            rounded-xl
            bg-[#3b82f6]
            flex
            items-center
            justify-center
          "
        >
          {branding?.logo_url ? <img src={branding.logo_url} alt="Company logo" className="h-full w-full rounded-xl bg-white object-contain p-1" /> : <Building2 size={22} className="text-white" />}
        </div>

        <div className="min-w-0 flex-1">

          <h3
            className="
              truncate
              text-sm
              font-semibold
              text-white
            "
          >
            {company}
          </h3>

          <p
            className="
              truncate
              text-xs
              text-slate-400
            "
          >
            {owner}
          </p>

        </div>

      </div>

      {/* Plan */}

      <div className="mt-5">

        <div className="flex items-center justify-between">

          <span
            className="
              text-xs
              text-slate-400
            "
          >
            Current Plan
          </span>

          <span
            className="
              inline-flex
              items-center
              gap-1

              rounded-full

              bg-blue-500/15

              px-2
              py-1

              text-[11px]
              font-medium

              text-blue-300
            "
          >
            <Crown size={12} />

            {planLabel}
          </span>

        </div>

      </div>



      {/* Upgrade */}

      <button
        onClick={() => navigate("/app/subscription")}
        className="
          mt-5

          flex
          w-full
          items-center
          justify-center
          gap-2

          rounded-xl

          border
          border-blue-600

          py-2.5

          text-sm
          font-medium

          text-blue-400

          transition

          hover:bg-blue-600
          hover:text-white
        "
      >
        <ArrowUpRight size={16} />

        {isEnterprise ? "Renew Enterprise" : "Upgrade Plan"}

      </button>

    </div>
  );
}
