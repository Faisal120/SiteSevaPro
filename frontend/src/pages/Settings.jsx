import React from "react";
import { useAuth } from "@/lib/auth";
import { SectionTitle } from "@/components/dashboard/Primitives";
import { User, Shield, Mail, Building } from "lucide-react";

export default function Settings() {
  const { user } = useAuth();
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Settings</h1>
        <p className="text-sm text-gray-500 mt-1">Your profile and account details.</p>
      </div>
      <div className="ss-card p-6 grid md:grid-cols-2 gap-6">
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Full Name</div>
          <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><User className="h-4 w-4 text-[#F97316]" /> {user.full_name}</div>
        </div>
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Email</div>
          <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><Mail className="h-4 w-4 text-[#F97316]" /> {user.email}</div>
        </div>
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Role</div>
          <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><Shield className="h-4 w-4 text-[#F97316]" /> {user.role.replace("_", " ")}</div>
        </div>
        {user.company_name && (
          <div>
            <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Company</div>
            <div className="mt-1 text-lg font-display font-bold flex items-center gap-2"><Building className="h-4 w-4 text-[#F97316]" /> {user.company_name}</div>
          </div>
        )}
        {user.username && (
          <div>
            <div className="text-xs font-bold uppercase tracking-wider text-gray-500">Username</div>
            <div className="mt-1 font-mono text-sm bg-gray-100 px-3 py-1.5 rounded inline-block">{user.username}</div>
          </div>
        )}
      </div>
    </div>
  );
}
