import React from "react";
import {
    IndianRupee,
    ClipboardCheck,
    Package,
    Users,
    Building2,
    Bell,
} from "lucide-react";

import { formatDistanceToNow } from "date-fns";

const config = {

    PAYMENT: {

        icon: IndianRupee,

        bg: "bg-green-100",

        color: "text-green-700",

        title: "Payment Recorded",

    },

    REPORT: {

        icon: ClipboardCheck,

        bg: "bg-blue-100",

        color: "text-blue-700",

        title: "Daily Progress Report",

    },

    MATERIAL: {

        icon: Package,

        bg: "bg-orange-100",

        color: "text-orange-700",

        title: "Material Updated",

    },

    LABOUR: {

        icon: Users,

        bg: "bg-indigo-100",

        color: "text-indigo-700",

        title: "Labour Activity",

    },

    SITE: {

        icon: Building2,

        bg: "bg-slate-100",

        color: "text-slate-700",

        title: "Site Updated",

    }

};

export default function RecentActivities({

    activities = []

}) {

    return (

        <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

            <div className="px-6 py-5 border-b">

                <h2 className="text-xl font-bold">

                    Recent Activities

                </h2>

                <p className="text-sm text-slate-500">

                    Latest updates from your company

                </p>

            </div>

            <div className="divide-y">

                {

                    activities.length === 0 ?

                        (

                            <div className="py-14 text-center text-slate-400">

                                No activity yet.

                            </div>

                        )

                        :

                        activities.slice(0, 8).map((activity) => {

                            const cfg = config[activity.type] || {

                                icon: Bell,

                                bg: "bg-slate-100",

                                color: "text-slate-700",

                                title: activity.title

                            };

                            const Icon = cfg.icon;

                            return (

                                <div

                                    key={activity.id}

                                    className="px-6 py-5 flex gap-4 hover:bg-slate-50 transition"

                                >

                                    <div

                                        className={`

                                        h-12

                                        w-12

                                        rounded-xl

                                        ${cfg.bg}

                                        flex

                                        items-center

                                        justify-center

                                    `}

                                    >

                                        <Icon

                                            className={cfg.color}

                                            size={20}

                                        />

                                    </div>

                                    <div className="flex-1">

                                        <div className="flex justify-between">

                                            <h3 className="font-semibold">

                                                {cfg.title}

                                            </h3>

                                            <span className="text-xs text-slate-400">

                                                {

                                                    formatDistanceToNow(

                                                        new Date(activity.created_at),

                                                        {

                                                            addSuffix: true

                                                        }

                                                    )

                                                }

                                            </span>

                                        </div>

                                        <p className="text-sm text-slate-500 mt-1">

                                            {

                                                activity.type === "PAYMENT"

                                                    ?

                                                    `Amount ${activity.description}`

                                                    :

                                                    activity.description ||

                                                    "Activity completed."

                                            }

                                        </p>

                                    </div>

                                </div>

                            )

                        })

                }

            </div>

        </div>

    )

}