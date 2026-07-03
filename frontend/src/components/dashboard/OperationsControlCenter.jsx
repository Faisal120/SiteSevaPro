import React from "react";
import {
    AlertTriangle,
    Clock3,
    IndianRupee,
    Package,
    Users,
    ArrowRight
} from "lucide-react";

import { useNavigate } from "react-router-dom";

export default function OperationsControlCenter({

    alerts=[]

}){

    const nav=useNavigate();

    return(

        <div className="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">

            <div className="px-6 py-5 border-b border-slate-100">

                <div className="flex items-center justify-between">

                    <div>

                        <h2 className="text-xl font-bold">

                            Operations Control Center

                        </h2>

                        <p className="text-sm text-slate-500 mt-1">

                            High priority actions requiring attention

                        </p>

                    </div>

                    <div className="h-12 w-12 rounded-2xl bg-red-50 flex items-center justify-center">

                        <AlertTriangle className="text-red-600"/>

                    </div>

                </div>

            </div>

            <div>

                {

                    alerts.length===0 ?

                    (

                        <div className="p-10 text-center">

                            <AlertTriangle

                                size={48}

                                className="mx-auto text-green-500"

                            />

                            <h3 className="mt-5 font-semibold text-lg">

                                Everything Looks Good

                            </h3>

                            <p className="text-slate-500 mt-2">

                                No critical alerts at the moment.

                            </p>

                        </div>

                    )

                    :

                    alerts.map((item,index)=>{

                        const icons={

                            site:AlertTriangle,

                            dpr:Clock3,

                            payment:IndianRupee,

                            material:Package,

                            labour:Users

                        };

                        const Icon=icons[item.type]||AlertTriangle;

                        return(

                            <div

                                key={index}

                                className="

                                flex

                                items-center

                                justify-between

                                px-6

                                py-5

                                border-b

                                last:border-0

                                hover:bg-slate-50

                                transition

                                "

                            >

                                <div className="flex items-center gap-4">

                                    <div className="h-12 w-12 rounded-xl bg-red-50 flex items-center justify-center">

                                        <Icon className="text-red-600"/>

                                    </div>

                                    <div>

                                        <h3 className="font-semibold">

                                            {item.title}

                                        </h3>

                                        <p className="text-sm text-slate-500">

                                            {item.description}

                                        </p>

                                    </div>

                                </div>

                                <button

                                    onClick={()=>nav(item.route)}

                                    className="text-blue-600 flex items-center gap-2 font-medium"

                                >

                                    Open

                                    <ArrowRight size={18}/>

                                </button>

                            </div>

                        )

                    })

                }

            </div>

        </div>

    )

}