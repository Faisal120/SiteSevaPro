import React from "react";
import { Building2, Check, Globe2, ImagePlus, Mail, Phone, Save, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { api, uploadToCloudinary } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const DEFAULTS = {
  company_name: "", gst_number: "", company_address: "", phone: "", website: "", email: "", logo_url: "",
};

export default function Branding() {
  const { user } = useAuth();
  const [form, setForm] = React.useState(DEFAULTS);
  const [logoFile, setLogoFile] = React.useState(null);
  const [saving, setSaving] = React.useState(false);

  const load = React.useCallback(async () => {
    try {
      const response = await api.get("/branding");
      setForm({ ...DEFAULTS, company_name: user?.company_name || "", ...(response.data || {}) });
    } catch { setForm((current) => ({ ...current, company_name: current.company_name || user?.company_name || "" })); }
  }, [user?.company_name]);
  React.useEffect(() => { load(); }, [load]);
  const update = (key) => (event) => setForm((current) => ({ ...current, [key]: event.target.value }));

  async function save(event) {
    event.preventDefault();
    setSaving(true);
    try {
      let logo_url = form.logo_url;
      if (logoFile) logo_url = (await uploadToCloudinary(logoFile, "siteseva/company_logos")).url;
      await api.put("/branding", { ...form, logo_url });
      setForm((current) => ({ ...current, logo_url }));
      window.dispatchEvent(new Event("siteseva:branding-updated"));
      toast.success("Company branding saved and applied across your workspace.");
    } catch (error) { toast.error(error?.response?.data?.detail || "Unable to save company branding"); }
    finally { setSaving(false); }
  }

  return <div className="mx-auto max-w-5xl space-y-6 ss-fade-in">
    <section className="relative isolate overflow-hidden rounded-[20px] border border-[#30323a] bg-[#111214] p-6 sm:p-8"><div className="pointer-events-none absolute -right-16 -top-16 -z-10 h-56 w-56 rounded-full bg-blue-500/15 blur-3xl" /><div className="relative z-10 flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between"><div className="min-w-0"><p className="text-xs font-semibold uppercase tracking-[.18em] text-blue-400">Workspace identity</p><h1 className="mt-2 font-display text-3xl font-extrabold tracking-tight text-white">Company branding</h1><p className="mt-3 max-w-2xl text-sm leading-6 text-gray-400">Your logo and business details are used in the navigation, dashboard, estimates and BOQ documents.</p></div><div className="relative z-10 inline-flex shrink-0 items-center gap-2 rounded-lg border border-blue-500/25 bg-blue-500/10 px-3 py-2 text-sm font-semibold text-blue-200"><ShieldCheck className="h-4 w-4 shrink-0" />Company workspace</div></div></section>

    <form onSubmit={save} className="grid gap-6 lg:grid-cols-[1fr_320px]">
      <section className="ss-card p-6"><div className="mb-6"><h2 className="font-display text-xl font-bold">Business details</h2><p className="mt-1 text-sm text-gray-500">Keep these details current for documents and client-facing communication.</p></div><div className="grid gap-5 sm:grid-cols-2"><Field label="Company name" value={form.company_name} onChange={update("company_name")} required /><Field label="GST number" value={form.gst_number} onChange={update("gst_number")} /><Field label="Email" type="email" icon={Mail} value={form.email} onChange={update("email")} /><Field label="Phone" type="tel" icon={Phone} value={form.phone} onChange={update("phone")} /><Field label="Website" type="url" icon={Globe2} value={form.website} onChange={update("website")} placeholder="https://yourcompany.com" /><div className="sm:col-span-2"><label className="text-sm font-semibold text-gray-300">Registered address</label><textarea rows="4" className="ss-input mt-2 h-auto py-3" value={form.company_address} onChange={update("company_address")} placeholder="Office address, city, state and PIN" /></div></div><div className="mt-7 flex justify-end border-t border-white/10 pt-5"><button disabled={saving} className="ss-btn-accent"><Save className="h-4 w-4" />{saving ? "Saving…" : "Save company branding"}</button></div></section>
      <aside className="space-y-5"><section className="ss-card p-5"><p className="text-sm font-semibold text-gray-200">Logo</p><p className="mt-1 text-xs leading-5 text-gray-500">PNG, JPG or SVG. A square image works best in the application navigation.</p><label className="mt-5 flex aspect-square cursor-pointer flex-col items-center justify-center overflow-hidden rounded-2xl border border-dashed border-[#3b82f6]/45 bg-[#17191d] p-4 text-center hover:bg-blue-500/10">{form.logo_url ? <img src={form.logo_url} alt="Company logo preview" className="h-full w-full object-contain" /> : <><div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-500/15 text-blue-400"><Building2 className="h-6 w-6" /></div><span className="mt-3 text-sm font-semibold text-gray-200">Upload company logo</span><span className="mt-1 text-xs text-gray-500">Choose image</span></>}<input className="sr-only" type="file" accept="image/*" onChange={(event) => { const file = event.target.files?.[0]; if (file) { setLogoFile(file); setForm((current) => ({ ...current, logo_url: URL.createObjectURL(file) })); } }} /></label>{form.logo_url && <button type="button" onClick={() => { setLogoFile(null); setForm((current) => ({ ...current, logo_url: "" })); }} className="mt-3 text-xs font-semibold text-blue-300 hover:text-white">Remove logo</button>}</section><section className="rounded-2xl border border-[#30323a] bg-[#111214] p-5"><p className="text-sm font-semibold text-white">Where it appears</p><ul className="mt-4 space-y-3 text-sm text-gray-400"><li className="flex gap-2"><Check className="mt-0.5 h-4 w-4 text-blue-400" />Sidebar and company workspace</li><li className="flex gap-2"><Check className="mt-0.5 h-4 w-4 text-blue-400" />Dashboard company overview</li><li className="flex gap-2"><Check className="mt-0.5 h-4 w-4 text-blue-400" />BOQ and estimate documents</li></ul></section></aside>
    </form>
  </div>;
}

function Field({ label, icon: Icon, ...props }) {
  return <label><span className="text-sm font-semibold text-gray-300">{label}</span><span className="relative mt-2 block">{Icon && <Icon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-500" />}<input className={`ss-input ${Icon ? "pl-10" : ""}`} {...props} /></span></label>;
}
