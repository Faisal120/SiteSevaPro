import React from "react";

export default function SSInput({

className="",

...props

}){

return(

<input

className={`

w-full

h-12

rounded-2xl

border

border-slate-200

bg-white

px-4

outline-none

focus:ring-4

focus:ring-blue-100

focus:border-blue-500

${className}

`}

{...props}

/>

)

}