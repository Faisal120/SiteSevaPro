import React from "react";
import { Download, FileImage, FileText, RefreshCw, Sparkles, Zap, WalletCards, Box, History } from "lucide-react";
import { api } from "@/lib/api";
import { toast } from "sonner";

const TECHNICAL_DRAWINGS = [["ELECTRICAL", "Electrical Plan"], ["PLUMBING", "Plumbing Plan"], ["COLUMN", "Column Layout"], ["STRUCTURAL", "Structural Plan"], ["FOUNDATION", "Foundation Plan"], ["DOOR_WINDOW", "Door/Window Schedule"]];

export default function DesignStudio() {
    const [sites, setSites] = React.useState([]);
    const [wallet, setWallet] = React.useState({ credits: 0 });
    const [loading, setLoading] = React.useState(false);
    const [technicalLoading, setTechnicalLoading] = React.useState("");
    const [layout, setLayout] = React.useState(null);
    const [design, setDesign] = React.useState(null);
    const [activeDrawing, setActiveDrawing] = React.useState("FLOOR");
    const [transactions, setTransactions] = React.useState([]);
    const [plan, setPlan] = React.useState("FREE");
    const [selectedFloor, setSelectedFloor] = React.useState(1);
    const [threeDLoading, setThreeDLoading] = React.useState(false);
    const [view3D, setView3D] = React.useState(null);
    const floorBrief = (floor_number) => ({ floor_number, bedrooms: 2, bathrooms: 2, living: true, dining: true, kitchen: true, staircase: true, parking: false, balcony: false, pooja_room: false, study_room: false, store_room: false, utility_room: false, lift: false });
    const [form, setForm] = React.useState({ site_id: "", project_name: "", plot_width: "", plot_length: "", facing: "East", bedrooms: 2, bathrooms: 2, floors: 1, type: "2D", variation: 0, dining: true, kitchen: true, staircase: true, parking: false, garden: false, pooja_room: false, study_room: false, store_room: false, utility_room: false, lift: false, floor_requirements: [floorBrief(1)] });

    React.useEffect(() => {
        async function load() {
            try {
                const [siteRes, walletRes, transactionRes, subscriptionRes] = await Promise.all([api.get("/sites"), api.get("/design-wallet"), api.get("/design-wallet/transactions"), api.get("/subscription")]);
                setSites(siteRes.data || []);
                setWallet(walletRes.data || { credits: 0 });
                setTransactions(transactionRes.data || []);
                setPlan(subscriptionRes.data?.plan || "FREE");
            } catch { toast.error("Unable to load Design Studio data"); }
        }
        load();
    }, []);

    const update = (values) => setForm((current) => ({ ...current, ...values }));
    const updateFloorCount = (floors) => setForm((current) => ({
        ...current,
        floors,
        floor_requirements: Array.from({ length: floors }, (_, index) => current.floor_requirements[index] || floorBrief(index + 1)),
    }));
    const updateFloorBrief = (floorNumber, values) => setForm((current) => ({
        ...current,
        floor_requirements: current.floor_requirements.map((brief) => brief.floor_number === floorNumber ? { ...brief, ...values } : brief),
    }));
    const technicalDrawing = design?.outputs?.technical_drawings?.[activeDrawing];
    const svg = activeDrawing === "FLOOR" ? layout?.svg || "" : technicalDrawing?.svg || "";

    async function refreshCredits() {
        const [response, history] = await Promise.all([api.get("/design-wallet"), api.get("/design-wallet/transactions")]);
        setWallet(response.data || { credits: 0 });
        setTransactions(history.data || []);
    }

    async function generateMap(variation = form.variation, type = form.type) {
        if (!form.site_id || !Number(form.plot_width) || !Number(form.plot_length)) return toast.error("Select a site and enter valid plot dimensions");
        if (type === "3D" && plan === "FREE") return toast.error("Upgrade to Pro or Enterprise to generate 3D planning views");
        setLoading(true);
        try {
            const { data } = await api.post("/maps/generate", { ...form, type, variation, plot_width: Number(form.plot_width), plot_length: Number(form.plot_length) });
            setLayout(data.outputs.layout);
            setDesign(data);
            setSelectedFloor(1);
            setView3D(null);
            setActiveDrawing("FLOOR");
            update({ variation });
            await refreshCredits();
            toast.success(variation ? "New rough option generated · 10 credits used" : "Your floor-wise responsive SVG plan is ready · 10 credits used");
        } catch (error) {
            toast.error(error?.response?.status === 402 ? "Insufficient design credits" : error?.response?.data?.detail || "Failed to generate plan");
        } finally { setLoading(false); }
    }

    async function generateTechnicalDrawing(type) {
        if (!design?.id) return;
        setTechnicalLoading(type);
        try {
            const { data } = await api.post(`/maps/${design.id}/technical/${type}`);
            setDesign(data);
            setView3D(null);
            setActiveDrawing(type);
            await refreshCredits();
            toast.success(`${type.toLowerCase()} drawing generated · 5 credits used`);
        } catch (error) { toast.error(error?.response?.data?.detail || "Unable to generate technical drawing"); }
        finally { setTechnicalLoading(""); }
    }

    function downloadSvg() {
        const drawing = view3D?.svg || svg;
        if (!drawing) return;
        const link = document.createElement("a");
        link.href = URL.createObjectURL(new Blob([drawing], { type: "image/svg+xml;charset=utf-8" }));
        link.download = `siteseva-${view3D ? "3d" : activeDrawing.toLowerCase()}-floor-${selectedFloor}.svg`;
        link.click();
        window.setTimeout(() => URL.revokeObjectURL(link.href), 0);
    }

    async function downloadPdf() {
        if (!design?.id) return;
        try {
            const type = activeDrawing === "FLOOR" ? "FLOOR" : activeDrawing;
            const { data } = await api.get(`/maps/${design.id}/download/${type}.pdf`, { params: { floor_number: selectedFloor }, responseType: "blob" });
            const link = document.createElement("a");
            link.href = URL.createObjectURL(new Blob([data], { type: "application/pdf" }));
            link.download = `siteseva-${type.toLowerCase()}-floor-${selectedFloor}.pdf`;
            link.click();
            window.setTimeout(() => URL.revokeObjectURL(link.href), 0);
        } catch (error) { toast.error(error?.response?.data?.detail || "Unable to prepare PDF download"); }
    }

    async function generate3D() {
        if (!design?.id) return toast.error("Generate and select a 2D floor first");
        const existing = design.outputs?.three_d?.[String(selectedFloor)];
        if (existing) {
            setView3D(existing);
            return;
        }
        setThreeDLoading(true);
        try { const { data } = await api.post(`/maps/${design.id}/3d/${selectedFloor}`); setDesign(data); setView3D(data.outputs?.three_d?.[String(selectedFloor)] || null); await refreshCredits(); toast.success("Furnished 3D planning view generated · 25 credits used"); }
        catch (error) { toast.error(error?.response?.data?.detail || "Unable to generate 3D planning view"); }
        finally { setThreeDLoading(false); }
    }

    return (
        <div className="studio-shell space-y-6">
            <section className="studio-hero ss-card p-6 lg:p-8">
                <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-start">
                    <div>
                        <div className="mb-2 flex items-center gap-2 text-blue-400"><Sparkles className="h-5 w-5" /><span className="text-sm font-semibold">Floor-wise architectural planning engine</span></div>
                        <h2 className="text-2xl font-bold">AI Design Studio</h2>
                        <p className="mt-2 max-w-2xl text-gray-400">Brief every floor separately, review a furnished CAD-style 2D plan, then create an open-top 3D concept for one approved floor.</p>
                    </div>
                    <div className="studio-credit-card rounded-xl px-5 py-4"><div className="text-sm font-medium text-gray-400">Design credits</div><div className="mt-1 flex items-baseline gap-2"><span className="text-3xl font-bold text-blue-400">{wallet?.credits ?? 0}</span><span className="text-xs text-gray-500">available</span></div><p className="mt-3 inline-flex items-center gap-1 text-xs font-semibold text-blue-300"><WalletCards className="h-3.5 w-3.5" />Included with your subscription</p></div>
                </div>
                <div className="studio-pricing mt-6 grid gap-3 rounded-xl p-4 text-sm md:grid-cols-3"><p><strong>2D floor plan</strong><br />10 credits per multi-floor brief.</p><p><strong>Furnished 3D concept</strong><br />25 credits per selected floor · Pro and Enterprise.</p><p><strong>Technical plan</strong><br />5 credits each after a floor plan.</p></div>
            </section>

            <section className="studio-steps grid gap-3 md:grid-cols-3">
                <div className="studio-step"><span>01</span><div><strong>Create a brief</strong><p>Enter plot, facing and room requirements.</p></div></div>
                <div className="studio-step"><span>02</span><div><strong>Review rough options</strong><p>Generate another option whenever the plan is not right.</p></div></div>
                <div className="studio-step"><span>03</span><div><strong>Prepare technical plans</strong><p>Use the base plan for discipline overlays.</p></div></div>
            </section>

            <section className="ss-card studio-form-card p-6">
                <div className="mb-5 flex items-center justify-between gap-4"><div><h3 className="font-bold text-lg">Plan requirements</h3><p className="text-sm text-gray-400">All dimensions are in feet. 3D stays unavailable until this 2D plan is approved.</p></div><span className="studio-badge rounded-full px-3 py-1 text-sm font-semibold">2D Floor Plan</span></div>
                <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                    <div><label>Select site</label><select className="ss-input" value={form.site_id} onChange={(e) => update({ site_id: e.target.value })}><option value="">Select site</option>{sites.map((site) => <option key={site.id} value={site.id}>{site.name}</option>)}</select></div>
                    <div><label>Project name <span className="text-gray-500">(optional)</span></label><input className="ss-input" value={form.project_name} onChange={(e) => update({ project_name: e.target.value })} placeholder="e.g. Sharma Residence" /></div>
                    <div><label>Facing</label><select className="ss-input" value={form.facing} onChange={(e) => update({ facing: e.target.value })}>{["East", "West", "North", "South"].map((facing) => <option key={facing}>{facing}</option>)}</select></div>
                    <div><label>Plot width (ft)</label><input min="10" type="number" className="ss-input" value={form.plot_width} onChange={(e) => update({ plot_width: e.target.value })} placeholder="30" /></div>
                    <div><label>Plot length (ft)</label><input min="10" type="number" className="ss-input" value={form.plot_length} onChange={(e) => update({ plot_length: e.target.value })} placeholder="50" /></div>
                    <div><label>Floors</label><input min="1" max="5" type="number" className="ss-input" value={form.floors} onChange={(e) => updateFloorCount(Math.max(1, Math.min(5, Number(e.target.value) || 1)))} /></div>
                </div>
                <fieldset className="mt-6"><legend className="mb-1 font-semibold">Floor-by-floor brief</legend><p className="mb-3 text-sm text-gray-400">Parking is available only on the ground floor. Upper floors use the same plot envelope without vehicle access.</p><div className="grid gap-4 xl:grid-cols-2">{form.floor_requirements.map((brief) => <div key={brief.floor_number} className="rounded-xl border border-white/10 bg-black/15 p-4"><div className="mb-3 flex items-center justify-between"><strong>{brief.floor_number === 1 ? "Ground floor" : `Floor ${brief.floor_number - 1}`}</strong>{brief.floor_number === 1 && <span className="text-xs text-blue-300">Parking permitted</span>}</div><div className="grid gap-3 sm:grid-cols-2"><label>Bedrooms<input min="0" max="8" type="number" className="ss-input" value={brief.bedrooms} onChange={(e) => updateFloorBrief(brief.floor_number, { bedrooms: Number(e.target.value) })} /></label><label>Bathrooms<input min="0" max="8" type="number" className="ss-input" value={brief.bathrooms} onChange={(e) => updateFloorBrief(brief.floor_number, { bathrooms: Number(e.target.value) })} /></label></div><div className="mt-3 grid gap-2 sm:grid-cols-2">{[["living", "Living room"], ["dining", "Dining room"], ["kitchen", "Kitchen"], ["staircase", "Staircase"], ["balcony", "Balcony"], ["pooja_room", "Pooja room"], ["study_room", "Study"], ["store_room", "Store"], ["utility_room", "Utility"], ["lift", "Lift"], ...(brief.floor_number === 1 ? [["parking", "Car / bike parking"]] : [])].map(([field, label]) => <label key={field} className="studio-option flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-sm"><input type="checkbox" checked={brief[field]} onChange={(e) => updateFloorBrief(brief.floor_number, { [field]: e.target.checked })} />{label}</label>)}</div></div>)}</div></fieldset>
                <div className="mt-6 flex flex-col gap-3 border-t border-white/10 pt-5 sm:flex-row sm:items-center sm:justify-between"><p className="max-w-2xl text-sm text-gray-500">This is an overview and rough map planning. For detailed planning, contact <a className="font-semibold text-blue-300 hover:text-white" href="https://wa.me/917905226334" target="_blank" rel="noreferrer">+91 7905226334 (WhatsApp only)</a>. Generate 2D plans first; select one floor from the result before making its 3D furnished concept.</p><button onClick={() => generateMap()} disabled={loading} className="inline-flex shrink-0 items-center justify-center gap-2 rounded-lg bg-blue-500 px-6 py-3 font-semibold text-white hover:bg-blue-600 disabled:cursor-not-allowed disabled:opacity-60"><FileImage className="h-4 w-4" />{loading ? "Generating plan…" : `Generate ${form.floors} Floor 2D Plan · 10 credits`}</button></div>
            </section>

            {layout && <section className="ss-card studio-drawing-card overflow-hidden p-0">
                <div className="flex flex-col gap-3 border-b border-white/10 p-5 sm:flex-row sm:items-center sm:justify-between"><div><h2 className="font-bold text-xl">{view3D ? `${view3D.label} · Furnished 3D Concept` : activeDrawing === "FLOOR" ? "Generated 2D Floor Plan" : technicalDrawing?.title}</h2><p className="text-sm text-gray-400">Choose an approved floor, then create its furnished 3D planning concept.</p></div><div className="flex flex-wrap gap-2"><button onClick={() => generateMap(form.variation + 1)} disabled={loading || technicalLoading} className="inline-flex items-center justify-center gap-2 rounded-lg bg-blue-500 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-600 disabled:opacity-60"><RefreshCw className="h-4 w-4" />Another 2D option · 10</button><button onClick={downloadSvg} className="studio-download inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold"><Download className="h-4 w-4" />Download SVG</button>{!view3D && <button onClick={downloadPdf} className="studio-download inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold"><FileText className="h-4 w-4" />Download PDF</button>}</div></div>
                <div className="flex flex-wrap gap-2 border-b border-white/10 p-3">{(design?.outputs?.floor_plans || [{ floor_number: 1, label: "Ground Floor", layout }]).map((floor) => <button key={floor.floor_number} onClick={() => { setSelectedFloor(floor.floor_number); setLayout(floor.layout); setView3D(null); setActiveDrawing("FLOOR"); }} className={`rounded-lg px-3 py-2 text-sm font-semibold ${selectedFloor === floor.floor_number && !view3D ? "bg-white text-gray-900" : "text-gray-300"}`}>{floor.label}</button>)}<button onClick={generate3D} disabled={threeDLoading || plan === "FREE"} className="ml-auto inline-flex items-center gap-2 rounded-lg bg-blue-500 px-3 py-2 text-sm font-semibold text-white disabled:opacity-50"><Box className="h-4 w-4" />{threeDLoading ? "Rendering 3D…" : "Generate selected floor 3D · 25"}</button></div>
                <div className="studio-tabs flex flex-wrap gap-2 border-b border-white/10 p-3"><button onClick={() => { setView3D(null); setActiveDrawing("FLOOR"); }} className={`rounded-lg px-3 py-2 text-sm font-semibold ${activeDrawing === "FLOOR" ? "bg-white text-gray-900" : "text-gray-300"}`}>Floor Plan</button>{TECHNICAL_DRAWINGS.map(([type, label]) => { const exists = design?.outputs?.technical_drawings?.[type]; return <button key={type} onClick={() => { if (exists) { setView3D(null); setActiveDrawing(type); } else generateTechnicalDrawing(type); }} disabled={Boolean(technicalLoading)} className={`inline-flex items-center gap-1 rounded-lg px-3 py-2 text-sm font-semibold disabled:opacity-60 ${activeDrawing === type ? "bg-white text-gray-900" : "text-gray-300"}`}><Zap className="h-3.5 w-3.5" />{technicalLoading === type ? "Generating…" : exists ? label : `${label} · 5`}</button>; })}</div>
                <div className="floor-plan-preview p-3 sm:p-6"><p className="mb-3 text-xs font-semibold uppercase tracking-[.15em] text-gray-500">{view3D ? "Furnished 3D conceptual renderer · selected floor" : "2D CAD plan with furniture"}</p><div dangerouslySetInnerHTML={{ __html: view3D?.svg || svg }} /></div>
            </section>}
            <section className="ss-card p-6"><div className="mb-4 flex items-center gap-2"><History className="h-5 w-5 text-blue-400" /><div><h3 className="font-bold">Design credit history</h3><p className="text-sm text-gray-400">Usage and subscription credit allocations.</p></div></div>{transactions.length ? <div className="overflow-x-auto"><table className="ss-table"><thead><tr><th>Date</th><th>Type</th><th>Description</th><th className="text-right">Credits</th></tr></thead><tbody>{transactions.map((transaction) => <tr key={transaction.id || `${transaction.created_at}-${transaction.description}`}><td>{new Date(transaction.created_at).toLocaleDateString("en-IN")}</td><td>{transaction.type}</td><td>{transaction.description}</td><td className={`text-right font-bold ${transaction.credits >= 0 ? "text-emerald-400" : "text-blue-300"}`}>{transaction.credits >= 0 ? "+" : ""}{transaction.credits}</td></tr>)}</tbody></table></div> : <p className="py-5 text-sm text-gray-500">No design credit activity yet.</p>}</section>
        </div>
    );
}
