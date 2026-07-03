import React from "react";

export default function DashboardGrid({ children }) {
    return (
        <div
            className="
                grid
                grid-cols-12
                gap-6
                mt-8
            "
        >
            {children}
        </div>
    );
}

export function GridLeft({ children }) {
    return (
        <div
            className="
                col-span-12
                xl:col-span-8
                space-y-6
            "
        >
            {children}
        </div>
    );
}

export function GridRight({ children }) {
    return (
        <div
            className="
                col-span-12
                xl:col-span-4
                space-y-6
            "
        >
            {children}
        </div>
    );
}