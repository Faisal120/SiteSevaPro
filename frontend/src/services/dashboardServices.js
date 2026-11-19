import dashboardApi from "../api/dashboardApi";

const dashboardService = {

    async getDashboard() {

        const dashboard = await dashboardApi.getDashboard();
        const data = dashboard.data || {};

        return {

            stats: data.stats || {},

            sites: data.sites || [],

            team: data.team || [],

            charts: data.charts || {},

            alerts: data.alerts || [],

            activities: data.activities || [],

            company: data.company || {},

            latestPhotos: data.latestPhotos || [],

        };

    },

};

export default dashboardService;
