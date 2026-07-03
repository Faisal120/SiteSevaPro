import React from "react";

const filters = [

    "All",

    "Active",

    "Completed",

    "Delayed",

    "Archived"

];

export default function SiteFilters({

    active,

    onChange

}) {

    return (

        <div className="flex flex-wrap gap-3">

            {

                filters.map(filter => (

                    <button

                        key={filter}

                        onClick={() => onChange(filter)}

                        className={`

                            px-5

                            h-11

                            rounded-xl

                            font-medium

                            transition

                            ${

                                active === filter

                                ?

                                "bg-blue-600 text-white shadow"

                                :

                                "bg-white border border-slate-200 text-slate-600 hover:border-blue-500"

                            }

                        `}

                    >

                        {filter}

                    </button>

                ))

            }

        </div>

    );

}