import {
    Tabs,
    TabsContent,
    TabsList,
    TabsTrigger
} from "@/components/ui/tabs";

import OverviewTab from "./tabs/OverviewTab";
import LabourTab from "./tabs/LabourTab";
import MaterialsTab from "./tabs/MaterialsTab";
import PaymentsTab from "./tabs/PaymentsTab";
import ReportsTab from "./tabs/ReportsTab";
import TasksTab from "./tabs/TasksTab";
import AITab from "./tabs/AITab";

export default function SiteDetailsTabs({

    site,

    labour,

    materials,

    payments,

    reports,

    tasks,

    user,

    ai,

    actions

}) {

    return (

        <Tabs

            defaultValue="overview"

            className="space-y-6"

        >

            <TabsList className="grid grid-cols-7 rounded-2xl bg-white border border-slate-200 p-1">

                <TabsTrigger value="overview">

                    Overview

                </TabsTrigger>

                <TabsTrigger value="labour">

                    Labour

                </TabsTrigger>

                <TabsTrigger value="materials">

                    Materials

                </TabsTrigger>

                <TabsTrigger value="payments">

                    Payments

                </TabsTrigger>

                <TabsTrigger value="reports">

                    Reports

                </TabsTrigger>

                <TabsTrigger value="tasks">

                    Tasks

                </TabsTrigger>

                <TabsTrigger value="ai">

                    AI

                </TabsTrigger>

            </TabsList>

            <TabsContent value="overview">

                <OverviewTab

                    site={site}

                />

            </TabsContent>

            <TabsContent value="labour">

                <LabourTab

                    labour={labour}

                />

            </TabsContent>

            <TabsContent value="materials">

                <MaterialsTab

                    materials={materials}

                />

            </TabsContent>

            <TabsContent value="payments">

                <PaymentsTab

                    payments={payments}

                />

            </TabsContent>

            <TabsContent value="reports">

                <ReportsTab

                    reports={reports}

                />

            </TabsContent>

            <TabsContent value="tasks">

                <TasksTab

                    tasks={tasks}

                    actions={actions}

                />

            </TabsContent>

            <TabsContent value="ai">

                <AITab

                    ai={ai}

                    site={site}

                    actions={actions}

                />

            </TabsContent>

        </Tabs>

    )

}