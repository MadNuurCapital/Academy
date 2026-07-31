import { Users } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { EmptyState } from '@/components/ui/States';

/**
 * The manager's home screen.
 *
 * Exists to answer one question: who needs my attention today. Phase 5 fills in
 * the priority-ordered sections — attendance not recorded, needs attention,
 * awaiting me, today, all advisors.
 */
export function ManagerDashboard() {
  const { profile } = useAuth();
  const firstName = profile?.full_name.split(' ')[0] ?? 'there';

  return (
    <div className="space-y-6">
      <div>
        <h1>Good day, {firstName}</h1>
        <p className="mt-1 text-sm text-muted-foreground">Who needs your attention today.</p>
      </div>

      <EmptyState
        icon={Users}
        title="No advisors enrolled yet"
        description="Once advisors are enrolled, this dashboard shows who is behind schedule, whose attendance is outstanding, and what is waiting on your review."
      />
    </div>
  );
}
