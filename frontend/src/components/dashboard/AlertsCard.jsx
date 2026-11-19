import React from "react";
import {
    AlertTriangle,
    Clock3,
    Wallet
} from "lucide-react";

const alerts = [

    {
        title: "3 Sites Delayed",
        color: "text-red-600",
        icon: AlertTriangle
    },

    {
        title: "5 DPR Pending",
        color: "text-blue-500",
        icon: Clock3
    },

    {
        title: "2 Client Payments Due",
        color: "text-blue-600",
        icon: Wallet
    }

];

export default function AlertsCard() {

    return (

        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">

            <h2 className="text-xl font-bold">

                Attention Required

            </h2>

            <div className="space-y-5 mt-6">

                {

                    alerts.map((item, index) => {

                        const Icon = item.icon;

                        return (

                            <div

                                key={index}

                                className="flex items-center gap-4"

                            >

                                <div className="h-11 w-11 rounded-xl bg-slate-100 flex items-center justify-center">

                                    <Icon

                                        size={22}

                                        className={item.color}

                                    />

                                </div>

                                <div>

                                    <p className="font-medium">

                                        {item.title}

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