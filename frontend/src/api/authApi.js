import apiClient from "./apiClient";

const authApi = {

    login(data) {

        return apiClient.post(

            "/api/auth/login",

            data

        );

    },

    register(data) {

        return apiClient.post(

            "/api/auth/applications",

            data

        );

    },

    me() {

        return apiClient.get(

            "/api/auth/me"

        );

    },

    logout() {

        localStorage.clear();

    },

};

export default authApi;