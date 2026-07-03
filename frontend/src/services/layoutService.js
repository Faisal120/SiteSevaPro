import * as http from "./baseService";

const BASE="/labour";

export const labourService={

getAll(siteId){

return http.get(BASE,{site_id:siteId});

},

create(payload){

return http.post(BASE,payload);

},

attendance(payload){

return http.post(`${BASE}/attendance`,payload);

},

wallet(id){

return http.get(`${BASE}/${id}/wallet`);

},

payments(id){

return http.get(`${BASE}/${id}/payments`);

}

}