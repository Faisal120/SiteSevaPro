import React from "react";

import { ChevronDown } from "lucide-react";

import {
DropdownMenu,
DropdownMenuTrigger,
DropdownMenuContent,
DropdownMenuItem,
DropdownMenuSeparator,
DropdownMenuLabel
} from "@/components/ui/dropdown-menu";

import {
Avatar,
AvatarFallback
} from "@/components/ui/avatar";

export default function UserMenu({

user,

logout,

nav

}){

const initials=(

user?.full_name||

user?.email||

"U"

).slice(0,2).toUpperCase();

return(

<DropdownMenu>

<DropdownMenuTrigger asChild>

<button

className="

flex

items-center

gap-3

rounded-2xl

border

border-slate-200

bg-white

px-3

h-12

hover:border-blue-500

transition

"

>

<Avatar className="h-9 w-9">

<AvatarFallback

className="

bg-gradient-to-br

from-blue-600

to-blue-800

text-white

font-bold

"

>

{initials}

</AvatarFallback>

</Avatar>

<div className="hidden lg:flex flex-col items-start">

<span className="text-sm font-semibold">

{user?.full_name}

</span>

<span className="text-xs text-blue-600">

{user?.role}

</span>

</div>

<ChevronDown size={18}/>

</button>

</DropdownMenuTrigger>

<DropdownMenuContent align="end">

<DropdownMenuLabel>

{user?.email}

</DropdownMenuLabel>

<DropdownMenuSeparator/>

<DropdownMenuItem

onClick={()=>nav("/app/settings")}

>

Settings

</DropdownMenuItem>

<DropdownMenuSeparator/>

<DropdownMenuItem

onClick={()=>{

logout();

nav("/login");

}}

>

Logout

</DropdownMenuItem>

</DropdownMenuContent>

</DropdownMenu>

)

}