import dashboardApi from "../api/dashboardApi";

const dashboardService = {

    async getDashboard() {

        const response = await dashboardApi.getDashboard();

        return response.data;

    },

};

export default dashboardService;