import {

    AlertTriangle,

    RefreshCcw

} from "lucide-react";

export default function ErrorState({

    title = "Something went wrong",

    description = "Unable to load data.",

    onRetry

}) {

    return (

        <div className="min-h-[60vh] flex flex-col items-center justify-center">

            <div className="h-20 w-20 rounded-full bg-red-50 flex items-center justify-center">

                <AlertTriangle

                    size={42}

                    className="text-red-600"

                />

            </div>

            <h2 className="mt-6 text-2xl font-bold">

                {title}

            </h2>

            <p className="mt-3 text-slate-500">

                {description}

            </p>

            <button

                onClick={onRetry}

                className="mt-8 rounded-xl bg-blue-600 text-white px-6 h-11 flex items-center gap-2"

            >

                <RefreshCcw size={18} />

                Retry

            </button>

        </div>

    )

}