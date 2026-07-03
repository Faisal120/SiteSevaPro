import apiClient from "./apiClient";

const materialApi = {

    list(siteId) {

        return apiClient.get(

            `/materials?site_id=${siteId}`

        );

    },

    create(data) {

        return apiClient.post(

            "/materials",

            data

        );

    },

    transaction(data) {

        return apiClient.post(

            "/material-txns",

            data

        );

    },

};

export default materialApi;