import React from "react";
import { Plus, Users, CheckCircle2, X } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { SectionTitle, EmptyState, Chip } from "@/components/dashboard/Primitives";
import { inr, fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function Labour() {
  const { user } = useAuth();
  const [labour, setLabour] = React.useState([]);
  const [sites, setSites] = React.useState([]);
  const [siteId, setSiteId] = React.useState("");
  const [open, setOpen] = React.useState(false);
  const [attDate, setAttDate] = React.useState(new Date().toISOString().slice(0, 10));
  const [attendance, setAttendance] = React.useState({});

  const load = async () => {
    const sts = await api.get("/sites");
    setSites(sts.data);
    if (!siteId && sts.data[0]) setSiteId(sts.data[0].id);
  };
  React.useEffect(() => { load(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, []);

  React.useEffect(() => {
    if (!siteId) return;
    api.get(`/labour?site_id=${siteId}`).then((r) => setLabour(r.data));
    api.get(`/attendance?site_id=${siteId}&date=${attDate}`).then((r) => {
      const map = {};
      (r.data.entries || []).forEach((e) => {
        map[e.labour_id] = {
          status: e.status || (e.present ? "PRESENT" : "ABSENT"),
          overtime_hours: e.overtime_hours,
          advance: e.advance,
        };
      });
      setAttendance(map);
    });
  }, [siteId, attDate]);

  const saveAttendance = async () => {
    const entries = labour.map((l) => ({
      labour_id: l.id,
      status: attendance[l.id]?.status || "ABSENT",
      overtime_hours: Number(attendance[l.id]?.overtime_hours || 0),
      advance: Number(attendance[l.id]?.advance || 0),
    }));
    try {
      await api.post("/attendance", { site_id: siteId, date: attDate, entries });
      toast.success("Attendance saved · earnings auto-credited to wallet");
    } catch (e) { toast.error("Failed"); }
  };

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Labour & Attendance</h1>
          <p className="text-sm text-gray-500 mt-1">Manage your workforce and daily muster.</p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={siteId} onValueChange={setSiteId}>
            <SelectTrigger className="w-56" data-testid="labour-site"><SelectValue placeholder="Select site" /></SelectTrigger>
            <SelectContent>{sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent>
          </Select>
          {user.role !== "CLIENT" && siteId && (
            <Dialog open={open} onOpenChange={setOpen}>
              <DialogTrigger asChild>
                <button className="ss-btn-accent" data-testid="labour-add"><Plus className="h-4 w-4" /> Add Labour</button>
              </DialogTrigger>
              <LabourForm siteId={siteId} onDone={() => { setOpen(false); api.get(`/labour?site_id=${siteId}`).then((r) => setLabour(r.data)); }} />
            </Dialog>
          )}
        </div>
      </div>

      <Tabs defaultValue="list">
        <TabsList className="bg-white border border-gray-200 p-1">
          <TabsTrigger value="list" data-testid="labour-tab-list">Labour List</TabsTrigger>
          <TabsTrigger value="attendance" data-testid="labour-tab-attendance">Today's Attendance</TabsTrigger>
        </TabsList>

        <TabsContent value="list" className="mt-5">
          {labour.length === 0 ? (
            <EmptyState icon={Users} title="No labour added" description="Add labour to start tracking attendance and wages." />
          ) : (
            <div className="ss-card p-5 overflow-x-auto">
              <table className="ss-table">
                <thead><tr><th>Name</th><th>Role</th><th>Daily Wage</th><th>Mobile</th><th>Added</th></tr></thead>
                <tbody>
                  {labour.map((l) => (
                    <tr key={l.id} data-testid={`labour-row-${l.id}`}>
                      <td className="font-semibold">{l.full_name}</td>
                      <td><Chip className="bg-gray-100 text-gray-700">{l.trade}</Chip></td>
                      <td>{inr(l.daily_wage)}</td>
                      <td>{l.mobile || "—"}</td>
                      <td className="text-gray-500">{fmtDate(l.created_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </TabsContent>

        <TabsContent value="attendance" className="mt-5">
          <div className="ss-card p-5">
            <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
              <div>
                <h3 className="font-display font-bold text-lg">Mark Attendance</h3>
                <p className="text-xs text-gray-500">Save by tapping the button at the bottom.</p>
              </div>
              <input type="date" className="ss-input w-44" value={attDate} onChange={(e) => setAttDate(e.target.value)} data-testid="att-date" />
            </div>
            <div className="overflow-x-auto">
              <table className="ss-table">
                <thead><tr><th>Worker</th><th>Status</th><th>OT (hrs)</th><th>Advance</th><th className="text-right">Earning</th></tr></thead>
                <tbody>
                  {labour.map((l) => {
                    const a = attendance[l.id] || {};
                    const status = a.status || "ABSENT";
                    const factor = status === "PRESENT" ? 1 : status === "HALF" ? 0.5 : 0;
                    const ot = Number(a.overtime_hours || 0) * (l.daily_wage / 8);
                    const earn = l.daily_wage * factor + ot;
                    return (
                      <tr key={l.id}>
                        <td><div className="font-semibold">{l.full_name}</div><div className="text-xs text-gray-500">{l.trade} · ₹{l.daily_wage}/day</div></td>
                        <td>
                          <div className="flex gap-1">
                            {["PRESENT", "HALF", "ABSENT"].map((s) => (
                              <button
                                key={s}
                                type="button"
                                onClick={() => setAttendance({ ...attendance, [l.id]: { ...a, status: s } })}
                                className={`px-2.5 py-1 rounded text-xs font-semibold border-2 transition ${status === s
                                  ? (s === "PRESENT" ? "bg-emerald-100 text-emerald-700 border-emerald-300" :
                                    s === "HALF" ? "bg-yellow-100 text-yellow-800 border-yellow-300" :
                                      "bg-red-100 text-red-700 border-red-300")
                                  : "bg-gray-50 text-gray-500 border-transparent hover:border-gray-200"
                                  }`}
                                data-testid={`att-${s.toLowerCase()}-${l.id}`}
                              >
                                {s === "PRESENT" ? "P" : s === "HALF" ? "½" : "A"}
                              </button>
                            ))}
                          </div>
                        </td>
                        <td><input type="number" className="ss-input w-24" value={a.overtime_hours || 0} onChange={(e) => setAttendance({ ...attendance, [l.id]: { ...a, overtime_hours: e.target.value } })} /></td>
                        <td><input type="number" className="ss-input w-32" value={a.advance || 0} onChange={(e) => setAttendance({ ...attendance, [l.id]: { ...a, advance: e.target.value } })} /></td>
                        <td className="text-right font-bold text-emerald-600">₹{earn.toFixed(0)}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            {labour.length > 0 && (
              <button onClick={saveAttendance} className="ss-btn-accent mt-5" data-testid="att-save"><CheckCircle2 className="h-4 w-4" /> Save Attendance</button>
            )}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}

function LabourForm({ siteId, onDone }) {
  const [f, setF] = React.useState({ name: "", role: "Mason", daily_wage: 800, mobile: "", aadhaar: "" });
  const submit = async (e) => {
    e.preventDefault();

    try {

      await api.post("/labour", {

        full_name: f.name,

        trade: f.role,

        daily_wage: Number(f.daily_wage),

        mobile: f.mobile || null,

        aadhaar: f.aadhaar || null,

        address: null,

        site_id: siteId,

      });

      toast.success("Labour added");

      onDone();

    } catch (err) {

      console.log(err.response?.data);

      toast.error("Failed");

    }
  };
  return (
    <DialogContent>
      <DialogHeader><DialogTitle>Add Labour</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4">
        <div><label className="text-xs font-bold uppercase text-gray-500">Name</label><input className="ss-input mt-1" required value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} data-testid="labour-form-name" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Role</label><input className="ss-input mt-1" required value={f.role} onChange={(e) => setF({ ...f, role: e.target.value })} data-testid="labour-form-role" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Daily Wage</label><input className="ss-input mt-1" type="number" required value={f.daily_wage} onChange={(e) => setF({ ...f, daily_wage: e.target.value })} data-testid="labour-form-wage" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Mobile</label><input className="ss-input mt-1" value={f.mobile} onChange={(e) => setF({ ...f, mobile: e.target.value })} /></div>
        <button type="submit" className="ss-btn-accent" data-testid="labour-form-submit">Save</button>
      </form>
    </DialogContent>
  );
}
