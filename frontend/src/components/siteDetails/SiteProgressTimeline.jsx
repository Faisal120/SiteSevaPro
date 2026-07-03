
import {
    CheckCircle2,
    Clock3,
    Circle
} from "lucide-react";

const DEFAULT_STAGES = [

    "Foundation",

    "Plinth",

    "Ground Floor",

    "First Floor",

    "Roof",

    "Finishing"

];

export default function SiteProgressTimeline({

    site

}){

    const completed = site?.completed_stages || [];

    const current = site?.current_stage || "Foundation";

    const progress = site?.progress || 0;

    return(

        <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

            <div className="p-6 border-b">

                <h2 className="text-xl font-bold">

                    Construction Timeline

                </h2>

                <p className="text-slate-500 mt-1">

                    Live project execution stages

                </p>

            </div>

            <div className="p-6">

                {

                    DEFAULT_STAGES.map((stage,index)=>{

                        const isCompleted = completed.includes(stage);

                        const isCurrent = current===stage;

                        return(

                            <div

                                key={stage}

                                className="flex gap-5"

                            >

                                <div className="flex flex-col items-center">

                                    {

                                        isCompleted ?

                                        (

                                            <CheckCircle2

                                                className="text-green-600"

                                                size={24}

                                            />

                                        )

                                        :

                                        isCurrent ?

                                        (

                                            <Clock3

                                                className="text-orange-500"

                                                size={24}

                                            />

                                        )

                                        :

                                        (

                                            <Circle

                                                className="text-slate-300"

                                                size={22}

                                            />

                                        )

                                    }

                                    {

                                        index!==DEFAULT_STAGES.length-1 && (

                                            <div className="w-px h-16 bg-slate-200 mt-2"/>

                                        )

                                    }

                                </div>

                                <div className="pb-10 flex-1">

                                    <div className="flex justify-between">

                                        <h3 className="font-semibold">

                                            {stage}

                                        </h3>

                                        {

                                            isCurrent && (

                                                <span className="text-sm text-orange-600 font-semibold">

                                                    {progress}%

                                                </span>

                                            )

                                        }

                                    </div>

                                    <p className="mt-2 text-sm text-slate-500">

                                        {

                                            isCompleted

                                            ?

                                            "Completed"

                                            :

                                            isCurrent

                                            ?

                                            "Currently In Progress"

                                            :

                                            "Waiting"

                                        }

                                    </p>

                                    {

                                        isCurrent && (

                                            <div className="mt-4 h-2 rounded-full bg-slate-100 overflow-hidden">

                                                <div

                                                    className="h-full bg-gradient-to-r from-blue-600 to-cyan-500"

                                                    style={{

                                                        width:`${progress}%`

                                                    }}

                                                />

                                            </div>

                                        )

                                    }

                                </div>

                            </div>

                        )

                    })

                }

            </div>

        </div>

    )

}