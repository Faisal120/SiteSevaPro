import React from "react";
import {
    CheckCircle2,
    Clock3,
    ArrowRight
} from "lucide-react";



export default function SiteCommandCenter({

    sites = []

}) {

    return (

        <div className="mt-10">

            <div className="flex items-center justify-between mb-6">

                <div>

                    <h2 className="text-2xl font-bold">

                        Site Command Center

                    </h2>

                    <p className="text-slate-500 mt-1">

                        Monitor all active construction sites

                    </p>

                </div>

            </div>

            <div className="space-y-5">

                {

                    sites.length === 0 ? (

                        <div className="rounded-3xl bg-white border border-dashed border-slate-300 p-12 text-center">

                            <h3 className="text-lg font-semibold text-slate-700">

                                No Active Sites

                            </h3>

                            <p className="text-slate-500 mt-2">

                                Create your first construction site to start tracking progress.

                            </p>

                        </div>

                    ) : (

                        sites.map((site) => (

                            <div

                                key={site.id}

                                className="

                            rounded-3xl

                            bg-white

                            border

                            border-slate-200

                            p-6

                            shadow-sm

                            hover:shadow-xl

                            transition-all

                            "

                            >

                                <div className="flex justify-between items-start">

                                    <div>

                                        <h3 className="text-lg font-bold">

                                            {site.site_name || site.name}

                                        </h3>

                                        <p className="text-slate-500 mt-1">

                                            Current Stage

                                        </p>

                                        <p className="font-semibold mt-1">

                                            {site.current_stage || "Planning"}

                                        </p>

                                    </div>

                                    <button

                                        onClick={() =>

                                            window.location.href =

                                            `/app/sites/${site.id}`

                                        }

                                        className="

                                    flex

                                    items-center

                                    gap-2

                                    text-blue-600

                                    font-semibold

                                    "

                                    >

                                        View Site

                                        <ArrowRight size={18} />

                                    </button>

                                </div>

                                <div className="mt-6">

                                    <div className="flex justify-between mb-2">

                                        <span>

                                            Progress

                                        </span>

                                        <span className="font-bold">

                                            {site.progress ?? 0}%

                                        </span>

                                    </div>

                                    <div className="h-3 rounded-full bg-slate-100 overflow-hidden">

                                        <div

                                            className="h-full rounded-full bg-gradient-to-r from-blue-600 to-blue-400"

                                            style={{

                                                width: `${site.progress ?? 0}%`

                                            }}

                                        />

                                    </div>

                                </div>

                                <div className="mt-5 flex items-center gap-2">

                                    {

                                        site.status === "On Track"

                                            ?

                                            <CheckCircle2

                                                size={18}

                                                className="text-green-600"

                                            />

                                            :

                                            <Clock3

                                                size={18}

                                                className="text-orange-500"

                                            />

                                    }

                                    <span className="text-sm">

                                        site.status || "On Track"

                                    </span>

                                </div>

                            </div>

                        )))

                }

            </div>

        </div>

    )

}