import React from "react";

export default function FloorPlanViewer({plan}) {

  return (

    <div
      style={{
        position:"relative",
        width:"1000px",
        height:"700px",
        border:"2px solid black"
      }}
    >

      {plan.rooms.map(room=>(
        <div
          key={room.name}
          style={{
            position:"absolute",
            left:room.x*20,
            top:room.y*20,
            width:room.width*20,
            height:room.height*20,
            border:"2px solid black"
          }}
        >
          {room.name}
        </div>
      ))}

    </div>
  );
}