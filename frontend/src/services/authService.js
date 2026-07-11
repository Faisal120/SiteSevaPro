import authApi from "../api/authApi";

const TOKEN_KEY = "access_token";
const USER_KEY = "user";

const authService = {

    async login(credentials) {

        const response = await authApi.login(credentials);

        const data = response.data;

        localStorage.setItem(
            TOKEN_KEY,
            data.token
        );

        localStorage.setItem(
            USER_KEY,
            JSON.stringify(data.user)
        );

        return data;

    },

    logout() {

        localStorage.removeItem(TOKEN_KEY);

        localStorage.removeItem(USER_KEY);

    },

    getToken() {

        return localStorage.getItem(TOKEN_KEY);

    },

    getUser() {

        const user = localStorage.getItem(USER_KEY);

        if (!user) return null;

        return JSON.parse(user);

    },

    isAuthenticated() {

        return !!this.getToken();

    },

};

export default authService;