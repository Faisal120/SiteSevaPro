import {
  Building2,
  MapPin,
  Calendar,
  Wallet,
  User,
  HardHat,
  Plus,
  ClipboardList,
  Package,
  Receipt
} from "lucide-react";

import { useNavigate } from "react-router-dom";
import {

  useSite

}

  from "@/context/SiteContext";

export default function SiteHero({ site }) {

  const navigate = useNavigate();
  const {site}= useSite();

  return (

    <div className="rounded-3xl bg-gradient-to-r from-slate-900 via-blue-900 to-blue-700 text-white shadow-xl overflow-hidden">

      <div className="p-8">

        <div className="flex flex-col xl:flex-row justify-between gap-8">

          {/* Left */}

          <div>

            <div className="flex items-center gap-3">

              <div className="h-14 w-14 rounded-2xl bg-white/10 flex items-center justify-center">

                <Building2 size={28} />

              </div>

              <div>

                <h1 className="text-3xl font-bold">

                  {site?.site_name}

                </h1>

                <div className="flex items-center gap-2 mt-2 text-blue-100">

                  <MapPin size={16} />

                  {site?.location}

                </div>

              </div>

            </div>

            {/* Progress */}

            <div className="mt-8">

              <div className="flex justify-between text-sm mb-2">

                <span>Project Progress</span>

                <span>{site?.progress || 0}%</span>

              </div>

              <div className="h-3 bg-white/20 rounded-full">

                <div

                  className="h-full bg-cyan-400 rounded-full"

                  style={{

                    width: `${site?.progress || 0}%`

                  }}

                />

              </div>

            </div>

          </div>

          {/* Right */}

          <div className="grid grid-cols-2 gap-5 min-w-[340px]">

            <Info icon={<User size={18} />} title="Client" value={site?.client_name} />

            <Info icon={<HardHat size={18} />} title="Supervisor" value={site?.supervisor_name} />

            <Info icon={<Wallet size={18} />} title="Budget" value={`₹${Number(site?.budget || 0).toLocaleString("en-IN")}`} />

            <Info icon={<Calendar size={18} />} title="Completion" value={site?.completion_date} />

          </div>

        </div>

        {/* Quick Actions */}

        <div className="mt-8 flex flex-wrap gap-4">

          <ActionButton
            icon={<Plus size={18} />}
            text="Add Labour"
            onClick={() => navigate(`/app/labour?site=${site?._id}`)}
          />

          <ActionButton
            icon={<Package size={18} />}
            text="Material Entry"
            onClick={() => navigate(`/app/materials?site=${site?._id}`)}
          />

          <ActionButton
            icon={<ClipboardList size={18} />}
            text="Daily Report"
            onClick={() => navigate(`/app/reports?site=${site?._id}`)}
          />

          <ActionButton
            icon={<Receipt size={18} />}
            text="Expense"
            onClick={() => navigate(`/app/expenses?site=${site?._id}`)}
          />

        </div>

      </div>

    </div>

  );

}

function Info({ icon, title, value }) {

  return (

    <div className="rounded-2xl bg-white/10 backdrop-blur p-4">

      <div className="flex items-center gap-2 text-blue-100">

        {icon}

        <span>{title}</span>

      </div>

      <div className="mt-3 font-semibold text-lg">

        {value || "--"}

      </div>

    </div>

  );

}

function ActionButton({ icon, text, onClick }) {

  return (

    <button

      onClick={onClick}

      className="flex items-center gap-2 rounded-2xl bg-white text-slate-900 px-5 py-3 font-semibold hover:bg-blue-50 transition"

    >

      {icon}

      {text}

    </button>

  );

}