export default function Avatar({
  name,
}) {
  return (
    <div
      className="
        h-12

        w-12

        rounded-2xl

        bg-gradient-to-br

        from-blue-600

        to-indigo-600

        text-white

        flex

        items-center

        justify-center

        font-bold
      "
    >
      {name?.charAt(0)}
    </div>
  );
}