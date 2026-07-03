import React from "react";
import { Building2, Crown, HardHat } from "lucide-react";

export default function CompanyCard({ user }) {
  return (
    <div
      className="
        mx-4
        mb-6
        overflow-hidden
        rounded-3xl
        border
        border-slate-700
        bg-gradient-to-br
        from-slate-900
        via-slate-800
        to-slate-900
        shadow-xl
      "
    >
      {/* Header */}

      <div
        className="
          flex
          items-center
          gap-4
          p-5
        "
      >
        <div
          className="
            h-14
            w-14
            rounded-2xl
            bg-gradient-to-br
            from-blue-500
            to-blue-700
            flex
            items-center
            justify-center
            shadow-lg
          "
        >
          <HardHat
            size={28}
            className="text-white"
          />
        </div>

        <div className="flex-1">

          <p
            className="
              text-[11px]
              uppercase
              tracking-[0.2em]
              text-slate-400
            "
          >
            Company
          </p>

          <h2
            className="
              mt-1
              text-lg
              font-bold
              text-white
              truncate
            "
          >
            {user?.company_name || "Construction Company"}
          </h2>

        </div>

      </div>

      {/* Divider */}

      <div className="border-t border-slate-700" />

      {/* Plan */}

      <div
        className="
          flex
          items-center
          justify-between
          px-5
          py-4
        "
      >
        <div>

          <p className="text-xs text-slate-400">

            Current Plan

          </p>

          <div
            className="
              mt-1
              flex
              items-center
              gap-2
            "
          >
            <Crown
              size={15}
              className="text-yellow-400"
            />

            <span
              className="
                font-semibold
                text-blue-400
              "
            >
              Professional
            </span>

          </div>

        </div>

        <button
          className="
            rounded-xl
            bg-blue-600
            hover:bg-blue-700
            px-4
            py-2
            text-xs
            font-semibold
            text-white
            transition
          "
        >
          Upgrade
        </button>

      </div>

      {/* Divider */}

      <div className="border-t border-slate-700" />

      {/* Stats */}

      <div
        className="
          grid
          grid-cols-2
        "
      >

        <div
          className="
            border-r
            border-slate-700
            p-4
          "
        >
          <p
            className="
              text-xs
              text-slate-500
            "
          >
            Active Sites
          </p>

          <h3
            className="
              mt-1
              text-xl
              font-bold
              text-white
            "
          >
            0
          </h3>

        </div>

        <div className="p-4">

          <p
            className="
              text-xs
              text-slate-500
            "
          >
            Team Members
          </p>

          <h3
            className="
              mt-1
              text-xl
              font-bold
              text-white
            "
          >
            0
          </h3>

        </div>

      </div>

    </div>
  );
}