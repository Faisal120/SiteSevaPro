import React from "react";
import {
    Sparkles,
    CloudRain,
    TriangleAlert,
    TrendingUp,
    Package,
    Users,
    IndianRupee,
    Bot,
    Send,
    RefreshCcw
} from "lucide-react";

const defaultInsights = [
    {
        title: "Weather Alert",
        description: "Heavy rain expected tomorrow. Avoid slab casting.",
        icon: CloudRain,
        color: "blue"
    },
    {
        title: "Delay Prediction",
        description: "Project has 18% delay probability.",
        icon: TriangleAlert,
        color: "orange"
    },
    {
        title: "Material Forecast",
        description: "Cement stock may finish in 4 days.",
        icon: Package,
        color: "red"
    },
    {
        title: "Labour Optimization",
        description: "Increase 5 labourers for slab work.",
        icon: Users,
        color: "green"
    },
    {
        title: "Cashflow Forecast",
        description: "₹6.2L payment expected this week.",
        icon: IndianRupee,
        color: "violet"
    }
];

export default function AITab({

    insights = defaultInsights,

    actions = {}

}) {

    return (

        <div className="space-y-6">

            {/* Header */}

            <div className="rounded-3xl bg-gradient-to-r from-slate-900 via-blue-900 to-blue-700 text-white p-8 shadow-xl">

                <div className="flex justify-between items-center">

                    <div>

                        <div className="flex items-center gap-3">

                            <Sparkles className="text-cyan-300" />

                            <h2 className="text-3xl font-bold">

                                AI Construction Command Center

                            </h2>

                        </div>

                        <p className="mt-3 text-blue-100">

                            AI powered construction intelligence

                        </p>

                    </div>

                    <button

                        onClick={actions.refreshAI}

                        className="rounded-xl bg-white text-slate-900 px-5 h-11 flex items-center gap-2"

                    >

                        <RefreshCcw size={18} />

                        Refresh

                    </button>

                </div>

            </div>

            {/* AI Cards */}

            <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-6">

                {

                    insights.map((item, index) => {

                        const Icon = item.icon;

                        return (

                            <div

                                key={index}

                                className="rounded-3xl bg-white border border-slate-200 p-6 shadow-sm"

                            >

                                <div className="flex justify-between">

                                    <div className={`

h-14

w-14

rounded-2xl

flex

items-center

justify-center

bg-${item.color}-50

text-${item.color}-600

`}>

                                        <Icon size={24} />

                                    </div>

                                    <Sparkles

                                        size={18}

                                        className="text-blue-500"

                                    />

                                </div>

                                <h3 className="mt-6 text-lg font-bold">

                                    {item.title}

                                </h3>

                                <p className="mt-3 text-slate-500">

                                    {item.description}

                                </p>

                            </div>

                        )

                    })

                }

            </div>

            {/* AI Chat */}

            <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

                <div className="flex items-center gap-3 p-6 border-b">

                    <Bot className="text-blue-600" />

                    <div>

                        <h2 className="text-xl font-bold">

                            Construction AI Assistant

                        </h2>

                        <p className="text-slate-500">

                            Ask anything about this project

                        </p>

                    </div>

                </div>

                <div className="p-6">

                    <div className="rounded-2xl bg-slate-50 p-6 h-80 overflow-auto">

                        <div className="rounded-2xl bg-blue-600 text-white inline-block px-4 py-3">

                            Hello 👋

                            How can I help you with this project?

                        </div>

                    </div>

                    <div className="mt-5 flex gap-3">

                        <input

                            placeholder="Ask AI about labour, materials, delays..."

                            className="flex-1 h-12 rounded-xl border px-4"

                        />

                        <button

                            className="h-12 px-6 rounded-xl bg-blue-600 text-white"

                        >

                            <Send />

                        </button>

                    </div>

                </div>

            </div>

            {/* Suggested Prompts */}

            <div className="rounded-3xl bg-white border border-slate-200 p-6">

                <h2 className="font-bold mb-5">

                    Suggested Questions

                </h2>

                <div className="flex flex-wrap gap-3">

                    {

                        [

                            "Why is project delayed?",

                            "Forecast material usage",

                            "Labour productivity",

                            "Weekly cashflow",

                            "Project risks",

                            "Generate DPR Summary"

                        ].map(prompt => (

                            <button

                                key={prompt}

                                className="rounded-full border px-4 py-2 hover:bg-blue-50"

                            >

                                {prompt}

                            </button>

                        ))

                    }

                </div>

            </div>

        </div>

    )

}