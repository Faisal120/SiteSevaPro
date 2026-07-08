import clsx from "clsx";

const variants = {
  success:
    "bg-green-100 text-green-700",

  warning:
    "bg-orange-100 text-orange-700",

  info:
    "bg-blue-100 text-blue-700",

  danger:
    "bg-red-100 text-red-700",

  gray:
    "bg-slate-100 text-slate-700",
};

export default function Badge({
  children,
  variant = "gray",
}) {
  return (
    <span
      className={clsx(
        "inline-flex items-center",

        "rounded-full",

        "px-3 py-1",

        "text-xs",

        "font-semibold",

        variants[variant]
      )}
    >
      {children}
    </span>
  );
}