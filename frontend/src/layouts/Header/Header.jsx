import React from "react";
import { Link, useNavigate } from "react-router-dom";
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
import { api } from "@/lib/api";

export default function Header({
    user,
    theme,
    toggle,
    setMobileOpen,
    branding,
}) {
    const navigate = useNavigate();
    const [open, setOpen] = React.useState(false);
    const [notificationsOpen, setNotificationsOpen] = React.useState(false);
    const [notifications, setNotifications] = React.useState([]);

    React.useEffect(() => {
        let mounted = true;
        const loadNotifications = async () => {
            try {
                const response = await api.get("/notifications");
                if (mounted) setNotifications((response.data || []).slice(0, 5));
            } catch { /* Header remains usable when notifications are unavailable. */ }
        };
        loadNotifications();
        const poll = window.setInterval(loadNotifications, 60000);
        return () => { mounted = false; window.clearInterval(poll); };
    }, []);
    const unreadCount = notifications.filter((notification) => !notification.read).length;
    const markNotificationRead = async (id) => {
        try {
            await api.put(`/notifications/${id}/read`);
            setNotifications((current) => current.map((notification) => notification.id === id ? { ...notification, read: true } : notification));
        } catch { /* The activity centre remains the recovery path. */ }
    };

    return (
        <header
            className={`
        sticky
        top-0
        z-40

        h-20

        flex
        items-center
        justify-between

        px-8

        ${theme === "dark" ? "bg-[#0d0e10]/95 text-[#f5f7fa] border-[#25272c] shadow-none" : "bg-white/80 border-slate-200/70 shadow-sm"}
        backdrop-blur-2xl

        border-b

        transition-all
        duration-300
    `}
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

            hover:bg-slate-100 ss-header-icon
          "
                >
                    <Menu size={20} />
                </button>

                {/* Search */}


                <div
                    className="ss-header-search
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
                        placeholder={`Search ${branding?.company_name || "workspace"}...`}
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
                    onClick={() => navigate("/app/sites?create=1")}
                >
                    Create
                </Button>

                {/* Notifications */}

                <div className="relative">
                    <button
                        onClick={() => setNotificationsOpen((value) => !value)}
                        aria-label="Open notifications"
                        className="ss-header-icon
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

                        {unreadCount > 0 && <span
                            className="
              absolute

              top-2
              right-2

              h-2.5
              w-2.5

              rounded-full

                        bg-blue-500
            "
                        />}
                    </button>
                    {notificationsOpen && <div className="absolute right-0 top-14 z-50 w-[340px] overflow-hidden rounded-2xl border border-[#30323a] bg-[#111214] shadow-2xl"><div className="flex items-center justify-between border-b border-[#25272c] px-4 py-3"><div><p className="font-semibold text-white">Notifications</p><p className="text-xs text-gray-400">{unreadCount ? `${unreadCount} unread updates` : "You are all caught up"}</p></div><Link to="/app/notifications" onClick={() => setNotificationsOpen(false)} className="text-xs font-semibold text-blue-300 hover:text-white">View all</Link></div><div className="max-h-[320px] overflow-y-auto">{notifications.length ? notifications.map((notification) => <button key={notification.id} onClick={() => markNotificationRead(notification.id)} className={`block w-full border-b border-[#25272c] px-4 py-3 text-left hover:bg-white/5 ${notification.read ? "" : "bg-blue-500/10"}`}><div className="flex gap-2"><span className={`mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full ${notification.read ? "bg-transparent" : "bg-blue-400"}`} /><div><p className="text-sm font-semibold text-white">{notification.title}</p><p className="mt-0.5 line-clamp-2 text-xs leading-5 text-gray-400">{notification.message || notification.body}</p></div></div></button>) : <p className="p-5 text-center text-sm text-gray-400">No notifications yet.</p>}</div></div>}
                </div>

                <button
                    onClick={toggle}
                    aria-label={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
                    className="ss-header-icon h-11 w-11 rounded-2xl border border-slate-300/60 flex items-center justify-center hover:bg-slate-100 hover:scale-105 transition-all duration-200"
                >
                    {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
                </button>

                {/* User */}

                <button
                    onClick={() => setOpen(!open)}
                    className="ss-header-user
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

                        <div
                            className="
                text-[15px]
                font-semibold
                font-semibold

                text-slate-800
              "
                        >
                            {user?.full_name}
                        </div>

                        <div
                            className="
                text-xs

                text-slate-500
              "
                        >
                            {user?.role
                                ?.toLowerCase()
                                .replace("_", " ")
                                .replace(/\b\w/g, l => l.toUpperCase())}

                            <span
                                className="
        mt-1

        inline-flex

        items-center

        gap-1

        rounded-full

        bg-blue-100

        px-2

        py-0.5

        text-[10px]

        font-semibold

        text-blue-900
    "
                            >
                                <Sparkles size={11} />

                                AI Enabled
                            </span>
                        </div>

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
