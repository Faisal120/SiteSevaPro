import clsx from "clsx";

export default function Card({
  children,
  className,
  hover = true,
}) {
  return (
    <div
      className={clsx(
        "bg-white",

        "rounded-[24px]",

        "border border-slate-200",

        "shadow-[0_10px_35px_rgba(15,23,42,.05)]",

        hover &&
          "hover:-translate-y-[2px] hover:shadow-[0_20px_45px_rgba(15,23,42,.08)]",

        "transition-all duration-300",

        className
      )}
    >
      {children}
    </div>
  );
}
