import React from "react";
import {
    Building2,
    CalendarDays,
    Clock3,
    Sparkles,
    TrendingUp,
    ArrowUpRight,
} from "lucide-react";

export default function DashboardHeader({
    user,
    stats,
    company,
}) {
    const [time, setTime] = React.useState(new Date());

    React.useEffect(() => {
        const timer = setInterval(() => {
            setTime(new Date());
        }, 1000);

        return () => clearInterval(timer);
    }, []);

    const greeting = () => {
        const h = time.getHours();

        if (h < 12) return "Good Morning";
        if (h < 17) return "Good Afternoon";
        return "Good Evening";
    };

    return (
        <section
            className="
        relative
        overflow-hidden

        rounded-[32px]

        border
        border-slate-200

        bg-gradient-to-r
        from-[#0F3DDE]
        via-[#2563EB]
        to-[#3B82F6]

        px-10
        py-10

        text-white
      "
        >
            {/* Decorative Blur */}

            <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-white/10 blur-3xl" />
            <div className="absolute left-1/2 bottom-0 h-40 w-40 rounded-full bg-blue-300/20 blur-3xl" />

            <div
                className="
                    absolute
                    inset-0
                    opacity-[0.04]
                    bg-[radial-gradient(circle_at_1px_1px,white_1px,transparent_0)]
                    bg-[length:22px_22px]
                "
            />

            <div className="relative flex flex-col lg:flex-row justify-between gap-8">

                {/* Left */}

                <div className="space-y-5">

                    <span
                        className="
              inline-flex
              items-center
              gap-2

              rounded-full

              bg-white/10
              border
              border-white/20

              px-4
              py-2

              text-sm
              backdrop-blur
            "
                    >
                        <Sparkles size={16} />

                        SiteSeva Pro Enterprise
                    </span>

                    <div>

                        <h1
                            className="
                            font-display
                            text-5xl
                            font-bold
                            leading-tight
                            tracking-tight
                            "
                        >
                            {greeting()},
                            <br />

                            {user?.full_name}
                        </h1>

                        <p
                            className="
                mt-3

                text-blue-100

                max-w-2xl
                leading-7
                text-[15px]
              "
                        >
                            Welcome back to SiteSeva Pro.

                            Monitor your projects, teams, expenses,
                            materials and reports from one place.
                        </p>

                    </div>

                </div>

                {/* Right */}

                <div
                    className="
            flex
            flex-col

            justify-between

            gap-4

            min-w-[300px]
          "
                >
                    <div
                        className="
              rounded-[24px]

              bg-white/10
                border
                border-white/15

              backdrop-blur

              p-5
            "
                    >
                        <div className="flex items-center gap-3">

                            <Building2 size={22} />

                            <div>

                                <p className="text-xs text-blue-100 uppercase">
                                    Company
                                </p>

                                <h3 className="font-semibold text-lg">
                                    {company?.branding?.company_name}
                                </h3>

                            </div>

                        </div>
                    </div>

                    <div
                        className="
              grid
              grid-cols-2
              gap-4
            "
                    >
                        <div
                            className="
                rounded-2xl

                bg-white/10

                p-4
              "
                        >
                            <CalendarDays
                                className="mb-2"
                                size={20}
                            />

                            <p className="text-xs text-blue-100">
                                Today
                            </p>

                            <h4 className="font-semibold">
                                {time.toLocaleDateString("en-IN", {
                                    weekday: "long",
                                    day: "numeric",
                                    month: "long",
                                })}
                            </h4>

                        </div>

                        <div
                            className="
                rounded-2xl

                bg-white/10

                p-4
              "
                        >
                            <Clock3
                                className="mb-2"
                                size={20}
                            />

                            <p className="text-xs text-blue-100">
                                Current Time
                            </p>

                            <h4 className="font-semibold">
                                {time.toLocaleTimeString()}
                            </h4>

                        </div>

                    </div>

                    <div
                        className="
              flex
              items-center
              justify-between

              rounded-2xl

              bg-white

              p-5

              text-slate-800
            "
                    >
                        <div>

                            <p
                                className="
                  text-xs
                  uppercase

                  text-slate-500
                "
                            >
                                Company Health
                            </p>

                            <h2
                                className="
                  mt-1

                  text-4xl

                  font-bold
                "
                            >
                                {Math.round(stats?.productivity ?? 0)}%
                            </h2>

                        </div>

                        <div
                            className="
                h-14
                w-14

                rounded-2xl

                bg-gradient-to-br
from-blue-100
to-blue-200

                flex
                items-center
                justify-center
              "
                        >
                            <TrendingUp
                                size={26}
                                className="text-blue-700"
                            />
                        </div>

                        <div
                            className="
rounded-full
bg-green-100
px-3
py-1
text-xs
font-semibold
text-green-700
"
                        >

                            Excellent

                        </div>

                    </div>

                </div>

            </div>



        </section>
    );
}