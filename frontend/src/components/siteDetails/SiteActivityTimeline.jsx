import {
  Users,
  Package,
  Wallet,
  FileText,
  Camera,
  Clock3
} from "lucide-react";

const iconMap = {
  attendance: Users,
  material: Package,
  expense: Wallet,
  report: FileText,
  photo: Camera,
};

export default function SiteActivityTimeline({

  activities = []

}) {

  if (!activities.length) {

    return (

      <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

        <div className="p-6 border-b border-slate-100">

          <h2 className="text-xl font-bold">

            Today's Activity

          </h2>

          <p className="text-slate-500 mt-1">

            Live site updates

          </p>

        </div>

        <div className="p-10 text-center">

          <Clock3

            className="mx-auto text-slate-300"

            size={46}

          />

          <h3 className="mt-5 text-lg font-semibold">

            No Activity Yet

          </h3>

          <p className="mt-2 text-slate-500">

            Activities will appear here automatically.

          </p>

        </div>

      </div>

    );

  }

  return (

    <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

      <div className="p-6 border-b border-slate-100">

        <h2 className="text-xl font-bold">

          Today's Activity

        </h2>

        <p className="text-slate-500 mt-1">

          Live construction feed

        </p>

      </div>

      <div className="p-6">

        {

          activities.map((activity, index) => {

            const Icon = iconMap[activity.type] || Clock3;

            return (

              <div

                key={index}

                className="flex gap-5"

              >

                {/* Timeline */}

                <div className="flex flex-col items-center">

                  <div className="h-12 w-12 rounded-2xl bg-blue-50 flex items-center justify-center">

                    <Icon

                      size={22}

                      className="text-blue-600"

                    />

                  </div>

                  {

                    index !== activities.length - 1 && (

                      <div className="w-px flex-1 bg-slate-200 mt-2"/>

                    )

                  }

                </div>

                {/* Content */}

                <div className="pb-8 flex-1">

                  <div className="flex justify-between">

                    <h3 className="font-semibold">

                      {activity.title}

                    </h3>

                    <span className="text-sm text-slate-500">

                      {activity.time}

                    </span>

                  </div>

                  <p className="mt-2 text-slate-500">

                    {activity.description}

                  </p>

                  {

                    activity.user && (

                      <div className="mt-3 text-sm text-blue-600 font-medium">

                        {activity.user}

                      </div>

                    )

                  }

                </div>

              </div>

            );

          })

        }

      </div>

    </div>

  );

}