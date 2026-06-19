import React from "react";
import { useNavigate } from "react-router-dom";
import { Building2, Plus, MapPin, Calendar, IndianRupee, X } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { SectionTitle, Chip, EmptyState } from "@/components/dashboard/Primitives";
import { inr, fmtDate, SITE_STATUS_COLOR } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";


export default function Sites() {
  const { user } = useAuth();
  const nav = useNavigate();
  const [sites, setSites] = React.useState([]);
  const [loading, setLoading] = React.useState(true);
  const [open, setOpen] = React.useState(false);
  const [filter, setFilter] = React.useState("ALL");

  const load = async () => {
    setLoading(true);
    const { data } = await api.get("/sites");
    setSites(data);

    setLoading(false);
  };
  React.useEffect(() => { load(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, []);

  const filtered = sites.filter((s) => filter === "ALL" || s.status === filter);

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Sites</h1>
          <p className="text-sm text-gray-500 mt-1">All your construction projects in one view.</p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={filter} onValueChange={setFilter}>
            <SelectTrigger className="w-40" data-testid="sites-filter"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">All</SelectItem>
              <SelectItem value="ACTIVE">Active</SelectItem>
              <SelectItem value="PLANNING">Planning</SelectItem>
              <SelectItem value="ON_HOLD">On Hold</SelectItem>
              <SelectItem value="COMPLETED">Completed</SelectItem>
            </SelectContent>
          </Select>
          {user.role === "CONTRACTOR" && (
            <Dialog open={open} onOpenChange={setOpen}>
              <DialogTrigger asChild>
                <button className="ss-btn-accent" data-testid="sites-new"><Plus className="h-4 w-4" /> New Site</button>
              </DialogTrigger>
              <SiteForm onDone={() => { setOpen(false); load(); }} />
            </Dialog>
          )}
        </div>
      </div>

      {loading ? (
        <div className="text-center py-20 text-gray-500">Loading…</div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={Building2}
          title="No sites yet"
          description={user.role === "CONTRACTOR" ? "Create your first site to start tracking labour, materials, and payments." : "No sites match your view."}
          action={user.role === "CONTRACTOR" ? <button onClick={() => setOpen(true)} className="ss-btn-accent"><Plus className="h-4 w-4" /> Create site</button> : null}
        />
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filtered.map((s) => (
            <button key={s.id} onClick={() => nav(`/app/sites/${s.id}`)} className="ss-card text-left overflow-hidden hover:-translate-y-1" data-testid={`site-card-${s.id}`}>
              <div className="h-32 bg-gradient-to-br from-[#171717] to-[#262626] relative">
                <img
                  src="https://images.pexels.com/photos/1816030/pexels-photo-1816030.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=200&w=400"
                  alt={s.name}
                  className="w-full h-full object-cover opacity-80"
                />
                <Chip className={`${SITE_STATUS_COLOR[s.status]} absolute top-3 right-3`}>{s.status}</Chip>
              </div>
              <div className="p-5">
                <h3 className="font-display font-bold text-lg truncate">{s.name}</h3>
                <p className="text-xs text-gray-500 flex items-center gap-1 mt-1"><MapPin className="h-3 w-3" /> {s.location}</p>
                <div className="grid grid-cols-2 gap-3 mt-4 text-xs">
                  <div>
                    <div className="text-gray-500">Budget</div>
                    <div className="font-bold text-[#171717]">{inr(s.budget)}</div>
                  </div>
                  <div>
                    <div className="text-gray-500">End Date</div>
                    <div className="font-bold text-[#171717]">{fmtDate(s.end_date)}</div>
                  </div>
                </div>
                <div className="mt-4">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-gray-500">Progress</span>
                    <span className="font-bold">{s.progress}%</span>
                  </div>
                  <div className="w-full h-1.5 bg-gray-200 rounded-full mt-1 overflow-hidden">
                    <div className="h-full bg-[#F97316]" style={{ width: `${s.progress}%` }} />
                  </div>
                </div>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function SiteForm({ onDone }) {
  const [f, setF] = React.useState({
    name: "", client_id: "",
    supervisor_id: "", location: "", budget: 0,
    floors: 1, has_boring: false, has_septic_tank: false,
    has_soak_pit: false, has_mumty: false,
    start_date: new Date().toISOString().slice(0, 10),
    end_date: new Date(Date.now() + 1000 * 60 * 60 * 24 * 180).toISOString().slice(0, 10),
    status: "ACTIVE", description: "",
  });
  const [busy, setBusy] = React.useState(false);
  const [team, setTeam] = React.useState([]);
  React.useEffect(() => {
    api.get("/team")
      .then((res) => setTeam(res.data))
      .catch(console.error);
  }, []);
  const set = (k) => (e) => setF({ ...f, [k]: e.target.value });
  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    try {
      await api.post("/sites", {
        ...f, budget: Number(f.budget), floors: f.floors, has_boring: f.has_boring,

        has_septic_tank:
          f.has_septic_tank,

        has_soak_pit:
          f.has_soak_pit,

        has_mumty:
          f.has_mumty

      });
      toast.success("Site created");
      onDone();
    } catch (err) { toast.error(err?.response?.data?.detail || "Failed"); }
    finally { setBusy(false); }
  };
  return (
    <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto rounded-3xl">
      <DialogHeader><DialogTitle>Create New Site</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4 md:grid-cols-2" data-testid="site-form">
        <div className="md:col-span-2">
          <div className="md:col-span-2 border-b pb-2">
            <h3 className="text-lg font-bold">
              Basic Information
            </h3>
          </div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Site Name</label>
          <input className="ss-input mt-1" required value={f.name} onChange={set("name")} data-testid="site-name" />
        </div>
        <div className="md:col-span-2">
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Location</label>
          <input className="ss-input mt-1" required value={f.location} onChange={set("location")} data-testid="site-location" />
        </div>
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">
            Supervisor
          </label>

          <select
            className="ss-input mt-1"
            value={f.supervisor_id}
            onChange={(e) =>
              setF({
                ...f,
                supervisor_id: e.target.value
              })
            }
          >
            <option value="">Select Supervisor</option>

            {team
              .filter((u) => u.role === "SUPERVISOR")
              .map((u) => (
                <option key={u.id} value={u.id}>
                  {u.full_name}
                </option>
              ))}
          </select>
        </div>
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">
            Client
          </label>

          <select
            className="ss-input mt-1"
            value={f.client_id}
            onChange={(e) =>
              setF({
                ...f,
                client_id: e.target.value
              })
            }
          >
            <option value="">Select Client</option>

            {team
              .filter((u) => u.role === "CLIENT")
              .map((u) => (
                <option key={u.id} value={u.id}>
                  {u.full_name}
                </option>
              ))}
          </select>
        </div>
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Start</label>
          <input className="ss-input mt-1" type="date" required value={f.start_date} onChange={set("start_date")} data-testid="site-start" />
        </div>
        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">End</label>
          <input className="ss-input mt-1" type="date" required value={f.end_date} onChange={set("end_date")} data-testid="site-end" />
        </div>
        <div>
          <div>
            <label className="text-xs font-bold uppercase tracking-wider text-gray-500">
              Budget (₹)
            </label>

            <input
              className="ss-input mt-1"
              type="number"
              required
              value={f.budget}
              onChange={set("budget")}
            />
          </div>

          <div>
            <label className="text-xs font-bold uppercase tracking-wider text-gray-500">
              Total Floors
            </label>

            <select
              className="ss-input mt-1"
              value={f.floors}
              onChange={(e) =>
                setF({
                  ...f,
                  floors: Number(e.target.value)
                })
              }
            >
              <option value={1}>Ground Floor</option>
              <option value={2}>Ground + First</option>
              <option value={3}>Ground + First + Second</option>
              <option value={4}>Ground + First + Second + Third</option>
            </select>
          </div>

          <div className="grid md:grid-cols-2 gap-3">

            <label className="flex items-center gap-2">

              <input
                type="checkbox"
                checked={f.has_boring}
                onChange={(e) =>
                  setF({
                    ...f,
                    has_boring: e.target.checked
                  })
                }
              />

              Boring
            </label>

            <label className="flex items-center gap-2">

              <input
                type="checkbox"
                checked={f.has_septic_tank}
                onChange={(e) =>
                  setF({
                    ...f,
                    has_septic_tank: e.target.checked
                  })
                }
              />

              Septic Tank
            </label>

            <label className="flex items-center gap-2">

              <input
                type="checkbox"
                checked={f.has_soak_pit}
                onChange={(e) =>
                  setF({
                    ...f,
                    has_soak_pit: e.target.checked
                  })
                }
              />

              Soak Pit
            </label>

            <label className="flex items-center gap-2">

              <input
                type="checkbox"
                checked={f.has_mumty}
                onChange={(e) =>
                  setF({
                    ...f,
                    has_mumty: e.target.checked
                  })
                }
              />
              Mumty
            </label>

          </div>

        </div>


        <div>
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Status</label>
          <Select value={f.status} onValueChange={(v) => setF({ ...f, status: v })}>
            <SelectTrigger className="mt-1" data-testid="site-status"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="PLANNING">Planning</SelectItem>
              <SelectItem value="ACTIVE">Active</SelectItem>
              <SelectItem value="ON_HOLD">On Hold</SelectItem>
              <SelectItem value="COMPLETED">Completed</SelectItem>
            </SelectContent>
          </Select>
        </div>



        <div className="md:col-span-2">
          <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Description</label>
          <textarea className="ss-input mt-1 min-h-[80px]" value={f.description} onChange={set("description")} data-testid="site-description" />
        </div>
        <button type="submit" disabled={busy} className="ss-btn-accent md:col-span-2" data-testid="site-submit">
          {busy ? "Saving…" : "Create Site"}
        </button>
      </form>
    </DialogContent>
  );
}
