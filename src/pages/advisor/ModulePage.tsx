import { Link, useParams } from 'react-router-dom';
import { BookOpen, CheckCircle2, Circle, Clock, Download, ExternalLink, HelpCircle } from 'lucide-react';
import { useModuleDetail } from '@/api/content';
import { useMyEnrolment } from '@/api/enrolments';
import { useQuizAttempts } from '@/api/quizzes';
import { useSettings } from '@/api/settings';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatMinutes } from '@/lib/formatDate';

export function ModulePage() {
  const { moduleId } = useParams<{ moduleId: string }>();
  const { data: enrolment } = useMyEnrolment();
  const { data, isLoading, error, refetch } = useModuleDetail(moduleId, enrolment?.id);
  const { data: settings } = useSettings();
  const { data: attempts } = useQuizAttempts(data?.quiz?.id, enrolment?.id);

  if (isLoading) return <LoadingState label="Loading the module…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load this module"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  // An empty result here usually means the module belongs to a day the advisor
  // has not unlocked — RLS filters it out rather than raising.
  if (!data) {
    return (
      <EmptyState
        title="Module not available"
        description="This module is either not published yet, or belongs to a day you have not reached."
        action={
          <Link to="/roadmap" className="text-sm font-medium text-accent hover:underline">
            Back to my roadmap
          </Link>
        }
      />
    );
  }

  const { module, lessons, resources, terminology, revisionCards, quiz, completedLessonIds, quizPassed } =
    data;

  const allLessonsRead = lessons.length > 0 && lessons.every((lesson) => completedLessonIds.has(lesson.id));
  const nextLesson = lessons.find((lesson) => !completedLessonIds.has(lesson.id));
  const passMark = quiz?.pass_mark ?? settings?.quizPassMark ?? 80;
  const failedAttempts = (attempts ?? []).filter((attempt) => attempt.passed === false).length;

  return (
    <div className="space-y-6">
      <div>
        <h1>{module.title}</h1>
        {module.description && (
          <p className="mt-2 text-sm text-muted-foreground">{module.description}</p>
        )}
        <p className="mt-2 inline-flex items-center gap-1.5 text-sm text-muted-foreground">
          <Clock className="h-4 w-4" aria-hidden="true" />
          About {formatMinutes(module.est_minutes)}
        </p>
      </div>

      {module.objectives.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>What you will be able to do</CardTitle>
          </CardHeader>
          <CardBody>
            <ul className="space-y-1.5 text-sm">
              {module.objectives.map((objective, index) => (
                <li key={index} className="flex gap-2">
                  <span className="text-accent" aria-hidden="true">
                    •
                  </span>
                  {objective}
                </li>
              ))}
            </ul>
          </CardBody>
        </Card>
      )}

      {/* Lessons */}
      <Card>
        <CardHeader>
          <CardTitle>Lessons</CardTitle>
        </CardHeader>
        <CardBody className="p-0">
          {lessons.length === 0 ? (
            <p className="px-5 py-4 text-sm text-muted-foreground">
              No lessons have been published for this module yet.
            </p>
          ) : (
            <ul className="divide-y divide-border">
              {lessons.map((lesson) => {
                const isRead = completedLessonIds.has(lesson.id);
                return (
                  <li key={lesson.id}>
                    <Link
                      to={`/lesson/${lesson.id}`}
                      className="flex min-h-[56px] items-center gap-3 px-5 py-3 hover:bg-muted"
                    >
                      {isRead ? (
                        <CheckCircle2 className="h-5 w-5 shrink-0 text-success" aria-label="Read" />
                      ) : (
                        <Circle className="h-5 w-5 shrink-0 text-muted-foreground" aria-hidden="true" />
                      )}
                      <span className="min-w-0 flex-1 truncate text-sm font-medium">{lesson.title}</span>
                      <span className="shrink-0 text-xs text-muted-foreground">
                        {formatMinutes(lesson.est_minutes)}
                      </span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          )}
        </CardBody>
      </Card>

      {/* Quiz — the gate */}
      {quiz && (
        <Card>
          <CardHeader>
            <CardTitle>{quiz.title}</CardTitle>
          </CardHeader>
          <CardBody className="space-y-3">
            {quizPassed ? (
              <div className="flex items-start gap-3">
                <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" aria-hidden="true" />
                <div>
                  <p className="font-medium">Passed</p>
                  <p className="text-sm text-muted-foreground">
                    Best score {Math.max(...(attempts ?? []).map((attempt) => attempt.score ?? 0))}%.
                  </p>
                </div>
              </div>
            ) : (
              <>
                <p className="text-sm text-muted-foreground">
                  You need <strong className="text-foreground">{passMark}%</strong> to pass. You may
                  retry as many times as you need — but the next day stays locked until you pass.
                </p>
                {failedAttempts > 0 && (
                  <p className="text-sm text-warning">
                    {failedAttempts} unsuccessful {failedAttempts === 1 ? 'attempt' : 'attempts'} so
                    far. Review the lessons before trying again.
                  </p>
                )}
                {!allLessonsRead && (
                  <p className="text-sm text-muted-foreground">
                    Work through the lessons first — the quiz covers all of them.
                  </p>
                )}
                <Link
                  to={`/quiz/${quiz.id}`}
                  className="inline-flex min-h-[44px] w-full items-center justify-center gap-2 rounded-md bg-accent px-4 text-sm font-medium text-accent-foreground hover:bg-accent/90 sm:w-auto"
                >
                  <HelpCircle className="h-4 w-4" aria-hidden="true" />
                  {failedAttempts > 0 ? 'Try the quiz again' : 'Start the quiz'}
                </Link>
              </>
            )}
          </CardBody>
        </Card>
      )}

      {nextLesson && (
        <Link
          to={`/lesson/${nextLesson.id}`}
          className="inline-flex min-h-[44px] w-full items-center justify-center gap-2 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90 sm:w-auto"
        >
          <BookOpen className="h-4 w-4" aria-hidden="true" />
          {completedLessonIds.size === 0 ? 'Start the first lesson' : 'Continue where you left off'}
        </Link>
      )}

      {terminology.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Key terms</CardTitle>
          </CardHeader>
          <CardBody>
            <dl className="space-y-3">
              {terminology.map((entry) => (
                <div key={entry.id}>
                  <dt className="text-sm font-semibold">{entry.term}</dt>
                  <dd className="text-sm text-muted-foreground">{entry.definition}</dd>
                </div>
              ))}
            </dl>
          </CardBody>
        </Card>
      )}

      {revisionCards.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Revision</CardTitle>
          </CardHeader>
          <CardBody>
            <ul className="space-y-3">
              {revisionCards.map((card) => (
                <li key={card.id} className="rounded-md border border-border p-3">
                  <p className="text-sm font-medium">{card.front}</p>
                  <p className="mt-1 text-sm text-muted-foreground">{card.back}</p>
                </li>
              ))}
            </ul>
          </CardBody>
        </Card>
      )}

      {resources.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Resources</CardTitle>
          </CardHeader>
          <CardBody className="p-0">
            <ul className="divide-y divide-border">
              {resources.map((resource) => (
                <li key={resource.id}>
                  <a
                    href={resource.external_url ?? '#'}
                    target={resource.external_url ? '_blank' : undefined}
                    rel="noreferrer"
                    className="flex min-h-[48px] items-center gap-3 px-5 py-3 text-sm hover:bg-muted"
                  >
                    {resource.downloadable ? (
                      <Download className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
                    ) : (
                      <ExternalLink className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
                    )}
                    <span className="flex-1">{resource.title}</span>
                  </a>
                </li>
              ))}
            </ul>
          </CardBody>
        </Card>
      )}
    </div>
  );
}
