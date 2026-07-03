import axios from "axios";

const apiClient = axios.create({

    baseURL: process.env.REACT_APP_BACKEND_URL,

    timeout: 30000,

    headers: {

        "Content-Type": "application/json",

    },

});


// ==========================================
// REQUEST
// ==========================================

apiClient.interceptors.request.use(

    (config) => {

        const token = localStorage.getItem("access_token");

        if (token) {

            config.headers.Authorization = `Bearer ${token}`;

        }

        return config;

    },

    (error) => Promise.reject(error)

);


// ==========================================
// RESPONSE
// ==========================================

apiClient.interceptors.response.use(

    (response) => response,

    (error) => {

        if (error.response?.status === 401) {

            localStorage.removeItem("access_token");

            localStorage.removeItem("user");

            window.location.href = "/login";

        }

        return Promise.reject(error);

    }

);


export default apiClient;