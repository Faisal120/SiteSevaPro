import apiClient from "./apiClient";

const dashboardApi = {

    getDashboard() {

        return apiClient.get(

            "/dashboard"

        );

    },

};

export default dashboardApi;