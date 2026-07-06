import { useMutation } from "@tanstack/react-query";

import { useAuth } from "@/lib/auth";

export function useLogin() {

    const auth = useAuth();

    return useMutation({

        mutationFn: auth.login,

    });

}