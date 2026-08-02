import { Link } from 'react-router-dom';
import { ArrowRight, CalendarCheck, CheckCircle2, Clock, Map, Target } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { useEnrolmentDays, useMyEnrolment, useProgress } from '@/api/enrolments';
import { useSettings } from '@/api/settings';
import { Panel, Well } from '@/components/ui/Panel';
import { Bento, BentoTile } from '@/components/ui/Bento';
import { Metric, ProgressRing } from '@/components/ui/Metric';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { ProgressBadge } from '@/components/ui/StatusBadge';
import { formatLongDate, formatMinutes } from '@/lib/formatDate';
import { useModulesForDay } from '@/api/content';

/**
 * The advisor's command view.
 *
 * A bento grid, but ordered rather than decorative: the tiles are written in
 * priority order, and on a phone they collapse to that same order in a single
 * column. Today's mission comes first because it is the only thing an advisor
 * has to act on; everything below it is orientation.
 *
 * Tiles stay conditional. An advisor with nothing outstanding sees a short
 * screen with one obvious action, not a wall of empty panels — which is the
 * single most common way a dashboard like this becomes noise.
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
  const completedDays = days?.filter((day) => day.status === 'complete').length ?? 0;

  // The current phase, and how far through it the advisor is. This is the
  // gamified unit that actually means something: phases are the curriculum's
  // own structure, not a scoring layer bolted on top of it.
  const phaseName = currentDay?.programme_days?.phase ?? null;
  const phaseDays = phaseName
    ? (days ?? []).filter((day) => day.programme_days?.phase === phaseName)
    : [];
  const phaseCleared = phaseDays.filter((day) => day.status === 'complete').length;

  return (
    <div className="space-y-5">
      <Greeting firstName={firstName} />

      <Bento>
        {/* 1 — Today's mission. The only thing that has to be acted on. */}
        <BentoTile span="hero" index={0}>
          {nextModule ? (
            <Panel tone="current" className="p-5 sm:p-6">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div className="min-w-0 flex-1">
                  <p className="console-label flex items-center gap-2">
                    <Target className="h-3.5 w-3.5" aria-hidden="true" />
                    Today&rsquo;s mission · Day {enrolment.current_day}
                  </p>
                  <h2 className="mt-2 text-2xl font-semibold tracking-tight">{nextModule.title}</h2>
                  {nextModule.description && (
                    <p className="mt-2 max-w-2xl text-sm text-muted-foreground">
                      {nextModule.description}
                    </p>
                  )}
                  <p className="mt-3 inline-flex items-center gap-1.5 text-sm text-muted-foreground">
                    <Clock className="h-4 w-4" aria-hidden="true" />
                    {formatMinutes(remainingMinutes)} remaining
                    {outstandingModules.length > 1 && (
                      <span>
                        {' '}
                        · {outstandingModules.length} objectives
                      </span>
                    )}
                  </p>
                </div>
                <Link
                  to={`/module/${nextModule.id}`}
                  className="inline-flex min-h-[44px] w-full items-center justify-center gap-2 rounded-md bg-primary px-5 text-sm font-semibold text-primary-foreground transition-[background-color,transform] duration-150 ease-console hover:bg-primary/90 active:scale-[0.985] sm:w-auto"
                >
                  Begin
                  <ArrowRight className="h-4 w-4" aria-hidden="true" />
                </Link>
              </div>
            </Panel>
          ) : (
            <Panel className="flex items-start gap-3 p-5 sm:p-6">
              <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" aria-hidden="true" />
              <div>
                <p className="console-label">Day {enrolment.current_day}</p>
                <p className="mt-1 text-lg font-semibold">Mission complete</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  {enrolment.current_day >= programmeLength
                    ? 'You have reached the end of the programme. Your manager will review your readiness.'
                    : 'The next day is unlocked and waiting. Well done.'}
                </p>
              </div>
            </Panel>
          )}
        </BentoTile>

        {/* 2 — Where am I in the programme. */}
        <BentoTile span="third" index={1}>
          <Panel className="flex h-full flex-col items-center justify-center gap-3 p-5">
            <ProgressRing
              percent={progress?.percentComplete ?? 0}
              label="Programme completion"
              caption="Complete"
            />
            <p className="text-center text-sm">
              <span className="font-semibold tabular">Day {enrolment.current_day}</span>
              <span className="text-muted-foreground"> of {programmeLength}</span>
            </p>
          </Panel>
        </BentoTile>

        {/* 3 — Am I keeping pace, and when do I finish. */}
        <BentoTile span="wide" index={2}>
          <Panel className="flex h-full flex-col gap-4 p-5">
            <div className="flex items-start justify-between gap-3">
              <p className="console-label">Trajectory</p>
              {progress && <ProgressBadge status={progress.status} />}
            </div>

            {progress ? (
              <>
                <p className="text-sm text-muted-foreground">
                  {progress.isAhead
                    ? 'You are ahead of schedule.'
                    : progress.driftDays === 0
                      ? 'You are keeping pace with the target.'
                      : `${progress.driftDays} working ${progress.driftDays === 1 ? 'day' : 'days'} behind target.`}
                </p>
                <div className="mt-auto grid grid-cols-2 gap-3">
                  <Well>
                    <p className="console-label">Target finish</p>
                    <p className="mt-1 text-sm font-medium tabular">
                      {formatLongDate(progress.targetEndDate)}
                    </p>
                  </Well>
                  <Well>
                    <p className="console-label">Projected</p>
                    <p className="mt-1 text-sm font-medium tabular">
                      {formatLongDate(progress.projectedEndDate)}
                    </p>
                  </Well>
                </div>
              </>
            ) : (
              <p className="text-sm text-muted-foreground">
                Your trajectory appears once the programme calendar has loaded.
              </p>
            )}
          </Panel>
        </BentoTile>

        {/* 4 — The phase gate. Progression that means something, because phases
            are the curriculum's own structure rather than a score. */}
        {phaseName && phaseDays.length > 0 && (
          <BentoTile span="half" index={3}>
            <Panel className="h-full p-5">
              <p className="console-label">Current phase</p>
              <p className="mt-1 text-lg font-semibold tracking-tight">{phaseName}</p>
              <p className="mt-1 text-sm text-muted-foreground tabular">
                {phaseCleared} of {phaseDays.length} days cleared
              </p>
              {/* One pip per day in the phase. Cleared, current, ahead. */}
              <div className="mt-4 flex flex-wrap gap-1.5" aria-hidden="true">
                {phaseDays.map((day) => (
                  <span
                    key={day.id}
                    className={
                      day.status === 'complete'
                        ? 'h-1.5 w-6 rounded-full bg-success'
                        : day.day_number === enrolment.current_day
                          ? 'h-1.5 w-6 rounded-full bg-highlight'
                          : 'h-1.5 w-6 rounded-full bg-white/10'
                    }
                  />
                ))}
              </div>
            </Panel>
          </BentoTile>
        )}

        {/* 5 — Days cleared. Personal, never comparative: this counter exists to
            show momentum, and is deliberately not a ranking against anyone. */}
        <BentoTile span="half" index={4}>
          <Panel className="h-full p-5">
            <Metric
              label="Days cleared"
              value={completedDays}
              unit={`/ ${programmeLength}`}
              note={
                completedDays === 0
                  ? 'Your first one is today.'
                  : `${programmeLength - completedDays} to go.`
              }
              tone="highlight"
            />
          </Panel>
        </BentoTile>

        {/* 6, 7 — Orientation. */}
        <BentoTile span="half" index={5}>
          <Link to="/attendance" className="block h-full">
            <Panel interactive className="flex h-full flex-col gap-2 p-5">
              <p className="console-label flex items-center gap-2">
                <CalendarCheck className="h-3.5 w-3.5" aria-hidden="true" />
                Office attendance
              </p>
              <p className="text-sm text-muted-foreground">
                Required every working day. Recorded by your manager.
              </p>
              <span className="mt-auto inline-flex items-center gap-1.5 text-sm font-medium text-accent">
                View my attendance
                <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
              </span>
            </Panel>
          </Link>
        </BentoTile>

        <BentoTile span="half" index={6}>
          <Link to="/roadmap" className="block h-full">
            <Panel interactive className="flex h-full flex-col gap-2 p-5">
              <p className="console-label flex items-center gap-2">
                <Map className="h-3.5 w-3.5" aria-hidden="true" />
                Mission map
              </p>
              <p className="text-sm text-muted-foreground">
                All {programmeLength} days and what each one covers.
              </p>
              <span className="mt-auto inline-flex items-center gap-1.5 text-sm font-medium text-accent">
                Open the map
                <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
              </span>
            </Panel>
          </Link>
        </BentoTile>
      </Bento>
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
