import { Link } from 'react-router-dom';
import { AlertTriangle, ArrowRight, CalendarCheck, Users } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { useAllAdvisors, today } from '@/api/enrolments';
import { usePublicHolidays, useSettings } from '@/api/settings';
import { useAttendancePending } from '@/api/attendance';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { ProgressBadge } from '@/components/ui/StatusBadge';
import { calculateProgress, createCalendar, type ProgressResult } from '@/lib/workingDays';

/**
 * The manager's home screen.
 *
 * Exists to answer one question: who needs my attention today. Advisors who are
 * on track are deliberately not listed here — they are one click away on the
 * advisors page. A dashboard that shows everyone shows nothing.
 */
export function ManagerDashboard() {
  const { profile } = useAuth();
  const { data: advisors, isLoading, error, refetch } = useAllAdvisors();
  const { data: settings } = useSettings();
  const { data: holidays } = usePublicHolidays();
  const { data: attendancePending } = useAttendancePending();

  const firstName = profile?.full_name.split(' ')[0] ?? 'there';

  if (isLoading) return <LoadingState label="Loading your advisors…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load your dashboard"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  const enrolled = (advisors ?? []).filter((row) => row.enrolment !== null);

  const withProgress = enrolled.map((row) => {
    let progress: ProgressResult | null = null;
    if (row.enrolment && settings) {
      progress = calculateProgress({
        startDate: row.enrolment.start_date,
        asOf: today(),
        currentDay: row.enrolment.current_day,
        programmeLengthDays: settings.programmeLengthDays,
        calendar: createCalendar(holidays ?? [], settings.workingWeekdays),
        thresholds: {
          onTrackDays: settings.driftOnTrackDays,
          attentionDays: settings.driftAttentionDays,
        },
      });
    }
    return { ...row, progress };
  });

  const needsAttention = withProgress.filter(
    (row) => row.progress && row.progress.status !== 'on_track',
  );

  return (
    <div className="space-y-6">
      <div>
        <h1>Good day, {firstName}</h1>
        <p className="mt-1 text-sm text-muted-foreground">Who needs your attention today.</p>
      </div>

      {/*
        The attendance reminder. Sits above everything else because recording it
        is the one thing a manager does every single morning, and it returns 0
        on a non-working day so the banner stays quiet at weekends.
      */}
      {attendancePending !== undefined && attendancePending > 0 && (
        <Link
          to="/manage/attendance"
          className="flex items-start gap-3 rounded-md border border-warning/30 bg-warning/5 px-4 py-3 hover:bg-warning/10"
        >
          <CalendarCheck className="mt-0.5 h-5 w-5 shrink-0 text-warning" aria-hidden="true" />
          <div className="flex-1">
            <p className="font-medium">Today's attendance is not recorded</p>
            <p className="text-sm text-muted-foreground">
              {attendancePending} {attendancePending === 1 ? 'advisor is' : 'advisors are'} still
              unmarked. It takes under a minute.
            </p>
          </div>
          <ArrowRight className="mt-0.5 h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
        </Link>
      )}

      {enrolled.length === 0 ? (
        <EmptyState
          icon={Users}
          title="No advisors enrolled yet"
          description="Once advisors are enrolled, this dashboard shows who is behind schedule and what is waiting on your review."
          action={
            <Link to="/manage/enrol" className="text-sm font-medium text-accent hover:underline">
              Enrol an advisor
            </Link>
          }
        />
      ) : (
        <>
          <div className="grid gap-4 sm:grid-cols-3">
            <StatCard label="Advisors on programme" value={enrolled.length} />
            <StatCard
              label="On track"
              value={withProgress.filter((row) => row.progress?.status === 'on_track').length}
            />
            <StatCard label="Need attention" value={needsAttention.length} emphasis={needsAttention.length > 0} />
          </div>

          {needsAttention.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>
                  <span className="inline-flex items-center gap-2">
                    <AlertTriangle className="h-4 w-4 text-warning" aria-hidden="true" />
                    Needs attention
                  </span>
                </CardTitle>
              </CardHeader>
              <CardBody className="p-0">
                <ul className="divide-y divide-border">
                  {needsAttention.map((row) => (
                    <li key={row.profile.id}>
                      <Link
                        to={`/manage/advisors/${row.profile.id}`}
                        className="flex min-h-[56px] items-center gap-3 px-5 py-3 hover:bg-muted"
                      >
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-sm font-medium">{row.profile.full_name}</p>
                          <p className="text-xs text-muted-foreground">
                            Day {row.enrolment?.current_day} ·{' '}
                            {row.progress?.driftDays} working{' '}
                            {row.progress?.driftDays === 1 ? 'day' : 'days'} behind target
                          </p>
                        </div>
                        {row.progress && <ProgressBadge status={row.progress.status} />}
                      </Link>
                    </li>
                  ))}
                </ul>
              </CardBody>
            </Card>
          )}

          <Link
            to="/manage/advisors"
            className="inline-flex items-center gap-2 text-sm font-medium text-accent hover:underline"
          >
            View all advisors
            <ArrowRight className="h-4 w-4" aria-hidden="true" />
          </Link>
        </>
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  emphasis,
}: {
  label: string;
  value: number;
  emphasis?: boolean;
}) {
  return (
    <Card>
      <CardBody>
        <p className="text-sm text-muted-foreground">{label}</p>
        <p className={`mt-1 text-2xl font-semibold ${emphasis ? 'text-warning' : 'text-foreground'}`}>
          {value}
        </p>
      </CardBody>
    </Card>
  );
}
