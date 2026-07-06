import { useEffect, useState } from "react";
import dashboardService from "../services/dashboardServices";

export default function useDashboard() {
    const [stats, setStats] = useState(null);
    const [sites, setSites] = useState([]);
    const [team, setTeam] = useState([]);
    const [latestPhotos, setLatestPhotos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const loadDashboard = async () => {
        try {
            setLoading(true);

            const data = await dashboardService.getDashboard();

            setStats(data.stats ?? {});
            setSites(data.sites ?? []);
            setTeam(data.team ?? []);
            setLatestPhotos(data.latestPhotos ?? []);
            setError(null);
        } catch (err) {
            setError(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadDashboard();
    }, []);

    return {
        stats,
        sites,
        team,
        latestPhotos,
        loading,
        error,
        refresh: loadDashboard,
        isFetching: loading,
    };
}