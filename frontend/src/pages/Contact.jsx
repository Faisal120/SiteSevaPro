import React from "react";
import PublicNav from "@/components/PublicNav";
import PublicFooter from "@/components/PublicFooter";
import { Mail, Send } from "lucide-react";
import { toast } from "sonner";
import { api } from "@/lib/api";

export default function Contact() {
  const [form, setForm] = React.useState({ name: "", email: "", message: "" });
  const [submitting, setSubmitting] = React.useState(false);
  const submit = async (e) => {
    e.preventDefault();
    if (!form.name || !form.email || !form.message) return toast.error("Please fill all fields");
    setSubmitting(true);
    try { await api.post("/public/enquiries", form); toast.success("Thanks! We'll get back to you within 24 hours."); setForm({ name: "", email: "", message: "" }); }
    catch (error) { toast.error(error?.response?.data?.detail || "We could not send your enquiry. Please try again or email support."); }
    finally { setSubmitting(false); }
  };
  return (
    <div className="landing-shell min-h-screen ss-mesh">
      <PublicNav />
      <section className="py-16 lg:py-24">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 grid lg:grid-cols-2 gap-10">
          <div>
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#3B82F6]">Contact</span>
            <h1 className="mt-2 text-4xl sm:text-5xl font-extrabold font-display tracking-tight">Talk to our team.</h1>
            <p className="mt-4 text-gray-600">Questions about pricing, demo, or onboarding your sites? We're here.</p>
            <div className="mt-8 space-y-4 text-sm">
              <a href="mailto:support@sitesevapro.in" className="flex items-center gap-3 text-slate-200 hover:text-blue-300"><Mail className="h-4 w-4 text-[#3B82F6]" /> support@sitesevapro.in</a>
              <a href="mailto:info@sitesevapro.in" className="flex items-center gap-3 text-slate-200 hover:text-blue-300"><Mail className="h-4 w-4 text-[#3B82F6]" /> info@sitesevapro.in</a>
            </div>
          </div>
          <form onSubmit={submit} className="ss-card p-6 space-y-4" data-testid="contact-form">
            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Name</label>
              <input className="ss-input mt-1" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} data-testid="contact-name" />
            </div>
            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Email</label>
              <input className="ss-input mt-1" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} data-testid="contact-email" />
            </div>
            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Message</label>
              <textarea className="ss-input mt-1 min-h-[120px]" value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })} data-testid="contact-message" />
            </div>
            <button type="submit" disabled={submitting} className="ss-btn-accent w-full disabled:opacity-50" data-testid="contact-submit">
              <Send className="h-4 w-4" /> {submitting ? "Sending…" : "Send Message"}
            </button>
          </form>
        </div>
      </section>
      <PublicFooter />
    </div>
  );
}
