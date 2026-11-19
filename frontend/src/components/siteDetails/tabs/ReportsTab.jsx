import React from "react";
import {
    FileText,
    Camera,
    Calendar,
    User,
    Eye,
    Download,
    Plus,
    CheckCircle2,
    Clock3
} from "lucide-react";

export default function ReportsTab({

    reports = [],

    actions = {}

}) {

    const total = reports.length;

    const approved = reports.filter(

        r => r.status === "Approved"

    ).length;

    const pending = reports.filter(

        r => r.status === "Pending"

    ).length;

    const rejected = reports.filter(

        r => r.status === "Rejected"

    ).length;

    return (

        <div className="space-y-6">

            {/* KPI Cards */}

            <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-5">

                <StatCard

                    title="Reports"

                    value={total}

                    icon={FileText}

                    color="blue"

                />

                <StatCard

                    title="Approved"

                    value={approved}

                    icon={CheckCircle2}

                    color="green"

                />

                <StatCard

                    title="Pending"

                    value={pending}

                    icon={Clock3}

                    color="blue"

                />

                <StatCard

                    title="Rejected"

                    value={rejected}

                    icon={FileText}

                    color="red"

                />

            </div>

            {/* Header */}

            <div className="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">

                <div className="flex items-center justify-between p-6 border-b">

                    <div>

                        <h2 className="text-xl font-bold">

                            Daily Progress Reports

                        </h2>

                        <p className="text-slate-500 mt-1">

                            DPR timeline with approvals

                        </p>

                    </div>

                    <button

                        className="bg-blue-600 text-white rounded-xl h-11 px-5 flex items-center gap-2"

                    >

                        <Plus size={18} />

                        New DPR

                    </button>

                </div>

                {

                    reports.length === 0 ?

                        (

                            <div className="p-12 text-center">

                                <FileText

                                    size={46}

                                    className="mx-auto text-slate-300"

                                />

                                <h3 className="mt-5 font-semibold">

                                    No Reports Yet

                                </h3>

                                <p className="text-slate-500 mt-2">

                                    Daily reports will appear here.

                                </p>

                            </div>

                        )

                        :

                        (

                            <div className="divide-y">

                                {

                                    reports.map(report => (

                                        <div

                                            key={report._id}

                                            className="p-6 hover:bg-slate-50 transition"

                                        >

                                            <div className="flex flex-col xl:flex-row justify-between gap-5">

                                                <div className="space-y-3">

                                                    <div className="flex items-center gap-3">

                                                        <h3 className="text-lg font-bold">

                                                            {report.title}

                                                        </h3>

                                                        <StatusBadge

                                                            status={report.status}

                                                        />

                                                    </div>

                                                    <div className="flex flex-wrap gap-5 text-sm text-slate-500">

                                                        <span className="flex items-center gap-2">

                                                            <Calendar size={15} />

                                                            {report.date}

                                                        </span>

                                                        <span className="flex items-center gap-2">

                                                            <User size={15} />

                                                            {report.created_by}

                                                        </span>

                                                        <span className="flex items-center gap-2">

                                                            <Camera size={15} />

                                                            {report.photos || 0} Photos

                                                        </span>

                                                    </div>

                                                    <p className="text-slate-600">

                                                        {report.summary}

                                                    </p>

                                                </div>

                                                <div className="flex items-center gap-3">

                                                    <button className="rounded-xl border px-4 h-11 flex items-center gap-2">

                                                        <Eye size={18} />

                                                        View

                                                    </button>

                                                    <button className="rounded-xl border px-4 h-11 flex items-center gap-2">

                                                        <Download size={18} />

                                                        PDF

                                                    </button>

                                                </div>

                                            </div>

                                        </div>

                                    ))

                                }

                            </div>

                        )

                }

            </div>

        </div>

    );

}

function StatusBadge({ status }) {

    const styles = {

        Approved: "bg-green-100 text-green-700",

        Pending: "bg-blue-100 text-blue-700",

        Rejected: "bg-red-100 text-red-700"

    };

    return (

        <span

            className={`px-3 py-1 rounded-full text-sm ${styles[status] || "bg-slate-100 text-slate-700"}`}

        >

            {status}

        </span>

    );

}

function StatCard({

    title,

    value,

    icon: Icon,

    color

}) {

    const colors = {

        blue: "bg-blue-50 text-blue-600",

        green: "bg-green-50 text-green-600",

        blue: "bg-blue-50 text-blue-600",

        red: "bg-red-50 text-red-600"

    };

    return (

        <div className="rounded-3xl bg-white border border-slate-200 shadow-sm p-6">

            <div className="flex justify-between">

                <div>

                    <p className="text-sm text-slate-500">

                        {title}

                    </p>

                    <h2 className="mt-3 text-3xl font-bold">

                        {value}

                    </h2>

                </div>

                <div className={`h-14 w-14 rounded-2xl flex items-center justify-center ${colors[color]}`}>

                    <Icon size={24} />

                </div>

            </div>

        </div>

    );

}