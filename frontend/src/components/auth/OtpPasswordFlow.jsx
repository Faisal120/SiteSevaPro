import React from "react";
import { ArrowLeft, CheckCircle2, Eye, EyeOff, KeyRound, LoaderCircle, MessageCircle, RefreshCw, ShieldCheck } from "lucide-react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { toast } from "sonner";

import { api } from "@/lib/api";
import OtpCodeInput from "@/components/auth/OtpCodeInput";

const PASSWORD_REQUIREMENTS = [
  ["12+ characters", (password) => password.length >= 12],
  ["uppercase letter", (password) => /[A-Z]/.test(password)],
  ["lowercase letter", (password) => /[a-z]/.test(password)],
  ["number", (password) => /\d/.test(password)],
  ["special character", (password) => /[^A-Za-z0-9]/.test(password)],
];

function errorDetails(error, fallback) {
  if (!error?.response) return "We could not reach the server. Check your connection and try again.";
  const detail = error.response.data?.detail;
  if (detail && typeof detail === "object") return detail.message || detail.status || fallback;
  return detail || fallback;
}

function retryAfter(error) {
  const value = Number(error?.response?.headers?.["retry-after"]);
  return Number.isFinite(value) && value > 0 ? Math.ceil(value) : 60;
}

function PasswordField({ id, label, value, onChange, show, setShow, autoComplete }) {
  return <label className="block" htmlFor={id}>
    <span className="text-xs font-bold uppercase tracking-wider text-gray-500">{label}</span>
    <div className="relative mt-1">
      <input
        autoComplete={autoComplete}
        className="ss-input pr-11"
        id={id}
        minLength="12"
        onChange={(event) => onChange(event.target.value)}
        required
        type={show ? "text" : "password"}
        value={value}
      />
      <button
        aria-label={`${show ? "Hide" : "Show"} ${label.toLowerCase()}`}
        className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-[#3B82F6]"
        onClick={() => setShow((current) => !current)}
        type="button"
      >
        {show ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
      </button>
    </div>
  </label>;
}

/** Public activation/reset UI using only the FastAPI OTP contract. */
export default function OtpPasswordFlow({ purpose }) {
  const navigate = useNavigate();
  const location = useLocation();
  const isActivation = purpose === "activation";
  const copy = isActivation ? {
    requestPath: "/auth/activation/request-otp",
    verifyPath: "/auth/activation/verify-otp",
    passwordPath: "/auth/activation/set-password",
    requestHeading: "Create your password",
    requestDescription: "Enter the email address or Login ID registered with SiteSeva Pro. If the account is eligible, a one-time code will be sent to its registered WhatsApp number.",
    verifyHeading: "Verify your WhatsApp code",
    passwordHeading: "Choose a secure password",
    completeHeading: "Password created",
    completeDescription: "Your SiteSeva Pro account is ready. Sign in with the password you just created.",
    submitRequest: "Send verification code",
    submitPassword: "Create password",
    loginLink: "Back to sign in",
  } : {
    requestPath: "/auth/password/forgot",
    verifyPath: "/auth/password/reset/verify-otp",
    passwordPath: "/auth/password/reset/set-password",
    requestHeading: "Forgot password?",
    requestDescription: "Enter the email address or Login ID registered with SiteSeva Pro. If the account is eligible, a one-time code will be sent to its registered WhatsApp number.",
    verifyHeading: "Verify your WhatsApp code",
    passwordHeading: "Set a new password",
    completeHeading: "Password reset",
    completeDescription: "Your password has been updated. Sign in with your new password.",
    submitRequest: "Send reset code",
    submitPassword: "Reset password",
    loginLink: "Back to sign in",
  };

  const [identifier, setIdentifier] = React.useState(() => location.state?.identifier || "");
  const [code, setCode] = React.useState("");
  const [step, setStep] = React.useState("REQUEST");
  const [busy, setBusy] = React.useState(false);
  const [resendIn, setResendIn] = React.useState(0);
  const [authorizationToken, setAuthorizationToken] = React.useState("");
  const [authorizationExpiresIn, setAuthorizationExpiresIn] = React.useState(600);
  const [authorizationRemaining, setAuthorizationRemaining] = React.useState(0);
  const [newPassword, setNewPassword] = React.useState("");
  const [confirmPassword, setConfirmPassword] = React.useState("");
  const [showNewPassword, setShowNewPassword] = React.useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = React.useState(false);

  React.useEffect(() => {
    if (!resendIn) return undefined;
    const timer = window.setInterval(() => setResendIn((remaining) => Math.max(remaining - 1, 0)), 1000);
    return () => window.clearInterval(timer);
  }, [resendIn]);

  React.useEffect(() => {
    if (step !== "COMPLETE") return undefined;
    const timer = window.setTimeout(() => navigate("/login", { replace: true }), 2500);
    return () => window.clearTimeout(timer);
  }, [navigate, step]);

  React.useEffect(() => {
    if (step !== "PASSWORD" || authorizationRemaining <= 0) return undefined;
    const timer = window.setInterval(() => {
      setAuthorizationRemaining((remaining) => Math.max(remaining - 1, 0));
    }, 1000);
    return () => window.clearInterval(timer);
  }, [authorizationRemaining, step]);

  const requestOtp = async (event) => {
    event?.preventDefault();
    if (!identifier.trim() || busy) return;
    setBusy(true);
    try {
      const { data } = await api.post(copy.requestPath, { identifier: identifier.trim() });
      if (data?.status === "RATE_LIMITED") {
        setResendIn(60);
        toast.error("Please wait before requesting another code.");
        return;
      }
      setCode("");
      setAuthorizationToken("");
      setStep("VERIFY");
      setResendIn(60);
      toast.success("If the account is eligible, a verification code has been sent to its registered WhatsApp number.");
    } catch (error) {
      if (error?.response?.status === 429) setResendIn(retryAfter(error));
      toast.error(errorDetails(error, "Unable to request a verification code"));
    } finally {
      setBusy(false);
    }
  };

  const verifyOtp = async (event) => {
    event.preventDefault();
    if (code.length !== 6 || busy) return;
    setBusy(true);
    try {
      const { data } = await api.post(copy.verifyPath, { identifier: identifier.trim(), code });
      if (!data?.authorization_token) {
        toast.error("The verification response was incomplete. Request a new code and try again.");
        return;
      }
      setAuthorizationToken(data.authorization_token);
      setAuthorizationExpiresIn(Number(data.expires_in) || 600);
      setAuthorizationRemaining(Number(data.expires_in) || 600);
      setCode("");
      setStep("PASSWORD");
    } catch (error) {
      const message = errorDetails(error, "The code is invalid or expired. Request a new code and try again.");
      toast.error(message);
      if (error?.response?.status === 429) setResendIn(retryAfter(error));
    } finally {
      setBusy(false);
    }
  };

  const savePassword = async (event) => {
    event.preventDefault();
    if (newPassword !== confirmPassword) {
      toast.error("Passwords do not match");
      return;
    }
    if (!PASSWORD_REQUIREMENTS.every(([, valid]) => valid(newPassword))) {
      toast.error("Use a password that meets every requirement below.");
      return;
    }
    if (!authorizationToken || authorizationRemaining <= 0 || busy) {
      toast.error("This authorization has expired. Request a new verification code.");
      setAuthorizationToken("");
      setStep("REQUEST");
      return;
    }
    setBusy(true);
    try {
      await api.post(copy.passwordPath, {
        authorization_token: authorizationToken,
        new_password: newPassword,
        confirm_password: confirmPassword,
      });
      setAuthorizationToken("");
      setNewPassword("");
      setConfirmPassword("");
      setStep("COMPLETE");
      toast.success(isActivation ? "Password created successfully" : "Password reset successfully");
    } catch (error) {
      toast.error(errorDetails(error, "Unable to save your password"));
      if (error?.response?.status === 400 || error?.response?.status === 401 || error?.response?.status === 403) {
        setAuthorizationToken("");
      }
    } finally {
      setBusy(false);
    }
  };

  const passwordChecks = PASSWORD_REQUIREMENTS.map(([label, valid]) => ({ label, valid: valid(newPassword) }));
  const strength = passwordChecks.filter((item) => item.valid).length;

  return <div className="min-h-screen ss-mesh flex items-center justify-center p-6">
    <div className="w-full max-w-md ss-card p-7 sm:p-9">
      <Link to="/login" className="inline-flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-blue-500"><ArrowLeft className="h-4 w-4" />{copy.loginLink}</Link>
      <div className="mt-7 grid h-12 w-12 place-items-center rounded-xl bg-blue-500/10 text-blue-500">
        {step === "COMPLETE" ? <CheckCircle2 /> : step === "VERIFY" ? <MessageCircle /> : <KeyRound />}
      </div>

      {step === "REQUEST" && <>
        <h1 className="mt-4 font-display text-3xl font-extrabold">{copy.requestHeading}</h1>
        <p className="mt-2 text-sm leading-6 text-gray-500">{copy.requestDescription}</p>
        <form className="mt-7 space-y-4" onSubmit={requestOtp}>
          <label className="block" htmlFor="account-identifier"><span className="text-xs font-bold uppercase tracking-wider text-gray-500">Registered email or Login ID</span><input autoComplete="username" autoFocus className="ss-input mt-1" id="account-identifier" maxLength="160" minLength="3" onChange={(event) => setIdentifier(event.target.value)} required value={identifier} /></label>
          <button className="ss-btn-accent w-full" disabled={busy} type="submit">{busy ? <><LoaderCircle className="h-4 w-4 animate-spin" />Sending…</> : copy.submitRequest}</button>
        </form>
      </>}

      {step === "VERIFY" && <>
        <h1 className="mt-4 font-display text-3xl font-extrabold">{copy.verifyHeading}</h1>
        <p className="mt-2 text-sm leading-6 text-gray-500">Enter the six-digit code sent to the WhatsApp number registered for this account. Codes expire in 10 minutes.</p>
        <form className="mt-7 space-y-5" onSubmit={verifyOtp}>
          <OtpCodeInput disabled={busy} onChange={setCode} value={code} />
          <button className="ss-btn-accent w-full" disabled={busy || code.length !== 6} type="submit">{busy ? <><LoaderCircle className="h-4 w-4 animate-spin" />Verifying…</> : "Verify code"}</button>
        </form>
        <div className="mt-5 text-center text-sm text-gray-500">
          {resendIn > 0 ? <span>Resend available in {resendIn}s</span> : <button className="inline-flex items-center gap-1 font-semibold text-blue-500 hover:underline disabled:opacity-60" disabled={busy} onClick={requestOtp} type="button"><RefreshCw className="h-3.5 w-3.5" />Resend code</button>}
        </div>
        <button className="mt-4 w-full text-sm font-semibold text-gray-500 hover:text-blue-500" disabled={busy} onClick={() => { setCode(""); setStep("REQUEST"); }} type="button">Use a different Login ID</button>
      </>}

      {step === "PASSWORD" && <>
        <h1 className="mt-4 font-display text-3xl font-extrabold">{copy.passwordHeading}</h1>
        <p className="mt-2 text-sm leading-6 text-gray-500">This verification is temporary. Complete this step within {Math.ceil(authorizationExpiresIn / 60)} minutes ({Math.max(0, Math.ceil(authorizationRemaining / 60))} minute{Math.ceil(authorizationRemaining / 60) === 1 ? "" : "s"} remaining).</p>
        <form className="mt-7 space-y-4" onSubmit={savePassword}>
          <PasswordField autoComplete="new-password" id="new-password" label="New password" onChange={setNewPassword} setShow={setShowNewPassword} show={showNewPassword} value={newPassword} />
          <PasswordField autoComplete="new-password" id="confirm-password" label="Confirm new password" onChange={setConfirmPassword} setShow={setShowConfirmPassword} show={showConfirmPassword} value={confirmPassword} />
          <div aria-label={`Password strength: ${strength} of ${PASSWORD_REQUIREMENTS.length} requirements met`} className="rounded-lg bg-gray-50 p-3 dark:bg-white/5">
            <div className="mb-2 flex gap-1" aria-hidden>{PASSWORD_REQUIREMENTS.map(([, valid], index) => <span className={`h-1 flex-1 rounded-full ${index < strength ? "bg-emerald-500" : "bg-gray-200 dark:bg-white/10"}`} key={index} />)}</div>
            <ul className="grid grid-cols-1 gap-1 text-xs text-gray-500 sm:grid-cols-2">{passwordChecks.map((item) => <li className={item.valid ? "text-emerald-600 dark:text-emerald-300" : ""} key={item.label}><ShieldCheck className="mr-1 inline h-3 w-3" />{item.label}</li>)}</ul>
          </div>
          <button className="ss-btn-accent w-full" disabled={busy} type="submit">{busy ? <><LoaderCircle className="h-4 w-4 animate-spin" />Saving…</> : copy.submitPassword}</button>
        </form>
        <button className="mt-4 w-full text-sm font-semibold text-gray-500 hover:text-blue-500" disabled={busy} onClick={() => { setAuthorizationToken(""); setNewPassword(""); setConfirmPassword(""); setStep("REQUEST"); }} type="button">Request a new verification code</button>
      </>}

      {step === "COMPLETE" && <>
        <h1 className="mt-4 font-display text-3xl font-extrabold">{copy.completeHeading}</h1>
        <p className="mt-2 text-sm leading-6 text-gray-500">{copy.completeDescription}</p>
        <Link className="ss-btn-accent mt-7 w-full" to="/login">Sign in now</Link>
      </>}
    </div>
  </div>;
}
