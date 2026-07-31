import { CheckCircle2, MessageSquare, XCircle } from 'lucide-react';
import { useMyEnrolment } from '@/api/enrolments';
import { useAcknowledgeFeedback, useMyAssessments } from '@/api/practical';
import { Button } from '@/components/ui/Button';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { formatLongDate } from '@/lib/formatDate';

/**
 * Practical assessment results and their written feedback.
 *
 * Acknowledgement is required. It is not a legal formality — it is the only
 * evidence that the advisor actually read what their manager took the trouble
 * to write, and it surfaces on the Day 30 review.
 */
export function FeedbackPage() {
  const { data: enrolment } = useMyEnrolment();
  const { data: assessments, isLoading } = useMyAssessments(enrolment?.id);
  const acknowledge = useAcknowledgeFeedback();

  if (isLoading) return <LoadingState label="Loading your feedback…" />;

  const scored = (assessments ?? []).filter((assessment) => assessment.assessed_at);

  return (
    <div className="space-y-6">
      <div>
        <h1>Feedback</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Results and written feedback from your practical assessments.
        </p>
      </div>

      {scored.length === 0 ? (
        <EmptyState
          icon={MessageSquare}
          title="No feedback yet"
          description="Feedback appears here once your manager has assessed a practical exercise."
        />
      ) : (
        <div className="space-y-3">
          {scored.map((assessment) => (
            <Card key={assessment.id}>
              <CardBody className="space-y-3">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="font-medium">{assessment.title}</p>
                    <p className="text-xs text-muted-foreground">
                      {assessment.assessed_at &&
                        formatLongDate(assessment.assessed_at.slice(0, 10))}
                      {assessment.attempt_no > 1 && ` · attempt ${assessment.attempt_no}`}
                    </p>
                  </div>
                  {assessment.passed ? (
                    <CheckCircle2 className="h-5 w-5 shrink-0 text-success" aria-label="Passed" />
                  ) : (
                    <XCircle className="h-5 w-5 shrink-0 text-danger" aria-label="Not passed" />
                  )}
                </div>

                {assessment.total_score !== null && assessment.max_score !== null && (
                  <p className="text-sm">
                    <span className="font-semibold">
                      {assessment.total_score} / {assessment.max_score}
                    </span>
                  </p>
                )}

                {assessment.feedback && (
                  <div className="rounded-md bg-muted/50 p-3">
                    <p className="whitespace-pre-wrap text-sm">{assessment.feedback}</p>
                  </div>
                )}

                {assessment.advisor_acknowledged_at ? (
                  <p className="text-sm text-success">
                    Acknowledged {formatLongDate(assessment.advisor_acknowledged_at.slice(0, 10))}
                  </p>
                ) : (
                  <Button
                    size="sm"
                    variant="accent"
                    isLoading={acknowledge.isPending}
                    onClick={() => acknowledge.mutate(assessment.id)}
                  >
                    I have read this feedback
                  </Button>
                )}
              </CardBody>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
