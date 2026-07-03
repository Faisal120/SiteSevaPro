import { MapPin, Calendar } from "lucide-react";

export default function OverviewTab({ site }) {

    return (

        <div className="rounded-3xl bg-white border border-slate-200 p-6">

            <h2 className="text-xl font-bold">

                Project Overview

            </h2>

            <p className="mt-4 text-slate-600 leading-7">

                {site?.description || "No description available."}

            </p>

            <div className="grid md:grid-cols-3 gap-5 mt-8">

                <Card

                    icon={<Calendar size={18}/>}

                    title="Start Date"

                    value={site?.start_date}

                />

                <Card

                    icon={<Calendar size={18}/>}

                    title="Completion"

                    value={site?.completion_date}

                />

                <Card

                    icon={<MapPin size={18}/>}

                    title="Location"

                    value={site?.location}

                />

            </div>

        </div>

    );

}

function Card({

    icon,

    title,

    value

}){

    return(

        <div className="rounded-2xl bg-slate-50 p-5">

            <div className="flex items-center gap-2 text-slate-500">

                {icon}

                {title}

            </div>

            <div className="mt-3 font-semibold">

                {value || "--"}

            </div>

        </div>

    )

}