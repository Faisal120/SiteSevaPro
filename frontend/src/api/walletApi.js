import apiClient from "./apiClient";

const walletApi = {

    wallet(id) {

        return apiClient.get(

            `/wallet/${id}`

        );

    },

    ledger(id) {

        return apiClient.get(

            `/wallet/${id}/ledger`

        );

    },

    payroll(month) {

        return apiClient.get(

            `/wallet/payroll/${month}`

        );

    },

};

export default walletApi;