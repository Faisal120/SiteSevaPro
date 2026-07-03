import {
  LayoutDashboard,
  Building2,
  Users,
  Package,
  Wallet,
  FileText,
  Bell,
  CreditCard,
  Settings,
  Calculator,
  Receipt,
  BadgeIndianRupee,
  Building,
  BarChart3,
  Briefcase,
  Shield,
  Activity,
  Map,
} from "lucide-react";

/* ===========================================
   CONTRACTOR MENU
=========================================== */

export const contractorMenu = [
  {
    title: "Overview",
    items: [
      {
        label: "Dashboard",
        path: "/app/dashboard",
        icon: LayoutDashboard,
      },
      {
        label: "Executive",
        path: "/app/executive",
        icon: BarChart3,
        badge: "PRO",
      },
    ],
  },

  {
    title: "Operations",
    items: [
      {
        label: "Sites",
        path: "/app/sites",
        icon: Building2,
      },
      {
        label: "Team",
        path: "/app/team",
        icon: Users,
      },
      {
        label: "Labour",
        path: "/app/labour",
        icon: Users,
      },
      {
        label: "Labour Wallet",
        path: "/app/labour/wallet",
        icon: Wallet,
      },
      {
        label: "Materials",
        path: "/app/materials",
        icon: Package,
      },
      {
        label: "Vendors",
        path: "/app/vendors",
        icon: Building,
      },
      {
        label: "Daily Reports",
        path: "/app/reports",
        icon: FileText,
      },
    ],
  },

  {
    title: "Finance",
    items: [
      {
        label: "Payments",
        path: "/app/payments",
        icon: BadgeIndianRupee,
      },
      {
        label: "Expenses",
        path: "/app/expenses",
        icon: Receipt,
      },
    ],
  },

  {
    title: "Planning",
    items: [
      {
        label: "Estimator",
        path: "/app/estimates",
        icon: Calculator,
      },
      {
        label: "BOQ",
        path: "/app/boq",
        icon: FileText,
      },
      {
        label: "Design Studio",
        path: "/app/maps",
        icon: Map,
        badge: "NEW",
      },
    ],
  },

  {
    title: "Account",
    items: [
      {
        label: "Notifications",
        path: "/app/notifications",
        icon: Bell,
      },
      {
        label: "Subscription",
        path: "/app/subscription",
        icon: CreditCard,
      },
      {
        label: "Settings",
        path: "/app/settings",
        icon: Settings,
      },
    ],
  },
];

/* ===========================================
   SUPERVISOR MENU
=========================================== */

export const supervisorMenu = [
  {
    title: "Site",
    items: [
      {
        label: "Dashboard",
        path: "/app/dashboard",
        icon: LayoutDashboard,
      },
      {
        label: "My Sites",
        path: "/app/sites",
        icon: Building2,
      },
      {
        label: "Attendance",
        path: "/app/labour",
        icon: Users,
      },
      {
        label: "Labour Wallet",
        path: "/app/labour/wallet",
        icon: Wallet,
      },
      {
        label: "Materials",
        path: "/app/materials",
        icon: Package,
      },
      {
        label: "Expenses",
        path: "/app/expenses",
        icon: Receipt,
      },
      {
        label: "Daily Reports",
        path: "/app/reports",
        icon: FileText,
      },
    ],
  },

  {
    title: "Account",
    items: [
      {
        label: "Notifications",
        path: "/app/notifications",
        icon: Bell,
      },
      {
        label: "Settings",
        path: "/app/settings",
        icon: Settings,
      },
    ],
  },
];

/* ===========================================
   CLIENT MENU
=========================================== */

export const clientMenu = [
  {
    title: "Project",
    items: [
      {
        label: "Dashboard",
        path: "/app/dashboard",
        icon: LayoutDashboard,
      },
      {
        label: "My Project",
        path: "/app/sites",
        icon: Building2,
      },
      {
        label: "Payments",
        path: "/app/payments",
        icon: Wallet,
      },
      {
        label: "Updates",
        path: "/app/reports",
        icon: FileText,
      },
    ],
  },

  {
    title: "Account",
    items: [
      {
        label: "Notifications",
        path: "/app/notifications",
        icon: Bell,
      },
      {
        label: "Settings",
        path: "/app/settings",
        icon: Settings,
      },
    ],
  },
];

/* ===========================================
   SUPER ADMIN MENU
=========================================== */

export const adminMenu = [
  {
    title: "Platform",
    items: [
      {
        label: "Overview",
        path: "/app/admin",
        icon: LayoutDashboard,
      },
      {
        label: "Applications",
        path: "/app/admin/applications",
        icon: Briefcase,
      },
      {
        label: "Contractors",
        path: "/app/admin/contractors",
        icon: Users,
      },
      {
        label: "Supervisors",
        path: "/app/admin/supervisors",
        icon: Shield,
      },
      {
        label: "Subscriptions",
        path: "/app/admin/subscriptions",
        icon: CreditCard,
      },
      {
        label: "UPI Payments",
        path: "/app/admin/payments",
        icon: BadgeIndianRupee,
      },
      {
        label: "Analytics",
        path: "/app/admin/revenue",
        icon: BarChart3,
      },
      {
        label: "Audit Logs",
        path: "/app/admin/audit",
        icon: Activity,
      },
    ],
  },

  {
    title: "Account",
    items: [
      {
        label: "Notifications",
        path: "/app/notifications",
        icon: Bell,
      },
      {
        label: "Settings",
        path: "/app/settings",
        icon: Settings,
      },
    ],
  },
];