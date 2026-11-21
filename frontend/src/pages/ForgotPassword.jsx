import React from "react";
import { ArrowLeft, KeyRound, MessageCircle } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "sonner";

import { api } from "@/lib/api";


export default function ForgotPassword() {
  const navigate = useNavigate();
  const [identifier, setIdentifier] = React.useState("");
  const [code, setCode] = React.useState("");
  const [newPassword, setNewPassword] = React.useState("");
  const [confirmPassword, setConfirmPassword] = React.useState("");
  const [step, setStep] = React.useState("REQUEST");
  const [busy, setBusy] = React.useState(false);

  const requestCode = async (event) => {
    event.preventDefault();
    setBusy(true);
    try {
      const { data } = await api.post("/auth/password/forgot", { identifier });
      toast.success(data.message);
      setStep("RESET");
    } catch (error) {
      toast.error(error?.response?.data?.detail || "Unable to start password recovery");
    } finally {
      setBusy(false);
    }
  };

  const resetPassword = async (event) => {
    event.preventDefault();
    if (newPassword !== confirmPassword) return toast.error("Passwords do not match");
    setBusy(true);
    try {
      const { data } = await api.post("/auth/password/reset", {
        identifier,
        code,
        new_password: newPassword,
      });
      toast.success(data.message);
      navigate("/login", { replace: true });
    } catch (error) {
      toast.error(error?.response?.data?.detail || "Unable to reset password");
    } finally {
      setBusy(false);
    }
  };

  return <div className="min-h-screen ss-mesh flex items-center justify-center p-6">
    <div className="w-full max-w-md ss-card p-7 sm:p-9">
      <Link to="/login" className="inline-flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-blue-500"><ArrowLeft className="h-4 w-4"/>Back to sign in</Link>
      <div className="mt-7 grid h-12 w-12 place-items-center rounded-xl bg-blue-500/10 text-blue-400">{step === "REQUEST" ? <MessageCircle/> : <KeyRound/>}</div>
      <h1 className="mt-4 font-display text-3xl font-extrabold">{step === "REQUEST" ? "Forgot password?" : "Enter reset code"}</h1>
      <p className="mt-2 text-sm leading-6 text-gray-500">{step === "REQUEST" ? "We will send a six-digit recovery code to the WhatsApp number registered with your account." : `Enter the code sent for ${identifier}. It expires in 10 minutes.`}</p>

      {step === "REQUEST" ? <form onSubmit={requestCode} className="mt-7 space-y-4">
        <label className="block"><span className="text-xs font-bold uppercase tracking-wider text-gray-500">Email, username or mobile</span><input className="ss-input mt-1" value={identifier} onChange={(event) => setIdentifier(event.target.value)} required autoFocus /></label>
        <button className="ss-btn-accent w-full" disabled={busy}>{busy ? "Sending…" : "Send WhatsApp code"}</button>
      </form> : <form onSubmit={resetPassword} className="mt-7 space-y-4">
        <label className="block"><span className="text-xs font-bold uppercase tracking-wider text-gray-500">6-digit code</span><input className="ss-input mt-1 font-mono tracking-[.35em]" inputMode="numeric" pattern="[0-9]{6}" maxLength="6" value={code} onChange={(event) => setCode(event.target.value.replace(/\D/g, ""))} required autoFocus /></label>
        <label className="block"><span className="text-xs font-bold uppercase tracking-wider text-gray-500">New password</span><input className="ss-input mt-1" type="password" minLength="12" value={newPassword} onChange={(event) => setNewPassword(event.target.value)} required /></label>
        <label className="block"><span className="text-xs font-bold uppercase tracking-wider text-gray-500">Confirm password</span><input className="ss-input mt-1" type="password" minLength="12" value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} required /></label>
        <p className="text-xs leading-5 text-gray-500">Use 12+ characters with uppercase, lowercase, number and special character.</p>
        <button className="ss-btn-accent w-full" disabled={busy}>{busy ? "Updating…" : "Reset password"}</button>
        <button type="button" onClick={() => setStep("REQUEST")} className="w-full text-sm font-semibold text-blue-500">Send a new code</button>
      </form>}
    </div>
  </div>;
}
