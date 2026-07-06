import apiClient from "./apiClient";

const dashboardApi = {

    getDashboard() {

        return apiClient.get(

            "/api/dashboard"

        );

    },

};

export default dashboardApi;