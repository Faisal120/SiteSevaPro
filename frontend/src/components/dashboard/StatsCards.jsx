import React from "react";
import CountUp from "react-countup";
import {
  Building2,
  Users,
  Activity,
  Package,
  Package2,
} from "lucide-react";

const cards = [
  {
    key: "active_sites",
    title: "Active Projects",
    icon: Building2,
    iconBg: "bg-blue-500/15",
    iconColor: "text-blue-400",
    valueColor: "text-slate-900",
  },
  {
    key: "labours",
    title: "Total Workforce",
    icon: Users,
    iconBg: "bg-violet-100",
    iconColor: "text-violet-700",
    valueColor: "text-slate-900",
  },
  {
    key: "pending_tasks",
    title: "Pending Tasks",
    icon: Activity,
    iconBg: "bg-blue-100",
    iconColor: "text-blue-900",
    valueColor: "text-blue-700",
  },
  {
    key: "low_stock",
    title: "Low Stock Items",
    icon: Package, // we'll replace with Package icon if you import it
    iconBg: "bg-red-100",
    iconColor: "text-red-700",
    valueColor: "text-red-700",
  },
];

export default function StatsCards({ stats = {} }) {
  return (
    <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map((item) => {
        const Icon = item.icon;
        let value = stats?.[item.key];

        if (item.isArray) {
          value = Array.isArray(value) ? value.length : 0;
        }

        value ??= 0;

        return (
          <div
            key={item.key}
            className="
              group
              relative
              overflow-hidden

              rounded-[20px]

              border
              border-slate-200

              bg-white

              p-6

              transition-all
              duration-300

              hover:-translate-y-1
              hover:border-blue-500/60
              hover:shadow-none
            "
          >
            {/* Background Glow */}

            <div
              className="
                absolute

                -right-12
                -top-12

                h-40
                w-40

                rounded-full

                bg-blue-500/10

                opacity-0

                transition-all

                duration-500

                group-hover:opacity-100
              "
            />

            <div className="relative z-10">

              {/* Header */}

              <div className="flex items-center justify-between">

                <div>

                  <p
                    className="
                      text-xs

                      font-semibold

                      uppercase

                      tracking-[0.18em]

                      text-slate-400
                    "
                  >
                    {item.title}
                  </p>

                </div>

                <div
                  className={`
                    flex
                    h-14
                    w-14
                    items-center
                    justify-center

                    rounded-2xl

                    ${item.iconBg}
                  `}
                >
                  <Icon
                    size={26}
                    className={item.iconColor}
                  />
                </div>

              </div>

              {/* Value */}

              <div className="mt-7">

                <h2
                  className={`
                    text-4xl

                    font-bold

                    tracking-tight

                    ${item.valueColor}
                  `}
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

              {/* Footer */}

              <div className="mt-5 flex items-center justify-between">

                <span className="text-xs font-medium text-slate-500">

                  {item.key === "active_sites"
                    ? "Projects in progress"
                    : item.key === "labours"
                      ? "Registered workforce"
                      : item.key === "pending_tasks"
                        ? "Needs immediate attention"
                        : "Material procurement required"}

                </span>

                <span className="h-2 w-2 rounded-full bg-green-500 animate-pulse" />

              </div>

            </div>

          </div>
        );
      })}
    </div>
  );
}
