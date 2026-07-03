export default function PageHeader({

    title,

    subtitle,

    actions

}) {

    return (

        <div className="flex flex-col xl:flex-row justify-between gap-5 items-start xl:items-center">

            <div>

                <h1 className="text-3xl font-bold">

                    {title}

                </h1>

                <p className="mt-2 text-slate-500">

                    {subtitle}

                </p>

            </div>

            <div className="flex gap-3">

                {actions}

            </div>

        </div>

    )

}