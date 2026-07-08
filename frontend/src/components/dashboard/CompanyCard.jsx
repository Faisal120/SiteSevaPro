import React from "react";

import {
    Building2,
    BadgeCheck,
    Crown,
    Users,
    HardHat,
    Calendar,
    Pencil
} from "lucide-react";

export default function CompanyCard({
    company,
    stats,
    user,
}) {

    const score =
        stats?.total_sites
            ? Math.round(
                (stats.completed_sites /
                    stats.total_sites) *
                100
            )
            : 0;

    return (

        <div className="rounded-3xl overflow-hidden bg-white border border-slate-200 shadow-sm">

            <div className="bg-gradient-to-r from-blue-700 to-slate-900 p-8 text-white">

                <div className="flex items-center gap-5">

                    <div className="h-20 w-20 rounded-3xl bg-white/10 backdrop-blur flex items-center justify-center">

                        <Building2 size={42} />

                    </div>

                    <div>

                        <h2 className="text-2xl font-bold">

                            {company?.branding?.company_name || "Company Name"}

                        </h2>

                        <div className="flex items-center gap-2 mt-2">

                            <BadgeCheck
                                size={18}
                                className="text-green-400"
                            />

                            <span className="text-sm">

                                Verified Contractor

                            </span>

                        </div>

                    </div>

                </div>

            </div>

            <div className="p-6">

                <div className="grid grid-cols-2 gap-5">

                    <div>

                        <p className="text-slate-500 text-sm">

                            Owner

                        </p>

                        <h3 className="font-semibold mt-1">

                            {user?.full_name || "Owner Name"}

                        </h3>

                    </div>

                    <div>

                        <p className="text-slate-500 text-sm">

                            Plan

                        </p>

                        <div className="flex items-center gap-2 mt-1">

                            <Crown
                                size={16}
                                className="text-yellow-500"
                            />

                            <span>

                                {company?.plan || "FREE"}

                            </span>

                        </div>

                    </div>

                    <div>

                        <p className="text-slate-500 text-sm">

                            Active Sites

                        </p>

                        <div className="flex items-center gap-2 mt-1">

                            <Building2 size={16} />

                            {stats?.active_sites || 0}

                        </div>

                    </div>

                    <div>

                        <p className="text-slate-500 text-sm">

                            Labours

                        </p>

                        <div className="flex items-center gap-2 mt-1">

                            <Users size={16} />

                            {stats?.labours || 0}

                        </div>

                    </div>

                    <div>

                        <p className="text-slate-500 text-sm">

                            Completed Projects

                        </p>

                        <div className="flex items-center gap-2 mt-1">

                            <HardHat size={16} />

                            {stats?.completed_sites || 0}

                        </div>

                    </div>

                    <div>

                        <p className="text-slate-500 text-sm">

                            Renewal

                        </p>

                        <div className="flex items-center gap-2 mt-1">

                            <Calendar size={16} />

                            {company?.renewal_date || "--"}

                        </div>

                    </div>

                </div>

                <div className="mt-8">

                    <p className="text-sm text-slate-500">

                        Company Completion Score

                    </p>

                    <div className="mt-3 h-3 rounded-full bg-slate-100">

                        <div

                            className="h-full rounded-full bg-gradient-to-r from-blue-600 to-green-500"


                            style={{

                                width: `${score}%`

                            }}

                        />

                    </div>

                    <div className="mt-2 text-right font-semibold">

                        {score}%

                    </div>

                </div>

                <button

                    className="

mt-8

w-full

rounded-2xl

bg-blue-600

hover:bg-blue-700

text-white

py-3

font-semibold

flex

items-center

justify-center

gap-2

"

                >

                    <Pencil size={18} />

                    Edit Company Profile

                </button>

            </div>

        </div>

    )

}