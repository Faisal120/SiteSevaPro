import dashboardApi from "../api/dashboardApi";
import siteApi from "../api/siteApi";
import apiClient from "../api/apiClient";

const dashboardService = {

    async getDashboard() {

        const [

            dashboard,

            sites,

            team,

            reports,

        ] = await Promise.all([

            dashboardApi.getDashboard(),

            siteApi.list(),

            apiClient.get("/api/team"),

            apiClient.get("/api/reports"),

        ]);

        const latestPhotos =

            reports.data

                .flatMap(report =>

                    (report.media_urls || [])

                        .filter(media => media.type === "image")

                        .map(media => ({

                            ...media,

                            site_id: report.site_id,

                            report_date: report.date,

                        }))

                )

                .slice(0, 8);

        return {

            stats: dashboard.data.stats,

            sites: dashboard.data.sites,

            team: dashboard.data.team,

            latestPhotos: dashboard.data.latestPhotos || latestPhotos,

        };

    },

};

export default dashboardService;