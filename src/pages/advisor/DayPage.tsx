import { Link, useParams } from 'react-router-dom';
import { BookOpen, CheckCircle2, Clock, HelpCircle, Lock } from 'lucide-react';
import { useEnrolmentDays, useMyEnrolment } from '@/api/enrolments';
import { useModulesForDay } from '@/api/content';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatMinutes } from '@/lib/formatDate';
import { cn } from '@/lib/cn';

export function DayPage() {
  const { dayNumber } = useParams<{ dayNumber: string }>();
  const parsedDay = Number(dayNumber);

  const { data: enrolment, isLoading: enrolmentLoading } = useMyEnrolment();
  const { data: days, isLoading: daysLoading } = useEnrolmentDays(enrolment?.id);

  const day = days?.find((candidate) => candidate.day_number === parsedDay);
  const {
    data: modules,
    isLoading: modulesLoading,
    error,
    refetch,
  } = useModulesForDay(day?.programme_day_id, enrolment?.id);

  if (!Number.isInteger(parsedDay) || parsedDay < 1) {
    return <ErrorState title="That is not a valid programme day" />;
  }

  if (enrolmentLoading || daysLoading) return <LoadingState label="Loading the day…" />;

  if (!enrolment || !day) {
    return (
      <EmptyState
        title="Day not found"
        description="This day is not part of your programme."
        action={
          <Link to="/roadmap" className="text-sm font-medium text-accent hover:underline">
            Back to my roadmap
          </Link>
        }
      />
    );
  }

  // Locked days are handled here rather than left to produce an empty module
  // list, so the advisor gets an explanation instead of a blank screen.
  if (day.status === 'locked') {
    return (
      <div className="space-y-6">
        <h1>Day {day.day_number}</h1>
        <EmptyState
          icon={Lock}
          title="This day is not open yet"
          description="Days unlock one at a time. Finish the day you are on — including passing its quiz — and this one will open."
          action={
            <Link to="/roadmap" className="text-sm font-medium text-accent hover:underline">
              Back to my roadmap
            </Link>
          }
        />
      </div>
    );
  }

  if (modulesLoading) return <LoadingState label="Loading today's modules…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load this day"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  const totalMinutes = (modules ?? []).reduce((total, module) => total + module.est_minutes, 0);

  return (
    <div className="space-y-6">
      <div>
        <p className="text-sm font-medium text-muted-foreground">
          {day.programme_days?.phase ?? 'Programme'}
        </p>
        <h1>
          Day {day.day_number}
          {day.programme_days?.title ? ` · ${day.programme_days.title}` : ''}
        </h1>
        {day.programme_days?.description && (
          <p className="mt-2 text-sm text-muted-foreground">{day.programme_days.description}</p>
        )}
        {totalMinutes > 0 && (
          <p className="mt-2 inline-flex items-center gap-1.5 text-sm text-muted-foreground">
            <Clock className="h-4 w-4" aria-hidden="true" />
            About {formatMinutes(totalMinutes)} in total
          </p>
        )}
      </div>

      {!modules || modules.length === 0 ? (
        <EmptyState
          title="No modules published for this day yet"
          description="Your administrator has not published content for this day. Speak to your manager if you were expecting something here."
        />
      ) : (
        <div className="space-y-3">
          {modules.map((module) => {
            const isComplete = module.progress?.status === 'complete';
            const inProgress = module.progress?.status === 'in_progress';

            return (
              <Link key={module.id} to={`/module/${module.id}`} className="block">
                <Card className="transition-colors hover:border-accent/40">
                  <CardBody className="space-y-2">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <div className="flex flex-wrap items-center gap-2">
                          <h2 className="text-base font-semibold">{module.title}</h2>
                          {!module.is_required && (
                            <span className="rounded-full border border-border bg-muted px-2 py-0.5 text-xs text-muted-foreground">
                              Optional
                            </span>
                          )}
                        </div>
                        {module.description && (
                          <p className="mt-1 text-sm text-muted-foreground">{module.description}</p>
                        )}
                      </div>
                      {isComplete && (
                        <CheckCircle2 className="h-5 w-5 shrink-0 text-success" aria-label="Complete" />
                      )}
                    </div>

                    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-muted-foreground">
                      <span className="inline-flex items-center gap-1.5">
                        <BookOpen className="h-4 w-4" aria-hidden="true" />
                        {module.lesson_count} {module.lesson_count === 1 ? 'lesson' : 'lessons'}
                      </span>
                      {module.has_quiz && (
                        <span className="inline-flex items-center gap-1.5">
                          <HelpCircle className="h-4 w-4" aria-hidden="true" />
                          Quiz
                        </span>
                      )}
                      <span className="inline-flex items-center gap-1.5">
                        <Clock className="h-4 w-4" aria-hidden="true" />
                        {formatMinutes(module.est_minutes)}
                      </span>
                      <span
                        className={cn(
                          'font-medium',
                          isComplete ? 'text-success' : inProgress ? 'text-warning' : 'text-accent',
                        )}
                      >
                        {isComplete ? 'Complete' : inProgress ? 'In progress' : 'Not started'}
                      </span>
                    </div>
                  </CardBody>
                </Card>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
