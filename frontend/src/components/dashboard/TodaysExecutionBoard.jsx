import React from "react";

import {
    CheckCircle2,
    ClipboardCheck,
    Package,
    Users,
    FileText,
    IndianRupee,
    ArrowRight,
} from "lucide-react";

import { useNavigate } from "react-router-dom";


export default function TodaysExecutionBoard({

    stats = {}

}) {

    const navigate = useNavigate();


    const items = [
        {
            title: "Pending Tasks",
            value: stats.pending_tasks,
            icon: ClipboardCheck,
            color: "bg-orange-100 text-orange-700",
            route: "/app/tasks",
        },
        {
            title: "Today's Labour",
            value: stats.today_labours,
            icon: Users,
            color: "bg-blue-100 text-blue-700",
            route: "/app/labour",
        },
        {
            title: "Daily Reports",
            value: stats.today_reports,
            icon: FileText,
            color: "bg-indigo-100 text-indigo-700",
            route: "/app/reports",
        },
        {
            title: "Low Stock Items",
            value: stats.low_stock,
            icon: Package,
            color: "bg-red-100 text-red-700",
            route: "/app/materials",
        },
        {
            title: "Pending Payments",
            value: `₹${Number(stats.pending_payments).toLocaleString()}`,
            icon: IndianRupee,
            color: "bg-emerald-100 text-emerald-700",
            route: "/app/payments",
        },
        {
            title: "Completed Tasks",
            value: stats.completed_tasks,
            icon: CheckCircle2,
            color: "bg-green-100 text-green-700",
            route: "/app/tasks",
        },
    ];

    return (

        <div className="mt-10">

            <div className="flex items-center justify-between mb-6">

                <div>

                    <h2 className="text-2xl font-bold">

                        Today's Execution Board

                    </h2>

                    <p className="text-slate-500 mt-1">

                        Everything you need to complete today

                    </p>

                </div>

            </div>

            <div className="rounded-3xl border border-slate-200 bg-white shadow-sm">

                {
                    <div className="divide-y divide-slate-100">

                        {items.map((item) => {

                            const Icon = item.icon;

                            const needsAttention =
                                typeof item.value === "number"
                                    ? item.value > 0
                                    : item.value !== "₹0";

                            return (

                                <button
                                    key={item.title}
                                    onClick={() => navigate(item.route)}
                                    className="
                    w-full
                    flex
                    items-center
                    justify-between
                    p-6
                    hover:bg-slate-50
                    transition
                "
                                >

                                    <div className="flex items-center gap-5">

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

                                        <div className="text-left">

                                            <h3 className="font-semibold text-slate-800">
                                                {item.title}
                                            </h3>

                                            <p className="mt-1 text-sm text-slate-500">

                                                {needsAttention
                                                    ? "Needs attention"
                                                    : "All clear"}

                                            </p>

                                        </div>

                                    </div>

                                    <div className="flex items-center gap-6">

                                        <div className="text-right">

                                            <div className="text-2xl font-bold">

                                                {item.value}

                                            </div>

                                            <span
                                                className={`
                                inline-flex
                                rounded-full
                                px-2.5
                                py-1
                                text-xs
                                font-semibold
                                ${needsAttention
                                                        ? "bg-orange-100 text-orange-700"
                                                        : "bg-green-100 text-green-700"
                                                    }
                            `}
                                            >
                                                {needsAttention
                                                    ? "Attention"
                                                    : "Completed"}
                                            </span>

                                        </div>

                                        <ArrowRight
                                            size={18}
                                            className="text-slate-400"
                                        />

                                    </div>

                                </button>

                            );

                        })}

                    </div>
                }

            </div>

        </div >

    )

}