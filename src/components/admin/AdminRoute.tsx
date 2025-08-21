import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { isAdminAuthenticated, validateAdminSession } from "@/lib/admin-auth";
import { Loader2 } from "lucide-react";

interface AdminRouteProps {
  children: React.ReactNode;
}

export default function AdminRoute({ children }: AdminRouteProps) {
  const [isValidating, setIsValidating] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const checkAuth = async () => {
      try {
        // Check if admin is authenticated
        if (!isAdminAuthenticated()) {
          navigate('/admin/login');
          return;
        }

        // Validate session
        if (!validateAdminSession()) {
          navigate('/admin/login');
          return;
        }

        setIsValidating(false);
      } catch (error) {
        console.error('Admin route validation error:', error);
        navigate('/admin/login');
      }
    };

    checkAuth();
  }, [navigate]);

  if (isValidating) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Validating Admin Access...</p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
