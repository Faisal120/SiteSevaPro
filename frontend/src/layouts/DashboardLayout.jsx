import React from "react";
import { Outlet } from "react-router-dom";

import Sidebar from "@/layouts/Sidebar/Sidebar";
import Header from "@/layouts/Header/Header";

import { useTheme } from "@/lib/theme";
import { useAuth } from "@/lib/auth";

export default function DashboardLayout() {
    const { user, logout } = useAuth();
    const { theme, toggle } = useTheme();

    const [mobileOpen, setMobileOpen] = React.useState(false);

    return (
        <div
            className={`
        h-screen
        overflow-hidden
        flex
        bg-slate-50
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

          lg:ml-[260px]
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

            bg-slate-50

            p-5
            md:p-6
            xl:p-8
          "
                >
                    <Outlet />
                </main>
            </div>
        </div>
    );
}