import React from "react";
import { Link } from "react-router-dom";
import { ArrowUpRight, HardHat, Mail } from "lucide-react";

export default function PublicFooter() {
  return (
    <footer className="border-t border-white/10 bg-[#090a0c] text-gray-300">
      <div className="mx-auto grid max-w-7xl gap-10 px-6 py-14 md:grid-cols-[1.5fr_1fr_1fr_1fr] lg:px-8">
        <div>
          <Link to="/" className="flex items-center gap-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#3B82F6] text-white">
              <HardHat className="h-5 w-5" />
            </div>
            <span className="font-display text-lg font-extrabold text-white">Site Seva <span className="text-[#3B82F6]">Pro</span></span>
          </Link>
          <p className="mt-4 max-w-xs text-sm leading-6 text-gray-400">
            One focused workspace for construction operations, BOQ and estimates, and floor-wise 2D/3D planning.
          </p>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-white mb-3">Product</h4>
          <ul className="space-y-2 text-sm">
            <li><Link to="/pricing" className="hover:text-[#3B82F6]">Pricing</Link></li>
            <li><Link to="/register" className="hover:text-[#3B82F6]">BOQ & Estimates</Link></li>
            <li><Link to="/register" className="hover:text-[#3B82F6]">2D & 3D Planning</Link></li>
            <li><Link to="/register" className="hover:text-[#3B82F6]">Get Started</Link></li>
            <li><Link to="/login" className="hover:text-[#3B82F6]">Login</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-white mb-3">Company</h4>
          <ul className="space-y-2 text-sm">
            <li><Link to="/about" className="hover:text-[#3B82F6]">About</Link></li>
            <li><Link to="/contact" className="hover:text-[#3B82F6]">Contact</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="mb-3 text-sm font-semibold text-white">Support & legal</h4>
          <ul className="space-y-2 text-sm"><li><a href="mailto:support@sitesevapro.in" className="inline-flex items-center gap-2 font-semibold text-blue-300 hover:text-white"><Mail className="h-4 w-4" />support@sitesevapro.in</a></li><li><a href="mailto:info@sitesevapro.in" className="inline-flex items-center gap-2 text-gray-400 hover:text-white"><ArrowUpRight className="h-4 w-4" />info@sitesevapro.in</a></li><li><Link to="/contact" className="hover:text-[#3B82F6]">Privacy & security</Link></li><li><Link to="/contact" className="hover:text-[#3B82F6]">Terms of service</Link></li></ul>
        </div>
      </div>
      <div className="mx-auto flex max-w-7xl flex-col gap-2 border-t border-white/10 px-6 py-5 text-xs text-gray-500 sm:flex-row sm:items-center sm:justify-between lg:px-8">
        <span>© {new Date().getFullYear()} Site Seva Pro. All rights reserved.</span><span>Construction operations, BOQ and floor-wise planning for modern teams.</span>
      </div>
    </footer>
  );
}
