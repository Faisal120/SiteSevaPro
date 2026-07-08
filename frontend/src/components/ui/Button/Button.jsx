import clsx from "clsx";

const variants = {
    primary:
        "bg-blue-600 hover:bg-blue-700 text-white shadow-lg shadow-blue-600/20",

    secondary:
        "bg-white border border-slate-300 text-slate-700 hover:bg-slate-50",

    ghost:
        "bg-transparent hover:bg-slate-100 text-slate-700",

    danger:
        "bg-red-600 hover:bg-red-700 text-white",

    ai:
        "bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white shadow-lg shadow-orange-500/20",
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