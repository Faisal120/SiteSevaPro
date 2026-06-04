import React from "react";

export function StatCard({ label, value, icon: Icon, accent = "ink", trend, testId }) {
  const accents = {
    ink: "bg-[#171717] text-white",
    orange: "bg-[#F97316] text-white",
    yellow: "bg-[#EAB308] text-[#171717]",
    soft: "bg-gray-100 text-[#171717]",
  };
  return (
    <div className="ss-stat" data-testid={testId}>
      <div className="flex items-center justify-between">
        <span className="text-xs font-bold uppercase tracking-[0.18em] text-gray-500">{label}</span>
        {Icon && (
          <div className={`h-9 w-9 rounded-lg flex items-center justify-center ${accents[accent]}`}>
            <Icon className="h-4 w-4" />
          </div>
        )}
      </div>
      <div className="text-2xl sm:text-3xl font-extrabold text-[#171717] font-display">{value}</div>
      {trend && <div className="text-xs text-gray-500">{trend}</div>}
    </div>
  );
}

export function SectionTitle({ title, subtitle, action }) {
  return (
    <div className="flex items-end justify-between gap-4 mb-4">
      <div>
        <h2 className="text-xl sm:text-2xl font-extrabold tracking-tight font-display">{title}</h2>
        {subtitle && <p className="text-sm text-gray-500 mt-1">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

export function Chip({ children, className = "" }) {
  return <span className={`ss-chip ${className}`}>{children}</span>;
}

export function EmptyState({ icon: Icon, title, description, action }) {
  return (
    <div className="ss-card p-10 flex flex-col items-center text-center">
      {Icon && (
        <div className="h-12 w-12 rounded-xl bg-gray-100 flex items-center justify-center mb-3">
          <Icon className="h-6 w-6 text-gray-500" />
        </div>
      )}
      <h3 className="font-display text-lg font-bold text-[#171717]">{title}</h3>
      {description && <p className="text-sm text-gray-500 mt-1 max-w-md">{description}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}
