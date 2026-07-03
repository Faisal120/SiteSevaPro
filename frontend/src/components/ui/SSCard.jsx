import React from "react";

export default function SSCard({

children,

className=""

}){

return(

<div

className={`

ss-card

${className}

`}

>

{children}

</div>

)

}