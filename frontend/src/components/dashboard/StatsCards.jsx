import React from "react";
import CountUp from "react-countup";
import {
  Building2,
  Users,
  IndianRupee,
  Wallet,
  ClipboardList,
  Clock3,
  TrendingUp,
  Activity,
} from "lucide-react";

const cards = [
  {
    key: "active_sites",
    title: "Active Sites",
    icon: Building2,
    color: "bg-blue-100 text-blue-700",
  },
  {
    key: "labours",
    title: "Today's Labour",
    icon: Users,
    color: "bg-indigo-100 text-indigo-700",
  },
  {
    key: "cashflow",
    title: "Cash Flow",
    icon: IndianRupee,
    color: "bg-emerald-100 text-emerald-700",
    currency: true,
  },
  
  {
    key: "productivity",
    title: "Productivity",
    icon: Activity,
    color: "bg-slate-200 text-slate-800",
    suffix: "%",
  },
];

export default function StatsCards({ stats = {} }) {
  return (
    <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">

      {cards.map((item) => {

        const Icon = item.icon;

        const value = stats?.[item.key] ?? 0;

        return (

          <div
            key={item.key}
            className="
              group
              rounded-3xl
              border
              border-slate-200
              bg-white
              p-5
              transition-all
              duration-300
              hover:-translate-y-1
              hover:shadow-xl
            "
          >

            <div className="flex items-start justify-between">

              <div>

                <p
                  className="
                    text-xs
                    uppercase
                    tracking-wider
                    text-slate-500
                  "
                >
                  {item.title}
                </p>

                <h2
                  className="
                    mt-3
                    text-3xl
                    font-bold
                    text-slate-800
                  "
                >

                  {item.currency && "₹"}

                  <CountUp
                    end={Number(value)}
                    duration={1}
                    separator=","
                  />

                  {item.suffix}

                </h2>

              </div>

              <div
                className={`
                  h-14
                  w-14
                  rounded-2xl
                  flex
                  items-center
                  justify-center
                  ${item.color}
                `}
              >
                <Icon size={24} />
              </div>

            </div>

            <div
              className="
                mt-5
                flex
                items-center
                justify-between
              "
            >

              <span
                className="
                  text-xs
                  text-green-600
                  font-semibold
                "
              >
                Live Data
              </span>

              <span
                className="
                  h-2
                  w-2
                  rounded-full
                  bg-green-500
                  animate-pulse
                "
              />

            </div>

          </div>

        );

      })}

    </div>
  );
}