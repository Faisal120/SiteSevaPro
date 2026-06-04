import React from "react";
import { Plus, Building, Phone, MapPin, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { SectionTitle, EmptyState, Chip } from "@/components/dashboard/Primitives";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";

export default function Vendors() {
  const [list, setList] = React.useState([]);
  const [open, setOpen] = React.useState(false);
  const load = async () => { const { data } = await api.get("/vendors"); setList(data); };
  React.useEffect(() => { load(); }, []);
  const remove = async (id) => { if (!confirm("Delete vendor?")) return; await api.delete(`/vendors/${id}`); toast.success("Removed"); load(); };
  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Vendors</h1>
          <p className="text-sm text-gray-500 mt-1">Supplier directory across all sites.</p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <button className="ss-btn-accent" data-testid="vendor-add"><Plus className="h-4 w-4" /> New Vendor</button>
          </DialogTrigger>
          <VendorForm onDone={() => { setOpen(false); load(); }} />
        </Dialog>
      </div>
      {list.length === 0 ? (
        <EmptyState icon={Building} title="No vendors yet" />
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
          {list.map((v) => (
            <div key={v.id} className="ss-card p-5" data-testid={`vendor-card-${v.id}`}>
              <div className="flex items-start justify-between">
                <div className="h-10 w-10 rounded-lg bg-[#171717] text-[#F97316] flex items-center justify-center"><Building className="h-5 w-5" /></div>
                <button onClick={() => remove(v.id)} className="text-gray-400 hover:text-red-500"><Trash2 className="h-4 w-4" /></button>
              </div>
              <h3 className="mt-4 font-display font-bold text-lg">{v.name}</h3>
              <div className="mt-2 text-xs text-gray-500 space-y-1">
                {v.contact && <div className="flex items-center gap-1.5"><Phone className="h-3.5 w-3.5" /> {v.contact}</div>}
                {v.address && <div className="flex items-center gap-1.5"><MapPin className="h-3.5 w-3.5" /> {v.address}</div>}
                {v.gst && <div className="font-mono">GST: {v.gst}</div>}
              </div>
              {v.categories?.length > 0 && (
                <div className="mt-3 flex flex-wrap gap-1">{v.categories.map((c) => <Chip key={c} className="bg-gray-100 text-gray-700">{c}</Chip>)}</div>
              )}
              {v.payment_terms && <div className="mt-3 text-xs text-gray-500">Terms: {v.payment_terms}</div>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function VendorForm({ onDone }) {
  const [f, setF] = React.useState({ name: "", contact: "", gst: "", address: "", payment_terms: "", categories_raw: "" });
  const submit = async (e) => {
    e.preventDefault();
    try {
      await api.post("/vendors", { ...f, categories: f.categories_raw.split(",").map(s => s.trim()).filter(Boolean) });
      toast.success("Vendor added"); onDone();
    } catch { toast.error("Failed"); }
  };
  return (
    <DialogContent>
      <DialogHeader><DialogTitle>New Vendor</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4">
        <div><label className="text-xs font-bold uppercase text-gray-500">Name</label><input required className="ss-input mt-1" value={f.name} onChange={(e)=>setF({...f, name:e.target.value})} data-testid="vendorf-name" /></div>
        <div className="grid grid-cols-2 gap-3">
          <div><label className="text-xs font-bold uppercase text-gray-500">Contact</label><input className="ss-input mt-1" value={f.contact} onChange={(e)=>setF({...f, contact:e.target.value})} /></div>
          <div><label className="text-xs font-bold uppercase text-gray-500">GST</label><input className="ss-input mt-1" value={f.gst} onChange={(e)=>setF({...f, gst:e.target.value})} /></div>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Address</label><input className="ss-input mt-1" value={f.address} onChange={(e)=>setF({...f, address:e.target.value})} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Payment Terms</label><input className="ss-input mt-1" placeholder="Net 30, Net 15…" value={f.payment_terms} onChange={(e)=>setF({...f, payment_terms:e.target.value})} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Categories (comma separated)</label><input className="ss-input mt-1" placeholder="Cement, Steel" value={f.categories_raw} onChange={(e)=>setF({...f, categories_raw:e.target.value})} /></div>
        <button type="submit" className="ss-btn-accent" data-testid="vendorf-submit">Save</button>
      </form>
    </DialogContent>
  );
}
