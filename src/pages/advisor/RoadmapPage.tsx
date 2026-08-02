import { Link } from 'react-router-dom';
import { CheckCircle2, Circle, Lock } from 'lucide-react';
import { useEnrolmentDays, useMyEnrolment } from '@/api/enrolments';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { DayBadge } from '@/components/ui/StatusBadge';
import { cn } from '@/lib/cn';

/**
 * The whole 30-day journey, grouped by phase.
 *
 * Locked days are shown rather than hidden: a new advisor benefits from seeing
 * where the programme is going, even though the content itself stays
 * unreadable until they reach it. RLS enforces that — the titles here come from
 * programme_days, which is published curriculum metadata, not module content.
 */
export function RoadmapPage() {
  const { data: enrolment, isLoading: enrolmentLoading } = useMyEnrolment();
  const { data: days, isLoading, error, refetch } = useEnrolmentDays(enrolment?.id);

  if (enrolmentLoading || isLoading) return <LoadingState label="Loading your roadmap…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load your roadmap"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!enrolment || !days || days.length === 0) {
    return (
      <div className="space-y-6">
        <h1>My roadmap</h1>
        <EmptyState
          title="No roadmap yet"
          description="Your roadmap appears here once your manager enrols you in the programme."
        />
      </div>
    );
  }

  // Preserve curriculum order while grouping, so phases appear in the order the
  // programme runs rather than alphabetically.
  const phases: { phase: string; days: typeof days }[] = [];
  for (const day of days) {
    const phase = day.programme_days?.phase ?? 'Programme';
    const existing = phases.find((group) => group.phase === phase);
    if (existing) {
      existing.days.push(day);
    } else {
      phases.push({ phase, days: [day] });
    }
  }

  const completed = days.filter((day) => day.status === 'complete').length;

  return (
    <div className="space-y-6">
      <div>
        <h1>My roadmap</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {completed} of {days.length} days complete
        </p>
      </div>

      {phases.map((group) => (
        <section key={group.phase} className="space-y-3">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            {group.phase}
          </h2>
          <div className="space-y-2">
            {group.days.map((day) => {
              const isLocked = day.status === 'locked';
              const isToday = day.day_number === enrolment.current_day;
              const Icon =
                day.status === 'complete' ? CheckCircle2 : isLocked ? Lock : Circle;

              const content = (
                <Card
                  className={cn(
                    'transition-colors',
                    isLocked ? 'opacity-60' : 'hover:border-accent/40',
                    // The tan edge marks where the advisor is now. It is
                    // decorative: the "Today" label below carries the meaning,
                    // so nothing is lost if the colour is not perceived.
                    isToday && 'border-l-4 border-l-highlight',
                  )}
                >
                  <CardBody className="flex items-center gap-3 py-3">
                    <Icon
                      className={cn(
                        'h-5 w-5 shrink-0',
                        day.status === 'complete'
                          ? 'text-success'
                          : isLocked
                            ? 'text-muted-foreground'
                            : 'text-accent',
                      )}
                      aria-hidden="true"
                    />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium">
                        Day {day.day_number}
                        {day.programme_days?.title ? ` · ${day.programme_days.title}` : ''}
                      </p>
                      {isToday && (
                        <p className="text-xs font-medium text-muted-foreground">Today</p>
                      )}
                      {day.unlocked_by_override && (
                        <p className="text-xs text-warning">Unlocked by your manager</p>
                      )}
                    </div>
                    <DayBadge state={day.status} />
                  </CardBody>
                </Card>
              );

              // Locked days are not links — following one would only produce an
              // empty screen, since RLS returns no modules for it.
              return isLocked ? (
                <div key={day.id}>{content}</div>
              ) : (
                <Link key={day.id} to={`/day/${day.day_number}`} className="block">
                  {content}
                </Link>
              );
            })}
          </div>
        </section>
      ))}
    </div>
  );
}
