import React from "react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { toast } from "sonner";
import FloorPlanViewer from "../components/FloorPlanViewer";

export default function DesignStudio() {

    const { user } = useAuth();

    const [sites, setSites] = React.useState([]);
    const [wallet, setWallet] = React.useState({
        credits: 0
    });

    const [loading, setLoading] = React.useState(false);

    const [layout, setLayout] = React.useState(null);

    const [plan, setPlan] = React.useState(null);

    const [form, setForm] = React.useState({
        site_id: "",
        plot_width: "",
        plot_length: "",
        facing: "East",
        bedrooms: 2,
        bathrooms: 2,
        floors: 1,
        type: "2D"
    });

    React.useEffect(() => {

        async function load() {

            try {

                const siteRes = await api.get("/sites");
                setSites(siteRes.data || []);

                try {

                    const walletRes = await api.get("/wallet");
                    setWallet(walletRes.data);

                } catch {

                    setWallet({
                        credits: 0
                    });

                }

            } catch {

                toast.error("Unable to load data");

            }

        }

        load();

    }, []);

    async function generateMap() {

        if (user?.plan === "FREE") {

            toast.error(
                "Upgrade to Pro to use AI Design Studio"
            );

            return;
        }

        setLoading(true);

        try {

            const { data } = await api.post(
                "/maps/generate",
                form
            );

            setLayout(
                data.layout
            );

            if (data.plan_id) {

                const planRes =
                    await api.get(
                        `/plans/${data.plan_id}`
                    );

                setPlan(
                    planRes.data
                );

            }

            try {

                const walletRes =
                    await api.get("/wallet");

                setWallet(
                    walletRes.data
                );

            } catch { }

            toast.success(
                "AI Floor Plan Generated Successfully"
            );

        }

        catch (e) {

            if (
                e?.response?.status === 402
            ) {

                toast.error(
                    "Insufficient AI Credits"
                );

                return;

            }

            toast.error(

                e?.response?.data?.detail ||

                "Failed to generate plan"

            );

        }

        finally {

            setLoading(false);

        }

    }

    return (

        <div className="space-y-6">

            <div className="ss-card p-6 bg-orange-50 border border-orange-200">

                <h2 className="font-bold text-2xl">
                    AI Design Studio
                </h2>

                <p className="text-gray-600 mt-2">

                    Generate professional AI Floor Plans.

                </p>

                <div className="mt-4 inline-flex items-center gap-3 bg-white rounded-xl px-4 py-3 shadow">

                    <span className="font-semibold">

                        AI Credits

                    </span>

                    <span className="text-orange-600 font-bold text-xl">

                        {wallet?.credits ?? 0}

                    </span>

                </div>

            </div>

            <div className="ss-card p-6 grid md:grid-cols-2 gap-4">

                <div>

                    <label>Select Site</label>

                    <select
                        className="ss-input"
                        value={form.site_id}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                site_id: e.target.value
                            })
                        }
                    >

                        <option value="">
                            Select Site
                        </option>

                        {

                            sites.map(site => (

                                <option
                                    key={site.id}
                                    value={site.id}
                                >

                                    {site.name}

                                </option>

                            ))

                        }

                    </select>

                </div>

                <div>

                    <label>
                        Plot Width (Feet)
                    </label>

                    <input
                        className="ss-input"
                        value={form.plot_width}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                plot_width: e.target.value
                            })
                        }
                    />

                </div>

                <div>

                    <label>
                        Plot Length (Feet)
                    </label>

                    <input
                        className="ss-input"
                        value={form.plot_length}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                plot_length: e.target.value
                            })
                        }
                    />

                </div>

                <div>

                    <label>
                        Facing
                    </label>

                    <select
                        className="ss-input"
                        value={form.facing}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                facing: e.target.value
                            })
                        }
                    >

                        <option>East</option>
                        <option>West</option>
                        <option>North</option>
                        <option>South</option>

                    </select>

                </div>

                <div>

                    <label>
                        Bedrooms
                    </label>

                    <input
                        type="number"
                        className="ss-input"
                        value={form.bedrooms}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                bedrooms: Number(e.target.value)
                            })
                        }
                    />

                </div>

                <div>

                    <label>
                        Bathrooms
                    </label>

                    <input
                        type="number"
                        className="ss-input"
                        value={form.bathrooms}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                bathrooms: Number(e.target.value)
                            })
                        }
                    />

                </div>

                <div>

                    <label>
                        Floors
                    </label>

                    <input
                        type="number"
                        className="ss-input"
                        value={form.floors}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                floors: Number(e.target.value)
                            })
                        }
                    />

                </div>

                <div>

                    <label>
                        Plan Type
                    </label>

                    <select
                        className="ss-input"
                        value={form.type}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                type: e.target.value
                            })
                        }
                    >

                        <option value="2D">
                            2D Floor Plan
                        </option>

                        {

                            user?.plan === "ENTERPRISE" && (

                                <option value="3D">

                                    3D Elevation

                                </option>

                            )

                        }

                    </select>

                </div>

            </div>

            <button
                onClick={generateMap}
                disabled={loading}
                className="bg-orange-500 hover:bg-orange-600 text-white px-8 py-3 rounded-lg font-semibold"
            >

                {

                    loading

                        ? "Generating AI Plan..."

                        : "Generate Plan"

                }

            </button>

            {

                layout && (

                    <div className="ss-card p-6">

                        <h2 className="font-bold text-xl mb-4">

                            Generated Floor Plan

                        </h2>

                        <img
                            src={data.image_url}
                            className="w-full rounded-lg border"
                        />

                        <a href={data.image_url} download>
                            Download PNG
                        </a>

                    </div>

                )

            }

        </div>

    );

}