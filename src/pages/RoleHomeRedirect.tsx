import { Navigate } from 'react-router-dom';
import { useAuth } from '@/auth/useAuth';

/**
 * Sends a user to the right home screen for the roles they hold.
 *
 * A person may be both a Manager and an Advisor. When that happens the advisor
 * dashboard wins, because someone enrolled in the programme needs to see their
 * own day first; the manager section is one click away in the navigation.
 */
export function RoleHomeRedirect() {
  const { isAdvisor, isManagerOrAdmin, isAdmin } = useAuth();

  if (isAdvisor) return <Navigate to="/today" replace />;
  if (isManagerOrAdmin) return <Navigate to="/manage" replace />;
  if (isAdmin) return <Navigate to="/admin/content" replace />;
  return <Navigate to="/no-access" replace />;
}
