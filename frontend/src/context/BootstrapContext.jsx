import React, {
    createContext,
    useContext,
    useEffect,
    useState
} from "react";

import { getBootstrapData } from "@/services/bootstrapServices";

const BootstrapContext = createContext();

export function BootstrapProvider({ children }) {

    const [loading, setLoading] = useState(true);

    const [bootstrap, setBootstrap] = useState({

        company: null,

        dashboard: null,

        notifications: 0,

        subscription: null,

        weather: null,

        stats: null

    });

    async function refreshBootstrap() {

        try {

            const data = await getBootstrapData();

            setBootstrap(data);

        }

        catch (err) {

            console.error("Bootstrap Error", err);

        }

        finally {

            setLoading(false);

        }

    }

    useEffect(() => {

        refreshBootstrap();

    }, []);

    return (

        <BootstrapContext.Provider

            value={{

                loading,

                bootstrap,

                refreshBootstrap

            }}

        >

            {children}

        </BootstrapContext.Provider>

    );

}

export function useBootstrap() {

    return useContext(BootstrapContext);

}