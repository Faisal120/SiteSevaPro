import React from "react";
import { Bell, Wallet, Package, Building2, CreditCard, Info, CheckCheck } from "lucide-react";
import { api } from "@/lib/api";
import { SectionTitle, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";

const ICONS = { PAYMENT: Wallet, STOCK: Package, SITE: Building2, SUBSCRIPTION: CreditCard, ATTENDANCE: CheckCheck, INFO: Info };

export default function Notifications() {
  const [list, setList] = React.useState([]);
  const load = async () => {
    const { data } = await api.get("/notifications");
    setList(data);
  };
  React.useEffect(() => { load(); }, []);
  const markRead = async (id) => { await api.post(`/notifications/${id}/read`); load(); };

  return (
    <div className="space-y-6 ss-fade-in">
      <div>
        <h1 className="font-display text-3xl font-extrabold tracking-tight">Notifications</h1>
        <p className="text-sm text-gray-500 mt-1">Stay updated on payments, stock, sites and subscriptions.</p>
      </div>
      {list.length === 0 ? (
        <EmptyState icon={Bell} title="All caught up" description="You'll see alerts and updates here." />
      ) : (
        <div className="ss-card divide-y divide-gray-100">
          {list.map((n) => {
            const I = ICONS[n.type] || Info;
            return (
              <button key={n.id} onClick={() => markRead(n.id)} className={`w-full text-left flex items-start gap-4 p-5 hover:bg-gray-50 ${!n.read ? "bg-orange-50/30" : ""}`} data-testid={`notif-${n.id}`}>
                <div className={`h-10 w-10 rounded-lg flex items-center justify-center shrink-0 ${!n.read ? "bg-[#F97316] text-white" : "bg-gray-100 text-gray-500"}`}>
                  <I className="h-5 w-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-[#171717] truncate">{n.title}</span>
                    {!n.read && <span className="h-2 w-2 rounded-full bg-[#F97316]" />}
                  </div>
                  <div className="text-sm text-gray-600 mt-0.5">{n.body}</div>
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
