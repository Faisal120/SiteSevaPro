import * as http from "./baseService";

const BASE = "/sites";

export const siteService = {

    getAll() {

        return http.get(BASE);

    },

    getById(id) {

        return http.get(`${BASE}/${id}`);

    },

    create(payload) {

        return http.post(BASE, payload);

    },

    update(id, payload) {

        return http.put(`${BASE}/${id}`, payload);

    },

    delete(id) {

        return http.remove(`${BASE}/${id}`);

    }

}