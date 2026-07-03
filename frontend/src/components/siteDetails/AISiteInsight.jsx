import {

    Sparkles,

    AlertTriangle,

    CloudRain,

    TrendingUp,

    HardHat

} from "lucide-react";

export default function AISiteInsights({

    insights = []

}) {

    const defaultInsights = [

        {

            icon: CloudRain,

            title: "Weather Alert",

            message: "Rain expected tomorrow. Avoid concrete casting."

        },

        {

            icon: TrendingUp,

            title: "Progress Prediction",

            message: "Current speed indicates completion before deadline."

        },

        {

            icon: AlertTriangle,

            title: "Material Warning",

            message: "Cement stock may finish in next 3 days."

        },

        {

            icon: HardHat,

            title: "Labour Suggestion",

            message: "Increase labour by 4 workers for slab casting."

        }

    ];

    const data = insights.length ? insights : defaultInsights;

    return (

        <div className="rounded-3xl bg-gradient-to-br from-slate-900 via-blue-900 to-blue-700 text-white shadow-xl">

            <div className="p-6 border-b border-white/10">

                <div className="flex items-center gap-3">

                    <Sparkles className="text-cyan-300" />

                    <div>

                        <h2 className="text-xl font-bold">

                            AI Site Insights

                        </h2>

                        <p className="text-blue-100 text-sm mt-1">

                            Construction Intelligence

                        </p>

                    </div>

                </div>

            </div>

            <div className="p-6 space-y-5">

                {

                    data.map((item, index) => {

                        const Icon = item.icon;

                        return (

                            <div

                                key={index}

                                className="rounded-2xl bg-white/10 backdrop-blur p-5"

                            >

                                <div className="flex items-center gap-3">

                                    <div className="h-10 w-10 rounded-xl bg-cyan-400/20 flex items-center justify-center">

                                        <Icon size={20} />

                                    </div>

                                    <div>

                                        <h3 className="font-semibold">

                                            {item.title}

                                        </h3>

                                        <p className="text-sm text-blue-100 mt-1">

                                            {item.message}

                                        </p>

                                    </div>

                                </div>

                            </div>

                        )

                    })

                }

            </div>

        </div>

    )

}