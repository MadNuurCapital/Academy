import { Link } from 'react-router-dom';
import { CalendarCheck, Map } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState } from '@/components/ui/States';

/**
 * The advisor's home screen.
 *
 * Phase 1 renders the shell and the not-yet-enrolled state. The live cards —
 * today's learning, attendance status, drift against target, next action —
 * arrive in Phase 2 once enrolment and the roadmap exist.
 *
 * Kept deliberately sparse by design: conditional cards render only when they
 * have something to say, so an advisor with nothing outstanding sees a clean
 * screen with one clear action rather than a wall of empty panels.
 */
export function AdvisorDashboard() {
  const { profile } = useAuth();
  const firstName = profile?.full_name.split(' ')[0] ?? 'there';

  return (
    <div className="space-y-6">
      <div>
        <h1>Good day, {firstName}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Here is what needs your attention today.
        </p>
      </div>

      <EmptyState
        icon={Map}
        title="You are not enrolled in a programme yet"
        description="Once your manager enrols you, your 30-day roadmap will appear here with today's learning, your attendance and your next action."
      />

      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <CardBody className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-medium text-foreground">
              <Map className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
              Roadmap
            </div>
            <p className="text-sm text-muted-foreground">
              See all 30 days of the programme and what each one covers.
            </p>
            <Link to="/roadmap" className="inline-block text-sm font-medium text-accent hover:underline">
              View roadmap
            </Link>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-medium text-foreground">
              <CalendarCheck className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
              Attendance
            </div>
            <p className="text-sm text-muted-foreground">
              Your attendance is recorded by your manager each working day.
            </p>
            <Link to="/attendance" className="inline-block text-sm font-medium text-accent hover:underline">
              View attendance
            </Link>
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
