import React from "react";
import { Link, NavLink } from "react-router-dom";
import { HardHat, Menu, Sparkles, X } from "lucide-react";

export default function PublicNav() {
  const [open, setOpen] = React.useState(false);
  const linkCls = ({ isActive }) =>
    `text-sm font-medium transition-colors ${isActive ? "text-white" : "text-slate-300 hover:text-white"}`;
  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-[#090a0c]/90 backdrop-blur-xl">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-[72px] items-center justify-between">
          <Link to="/" className="flex items-center gap-2 group" data-testid="nav-logo">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#171717] text-[#3B82F6] group-hover:bg-[#262626] transition-colors">
              <HardHat className="h-5 w-5" />
            </div>
            <span className="font-display text-lg font-extrabold tracking-tight text-white">Site Seva <span className="text-[#3B82F6]">Pro</span></span>
          </Link>

          <nav className="hidden md:flex items-center gap-8">
            <NavLink to="/" end className={linkCls} data-testid="nav-home">Home</NavLink>
            <Link to="/register" className="inline-flex items-center gap-1.5 text-sm font-medium text-blue-300 hover:text-white"><Sparkles className="h-3.5 w-3.5" />Design Studio</Link>
            <NavLink to="/pricing" className={linkCls} data-testid="nav-pricing">Pricing</NavLink>
            <NavLink to="/about" className={linkCls} data-testid="nav-about">About</NavLink>
            <NavLink to="/contact" className={linkCls} data-testid="nav-contact">Contact</NavLink>
          </nav>

          <div className="hidden md:flex items-center gap-3">
            <Link to="/login" className="text-sm font-medium text-slate-200 hover:text-white" data-testid="nav-login">Login</Link>
            <Link to="/register" className="ss-btn-accent" data-testid="nav-register">Get Started</Link>
          </div>

          <button
            className="text-white md:hidden rounded-lg p-2 hover:bg-white/10"
            onClick={() => setOpen((v) => !v)}
            aria-label="Toggle menu"
            data-testid="nav-mobile-toggle"
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
        {open && (
          <div className="md:hidden pb-4 flex flex-col gap-3">
            <NavLink to="/" end className={linkCls} onClick={() => setOpen(false)}>Home</NavLink>
            <Link to="/register" className="text-sm font-medium text-blue-300" onClick={() => setOpen(false)}>Design Studio</Link>
            <NavLink to="/pricing" className={linkCls} onClick={() => setOpen(false)}>Pricing</NavLink>
            <NavLink to="/about" className={linkCls} onClick={() => setOpen(false)}>About</NavLink>
            <NavLink to="/contact" className={linkCls} onClick={() => setOpen(false)}>Contact</NavLink>
            <div className="flex gap-3 border-t border-white/10 pt-2">
              <Link to="/login" className="ss-btn-outline w-full" onClick={() => setOpen(false)}>Login</Link>
              <Link to="/register" className="ss-btn-accent w-full" onClick={() => setOpen(false)}>Get Started</Link>
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
