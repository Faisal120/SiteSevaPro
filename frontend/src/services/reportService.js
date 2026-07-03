import * as http from "./baseService";

const BASE="/reports";

export const reportService={

list(siteId){

return http.get(BASE,{site_id:siteId});

},

create(payload){

return http.post(BASE,payload);

},

download(id){

return http.get(`${BASE}/${id}/pdf`);

}

}