import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './useAuth';
import { FullPageLoading } from '@/components/ui/States';
import type { AppRole } from '@/types/database';

/**
 * Route guard.
 *
 * The order of the checks below is what makes a hard refresh on a deep
 * protected URL work correctly:
 *
 *   1. While the session is still resolving, render a loader — never a
 *      redirect. Redirecting here is the bug that sends a refreshing user back
 *      to the login page and loses where they were.
 *   2. Only once resolution has finished does an absent session mean the user
 *      is genuinely signed out.
 *   3. The attempted URL is preserved so the user lands back where they meant
 *      to be after signing in.
 *
 * These checks are a user-interface convenience. The real boundary is Row Level
 * Security in the database: a user who defeats this component still cannot read
 * a row the policies do not permit.
 */
export function ProtectedRoute({ allowedRoles }: { allowedRoles?: AppRole[] }) {
  const { session, roles, isResolving, profile } = useAuth();
  const location = useLocation();

  if (isResolving) {
    return <FullPageLoading />;
  }

  if (!session) {
    return <Navigate to="/login" replace state={{ from: location.pathname + location.search }} />;
  }

  // A valid session with no profile row means the account is half-created.
  // Sending them to the login page would loop, so route to a page that explains.
  if (!profile) {
    return <Navigate to="/no-access" replace />;
  }

  if (allowedRoles && !allowedRoles.some((role) => roles.includes(role))) {
    return <Navigate to="/no-access" replace />;
  }

  return <Outlet />;
}
