import { useEffect, useState } from "react";
import dashboardService from "../services/dashboardServices";

export default function useDashboard() {
    const [stats, setStats] = useState(null);
    const [sites, setSites] = useState([]);
    const [team, setTeam] = useState([]);
    const [company, setCompany] = useState({});
    const [charts, setCharts] = useState({});
    const [alerts, setAlerts] = useState([]);
    const [activities, setActivities] = useState([]);
    const [isFetching, setIsFetching] = useState(false);
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
            setCompany(data.company ?? {});
            setCharts(data.charts ?? {});
            setAlerts(data.alerts ?? []);
            setActivities(data.activities ?? []);
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
        company,
        stats,
        charts,
        alerts,
        activities,
        sites,
        team,
        latestPhotos,
        loading,
        error,
        refresh: loadDashboard,
        isFetching: loading,
    };
}