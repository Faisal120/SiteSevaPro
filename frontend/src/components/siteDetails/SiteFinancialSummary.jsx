import {
  IndianRupee,
  Wallet,
  TrendingUp,
  CreditCard
} from "lucide-react";

export default function SiteFinancialSummary({ site }) {

  const budget = Number(site?.budget || 0);
  const spent = Number(site?.spent_amount || 0);
  const received = Number(site?.received_amount || 0);

  const remaining = budget - spent;
  const pending = budget - received;

  const cards = [
    {
      title: "Project Budget",
      value: budget,
      color: "bg-blue-50 text-blue-600",
      icon: IndianRupee
    },
    {
      title: "Spent",
      value: spent,
      color: "bg-red-50 text-red-600",
      icon: Wallet
    },
    {
      title: "Received",
      value: received,
      color: "bg-green-50 text-green-600",
      icon: TrendingUp
    },
    {
      title: "Pending",
      value: pending,
      color: "bg-blue-50 text-blue-600",
      icon: CreditCard
    }
  ];

  return (

    <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

      <div className="p-6 border-b">

        <h2 className="text-xl font-bold">

          Financial Summary

        </h2>

        <p className="text-slate-500 mt-1">

          Live project financial overview

        </p>

      </div>

      <div className="grid md:grid-cols-2 gap-5 p-6">

        {

          cards.map((item,index)=>{

            const Icon = item.icon;

            return(

              <div
                key={index}
                className="rounded-2xl border border-slate-100 p-5"
              >

                <div className="flex justify-between">

                  <div>

                    <p className="text-sm text-slate-500">

                      {item.title}

                    </p>

                    <h2 className="mt-2 text-2xl font-bold">

                      ₹{item.value.toLocaleString("en-IN")}

                    </h2>

                  </div>

                  <div className={`h-12 w-12 rounded-xl flex items-center justify-center ${item.color}`}>

                    <Icon size={22}/>

                  </div>

                </div>

              </div>

            )

          })

        }

      </div>

      <div className="px-6 pb-6">

        <div className="flex justify-between text-sm mb-2">

          <span>Budget Utilization</span>

          <span>

            {

              budget

                ? Math.round((spent/budget)*100)

                : 0

            }%

          </span>

        </div>

        <div className="h-3 rounded-full bg-slate-100 overflow-hidden">

          <div

            className="h-full bg-gradient-to-r from-blue-600 to-cyan-500"

            style={{

              width:`${budget ? (spent/budget)*100 : 0}%`

            }}

          />

        </div>

      </div>

    </div>

  );

}