import { Navigate } from 'react-router-dom';
import { useAuth } from '@/auth/useAuth';

/**
 * Sends a user to the right home screen for the roles they hold.
 *
 * This is also where the logo goes when it is clicked, so "home" is defined
 * once here rather than guessed at separately by everything that wants to send
 * someone there.
 *
 * A person may hold more than one role. An advisor wins, because someone
 * enrolled in the programme needs to see their own day first; the manager
 * section is one click away in the navigation.
 *
 * The manager check asks for the manager role specifically rather than using
 * `isManagerOrAdmin`. That helper is true for admins as well, so the admin
 * branch below used to be unreachable — an admin who was not also a manager was
 * quietly sent to the manager dashboard. It worked, because the manager routes
 * admit admins, but it was not what the code claimed to do.
 */
export function RoleHomeRedirect() {
  const { isAdvisor, isAdmin, hasRole } = useAuth();

  if (isAdvisor) return <Navigate to="/today" replace />;
  if (hasRole('manager')) return <Navigate to="/manage" replace />;
  if (isAdmin) return <Navigate to="/admin" replace />;
  return <Navigate to="/no-access" replace />;
}
