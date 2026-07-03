import * as http from "./baseService";

const BASE="/payments";

export const paymentService={

list(siteId){

return http.get(BASE,{site_id:siteId});

},

create(payload){

return http.post(BASE,payload);

},

approve(id){

return http.post(`${BASE}/${id}/approve`);

},

receipt(id){

return http.get(`${BASE}/${id}/receipt`);

}

}