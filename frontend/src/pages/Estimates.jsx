import React from "react";
import { Calculator, FileText, Download } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { StatCard, SectionTitle, EmptyState, Chip } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function Estimates() {
  const nav = useNavigate();
  const [list, setList] = React.useState([]);
  const [result, setResult] = React.useState(null);
  const [busy, setBusy] = React.useState(false);
  const [f, setF] = React.useState({ name: "", plot_area_sqft: 1200, floors: 2, construction_type: "RESIDENTIAL", quality: "STANDARD" });

  const load = async () => { const { data } = await api.get("/estimates"); setList(data); };
  React.useEffect(() => { load(); }, []);

  const compute = async (e) => {
    e.preventDefault();
    setBusy(true);
    try {
      const { data } = await api.post("/estimates", { ...f, plot_area_sqft: Number(f.plot_area_sqft), floors: Number(f.floors) });
      setResult(data);
      toast.success("Estimate generated");
      load();
    } catch { toast.error("Failed"); }
    finally { setBusy(false); }
  };

  const generateBOQ = async () => {
    if (!result) return;
    try {
      const { data } = await api.post("/boq/generate", { estimate_id: result.id, name: result.name + " BOQ" });
      toast.success("BOQ created");
      nav(`/app/boq/${data.id}`);
    } catch { toast.error("BOQ failed"); }
  };

  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Construction Estimator</h1>
        <p className="text-sm text-gray-500 mt-1">Get instant material quantities and cost projections.</p>
      </div>

      <div className="grid lg:grid-cols-2 gap-5">
        <form onSubmit={compute} className="ss-card p-6 grid gap-4">
          <SectionTitle title="Inputs" subtitle="Quick smart-formula estimation" />
          <div><label className="text-xs font-bold uppercase text-gray-500">Project name</label><input required className="ss-input mt-1" value={f.name} onChange={(e)=>setF({...f, name:e.target.value})} data-testid="est-name" /></div>
          <div className="grid grid-cols-2 gap-3">
            <div><label className="text-xs font-bold uppercase text-gray-500">Plot area (sqft)</label><input type="number" required className="ss-input mt-1" value={f.plot_area_sqft} onChange={(e)=>setF({...f, plot_area_sqft:e.target.value})} data-testid="est-area" /></div>
            <div><label className="text-xs font-bold uppercase text-gray-500">Floors</label><input type="number" required className="ss-input mt-1" value={f.floors} onChange={(e)=>setF({...f, floors:e.target.value})} data-testid="est-floors" /></div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div><label className="text-xs font-bold uppercase text-gray-500">Type</label>
              <Select value={f.construction_type} onValueChange={(v)=>setF({...f, construction_type:v})}>
                <SelectTrigger className="mt-1" data-testid="est-type"><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="RESIDENTIAL">Residential</SelectItem>
                  <SelectItem value="COMMERCIAL">Commercial</SelectItem>
                  <SelectItem value="INDUSTRIAL">Industrial</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div><label className="text-xs font-bold uppercase text-gray-500">Quality</label>
              <Select value={f.quality} onValueChange={(v)=>setF({...f, quality:v})}>
                <SelectTrigger className="mt-1" data-testid="est-quality"><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="BASIC">Basic</SelectItem>
                  <SelectItem value="STANDARD">Standard</SelectItem>
                  <SelectItem value="PREMIUM">Premium</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <button type="submit" disabled={busy} className="ss-btn-accent" data-testid="est-submit"><Calculator className="h-4 w-4" /> {busy ? "Calculating…" : "Generate Estimate"}</button>
        </form>

        <div className="ss-card p-6">
          <SectionTitle title="Result" />
          {!result ? (
            <div className="text-center py-12 text-gray-400">
              <Calculator className="h-10 w-10 mx-auto mb-2" />
              <p className="text-sm">Fill the form and hit generate.</p>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="text-3xl font-extrabold text-[#171717] font-display">{inr(result.total)}</div>
              <div className="text-xs text-gray-500">Built-up {result.builtup_sqft} sqft @ {inr(result.rate_per_sqft)}/sqft</div>
              <div className="grid grid-cols-2 gap-3 mt-3">
                <Box label="Material cost" v={result.material_cost} />
                <Box label="Labour cost" v={result.labour_cost} />
                <Box label="Overhead" v={result.overhead} />
                <Box label="Total" v={result.total} accent />
              </div>
              <div className="mt-4">
                <div className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-2">Materials</div>
                <ul className="space-y-1.5 text-sm">
                  <li className="flex justify-between"><span>Cement</span><span className="font-semibold">{result.materials.cement_bags} bags</span></li>
                  <li className="flex justify-between"><span>Steel</span><span className="font-semibold">{result.materials.steel_kg} kg</span></li>
                  <li className="flex justify-between"><span>Sand</span><span className="font-semibold">{result.materials.sand_cft} cft</span></li>
                  <li className="flex justify-between"><span>Aggregate</span><span className="font-semibold">{result.materials.aggregate_cft} cft</span></li>
                  <li className="flex justify-between"><span>Bricks</span><span className="font-semibold">{result.materials.bricks_pcs} pcs</span></li>
                </ul>
              </div>
              <button onClick={generateBOQ} className="ss-btn-ink w-full mt-2" data-testid="est-boq"><FileText className="h-4 w-4" /> Generate BOQ</button>
            </div>
          )}
        </div>
      </div>

      <div className="ss-card p-5">
        <SectionTitle title="Saved Estimates" />
        {list.length === 0 ? (
          <EmptyState icon={Calculator} title="No estimates yet" description="Your saved estimates will appear here." />
        ) : (
          <div className="overflow-x-auto">
            <table className="ss-table">
              <thead><tr><th>Name</th><th>Built-up</th><th>Type / Quality</th><th>Created</th><th className="text-right">Total</th></tr></thead>
              <tbody>
                {list.map((e) => (
                  <tr key={e.id} data-testid={`est-row-${e.id}`}>
                    <td className="font-semibold">{e.name}</td>
                    <td>{e.builtup_sqft} sqft</td>
                    <td><Chip className="bg-gray-100 text-gray-700">{e.input.construction_type} · {e.input.quality}</Chip></td>
                    <td className="text-gray-500">{fmtDate(e.created_at)}</td>
                    <td className="text-right font-bold">{inr(e.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function Box({ label, v, accent }) {
  return (
    <div className={`rounded-lg p-3 ${accent ? "bg-[#171717] text-white" : "bg-gray-50"}`}>
      <div className={`text-[10px] font-bold uppercase tracking-wider ${accent ? "text-gray-400" : "text-gray-500"}`}>{label}</div>
      <div className={`text-lg font-extrabold mt-0.5 ${accent ? "text-[#F97316]" : "text-[#171717]"}`}>{inr(v)}</div>
    </div>
  );
}
