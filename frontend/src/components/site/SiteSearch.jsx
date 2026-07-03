import React from "react";
import { Search, X } from "lucide-react";

export default function SiteSearch({
    value,
    onChange,
    onClear
}) {

    return (

        <div className="relative w-full">

            <Search
                size={20}
                className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"
            />

            <input
                value={value}
                onChange={(e) => onChange(e.target.value)}
                placeholder="Search by Site, Client, Supervisor or Location..."
                className="
                    w-full
                    h-14
                    rounded-2xl
                    border
                    border-slate-200
                    bg-white
                    pl-12
                    pr-12
                    text-sm
                    outline-none
                    focus:ring-4
                    focus:ring-blue-100
                    focus:border-blue-500
                    transition
                "
            />

            {

                value && (

                    <button

                        onClick={onClear}

                        className="absolute right-4 top-1/2 -translate-y-1/2"

                    >

                        <X
                            size={18}
                            className="text-slate-500"
                        />

                    </button>

                )

            }

        </div>

    );

}