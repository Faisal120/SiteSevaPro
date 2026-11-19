import clsx from "clsx";

const variants = {
    primary:
        "bg-[#3b82f6] hover:bg-[#2563eb] text-white shadow-lg shadow-blue-950/25",

    secondary:
        "bg-white border border-slate-300 text-slate-700 hover:bg-slate-50",

    ghost:
        "bg-transparent hover:bg-slate-100 text-slate-700",

    danger:
        "bg-red-600 hover:bg-red-700 text-white",

    ai:
        "bg-gradient-to-r from-blue-500 to-blue-500 hover:from-blue-600 hover:to-blue-600 text-white shadow-lg shadow-blue-500/20",
};

export default function Button({
    children,
    variant = "primary",
    icon: Icon,
    className,
    ...props
}) {
    return (
        <button
            {...props}
            className={clsx(
                "inline-flex items-center justify-center gap-2",
                "h-12 px-5",
                "rounded-2xl",
                "font-semibold",
                "transition-all duration-200",
                "active:scale-[0.98]",
                "disabled:opacity-50",
                variants[variant],
                className
            )}
        >
            {Icon && <Icon size={18} />}

            {children}
        </button>
    );
}
