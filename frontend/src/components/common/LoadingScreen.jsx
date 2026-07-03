import { Loader2 } from "lucide-react";

export default function LoadingScreen({

    title = "Loading...",

    description = "Please wait while we fetch data."

}) {

    return (

        <div className="min-h-[60vh] flex flex-col items-center justify-center">

            <div className="h-20 w-20 rounded-full bg-blue-50 flex items-center justify-center">

                <Loader2

                    size={40}

                    className="animate-spin text-blue-600"

                />

            </div>

            <h2 className="mt-6 text-2xl font-bold">

                {title}

            </h2>

            <p className="mt-3 text-slate-500">

                {description}

            </p>

        </div>

    )

}