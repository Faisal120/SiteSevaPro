import * as http from "./baseService";

const BASE="/ai";

export const aiService={

insights(siteId){

return http.get(`${BASE}/insights`,{

site_id:siteId

});

},

chat(payload){

return http.post(`${BASE}/chat`,payload);

},

forecast(siteId){

return http.get(`${BASE}/forecast`,{

site_id:siteId

});

}

}