export default function SectionCard({

    title,

    subtitle,

    children,

    actions

}) {

    return (

        <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

            <div className="flex justify-between items-center p-6 border-b">

                <div>

                    <h2 className="text-xl font-bold">

                        {title}

                    </h2>

                    {

                        subtitle && (

                            <p className="text-slate-500 mt-1">

                                {subtitle}

                            </p>

                        )

                    }

                </div>

                {actions}

            </div>

            <div className="p-6">

                {children}

            </div>

        </div>

    )

}