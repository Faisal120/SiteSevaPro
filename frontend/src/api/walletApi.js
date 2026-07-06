import apiClient from "./apiClient";

const walletApi = {

    wallet(id) {

        return apiClient.get(

            `/api/wallet/${id}`

        );

    },

    ledger(id) {

        return apiClient.get(

            `/api/wallet/${id}/ledger`

        );

    },

    payroll(month) {

        return apiClient.get(

            `/api/wallet/payroll/${month}`

        );

    },

};

export default walletApi;