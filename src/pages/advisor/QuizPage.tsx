import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { AlertCircle, ArrowLeft, ArrowRight, CheckCircle2, RotateCcw, XCircle } from 'lucide-react';
import { useMyEnrolment } from '@/api/enrolments';
import { useStartQuizAttempt, useSubmitQuizAttempt } from '@/api/quizzes';
import { Button } from '@/components/ui/Button';
import { Card, CardBody } from '@/components/ui/Card';
import { ErrorState, LoadingState } from '@/components/ui/States';
import { ProgressBar } from '@/components/ui/StatusBadge';
import { cn } from '@/lib/cn';
import type { AttemptResult, StartedAttempt } from '@/types/database';

/**
 * The quiz runner.
 *
 * Worth being explicit about what this component does NOT do, because it is the
 * point of the whole design: it never determines whether an answer is correct.
 * It cannot. The payload from start_quiz_attempt contains option text and
 * nothing else — no is_correct flag, no explanation — so there is no way to
 * grade locally even if someone tried.
 *
 * Submission hands the chosen option ids to a server function that scores them
 * against the real answers and returns a verdict. Correct answers come back
 * only when that verdict is a pass.
 */
export function QuizPage() {
  const { quizId } = useParams<{ quizId: string }>();
  const navigate = useNavigate();
  const { data: enrolment } = useMyEnrolment();

  const startAttempt = useStartQuizAttempt();
  const submitAttempt = useSubmitQuizAttempt();

  const [attempt, setAttempt] = useState<StartedAttempt | null>(null);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [questionIndex, setQuestionIndex] = useState(0);
  const [result, setResult] = useState<AttemptResult | null>(null);
  const [startError, setStartError] = useState<string | null>(null);

  const { mutateAsync: beginAttempt } = startAttempt;

  useEffect(() => {
    if (!quizId || !enrolment) return;
    let cancelled = false;

    void (async () => {
      try {
        const started = await beginAttempt(quizId);
        if (!cancelled) setAttempt(started);
      } catch (error) {
        if (!cancelled) {
          setStartError(error instanceof Error ? error.message : 'We could not start this quiz.');
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [quizId, enrolment, beginAttempt]);

  if (startError) {
    return (
      <ErrorState
        title="We could not start this quiz"
        description={startError}
        onRetry={() => navigate(-1)}
      />
    );
  }

  if (!attempt) return <LoadingState label="Preparing your quiz…" />;

  if (result) {
    return <QuizResult result={result} onRetry={() => window.location.reload()} />;
  }

  const questions = attempt.questions;
  const question = questions[questionIndex];

  if (!question) {
    return <ErrorState title="This quiz has no questions yet" />;
  }

  const answeredCount = Object.keys(answers).length;
  const isLastQuestion = questionIndex === questions.length - 1;
  const currentAnswer = answers[question.question_id];

  async function handleSubmit() {
    if (!attempt) return;
    const payload = Object.entries(answers).map(([question_id, option_id]) => ({
      question_id,
      option_id,
    }));
    const outcome = await submitAttempt.mutateAsync({
      attemptId: attempt.attempt_id,
      answers: payload,
    });
    setResult(outcome);
  }

  return (
    <div className="space-y-6">
      <div>
        <h1>Knowledge check</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Question {questionIndex + 1} of {questions.length}
        </p>
        <div className="mt-3">
          <ProgressBar
            percent={(answeredCount / questions.length) * 100}
            label="Questions answered"
          />
        </div>
      </div>

      <Card>
        <CardBody className="space-y-4">
          <fieldset>
            <legend className="text-base font-medium">{question.question_text}</legend>
            <div className="mt-4 space-y-2">
              {question.options.map((option) => {
                const isSelected = currentAnswer === option.option_id;
                return (
                  <label
                    key={option.option_id}
                    className={cn(
                      'flex min-h-[52px] cursor-pointer items-center gap-3 rounded-md border px-4 py-3 text-sm transition-colors',
                      isSelected
                        ? 'border-accent bg-accent/5 font-medium'
                        : 'border-border hover:bg-muted',
                    )}
                  >
                    <input
                      type="radio"
                      name={question.question_id}
                      value={option.option_id}
                      checked={isSelected}
                      onChange={() =>
                        setAnswers((previous) => ({
                          ...previous,
                          [question.question_id]: option.option_id,
                        }))
                      }
                      className="h-4 w-4 shrink-0 accent-current"
                    />
                    <span>{option.option_text}</span>
                  </label>
                );
              })}
            </div>
          </fieldset>
        </CardBody>
      </Card>

      <div className="flex items-center justify-between gap-3">
        <Button
          variant="outline"
          onClick={() => setQuestionIndex((index) => Math.max(0, index - 1))}
          disabled={questionIndex === 0}
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Back
        </Button>

        {isLastQuestion ? (
          <Button
            variant="accent"
            size="lg"
            onClick={() => void handleSubmit()}
            isLoading={submitAttempt.isPending}
            disabled={answeredCount < questions.length}
          >
            Submit answers
          </Button>
        ) : (
          <Button variant="accent" onClick={() => setQuestionIndex((index) => index + 1)}>
            Next
            <ArrowRight className="h-4 w-4" aria-hidden="true" />
          </Button>
        )}
      </div>

      {isLastQuestion && answeredCount < questions.length && (
        <p className="text-sm text-muted-foreground">
          Answer all {questions.length} questions before submitting. Unanswered questions are marked
          wrong.
        </p>
      )}

      {submitAttempt.error && (
        <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
          {submitAttempt.error instanceof Error
            ? submitAttempt.error.message
            : 'We could not submit your answers.'}
        </p>
      )}
    </div>
  );
}

function QuizResult({ result, onRetry }: { result: AttemptResult; onRetry: () => void }) {
  return (
    <div className="space-y-6">
      <Card>
        <CardBody className="space-y-4 text-center">
          {result.passed ? (
            <CheckCircle2 className="mx-auto h-12 w-12 text-success" aria-hidden="true" />
          ) : (
            <XCircle className="mx-auto h-12 w-12 text-danger" aria-hidden="true" />
          )}

          <div>
            <h1>{result.passed ? 'Passed' : 'Not passed yet'}</h1>
            <p className="mt-2 text-3xl font-semibold">{result.score}%</p>
            <p className="mt-1 text-sm text-muted-foreground">
              {result.correct_answers} of {result.total_questions} correct · {result.pass_mark}%
              needed to pass
            </p>
          </div>

          {result.passed ? (
            <p className="text-sm text-muted-foreground">
              {result.day_complete
                ? 'That completes the day. The next day has been unlocked.'
                : 'Well done. Finish the remaining modules to complete the day.'}
            </p>
          ) : (
            <p className="text-sm text-muted-foreground">
              Review the lessons and try again. There is no limit on attempts, but the next day stays
              locked until you pass.
            </p>
          )}
        </CardBody>
      </Card>

      {/*
        The review is present only on a pass. After a failure the server returns
        null here, so there is nothing to render and nothing to memorise before
        a retry.
      */}
      {result.passed && result.review && (
        <Card>
          <CardBody className="space-y-4">
            <h2 className="text-base font-semibold">Your answers</h2>
            <ul className="space-y-4">
              {result.review.map((item) => (
                <li key={item.question_id} className="space-y-1">
                  <div className="flex items-start gap-2">
                    {item.was_correct ? (
                      <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success" aria-hidden="true" />
                    ) : (
                      <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-warning" aria-hidden="true" />
                    )}
                    <p className="text-sm font-medium">{item.question_text}</p>
                  </div>
                  {item.explanation && (
                    <p className="pl-6 text-sm text-muted-foreground">{item.explanation}</p>
                  )}
                </li>
              ))}
            </ul>
          </CardBody>
        </Card>
      )}

      <div className="flex flex-col gap-3 sm:flex-row">
        {!result.passed && (
          <Button variant="accent" size="lg" onClick={onRetry}>
            <RotateCcw className="h-4 w-4" aria-hidden="true" />
            Try again
          </Button>
        )}
        <Link
          to="/today"
          className="inline-flex min-h-[44px] items-center justify-center rounded-md border border-border bg-surface px-4 text-sm font-medium hover:bg-muted"
        >
          Back to my dashboard
        </Link>
      </div>
    </div>
  );
}
