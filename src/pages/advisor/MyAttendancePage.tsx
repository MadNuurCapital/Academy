import { AlertTriangle, CalendarCheck } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { useMyEnrolment } from '@/api/enrolments';
import { useAttendanceSummary, useMyAttendanceHistory, useMyMakeupTasks } from '@/api/attendance';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatLongDate } from '@/lib/formatDate';
import { cn } from '@/lib/cn';

const STATUS_STYLES: Record<string, string> = {
  present: 'text-success',
  late: 'text-warning',
  absent: 'text-danger',
};

/**
 * The advisor's own attendance.
 *
 * Read-only, and not because the buttons are hidden: there is no advisor write
 * policy on attendance_records at all. If an entry is wrong, the advisor speaks
 * to their manager, who corrects it with a recorded reason. There is
 * deliberately no correction-request workflow.
 */
export function MyAttendancePage() {
  const { session } = useAuth();
  const { data: enrolment } = useMyEnrolment();
  const { data: summary, isLoading, error, refetch } = useAttendanceSummary(session?.user.id);
  const { data: history } = useMyAttendanceHistory();
  const { data: makeupTasks } = useMyMakeupTasks(enrolment?.id);

  if (isLoading) return <LoadingState label="Loading your attendance…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load your attendance"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  const outstanding = (makeupTasks ?? []).filter((task) => task.status === 'outstanding');

  return (
    <div className="space-y-6">
      <div>
        <h1>My attendance</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Recorded by your manager each working day.
        </p>
      </div>

      {summary && summary.total_recorded > 0 ? (
        <>
          <Card>
            <CardBody className="space-y-4">
              <div className="flex flex-wrap items-end justify-between gap-2">
                <div>
                  <p className="text-3xl font-semibold">{summary.attendance_pct}%</p>
                  <p className="text-sm text-muted-foreground">
                    across {summary.total_recorded}{' '}
                    {summary.total_recorded === 1 ? 'day' : 'days'} recorded
                  </p>
                </div>
                {summary.below_target && (
                  <span className="inline-flex items-center gap-1.5 rounded-full border border-warning/20 bg-warning/10 px-2.5 py-0.5 text-xs font-medium text-warning">
                    <AlertTriangle className="h-3 w-3" aria-hidden="true" />
                    Below the {summary.target_pct}% target
                  </span>
                )}
              </div>

              <dl className="grid grid-cols-3 gap-4 border-t border-border pt-4 text-center">
                <div>
                  <dt className="text-xs text-muted-foreground">Present</dt>
                  <dd className="text-xl font-semibold text-success">{summary.present}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">Late</dt>
                  <dd className="text-xl font-semibold text-warning">{summary.late}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">Absent</dt>
                  <dd className="text-xl font-semibold text-danger">{summary.absent}</dd>
                </div>
              </dl>

              {/*
                Stated plainly because it genuinely is the policy: attendance is
                reported but never blocks completion. An advisor can attend every
                day and still fail the assessments, and the reverse is also true.
              */}
              <p className="border-t border-border pt-4 text-sm text-muted-foreground">
                Attendance is tracked separately from your assessments. It appears in your Day 30
                review but does not on its own prevent you completing the programme.
              </p>
            </CardBody>
          </Card>

          {outstanding.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>
                  <span className="inline-flex items-center gap-2">
                    <AlertTriangle className="h-4 w-4 text-warning" aria-hidden="true" />
                    Make-up training outstanding
                  </span>
                </CardTitle>
              </CardHeader>
              <CardBody className="space-y-2">
                <p className="text-sm text-muted-foreground">
                  You missed these days. The content is still in your roadmap — work through it when
                  you can.
                </p>
                <ul className="space-y-1 text-sm">
                  {outstanding.map((task) => (
                    <li key={task.id} className="flex justify-between gap-4">
                      <span>{formatLongDate(task.attendance_date)}</span>
                      {task.programme_day && (
                        <span className="text-muted-foreground">Day {task.programme_day}</span>
                      )}
                    </li>
                  ))}
                </ul>
              </CardBody>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle>History</CardTitle>
            </CardHeader>
            <CardBody className="p-0">
              <ul className="divide-y divide-border">
                {(history ?? []).map((record) => (
                  <li key={record.id} className="flex items-center gap-3 px-5 py-3">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm">{formatLongDate(record.attendance_date)}</p>
                      {record.remarks && (
                        <p className="text-xs text-muted-foreground">{record.remarks}</p>
                      )}
                    </div>
                    <span
                      className={cn(
                        'shrink-0 text-sm font-medium capitalize',
                        STATUS_STYLES[record.status],
                      )}
                    >
                      {record.status}
                    </span>
                  </li>
                ))}
              </ul>
            </CardBody>
          </Card>
        </>
      ) : (
        <EmptyState
          icon={CalendarCheck}
          title="No attendance recorded yet"
          description="Your attendance appears here once your manager has marked a day."
        />
      )}
    </div>
  );
}
