import React from "react";
import {
    Door,
    Window,
    Bed,
    Sofa
} from "./CADsymbols";

export default function FloorPlanViewer({ layout }) {

    if (!layout?.rooms?.length) {
        return null;
    }

    const scale = 20;

    return (
        <div className="bg-white p-4 rounded-xl border overflow-auto">

            <svg
                width="1200"
                height="900"
                viewBox="0 0 1200 900"
            >

                <rect
                    x="20"
                    y="20"
                    width="1000"
                    height="800"
                    fill="white"
                    stroke="black"
                    strokeWidth="6"
                />

                {
                    layout.rooms.map((room, index) => {

                        const x = 50 + room.x * scale;
                        const y = 50 + room.y * scale;
                        const w = room.width * scale;
                        const h = room.height * scale;

                        return (
                            <g key={index}>

                                <rect
                                    x={x}
                                    y={y}
                                    width={w}
                                    height={h}
                                    fill="#fafafa"
                                    stroke="black"
                                    strokeWidth="3"
                                />

                                <text
                                    x={x + 10}
                                    y={y + 25}
                                    fontSize="14"
                                    fontWeight="bold"
                                >
                                    {room.name}
                                </text>

                                <text
                                    x={x + 10}
                                    y={y + 45}
                                    fontSize="11"
                                >
                                    {room.width} x {room.height} ft
                                </text>

                                {
                                    room.type === "bedroom" &&
                                    <Bed
                                        x={x + 20}
                                        y={y + 40}
                                    />
                                }

                                {
                                    room.type === "living" &&
                                    <Sofa
                                        x={x + 20}
                                        y={y + 50}
                                    />
                                }

                                <Door
                                    x={x + w - 30}
                                    y={y + h}
                                />

                                <Window
                                    x={x + 30}
                                    y={y}
                                />

                                <>
                                    <line
                                        x1="1080"
                                        y1="140"
                                        x2="1080"
                                        y2="80"
                                        stroke="red"
                                        strokeWidth="4"
                                    />

                                    <polygon
                                        points="1080,60 1070,80 1090,80"
                                        fill="red"
                                    />

                                    <text
                                        x="1072"
                                        y="50"
                                        fontSize="18"
                                        fontWeight="bold"
                                    >
                                        N
                                    </text>
                                </>

                                <text
                                    x="450"
                                    y="30"
                                    fontSize="20"
                                >
                                    {layout.plot_width} FEET
                                </text>

                                <text
                                    x="15"
                                    y="400"
                                    transform="rotate(-90 15 400)"
                                    fontSize="20"
                                >
                                    {layout.plot_length} FEET
                                </text>

                                <rect
                                    x="850"
                                    y="720"
                                    width="180"
                                    height="70"
                                    fill="white"
                                    stroke="black"
                                />

                                <text
                                    x="860"
                                    y="750"
                                    fontSize="14"
                                >
                                    Ground Floor Plan
                                </text>

                                <text
                                    x="860"
                                    y="770"
                                    fontSize="12"
                                >
                                    SiteSeva Pro
                                </text>


                            </g>
                        );
                    })
                }

            </svg>

        </div>
    );
}