import { api } from "@/lib/api";

export async function getSiteDetails(siteId){

    const { data } = await api.get(

        `/sites/${siteId}`

    );

    return data;

}