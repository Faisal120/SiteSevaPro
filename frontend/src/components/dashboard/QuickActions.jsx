import React from "react";
import { useNavigate } from "react-router-dom";

import {
    Building2,
    Users,
    ClipboardCheck,
    Package,
    IndianRupee,
    FileText,
    Calculator,
    Camera,
    Plus,
    ArrowRight,
} from "lucide-react";

const actions = [
    {
        title: "Create Site",
        subtitle: "Start a new construction project",
        icon: Plus,
        color: "bg-blue-600",
        to: "/app/sites/new",
    },
    {
        title: "Manage Sites",
        subtitle: "View all active projects",
        icon: Building2,
        color: "bg-indigo-600",
        to: "/app/sites",
    },

    {
        title: "Daily Reports",
        subtitle: "Site progress updates",
        icon: ClipboardCheck,
        color: "bg-cyan-600",
        to: "/app/reports",
    },

    {
        title: "Estimates",
        subtitle: "BOQ & Quotations",
        icon: Calculator,
        color: "bg-slate-700",
        to: "/app/estimates",
    },

];

export default function QuickActions() {
    const navigate = useNavigate();

    return (
        <section className="space-y-5">

            <div className="flex items-center justify-between">

                <div>

                    <h2 className="text-xl font-bold text-slate-800">
                        Quick Actions
                    </h2>

                    <p className="text-sm text-slate-500">
                        Frequently used modules
                    </p>

                </div>

            </div>

            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">

                {actions.map((item) => {

                    const Icon = item.icon;

                    return (

                        <button
                            key={item.title}
                            onClick={() => navigate(item.to)}
                            className="
                group
                relative
                overflow-hidden

                rounded-3xl

                border
                border-slate-200

                bg-white

                p-5

                text-left

                transition-all
                duration-300

                hover:-translate-y-1
                hover:shadow-xl
              "
                        >
                            <div
                                className={`
                  h-14
                  w-14
                  rounded-2xl
                  flex
                  items-center
                  justify-center
                  text-white
                  ${item.color}
                `}
                            >
                                <Icon size={26} />
                            </div>

                            <h3
                                className="
                  mt-5
                  text-lg
                  font-semibold
                  text-slate-800
                "
                            >
                                {item.title}
                            </h3>

                            <p
                                className="
                  mt-1
                  text-sm
                  text-slate-500
                "
                            >
                                {item.subtitle}
                            </p>

                            <div
                                className="
                  mt-6
                  flex
                  items-center
                  justify-between
                "
                            >
                                <span
                                    className="
                    text-sm
                    font-medium
                    text-blue-600
                  "
                                >
                                    Open Module
                                </span>

                                <ArrowRight
                                    size={18}
                                    className="
                    text-blue-600
                    transition-transform
                    duration-300
                    group-hover:translate-x-1
                  "
                                />
                            </div>

                            <div
                                className="
                  absolute
                  inset-0
                  rounded-3xl
                  ring-2
                  ring-blue-500/0
                  transition-all
                  group-hover:ring-blue-500/20
                "
                            />

                        </button>

                    );

                })}

            </div>

        </section>
    );
}