import { useAuth } from '@/auth/useAuth';
import { AdvisorLayout } from './AdvisorLayout';
import { ManagerLayout } from './ManagerLayout';
import { AdminLayout } from './AdminLayout';

/**
 * The shell for /profile, which every signed-in user can reach.
 *
 * Profile is the one screen that belongs to no role, so it borrows whichever
 * navigation the person already knows: a manager editing their own name should
 * still see the manager sidebar rather than being dropped into an advisor one.
 */
export function ProfileLayout() {
  const { isAdmin, isManagerOrAdmin } = useAuth();
  if (isAdmin) return <AdminLayout />;
  if (isManagerOrAdmin) return <ManagerLayout />;
  return <AdvisorLayout />;
}
