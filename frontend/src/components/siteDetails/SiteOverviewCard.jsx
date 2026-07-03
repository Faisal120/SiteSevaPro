import {
    Users,
    Package,
    Wallet,
    CreditCard,
    TrendingUp,
    AlertTriangle
} from "lucide-react";

export default function SiteOverviewCards({ site }) {

    const cards = [

        {

            title: "Today's Labour",

            value: site?.today_labour || 0,

            icon: Users,

            color: "blue"

        },

        {

            title: "Material Status",

            value: site?.material_status || "Good",

            icon: Package,

            color: "emerald"

        },

        {

            title: "Today's Expense",

            value: `₹${Number(

                site?.today_expense || 0

            ).toLocaleString("en-IN")}`,

            icon: Wallet,

            color: "violet"

        },

        {

            title: "Payment Status",

            value: site?.payment_pending

                ? "Pending"

                : "Clear",

            icon: CreditCard,

            color: site?.payment_pending

                ? "orange"

                : "green"

        }

    ];

    const colors = {

        blue: "bg-blue-50 text-blue-600",

        emerald: "bg-emerald-50 text-emerald-600",

        violet: "bg-violet-50 text-violet-600",

        orange: "bg-orange-50 text-orange-600",

        green: "bg-green-50 text-green-600"

    };

    return (

        <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-6">

            {

                cards.map((card,index)=>{

                    const Icon = card.icon;

                    return(

                        <div

                            key={index}

                            className="rounded-3xl bg-white border border-slate-200 p-6 shadow-sm"

                        >

                            <div className="flex justify-between">

                                <div>

                                    <p className="text-sm text-slate-500">

                                        {card.title}

                                    </p>

                                    <h2 className="mt-3 text-3xl font-bold">

                                        {card.value}

                                    </h2>

                                </div>

                                <div className={`

                                    h-14

                                    w-14

                                    rounded-2xl

                                    flex

                                    items-center

                                    justify-center

                                    ${colors[card.color]}

                                `}>

                                    <Icon size={26}/>

                                </div>

                            </div>

                            <div className="mt-6 flex items-center gap-2">

                                {

                                    card.color==="orange"

                                    ?

                                    <AlertTriangle

                                        size={16}

                                        className="text-orange-500"

                                    />

                                    :

                                    <TrendingUp

                                        size={16}

                                        className="text-green-500"

                                    />

                                }

                                <span className="text-sm text-slate-500">

                                    Live Status

                                </span>

                            </div>

                        </div>

                    )

                })

            }

        </div>

    )

}