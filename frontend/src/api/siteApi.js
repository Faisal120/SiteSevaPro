import apiClient from "./apiClient";

const siteApi = {

    list() {

        return apiClient.get(

            "/api/sites"

        );

    },

    get(id) {

        return apiClient.get(

            `/api/sites/${id}`

        );

    },

    create(data) {

        return apiClient.post(

            "/api/sites",

            data

        );

    },

    update(id, data) {

        return apiClient.put(

            `/api/sites/${id}`,

            data

        );

    },

    delete(id) {

        return apiClient.delete(

            `/api/sites/${id}`

        );

    },

};

export default siteApi;