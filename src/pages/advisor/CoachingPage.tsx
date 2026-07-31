import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, CheckCircle2, Circle, MessageSquare } from 'lucide-react';
import { useCoachingSession, useCompleteCoachingAction, useMyCoaching } from '@/api/practical';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatLongDate } from '@/lib/formatDate';

/**
 * The advisor's coaching.
 *
 * Coaching is private to the advisor concerned, their manager and
 * administrators — never visible to other advisors. What an advisor sees here
 * is everything on the session record, because candid staff observations are
 * held in a separate table they have no access to at all. There is no field on
 * this screen that has been hidden from them.
 */
export function CoachingPage() {
  const { data: sessions, isLoading, error, refetch } = useMyCoaching();

  if (isLoading) return <LoadingState label="Loading your coaching…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load your coaching"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  const upcoming = (sessions ?? []).filter((session) => session.status === 'scheduled');
  const past = (sessions ?? []).filter((session) => session.status !== 'scheduled');

  return (
    <div className="space-y-6">
      <div>
        <h1>My coaching</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Sessions with your manager. Only you and your manager can see these.
        </p>
      </div>

      {(sessions ?? []).length === 0 ? (
        <EmptyState
          icon={MessageSquare}
          title="No coaching scheduled"
          description="Your manager will schedule coaching sessions as you work through the programme."
        />
      ) : (
        <>
          {upcoming.length > 0 && (
            <section className="space-y-2">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
                Upcoming
              </h2>
              {upcoming.map((session) => (
                <Link key={session.id} to={`/coaching/${session.id}`} className="block">
                  <Card className="transition-colors hover:border-accent/40">
                    <CardBody className="py-3">
                      <p className="font-medium">{session.topic}</p>
                      <p className="text-sm text-muted-foreground">
                        {new Date(session.scheduled_at).toLocaleString('en-SG', {
                          weekday: 'long',
                          day: 'numeric',
                          month: 'long',
                          hour: 'numeric',
                          minute: '2-digit',
                        })}
                      </p>
                      {session.preparation && (
                        <p className="mt-1 text-sm text-warning">Preparation required</p>
                      )}
                    </CardBody>
                  </Card>
                </Link>
              ))}
            </section>
          )}

          {past.length > 0 && (
            <section className="space-y-2">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
                Past sessions
              </h2>
              {past.map((session) => (
                <Link key={session.id} to={`/coaching/${session.id}`} className="block">
                  <Card className="transition-colors hover:border-accent/40">
                    <CardBody className="py-3">
                      <p className="font-medium">{session.topic}</p>
                      <p className="text-sm text-muted-foreground">
                        {formatLongDate(session.scheduled_at.slice(0, 10))}
                      </p>
                    </CardBody>
                  </Card>
                </Link>
              ))}
            </section>
          )}
        </>
      )}
    </div>
  );
}

export function CoachingDetailPage() {
  const { sessionId } = useParams<{ sessionId: string }>();
  const { data, isLoading, error } = useCoachingSession(sessionId);
  const completeAction = useCompleteCoachingAction();

  if (isLoading) return <LoadingState label="Loading the session…" />;

  if (error || !data?.session) {
    return (
      <EmptyState
        title="Coaching session not available"
        action={
          <Link to="/coaching" className="text-sm font-medium text-accent hover:underline">
            Back to my coaching
          </Link>
        }
      />
    );
  }

  const { session, actions } = data;

  return (
    <div className="space-y-6">
      <div>
        <Link
          to="/coaching"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          My coaching
        </Link>
        <h1 className="mt-2">{session.topic}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {new Date(session.scheduled_at).toLocaleString('en-SG', {
            weekday: 'long',
            day: 'numeric',
            month: 'long',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
          })}
        </p>
      </div>

      {session.preparation && (
        <Card>
          <CardHeader>
            <CardTitle>Before the session</CardTitle>
          </CardHeader>
          <CardBody>
            <p className="whitespace-pre-wrap text-sm">{session.preparation}</p>
          </CardBody>
        </Card>
      )}

      {(session.strengths || session.improvement_areas || session.outcome) && (
        <Card>
          <CardHeader>
            <CardTitle>What we discussed</CardTitle>
          </CardHeader>
          <CardBody className="space-y-3 text-sm">
            {session.strengths && (
              <div>
                <p className="font-medium text-success">Strengths</p>
                <p className="whitespace-pre-wrap text-muted-foreground">{session.strengths}</p>
              </div>
            )}
            {session.improvement_areas && (
              <div>
                <p className="font-medium text-warning">To work on</p>
                <p className="whitespace-pre-wrap text-muted-foreground">
                  {session.improvement_areas}
                </p>
              </div>
            )}
            {session.outcome && (
              <div>
                <p className="font-medium">Outcome</p>
                <p className="whitespace-pre-wrap text-muted-foreground">{session.outcome}</p>
              </div>
            )}
          </CardBody>
        </Card>
      )}

      {actions.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Agreed actions</CardTitle>
          </CardHeader>
          <CardBody className="p-0">
            <ul className="divide-y divide-border">
              {actions.map((action) => (
                <li key={action.id} className="flex items-start gap-3 px-5 py-3">
                  {action.status === 'complete' ? (
                    <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" aria-label="Complete" />
                  ) : (
                    <Circle className="mt-0.5 h-5 w-5 shrink-0 text-muted-foreground" aria-hidden="true" />
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="text-sm">{action.description}</p>
                    {action.due_date && (
                      <p className="text-xs text-muted-foreground">
                        Due {formatLongDate(action.due_date)}
                        {action.is_required && ' · required before your Day 30 review'}
                      </p>
                    )}
                  </div>
                  {action.status === 'open' && (
                    <Button
                      size="sm"
                      variant="outline"
                      isLoading={completeAction.isPending}
                      onClick={() => completeAction.mutate(action.id)}
                    >
                      Mark done
                    </Button>
                  )}
                </li>
              ))}
            </ul>
          </CardBody>
        </Card>
      )}
    </div>
  );
}
