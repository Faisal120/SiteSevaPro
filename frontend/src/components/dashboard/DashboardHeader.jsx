import React from "react";
import { CalendarDays } from "lucide-react";

export default function DashboardHeader({ user }) {

    const hour = new Date().getHours();

    let greeting = "Good Evening";

    if (hour < 12) greeting = "Good Morning";
    else if (hour < 17) greeting = "Good Afternoon";

    const today = new Date().toLocaleDateString("en-IN",{
        weekday:"long",
        day:"numeric",
        month:"long",
        year:"numeric"
    });

    return(

        <div className="mb-8">

            <div className="flex items-center justify-between">

                <div>

                    <p className="text-slate-500 text-sm">

                        {greeting},

                    </p>

                    <h1 className="text-4xl font-bold text-slate-900 mt-1">

                        {user?.full_name}

                    </h1>

                    <p className="text-slate-500 mt-2">

                        Welcome back to SiteSeva Construction Operating System.

                    </p>

                </div>

                <div className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white px-5 py-3 shadow-sm">

                    <CalendarDays className="h-5 w-5 text-blue-600"/>

                    <div>

                        <p className="text-xs text-slate-500">

                            Today

                        </p>

                        <p className="font-semibold">

                            {today}

                        </p>

                    </div>

                </div>

            </div>

        </div>

    );

}