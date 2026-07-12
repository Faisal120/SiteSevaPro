import React from "react";
import { Activity } from "lucide-react";
import { api } from "@/lib/api";
import {
  SectionTitle,
  Chip,
  EmptyState,
} from "@/components/dashboard/Primitives";

const ACTION_COLOR = {
  CREATE: "bg-emerald-100 text-emerald-700",
  UPDATE: "bg-blue-100 text-blue-700",
  DELETE: "bg-red-100 text-red-700",
  APPROVE: "bg-purple-100 text-purple-700",
  REJECT: "bg-orange-100 text-orange-700",
  PAY: "bg-yellow-100 text-yellow-800",
};

function formatDate(value) {

  if (!value) return "-";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {

    return "-";

  }

  return date.toLocaleString();

}

export default function AuditLogs() {

  const [list, setList] = React.useState([]);

  const [filter, setFilter] = React.useState("");

  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {

    setLoading(true);

    api
      .get(`/admin/audit?limit=300${filter ? `&entity=${filter}` : ""}`)
      .then((r) => {

        setList(Array.isArray(r.data) ? r.data : []);

      })
      .catch(() => {

        setList([]);

      })
      .finally(() => {

        setLoading(false);

      });

  }, [filter]);

  return (

    <div className="space-y-6 ss-fade-in">

      <div className="flex flex-wrap items-end justify-between gap-4">

        <div>

          <h1 className="font-display text-3xl font-extrabold">

            Audit Logs

          </h1>

          <p className="text-sm text-gray-500">

            Complete platform activity.

          </p>

        </div>

        <input

          className="ss-input w-60"

          placeholder="Filter entity..."

          value={filter}

          onChange={(e) => setFilter(e.target.value)}

        />

      </div>

      {loading ? (

        <div className="ss-card p-10 text-center">

          Loading...

        </div>

      ) : list.length === 0 ? (

        <EmptyState

          icon={Activity}

          title="No Audit Logs"

        />

      ) : (

        <div className="ss-card overflow-x-auto">

          <table className="ss-table">

            <thead>

              <tr>

                <th>Time</th>

                <th>User</th>

                <th>Role</th>

                <th>Action</th>

                <th>Entity</th>

                <th>Entity ID</th>

                <th>Meta</th>

              </tr>

            </thead>

            <tbody>

              {list.map((log) => (

                <tr key={log.id || log._id}>

                  <td>

                    {formatDate(

                      log.ts ||

                      log.created_at ||

                      log.timestamp

                    )}

                  </td>

                  <td>

                    {log.user_email ||

                      log.email ||

                      "-"}

                  </td>

                  <td>

                    <Chip>

                      {log.user_role ||

                        log.role ||

                        "-"}

                    </Chip>

                  </td>

                  <td>

                    <Chip

                      className={

                        ACTION_COLOR[log.action] ||

                        "bg-gray-100"

                      }

                    >

                      {log.action || "-"}

                    </Chip>

                  </td>

                  <td>

                    {log.entity || "-"}

                  </td>

                  <td className="font-mono text-xs">

                    {(log.entity_id || "-")
                      .toString()
                      .slice(0, 12)}

                  </td>

                  <td className="text-xs font-mono">

                    {log.meta
                      ? JSON.stringify(log.meta)
                      : "-"}

                  </td>

                </tr>

              ))}

            </tbody>

          </table>

        </div>

      )}

    </div>

  );

}