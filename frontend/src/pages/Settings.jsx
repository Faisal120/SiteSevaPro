import React from "react";
import { useAuth } from "@/lib/auth";
import { Link } from "react-router-dom";
import { User, Shield, Mail, Building, Bell, Palette, ShieldCheck } from "lucide-react";
import { useTheme } from "@/lib/theme";

export default function Settings() {
  const { user } = useAuth();
  const { theme, toggle } = useTheme();
  const [digest, setDigest] = React.useState(() => localStorage.getItem("ss_daily_digest") !== "off");
  const setDailyDigest = () => { const next = !digest; setDigest(next); localStorage.setItem("ss_daily_digest", next ? "on" : "off"); };
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Settings</h1>
        <p className="text-sm text-gray-500 mt-1">Your profile and account details.</p>
      </div>
      <div className="ss-card p-6 grid md:grid-cols-2 gap-6">
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Full Name</div>
          <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><User className="h-4 w-4 text-[#3B82F6]" /> {user.full_name}</div>
        </div>
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Email</div>
          <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><Mail className="h-4 w-4 text-[#3B82F6]" /> {user.email}</div>
        </div>
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Role</div>
          <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><Shield className="h-4 w-4 text-[#3B82F6]" /> {user.role.replace("_", " ")}</div>
        </div>
        {user.company_name && (
          <div>
            <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Company</div>
            <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><Building className="h-4 w-4 text-[#3B82F6]" /> {user.company_name}</div>
          </div>
        )}
        {user.username && (
          <div>
            <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Username</div>
            <div className="mt-1 font-mono text-sm bg-gray-100 px-3 py-1.5 rounded inline-block">{user.username}</div>
          </div>
        )}
      </div>
      <div className="grid gap-6 md:grid-cols-2">
        <section className="ss-card p-6"><div className="flex items-start gap-3"><div className="rounded-xl bg-blue-500/10 p-2.5 text-blue-300"><Palette className="h-5 w-5"/></div><div><h2 className="font-display text-lg font-bold">Appearance</h2><p className="mt-1 text-sm text-gray-500">Choose the workspace contrast that suits your environment.</p></div></div><button onClick={toggle} className="ss-btn-outline mt-5">{theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}</button></section>
        <section className="ss-card p-6"><div className="flex items-start gap-3"><div className="rounded-xl bg-blue-500/10 p-2.5 text-blue-300"><Bell className="h-5 w-5"/></div><div><h2 className="font-display text-lg font-bold">Daily operations digest</h2><p className="mt-1 text-sm text-gray-500">Keep a preference for a daily site activity summary.</p></div></div><button onClick={setDailyDigest} className="ss-btn-outline mt-5">{digest ? "Digest enabled" : "Enable digest"}</button></section>
      </div>
      <section className="ss-card p-6"><div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-center"><div><h2 className="font-display text-lg font-bold">Workspace administration</h2><p className="mt-1 text-sm text-gray-500">Update your company identity and review account protection.</p></div><div className="flex flex-wrap gap-3"><Link className="ss-btn-outline" to="/app/branding">Company branding</Link><Link className="ss-btn-outline" to="/app/security"><ShieldCheck className="h-4 w-4"/>Security centre</Link></div></div></section>
    </div>
  );
}
