import { api } from "@/lib/api";

/**
 * Dashboard Bootstrap API
 * Loads all data required by Layout, Sidebar and Dashboard
 */

export async function getBootstrapData() {

    const { data } = await api.get("/dashboard/bootstrap");

    return data;

}