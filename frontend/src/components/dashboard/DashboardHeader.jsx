import React from "react";
import {
    Building2,
    CalendarDays,
    Clock3,
    Sparkles,
    TrendingUp,
    ArrowUpRight,
} from "lucide-react";

export default function DashboardHeader({ user }) {
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

        rounded-3xl

        border
        border-slate-200

        bg-gradient-to-r
        from-blue-700
        via-blue-600
        to-blue-500

        p-8

        text-white
      "
        >
            {/* Decorative Blur */}

            <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-white/10 blur-3xl" />
            <div className="absolute left-1/2 bottom-0 h-40 w-40 rounded-full bg-blue-300/20 blur-3xl" />

            <div className="relative flex flex-col lg:flex-row justify-between gap-8">

                {/* Left */}

                <div className="space-y-5">

                    <span
                        className="
              inline-flex
              items-center
              gap-2

              rounded-full

              bg-white/15

              px-4
              py-2

              text-sm
              backdrop-blur
            "
                    >
                        <Sparkles size={16} />

                        Construction Operating System
                    </span>

                    <div>

                        <h1
                            className="
                text-4xl
                font-bold
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

                max-w-xl
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
              rounded-2xl

              bg-white/10

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
                                    {user?.company_name || "SiteSeva Pro"}
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
                                Productivity
                            </p>

                            <h2
                                className="
                  mt-1

                  text-3xl

                  font-bold
                "
                            >
                                98%
                            </h2>

                        </div>

                        <div
                            className="
                h-14
                w-14

                rounded-2xl

                bg-blue-100

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

                        <ArrowUpRight
                            className="text-green-500"
                            size={28}
                        />

                    </div>

                </div>

            </div>

        </section>
    );
}