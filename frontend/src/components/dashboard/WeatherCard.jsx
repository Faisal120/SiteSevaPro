import React from "react";
import { CloudSun } from "lucide-react";

export default function WeatherCard() {

    return (

        <div className="rounded-3xl bg-gradient-to-br from-blue-600 to-blue-700 text-white p-6 shadow-lg">

            <div className="flex justify-between items-center">

                <div>

                    <p className="text-sm opacity-80">

                        Lucknow

                    </p>

                    <h2 className="text-5xl font-bold mt-3">

                        34°

                    </h2>

                    <p className="mt-2">

                        Sunny

                    </p>

                </div>

                <CloudSun size={52} />

            </div>

        </div>

    )

}