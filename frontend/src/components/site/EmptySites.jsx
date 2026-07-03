import { Building2 } from "lucide-react";

export default function EmptySites(){

    return(

        <div className="rounded-3xl border border-dashed border-slate-300 bg-white p-16 text-center">

            <div className="mx-auto h-20 w-20 rounded-full bg-blue-50 flex items-center justify-center">

                <Building2
                    size={40}
                    className="text-blue-600"
                />

            </div>

            <h2 className="mt-6 text-2xl font-bold">

                No Projects Found

            </h2>

            <p className="mt-3 text-slate-500">

                Create your first construction project to start managing progress.

            </p>

        </div>

    )

}