import React from "react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { toast } from "sonner";
import FloorPlanViewer from "./FloorPlanViewer";

export default async function DesignStudio() {

    const { user } = useAuth();
    const [sites, setSites] = React.useState([]);
    const [loading, setLoading] = React.useState(false);
    const [preview, setPreview] = React.useState(null);
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
        api.get("/sites")
            .then(r => setSites(r.data || []));
    }, []);

    async function generateMap() {

        if (
            user?.plan === "FREE"
        ) {
            toast.error(
                "Upgrade to Pro to use Design Studio"
            );
            return;
        }

        setLoading(true);

        try {

            const { data } =
                await api.post(
                    "/maps/generate",
                    form
                );

            toast.success(
                "Map Request Created"
            );

            setPreview(data);

        } catch (e) {

            toast.error(
                e?.response?.data?.detail ||
                "Failed"
            );

        } finally {

            setLoading(false);

        }
    }

    const planRes =
        await api.get(
            `/plans/${data.id}`
        );

    setPlan(
        planRes.data
    );

    return (
        <div className="space-y-6">

            <div className="ss-card p-6 bg-orange-50 border border-orange-200">

                <h2 className="font-bold text-xl">
                    AI Design Studio
                </h2>

                <p className="text-gray-600 mt-2">
                    Generate professional construction drawings.
                </p>

                <div className="grid md:grid-cols-3 gap-3 mt-4">

                    <div className="bg-white p-3 rounded-lg">
                        <b>Pro Plan</b>
                        <p className="text-sm">
                            2D Floor Plans
                        </p>
                    </div>

                    <div className="bg-white p-3 rounded-lg">
                        <b>Pro Plus</b>
                        <p className="text-sm">
                            2D + 3D Elevation
                        </p>
                    </div>

                    <div className="bg-white p-3 rounded-lg">
                        <b>Branding Included</b>
                        <p className="text-sm">
                            Client & Company Details
                        </p>
                    </div>

                </div>

            </div>

            <div className="ss-card p-6 grid md:grid-cols-2 gap-4">

                <div>
                    <label className="text-sm font-medium">
                        Select Site
                    </label>

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

                        {sites.map(site => (
                            <option
                                key={site.id}
                                value={site.id}
                            >
                                {site.name}
                            </option>
                        ))}

                    </select>
                </div>

                <div>
                    <label className="text-sm font-medium">
                        Plot Width (Feet)
                    </label>

                    <input
                        className="ss-input mt-1"
                        placeholder="Plot Width (ft)"
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
                    <label className="text-sm font-medium">
                        Plot Length (Feet)
                    </label>
                    <input
                        className="ss-input mt-1"
                        placeholder="Plot Length (ft)"
                        value={form.plot_length}
                        onChange={(e) =>
                            setForm({
                                ...form,
                                plot_length: e.target.value
                            })
                        }
                    />
                </div>

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
                        2D Plan
                    </option>

                    {user?.plan ===
                        "ENTERPRISE" && (
                            <option value="3D">
                                3D Elevation
                            </option>
                        )}

                </select>

            </div>

            <button
                onClick={generateMap}
                disabled={loading}
                className="
        bg-[#F97316]
        text-white
        px-6
        py-3
        rounded-lg
        font-semibold
        "
            >
                {
                    loading
                        ? "Generating..."
                        : "Generate Plan"
                }
            </button>


            {
                preview && (

                    <div className="
ss-card
p-6
space-y-4
">

                        <h3 className="
font-bold
text-xl
">
                            Generated Plan
                        </h3>

                        <img
                            src={preview.image_url}
                            alt="Floor Plan"
                            className="
w-full
rounded-lg
border
"
                        />

                        <a
                            href={preview.image_url}
                            target="_blank"
                            rel="noreferrer"
                            className="
inline-block
bg-green-600
text-white
px-4
py-2
rounded-lg
"
                        >
                            Download Image
                        </a>

                    </div>

                )
            }

            {
                plan && (
                    <FloorPlanViewer
                        plan={plan}
                    />
                )
            }

        </div>
    );
}