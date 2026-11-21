import React from "react";
import { CheckCircle2, KeyRound, LockKeyhole, ShieldCheck, Smartphone } from "lucide-react";
import { toast } from "sonner";

import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";


export default function Security() {
  const { user, logout } = useAuth();
  const [alerts, setAlerts] = React.useState(() => localStorage.getItem("ss_security_alerts") !== "off");
  const [form, setForm] = React.useState({ current_password: "", new_password: "", confirm_password: "" });
  const [busy, setBusy] = React.useState(false);
  const toggleAlerts = () => { const next = !alerts; setAlerts(next); localStorage.setItem("ss_security_alerts", next ? "on" : "off"); };
  const changePassword = async (event) => {
    event.preventDefault();
    if (form.new_password !== form.confirm_password) return toast.error("Passwords do not match");
    setBusy(true);
    try {
      await api.patch("/auth/password", { current_password: form.current_password, new_password: form.new_password });
      toast.success("Password updated. Sign in again with the new password.");
      logout();
      window.location.assign("/login");
    } catch (error) { toast.error(error?.response?.data?.detail || "Unable to change password"); }
    finally { setBusy(false); }
  };

  return <div className="mx-auto max-w-5xl space-y-6 ss-fade-in">
    <section className="rounded-2xl border border-[#30323a] bg-[#111214] p-7 sm:p-9"><div className="flex items-start gap-4"><div className="grid h-12 w-12 place-items-center rounded-xl bg-emerald-400/10 text-emerald-300"><ShieldCheck/></div><div><p className="text-xs font-bold uppercase tracking-[.18em] text-emerald-300">Account protection</p><h1 className="mt-2 font-display text-3xl font-extrabold text-white">Security centre</h1><p className="mt-3 text-sm text-slate-400">Manage your password and security preferences.</p></div></div></section>
    <section className="overflow-hidden rounded-2xl border border-[#30323a] bg-[#111214]"><SecurityRow icon={LockKeyhole} title="Authenticated workspace" copy={`Signed in as ${user?.email || "your account"}. Access is restricted by your assigned role.`} status="Active"/><SecurityRow icon={Smartphone} title="Security alerts" copy="Keep important account access notifications enabled." control={<button onClick={toggleAlerts} className={`rounded-full px-3 py-1.5 text-xs font-bold ${alerts ? "bg-emerald-400/15 text-emerald-300" : "bg-white/10 text-slate-300"}`}>{alerts ? "Enabled" : "Disabled"}</button>}/></section>
    <section className="rounded-2xl border border-[#30323a] bg-[#111214] p-6"><div className="flex items-start gap-3"><div className="grid h-10 w-10 place-items-center rounded-xl bg-blue-500/10 text-blue-300"><KeyRound className="h-5 w-5"/></div><div><h2 className="font-semibold text-white">Change password</h2><p className="mt-1 text-sm text-slate-400">Changing your password signs out all existing sessions.</p></div></div><form onSubmit={changePassword} className="mt-6 grid gap-4 md:grid-cols-3"><PasswordInput label="Current password" value={form.current_password} setValue={(value) => setForm({ ...form, current_password: value })}/><PasswordInput label="New password" value={form.new_password} setValue={(value) => setForm({ ...form, new_password: value })}/><PasswordInput label="Confirm password" value={form.confirm_password} setValue={(value) => setForm({ ...form, confirm_password: value })}/><div className="md:col-span-3 flex flex-wrap items-center justify-between gap-3"><p className="text-xs text-slate-500">12+ characters with uppercase, lowercase, number and special character.</p><button disabled={busy} className="rounded-lg bg-blue-500 px-5 py-2.5 text-sm font-semibold text-white disabled:opacity-50">{busy ? "Updating…" : "Update password"}</button></div></form></section>
    <p className="text-center text-xs text-slate-500"><CheckCircle2 className="mr-1 inline h-3.5 w-3.5 text-emerald-300"/>Role-based access is applied to contractor, supervisor, client and admin accounts.</p>
  </div>;
}

function PasswordInput({ label, value, setValue }) { return <label><span className="text-xs font-bold uppercase tracking-wider text-slate-500">{label}</span><input className="ss-input mt-1" type="password" value={value} onChange={(event) => setValue(event.target.value)} minLength="8" required/></label>; }
function SecurityRow({ icon: Icon, title, copy, status, control }) { return <div className="flex flex-col gap-4 border-b border-[#30323a] p-6 last:border-0 sm:flex-row sm:items-center"><div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-blue-500/10 text-blue-300"><Icon className="h-5 w-5"/></div><div className="flex-1"><h2 className="font-semibold text-white">{title}</h2><p className="mt-1 text-sm leading-6 text-slate-400">{copy}</p></div>{control || <span className="rounded-full bg-emerald-400/15 px-3 py-1.5 text-xs font-bold text-emerald-300">{status}</span>}</div>; }
