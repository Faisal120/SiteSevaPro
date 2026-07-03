import SiteCard from "./SiteCard";
import EmptySites from "./EmptySites";
import SiteSkeleton from "./SiteSkeleton";

export default function SiteGrid({
    sites = [],
    loading = false
}) {

    if (loading) {
        return <SiteSkeleton />;
    }

    if (!sites.length) {
        return <EmptySites />;
    }

    return (

        <div className="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-6">

            {

                sites.map(site => (

                    <SiteCard

                        key={site._id}

                        site={site}

                    />

                ))

            }

        </div>

    );

}