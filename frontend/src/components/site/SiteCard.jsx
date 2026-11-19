import React from "react";
import {
  Building2,
  MapPin,
  User,
  HardHat,
  Wallet,
  Package,
  ArrowRight,
  CheckCircle2,
  AlertTriangle,
} from "lucide-react";
import { useNavigate } from "react-router-dom";

export default function SiteCard({ site }) {
  const navigate = useNavigate();

  const progress = site?.progress ?? 0;
  const health = site?.health_score ?? 85;

  const healthColor =
    health >= 80
      ? "text-green-600 bg-green-50"
      : health >= 60
      ? "text-yellow-600 bg-yellow-50"
      : "text-red-600 bg-red-50";

  return (
    <div className="rounded-3xl border border-slate-200 bg-white shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden">

      {/* Header */}
      <div className="p-6 border-b border-slate-100 flex justify-between items-start">

        <div>

          <h2 className="text-xl font-bold text-slate-900">
            {site?.site_name}
          </h2>

          <div className="flex items-center gap-2 mt-2 text-sm text-slate-500">

            <MapPin size={15} />

            {site?.location || "Location"}

          </div>

        </div>

        <div className={`px-3 py-2 rounded-xl ${healthColor}`}>

          <div className="text-xs uppercase font-semibold">

            Health

          </div>

          <div className="font-bold">

            {health}/100

          </div>

        </div>

      </div>

      {/* Progress */}

      <div className="px-6 py-5">

        <div className="flex justify-between mb-2">

          <span className="text-sm text-slate-500">

            Progress

          </span>

          <span className="font-semibold">

            {progress}%

          </span>

        </div>

        <div className="h-3 bg-slate-100 rounded-full overflow-hidden">

          <div
            className="h-full bg-gradient-to-r from-blue-600 to-cyan-500"
            style={{ width: `${progress}%` }}
          />

        </div>

        <div className="mt-3 text-sm text-slate-600">

          Current Stage :
          <span className="font-semibold ml-2">

            {site?.current_stage || "Planning"}

          </span>

        </div>

      </div>

      {/* Details */}

      <div className="grid grid-cols-2 gap-4 px-6 pb-6">

        <InfoRow
          icon={<User size={16} />}
          title="Client"
          value={site?.client_name || "-"}
        />

        <InfoRow
          icon={<HardHat size={16} />}
          title="Supervisor"
          value={site?.supervisor_name || "-"}
        />

        <InfoRow
          icon={<Building2 size={16} />}
          title="Labour"
          value={site?.today_labour || 0}
        />

        <InfoRow
          icon={<Wallet size={16} />}
          title="Expense"
          value={`₹${Number(site?.today_expense || 0).toLocaleString("en-IN")}`}
        />

        <InfoRow
          icon={<Package size={16} />}
          title="Material"
          value={site?.material_status || "Good"}
        />

        <InfoRow
          icon={
            site?.payment_pending ? (
              <AlertTriangle size={16} className="text-blue-500" />
            ) : (
              <CheckCircle2 size={16} className="text-green-600" />
            )
          }
          title="Payment"
          value={site?.payment_pending ? "Pending" : "Clear"}
        />

      </div>

      {/* Footer */}

      <div className="border-t border-slate-100 p-5">

        <button
          onClick={() => navigate(`/app/sites/${site._id}`)}
          className="w-full rounded-2xl bg-blue-600 hover:bg-blue-700 text-white py-3 font-semibold flex items-center justify-center gap-2 transition"
        >

          Open Command Center

          <ArrowRight size={18} />

        </button>

      </div>

    </div>
  );
}

function InfoRow({ icon, title, value }) {
  return (
    <div className="rounded-2xl bg-slate-50 p-4">

      <div className="flex items-center gap-2 text-slate-500 text-sm">

        {icon}

        {title}

      </div>

      <div className="mt-2 font-semibold text-slate-900">

        {value}

      </div>

    </div>
  );
}