import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, CheckCircle2, Lock, Unlock, XCircle } from 'lucide-react';
import { useAllAdvisors, useEnrolmentDays, useManagerUnlockDay, today } from '@/api/enrolments';
import { useAllQuizAttempts } from '@/api/quizzes';
import { usePublicHolidays, useSettings } from '@/api/settings';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { DayBadge, ProgressBadge, ProgressBar } from '@/components/ui/StatusBadge';
import { calculateProgress, createCalendar } from '@/lib/workingDays';
import { formatLongDate } from '@/lib/formatDate';

export function AdvisorDetailPage() {
  const { advisorId } = useParams<{ advisorId: string }>();
  const { data: advisors, isLoading } = useAllAdvisors();
  const { data: settings } = useSettings();
  const { data: holidays } = usePublicHolidays();

  const record = advisors?.find((row) => row.profile.id === advisorId);
  const enrolment = record?.enrolment ?? null;

  const { data: days } = useEnrolmentDays(enrolment?.id);
  const { data: attempts } = useAllQuizAttempts(enrolment?.id);
  const unlockDay = useManagerUnlockDay();

  const [unlockTarget, setUnlockTarget] = useState<number | null>(null);
  const [reason, setReason] = useState('');
  const [unlockError, setUnlockError] = useState<string | null>(null);

  if (isLoading) return <LoadingState label="Loading advisor…" />;

  if (!record) {
    return (
      <EmptyState
        title="Advisor not found"
        action={
          <Link to="/manage/advisors" className="text-sm font-medium text-accent hover:underline">
            Back to advisors
          </Link>
        }
      />
    );
  }

  const progress =
    enrolment && settings
      ? calculateProgress({
          startDate: enrolment.start_date,
          asOf: today(),
          currentDay: enrolment.current_day,
          programmeLengthDays: settings.programmeLengthDays,
          calendar: createCalendar(holidays ?? [], settings.workingWeekdays),
          thresholds: {
            onTrackDays: settings.driftOnTrackDays,
            attentionDays: settings.driftAttentionDays,
          },
        })
      : null;

  async function handleUnlock() {
    if (!enrolment || unlockTarget === null) return;
    setUnlockError(null);
    try {
      await unlockDay.mutateAsync({
        enrolmentId: enrolment.id,
        dayNumber: unlockTarget,
        reason,
      });
      setUnlockTarget(null);
      setReason('');
    } catch (error) {
      setUnlockError(error instanceof Error ? error.message : 'We could not unlock that day.');
    }
  }

  const failedAttempts = (attempts ?? []).filter((attempt) => attempt.passed === false);

  return (
    <div className="space-y-6">
      <div>
        <Link
          to="/manage/advisors"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Advisors
        </Link>
        <h1 className="mt-2">{record.profile.full_name}</h1>
        <p className="mt-1 text-sm text-muted-foreground">{record.profile.email}</p>
      </div>

      {!enrolment ? (
        <EmptyState
          title="Not enrolled"
          description="This advisor has not been enrolled in a programme yet."
          action={
            <Link to="/manage/enrol" className="text-sm font-medium text-accent hover:underline">
              Enrol them now
            </Link>
          }
        />
      ) : (
        <>
          <Card>
            <CardBody className="space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <p className="text-lg font-semibold">
                  Day {enrolment.current_day} of {settings?.programmeLengthDays ?? 30}
                </p>
                {progress && <ProgressBadge status={progress.status} />}
              </div>
              {progress && <ProgressBar percent={progress.percentComplete} />}
              {progress && (
                <dl className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <dt className="text-muted-foreground">Started</dt>
                    <dd className="font-medium">{formatLongDate(enrolment.start_date)}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Target finish</dt>
                    <dd className="font-medium">{formatLongDate(progress.targetEndDate)}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Projected finish</dt>
                    <dd className="font-medium">{formatLongDate(progress.projectedEndDate)}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Drift</dt>
                    <dd className="font-medium">
                      {progress.isAhead
                        ? 'Ahead of target'
                        : progress.driftDays === 0
                          ? 'On pace'
                          : `${progress.driftDays} working days behind`}
                    </dd>
                  </div>
                </dl>
              )}
            </CardBody>
          </Card>

          {failedAttempts.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Unsuccessful quiz attempts</CardTitle>
              </CardHeader>
              <CardBody className="p-0">
                <ul className="divide-y divide-border">
                  {failedAttempts.map((attempt) => (
                    <li key={attempt.id} className="flex items-center gap-3 px-5 py-3 text-sm">
                      <XCircle className="h-4 w-4 shrink-0 text-danger" aria-hidden="true" />
                      <span className="flex-1">
                        {attempt.quizzes?.modules?.title ?? 'Quiz'} · attempt {attempt.attempt_no}
                      </span>
                      <span className="font-semibold">{attempt.score}%</span>
                    </li>
                  ))}
                </ul>
              </CardBody>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle>Programme days</CardTitle>
            </CardHeader>
            <CardBody className="p-0">
              <ul className="divide-y divide-border">
                {(days ?? []).map((day) => (
                  <li key={day.id} className="flex items-center gap-3 px-5 py-3">
                    {day.status === 'complete' ? (
                      <CheckCircle2 className="h-4 w-4 shrink-0 text-success" aria-hidden="true" />
                    ) : day.status === 'locked' ? (
                      <Lock className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
                    ) : (
                      <Unlock className="h-4 w-4 shrink-0 text-accent" aria-hidden="true" />
                    )}
                    <span className="min-w-0 flex-1 truncate text-sm">
                      Day {day.day_number}
                      {day.programme_days?.title ? ` · ${day.programme_days.title}` : ''}
                      {day.unlocked_by_override && (
                        <span className="ml-2 text-xs text-warning">override</span>
                      )}
                    </span>
                    <DayBadge state={day.status} />
                    {day.status === 'locked' && (
                      <Button size="sm" variant="outline" onClick={() => setUnlockTarget(day.day_number)}>
                        Unlock
                      </Button>
                    )}
                  </li>
                ))}
              </ul>
            </CardBody>
          </Card>
        </>
      )}

      {/*
        The override dialogue. The reason field is not a formality — the RPC
        rejects a blank one, and the value is written to the audit log, so this
        form cannot submit without it.
      */}
      {unlockTarget !== null && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-foreground/40 p-4 sm:items-center">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>Unlock Day {unlockTarget}</CardTitle>
            </CardHeader>
            <CardBody className="space-y-4">
              <p className="text-sm text-muted-foreground">
                This opens the day without the advisor having completed the previous one. The reason
                below is recorded permanently in the audit log against your name.
              </p>
              <div className="space-y-1.5">
                <label htmlFor="unlock-reason" className="block text-sm font-medium">
                  Reason
                </label>
                <textarea
                  id="unlock-reason"
                  value={reason}
                  onChange={(event) => setReason(event.target.value)}
                  rows={3}
                  className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                  placeholder="For example: sat the assessment offline while travelling"
                />
              </div>
              {unlockError && (
                <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
                  {unlockError}
                </p>
              )}
              <div className="flex gap-2">
                <Button
                  variant="accent"
                  onClick={() => void handleUnlock()}
                  isLoading={unlockDay.isPending}
                  disabled={reason.trim().length === 0}
                >
                  Unlock day
                </Button>
                <Button
                  variant="ghost"
                  onClick={() => {
                    setUnlockTarget(null);
                    setReason('');
                    setUnlockError(null);
                  }}
                >
                  Cancel
                </Button>
              </div>
            </CardBody>
          </Card>
        </div>
      )}
    </div>
  );
}
