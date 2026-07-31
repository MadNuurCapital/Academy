import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { MessageSquare, Plus } from 'lucide-react';
import { useAllAdvisors } from '@/api/enrolments';
import { useAllCoaching, useScheduleCoaching } from '@/api/practical';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { formatLongDate } from '@/lib/formatDate';

export function CoachingManagePage() {
  const { data: sessions, isLoading } = useAllCoaching();

  if (isLoading) return <LoadingState label="Loading coaching…" />;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1>Coaching</h1>
        <Link
          to="/manage/coaching/new"
          className="inline-flex min-h-[44px] items-center gap-2 rounded-md bg-accent px-4 text-sm font-medium text-accent-foreground hover:bg-accent/90"
        >
          <Plus className="h-4 w-4" aria-hidden="true" />
          Schedule a session
        </Link>
      </div>

      {!sessions || sessions.length === 0 ? (
        <EmptyState
          icon={MessageSquare}
          title="No coaching sessions yet"
          description="Schedule a session when an advisor needs focused support on something specific."
        />
      ) : (
        <div className="space-y-2">
          {sessions.map((session) => (
            <Card key={session.id}>
              <CardBody className="py-3">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="min-w-0">
                    <p className="truncate font-medium">
                      {session.profiles?.full_name ?? 'Advisor'}
                    </p>
                    <p className="text-sm text-muted-foreground">{session.topic}</p>
                  </div>
                  <p className="shrink-0 text-sm text-muted-foreground">
                    {formatLongDate(session.scheduled_at.slice(0, 10))}
                  </p>
                </div>
              </CardBody>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

export function ScheduleCoachingPage() {
  const navigate = useNavigate();
  const { data: advisors } = useAllAdvisors();
  const schedule = useScheduleCoaching();

  const [advisorId, setAdvisorId] = useState('');
  const [scheduledAt, setScheduledAt] = useState('');
  const [topic, setTopic] = useState('');
  const [reason, setReason] = useState('');
  const [preparation, setPreparation] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    setSubmitError(null);
    try {
      await schedule.mutateAsync({
        advisorId,
        scheduledAt: new Date(scheduledAt).toISOString(),
        topic,
        reason: reason.trim() || undefined,
        preparation: preparation.trim() || undefined,
      });
      navigate('/manage/coaching');
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'We could not schedule that.');
    }
  }

  return (
    <div className="space-y-6">
      <h1>Schedule coaching</h1>

      <Card>
        <CardHeader>
          <CardTitle>Session details</CardTitle>
        </CardHeader>
        <CardBody>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="advisor" className="block text-sm font-medium">Advisor</label>
              <select
                id="advisor"
                value={advisorId}
                onChange={(event) => setAdvisorId(event.target.value)}
                required
                className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              >
                <option value="">Select an advisor…</option>
                {(advisors ?? []).map(({ profile }) => (
                  <option key={profile.id} value={profile.id}>{profile.full_name}</option>
                ))}
              </select>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="when" className="block text-sm font-medium">Date and time</label>
              <input
                id="when"
                type="datetime-local"
                value={scheduledAt}
                onChange={(event) => setScheduledAt(event.target.value)}
                required
                className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="topic" className="block text-sm font-medium">Topic</label>
              <input
                id="topic"
                type="text"
                value={topic}
                onChange={(event) => setTopic(event.target.value)}
                required
                placeholder="For example: opening a first appointment"
                className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="reason" className="block text-sm font-medium">
                Reason <span className="font-normal text-muted-foreground">(optional)</span>
              </label>
              <textarea
                id="reason"
                rows={2}
                value={reason}
                onChange={(event) => setReason(event.target.value)}
                className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="prep" className="block text-sm font-medium">
                Preparation for the advisor{' '}
                <span className="font-normal text-muted-foreground">(optional)</span>
              </label>
              <textarea
                id="prep"
                rows={3}
                value={preparation}
                onChange={(event) => setPreparation(event.target.value)}
                placeholder="What should they review or think about beforehand?"
                className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
              <p className="text-sm text-muted-foreground">
                The advisor is notified as soon as you save, and told if preparation is required.
              </p>
            </div>

            {submitError && (
              <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
                {submitError}
              </p>
            )}

            <Button type="submit" variant="accent" size="lg" isLoading={schedule.isPending} disabled={!advisorId}>
              Schedule session
            </Button>
          </form>
        </CardBody>
      </Card>
    </div>
  );
}
