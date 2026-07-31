import { Link } from 'react-router-dom';
import { ArrowRight, CalendarCheck, CheckCircle2, Clock, Map } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { useEnrolmentDays, useMyEnrolment, useProgress } from '@/api/enrolments';
import { useSettings } from '@/api/settings';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { ProgressBadge, ProgressBar } from '@/components/ui/StatusBadge';
import { formatLongDate, formatMinutes } from '@/lib/formatDate';
import { useModulesForDay } from '@/api/content';

/**
 * The advisor's home screen.
 *
 * Answers five questions and nothing else: what do I do today, do I need to be
 * in the office, what is my attendance, am I on track, what is my next action.
 *
 * Cards are conditional throughout. An advisor with nothing outstanding sees a
 * short page with one obvious button, not a wall of empty panels — which is the
 * single most common way a dashboard like this becomes unusable.
 */
export function AdvisorDashboard() {
  const { profile } = useAuth();
  const { data: enrolment, isLoading, error, refetch } = useMyEnrolment();
  const { data: settings } = useSettings();
  const progress = useProgress(enrolment);
  const { data: days } = useEnrolmentDays(enrolment?.id);

  const firstName = profile?.full_name.split(' ')[0] ?? 'there';

  const currentDay = days?.find((day) => day.day_number === enrolment?.current_day);
  const { data: modules } = useModulesForDay(currentDay?.programme_day_id, enrolment?.id);

  if (isLoading) return <LoadingState label="Loading your programme…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load your programme"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!enrolment) {
    return (
      <div className="space-y-6">
        <Greeting firstName={firstName} />
        <EmptyState
          icon={Map}
          title="You are not enrolled in a programme yet"
          description="Once your manager enrols you, your 30-day roadmap will appear here with today's learning and your next action."
        />
      </div>
    );
  }

  const programmeLength = settings?.programmeLengthDays ?? 30;
  const outstandingModules = modules?.filter((module) => module.progress?.status !== 'complete') ?? [];
  const nextModule = outstandingModules[0];
  const remainingMinutes = outstandingModules.reduce((total, module) => total + module.est_minutes, 0);

  return (
    <div className="space-y-6">
      <Greeting firstName={firstName} />

      {/* Where am I, and am I on track? */}
      <Card>
        <CardBody className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div>
              <p className="text-2xl font-semibold text-foreground">
                Day {enrolment.current_day}{' '}
                <span className="text-base font-normal text-muted-foreground">
                  of {programmeLength}
                </span>
              </p>
              {progress && (
                <p className="mt-1 text-sm text-muted-foreground">
                  {progress.isAhead
                    ? 'You are ahead of schedule.'
                    : progress.driftDays === 0
                      ? 'You are keeping pace.'
                      : `${progress.driftDays} working ${progress.driftDays === 1 ? 'day' : 'days'} behind target.`}
                </p>
              )}
            </div>
            {progress && <ProgressBadge status={progress.status} />}
          </div>

          {progress && (
            <>
              <ProgressBar percent={progress.percentComplete} label="Programme completion" />
              <dl className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <dt className="text-muted-foreground">Target finish</dt>
                  <dd className="font-medium">{formatLongDate(progress.targetEndDate)}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground">Projected finish</dt>
                  <dd className="font-medium">{formatLongDate(progress.projectedEndDate)}</dd>
                </div>
              </dl>
            </>
          )}
        </CardBody>
      </Card>

      {/* The single next action. */}
      {nextModule ? (
        <Card>
          <CardBody className="space-y-3">
            <p className="text-sm font-medium text-muted-foreground">Today's learning</p>
            <div>
              <h2 className="text-lg font-semibold">{nextModule.title}</h2>
              {nextModule.description && (
                <p className="mt-1 text-sm text-muted-foreground">{nextModule.description}</p>
              )}
            </div>
            <div className="flex items-center gap-4 text-sm text-muted-foreground">
              <span className="inline-flex items-center gap-1.5">
                <Clock className="h-4 w-4" aria-hidden="true" />
                {formatMinutes(remainingMinutes)} remaining today
              </span>
            </div>
            <Link
              to={`/module/${nextModule.id}`}
              className="inline-flex min-h-[44px] w-full items-center justify-center gap-2 rounded-md bg-accent px-4 text-sm font-medium text-accent-foreground hover:bg-accent/90 sm:w-auto"
            >
              Continue
              <ArrowRight className="h-4 w-4" aria-hidden="true" />
            </Link>
          </CardBody>
        </Card>
      ) : (
        modules &&
        modules.length > 0 && (
          <Card>
            <CardBody className="flex items-start gap-3">
              <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" aria-hidden="true" />
              <div>
                <p className="font-medium">Day {enrolment.current_day} is complete</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  {enrolment.current_day >= programmeLength
                    ? 'You have reached the end of the programme. Your manager will review your readiness.'
                    : 'The next day has been unlocked. Well done.'}
                </p>
              </div>
            </CardBody>
          </Card>
        )
      )}

      {/* Attendance is required every working day, so this always shows. */}
      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <CardBody className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-medium">
              <CalendarCheck className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
              Office attendance
            </div>
            <p className="text-sm text-muted-foreground">
              Required every working day. Recorded by your manager.
            </p>
            <Link to="/attendance" className="inline-block text-sm font-medium text-accent hover:underline">
              View my attendance
            </Link>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-medium">
              <Map className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
              Roadmap
            </div>
            <p className="text-sm text-muted-foreground">
              All {programmeLength} days and what each one covers.
            </p>
            <Link to="/roadmap" className="inline-block text-sm font-medium text-accent hover:underline">
              View roadmap
            </Link>
          </CardBody>
        </Card>
      </div>
    </div>
  );
}

function Greeting({ firstName }: { firstName: string }) {
  return (
    <div>
      <h1>Good day, {firstName}</h1>
      <p className="mt-1 text-sm text-muted-foreground">Here is what needs your attention today.</p>
    </div>
  );
}
