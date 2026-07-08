export default function PageHeader({
  title,

  subtitle,

  action,
}) {
  return (
    <div
      className="
        flex

        flex-wrap

        items-end

        justify-between

        gap-4

        mb-8
      "
    >
      <div>
        <h1
          className="
            font-display

            text-4xl

            font-bold

            tracking-tight
          "
        >
          {title}
        </h1>

        {subtitle && (
          <p
            className="
              mt-2

              text-slate-500
            "
          >
            {subtitle}
          </p>
        )}
      </div>

      {action}
    </div>
  );
}