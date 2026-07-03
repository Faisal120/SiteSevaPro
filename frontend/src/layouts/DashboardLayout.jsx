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

        <div className={`min-h-screen flex ${theme === "dark" ? "ss-dark" : ""}`}>

            <Sidebar
                user={user}
                role={user?.role}
                logout={logout}
                nav={nav}
                mobileOpen={mobileOpen}
                setMobileOpen={setMobileOpen}
            />

            <div className="flex-1 flex flex-col overflow-hidden">

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
                    p-8
                    "
                >

                    <Outlet />

                </main>

            </div>

        </div>

    )

}