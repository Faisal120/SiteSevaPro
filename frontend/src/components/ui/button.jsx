import React from "react";
import clsx from "clsx";

export default function Button({
  children,
  icon: Icon,
  variant = "primary",
  size = "md",
  className,
  loading = false,
  ...props
}) {

  const variants = {

    primary:
      "bg-blue-600 text-white hover:bg-blue-700 shadow-lg shadow-blue-600/20",

    secondary:
      "bg-white border border-slate-200 hover:bg-slate-50 text-slate-700",

    ghost:
      "hover:bg-slate-100 text-slate-700",

    danger:
      "bg-red-600 text-white hover:bg-red-700",

    success:
      "bg-emerald-600 text-white hover:bg-emerald-700",

    blue:
      "bg-blue-500 text-white hover:bg-blue-600",

  };

  const sizes = {

    sm: "h-10 px-4 text-sm",

    md: "h-11 px-5 text-sm",

    lg: "h-12 px-6 text-base",

    xl: "h-14 px-8 text-base",

  };

  return (

    <button
      {...props}
      className={clsx(

        "inline-flex items-center justify-center gap-2 rounded-2xl font-semibold transition-all duration-300 active:scale-[0.98] disabled:opacity-50",

        variants[variant],

        sizes[size],

        className

      )}
    >

      {loading ? (

        <div
          className="
                    h-5
                    w-5
                    rounded-full
                    border-2
                    border-white/40
                    border-t-white
                    animate-spin
                "
        />

      ) : (

        Icon && <Icon size={18} />

      )}

      {children}

    </button>

  );

}