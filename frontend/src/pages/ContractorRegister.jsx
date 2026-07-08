import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { HardHat, CheckCircle2, Send } from "lucide-react";
import { api } from "@/lib/api";
import { toast } from "sonner";

export default function ContractorRegister() {
  const nav = useNavigate();
  const [form, setForm] = React.useState({
    company_name: "", owner_name: "", mobile: "", email: "", gst_number: "",
    office_address: "", city: "", state: "", active_projects: 0, employee_count: 0,
  });
  const [busy, setBusy] = React.useState(false);
  const [done, setDone] = React.useState(false);

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    try {
      await api.post("/auth/applications", {
        ...form,
        active_projects: Number(form.active_projects || 0),
        employee_count: Number(form.employee_count || 0),
      });
      setDone(true);
      toast.success("Application submitted!");
    } catch (err) {
      toast.error(err?.response?.data?.detail || "Failed to submit");
    } finally {
      setBusy(false);
    }
  };

  if (done) {
    return (
      <div className="min-h-screen ss-mesh flex items-center justify-center p-6">
        <div className="ss-card p-10 max-w-lg text-center">
          <div className="h-14 w-14 mx-auto rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center">
            <CheckCircle2 className="h-7 w-7" />
          </div>
          <h2 className="mt-4 font-display text-2xl font-extrabold">Application Received</h2>
          <p className="mt-2 text-gray-600">Our admin team will review your application and email you your login credentials within 24 hours.</p>
          <Link to="/" className="ss-btn-ink mt-6 inline-flex">Back to Home</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen ss-mesh py-10">
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <Link to="/" className="flex items-center gap-2 mb-6">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#171717] text-[#F97316]"><HardHat className="h-5 w-5" /></div>
          <span className="font-display text-lg font-extrabold">Site Seva <span className="text-[#F97316]">Pro</span></span>
        </Link>
        <h1 className="font-display text-3xl sm:text-4xl font-extrabold tracking-tight">Contractor Registration</h1>
        <p className="mt-2 text-gray-600">Fill the form below. Our admin reviews and emails you your credentials.</p>

        <form onSubmit={submit} className="mt-8 ss-card p-6 grid gap-5 md:grid-cols-2" data-testid="register-form">
          {[
            ["company_name", "Company Name", "text"],
            ["owner_name", "Owner Name", "text"],
            ["mobile", "Mobile Number", "tel"],
            ["email", "Email", "email"],
            ["gst_number", "GST Number (optional)", "text"],
            ["office_address", "Office Address", "text"],
            ["city", "City", "text"],
            ["state", "State", "text"],
            ["active_projects", "Active Projects", "number"],
            ["employee_count", "Employee Count", "number"],
          ].map(([k, lbl, t]) => (
            <div key={k} className={k === "office_address" ? "md:col-span-2" : ""}>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500">{lbl}</label>
              <input
                className="ss-input mt-1"
                type={t}
                value={form[k]}
                onChange={set(k)}
                required={!["gst_number", "active_projects", "employee_count"].includes(k)}
                data-testid={`register-${k}`}
              />
            </div>
          ))}
          <div className="md:col-span-2 flex flex-wrap gap-3 pt-2 border-t border-gray-100">
            <button type="submit" disabled={busy} className="ss-btn-accent" data-testid="register-submit">
              <Send className="h-4 w-4" /> {busy ? "Submitting…" : "Submit Application"}
            </button>
            <Link to="/login" className="ss-btn-outline">Already have credentials? Sign in</Link>
          </div>
        </form>
      </div>
    </div>
  );
}
