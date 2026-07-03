import { useCallback, useEffect, useState } from "react";
import { getSiteDetails } from "@/services/siteDetailsService";

export default function useSiteDetails(siteId) {

    const [site, setSite] = useState(null);

    const [loading, setLoading] = useState(true);

    const [error, setError] = useState(null);

    const loadSite = useCallback(async () => {

        try {

            setLoading(true);

            const data = await getSiteDetails(siteId);

            setSite(data);

            setError(null);

        }

        catch (err) {

            console.error(err);

            setError(err);

        }

        finally {

            setLoading(false);

        }

    }, [siteId]);

    useEffect(() => {

        if(siteId){

            loadSite();

        }

    }, [siteId, loadSite]);

    return {

        site,

        loading,

        error,

        refresh: loadSite

    };

}