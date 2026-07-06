import React from "react";

export default function NavGroup({
  title,
  children,
}) {
  return (
    <section className="space-y-2">

      {/* Section Title */}

      <div
        className="
          px-3

          text-[11px]

          font-semibold

          uppercase

          tracking-[0.18em]

          text-slate-500

          select-none
        "
      >
        {title}
      </div>

      {/* Menu */}

      <div className="space-y-1">
        {children}
      </div>

    </section>
  );
}