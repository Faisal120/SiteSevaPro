import React from "react";
import { Plus, Camera, Image as ImageIcon, Video, Loader2, FileText } from "lucide-react";
import { api, uploadToCloudinary } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { SectionTitle, EmptyState } from "@/components/dashboard/Primitives";
import { fmtDate } from "@/lib/constants";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function DailyReports() {
  const { user } = useAuth();
  const [list, setList] = React.useState([]);
  const [sites, setSites] = React.useState([]);
  const [siteFilter, setSiteFilter] = React.useState("ALL");
  const [open, setOpen] = React.useState(false);


  const load = async () => {
    const [r, s] = await Promise.all([api.get("/reports"), api.get("/sites")]);
    setList(r.data); setSites(s.data);
  };
  React.useEffect(() => { load(); }, []);
  const siteName = (id) => sites.find((s) => s.id === id)?.name || "Site";
  const filtered = siteFilter === "ALL" ? list : list.filter((r) => r.site_id === siteFilter);

  return (
    <div className="space-y-6 ss-fade-in">
      <div className="flex flex-wrap items-end justify-between gap-4">

        <div>
          <h1 className="font-display text-3xl font-extrabold tracking-tight">Daily Site Reports</h1>
          <p className="text-sm text-gray-500 mt-1">Photos, videos, completed tasks and issues in a single timeline.</p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={siteFilter} onValueChange={setSiteFilter}>
            <SelectTrigger className="w-56" data-testid="dr-filter"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">All sites</SelectItem>
              {sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}
            </SelectContent>
          </Select>
          {(user.role === "SUPERVISOR" || user.role === "CONTRACTOR") && (
            <Dialog open={open} onOpenChange={setOpen}>
              <DialogTrigger asChild>
                <button className="ss-btn-accent" data-testid="dr-new"><Plus className="h-4 w-4" /> New Report</button>
              </DialogTrigger>
              <ReportForm sites={sites} onDone={() => { setOpen(false); load(); }} />
            </Dialog>
          )}
        </div>

        <div className="grid md:grid-cols-4 gap-4">

          <div className="ss-card p-6 hover:shadow-lg transition-all">
            <div className="text-xs text-gray-500">
              Total Reports
            </div>

            <div className="text-3xl font-bold">
              {list.length}
            </div>
          </div>

          <div className="ss-card p-6 hover:shadow-lg transition-all">
            <div className="text-xs text-gray-500">
              Photos
            </div>

            <div className="text-3xl font-bold">
              {
                list.reduce(
                  (a, r) =>
                    a +
                    (r.media_urls || [])
                      .filter(x => x.type === "image")
                      .length,
                  0
                )
              }
            </div>
          </div>

          <div className="ss-card p-6 hover:shadow-lg transition-all">
            <div className="text-xs text-gray-500">
              Videos
            </div>

            <div className="text-3xl font-bold">
              {
                list.reduce(
                  (a, r) =>
                    a +
                    (r.media_urls || [])
                      .filter(x => x.type === "video")
                      .length,
                  0
                )
              }
            </div>
          </div>

          <div className="ss-card p-6 hover:shadow-lg transition-all">
            <div className="text-xs text-gray-500">
              Active Sites
            </div>

            <div className="text-3xl font-bold">
              {sites.length}
            </div>
          </div>

        </div>
      </div>

      {filtered.length === 0 ? (
        <EmptyState icon={FileText} title="No reports yet" description="Daily site updates from supervisors will show up here." />
      ) : (
        <div className="relative pl-6">
          <div className="absolute left-2 top-0 bottom-0 w-px bg-gray-200" />
          <div className="space-y-5">
            {filtered.map((r) => (
              <div key={r.id} className="relative" data-testid={`dr-${r.id}`}>
                <div className="absolute -left-4 top-3 h-3 w-3 rounded-full bg-[#3B82F6] ring-4 ring-white" />
                <div className="ss-card p-6 hover:shadow-lg transition-all">
                  <div className="flex items-center justify-between flex-wrap gap-2">
                    <div>
                      <div className="text-xs font-bold uppercase tracking-wider text-[#3B82F6]">{fmtDate(r.date)}</div>
                      <h3 className="font-display font-bold text-xl mt-1">{siteName(r.site_id)}</h3>
                      <div className="text-xs text-gray-500 mt-0.5">by {r.created_by_name || "Supervisor"}</div>
                    </div>
                     <div className="flex gap-2 mt-2">

                        <span className="ss-chip bg-blue-100 text-blue-700">
                          Report
                        </span>

                        <span className="ss-chip bg-green-100 text-green-700">
                          {r.media_urls?.length || 0} Files
                        </span>

                      </div>
                  </div>
                  <p className="mt-3 text-sm text-gray-700 whitespace-pre-wrap">{r.notes}</p>
                  {r.completed_tasks?.length > 0 && (
                    <div className="mt-3"><div className="text-xs font-bold uppercase tracking-wider text-emerald-600 mb-1">Completed</div>
                      <ul className="text-sm text-gray-700 list-disc list-inside">{r.completed_tasks.map((t, i) => <li key={i}>{t}</li>)}</ul></div>
                  )}
                  {r.issues?.length > 0 && (
                    <div className="mt-3"><div className="text-xs font-bold uppercase tracking-wider text-red-600 mb-1">Issues</div>
                      <ul className="text-sm text-gray-700 list-disc list-inside">{r.issues.map((t, i) => <li key={i}>{t}</li>)}</ul></div>
                  )}
                  {r.media_urls?.length > 0 && (
                    <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-2">
                      {r.media_urls.map((m) => (
                        m.type === "video" ? (
                          <video key={m.public_id || m.url} src={m.url} controls className="rounded-lg h-32 w-full object-cover bg-black" />
                        ) : (
                          <img key={m.public_id || m.url} src={m.url} alt="" className="rounded-lg h-32 w-full object-cover" />
                        )
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function ReportForm({ sites, onDone }) {
  const [f, setF] = React.useState({
    site_id: sites[0]?.id || "", date: new Date().toISOString().slice(0, 10),
    notes: "", completed_tasks_raw: "", issues_raw: "", media_urls: [],
  });
  const [uploading, setUploading] = React.useState(false);
  const handleFiles = async (files) => {
    if (!files?.length) return;
    setUploading(true);
    try {
      const uploads = await Promise.all(Array.from(files).map((file) => uploadToCloudinary(file, "siteseva/reports")));
      setF((prev) => ({ ...prev, media_urls: [...prev.media_urls, ...uploads] }));
      toast.success(`${uploads.length} file(s) uploaded`);
    } catch { toast.error("Upload failed. Check Cloudinary keys."); }
    finally { setUploading(false); }
  };
  const submit = async (e) => {
    e.preventDefault();
    try {
      await api.post("/reports", {
        site_id: f.site_id, date: f.date, notes: f.notes,
        completed_tasks: f.completed_tasks_raw.split("\n").map(s => s.trim()).filter(Boolean),
        issues: f.issues_raw.split("\n").map(s => s.trim()).filter(Boolean),
        media_urls: f.media_urls,
      });
      toast.success("Report submitted"); onDone();
    } catch (err) { toast.error("Failed"); }
  };
  return (
    <DialogContent className="max-w-2xl">
      <DialogHeader><DialogTitle>New Daily Report</DialogTitle></DialogHeader>
      <form onSubmit={submit} className="grid gap-4">
        <div className="grid md:grid-cols-2 gap-4">
          <div><label className="text-xs font-bold uppercase text-gray-500">Site</label>
            <Select value={f.site_id} onValueChange={(v) => setF({ ...f, site_id: v })}>
              <SelectTrigger className="mt-1" data-testid="drf-site"><SelectValue /></SelectTrigger>
              <SelectContent>{sites.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent>
            </Select>
          </div>
          <div><label className="text-xs font-bold uppercase text-gray-500">Date</label><input type="date" required className="ss-input mt-1" value={f.date} onChange={(e) => setF({ ...f, date: e.target.value })} /></div>
        </div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Notes</label><textarea required className="ss-input mt-1 min-h-[80px]" value={f.notes} onChange={(e) => setF({ ...f, notes: e.target.value })} data-testid="drf-notes" /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Completed tasks (one per line)</label><textarea className="ss-input mt-1 min-h-[60px]" value={f.completed_tasks_raw} onChange={(e) => setF({ ...f, completed_tasks_raw: e.target.value })} /></div>
        <div><label className="text-xs font-bold uppercase text-gray-500">Issues (one per line)</label><textarea className="ss-input mt-1 min-h-[60px]" value={f.issues_raw} onChange={(e) => setF({ ...f, issues_raw: e.target.value })} /></div>
        <div>
          <label className="text-xs font-bold uppercase text-gray-500">Photos / Videos</label>
          <label className="mt-1 flex flex-col items-center justify-center border-2 border-dashed border-gray-300 rounded-lg p-6 cursor-pointer hover:border-[#3B82F6] hover:bg-blue-50/30 transition-colors">
            {uploading ? <Loader2 className="h-6 w-6 text-[#3B82F6] animate-spin" /> : <Camera className="h-6 w-6 text-gray-500" />}
            <span className="text-xs text-gray-500 mt-2">Click to upload (multiple)</span>
            <input type="file" multiple accept="image/*,video/*" hidden onChange={(e) => handleFiles(e.target.files)} data-testid="drf-files" />
          </label>
          {f.media_urls.length > 0 && (
            <div className="mt-3 grid grid-cols-4 gap-2">
              {f.media_urls.map((m) => (
                <div key={m.public_id || m.url} className="relative">
                  {m.type === "video" ? <Video className="h-5 w-5 text-white absolute top-1 left-1" /> : <ImageIcon className="h-5 w-5 text-white absolute top-1 left-1" />}
                  {m.type === "video" ? <video src={m.url} className="h-20 w-full object-cover rounded bg-black" /> : <img src={m.url} alt="" className="h-20 w-full object-cover rounded" />}
                </div>
              ))}
            </div>
          )}
        </div>
        <button type="submit" disabled={uploading} className="ss-btn-accent" data-testid="drf-submit">Submit Report</button>
      </form>
    </DialogContent>
  );
}
