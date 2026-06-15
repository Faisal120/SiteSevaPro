import React, { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function TeamManagement() {
  const [members, setMembers] = useState([]);
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState("");

  const [form, setForm] = useState({
    full_name: "",
    email: "",
    role: "SUPERVISOR",
  });

  async function loadTeam() {
    try {
      const res = await api.get("/team");
      setMembers(res.data || []);
    } catch (err) {
      console.error(err);
      toast.error("Failed to load team");
    } finally {
      setLoading(false);
    }
  }

  async function createMember() {
    try {
      const res = await api.post("/team", form);

      toast.success(
        `Created Successfully\nEmail: ${res.data.email}\nPassword: ${res.data.password}`
      );

      alert(
        `Account Created\n\nEmail: ${res.data.email}\nPassword: ${res.data.password}`
      );

      setForm({
        full_name: "",
        email: "",
        role: "SUPERVISOR",
      });

      loadTeam();
    } catch (err) {
      toast.error(
        err?.response?.data?.detail || "Creation failed"
      );
    }
  }

  async function deleteMember(id) {
    const ok = window.confirm(
      "Are you sure you want to delete this member?"
    );

    if (!ok) return;

    try {
      await api.delete(`/team/${id}`);

      toast.success("Member deleted");

      loadTeam();
    } catch (err) {
      toast.error("Delete failed");
    }
  }

  async function toggleMember(id, blocked) {
    try {
      await api.patch(
        `/team/${id}?blocked=${!blocked}`
      );

      toast.success("Status updated");

      loadTeam();
    } catch (err) {
      toast.error("Update failed");
    }
  }

  useEffect(() => {
    loadTeam();
  }, []);

  const filteredMembers = members.filter((member) =>
    `${member.full_name || ""} ${member.email || ""} ${member.role || ""}`
      .toLowerCase()
      .includes(search.toLowerCase())
  );

  const totalSupervisors = members.filter(
    (m) => m.role === "SUPERVISOR"
  ).length;

  const totalClients = members.filter(
    (m) => m.role === "CLIENT"
  ).length;

  return (
    <div className="p-6">

      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold">
            Team Management
          </h1>

          <p className="text-muted-foreground">
            Manage Supervisors and Clients
          </p>
        </div>
      </div>

      {/* Stats */}

      <div className="grid md:grid-cols-3 gap-4 mb-6">

        <div className="border rounded-lg p-4 bg-white">
          <div className="text-sm text-gray-500">
            Total Members
          </div>

          <div className="text-3xl font-bold">
            {members.length}
          </div>
        </div>

        <div className="border rounded-lg p-4 bg-white">
          <div className="text-sm text-gray-500">
            Supervisors
          </div>

          <div className="text-3xl font-bold">
            {totalSupervisors}
          </div>
        </div>

        <div className="border rounded-lg p-4 bg-white">
          <div className="text-sm text-gray-500">
            Clients
          </div>

          <div className="text-3xl font-bold">
            {totalClients}
          </div>
        </div>

      </div>

      {/* Create Member */}

      <div className="border rounded-lg p-5 bg-white mb-6">

        <h2 className="font-bold text-lg mb-4">
          Add Team Member
        </h2>

        <div className="grid md:grid-cols-4 gap-3">

          <Input
            placeholder="Full Name"
            value={form.full_name}
            onChange={(e) =>
              setForm({
                ...form,
                full_name: e.target.value,
              })
            }
          />

          <Input
            placeholder="Email Address"
            value={form.email}
            onChange={(e) =>
              setForm({
                ...form,
                email: e.target.value,
              })
            }
          />

          <select
            className="border rounded-md px-3 py-2"
            value={form.role}
            onChange={(e) =>
              setForm({
                ...form,
                role: e.target.value,
              })
            }
          >
            <option value="SUPERVISOR">
              Supervisor
            </option>

            <option value="CLIENT">
              Client
            </option>
          </select>

          <Button onClick={createMember}>
            Create Member
          </Button>

        </div>

      </div>

      {/* Search */}

      <div className="mb-4">

        <Input
          placeholder="Search team member..."
          value={search}
          onChange={(e) =>
            setSearch(e.target.value)
          }
        />

      </div>

      {/* Table */}

      <div className="border rounded-lg overflow-hidden bg-white">

        {loading ? (

          <div className="p-6">
            Loading...
          </div>

        ) : (

          <table className="w-full">

            <thead className="bg-gray-100">

              <tr>

                <th className="text-left p-3">
                  Name
                </th>

                <th className="text-left p-3">
                  Email
                </th>

                <th className="text-left p-3">
                  Role
                </th>

                <th className="text-left p-3">
                  Status
                </th>

                <th className="text-left p-3">
                  Actions
                </th>

              </tr>

            </thead>

            <tbody>

              {filteredMembers.length === 0 ? (

                <tr>
                  <td
                    colSpan="5"
                    className="p-6 text-center text-gray-500"
                  >
                    No team members found
                  </td>
                </tr>

              ) : (

                filteredMembers.map((member) => (

                  <tr
                    key={member.id}
                    className="border-t"
                  >

                    <td className="p-3">
                      {member.full_name}
                    </td>

                    <td className="p-3">
                      {member.email}
                    </td>

                    <td className="p-3">
                      {member.role}
                    </td>

                    <td className="p-3">

                      {member.blocked ? (

                        <span className="text-red-600 font-medium">
                          Blocked
                        </span>

                      ) : (

                        <span className="text-green-600 font-medium">
                          Active
                        </span>

                      )}

                    </td>

                    <td className="p-3 space-x-3">

                      <button
                        className="text-blue-600 font-medium"
                        onClick={() =>
                          toggleMember(
                            member.id,
                            member.blocked
                          )
                        }
                      >
                        {member.blocked
                          ? "Unblock"
                          : "Block"}
                      </button>

                      <button
                        className="text-red-600 font-medium"
                        onClick={() =>
                          deleteMember(member.id)
                        }
                      >
                        Delete
                      </button>

                    </td>

                  </tr>

                ))

              )}

            </tbody>

          </table>

        )}

      </div>

    </div>
  );
}