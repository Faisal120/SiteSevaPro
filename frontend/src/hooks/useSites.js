import { useEffect, useMemo, useState } from "react";
import { getSites } from "@/services/siteService";

export default function useSites() {

    const [sites, setSites] = useState([]);

    const [loading, setLoading] = useState(true);

    const [search, setSearch] = useState("");

    const [filter, setFilter] = useState("All");

    async function loadSites() {

        try {

            setLoading(true);

            const data = await getSites();

            setSites(data);

        } finally {

            setLoading(false);

        }

    }

    useEffect(() => {

        loadSites();

    }, []);

    const filteredSites = useMemo(() => {

        let list = [...sites];

        if (filter !== "All") {

            list = list.filter(

                site =>

                site.status?.toLowerCase() === filter.toLowerCase()

            );

        }

        if (search.trim()) {

            const keyword = search.toLowerCase();

            list = list.filter(site =>

                site.site_name?.toLowerCase().includes(keyword)

                ||

                site.client_name?.toLowerCase().includes(keyword)

                ||

                site.supervisor_name?.toLowerCase().includes(keyword)

                ||

                site.location?.toLowerCase().includes(keyword)

            );

        }

        return list;

    }, [sites, filter, search]);

    const stats = useMemo(() => {

        return {

            active:

                sites.filter(s => s.status === "ACTIVE").length,

            completed:

                sites.filter(s => s.status === "COMPLETED").length,

            delayed:

                sites.filter(s => s.status === "DELAYED").length,

            value:

                "₹" +

                sites.reduce(

                    (t, s) => t + (s.project_value || 0),

                    0

                ).toLocaleString("en-IN")

        };

    }, [sites]);

    return {

        sites: filteredSites,

        loading,

        stats,

        search,

        setSearch,

        filter,

        setFilter,

        refresh: loadSites

    };

}