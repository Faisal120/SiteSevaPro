import React from "react";
import { useNavigate } from "react-router-dom";
import {
  LifeBuoy,
  ShieldCheck,
  LogOut,
  ChevronRight,
} from "lucide-react";

export default function SidebarFooter({ logout }) {
  const navigate = useNavigate();

  const Item = ({ icon: Icon, label, onClick, danger = false }) => (
    <button
      onClick={onClick}
      className={`
        w-full
        flex
        items-center
        gap-3

        px-3
        h-11

        rounded-xl

        transition-all
        duration-200

        ${
          danger
            ? "text-red-400 hover:bg-red-500/10 hover:text-red-300"
            : "text-slate-400 hover:bg-[#17191d] hover:text-white"
        }
      `}
    >
      <Icon
        size={18}
        className="shrink-0"
      />

      <span
        className="
          flex-1
          text-left
          text-sm
          font-medium
        "
      >
        {label}
      </span>

      {!danger && (
        <ChevronRight
          size={15}
          className="opacity-40"
        />
      )}
    </button>
  );

  return (
    <div
      className="
        pt-6

        border-t
        border-[#25272c]

        space-y-1
      "
    >
      <Item
        icon={LifeBuoy}
        label="Help Center"
        onClick={() => navigate("/app/help")}
      />

      <Item
        icon={ShieldCheck}
        label="Security"
        onClick={() => navigate("/app/security")}
      />

      <Item
        icon={LogOut}
        label="Logout"
        danger
        onClick={logout}
      />

      <div
        className="
          mt-5

          rounded-xl

          bg-[#111214]

          p-3
        "
      >
        <div className="text-xs text-slate-500">

          SiteSeva Pro

        </div>

        <div className="mt-1 flex items-center justify-between">

          <span
            className="
              text-sm
              font-semibold
              text-white
            "
          >
            v2.0.0
          </span>

          <span
            className="
              rounded-full

              bg-green-500/15

              px-2

              py-1

              text-[10px]

              font-semibold

              text-green-400
            "
          >
            Stable
          </span>

        </div>
      </div>
    </div>
  );
}
