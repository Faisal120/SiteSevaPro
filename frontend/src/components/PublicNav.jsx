import React from "react";
import { Link, NavLink } from "react-router-dom";
import { HardHat, Menu, X } from "lucide-react";

export default function PublicNav() {
  const [open, setOpen] = React.useState(false);
  const linkCls = ({ isActive }) =>
    `text-sm font-medium transition-colors ${isActive ? "text-[#171717]" : "text-gray-600 hover:text-[#171717]"}`;
  return (
    <header className="sticky top-0 z-50 ss-glass border-b border-gray-200/60">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          <Link to="/" className="flex items-center gap-2 group" data-testid="nav-logo">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#171717] text-[#F97316] group-hover:bg-[#262626] transition-colors">
              <HardHat className="h-5 w-5" />
            </div>
            <span className="font-display text-lg font-extrabold tracking-tight">Site Seva <span className="text-[#F97316]">Pro</span></span>
          </Link>

          <nav className="hidden md:flex items-center gap-8">
            <NavLink to="/" end className={linkCls} data-testid="nav-home">Home</NavLink>
            <NavLink to="/pricing" className={linkCls} data-testid="nav-pricing">Pricing</NavLink>
            <NavLink to="/about" className={linkCls} data-testid="nav-about">About</NavLink>
            <NavLink to="/contact" className={linkCls} data-testid="nav-contact">Contact</NavLink>
          </nav>

          <div className="hidden md:flex items-center gap-3">
            <Link to="/login" className="text-sm font-medium text-[#171717] hover:text-[#F97316]" data-testid="nav-login">Login</Link>
            <Link to="/register" className="ss-btn-accent" data-testid="nav-register">Get Started</Link>
          </div>

          <button
            className="md:hidden p-2 rounded-lg hover:bg-gray-100"
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
            <NavLink to="/pricing" className={linkCls} onClick={() => setOpen(false)}>Pricing</NavLink>
            <NavLink to="/about" className={linkCls} onClick={() => setOpen(false)}>About</NavLink>
            <NavLink to="/contact" className={linkCls} onClick={() => setOpen(false)}>Contact</NavLink>
            <div className="flex gap-3 pt-2 border-t border-gray-200">
              <Link to="/login" className="ss-btn-outline w-full" onClick={() => setOpen(false)}>Login</Link>
              <Link to="/register" className="ss-btn-accent w-full" onClick={() => setOpen(false)}>Get Started</Link>
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
