import { useMutation } from "@tanstack/react-query";

import { useAuth } from "../contexts/AuthContext";

export function useLogin() {

    const auth = useAuth();

    return useMutation({

        mutationFn: auth.login,

    });

}