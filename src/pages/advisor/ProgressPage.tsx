import { CheckCircle2, XCircle } from 'lucide-react';
import { useEnrolmentDays, useMyEnrolment, useProgress } from '@/api/enrolments';
import { useAllQuizAttempts } from '@/api/quizzes';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { ProgressBadge, ProgressBar } from '@/components/ui/StatusBadge';
import { formatLongDate } from '@/lib/formatDate';

export function ProgressPage() {
  const { data: enrolment, isLoading } = useMyEnrolment();
  const progress = useProgress(enrolment);
  const { data: days } = useEnrolmentDays(enrolment?.id);
  const { data: attempts } = useAllQuizAttempts(enrolment?.id);

  if (isLoading) return <LoadingState label="Loading your progress…" />;

  if (!enrolment) {
    return (
      <div className="space-y-6">
        <h1>My progress</h1>
        <EmptyState title="No programme yet" description="Your progress appears once you are enrolled." />
      </div>
    );
  }

  const completedDays = days?.filter((day) => day.status === 'complete').length ?? 0;
  const totalDays = days?.length ?? 0;

  return (
    <div className="space-y-6">
      <h1>My progress</h1>

      <Card>
        <CardBody className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <p className="text-sm text-muted-foreground">
              {completedDays} of {totalDays} days complete
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
            </dl>
          )}
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Quiz history</CardTitle>
        </CardHeader>
        <CardBody className="p-0">
          {!attempts || attempts.length === 0 ? (
            <p className="px-5 py-4 text-sm text-muted-foreground">
              You have not sat any quizzes yet.
            </p>
          ) : (
            <ul className="divide-y divide-border">
              {attempts.map((attempt) => (
                <li key={attempt.id} className="flex items-center gap-3 px-5 py-3">
                  {attempt.passed ? (
                    <CheckCircle2 className="h-5 w-5 shrink-0 text-success" aria-label="Passed" />
                  ) : (
                    <XCircle className="h-5 w-5 shrink-0 text-danger" aria-label="Not passed" />
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">
                      {attempt.quizzes?.modules?.title ?? attempt.quizzes?.title ?? 'Quiz'}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Attempt {attempt.attempt_no}
                      {attempt.pass_mark_applied
                        ? ` · ${attempt.pass_mark_applied}% needed`
                        : ''}
                    </p>
                  </div>
                  <span className="shrink-0 text-sm font-semibold">{attempt.score}%</span>
                </li>
              ))}
            </ul>
          )}
        </CardBody>
      </Card>
    </div>
  );
}
