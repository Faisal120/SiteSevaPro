import React from "react";
import {
  Building2,
  Crown,
  HardHat,
  ArrowUpRight,
} from "lucide-react";

export default function CompanyCard({ user }) {
  const company = user?.company_name || "SiteSeva Construction";
  const owner = user?.full_name || "Contractor";

  return (
    <div
      className="
        rounded-2xl
        border
        border-slate-800
        bg-slate-900
        p-4
      "
    >
      {/* Header */}

      <div className="flex items-center gap-3">

        <div
          className="
            h-12
            w-12
            rounded-xl
            bg-blue-600
            flex
            items-center
            justify-center
          "
        >
          <Building2
            size={22}
            className="text-white"
          />
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

              bg-blue-600/20

              px-2
              py-1

              text-[11px]
              font-medium

              text-blue-400
            "
          >
            <Crown size={12} />

            Professional
          </span>

        </div>

      </div>

      {/* Stats */}

      <div className="mt-5 grid grid-cols-2 gap-3">

        <div
          className="
            rounded-xl
            bg-slate-800
            p-3
          "
        >
          <div className="text-xl font-bold text-white">
            {user?.site_ids?.length ?? 0}
          </div>

          <div className="text-[11px] text-slate-400">
            Active Sites
          </div>
        </div>

        <div
          className="
            rounded-xl
            bg-slate-800
            p-3
          "
        >
          <div className="text-xl font-bold text-white">
            {user?.role === "CONTRACTOR" ? "PRO" : "--"}
          </div>

          <div className="text-[11px] text-slate-400">
            Workspace
          </div>
        </div>

      </div>

      {/* Upgrade */}

      <button
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

        Upgrade Plan

      </button>

    </div>
  );
}