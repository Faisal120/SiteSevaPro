import {
    Users,
    UserCheck,
    UserX,
    Wallet,
    Plus,
    Download
} from "lucide-react";

export default function LabourTab({

    labour = [],

    actions = {}

}) {

    const present =

        labour.filter(

            x => x.status === "Present"

        ).length;

    const absent =

        labour.filter(

            x => x.status === "Absent"

        ).length;

    const totalWage =

        labour.reduce(

            (sum, l) => sum + (l.today_wage || 0),

            0

        );

    return (

        <div className="space-y-6">

            <div className="grid xl:grid-cols-4 gap-5">

                <StatsCard

                    icon={Users}

                    title="Total Labour"

                    value={labour.length}

                    color="blue"

                />

                <StatCard

                    title="Present"

                    value={present}

                    icon={UserCheck}

                    color="green"

                />

                <StatsCard

                    icon={UserX}

                    title="Absent"

                    value={absent}

                    color="red"

                />

                <StatsCard

                    icon={Wallet}

                    title="Today's Wage"

                    value={`₹${totalWage.toLocaleString("en-IN")}`}

                    color="violet"

                />

            </div>

            <div className="rounded-3xl bg-white border border-slate-200 overflow-hidden">

                <div className="flex items-center justify-between p-6 border-b">

                    <h2 className="text-xl font-bold">

                        Labour List

                    </h2>

                    <div className="flex gap-3">

                        <button className="rounded-xl bg-blue-600 text-white px-4 h-11 flex items-center gap-2">

                            <Plus size={18} />

                            Add Labour

                        </button>

                        <button className="rounded-xl border px-4 h-11 flex items-center gap-2">

                            <Download size={18} />

                            Export

                        </button>

                    </div>

                </div>

                <div className="overflow-auto">

                    <table className="w-full">

                        <thead className="bg-slate-50">

                            <tr>

                                <th className="text-left px-6 py-4">

                                    Name

                                </th>

                                <th className="text-left">

                                    Skill

                                </th>

                                <th>

                                    Status

                                </th>

                                <th>

                                    Today's Wage

                                </th>

                                <th>

                                    Action

                                </th>

                            </tr>

                        </thead>

                        <tbody>

                            {

                                labour.map(worker => (

                                    <tr

                                        key={worker._id}

                                        className="border-t"

                                    >

                                        <td className="px-6 py-5">

                                            <div>

                                                <div className="font-semibold">

                                                    {worker.name}

                                                </div>

                                                <div className="text-sm text-slate-500">

                                                    {worker.phone}

                                                </div>

                                            </div>

                                        </td>

                                        <td>

                                            {worker.skill}

                                        </td>

                                        <td>

                                            <span className={`

px-3

py-1

rounded-full

text-sm

${worker.status === "Present"

                                                    ?

                                                    "bg-green-100 text-green-700"

                                                    :

                                                    "bg-red-100 text-red-700"

                                                }

`}>

                                                {worker.status}

                                            </span>

                                        </td>

                                        <td>

                                            ₹{worker.today_wage}

                                        </td>

                                        <td>

                                            <button className="text-blue-600 font-semibold">

                                                View

                                            </button>

                                        </td>

                                    </tr>

                                ))

                            }

                        </tbody>

                    </table>

                </div>

            </div>

        </div>

    )

}