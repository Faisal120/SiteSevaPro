import React, { useEffect, useState } from "react";
import { MessageCircle, RefreshCw, Search, ShieldCheck, UserPlus } from "lucide-react";
import { toast } from "sonner";

import { api } from "@/lib/api";


const deliveryStyle = {
  ACCEPTED: "bg-emerald-500/15 text-emerald-300",
  SENT: "bg-emerald-500/15 text-emerald-300",
  DELIVERED: "bg-emerald-500/15 text-emerald-300",
  READ: "bg-emerald-500/15 text-emerald-300",
  FAILED: "bg-red-500/15 text-red-300",
  NOT_CONFIGURED: "bg-amber-500/15 text-amber-300",
  NO_PHONE: "bg-red-500/15 text-red-300",
};

export default function TeamManagement() {
  const [members, setMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [busyId, setBusyId] = useState(null);
  const [form, setForm] = useState({ full_name: "", email: "", phone: "", role: "SUPERVISOR" });

  const loadTeam = async () => {
    try {
      const response = await api.get("/team");
      setMembers(response.data || []);
    } catch {
      toast.error("Failed to load team");
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => { loadTeam(); }, []);

  const createMember = async () => {
    if (!form.full_name || !form.email || !form.phone) return toast.error("Enter name, email and WhatsApp number");
    setBusyId("CREATE");
    try {
      const { data } = await api.post("/team", form);
      const status = data.whatsapp_delivery?.status;
      if (["ACCEPTED", "SENT", "DELIVERED", "READ"].includes(status)) toast.success("Member created and credentials sent on WhatsApp");
      else toast.warning(`Member created; WhatsApp status: ${status || "UNKNOWN"}`);
      setForm({ full_name: "", email: "", phone: "", role: "SUPERVISOR" });
      loadTeam();
    } catch (error) {
      toast.error(error?.response?.data?.detail || "Creation failed");
    } finally {
      setBusyId(null);
    }
  };

  const toggleMember = async (id, blocked) => {
    setBusyId(id);
    try {
      await api.patch(`/team/${id}?blocked=${!blocked}`);
      toast.success(blocked ? "Member unblocked" : "Member blocked");
      loadTeam();
    } catch {
      toast.error("Unable to update member");
    } finally { setBusyId(null); }
  };

  const resend = async (id) => {
    if (!window.confirm("Generate a new temporary password and send it on WhatsApp? Existing sessions will be signed out.")) return;
    setBusyId(id);
    try {
      const { data } = await api.post(`/team/${id}/resend-credentials`);
      const status = data.whatsapp_delivery?.status;
      if (["ACCEPTED", "SENT", "DELIVERED", "READ"].includes(status)) toast.success("New credentials accepted by WhatsApp");
      else toast.warning(`Credentials regenerated; WhatsApp status: ${status || "UNKNOWN"}`);
      loadTeam();
    } catch (error) {
      toast.error(error?.response?.data?.detail || "Unable to resend credentials");
    } finally { setBusyId(null); }
  };

  const removeMember = async (id) => {
    if (!window.confirm("Remove this member from the workspace? Their account will be archived and blocked.")) return;
    setBusyId(id);
    try {
      await api.delete(`/team/${id}`);
      toast.success("Member archived");
      loadTeam();
    } catch { toast.error("Remove failed"); }
    finally { setBusyId(null); }
  };

  const filtered = members.filter((member) => `${member.full_name || ""} ${member.email || ""} ${member.phone || ""} ${member.role || ""}`.toLowerCase().includes(search.toLowerCase()));
  const supervisors = members.filter((member) => member.role === "SUPERVISOR").length;
  const clients = members.filter((member) => member.role === "CLIENT").length;

  return <div className="space-y-6 ss-fade-in">
    <section className="rounded-2xl border border-[#30323a] bg-[#111214] p-6 sm:p-8"><div className="flex flex-col justify-between gap-6 lg:flex-row lg:items-end"><div><p className="text-xs font-bold uppercase tracking-[.18em] text-blue-300">Workspace access</p><h1 className="mt-2 font-display text-3xl font-extrabold text-white">Team management</h1><p className="mt-2 text-sm text-slate-400">Create supervisor and client accounts with one-time WhatsApp credentials.</p></div><div className="grid grid-cols-3 gap-3">{[["Members", members.length], ["Supervisors", supervisors], ["Clients", clients]].map(([label, value]) => <div key={label} className="rounded-xl border border-[#30323a] bg-[#17191d] px-4 py-3"><p className="text-xs text-slate-400">{label}</p><b className="mt-1 block text-xl text-white">{value}</b></div>)}</div></div></section>

    <section className="rounded-2xl border border-[#30323a] bg-[#111214] p-6"><div className="mb-5 flex items-center gap-2"><UserPlus className="h-5 w-5 text-blue-300"/><div><h2 className="font-display text-lg font-bold text-white">Add a team member</h2><p className="text-sm text-slate-400">They must change the temporary password on first login.</p></div></div><div className="grid gap-3 xl:grid-cols-[1fr_1fr_1fr_170px_auto]"><input className="ss-input" placeholder="Full name" value={form.full_name} onChange={(event) => setForm({ ...form, full_name: event.target.value })}/><input className="ss-input" type="email" placeholder="Email address" value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })}/><input className="ss-input" type="tel" placeholder="WhatsApp +91…" value={form.phone} onChange={(event) => setForm({ ...form, phone: event.target.value })}/><select className="ss-input" value={form.role} onChange={(event) => setForm({ ...form, role: event.target.value })}><option value="SUPERVISOR">Supervisor</option><option value="CLIENT">Client</option></select><button disabled={busyId === "CREATE"} className="rounded-lg bg-blue-500 px-5 py-3 text-sm font-semibold text-white hover:bg-blue-600 disabled:opacity-50" onClick={createMember}>{busyId === "CREATE" ? "Creating…" : "Create & send"}</button></div></section>

    <section className="overflow-hidden rounded-2xl border border-[#30323a] bg-[#111214]"><div className="flex flex-col justify-between gap-4 border-b border-[#30323a] p-5 sm:flex-row sm:items-center"><div><h2 className="font-display text-lg font-bold text-white">Your team</h2><p className="text-sm text-slate-400">Account access and credential delivery status.</p></div><label className="relative block"><Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500"/><input className="ss-input w-full pl-9 sm:w-72" placeholder="Search team" value={search} onChange={(event) => setSearch(event.target.value)}/></label></div><div className="overflow-x-auto"><table className="w-full min-w-[940px] text-sm"><thead className="bg-[#17191d] text-left text-xs uppercase tracking-[.12em] text-slate-400"><tr><th className="px-5 py-4">Member</th><th className="px-5 py-4">Role</th><th className="px-5 py-4">WhatsApp</th><th className="px-5 py-4">Status</th><th className="px-5 py-4 text-right">Actions</th></tr></thead><tbody>{loading ? <tr><td colSpan="5" className="p-8 text-center text-slate-400">Loading team…</td></tr> : filtered.length ? filtered.map((member) => <tr key={member.id} className="border-t border-[#25272c]"><td className="px-5 py-4"><div className="flex items-center gap-3"><span className="grid h-9 w-9 place-items-center rounded-full bg-blue-500/15 font-semibold text-blue-200">{member.full_name?.slice(0, 1)?.toUpperCase() || "U"}</span><div><b className="text-white">{member.full_name}</b><p className="mt-0.5 text-xs text-slate-400">{member.email}</p></div></div></td><td className="px-5 py-4"><span className="rounded-full bg-white/5 px-2.5 py-1 text-xs font-semibold text-slate-300">{member.role}</span></td><td className="px-5 py-4"><p className="flex items-center gap-1.5 text-slate-300"><MessageCircle className="h-3.5 w-3.5 text-emerald-300"/>{member.phone || member.whatsapp || "—"}</p><span className={`mt-1.5 inline-flex rounded-full px-2 py-1 text-[10px] font-bold ${deliveryStyle[member.credential_delivery_status] || "bg-white/5 text-slate-400"}`}>{member.credential_delivery_status || "NOT SENT"}</span></td><td className="px-5 py-4"><span className={member.blocked ? "text-red-300" : "inline-flex items-center gap-1 text-emerald-300"}>{!member.blocked && <ShieldCheck className="h-4 w-4"/>}{member.blocked ? "Blocked" : "Active"}</span>{member.must_change_password && <p className="mt-1 text-[11px] text-amber-300">Password change pending</p>}</td><td className="px-5 py-4 text-right"><div className="flex justify-end gap-3"><button disabled={busyId === member.id} className="inline-flex items-center gap-1 font-semibold text-emerald-300 hover:text-white disabled:opacity-40" onClick={() => resend(member.id)}><RefreshCw className="h-3.5 w-3.5"/>Resend</button><button disabled={busyId === member.id} className="font-semibold text-blue-300 hover:text-white disabled:opacity-40" onClick={() => toggleMember(member.id, member.blocked)}>{member.blocked ? "Unblock" : "Block"}</button><button disabled={busyId === member.id} className="font-semibold text-red-300 hover:text-red-200 disabled:opacity-40" onClick={() => removeMember(member.id)}>Remove</button></div></td></tr>) : <tr><td colSpan="5" className="p-8 text-center text-slate-400">No team members found.</td></tr>}</tbody></table></div></section>
  </div>;
}
