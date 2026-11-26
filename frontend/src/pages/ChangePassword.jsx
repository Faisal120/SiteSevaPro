import React from "react";
import { HardHat, KeyRound, LogOut } from "lucide-react";
import { toast } from "sonner";

import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";


export default function ChangePassword() {
  const { user, logout } = useAuth();
  const [currentPassword, setCurrentPassword] = React.useState("");
  const [newPassword, setNewPassword] = React.useState("");
  const [confirmPassword, setConfirmPassword] = React.useState("");
  const [busy, setBusy] = React.useState(false);

  const submit = async (event) => {
    event.preventDefault();
    if (newPassword !== confirmPassword) return toast.error("Passwords do not match");
    setBusy(true);
    try {
      await api.patch("/auth/password", {
        current_password: currentPassword,
        new_password: newPassword,
      });
      toast.success("Password changed. Please sign in again.");
      logout();
      window.location.assign("/login");
    } catch (error) {
      toast.error(error?.response?.data?.detail || "Unable to change password");
    } finally {
      setBusy(false);
    }
  };

  return <div className="min-h-screen ss-mesh flex items-center justify-center p-6">
    <div className="w-full max-w-md ss-card p-7 sm:p-9">
      <div className="flex items-center gap-3"><div className="grid h-11 w-11 place-items-center rounded-xl bg-[#171717] text-blue-400"><HardHat className="h-5 w-5"/></div><div><p className="text-xs font-bold uppercase tracking-[.16em] text-blue-500">SiteSeva Pro</p><p className="text-sm text-gray-500">{user?.email}</p></div></div>
      <div className="mt-8 grid h-12 w-12 place-items-center rounded-xl bg-amber-500/10 text-amber-500"><KeyRound/></div>
      <h1 className="mt-4 font-display text-3xl font-extrabold">Update your password</h1>
      <p className="mt-2 text-sm leading-6 text-gray-500">Enter your current password and choose a new secure password. First-time account setup uses the separate WhatsApp OTP flow.</p>
      <form onSubmit={submit} className="mt-7 space-y-4">
        <PasswordField label="Current password" value={currentPassword} setValue={setCurrentPassword}/>
        <PasswordField label="New password" value={newPassword} setValue={setNewPassword}/>
        <PasswordField label="Confirm new password" value={confirmPassword} setValue={setConfirmPassword}/>
        <p className="text-xs leading-5 text-gray-500">Minimum 12 characters, including uppercase, lowercase, number and special character.</p>
        <button className="ss-btn-accent w-full" disabled={busy}>{busy ? "Saving…" : "Set password and continue"}</button>
      </form>
      <button onClick={logout} className="mt-5 flex w-full items-center justify-center gap-2 text-sm font-semibold text-gray-500 hover:text-red-500"><LogOut className="h-4 w-4"/>Sign out</button>
    </div>
  </div>;
}

function PasswordField({ label, value, setValue }) {
  return <label className="block"><span className="text-xs font-bold uppercase tracking-wider text-gray-500">{label}</span><input className="ss-input mt-1" type="password" minLength="8" value={value} onChange={(event) => setValue(event.target.value)} required /></label>;
}
