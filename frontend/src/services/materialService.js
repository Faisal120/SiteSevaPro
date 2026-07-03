import * as http from "./baseService";

const BASE="/materials";

export const materialService={

getAll(siteId){

return http.get(BASE,{site_id:siteId});

},

create(payload){

return http.post(BASE,payload);

},

updateStock(id,payload){

return http.put(`${BASE}/${id}/stock`,payload);

},

ledger(id){

return http.get(`${BASE}/${id}/ledger`);

}

}