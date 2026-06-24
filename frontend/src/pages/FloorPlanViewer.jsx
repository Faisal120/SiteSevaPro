import React from "react";

export default function FloorPlanViewer({ plan }) {

  if (!plan) return null;

  const scale = 20;

  return (
    <div
      className="bg-white border rounded-xl p-4 overflow-auto"
    >
      <div
        style={{
          position: "relative",
          width: plan.plot_width * scale,
          height: plan.plot_length * scale,
          border: "4px solid black",
          background: "#fff"
        }}
      >
        {plan.rooms.map((room, index) => (

          <div
            key={index}
            style={{
              position: "absolute",
              left: room.x * scale,
              top: room.y * scale,
              width: room.width * scale,
              height: room.height * scale,
              border: "2px solid black",
              background: "#f8fafc",
              padding: "4px",
              fontSize: "12px",
              overflow: "hidden"
            }}
          >
            <strong>
              {room.name}
            </strong>

            <br />

            {room.width} × {room.height} ft
          </div>

        ))}
      </div>
    </div>
  );
}