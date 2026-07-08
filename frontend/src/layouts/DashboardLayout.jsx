import React from "react";
import { Outlet } from "react-router-dom";

import Sidebar from "@/layouts/Sidebar/Sidebar";
import Header from "@/layouts/Header/Header";

import { useTheme } from "@/lib/theme";
import { useAuth } from "@/lib/auth";

export default function DashboardLayout() {
    const { user, logout } = useAuth();
    const { theme, toggle } = useTheme();
    const [stats, setStats] = React.useState(null);
    const [mobileOpen, setMobileOpen] = React.useState(false);

    return (
        <div
            className={`
        h-screen
        overflow-hidden
        relative
        flex
        bg-[#EEF3FA]
        ${theme === "dark" ? "ss-dark" : ""}
      `}
        >
            {/* Mobile Overlay */}

            {mobileOpen && (
                <div
                    className="
            fixed
            inset-0
            z-40
            bg-black/50
            backdrop-blur-sm
            lg:hidden
          "
                    onClick={() => setMobileOpen(false)}
                />
            )}

            {/* Sidebar */}

            <Sidebar
                user={user}
                stats={stats}
                role={user?.role}
                logout={logout}
                mobileOpen={mobileOpen}
                setMobileOpen={setMobileOpen}
            />

            {/* Right Layout */}

            <div
                className="
          flex-1
          flex
          flex-col
          overflow-hidden
          relative

          lg:ml-[280px]
        "
            >
                <Header
                    user={user}
                    logout={logout}
                    toggle={toggle}
                    theme={theme}
                    setMobileOpen={setMobileOpen}
                />

                <main
                    className="
        flex-1
        overflow-y-auto

        bg-[#F6F8FC]

        p-6
        lg:p-8

        transition-all
        duration-300
    "
                >
                    <div
                        className="
            mx-auto

            w-full

            rounded-[28px]

            bg-white

            border

            border-slate-200/70

            shadow-[0_20px_60px_rgba(15,23,42,.06)]

            min-h-full

            p-8
        "
                    >
                        <Outlet />
                    </div>
                </main>
            </div>
        </div>
    );
}