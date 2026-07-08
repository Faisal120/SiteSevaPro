import React from "react";
import { useNavigate } from "react-router-dom";
import {
  Building2, Users, Activity, AlertCircle, ArrowRight,
} from "lucide-react";
import { useAuth } from "@/lib/auth";
import { StatCard, SectionTitle, Chip } from "@/components/dashboard/Primitives";
import { inr, fmtDate, SITE_STATUS_COLOR } from "@/lib/constants";
import {
  ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, PieChart, Pie, Cell, Legend,
} from "recharts";

import useDashboard from "@/hooks/useDashboard";

import DashboardHeader from "@/components/dashboard/DashboardHeader";

import StatsCards from "@/components/dashboard/StatsCards";

import QuickActions from "@/components/dashboard/QuickActions";

import SiteCommandCenter from "@/components/dashboard/SiteCommandCenter";

import TodaysExecutionBoard from "@/components/dashboard/TodaysExecutionBoard";
import OperationsControlCenter from "@/components/dashboard/OperationsControlCenter";
import CompanyCard from "@/components/dashboard/CompanyCard";
import Button from "@/components/ui/button";

import DashboardGrid, {
  GridLeft,
  GridRight
} from "@/components/dashboard/DashboardGrid";


import WeatherCard from "@/components/dashboard/WeatherCard";
import RecentActivities from "@/components/dashboard/RecentActivities";

export default function Dashboard() {
  const { user } = useAuth();
  const nav = useNavigate();
  const {

    stats,

    charts,

    sites,

    team,

    latestPhotos,

    activities,

    alerts,

    company,

    loading,

    error,

    refresh,

  } = useDashboard();



  const greeting = React.useMemo(() => {

    const hour = new Date().getHours();

    if (hour < 12) return "Good Morning";

    if (hour < 17) return "Good Afternoon";

    return "Good Evening";

  }, []);

  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-10 w-64 rounded-xl bg-slate-200" />
        <div className="grid grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-40 rounded-3xl bg-slate-200" />
          ))}
        </div>
      </div>
    );
  }

  if (user.role === "CONTRACTOR") return (
    <ContractorDash

      charts={charts}

      user={user}

      stats={stats}

      sites={sites}

      team={team}

      company={company}

      activities={activities}

      alerts={alerts}

      latestPhotos={latestPhotos}

      greeting={greeting}

      nav={nav}

      loading={loading}

      error={error}

      refresh={refresh}

    />
  );
  if (user.role === "SUPERVISOR") return <SupervisorDash user={user} sites={sites} greeting={greeting} nav={nav} />;
  if (user.role === "CLIENT") return <ClientDash user={user} charts={charts} sites={sites} greeting={greeting} nav={nav} stats={stats} />;
  return null;
}

function ContractorDash({
  user,
  stats,
  charts,
  sites,
  team,
  alerts,
  latestPhotos,
  company,
  activities,
  greeting,
  nav,
  loading,
  error,
  refresh,
}) {
  return (
    <div className="space-y-6 ss-fade-in">

      <DashboardHeader
        user={user}
        stats={stats}
        company={company}
      />
      <div className="flex flex-wrap items-end justify-between gap-4">
        <Button
          icon={Building2}
          onClick={() => nav("/app/sites")}
        >
          Manage Sites
        </Button>
      </div>
      <div className="grid md:grid-cols-4 gap-4">

        <button
          className="ss-card p-5 text-left hover:border-orange-500"
          onClick={() => nav("/app/sites")}
        >
          Manage Sites
        </button>

        <button
          className="ss-card p-5 text-left hover:border-orange-500"
          onClick={() => nav("/app/team")}
        >
          Manage Team
        </button>

        <button
          className="ss-card p-5 text-left hover:border-orange-500"
          onClick={() => nav("/app/materials")}
        >
          Materials
        </button>

        <button
          className="ss-card p-5 text-left hover:border-orange-500"
          onClick={() => nav("/app/payments")}
        >
          Payments
        </button>

      </div>

      <StatsCards stats={stats} />

      <QuickActions />

      <DashboardGrid>

        <GridLeft>

          <SiteCommandCenter
            sites={sites}
          />

          <div className="ss-card p-5">

            <SectionTitle
              title="Latest Site Updates"
              subtitle="Recent photos uploaded by supervisors"
            />

            {latestPhotos.length === 0 ? (

              <div className="text-center py-10 text-gray-500">
                No site photos uploaded yet
              </div>

            ) : (

              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">

                {latestPhotos.map((photo, index) => (

                  <div
                    key={index}
                    className="overflow-hidden rounded-xl border"
                  >

                    <img
                      src={photo.url}
                      alt=""
                      className="
              h-40
              w-full
              object-cover
              hover:scale-105
              transition
            "
                    />

                  </div>

                ))}

              </div>

            )}

          </div>


          <div className="ss-card p-5 lg:col-span-2">
            <SectionTitle title="Site Progress Overview" subtitle="Progress across all active construction projects" />
            <div className="h-72">
              <ResponsiveContainer>
                {charts?.site_progress?.length ? (

                  <ResponsiveContainer>

                    <BarChart
                      data={charts.site_progress}
                      margin={{
                        top: 5,
                        right: 10,
                        left: -10,
                        bottom: 5,
                      }}
                    >

                      <CartesianGrid
                        strokeDasharray="3 3"
                        stroke="#E5E7EB"
                        vertical={false}
                      />

                      <XAxis
                        dataKey="name"
                        tick={{
                          fontSize: 11,
                          fill: "#525252",
                        }}
                      />

                      <YAxis
                        tick={{
                          fontSize: 11,
                          fill: "#525252",
                        }}
                      />

                      <Tooltip
                        formatter={(value, name, props) => [
                          `${value}%`,
                          props?.payload?.name || "Progress",
                        ]}
                        contentStyle={{
                          background: "#fff",
                          border: "1px solid #E5E7EB",
                          borderRadius: 12,
                          boxShadow:
                            "0 8px 30px rgba(0,0,0,.08)",
                        }}
                      />

                      <Bar
                        dataKey="progress"
                        fill="#2563EB"
                        radius={[8, 8, 0, 0]}
                      />

                    </BarChart>

                  </ResponsiveContainer>

                ) : (

                  <div
                    className="
            h-72
            flex
            items-center
            justify-center
            text-slate-400
            text-sm
        "
                  >
                    No project progress available.
                  </div>

                )}
              </ResponsiveContainer>
            </div>
          </div>



          <div className="ss-card p-5 lg:col-span-2">
            <SectionTitle
              title="Your Sites"
              action={<button onClick={() => nav("/app/sites")} className="text-sm font-semibold text-[#F97316] flex items-center gap-1">All sites <ArrowRight className="h-3.5 w-3.5" /></button>}
            />
            <div className="space-y-3">
              {sites.slice(0, 4).map((s) => (
                <button key={s.id} onClick={() => nav(`/app/sites/${s.id}`)} className="w-full text-left flex items-center gap-4 p-3 rounded-lg hover:bg-gray-50 border border-gray-100" data-testid={`dash-site-${s.id}`}>
                  <div className="h-12 w-12 rounded-lg bg-[#171717] text-[#F97316] flex items-center justify-center"><Building2 className="h-5 w-5" /></div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2"><span className="font-semibold truncate">{s.name}</span><Chip className={SITE_STATUS_COLOR[s.status]}>{s.status}</Chip></div>
                    <div className="text-xs text-gray-500">{s.location} · {inr(s.budget)}</div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-bold">{s.progress}%</div>
                    <div className="w-24 h-1.5 bg-gray-200 rounded-full mt-1 overflow-hidden">
                      <div className="h-full bg-[#F97316]" style={{ width: `${s.progress}%` }} />
                    </div>
                  </div>
                </button>
              ))}
              {sites.length === 0 && <p className="text-sm text-gray-500 p-4 text-center">No sites yet. Create your first site.</p>}
            </div>
          </div>

          <div className="ss-card p-5">
            <RecentActivities

              activities={activities}

            />
          </div>

        </GridLeft>

        <GridRight>

          <WeatherCard
            weather={null}
          />

          <OperationsControlCenter
            alerts={alerts}
          />



          <CompanyCard
            company={company}
            stats={stats}
            user={user}
          />

          <TodaysExecutionBoard
            stats={stats}
          />

        </GridRight>

      </DashboardGrid>

      {/* <div className="grid grid-cols-2 lg:grid-cols-3 gap-5">
        <StatCard label="Active Sites" value={`${stats.active_sites}/${stats.total_sites}`} icon={Building2} accent="ink" testId="stat-active-sites" />
        <StatCard label="Total Budget" value={inr(stats.total_budget)} icon={Wallet} accent="orange" testId="stat-total-budget" />
        <StatCard label="Total Received" value={inr(stats.total_received)} icon={TrendingUp} accent="yellow" trend={`Pending ${inr(stats.pending_payments)}`} testId="stat-received" />
        <StatCard label="Net Profit" value={inr(stats.net_profit)} icon={Activity} accent="soft" testId="stat-profit" />
        <StatCard
          label="Supervisors"
          value={
            team.filter(
              t => t.role === "SUPERVISOR"
            ).length
          }
          icon={Users}
          accent="orange"
        />

        <StatCard
          label="Clients"
          value={
            team.filter(
              t => t.role === "CLIENT"
            ).length
          }
          icon={Users}
          accent="yellow"
        />
      </div> */}


    </div>
  );
}

function SupervisorDash({ user, sites, greeting, nav }) {
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <p className="text-sm text-gray-500">{greeting},</p>
        <h1 className="font-display text-4xl font-extrabold tracking-tight">{user.full_name}</h1>
        <p className="text-sm text-gray-500 mt-1">You're assigned to {sites.length} site{sites.length !== 1 && "s"}.</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-5">
        <StatCard label="My Sites" value={sites.length} icon={Building2} accent="ink" testId="sup-sites" />
        <StatCard label="Today" value={fmtDate(new Date())} icon={Activity} accent="orange" testId="sup-today" />
        <StatCard label="Role" value={user.role} icon={Users} accent="yellow" testId="sup-role" />
        <StatCard
          label="Completed Sites"
          value={
            sites.filter(
              s => s.status === "COMPLETED"
            ).length
          }
          icon={Building2}
          accent="soft"
        />

        <StatCard
          label="Active Sites"
          value={
            sites.filter(
              s => s.status === "ACTIVE"
            ).length
          }
          icon={Activity}
          accent="orange"
        />
      </div>



      <div className="ss-card p-5">
        <SectionTitle title="My Sites" subtitle="Tap a site to mark attendance, upload reports and track materials." />
        <div className="grid md:grid-cols-2 gap-4">
          {sites.map((s) => (
            <button key={s.id} onClick={() => nav(`/app/sites/${s.id}`)} className="ss-card p-5 text-left hover:-translate-y-0.5" data-testid={`sup-site-${s.id}`}>
              <div className="flex items-center justify-between">
                <h3 className="font-display font-bold text-lg">{s.name}</h3>
                <Chip className={SITE_STATUS_COLOR[s.status]}>{s.status}</Chip>
              </div>
              <p className="text-sm text-gray-500 mt-1">{s.location}</p>
              <div className="mt-4 flex items-center justify-between">
                <div className="text-xs text-gray-500">Progress</div>
                <div className="text-sm font-bold">{s.progress}%</div>
              </div>
              <div className="w-full h-1.5 bg-gray-200 rounded-full mt-1 overflow-hidden">
                <div className="h-full bg-[#F97316]" style={{ width: `${s.progress}%` }} />
              </div>
            </button>
          ))}
          {sites.length === 0 && (
            <div className="md:col-span-2 text-center py-10 text-gray-500">No sites assigned yet. Contact your contractor.</div>
          )}
        </div>
      </div>
    </div>
  );
}

function ClientDash({ user, sites, greeting, nav, stats }) {
  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <p className="text-sm text-gray-500">{greeting},</p>
        <h1 className="font-display text-4xl font-extrabold tracking-tight">{user.full_name}</h1>
        <p className="text-sm text-gray-500 mt-1">Welcome to your project portal.</p>

      </div>
      <div className="grid md:grid-cols-2 gap-5">
        {sites.map((s) => (
          <div key={s.id} className="ss-card overflow-hidden">
            <img src="https://images.pexels.com/photos/1816030/pexels-photo-1816030.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600" alt="" className="w-full h-40 object-cover" />
            <div className="p-5">
              <div className="flex items-center justify-between">
                <h3 className="font-display font-bold text-lg">{s.name}</h3>
                <Chip className={SITE_STATUS_COLOR[s.status]}>{s.status}</Chip>
              </div>
              <p className="text-sm text-gray-500 mt-1">{s.location}</p>
              <div className="grid grid-cols-2 gap-3 mt-4">
                <div>
                  <div className="text-[10px] font-bold uppercase tracking-wider text-gray-500">Progress</div>
                  <div className="text-2xl font-extrabold text-[#171717]">{s.progress}%</div>
                </div>
                <div>
                  <div className="text-[10px] font-bold uppercase tracking-wider text-gray-500">Budget</div>
                  <div className="text-2xl font-extrabold text-[#171717]">{inr(s.budget)}</div>
                </div>
              </div>
              <button onClick={() => nav(`/app/sites/${s.id}`)} className="ss-btn-ink w-full mt-4" data-testid={`client-view-${s.id}`}>View Updates <ArrowRight className="h-4 w-4" /></button>
            </div>
          </div>
        ))}
        {sites.length === 0 && (
          <div className="md:col-span-2 ss-card p-10 text-center">
            <AlertCircle className="h-8 w-8 mx-auto text-gray-400" />
            <h3 className="mt-3 font-display font-bold">No project found</h3>
            <p className="text-sm text-gray-500">Your contractor hasn't linked you to a project yet.</p>
          </div>
        )}
      </div>
    </div>
  );
}
