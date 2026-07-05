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

            apiClient.get("/team"),

            apiClient.get("/reports"),

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

            stats: dashboard.data,

            sites: sites.data,

            team: team.data,

            latestPhotos,

        };

    },

};

export default dashboardService;