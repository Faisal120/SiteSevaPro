export default function SkeletonCard() {

    return (

        <div className="rounded-3xl bg-white border border-slate-200 p-6 animate-pulse">

            <div className="h-6 w-40 rounded bg-slate-200" />

            <div className="mt-6 h-4 w-full rounded bg-slate-200" />

            <div className="mt-3 h-4 w-3/4 rounded bg-slate-200" />

            <div className="mt-8 h-10 rounded-xl bg-slate-200" />

        </div>

    )

}