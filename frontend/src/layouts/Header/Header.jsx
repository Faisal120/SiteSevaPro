import React from "react";

import SearchBar from "./SearchBar";
import HeaderActions from "./HeaderActions";
import UserMenu from "./UserMenu";

export default function Header({

    user,
    theme,
    toggle,
    nav,
    logout,
    notificationCount = 0,
    weather

}){

    const hour = new Date().getHours();

    let greeting = "Good Evening";

    if(hour < 12){

        greeting = "Good Morning";

    }

    else if(hour < 17){

        greeting = "Good Afternoon";

    }

    return(

        <header
            className="
                sticky
                top-0
                z-40
                h-20
                bg-white/95
                backdrop-blur-xl
                border-b
                border-slate-200
                px-8
                flex
                items-center
                justify-between
                shadow-sm
            "
        >

            {/* LEFT */}

            <div
                className="
                    flex
                    items-center
                    gap-8
                    flex-1
                "
            >

                <div>

                    <p
                        className="
                            text-sm
                            text-slate-500
                        "
                    >

                        {greeting},

                    </p>

                    <h1
                        className="
                            text-2xl
                            font-bold
                            text-slate-900
                        "
                    >

                        {user?.full_name}

                    </h1>

                    <p
                        className="
                            text-xs
                            text-slate-400
                            mt-1
                        "
                    >

                        Construction Operating System

                    </p>

                </div>

                <SearchBar/>

            </div>

            {/* RIGHT */}

            <div
                className="
                    flex
                    items-center
                    gap-4
                "
            >

                <HeaderActions

                    theme={theme}

                    toggle={toggle}

                    nav={nav}

                    notificationCount={notificationCount}

                    weather={weather}

                />

                <UserMenu

                    user={user}

                    logout={logout}

                    nav={nav}

                />

            </div>

        </header>

    )

}