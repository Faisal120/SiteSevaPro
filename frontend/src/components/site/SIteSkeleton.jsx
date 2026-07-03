export default function SiteSkeleton(){

    return(

        <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-6">

            {

                Array.from({length:6}).map((_,i)=>(

                    <div

                        key={i}

                        className="rounded-3xl bg-white p-6 animate-pulse"

                    >

                        <div className="h-6 w-40 bg-slate-200 rounded"/>

                        <div className="mt-6 h-3 w-full bg-slate-200 rounded"/>

                        <div className="mt-2 h-3 w-3/4 bg-slate-200 rounded"/>

                        <div className="mt-8 h-10 w-full bg-slate-200 rounded"/>

                    </div>

                ))

            }

        </div>

    )

}