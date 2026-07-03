import {
    IndianRupee,
    Wallet,
    CreditCard,
    Clock3,
    Download,
    Plus,
    Eye
} from "lucide-react";

export default function PaymentsTab({

    payments = [],

    actions = {}

}) {

    const received = payments
        .filter(p => p.status === "Paid")
        .reduce((t, p) => t + (p.amount || 0), 0);

    const pending = payments
        .filter(p => p.status === "Pending")
        .reduce((t, p) => t + (p.amount || 0), 0);

    const overdue = payments
        .filter(p => p.status === "Overdue")
        .reduce((t, p) => t + (p.amount || 0), 0);

    const total = received + pending + overdue;

    return (

        <div className="space-y-6">

            <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-5">

                <StatsCard
                    title="Total Value"
                    value={`₹${total.toLocaleString("en-IN")}`}
                    icon={IndianRupee}
                    color="blue"
                />

                <StatsCard
                    title="Received"
                    value={`₹${received.toLocaleString("en-IN")}`}
                    icon={Wallet}
                    color="green"
                />

                <StatsCard
                    title="Pending"
                    value={`₹${pending.toLocaleString("en-IN")}`}
                    icon={Clock3}
                    color="orange"
                />

                <StatsCard
                    title="Overdue"
                    value={`₹${overdue.toLocaleString("en-IN")}`}
                    icon={CreditCard}
                    color="red"
                />

            </div>

            <div className="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">

                <div className="flex items-center justify-between p-6 border-b">

                    <div>

                        <h2 className="text-xl font-bold">

                            Payments Ledger

                        </h2>

                        <p className="text-slate-500">

                            Project payment history

                        </p>

                    </div>

                    <div className="flex gap-3">

                        <button className="h-11 rounded-xl bg-blue-600 text-white px-5 flex items-center gap-2">

                            <Plus size={18} />

                            New Payment

                        </button>

                        <button className="h-11 rounded-xl border px-5 flex items-center gap-2">

                            <Download size={18} />

                            Export

                        </button>

                    </div>

                </div>

                <div className="overflow-x-auto">

                    <table className="w-full">

                        <thead className="bg-slate-50">

                            <tr>

                                <th className="px-6 py-4 text-left">

                                    Invoice

                                </th>

                                <th>

                                    Client

                                </th>

                                <th>

                                    Date

                                </th>

                                <th>

                                    Amount

                                </th>

                                <th>

                                    Status

                                </th>

                                <th>

                                    Action

                                </th>

                            </tr>

                        </thead>

                        <tbody>

                            {

                                payments.map(payment => (

                                    <tr

                                        key={payment._id}

                                        className="border-t hover:bg-slate-50"

                                    >

                                        <td className="px-6 py-5">

                                            {payment.invoice_no}

                                        </td>

                                        <td>

                                            {payment.client_name}

                                        </td>

                                        <td>

                                            {payment.date}

                                        </td>

                                        <td>

                                            ₹{Number(payment.amount).toLocaleString("en-IN")}

                                        </td>

                                        <td>

                                            <span className={`

px-3

py-1

rounded-full

text-sm

${payment.status === "Paid"

                                                    ?

                                                    "bg-green-100 text-green-700"

                                                    :

                                                    payment.status === "Pending"

                                                        ?

                                                        "bg-orange-100 text-orange-700"

                                                        :

                                                        "bg-red-100 text-red-700"

                                                }

`}>

                                                {payment.status}

                                            </span>

                                        </td>

                                        <td>

                                            <button>

                                                <Eye
                                                    size={18}
                                                    className="text-blue-600"
                                                />

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