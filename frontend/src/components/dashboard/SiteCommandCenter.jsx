import React from "react";
import { useNavigate } from "react-router-dom";

import {
  Building2,
  MapPin,
  CalendarDays,
  Users,
  ArrowRight,
  Clock3,
} from "lucide-react";

export default function SiteCommandCenter({ sites = [] }) {
  const navigate = useNavigate();

  return (
    <section
      className="
        rounded-3xl
        border
        border-slate-200
        bg-white
        p-6
        shadow-sm
      "
    >
      {/* Header */}

      <div className="flex items-center justify-between mb-6">

        <div>

          <h2 className="text-xl font-bold text-slate-800">
            Construction Projects
          </h2>

          <p className="text-sm text-slate-500">
            Monitor all running projects
          </p>

        </div>

        <button
          onClick={() => navigate("/app/sites")}
          className="
            flex
            items-center
            gap-2
            text-blue-600
            font-medium
            hover:text-blue-700
          "
        >
          View All

          <ArrowRight size={16} />
        </button>

      </div>

      {/* Empty */}

      {sites.length === 0 && (

        <div
          className="
            rounded-2xl
            border-2
            border-dashed
            border-slate-200
            py-14
            text-center
          "
        >
          <Building2
            size={42}
            className="mx-auto text-slate-300"
          />

          <h3 className="mt-4 font-semibold text-slate-700">
            No Sites Found
          </h3>

          <p className="mt-1 text-sm text-slate-500">
            Create your first construction project.
          </p>

        </div>

      )}

      {/* Site Cards */}

      <div className="space-y-5">

        {sites.map((site) => (

          <div
            key={site.id || site._id}
            onClick={() =>
              navigate(`/app/sites/${site.id || site._id}`)
            }
            className="
              cursor-pointer

              rounded-2xl

              border
              border-slate-200

              p-5

              transition-all

              hover:border-blue-300
              hover:shadow-lg
            "
          >

            {/* Top */}

            <div className="flex justify-between">

              <div>

                <h3
                  className="
                    text-lg
                    font-semibold
                    text-slate-800
                  "
                >
                  {site.name}
                </h3>

                <div
                  className="
                    mt-2

                    flex
                    flex-wrap

                    gap-5

                    text-sm
                    text-slate-500
                  "
                >

                  <span className="flex items-center gap-2">

                    <MapPin size={15} />

                    {site.location || "Unknown"}

                  </span>

                  <span className="flex items-center gap-2">

                    <CalendarDays size={15} />

                    {site.start_date || "--"}

                  </span>

                </div>

              </div>

              {/* Status */}

              <span
                className={`
                  h-fit

                  rounded-full

                  px-3
                  py-1

                  text-xs
                  font-semibold

                  ${site.status === "ACTIVE"
                    ? "bg-green-100 text-green-700"
                    : site.status === "COMPLETED"
                      ? "bg-blue-100 text-blue-700"
                      : "bg-yellow-100 text-yellow-700"
                  }
                `}
              >
                {site.status}
              </span>

            </div>

            {/* Progress */}

            <div className="mt-5">

              <div
                className="
                  flex
                  justify-between

                  text-sm
                  mb-2
                "
              >
                <span>Overall Progress</span>

                <span className="font-semibold">
                  {site.progress || 0}%
                </span>

              </div>

              <div
                className="
                  h-2

                  rounded-full

                  bg-slate-200
                "
              >
                <div
                  className="
                    h-2

                    rounded-full

                    bg-blue-600
                  "
                  style={{
                    width: `${site.progress || 0}%`,
                  }}
                />
              </div>

            </div>

            {/* Footer */}

            <div
              className="
                mt-5

                grid

                grid-cols-3

                gap-4
              "
            >

              <div>

                <p className="text-xs text-slate-400">
                  Budget
                </p>

                <h4 className="font-semibold">
                  ₹{Number(site.budget || 0).toLocaleString()}
                </h4>

              </div>

              <div>

                <p className="text-xs text-slate-400">
                  Supervisor
                </p>

                <h4 className="font-semibold truncate">
                  {site.supervisor_name || "--"}
                </h4>

              </div>

              <div>

                <p className="text-xs text-slate-400">
                  Labour
                </p>

                <h4
                  className="
                    flex
                    items-center
                    gap-2
                    font-semibold
                  "
                >
                  <Users size={15} />

                  {site.labours || 0}
                </h4>

              </div>

            </div>

            {/* Last Update */}

            <div
              className="
                mt-5

                flex

                items-center

                justify-between

                border-t

                pt-4
              "
            >

              <div
                className="
                  flex
                  items-center
                  gap-2

                  text-xs

                  text-slate-500
                "
              >
                <Clock3 size={14} />

                Updated{" "}
                {site.updated_at
                  ? new Date(site.updated_at).toLocaleString()
                  : "--"}
              </div>

              <button
                className="
                  text-sm
                  font-medium
                  text-blue-600
                "
              >
                Open Project →
              </button>

            </div>

          </div>

        ))}

      </div>

    </section>
  );
}