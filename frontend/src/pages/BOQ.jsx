import React from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, FileText, Printer } from "lucide-react";
import { api } from "@/lib/api";
import { SectionTitle, EmptyState } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";

export default function BOQ() {
  const { boqId } = useParams();
  const nav = useNavigate();
  const [list, setList] = React.useState([]);
  const [boq, setBoq] = React.useState(null);
  const [branding, setBranding] = React.useState(null);

  React.useEffect(() => {

    api.get("/branding")
      .then((r) => setBranding(r.data))
      .catch(() => { });

    if (boqId)
      api.get(`/boq/${boqId}`)
        .then((r) => setBoq(r.data));

    else
      api.get("/boq")
        .then((r) => setList(r.data));

  }, [boqId]);

  if (!boqId) {
    return (
      <div className="space-y-6 ss-fade-in">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Bills of Quantity</h1>
          <p className="text-sm text-gray-500 mt-1">All BOQs generated for your projects.</p>
        </div>
        {list.length === 0 ? (
          <EmptyState icon={FileText} title="No BOQs yet" description="Generate a BOQ from any estimate." />
        ) : (
          <div className="ss-card p-5 overflow-x-auto">
            <table className="ss-table">
              <thead><tr><th>Name</th><th>Built-up</th><th>Sections</th><th>Created</th><th className="text-right">Total</th></tr></thead>
              <tbody>
                {list.map((b) => (
                  <tr key={b.id} onClick={() => nav(`/app/boq/${b.id}`)} className="cursor-pointer" data-testid={`boq-row-${b.id}`}>
                    <td className="font-semibold">{b.name}</td>
                    <td>{b.builtup_sqft} sqft</td>
                    <td>{b.sections.length}</td>
                    <td className="text-gray-500">{fmtDate(b.created_at)}</td>
                    <td className="text-right font-bold">{inr(b.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    );
  }

  if (!boq) return <div className="p-10 text-center text-gray-500">Loading…</div>;

  return (
    <div className="space-y-6 ss-fade-in print:p-6">
      <button onClick={() => nav(-1)} className="text-sm text-gray-500 hover:text-[#171717] flex items-center gap-1 print:hidden"><ArrowLeft className="h-4 w-4" /> Back</button>
      <div className="ss-card p-6">
        {branding && (

          <div className="
flex
justify-between
items-start
border-b
pb-4
mb-6
">

            <div className="flex gap-4">

              {branding.logo_url && (

                <img
                  src={branding.logo_url}
                  alt="logo"
                  className="h-20 w-20 object-contain"
                />

              )}

              <div>

                <h2 className="
      text-2xl
      font-bold
      ">
                  {branding.company_name}
                </h2>

                <p>
                  GST:
                  {branding.gst_number}
                </p>

                <p>
                  {branding.phone}
                </p>

                <p>
                  {branding.email}
                </p>

                <p>
                  {branding.company_address}
                </p>

              </div>

            </div>

          </div>

        )}
        <div className="flex flex-wrap items-center justify-between gap-4 mb-4">
          <div>
            <h1 className="font-display text-2xl font-extrabold">{boq.name}</h1>
            <p className="text-sm text-gray-500">Built-up area: {boq.builtup_sqft} sqft · Generated {fmtDate(boq.created_at)}</p>
          </div>
          <div className="flex gap-2 print:hidden">
            <button onClick={() => window.print()} className="ss-btn-outline" data-testid="boq-print"><Printer className="h-4 w-4" /> Print / PDF</button>
          </div>
        </div>

        {boq.sections.map((sec, i) => (
          <div key={i} className="mt-6">
            <div className="flex items-center justify-between border-b border-gray-200 pb-2 mb-2">
              <h3 className="font-display font-bold text-lg">{i + 1}. {sec.name}</h3>
              <span className="text-sm font-bold text-[#F97316]">{inr(sec.subtotal)}</span>
            </div>
            <table className="ss-table">
              <thead><tr><th>Description</th><th>Unit</th><th className="text-right">Qty</th><th className="text-right">Rate</th><th className="text-right">Amount</th></tr></thead>
              <tbody>
                {sec.items.map((it, j) => (
                  <tr key={j}>
                    <td>{it.desc}</td>
                    <td className="text-gray-500">{it.unit}</td>
                    <td className="text-right">{it.qty}</td>
                    <td className="text-right">{inr(it.rate)}</td>
                    <td className="text-right font-semibold">{inr(it.amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ))}

        <div className="mt-6 border-t-2 border-[#171717] pt-4 flex items-center justify-between">
          <div className="font-display text-xl font-bold">Grand Total</div>
          <div
            className="
mt-10
text-center
text-sm
text-gray-500
"
          >

            Generated By

            <br />

            {branding?.company_name}

            <br />

            Powered By SiteSevaPro

          </div>
          <div className="font-display text-2xl font-extrabold text-[#F97316]">{inr(boq.total)}</div>
        </div>
      </div>
    </div>
  );
}
