import apiClient from "./apiClient";

const attendanceApi = {

    mark(data) {

        return apiClient.post(

            "/api/attendance",

            data

        );

    },

    list(siteId, date = null) {

        let url = `/api/attendance?site_id=${siteId}`;

        if (date) {

            url += `&date=${date}`;

        }

        return apiClient.get(url);

    },

};

export default attendanceApi;