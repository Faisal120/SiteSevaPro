import React from "react";
import { Link } from "react-router-dom";
import { HardHat } from "lucide-react";

export default function PublicFooter() {
  return (
    <footer className="border-t border-gray-200 bg-[#171717] text-gray-300">
      <div className="mx-auto max-w-7xl px-6 py-12 lg:px-8 grid gap-10 md:grid-cols-4">
        <div>
          <Link to="/" className="flex items-center gap-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#F97316] text-white">
              <HardHat className="h-5 w-5" />
            </div>
            <span className="font-display text-lg font-extrabold text-white">Site Seva <span className="text-[#F97316]">Pro</span></span>
          </Link>
          <p className="mt-4 text-sm text-gray-400 max-w-xs">
            India's construction-first SaaS to digitise sites, supervisors, materials and payments — end to end.
          </p>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-white mb-3">Product</h4>
          <ul className="space-y-2 text-sm">
            <li><Link to="/pricing" className="hover:text-[#F97316]">Pricing</Link></li>
            <li><Link to="/register" className="hover:text-[#F97316]">Get Started</Link></li>
            <li><Link to="/login" className="hover:text-[#F97316]">Login</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-white mb-3">Company</h4>
          <ul className="space-y-2 text-sm">
            <li><Link to="/about" className="hover:text-[#F97316]">About</Link></li>
            <li><Link to="/contact" className="hover:text-[#F97316]">Contact</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-white mb-3">Legal</h4>
          <ul className="space-y-2 text-sm">
            <li><span className="hover:text-[#F97316] cursor-pointer">Privacy</span></li>
            <li><span className="hover:text-[#F97316] cursor-pointer">Terms</span></li>
          </ul>
        </div>
      </div>
      <div className="border-t border-white/10 py-5 text-center text-xs text-gray-500">
        © {new Date().getFullYear()} Site Seva Pro. Built for Indian construction.
      </div>
    </footer>
  );
}
