import React from "react";

export default function NavGroup({
  title,
  children,
}) {
  return (
    <div className="mb-7">

      {/* Group Title */}

      <div
        className="
          px-4
          mb-3
          text-[11px]
          font-bold
          uppercase
          tracking-[0.18em]
          text-slate-500
          select-none
        "
      >
        {title}
      </div>

      {/* Group Items */}

      <div
        className="
          flex
          flex-col
          gap-1
        "
      >
        {children}
      </div>

    </div>
  );
}