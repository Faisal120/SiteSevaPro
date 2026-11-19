import {
    Building2,
    CheckCircle2,
    AlertTriangle,
    IndianRupee
} from "lucide-react";

export default function SiteStatsBar({ stats }) {

    const cards = [

        {
            title: "Active Sites",
            value: stats?.active || 0,
            icon: Building2,
            color: "text-blue-600 bg-blue-50"
        },

        {
            title: "Completed",
            value: stats?.completed || 0,
            icon: CheckCircle2,
            color: "text-green-600 bg-green-50"
        },

        {
            title: "Delayed",
            value: stats?.delayed || 0,
            icon: AlertTriangle,
            color: "text-blue-600 bg-blue-50"
        },

        {
            title: "Running Value",
            value: stats?.value || "₹0",
            icon: IndianRupee,
            color: "text-violet-600 bg-violet-50"
        }

    ];

    return (

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">

            {

                cards.map((card, index) => {

                    const Icon = card.icon;

                    return (

                        <div
                            key={index}
                            className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm hover:shadow-lg transition"
                        >

                            <div className="flex items-center justify-between">

                                <div>

                                    <p className="text-sm text-slate-500">

                                        {card.title}

                                    </p>

                                    <h2 className="mt-3 text-3xl font-bold">

                                        {card.value}

                                    </h2>

                                </div>

                                <div className={`h-14 w-14 rounded-2xl flex items-center justify-center ${card.color}`}>

                                    <Icon size={26} />

                                </div>

                            </div>

                        </div>

                    );

                })

            }

        </div>

    );

}