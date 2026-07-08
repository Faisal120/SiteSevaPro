import React from "react";
import {
    Menu,
    Search,
    Bell,
    Sun,
    Moon,
    Plus,
    ChevronDown,
    Sparkles,
} from "lucide-react";

import { Button } from "@/components/ui";

export default function Header({
    user,
    theme,
    toggle,
    setMobileOpen,
}) {
    const [open, setOpen] = React.useState(false);

    return (
        <header
            className="
        sticky
        top-0
        z-40

        h-20

        flex
        items-center
        justify-between

        px-8

        bg-white/80
        backdrop-blur-2xl

        border-b
        border-slate-200/70

        shadow-sm

        transition-all
        duration-300
    "
        >
            {/* Left */}

            <div className="flex items-center gap-4">

                <button
                    onClick={() => setMobileOpen(true)}
                    className="
            lg:hidden

            h-10
            w-10

            rounded-xl

            flex
            items-center
            justify-center

            hover:bg-slate-100
          "
                >
                    <Menu size={20} />
                </button>

                {/* Search */}


                <div
                    className="
            hidden
            md:flex

            items-center

            gap-4

            h-11
            w-[520px]

            rounded-[18px]

            border
            border-slate-300/70

            bg-white

            px-4
          "
                >
                    <Search
                        size={18}
                        className="text-slate-400"
                    />

                    <input
                        type="text"
                        placeholder="Search sites, labour, materials, payments..."
                        className="
              flex-1

              bg-transparent

              text-sm

              outline-none
            "
                    />

                    <kbd
                        className="
                        rounded-lg
                        border
                        border-slate-200
                        bg-slate-50
                        px-2.5
                        py-1
                        text-[11px]
                        font-medium
                        text-slate-500
                    "
                    >
                        Ctrl K
                    </kbd>
                </div>

            </div>

            {/* Right */}

            <div className="flex items-center gap-4">

                {/* Create */}

                <Button
                    icon={Plus}
                    className="hidden md:flex"
                >
                    Create
                </Button>

                {/* Notifications */}

                <button
                    className="
            relative

            h-11
            w-11

            rounded-2xl

            border
            border-slate-300/60

            flex
            items-center
            justify-center

            hover:bg-slate-100
            hover:scale-105
            transition-all
            duration-200
          "
                >
                    <Bell size={19} />

                    <span
                        className="
              absolute

              top-2
              right-2

              h-2.5
              w-2.5

              rounded-full

              bg-red-500
            "
                    />
                </button>

                {/* Theme */}

                <button
                    onClick={toggle}
                    className="
            relative

            h-11
            w-11

            rounded-2xl

            border
            border-slate-300/60

            flex
            items-center
            justify-center

            hover:bg-slate-100

            hover:scale-105

            transition-all

            duration-200
          "
                >
                    {theme === "dark" ? (
                        <Sun size={18} />
                    ) : (
                        <Moon size={18} />
                    )}
                </button>

                {/* User */}

                <button
                    onClick={() => setOpen(!open)}
                    className="
            flex
            items-center

            gap-4

            rounded-2xl

            border
            border-slate-300/70

            bg-white

            px-3
            py-2

            hover:bg-slate-50

            hover:border-blue-200

            transition-all

            duration-200
          "
                >
                    <div
                        className="
              h-12
              w-12

              rounded-2xl

              bg-gradient-to-br
             from-blue-600
             to-indigo-600

              flex
              items-center
              justify-center

              text-white
              font-semibold
            "
                    >
                        {user?.full_name?.charAt(0)}
                    </div>

                    <div className="hidden lg:block text-left">

                        <p
                            className="
                text-[15px]
                font-semibold
                font-semibold

                text-slate-800
              "
                        >
                            {user?.full_name}
                        </p>

                        <p
                            className="
                text-xs

                text-slate-500
              "
                        >
                            {user?.role
                                ?.toLowerCase()
                                .replace("_", " ")
                                .replace(/\b\w/g, l => l.toUpperCase())}

                            <p
                                className="
        mt-1

        inline-flex

        items-center

        gap-1

        rounded-full

        bg-orange-100

        px-2

        py-0.5

        text-[10px]

        font-semibold

        text-orange-700
    "
                            >
                                <Sparkles size={11} />

                                AI Enabled
                            </p>
                        </p>

                    </div>

                    <ChevronDown
                        size={17}
                        className="
              text-slate-400
            "
                    />
                </button>

            </div>
        </header>
    );
}