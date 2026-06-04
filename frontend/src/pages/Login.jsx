import React from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { HardHat, LogIn, Eye, EyeOff } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { toast } from "sonner";

export default function Login() {
  const { login, user } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [showPw, setShowPw] = React.useState(false);
  const [busy, setBusy] = React.useState(false);

  React.useEffect(() => {
    if (user) nav("/app/dashboard", { replace: true });
  }, [user, nav]);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    try {
      const u = await login(email, password);
      toast.success(`Welcome back, ${u.full_name || u.email}`);
      const redirect = u.role === "SUPER_ADMIN" ? "/app/admin" : "/app/dashboard";
      nav(loc.state?.from || redirect, { replace: true });
    } catch (err) {
      toast.error(err?.response?.data?.detail || "Login failed");
    } finally {
      setBusy(false);
    }
  };

  const quickFill = (e, p) => { setEmail(e); setPassword(p); };

  return (
    <div className="min-h-screen flex">
      <div className="hidden lg:flex w-1/2 bg-[#171717] text-white relative overflow-hidden">
        <div className="absolute inset-0 ss-grid-dots opacity-10" aria-hidden />
        <div className="absolute -right-20 top-20 h-72 w-72 rounded-full bg-[#F97316]/20 blur-3xl" aria-hidden />
        <div className="relative flex flex-col justify-between p-12 w-full">
          <Link to="/" className="flex items-center gap-2">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-[#F97316]">
              <HardHat className="h-5 w-5" />
            </div>
            <span className="font-display text-lg font-extrabold">Site Seva <span className="text-[#F97316]">Pro</span></span>
          </Link>
          <div>
            <h1 className="font-display text-4xl font-extrabold leading-tight">Run your construction company like a tech startup.</h1>
            <p className="mt-4 text-gray-300 max-w-md">Sites, supervisors, materials, payments — one beautifully designed platform.</p>
          </div>
          <div className="text-xs text-gray-400">© {new Date().getFullYear()} Site Seva Pro</div>
        </div>
      </div>

      <div className="flex-1 flex items-center justify-center p-6 ss-mesh">
        <div className="w-full max-w-md">
          <Link to="/" className="lg:hidden flex items-center gap-2 mb-8">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#171717] text-[#F97316]"><HardHat className="h-5 w-5" /></div>
            <span className="font-display text-lg font-extrabold">Site Seva <span className="text-[#F97316]">Pro</span></span>
          </Link>
          <h2 className="font-display text-3xl font-extrabold tracking-tight">Welcome back</h2>
          <p className="mt-1 text-sm text-gray-500">Sign in to your dashboard.</p>

          <form onSubmit={submit} className="mt-8 space-y-4" data-testid="login-form">
            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Email</label>
              <input
                type="email"
                className="ss-input mt-1"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                data-testid="login-email"
              />
            </div>
            <div>
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Password</label>
              <div className="relative mt-1">
                <input
                  type={showPw ? "text" : "password"}
                  className="ss-input pr-10"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  data-testid="login-password"
                />
                <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" onClick={() => setShowPw((v) => !v)}>
                  {showPw ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>
            <button type="submit" disabled={busy} className="ss-btn-accent w-full" data-testid="login-submit">
              <LogIn className="h-4 w-4" /> {busy ? "Signing in…" : "Sign in"}
            </button>
          </form>

          <div className="mt-6 text-sm text-gray-500 text-center">
            New contractor? <Link to="/register" className="font-semibold text-[#F97316] hover:underline" data-testid="login-to-register">Apply for access</Link>
          </div>

          <div className="mt-8 ss-card p-4">
            <div className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-2">Demo accounts (click to fill)</div>
            <div className="grid gap-2 text-xs">
              <button type="button" className="text-left p-2 rounded hover:bg-gray-50" onClick={() => quickFill("admin@siteseva.pro", "Admin@SiteSeva2026")} data-testid="demo-admin">
                <span className="font-semibold text-[#F97316]">Super Admin</span> · admin@siteseva.pro
              </button>
              <button type="button" className="text-left p-2 rounded hover:bg-gray-50" onClick={() => quickFill("contractor@demo.com", "Contractor@2026")} data-testid="demo-contractor">
                <span className="font-semibold text-[#F97316]">Contractor</span> · contractor@demo.com
              </button>
              <button type="button" className="text-left p-2 rounded hover:bg-gray-50" onClick={() => quickFill("supervisor@demo.com", "Supervisor@2026")} data-testid="demo-supervisor">
                <span className="font-semibold text-[#F97316]">Supervisor</span> · supervisor@demo.com
              </button>
              <button type="button" className="text-left p-2 rounded hover:bg-gray-50" onClick={() => quickFill("client@demo.com", "Client@2026")} data-testid="demo-client">
                <span className="font-semibold text-[#F97316]">Client</span> · client@demo.com
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
