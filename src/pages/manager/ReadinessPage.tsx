import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { AlertTriangle, ArrowLeft, CheckCircle2, Circle, Download, XCircle } from 'lucide-react';
import { useAllAdvisors } from '@/api/enrolments';
import {
  useReadinessEvaluation,
  useReadinessReviews,
  useRecordReadinessDecision,
} from '@/api/practical';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatLongDate } from '@/lib/formatDate';
import { cn } from '@/lib/cn';
import type { ReadinessOutcome } from '@/types/database';

/**
 * The Day 30 readiness review.
 *
 * The most consequential screen in ATLAS: it produces the record that says
 * whether someone may start seeing clients under supervision. Two things
 * therefore matter more here than anywhere else.
 *
 * First, the blockers are stated explicitly rather than reduced to a single
 * red or green light. A manager signing someone off should be able to see
 * exactly what is unmet.
 *
 * Second, none of the four outcomes says "certified" or "independent".
 * Completing ATLAS means ready for SUPERVISED fieldwork, and the wording on
 * this screen is where that distinction either holds or quietly erodes.
 */

const OUTCOMES: { value: ReadinessOutcome; label: string; description: string }[] = [
  {
    value: 'ready_for_supervised_fieldwork',
    label: 'Ready for Supervised Fieldwork',
    description:
      'May participate in client-facing activity with a senior advisor present. Not yet independent.',
  },
  {
    value: 'ready_with_development_actions',
    label: 'Ready with Development Actions',
    description:
      'May begin supervised fieldwork, with specific areas to work on recorded below.',
  },
  {
    value: 'additional_training_required',
    label: 'Additional Training Required',
    description: 'Not yet ready. Needs further training before client-facing activity.',
  },
  {
    value: 'programme_extended',
    label: 'Programme Extended',
    description: 'The programme continues. No readiness decision is made yet.',
  },
];

export function ReadinessPage() {
  const { enrolmentId } = useParams<{ enrolmentId: string }>();
  const { data: advisors } = useAllAdvisors();
  const { data: evaluation, isLoading, error, refetch } = useReadinessEvaluation(enrolmentId);
  const { data: previousReviews } = useReadinessReviews(enrolmentId);
  const record = useRecordReadinessDecision();

  const [outcome, setOutcome] = useState<ReadinessOutcome | ''>('');
  const [strengths, setStrengths] = useState('');
  const [developmentAreas, setDevelopmentAreas] = useState('');
  const [notes, setNotes] = useState('');
  const [overrideReason, setOverrideReason] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  const advisor = advisors?.find((row) => row.enrolment?.id === enrolmentId);

  if (isLoading) return <LoadingState label="Evaluating the programme…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not evaluate this advisor"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!evaluation) {
    return (
      <EmptyState
        title="Nothing to review"
        action={
          <Link to="/manage/advisors" className="text-sm font-medium text-accent hover:underline">
            Back to advisors
          </Link>
        }
      />
    );
  }

  const blockers = evaluation.requirements.filter((item) => item.blocks && !item.met);

  // A "ready" outcome despite unmet blockers is the case that demands
  // justification. Choosing additional training or an extension is the honest
  // answer for an advisor who is not there yet, and needs no override.
  const isReadyOutcome =
    outcome === 'ready_for_supervised_fieldwork' || outcome === 'ready_with_development_actions';
  const needsOverride = blockers.length > 0 && isReadyOutcome;
  const canSubmit =
    outcome !== '' && (!needsOverride || overrideReason.trim().length > 0) && !done;

  async function handleSubmit() {
    if (!enrolmentId || outcome === '') return;
    setSubmitError(null);
    try {
      await record.mutateAsync({
        enrolmentId,
        outcome,
        strengths: strengths.trim() || undefined,
        developmentAreas: developmentAreas.trim() || undefined,
        notes: notes.trim() || undefined,
        overrideReason: overrideReason.trim() || undefined,
      });
      setDone(true);
    } catch (mutationError) {
      setSubmitError(
        mutationError instanceof Error
          ? mutationError.message
          : 'We could not record that decision.',
      );
    }
  }

  function handleExport() {
    // The readiness report is the one artefact worth printing or forwarding, so
    // it opens in a print-ready window rather than downloading a CSV.
    window.print();
  }

  return (
    <div className="space-y-6">
      <div className="print:hidden">
        <Link
          to={advisor ? `/manage/advisors/${advisor.profile.id}` : '/manage/advisors'}
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Back
        </Link>
      </div>

      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1>Readiness review</h1>
          {advisor && (
            <p className="mt-1 text-sm text-muted-foreground">
              {advisor.profile.full_name}
              {advisor.enrolment && ` · started ${formatLongDate(advisor.enrolment.start_date)}`}
            </p>
          )}
        </div>
        <Button variant="outline" onClick={handleExport} className="print:hidden">
          <Download className="h-4 w-4" aria-hidden="true" />
          Print report
        </Button>
      </div>

      {done ? (
        <Card>
          <CardBody className="flex items-start gap-3">
            <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" aria-hidden="true" />
            <div>
              <p className="font-medium">Decision recorded</p>
              <p className="mt-1 text-sm text-muted-foreground">
                The advisor has been notified. This decision is permanent and appears in the audit
                log.
              </p>
              <Link
                to="/manage/advisors"
                className="mt-3 inline-block text-sm font-medium text-accent hover:underline"
              >
                Back to advisors
              </Link>
            </div>
          </CardBody>
        </Card>
      ) : (
        <>
          {/* The checklist. Stated explicitly, never reduced to a single light. */}
          <Card>
            <CardHeader>
              <CardTitle>Completion requirements</CardTitle>
            </CardHeader>
            <CardBody className="p-0">
              <ul className="divide-y divide-border">
                {evaluation.requirements.map((item) => (
                  <li key={item.key} className="flex items-start gap-3 px-5 py-3">
                    {item.met ? (
                      <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" aria-label="Met" />
                    ) : item.blocks ? (
                      <XCircle className="mt-0.5 h-5 w-5 shrink-0 text-danger" aria-label="Not met" />
                    ) : (
                      <Circle className="mt-0.5 h-5 w-5 shrink-0 text-muted-foreground" aria-label="Not met" />
                    )}
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium">{item.label}</p>
                      <p className="text-xs text-muted-foreground">{item.detail}</p>
                    </div>
                    {!item.blocks && (
                      <span className="shrink-0 text-xs text-muted-foreground">
                        Does not block
                      </span>
                    )}
                  </li>
                ))}
              </ul>
            </CardBody>
          </Card>

          {blockers.length > 0 && (
            <div className="flex items-start gap-3 rounded-md border border-warning/30 bg-warning/5 px-4 py-3">
              <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-warning" aria-hidden="true" />
              <div>
                <p className="font-medium">
                  {blockers.length} requirement{blockers.length === 1 ? '' : 's'} not met
                </p>
                <p className="text-sm text-muted-foreground">
                  You may still record Additional Training Required or Programme Extended without
                  explanation. Recording a ready outcome will ask you to justify it.
                </p>
              </div>
            </div>
          )}

          <Card className="print:hidden">
            <CardHeader>
              <CardTitle>Decision</CardTitle>
            </CardHeader>
            <CardBody className="space-y-4">
              <fieldset>
                <legend className="sr-only">Readiness outcome</legend>
                <div className="space-y-2">
                  {OUTCOMES.map((option) => (
                    <label
                      key={option.value}
                      className={cn(
                        'flex cursor-pointer items-start gap-3 rounded-md border p-3 transition-colors',
                        outcome === option.value
                          ? 'border-accent bg-accent/5'
                          : 'border-border hover:bg-muted',
                      )}
                    >
                      <input
                        type="radio"
                        name="outcome"
                        value={option.value}
                        checked={outcome === option.value}
                        onChange={() => setOutcome(option.value)}
                        className="mt-1 h-4 w-4 shrink-0"
                      />
                      <div>
                        <p className="text-sm font-medium">{option.label}</p>
                        <p className="text-xs text-muted-foreground">{option.description}</p>
                      </div>
                    </label>
                  ))}
                </div>
              </fieldset>

              <div className="space-y-1.5">
                <label htmlFor="strengths" className="block text-sm font-medium">
                  Strengths
                </label>
                <textarea
                  id="strengths"
                  rows={3}
                  value={strengths}
                  onChange={(event) => setStrengths(event.target.value)}
                  className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                />
              </div>

              <div className="space-y-1.5">
                <label htmlFor="development" className="block text-sm font-medium">
                  Development areas
                </label>
                <textarea
                  id="development"
                  rows={3}
                  value={developmentAreas}
                  onChange={(event) => setDevelopmentAreas(event.target.value)}
                  className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                />
              </div>

              <div className="space-y-1.5">
                <label htmlFor="notes" className="block text-sm font-medium">
                  Notes
                </label>
                <textarea
                  id="notes"
                  rows={2}
                  value={notes}
                  onChange={(event) => setNotes(event.target.value)}
                  className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                />
              </div>

              {needsOverride && (
                <div className="space-y-1.5 rounded-md border border-warning/30 bg-warning/5 p-3">
                  <label htmlFor="override" className="block text-sm font-medium text-warning">
                    Why are you recording a ready outcome despite {blockers.length} unmet
                    requirement{blockers.length === 1 ? '' : 's'}?
                  </label>
                  <textarea
                    id="override"
                    rows={3}
                    value={overrideReason}
                    onChange={(event) => setOverrideReason(event.target.value)}
                    placeholder="Required. Recorded permanently against your name and stored with the decision."
                    className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                  />
                  <ul className="mt-2 space-y-0.5 text-xs text-muted-foreground">
                    {blockers.map((item) => (
                      <li key={item.key}>• {item.label} — {item.detail}</li>
                    ))}
                  </ul>
                </div>
              )}

              {submitError && (
                <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
                  {submitError}
                </p>
              )}

              <Button
                variant="accent"
                size="lg"
                onClick={() => void handleSubmit()}
                isLoading={record.isPending}
                disabled={!canSubmit}
              >
                Record decision
              </Button>
            </CardBody>
          </Card>
        </>
      )}

      {previousReviews && previousReviews.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Previous decisions</CardTitle>
          </CardHeader>
          <CardBody className="p-0">
            <ul className="divide-y divide-border">
              {previousReviews.map((review) => {
                const typed = review as {
                  id: string;
                  outcome: ReadinessOutcome;
                  decided_at: string;
                  override_reason: string | null;
                };
                return (
                  <li key={typed.id} className="px-5 py-3">
                    <p className="text-sm font-medium">
                      {OUTCOMES.find((option) => option.value === typed.outcome)?.label ??
                        typed.outcome}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {formatLongDate(typed.decided_at.slice(0, 10))}
                    </p>
                    {typed.override_reason && (
                      <p className="mt-1 text-xs text-warning">
                        Override: {typed.override_reason}
                      </p>
                    )}
                  </li>
                );
              })}
            </ul>
          </CardBody>
        </Card>
      )}
    </div>
  );
}
