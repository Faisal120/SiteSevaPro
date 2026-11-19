import React from "react";
import {
    AlertTriangle,
    Clock3,
    IndianRupee,
    Package,
    Users,
    ArrowRight
} from "lucide-react";

import { useNavigate } from "react-router-dom";

export default function OperationsControlCenter({

    alerts = []

}) {

    const nav = useNavigate();

    return (

        <div className="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">

            <div className="px-6 py-5 border-b border-slate-100">

                <div className="flex items-center justify-between">

                    <div>

                        <div>

                            <h2 className="text-xl font-bold">

                                Operations Control Center

                            </h2>

                            <p className="mt-1 text-sm text-slate-500">

                                {alerts.length} Active Alert{alerts.length !== 1 && "s"}

                            </p>

                        </div>

                        <p className="text-sm text-slate-500 mt-1">

                            High priority actions requiring attention

                        </p>

                    </div>

                    <div className="h-12 w-12 rounded-xl bg-red-50 flex items-center justify-center">
                        <AlertTriangle className="text-red-600" />
                    </div>

                </div>

            </div>

            <div>

                {

                    alerts.length === 0 ?

                        (

                            <div className="p-10 text-center">

                                <AlertTriangle

                                    size={48}

                                    className="mx-auto text-green-500"

                                />

                                <h3 className="mt-5 font-semibold text-lg">

                                    Everything Looks Good

                                </h3>

                                <p className="text-slate-500 mt-2">

                                    All operations are running normally.

                                    No high-priority alerts require your attention.

                                </p>

                            </div>

                        )

                        :

                        alerts.map((item, index) => {

                            const icons = {
                                TASK: Clock3,
                                PAYMENT: IndianRupee,
                                MATERIAL: Package,
                                LABOUR: Users,
                                SITE: AlertTriangle,
                            };

                            const severityColors = {
                                HIGH: {
                                    bg: "bg-red-50",
                                    text: "text-red-600",
                                    chip: "bg-red-100 text-red-700",
                                },
                                MEDIUM: {
                                    bg: "bg-blue-50",
                                    text: "text-blue-600",
                                    chip: "bg-blue-100 text-blue-700",
                                },
                                LOW: {
                                    bg: "bg-blue-50",
                                    text: "text-blue-600",
                                    chip: "bg-blue-100 text-blue-700",
                                },
                            };

                            const Icon = icons[item.type] || AlertTriangle;

                            const style =
                                severityColors[item.severity] ||
                                severityColors.HIGH;

                            return (

                                <div

                                    key={index}

                                    className="

                                flex

                                items-center

                                justify-between

                                px-6

                                py-5

                                border-b

                                last:border-0

                                hover:bg-slate-50

                                transition

                                "

                                >

                                    <div className="flex items-center gap-4">

                                        <div className="h-12 w-12 rounded-xl bg-red-50 flex items-center justify-center">

                                            <Icon className={style.text} />

                                        </div>

                                        <div>

                                            <h3 className="font-semibold">

                                                {item.title}

                                            </h3>

                                            <div className="mt-2">

                                                <span
                                                    className={`
            inline-flex
            items-center
            rounded-full
            px-2.5
            py-1
            text-xs
            font-semibold
            ${style.chip}
        `}
                                                >
                                                    {item.severity}
                                                </span>

                                            </div>

                                            <p className="text-sm text-slate-500">

                                                {item.description ||
                                                    "Requires immediate attention."}

                                            </p>

                                        </div>

                                    </div>

                                    <button

                                        onClick={() => {

                                            if (item.route) {

                                                nav(item.route);

                                            }

                                        }}

                                        className="text-blue-600 flex items-center gap-2 font-medium"

                                    >

                                        Open

                                        <ArrowRight size={18} />

                                    </button>

                                </div>

                            )

                        })

                }

            </div>

        </div>

    )

}