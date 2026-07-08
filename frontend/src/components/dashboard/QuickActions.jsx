import React from "react";
import { useNavigate } from "react-router-dom";

import {
    Building2,
    ClipboardCheck,
    Calculator,
    Plus,
    ArrowRight,
} from "lucide-react";

const actions = [
    {
        title: "Create Site",
        subtitle: "Start a new construction project",
        icon: Plus,
        color: "from-blue-600 to-indigo-600",
        to: "/app/sites/new",
        featured: true,
    },
    {
        title: "Manage Sites",
        subtitle: "View and monitor all projects",
        icon: Building2,
        color: "from-slate-700 to-slate-800",
        to: "/app/sites",
    },
    {
        title: "Daily Reports",
        subtitle: "Progress updates & photos",
        icon: ClipboardCheck,
        color: "from-cyan-500 to-blue-500",
        to: "/app/reports",
    },
    {
        title: "Estimates",
        subtitle: "BOQ & Quotations",
        icon: Calculator,
        color: "from-orange-500 to-amber-500",
        to: "/app/estimates",
    },
];

export default function QuickActions() {
    const navigate = useNavigate();

    return (
        <section className="space-y-6">

            <div className="flex items-end justify-between">

                <div>

                    <h2 className="font-display text-2xl font-bold tracking-tight">
                        Quick Workspace
                    </h2>

                    <p className="mt-1 text-sm text-slate-500">
                        Access your most frequently used modules.
                    </p>

                </div>

            </div>

            <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">

                {actions.map((item) => {

                    const Icon = item.icon;

                    return (

                        <button
                            key={item.title}
                            onClick={() => navigate(item.to)}
                            className={`
                                group
                                relative
                                overflow-hidden

                                rounded-[28px]

                                border

                                transition-all
                                duration-300

                                hover:-translate-y-1
                                hover:shadow-2xl

                                ${item.featured
                                    ? "border-blue-200 bg-gradient-to-br from-blue-600 to-indigo-700 text-white"
                                    : "border-slate-200 bg-white"}
                            `}
                        >

                            {/* Glow */}

                            <div
                                className="
                                    absolute

                                    -right-10
                                    -top-10

                                    h-40
                                    w-40

                                    rounded-full

                                    bg-white/10

                                    blur-2xl
                                "
                            />

                            <div className="relative p-6">

                                <div className="flex items-center justify-between">

                                    <div
                                        className={`
                                            flex
                                            h-14
                                            w-14
                                            items-center
                                            justify-center

                                            rounded-2xl

                                            ${item.featured
                                                ? "bg-white/20"
                                                : `bg-gradient-to-br ${item.color} text-white`
                                            }
                                        `}
                                    >
                                        <Icon size={28} />
                                    </div>

                                    {!item.featured && (
                                        <ArrowRight
                                            size={18}
                                            className="
                                                text-slate-300

                                                transition-all

                                                group-hover:translate-x-1
                                                group-hover:text-blue-600
                                            "
                                        />
                                    )}

                                </div>

                                <h3
                                    className={`
                                        mt-8

                                        text-xl

                                        font-bold

                                        ${item.featured
                                            ? "text-white"
                                            : "text-slate-800"}
                                    `}
                                >
                                    {item.title}
                                </h3>

                                <p
                                    className={`
                                        mt-2

                                        text-sm

                                        leading-6

                                        ${item.featured
                                            ? "text-blue-100"
                                            : "text-slate-500"}
                                    `}
                                >
                                    {item.subtitle}
                                </p>

                                <div className="mt-8">

                                    <span
                                        className={`
                                            inline-flex

                                            items-center

                                            gap-2

                                            rounded-full

                                            px-4

                                            py-2

                                            text-sm

                                            font-semibold

                                            transition-all

                                            ${item.featured
                                                ? "bg-white text-blue-700"
                                                : "bg-blue-50 text-blue-700 group-hover:bg-blue-100"}
                                        `}
                                    >
                                        Visit Now

                                        <ArrowRight size={16} />

                                    </span>

                                </div>

                            </div>

                        </button>

                    );

                })}

            </div>

        </section>
    );
}