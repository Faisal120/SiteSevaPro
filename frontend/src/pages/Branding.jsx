import React, { useEffect, useState } from "react";
import { api, uploadToCloudinary } from "@/lib/api";
import { toast } from "sonner";


export default function Branding() {
    const [logoFile, setLogoFile] = useState(null);

    const [form, setForm] = useState({
        company_name: "",
        gst_number: "",
        company_address: "",
        phone: "",
        website: "",
        email: "",
        logo_url: "",
    });

    useEffect(() => {
        loadBranding();
    }, []);

    async function loadBranding() {
        try {
            const { data } = await api.get("/branding");
            setForm({
                ...form,
                ...data,
            });
        } catch (err) {
            console.log(err);
        }
    }
    async function uploadLogo() {

        if (!logoFile) return;

        try {

            const uploaded =
                await uploadToCloudinary(
                    logoFile,
                    "siteseva/company_logos"
                );

            setForm(prev => ({
                ...prev,
                logo_url: uploaded.url
            }));

            toast.success(
                "Logo uploaded successfully"
            );

            return uploaded.url;

        } catch (err) {

            toast.error(
                "Logo upload failed"
            );

            return null;
        }
    }

    async function saveBranding() {

        try {

            let logoUrl =
                form.logo_url;

            if (logoFile) {

                const uploadedUrl =
                    await uploadLogo();

                if (uploadedUrl)
                    logoUrl =
                        uploadedUrl;
            }

            await api.put(
                "/branding",
                {
                    ...form,
                    logo_url: logoUrl
                }
            );

            toast.success(
                "Branding Saved Successfully"
            );

            loadBranding();

        } catch (err) {

            toast.error(
                "Failed to save branding"
            );

        }
    }

    return (
        <div className="max-w-4xl">

            <h1 className="text-3xl font-bold mb-6">
                Company Branding
            </h1>

            <div className="bg-white rounded-xl border p-6 grid md:grid-cols-2 gap-4">

                <input
                    className="border rounded-lg p-3"
                    placeholder="Company Name"
                    value={form.company_name}
                    onChange={(e) =>
                        setForm({
                            ...form,
                            company_name: e.target.value
                        })
                    }
                />

                <input
                    className="border rounded-lg p-3"
                    placeholder="GST Number"
                    value={form.gst_number}
                    onChange={(e) =>
                        setForm({
                            ...form,
                            gst_number: e.target.value
                        })
                    }
                />

                <input
                    className="border rounded-lg p-3"
                    placeholder="Email"
                    value={form.email}
                    onChange={(e) =>
                        setForm({
                            ...form,
                            email: e.target.value
                        })
                    }
                />

                <input
                    className="border rounded-lg p-3"
                    placeholder="Phone"
                    value={form.phone}
                    onChange={(e) =>
                        setForm({
                            ...form,
                            phone: e.target.value
                        })
                    }
                />

                <input
                    className="border rounded-lg p-3"
                    placeholder="Website"
                    value={form.website}
                    onChange={(e) =>
                        setForm({
                            ...form,
                            website: e.target.value
                        })
                    }
                />

                <input
                    className="border rounded-lg p-3"
                    placeholder="Logo URL"
                    value={form.logo_url}
                    onChange={(e) =>
                        setForm({
                            ...form,
                            logo_url: e.target.value
                        })
                    }
                />

                <textarea
                    className="border rounded-lg p-3 md:col-span-2"
                    rows="4"
                    placeholder="Company Address"
                    value={form.company_address}
                    onChange={(e) =>
                        setForm({
                            ...form,
                            company_address: e.target.value
                        })
                    }
                />

                <input
                    type="file"
                    accept="image/*"
                    onChange={(e) =>
                        setLogoFile(
                            e.target.files[0]
                        )
                    }
                />

                {
                    form.logo_url && (

                        <img
                            src={form.logo_url}
                            alt="Company Logo"
                            className="
    h-24
    w-24
    object-contain
    border
    rounded-lg
    p-2
    "
                        />

                    )
                }

                <button
                    onClick={saveBranding}
                    className="
          bg-[#F97316]
          text-white
          rounded-lg
          py-3
          font-semibold
          "
                >
                    Save Branding
                </button>

            </div>

        </div>
    );
}