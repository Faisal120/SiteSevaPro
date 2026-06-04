import React from "react";
import "@/App.css";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Toaster } from "sonner";
import { AuthProvider, useAuth } from "@/lib/auth";

import Landing from "@/pages/Landing";
import Pricing from "@/pages/Pricing";
import About from "@/pages/About";
import Contact from "@/pages/Contact";
import Login from "@/pages/Login";
import ContractorRegister from "@/pages/ContractorRegister";

import DashboardLayout from "@/layouts/DashboardLayout";
import Dashboard from "@/pages/Dashboard";
import Sites from "@/pages/Sites";
import SiteDetail from "@/pages/SiteDetail";
import Labour from "@/pages/Labour";
import Materials from "@/pages/Materials";
import Payments from "@/pages/Payments";
import DailyReports from "@/pages/DailyReports";
import Notifications from "@/pages/Notifications";
import Subscription from "@/pages/Subscription";
import Settings from "@/pages/Settings";

import AdminDashboard from "@/pages/admin/AdminDashboard";
import Applications from "@/pages/admin/Applications";
import Contractors from "@/pages/admin/Contractors";
import Revenue from "@/pages/admin/Revenue";

function Protected({ children, roles }) {
  const { user, loading } = useAuth();
  if (loading) return <div className="p-10 text-center text-gray-500">Loading…</div>;
  if (!user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) return <Navigate to="/app/dashboard" replace />;
  return children;
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Toaster position="top-right" richColors closeButton />
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/pricing" element={<Pricing />} />
          <Route path="/about" element={<About />} />
          <Route path="/contact" element={<Contact />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<ContractorRegister />} />

          <Route
            path="/app"
            element={
              <Protected>
                <DashboardLayout />
              </Protected>
            }
          >
            <Route index element={<Navigate to="dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="sites" element={<Sites />} />
            <Route path="sites/:siteId" element={<SiteDetail />} />
            <Route path="labour" element={<Labour />} />
            <Route path="materials" element={<Materials />} />
            <Route path="payments" element={<Payments />} />
            <Route path="reports" element={<DailyReports />} />
            <Route path="notifications" element={<Notifications />} />
            <Route path="subscription" element={<Subscription />} />
            <Route path="settings" element={<Settings />} />

            <Route
              path="admin"
              element={
                <Protected roles={["SUPER_ADMIN"]}>
                  <AdminDashboard />
                </Protected>
              }
            />
            <Route
              path="admin/applications"
              element={
                <Protected roles={["SUPER_ADMIN"]}>
                  <Applications />
                </Protected>
              }
            />
            <Route
              path="admin/contractors"
              element={
                <Protected roles={["SUPER_ADMIN"]}>
                  <Contractors />
                </Protected>
              }
            />
            <Route
              path="admin/revenue"
              element={
                <Protected roles={["SUPER_ADMIN"]}>
                  <Revenue />
                </Protected>
              }
            />
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
