import React from "react";

import {
    CheckCircle2,
    Clock3,
    Truck,
    Users,
    Camera,
    IndianRupee
} from "lucide-react";


export default function TodaysExecutionBoard({

    tasks = []

}) {

    return (

        <div className="mt-10">

            <div className="flex items-center justify-between mb-6">

                <div>

                    <h2 className="text-2xl font-bold">

                        Today's Execution Board

                    </h2>

                    <p className="text-slate-500 mt-1">

                        Everything you need to complete today

                    </p>

                </div>

            </div>

            <div className="rounded-3xl border border-slate-200 bg-white shadow-sm">

                {

                    tasks.length === 0 ? (

                        <div className="rounded-2xl bg-slate-50 border border-dashed border-slate-300 p-10 text-center">

                            <h3 className="font-semibold">

                                No Pending Tasks

                            </h3>

                            <p className="text-slate-500 mt-2">

                                You're all caught up for today.

                            </p>

                        </div>

                    ) : (

                        tasks.map((task, index) => {

                            const Icon = task.icon;

                            return (

                                <div key={index} className="

flex

items-center

justify-between

p-6

border-b

last:border-0

">

                                    <div className="flex items-center gap-5">

                                        <div

                                            className={`
h-14
w-14
rounded-2xl
flex
items-center
justify-center

${task.completed

                                                    ?

                                                    "bg-green-50"

                                                    :

                                                    "bg-orange-50"

                                                }

`}

                                        >

                                            {

                                                task.completed

                                                    ?

                                                    <CheckCircle2

                                                        size={24}

                                                        className="text-green-600"

                                                    />

                                                    :

                                                    <Clock3

                                                        size={24}

                                                        className="text-orange-500"

                                                    />

                                            }

                                        </div>

                                        <div>

                                            <h3 className="font-semibold">

                                                {task.title || task.task_name}

                                            </h3>

                                            <p className="text-sm text-slate-500 mt-1">

                                                {task.due_time || "Today"}

                                            </p>

                                        </div>

                                    </div>

                                    {

                                        task.completed

                                            ?

                                            <div className="flex items-center gap-2 text-green-600">

                                                <CheckCircle2 size={18} />

                                                Completed

                                            </div>

                                            :

                                            <div className="flex items-center gap-2 text-orange-500">

                                                <Clock3 size={18} />

                                                Pending
                                                {

                                                    !task.completed && (

                                                        <button

                                                            className="

mt-4

rounded-xl

bg-blue-600

px-4

py-2

text-white

text-sm

hover:bg-blue-700

"

                                                        >

                                                            Mark Complete

                                                        </button>

                                                    )

                                                }

                                            </div>

                                    }

                                </div>

                            )

                        }))

                }

            </div>

        </div >

    )

}