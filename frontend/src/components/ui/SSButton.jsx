import React from "react";

export default function SSButton({

children,

className="",

...props

}){

return(

<button

className={`

rounded-2xl

bg-blue-600

hover:bg-blue-700

text-white

font-semibold

px-5

h-12

transition-all

duration-300

hover:scale-[1.02]

shadow-lg

${className}

`}

{...props}

>

{children}

</button>

)

}