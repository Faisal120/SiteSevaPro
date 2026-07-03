import React from "react";
import { useNavigate } from "react-router-dom";

import {
    Building2,
    Camera,
    Users,
    Package,
    ArrowRight
} from "lucide-react";

const actions = [

    {
        title: "Create Site",
        subtitle: "Start a new project",
        icon: Building2,
        color: "from-blue-600 to-blue-700",
        route: "/app/sites"
    },

    {
        title: "Daily Report",
        subtitle: "Submit today's DPR",
        icon: Camera,
        color: "from-emerald-600 to-green-700",
        route: "/app/reports"
    },

    {
        title: "Labour Attendance",
        subtitle: "Mark today's attendance",
        icon: Users,
        color: "from-orange-500 to-orange-600",
        route: "/app/labour"
    },

    {
        title: "Material Entry",
        subtitle: "Add stock or consumption",
        icon: Package,
        color: "from-violet-600 to-purple-700",
        route: "/app/materials"
    }

];

export default function QuickActions() {

    const nav = useNavigate();

    return (

        <div className="mt-8">

            <div className="flex items-center justify-between mb-5">

                <div>

                    <h2 className="text-xl font-bold text-slate-900">

                        Quick Actions

                    </h2>

                    <p className="text-sm text-slate-500 mt-1">

                        Frequently used actions

                    </p>

                </div>

            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">

                {

                    actions.map((item)=>{

                        const Icon=item.icon;

                        return(

                            <button

                                key={item.title}

                                onClick={()=>nav(item.route)}

                                className="

                                group

                                rounded-3xl

                                overflow-hidden

                                shadow-lg

                                text-left

                                transition-all

                                duration-300

                                hover:-translate-y-1

                                hover:shadow-2xl

                                "

                            >

                                <div

                                    className={`

                                    bg-gradient-to-r

                                    ${item.color}

                                    p-6

                                    text-white

                                    `}

                                >

                                    <div className="flex items-center justify-between">

                                        <div>

                                            <Icon size={34}/>

                                        </div>

                                        <ArrowRight

                                            size={22}

                                            className="

                                            transition-transform

                                            group-hover:translate-x-1

                                            "

                                        />

                                    </div>

                                    <h3 className="mt-8 text-lg font-bold">

                                        {item.title}

                                    </h3>

                                    <p className="text-sm text-white/80 mt-1">

                                        {item.subtitle}

                                    </p>

                                </div>

                            </button>

                        )

                    })

                }

            </div>

        </div>

    )

}