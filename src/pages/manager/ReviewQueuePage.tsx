import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, ClipboardCheck } from 'lucide-react';
import { useReviewQueue, useRubric, useScorePractical } from '@/api/practical';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { cn } from '@/lib/cn';

/**
 * The manager's review queue and scoring form.
 *
 * Practicals are conducted face to face — there is no recording to play back —
 * so what a manager types here is the entire record of how the advisor
 * performed. That is why written feedback is mandatory rather than optional:
 * a bare score tells the advisor nothing they can act on, and tells a future
 * reader of the Day 30 review nothing at all.
 */
export function ReviewQueuePage() {
  const { data: queue, isLoading, error, refetch } = useReviewQueue();

  if (isLoading) return <LoadingState label="Loading the review queue…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load the review queue"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1>Review queue</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Practical assessments waiting for your score.
        </p>
      </div>

      {!queue || queue.length === 0 ? (
        <EmptyState
          icon={ClipboardCheck}
          title="Nothing waiting"
          description="Every practical assessment has been scored. New ones appear here as advisors reach them."
        />
      ) : (
        <div className="space-y-2">
          {queue.map((assessment) => (
            <Link key={assessment.id} to={`/manage/reviews/${assessment.id}`} className="block">
              <Card className="transition-colors hover:border-accent/40">
                <CardBody className="py-3">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="min-w-0">
                      <p className="truncate font-medium">
                        {assessment.enrolments?.profiles?.full_name ?? 'Advisor'}
                      </p>
                      <p className="text-sm text-muted-foreground">{assessment.title}</p>
                    </div>
                    {assessment.status === 'retry_required' && (
                      <span className="shrink-0 rounded-full border border-warning/20 bg-warning/10 px-2.5 py-0.5 text-xs font-medium text-warning">
                        Retry · attempt {assessment.attempt_no}
                      </span>
                    )}
                  </div>
                </CardBody>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

export function ScorePracticalPage() {
  const { assessmentId } = useParams<{ assessmentId: string }>();
  const { data: queue } = useReviewQueue();
  const assessment = queue?.find((item) => item.id === assessmentId);
  const { data: criteria, isLoading } = useRubric(assessment?.rubric_id);
  const score = useScorePractical();

  const [scores, setScores] = useState<Record<string, number>>({});
  const [comments, setComments] = useState<Record<string, string>>({});
  const [feedback, setFeedback] = useState('');
  const [result, setResult] = useState<{ total: number; max: number; passed: boolean } | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);

  if (isLoading) return <LoadingState label="Loading the rubric…" />;

  if (!assessment) {
    return (
      <EmptyState
        title="Assessment not found"
        description="It may already have been scored."
        action={
          <Link to="/manage/reviews" className="text-sm font-medium text-accent hover:underline">
            Back to the review queue
          </Link>
        }
      />
    );
  }

  const allScored = (criteria ?? []).every((criterion) => scores[criterion.id] !== undefined);

  async function handleSubmit() {
    if (!assessmentId) return;
    setSubmitError(null);
    try {
      const payload = (criteria ?? []).map((criterion) => ({
        criterion_id: criterion.id,
        score: scores[criterion.id] ?? 0,
        comment: comments[criterion.id]?.trim() || undefined,
      }));
      const outcome = await score.mutateAsync({
        assessmentId,
        scores: payload,
        feedback,
      });
      setResult({ total: outcome.total_score, max: outcome.max_score, passed: outcome.passed });
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'We could not save that score.');
    }
  }

  if (result) {
    return (
      <div className="space-y-6">
        <Card>
          <CardBody className="space-y-3 text-center">
            <h1>{result.passed ? 'Passed' : 'Needs another attempt'}</h1>
            <p className="text-3xl font-semibold">
              {result.total} / {result.max}
            </p>
            <p className="text-sm text-muted-foreground">
              The advisor has been notified and asked to acknowledge your feedback.
            </p>
            <Link
              to="/manage/reviews"
              className="inline-block text-sm font-medium text-accent hover:underline"
            >
              Back to the review queue
            </Link>
          </CardBody>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <Link
          to="/manage/reviews"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Review queue
        </Link>
        <h1 className="mt-2">{assessment.title}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {assessment.enrolments?.profiles?.full_name ?? 'Advisor'} · attempt{' '}
          {assessment.attempt_no}
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Scoring</CardTitle>
        </CardHeader>
        <CardBody className="space-y-5">
          {(criteria ?? []).map((criterion) => (
            <div key={criterion.id} className="space-y-2">
              <div>
                <p className="text-sm font-medium">{criterion.name}</p>
                {criterion.description && (
                  <p className="text-xs text-muted-foreground">{criterion.description}</p>
                )}
              </div>
              <div
                role="radiogroup"
                aria-label={criterion.name}
                className="flex flex-wrap gap-1"
              >
                {Array.from({ length: criterion.max_score + 1 }, (_, value) => (
                  <button
                    key={value}
                    type="button"
                    role="radio"
                    aria-checked={scores[criterion.id] === value}
                    onClick={() => setScores((prev) => ({ ...prev, [criterion.id]: value }))}
                    className={cn(
                      'min-h-[44px] min-w-[44px] rounded-md border text-sm font-medium',
                      scores[criterion.id] === value
                        ? 'border-accent bg-accent/10 text-accent'
                        : 'border-border bg-surface text-muted-foreground hover:bg-muted',
                    )}
                  >
                    {value}
                  </button>
                ))}
              </div>
              <input
                type="text"
                value={comments[criterion.id] ?? ''}
                onChange={(event) =>
                  setComments((prev) => ({ ...prev, [criterion.id]: event.target.value }))
                }
                placeholder="Comment (optional)"
                aria-label={`Comment on ${criterion.name}`}
                className="w-full rounded-md border border-input bg-surface px-3 py-2 text-sm"
              />
            </div>
          ))}
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Written feedback</CardTitle>
        </CardHeader>
        <CardBody className="space-y-2">
          <textarea
            rows={5}
            value={feedback}
            onChange={(event) => setFeedback(event.target.value)}
            placeholder="What did they do well, and what specifically should they do differently next time?"
            aria-label="Written feedback"
            className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
          />
          <p className="text-sm text-muted-foreground">
            Required. There is no recording of this session — what you write here is the only
            record of how it went.
          </p>
        </CardBody>
      </Card>

      {submitError && (
        <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
          {submitError}
        </p>
      )}

      <Button
        variant="accent"
        size="lg"
        onClick={() => void handleSubmit()}
        isLoading={score.isPending}
        disabled={!allScored || feedback.trim().length === 0}
      >
        Save score and feedback
      </Button>

      {!allScored && (
        <p className="text-sm text-muted-foreground">Score every criterion before saving.</p>
      )}
    </div>
  );
}
