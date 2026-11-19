import React from "react";
import { Bell, Wallet, Package, Building2, CreditCard, Info, CheckCheck } from "lucide-react";
import { api } from "@/lib/api";
import { SectionTitle, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";

const ICONS = { PAYMENT: Wallet, WALLET: Wallet, STOCK: Package, MATERIAL: Package, SITE: Building2, SUBSCRIPTION: CreditCard, ATTENDANCE: CheckCheck, INFO: Info };

export default function Notifications() {
  const [list, setList] = React.useState([]);
  const [filter, setFilter] =
    React.useState("ALL");
  const unreadCount =
    list.filter(x => !x.read).length;
  const load = async () => {
    const { data } = await api.get("/notifications");
    setList(data);
  };
  React.useEffect(() => { load(); }, []);
  const markRead = async (id) => { await api.put(`/notifications/${id}/read`); load(); };

  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">
          Activity Center
        </h1>

        <p className="text-sm text-gray-500 mt-1">
          Track assignments, payments, materials and project updates.
        </p>

        <div className="mt-4">
          <button
            className="ss-btn-outline"
            onClick={async () => {
              for (const n of list.filter(x => !x.read)) {
                await api.put(
                  `/notifications/${n.id}/read`
                );
              }

              load();
            }}
          >
            <CheckCheck className="h-4 w-4" />
            Mark All Read ({unreadCount})
          </button>
        </div>
      </div>

      <div className="grid md:grid-cols-3 gap-4">

        <div className="ss-card p-5">
          <div className="text-xs text-gray-500">
            Total Notifications
          </div>

          <div className="text-3xl font-bold mt-1">
            {list.length}
          </div>
        </div>

        <div className="ss-card p-5">
          <div className="text-xs text-gray-500">
            Unread
          </div>

          <div className="text-3xl font-bold text-blue-400 mt-1">
            {list.filter(x => !x.read).length}
          </div>
        </div>

        <div className="ss-card p-5">
          <div className="text-xs text-gray-500">
            Read
          </div>

          <div className="text-3xl font-bold text-green-600 mt-1">
            {list.filter(x => x.read).length}
          </div>
        </div>

        <div className="flex gap-2 flex-wrap">

          {[
            "ALL",
            "PAYMENT",
            "SITE",
            "STOCK",
            "ATTENDANCE"
          ].map(type => (

            <button
              key={type}
              onClick={() => setFilter(type)}
              className={`
        px-4 py-2 rounded-lg border
        ${filter === type
                  ? "bg-blue-500 text-white"
                  : "bg-white"
                }
      `}
            >
              {type}
            </button>

          ))}

        </div>

      </div>
      {list.length === 0 ? (
        <EmptyState icon={Bell} title="All caught up" description="You'll see alerts and updates here." />
      ) : (
        <div className="ss-card divide-y divide-gray-100">
          {list
            .filter(
              n =>
                filter === "ALL" ||
                n.type === filter
            )
            .map((n) => {
              const I = ICONS[n.type] || Info;
              return (
                <button key={n.id} onClick={() => markRead(n.id)} className={`w-full text-left flex items-start gap-4 p-5 hover:bg-white/5 ${!n.read ? "bg-blue-500/10" : ""}`} data-testid={`notif-${n.id}`}>
                  <div
                    className={`
    h-12 w-12 rounded-xl
    flex items-center justify-center
    shrink-0
    ${!n.read
                        ? "bg-blue-500 text-white"
                        : "bg-gray-100 text-gray-500"
                      }
  `}
                  >
                    <I className="h-5 w-5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-[#171717] truncate">{n.title}</span>
                      {!n.read && <span className="h-2 w-2 rounded-full bg-blue-400" />}
                    </div>
                    <div className="text-sm text-gray-600 mt-0.5">{n.message || n.body}</div>
                    <div className="text-xs text-gray-400 mt-1">{fmtDate(n.created_at)}</div>
                  </div>
                </button>
              );
            })}
        </div>
      )}
    </div>
  );
}
