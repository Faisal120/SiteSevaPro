import { Navigate } from "react-router-dom";
import { useAuth } from "@/lib/auth";

export default function PublicRoute({ children }) {
    const { user, loading } = useAuth();

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center">
                Loading...
            </div>
        );
    }

    if (user) {
        return <Navigate to="/app/dashboard" replace />;
    }

    return children;
}