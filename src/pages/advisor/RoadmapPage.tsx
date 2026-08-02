import { Link } from 'react-router-dom';
import { Check, Lock } from 'lucide-react';
import { useEnrolmentDays, useMyEnrolment } from '@/api/enrolments';
import { Panel } from '@/components/ui/Panel';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { cn } from '@/lib/cn';

/**
 * The mission map: the whole 30-day journey, grouped by phase.
 *
 * Locked days are shown rather than hidden. A new advisor benefits from seeing
 * where the programme is going, even though the content stays unreadable until
 * they reach it — RLS enforces that, and the titles here come from
 * programme_days, which is published curriculum metadata rather than module
 * content.
 *
 * It is a list, not a node graph. A branching map looks impressive on a laptop
 * and is unusable on the phone where advisors actually read, so the spine runs
 * vertically and every row is a full-width target at any width.
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
        <h1>Mission map</h1>
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
        <h1>Mission map</h1>
        <p className="mt-1 text-sm text-muted-foreground tabular">
          {completed} of {days.length} days cleared
        </p>
      </div>

      {phases.map((group, groupIndex) => {
        const cleared = group.days.filter((day) => day.status === 'complete').length;
        const isPhaseComplete = cleared === group.days.length;
        const isPhaseActive = group.days.some(
          (day) => day.day_number === enrolment.current_day,
        );

        return (
          <section key={group.phase} className="space-y-3">
            {/* The phase gate. */}
            <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
              <h2 className="flex items-center gap-2 text-sm font-semibold uppercase tracking-console">
                <span
                  className={cn(
                    'inline-block h-1.5 w-1.5 rounded-full',
                    isPhaseComplete
                      ? 'bg-success'
                      : isPhaseActive
                        ? 'bg-highlight'
                        : 'bg-white/20',
                  )}
                  aria-hidden="true"
                />
                <span className={isPhaseActive ? 'text-foreground' : 'text-muted-foreground'}>
                  {group.phase}
                </span>
              </h2>
              <span className="console-label tabular">
                {cleared} of {group.days.length} cleared
              </span>
            </div>

            {/* The spine. Rows hang off a single vertical rule. */}
            <div className="relative space-y-2 pl-7">
              <span
                className="absolute bottom-3 left-[11px] top-3 w-px bg-white/[0.13]"
                aria-hidden="true"
              />

              {group.days.map((day, dayIndex) => {
                const isLocked = day.status === 'locked';
                const isComplete = day.status === 'complete';
                const isToday = day.day_number === enrolment.current_day;

                const node = (
                  <span
                    className={cn(
                      'absolute left-0 top-1/2 z-10 flex h-[22px] w-[22px] -translate-x-[11px] -translate-y-1/2 items-center justify-center rounded-full border',
                      isComplete && 'border-success/40 bg-success/20 text-success',
                      isToday && !isComplete && 'border-highlight bg-highlight text-highlight-foreground',
                      !isComplete && !isToday && 'border-white/15 bg-background text-muted-foreground',
                    )}
                    aria-hidden="true"
                  >
                    {isComplete ? (
                      <Check className="h-3 w-3" strokeWidth={3} />
                    ) : isLocked ? (
                      <Lock className="h-2.5 w-2.5" />
                    ) : (
                      <span className="h-1.5 w-1.5 rounded-full bg-current" />
                    )}
                  </span>
                );

                const body = (
                  <Panel
                    interactive={!isLocked}
                    tone={isToday ? 'current' : 'neutral'}
                    className={cn(
                      'flex items-center gap-3 px-4 py-3',
                      isLocked && 'opacity-55',
                    )}
                  >
                    <div className="min-w-0 flex-1">
                      {/* Deliberately not truncated. On a phone the title is
                          the only thing that tells an advisor what a day is
                          about, and clipping it to fit the status label beside
                          it trades the content for the label. It wraps. */}
                      <p className={cn('text-sm', isToday ? 'font-semibold' : 'font-medium')}>
                        <span className="tabular text-muted-foreground">
                          {String(day.day_number).padStart(2, '0')}
                        </span>
                        <span className="mx-2 text-white/15" aria-hidden="true">
                          /
                        </span>
                        {day.programme_days?.title ?? `Day ${day.day_number}`}
                      </p>
                      {isToday && (
                        <p className="text-xs font-medium text-highlight">Today</p>
                      )}
                      {day.unlocked_by_override && (
                        <p className="text-xs text-warning">Unlocked by your manager</p>
                      )}
                    </div>
                    <span
                      className={cn(
                        'console-label shrink-0',
                        isComplete && 'text-success',
                        isToday && !isComplete && 'text-highlight',
                      )}
                    >
                      {isComplete ? 'Cleared' : isLocked ? 'Locked' : 'Ready'}
                    </span>
                  </Panel>
                );

                // Locked days are not links — following one would only produce
                // an empty screen, since RLS returns no modules for it.
                return (
                  <div key={day.id} className="relative">
                    {node}
                    {isLocked ? (
                      body
                    ) : (
                      <Link
                        to={`/day/${day.day_number}`}
                        className="block animate-panel-in"
                        style={{
                          animationDelay: `${Math.min(groupIndex * 2 + dayIndex, 10) * 25}ms`,
                        }}
                      >
                        {body}
                      </Link>
                    )}
                  </div>
                );
              })}
            </div>
          </section>
        );
      })}
    </div>
  );
}
