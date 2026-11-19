import React from "react";
import { Link } from "react-router-dom";
import {
  Bell,
  Moon,
  Sun,
  Plus,
  CloudSun
} from "lucide-react";

import SSButton from "@/components/ui/SSButton";

export default function HeaderActions({
  theme,
  toggle,
  nav,
  notificationCount = 0,
  weather = {
    city: "Lucknow",
    temp: 34,
    condition: "Sunny"
  }
}) {

  return (

    <div className="flex items-center gap-3">

      {/* Weather */}

      <div
        className="
          hidden
          xl:flex
          items-center
          gap-2
          rounded-2xl
          border
          border-slate-200
          bg-white
          px-4
          h-12
          shadow-sm
        "
      >

        <CloudSun
          size={18}
          className="text-blue-500"
        />

        <div className="leading-tight">

          <p className="text-xs font-semibold text-slate-700">

            {weather.temp}°

          </p>

          <p className="text-[11px] text-slate-500">

            {weather.city}

          </p>

        </div>

      </div>

      {/* Theme */}

      <button

        onClick={toggle}

        className="
          h-12
          w-12
          rounded-2xl
          border
          border-slate-200
          bg-white
          flex
          items-center
          justify-center
          hover:border-blue-500
          transition
        "

      >

        {

          theme === "dark"

            ? <Sun size={20} />

            : <Moon size={20} />

        }

      </button>

      {/* Notification */}

      <Link

        to="/app/notifications"

        className="
          relative
          h-12
          w-12
          rounded-2xl
          border
          border-slate-200
          bg-white
          flex
          items-center
          justify-center
          hover:border-blue-500
          transition
        "

      >

        <Bell size={20} />

        {

          notificationCount > 0 && (

            <span
              className="
                absolute
                -top-1
                -right-1
                min-w-[20px]
                h-5
                rounded-full
                bg-red-500
                text-white
                text-[10px]
                font-bold
                flex
                items-center
                justify-center
                px-1
              "
            >

              {notificationCount}

            </span>

          )

        }

      </Link>

      {/* Create Site */}

      <SSButton

        onClick={() => nav("/app/sites?create=1")}

        className="hidden lg:flex items-center gap-2"

      >

        <Plus size={18} />

        New Site

      </SSButton>

    </div>

  );

}
