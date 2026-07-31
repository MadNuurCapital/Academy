import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, ArrowRight, CheckCircle2 } from 'lucide-react';
import { useLesson } from '@/api/content';
import { useMyEnrolment } from '@/api/enrolments';
import { useMarkLessonRead } from '@/api/quizzes';
import { Button } from '@/components/ui/Button';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatMinutes } from '@/lib/formatDate';

export function LessonPage() {
  const { lessonId } = useParams<{ lessonId: string }>();
  const navigate = useNavigate();
  const { data: enrolment } = useMyEnrolment();
  const { data, isLoading, error, refetch } = useLesson(lessonId, enrolment?.id);
  const markRead = useMarkLessonRead();
  const [submitError, setSubmitError] = useState<string | null>(null);

  if (isLoading) return <LoadingState label="Loading the lesson…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load this lesson"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!data) {
    return (
      <EmptyState
        title="Lesson not available"
        description="This lesson is either not published, or belongs to a day you have not reached yet."
        action={
          <Link to="/roadmap" className="text-sm font-medium text-accent hover:underline">
            Back to my roadmap
          </Link>
        }
      />
    );
  }

  const { lesson, module, siblings, isComplete } = data;
  const index = siblings.findIndex((candidate) => candidate.id === lesson.id);
  const previous = index > 0 ? siblings[index - 1] : undefined;
  const next = index >= 0 && index < siblings.length - 1 ? siblings[index + 1] : undefined;

  async function handleMarkRead() {
    setSubmitError(null);
    try {
      await markRead.mutateAsync(lesson.id);
      // Move straight on to the next lesson if there is one; otherwise return to
      // the module, where the quiz is waiting.
      navigate(next ? `/lesson/${next.id}` : `/module/${module.id}`);
    } catch (mutationError) {
      setSubmitError(
        mutationError instanceof Error ? mutationError.message : 'We could not save your progress.',
      );
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <Link
          to={`/module/${module.id}`}
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          {module.title}
        </Link>
        <h1 className="mt-2">{lesson.title}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Lesson {index + 1} of {siblings.length} · {formatMinutes(lesson.est_minutes)}
        </p>
      </div>

      <Card>
        <CardBody>
          {/*
            Lesson bodies are authored by administrators inside ATLAS, not
            supplied by advisors. They are rendered as plain text with preserved
            line breaks rather than as HTML, so a pasted <script> is displayed
            rather than executed.
          */}
          <div className="whitespace-pre-wrap text-base leading-relaxed">{lesson.body}</div>
        </CardBody>
      </Card>

      {submitError && (
        <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
          {submitError}
        </p>
      )}

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          {previous && (
            <Link
              to={`/lesson/${previous.id}`}
              className="inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"
            >
              <ArrowLeft className="h-4 w-4" aria-hidden="true" />
              Previous lesson
            </Link>
          )}
        </div>

        {isComplete ? (
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            <span className="inline-flex items-center gap-1.5 text-sm font-medium text-success">
              <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
              Marked as read
            </span>
            {next ? (
              <Link
                to={`/lesson/${next.id}`}
                className="inline-flex min-h-[44px] items-center justify-center gap-2 rounded-md bg-accent px-4 text-sm font-medium text-accent-foreground hover:bg-accent/90"
              >
                Next lesson
                <ArrowRight className="h-4 w-4" aria-hidden="true" />
              </Link>
            ) : (
              <Link
                to={`/module/${module.id}`}
                className="inline-flex min-h-[44px] items-center justify-center gap-2 rounded-md bg-accent px-4 text-sm font-medium text-accent-foreground hover:bg-accent/90"
              >
                Back to the module
              </Link>
            )}
          </div>
        ) : (
          <Button
            onClick={() => void handleMarkRead()}
            isLoading={markRead.isPending}
            size="lg"
            variant="accent"
          >
            {next ? 'Mark as read and continue' : 'Mark as read'}
            <ArrowRight className="h-4 w-4" aria-hidden="true" />
          </Button>
        )}
      </div>
    </div>
  );
}
