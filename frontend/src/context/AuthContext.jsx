import {

    createContext,

    useContext,

    useState,

    useEffect,

} from "react";

import authService from "../services/authService";

const AuthContext = createContext(null);

export function AuthProvider({

    children,

}) {

    const [user, setUser] = useState(null);

    const [loading, setLoading] = useState(true);

    useEffect(() => {

        const existingUser = authService.getUser();

        if (existingUser) {

            setUser(existingUser);

        }

        setLoading(false);

    }, []);

    async function login(credentials) {

        const data = await authService.login(
            credentials
        );

        setUser(data.user);

        return data;

    }

    function logout() {

        authService.logout();

        setUser(null);

    }

    return (

        <AuthContext.Provider

            value={{

                user,

                loading,

                login,

                logout,

                isAuthenticated: !!user,

            }}

        >

            {children}

        </AuthContext.Provider>

    );

}

export function useAuth() {

    return useContext(AuthContext);

}