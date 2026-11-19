import React from "react";
import {
    Building2,
    CalendarDays,
    Clock3,
    Sparkles,
    TrendingUp,
    ArrowUpRight,
} from "lucide-react";
import { api } from "@/lib/api";

export default function DashboardHeader({
    user,
    stats,
    company,
}) {
    const [time, setTime] = React.useState(new Date());
    const [branding, setBranding] = React.useState(null);

    React.useEffect(() => {
        const timer = setInterval(() => {
            setTime(new Date());
        }, 1000);

        return () => clearInterval(timer);
    }, []);

    React.useEffect(() => {
        const loadBranding = () => api.get("/branding").then((response) => setBranding(response.data || null)).catch(() => {});
        loadBranding();
        window.addEventListener("siteseva:branding-updated", loadBranding);
        return () => window.removeEventListener("siteseva:branding-updated", loadBranding);
    }, []);
    const identity = branding || company?.branding || {};
    const health = Number(stats?.productivity) || (Number(stats?.total_sites) ? Math.round(((Number(stats?.completed_sites) || 0) / Number(stats.total_sites)) * 100) : 0);

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

        rounded-[22px]

        border
        border-[#30323a]

        bg-[#111214]

        px-10
        py-10

        text-white
      "
        >
            {/* Decorative Blur */}

            <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-blue-500/15 blur-3xl" />
            <div className="absolute left-1/2 bottom-0 h-40 w-40 rounded-full bg-blue-300/10 blur-3xl" />

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

                        {identity.company_name || company?.name || "Construction workspace"}
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

                text-slate-400

                max-w-2xl
                leading-7
                text-[15px]
              "
                        >
                            Monitor live sites, team activity, procurement and finance from one shared workspace.
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

                            {identity.logo_url ? <img src={identity.logo_url} alt="Company logo" className="h-9 w-9 rounded-lg bg-white object-contain p-1" /> : <Building2 size={22} />}

                            <div>

                                <p className="text-xs text-slate-400 uppercase">
                                    Company
                                </p>

                                <h3 className="font-semibold text-lg">
                                    {identity.company_name || company?.name || user?.company_name || "Your company"}
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

                            <p className="text-xs text-slate-400">
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

                            <p className="text-xs text-slate-400">
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

              border border-[#30323a]
              bg-[#17191d]

              p-5

              text-white
            "
                    >
                        <div>

                            <p
                                className="
                  text-xs
                  uppercase

                  text-slate-300
                "
                            >
                                Company Health
                            </p>

                            <h2
                                className="
                  mt-1

                  text-4xl text-white

                  font-bold
                "
                            >
                                {health}%
                            </h2>

                        </div>

                        <div
                            className="
                h-14
                w-14

                rounded-2xl

                bg-gradient-to-br
from-blue-500/25
to-blue-400/15

                flex
                items-center
                justify-center
              "
                        >
                            <TrendingUp
                                size={26}
                                className="text-blue-300"
                            />
                        </div>

                        <div
                            className="
rounded-full
bg-blue-500/15
px-3
py-1
text-xs
font-semibold
text-blue-200
"
                        >

                            {health >= 80 ? "Excellent" : health >= 50 ? "On track" : "Needs review"}

                        </div>

                    </div>

                </div>

            </div>



        </section>
    );
}
