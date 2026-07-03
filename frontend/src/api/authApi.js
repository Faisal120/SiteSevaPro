import apiClient from "./apiClient";

const authApi = {

    login(data) {

        return apiClient.post(

            "/auth/login",

            data

        );

    },

    register(data) {

        return apiClient.post(

            "/auth/register",

            data

        );

    },

    me() {

        return apiClient.get(

            "/auth/me"

        );

    },

    logout() {

        localStorage.clear();

    },

};

export default authApi;