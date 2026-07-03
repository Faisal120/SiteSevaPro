import React from "react";
import { useParams } from "react-router-dom";

import useSiteDetails from "@/hooks/useSiteDetails";

import SiteHero from "@/components/siteDetails/SiteHero";
import SiteOverviewCards from "@/components/siteDetails/SiteOverviewCards";
import SiteProgressTimeline from "@/components/siteDetails/SiteProgressTimeline";
import SiteActivityTimeline from "@/components/siteDetails/SiteActivityTimeline";
import SiteFinancialSummary from "@/components/siteDetails/SiteFinancialSummary";
import SitePhotoGallery from "@/components/siteDetails/SitePhotoGallery";
import SiteDocuments from "@/components/siteDetails/SiteDocuments";
import AISiteInsights from "@/components/siteDetails/AISiteInsights";

export default function SiteDetail() {

    const { siteId } = useParams();

    <SiteProvider siteId={id}>

        <SiteDetailContent />

    </SiteProvider>

    if (loading) {

        return (

            <div className="flex h-[70vh] items-center justify-center">

                Loading...

            </div>

        );

    }

    if (error) {

        return (

            <div className="text-center py-20">

                Failed to load project.

            </div>

        );

    }

    return (

        <div className="space-y-6">

            <SiteHero />

            <SiteDetailsTabs

                site={site}

                labour={labour}

                materials={materials}

                payments={payments}

                reports={reports}

                tasks={tasks}

                ai={site.ai_insights}

                user={user}

                actions={{

                    completeTask,

                    runAI

                }}

            />

            <SiteOverviewCards

                site={site}

            />

            <div className="grid xl:grid-cols-2 gap-6">

                <SiteProgressTimeline

                    site={site}

                />

                <SiteFinancialSummary

                    site={site}

                />

            </div>

            <div className="grid xl:grid-cols-3 gap-6">

                <div className="xl:col-span-2">

                    <SiteActivityTimeline

                        activities={site?.activities || []}

                    />

                </div>

                <AISiteInsights

                    insights={site?.ai_insights || []}

                />

            </div>

            <div className="grid xl:grid-cols-2 gap-6">

                <SitePhotoGallery

                    photos={site?.photos || []}

                />

                <SiteDocuments

                    documents={site?.documents || []}

                />

            </div>

        </div>

    );
}