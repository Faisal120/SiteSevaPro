import clsx from "clsx";

export default function Input({
  className,
  icon: Icon,
  ...props
}) {
  return (
    <div
      className={clsx(
        "flex items-center gap-3",

        "h-12",

        "rounded-2xl",

        "border border-slate-300",

        "bg-white",

        "px-4",

        "focus-within:border-blue-600",

        "focus-within:ring-4",

        "focus-within:ring-blue-600/10",

        "transition-all"
      )}
    >
      {Icon && (
        <Icon
          size={18}
          className="text-slate-400"
        />
      )}

      <input
        {...props}
        className={clsx(
          "flex-1",

          "bg-transparent",

          "outline-none",

          "text-sm",

          className
        )}
      />
    </div>
  );
}