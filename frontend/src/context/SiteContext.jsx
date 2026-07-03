import React, {
    createContext,
    useContext,
    useEffect,
    useState,
    useCallback
} from "react";

import {

    getSiteDetails

} from "@/services/siteDetailsService";

const SiteContext = createContext();

export function SiteProvider({

    siteId,

    children

}) {

    const [site, setSite] = useState(null);

    const [loading, setLoading] = useState(true);

    const [error, setError] = useState(null);

    const refresh = useCallback(async () => {

        try {

            setLoading(true);

            const data = await getSiteDetails(siteId);

            setSite(data);

            setError(null);

        }

        catch (err) {

            setError(err);

        }

        finally {

            setLoading(false);

        }

    }, [siteId]);

    useEffect(() => {

        if (siteId) {

            refresh();

        }

    }, [siteId, refresh]);

    return (

        <SiteContext.Provider

            value={{

                site,

                loading,

                error,

                refresh

            }}

        >

            {children}

        </SiteContext.Provider>

    )

}

export function useSite() {

    return useContext(SiteContext);

}