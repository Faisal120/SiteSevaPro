import React from "react";
import { Search } from "lucide-react";

export default function SearchBar() {
  return (
    <div className="hidden xl:flex flex-1 max-w-xl">

      <div className="relative w-full">

        <Search
          size={18}
          className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"
        />

        <input
          placeholder="Search Sites, Labour, Materials..."
          className="
            w-full
            h-12
            rounded-2xl
            border
            border-slate-200
            bg-slate-50
            pl-11
            pr-4
            outline-none
            transition
            focus:bg-white
            focus:border-blue-500
            focus:ring-4
            focus:ring-blue-100
          "
        />

      </div>

    </div>
  );
}