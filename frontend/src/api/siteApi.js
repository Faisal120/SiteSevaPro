import apiClient from "./apiClient";

const siteApi = {

    list() {

        return apiClient.get(

            "/sites"

        );

    },

    get(id) {

        return apiClient.get(

            `/sites/${id}`

        );

    },

    create(data) {

        return apiClient.post(

            "/sites",

            data

        );

    },

    update(id, data) {

        return apiClient.put(

            `/sites/${id}`,

            data

        );

    },

    delete(id) {

        return apiClient.delete(

            `/sites/${id}`

        );

    },

};

export default siteApi;