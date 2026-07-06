import React from "react";
import {
    Menu,
    Search,
    Bell,
    Sun,
    Moon,
    Plus,
    ChevronDown,
} from "lucide-react";

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

        h-16

        bg-white/90
        backdrop-blur-xl

        border-b
        border-slate-200

        flex
        items-center
        justify-between

        px-6
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

            gap-3

            h-11
            w-[360px]

            rounded-2xl

            border
            border-slate-200

            bg-slate-50

            px-4
          "
                >
                    <Search
                        size={18}
                        className="text-slate-400"
                    />

                    <input
                        type="text"
                        placeholder="Search sites, team, materials..."
                        className="
              flex-1

              bg-transparent

              text-sm

              outline-none
            "
                    />

                    <kbd
                        className="
              rounded-md

              border

              bg-white

              px-2
              py-1

              text-[10px]

              text-slate-400
            "
                    >
                        ⌘K
                    </kbd>
                </div>

            </div>

            {/* Right */}

            <div className="flex items-center gap-3">

                {/* Create */}

                <button
                    className="
            hidden
            md:flex

            items-center

            gap-2

            h-11

            rounded-xl

            bg-blue-600

            px-4

            text-sm
            font-medium

            text-white

            hover:bg-blue-700
          "
                >
                    <Plus size={18} />
                    Create
                </button>

                {/* Notifications */}

                <button
                    className="
            relative

            h-11
            w-11

            rounded-xl

            border
            border-slate-200

            flex
            items-center
            justify-center

            hover:bg-slate-100
          "
                >
                    <Bell size={19} />

                    <span
                        className="
              absolute

              top-2
              right-2

              h-2
              w-2

              rounded-full

              bg-red-500
            "
                    />
                </button>

                {/* Theme */}

                <button
                    onClick={toggle}
                    className="
            h-11
            w-11

            rounded-xl

            border
            border-slate-200

            flex
            items-center
            justify-center

            hover:bg-slate-100
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

            gap-3

            rounded-xl

            border
            border-slate-200

            bg-white

            px-3
            py-2

            hover:bg-slate-50
          "
                >
                    <div
                        className="
              h-10
              w-10

              rounded-full

              bg-blue-600

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
                text-sm
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
                            {user?.role}
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