import React from "react";
import { Outlet } from "react-router-dom";

import Sidebar from "@/layouts/Sidebar/Sidebar";
import Header from "@/layouts/Header/Header";

import { useTheme } from "@/lib/theme";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";

export default function DashboardLayout() {
    const { user, logout } = useAuth();
    const { theme, toggle } = useTheme();
    const [stats, setStats] = React.useState(null);
    const [mobileOpen, setMobileOpen] = React.useState(false);
    const [branding, setBranding] = React.useState(null);
    const [subscription, setSubscription] = React.useState({ plan: "FREE", status: "ACTIVE" });

    React.useEffect(() => {
        api.get("/branding")
            .then((response) => setBranding(response.data || null))
            .catch(() => setBranding(null));
        const refresh = () => api.get("/branding").then((response) => setBranding(response.data || null)).catch(() => {});
        window.addEventListener("siteseva:branding-updated", refresh);
        return () => window.removeEventListener("siteseva:branding-updated", refresh);
    }, []);

    React.useEffect(() => {
        api.get("/dashboard")
            .then((response) => setStats(response.data?.stats || null))
            .catch(() => setStats(null));
    }, []);

    React.useEffect(() => {
        if (user?.role !== "CONTRACTOR") return;
        api.get("/subscription")
            .then((response) => setSubscription(response.data || { plan: "FREE", status: "ACTIVE" }))
            .catch(() => setSubscription({ plan: "FREE", status: "ACTIVE" }));
    }, [user?.role]);

    return (
        <div
            className={`
        h-screen
        overflow-hidden
        relative
        flex
        ${theme === "dark" ? "ss-dark bg-[#090a0c]" : "bg-[#EEF3FA]"}
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
                branding={branding}
                subscription={subscription}
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

          lg:ml-[264px]
        "
            >
                <Header
                    user={user}
                    logout={logout}
                    toggle={toggle}
                    theme={theme}
                    branding={branding}
                    setMobileOpen={setMobileOpen}
                />

                <main
                    className={`
        flex-1
        overflow-y-auto

        ${theme === "dark" ? "bg-[#090a0c]" : "bg-[#F6F8FC]"}

        p-6
        lg:p-8

        transition-all
        duration-300
    `}
                >
                    <div
                        className={`
            mx-auto

            w-full

            ${theme === "dark" ? "rounded-[20px] bg-[#111214] border-[#25272c] shadow-none" : "rounded-[28px] bg-white border-slate-200/70 shadow-[0_20px_60px_rgba(15,23,42,.06)]"}

            border

            min-h-full

            p-8
        `}
                    >
                        <Outlet />
                    </div>
                </main>
            </div>
        </div>
    );
}
