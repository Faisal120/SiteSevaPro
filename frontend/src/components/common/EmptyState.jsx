
import {

    FolderOpen

} from "lucide-react";

export default function EmptyState({

    title,

    description,

    buttonText,

    onClick

}) {

    return (

        <div className="rounded-3xl bg-white border border-dashed border-slate-300 p-16 text-center">

            <div className="mx-auto h-20 w-20 rounded-full bg-blue-50 flex items-center justify-center">

                <FolderOpen

                    size={42}

                    className="text-blue-600"

                />

            </div>

            <h2 className="mt-6 text-2xl font-bold">

                {title}

            </h2>

            <p className="mt-3 text-slate-500">

                {description}

            </p>

            {

                buttonText && (

                    <button

                        onClick={onClick}

                        className="mt-8 bg-blue-600 text-white rounded-xl h-11 px-6"

                    >

                        {buttonText}

                    </button>

                )

            }

        </div>

    )

}