import React from "react";
import { LogOut, HelpCircle, ShieldCheck } from "lucide-react";

export default function SidebarFooter({
    logout,
    nav
}) {

    return (

        <div
            className="
                border-t
                border-slate-800
                p-4
                mt-auto
            "
        >

            {/* Version */}

            <div
                className="
                    rounded-2xl
                    bg-slate-900
                    border
                    border-slate-700
                    p-4
                    mb-4
                "
            >

                <div className="flex justify-between">

                    <span className="text-xs text-slate-400">

                        SiteSeva Pro

                    </span>

                    <span
                        className="
                            text-xs
                            text-blue-400
                            font-semibold
                        "
                    >

                        v2.0

                    </span>

                </div>

                <p
                    className="
                        text-xs
                        text-slate-500
                        mt-2
                    "
                >

                    Construction Operating System

                </p>

            </div>

            {/* Help */}

            <button
                className="
                    ss-sidebar-link
                    w-full
                    mb-2
                "
            >

                <HelpCircle size={18} />

                Help Center

            </button>

            {/* Security */}

            <button
                className="
                    ss-sidebar-link
                    w-full
                    mb-3
                "
            >

                <ShieldCheck size={18} />

                Security

            </button>

            {/* Logout */}

            <button

                onClick={() => {

                    logout();

                    nav("/login");

                }}

                className="
                    ss-sidebar-link
                    w-full
                    hover:bg-red-600/10
                    hover:text-red-400
                "

            >

                <LogOut size={18} />

                Logout

            </button>

        </div>

    );

}