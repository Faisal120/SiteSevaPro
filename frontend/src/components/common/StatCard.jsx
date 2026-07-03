export default function StatCard({

    title,

    value,

    icon: Icon,

    color = "blue"

}) {

    const colors = {

        blue: "bg-blue-50 text-blue-600",

        green: "bg-green-50 text-green-600",

        orange: "bg-orange-50 text-orange-600",

        red: "bg-red-50 text-red-600",

        violet: "bg-violet-50 text-violet-600"

    }

    return (

        <div className="rounded-3xl bg-white border border-slate-200 shadow-sm p-6">

            <div className="flex justify-between">

                <div>

                    <p className="text-slate-500 text-sm">

                        {title}

                    </p>

                    <h2 className="mt-3 text-3xl font-bold">

                        {value}

                    </h2>

                </div>

                <div className={`

h-14

w-14

rounded-2xl

flex

items-center

justify-center

${colors[color]}

`}>

                    <Icon size={24} />

                </div>

            </div>

        </div>

    )

}   