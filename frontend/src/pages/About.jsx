import React from "react";
import PublicNav from "@/components/PublicNav";
import PublicFooter from "@/components/PublicFooter";
import { ShieldCheck, Target, Users, Award } from "lucide-react";

export default function About() {
  return (
    <div className="min-h-screen ss-mesh">
      <PublicNav />
      <section className="py-16 lg:py-24">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <span className="text-xs font-bold uppercase tracking-[0.2em] text-[#3B82F6]">About</span>
          <h1 className="mt-2 text-4xl sm:text-5xl font-extrabold font-display tracking-tight">
            Built by builders, for builders.
          </h1>
          <p className="mt-5 text-lg text-gray-600 leading-relaxed max-w-3xl">
            Site Seva Pro was born on real construction sites in Mumbai and Pune — where supervisors lost daily registers, materials walked off, and contractors burnt evenings reconciling Excel. We built the operating system Indian construction always deserved.
          </p>

          <div className="mt-12 grid gap-6 md:grid-cols-2">
            {[
              { i: Target, t: "Mission", d: "Digitise 100,000 construction sites across India by 2030." },
              { i: Users, t: "Who we serve", d: "Contractors, builders, site supervisors and their clients — from 1 site to 100." },
              { i: ShieldCheck, t: "Security first", d: "Bank-grade encryption, role-based access, daily backups." },
              { i: Award, t: "India-first", d: "GST, INR formatting, Hindi roadmap and on-ground support." },
            ].map((b) => (
              <div key={b.t} className="ss-card p-6">
                <div className="h-10 w-10 rounded-lg bg-[#171717] text-[#3B82F6] flex items-center justify-center">
                  <b.i className="h-5 w-5" />
                </div>
                <h3 className="mt-4 font-display text-xl font-bold">{b.t}</h3>
                <p className="mt-1 text-sm text-gray-600">{b.d}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
      <PublicFooter />
    </div>
  );
}
