import { useQuery } from "@tanstack/react-query";
import dashboardService from "../services/dashboardService";

export default function useDashboard() {

    const query = useQuery({

        queryKey: ["dashboard"],

        queryFn: dashboardService.getDashboard,

        staleTime: 1000 * 60 * 5,

        refetchOnWindowFocus: false,

    });

    return {

        stats: query.data?.stats ?? null,

        sites: query.data?.sites ?? [],

        team: query.data?.team ?? [],

        latestPhotos: query.data?.latestPhotos ?? [],

        loading: query.isLoading,

        error: query.error,

        refresh: query.refetch,

        isFetching: query.isFetching,

    };

}