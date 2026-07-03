import React from "react";
import {
  Building2,
  Users,
  ClipboardList,
  IndianRupee,
  TrendingUp,
} from "lucide-react";
import { formatCurrency } from "@/utils/currency";

const cards = [

  {

    title: "Active Sites",

    value: stats?.active_sites ?? 0,

    icon: Building2,

    color: "bg-blue-50 text-blue-600",

    change: "Live"

  },

  {

    title: "Today's Labour",

    value: stats?.labours ?? 0,

    icon: Users,

    color: "bg-emerald-50 text-emerald-600",

    change: "Live"

  },

  {

    title: "Pending Tasks",

    value: stats?.pending_tasks ?? 0,

    icon: ClipboardList,

    color: "bg-orange-50 text-orange-600",

    change: "Live"

  },

  {

    title: "Cash Flow",

    value: formatCurrency(

      stats?.cash_flow

    ),

    icon: IndianRupee,

    color: "bg-violet-50 text-violet-600",

    change: "Live"

  }

];

export default function StatsCards({

  stats

}) {
  return (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">

      {cards.map((card) => {

        const Icon = card.icon;

        return (

          <div
            key={card.title}
            className="
              group
              rounded-3xl
              border
              border-slate-200
              bg-white
              p-6
              shadow-sm
              transition-all
              duration-300
              hover:-translate-y-1
              hover:shadow-xl
            "
          >

            <div className="flex items-start justify-between">

              <div>

                <p className="text-sm text-slate-500">

                  {card.title}

                </p>

                <h2 className="mt-3 text-3xl font-bold text-slate-900">

                  <div className="mt-3">

                    <h2 className="text-3xl font-bold">

                      {card.value}

                    </h2>

                  </div>

                </h2>

              </div>

              <div
                className={`
                  ${card.color}
                  flex
                  h-14
                  w-14
                  items-center
                  justify-center
                  rounded-2xl
                `}
              >

                <Icon size={28} />

              </div>

            </div>

            <div className="mt-6 flex items-center gap-2">

              <TrendingUp
                size={16}
                className="text-emerald-600"
              />

              <span className="text-sm font-medium text-emerald-600">

                {card.change}

              </span>

            </div>

          </div>

        );

      })}

    </div>
  );
}