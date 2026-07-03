import apiClient from "./apiClient";

const paymentApi = {

    list(siteId) {

        return apiClient.get(

            `/payments?site_id=${siteId}`

        );

    },

    create(data) {

        return apiClient.post(

            "/payments",

            data

        );

    },

};

export default paymentApi;