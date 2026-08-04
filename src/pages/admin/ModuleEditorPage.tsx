import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, Check, Plus, Trash2 } from 'lucide-react';
import {
  useDeleteQuizQuestion,
  useModuleForEditing,
  useQuizForAuthoring,
  useSaveQuizQuestion,
  useSetModuleStatus,
  useUpdateLesson,
  useUpdateModule,
  type AuthoringOption,
  type AuthoringQuestion,
} from '@/api/authoring';
import { Panel, Well } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import { ErrorState, LoadingState } from '@/components/ui/States';
import { AutoTextarea, SaveRow } from '@/components/admin/Editor';
import { inputClass } from '@/components/admin/editorState';
import { cn } from '@/lib/cn';
import type { Lesson } from '@/types/database';

/**
 * Review and correct one module.
 *
 * Built for the job it is actually for: reading thirty days of material you did
 * not write and fixing the wording as you go. Everything is editable in place —
 * there is no separate "edit mode" to enter and leave, because that turns a
 * two-word correction into four clicks.
 */
export function ModuleEditorPage() {
  const { moduleId } = useParams<{ moduleId: string }>();
  const { data, isLoading, error, refetch } = useModuleForEditing(moduleId);
  const setStatus = useSetModuleStatus();

  if (isLoading) return <LoadingState label="Loading the module…" />;

  if (error || !data) {
    return (
      <ErrorState
        title="We could not load that module"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  const isPublished = data.module.status === 'published';

  return (
    <div className="space-y-5">
      <div className="print:hidden">
        <Link
          to="/admin/content"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          All content
        </Link>
      </div>

      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1>{data.module.title}</h1>
          <p className="mt-1">
            <span
              className={cn('console-label', isPublished ? 'text-success' : 'text-warning')}
            >
              {isPublished ? 'Published — advisors can see this' : 'Draft — advisors cannot see this'}
            </span>
          </p>
        </div>
        <Button
          variant={isPublished ? 'outline' : 'primary'}
          isLoading={setStatus.isPending}
          onClick={() =>
            void setStatus.mutateAsync({
              moduleId: data.module.id,
              status: isPublished ? 'draft' : 'published',
            })
          }
        >
          {isPublished ? 'Return to draft' : 'Publish this module'}
        </Button>
      </div>

      <ModuleDetails module={data.module} />

      {data.lessons.map((lesson) => (
        <LessonEditor key={lesson.id} lesson={lesson} />
      ))}

      {data.quizId ? (
        <QuizEditor quizId={data.quizId} />
      ) : (
        <Panel className="p-5">
          <p className="console-label">Quiz</p>
          <p className="mt-1 text-sm text-muted-foreground">
            This module has no quiz. Days without a quiz complete on their lessons alone.
          </p>
        </Panel>
      )}
    </div>
  );
}

function ModuleDetails({ module }: { module: { id: string; title: string; description: string | null; est_minutes: number } }) {
  const update = useUpdateModule();
  const [title, setTitle] = useState(module.title);
  const [description, setDescription] = useState(module.description ?? '');
  const [minutes, setMinutes] = useState(String(module.est_minutes));
  const [saved, setSaved] = useState(false);

  const dirty =
    title !== module.title ||
    description !== (module.description ?? '') ||
    minutes !== String(module.est_minutes);

  return (
    <Panel className="space-y-3 p-5">
      <p className="console-label">Module</p>

      <div className="space-y-1.5">
        <label htmlFor="module-title" className="block text-sm font-medium">
          Title
        </label>
        <AutoTextarea
          id="module-title"
          singleLine
          value={title}
          onChange={(event) => {
            setTitle(event.target.value.replace(/\s*\n\s*/g, ' '));
            setSaved(false);
          }}
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="module-description" className="block text-sm font-medium">
          Description
        </label>
        <textarea
          id="module-description"
          rows={3}
          value={description}
          onChange={(event) => {
            setDescription(event.target.value);
            setSaved(false);
          }}
          className={inputClass}
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="module-minutes" className="block text-sm font-medium">
          Estimated minutes
        </label>
        <input
          id="module-minutes"
          type="number"
          min={1}
          value={minutes}
          onChange={(event) => {
            setMinutes(event.target.value);
            setSaved(false);
          }}
          className={cn(inputClass, 'max-w-32')}
        />
      </div>

      <SaveRow
        dirty={dirty}
        saved={saved}
        pending={update.isPending}
        error={update.error}
        onSave={async () => {
          await update.mutateAsync({
            moduleId: module.id,
            title,
            description,
            estMinutes: Number(minutes) || 1,
          });
          setSaved(true);
        }}
      />
    </Panel>
  );
}

function LessonEditor({ lesson }: { lesson: Lesson }) {
  const update = useUpdateLesson();
  const [title, setTitle] = useState(lesson.title);
  const [body, setBody] = useState(lesson.body);
  const [saved, setSaved] = useState(false);

  const dirty = title !== lesson.title || body !== lesson.body;

  return (
    <Panel className="space-y-3 p-5">
      <p className="console-label">Lesson {lesson.sequence}</p>

      <AutoTextarea
        aria-label={`Lesson ${lesson.sequence} title`}
        singleLine
        value={title}
        onChange={(event) => {
          setTitle(event.target.value.replace(/\s*\n\s*/g, ' '));
          setSaved(false);
        }}
        className="font-semibold"
      />

      {/*
        A plain textarea. The lesson body is prose an advisor reads top to
        bottom; a rich editor would add formatting the reader never sees and a
        class of bugs nobody needs.

        It grows with the text rather than scrolling inside a fixed box, because
        a nested scroll area on a phone fights the page scroll — and reviewing
        thirty days of this on a phone is exactly what will happen.
      */}
      <AutoTextarea
        aria-label={`Lesson ${lesson.sequence} body`}
        value={body}
        onChange={(event) => {
          setBody(event.target.value);
          setSaved(false);
        }}
        className="font-mono text-sm leading-relaxed"
      />

      <SaveRow
        dirty={dirty}
        saved={saved}
        pending={update.isPending}
        error={update.error}
        onSave={async () => {
          await update.mutateAsync({ lessonId: lesson.id, title, body });
          setSaved(true);
        }}
      />
    </Panel>
  );
}

/**
 * The quiz.
 *
 * This is the only screen in the application that shows which option is
 * correct. The column is revoked from the whole `authenticated` role, so the
 * data arrives through a function that runs as the database owner and checks
 * the caller's role itself.
 */
function QuizEditor({ quizId }: { quizId: string }) {
  const { data, isLoading, error } = useQuizForAuthoring(quizId);
  const [adding, setAdding] = useState(false);

  if (isLoading) return <LoadingState label="Loading the quiz…" />;
  if (error || !data) {
    return (
      <ErrorState
        title="We could not load the quiz"
        description={error instanceof Error ? error.message : undefined}
      />
    );
  }

  return (
    <Panel className="space-y-4 p-5">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <p className="console-label">
          Quiz · {data.questions.length} questions · {data.quiz.pass_mark_pct}% to pass
        </p>
      </div>

      <Well>
        <p className="text-sm text-muted-foreground">
          The correct answer is shown here and nowhere else. Advisors cannot read it, whatever
          they send to the server — and neither can this screen without going through a
          function that checks who is asking.
        </p>
      </Well>

      {data.questions.map((question) => (
        <QuestionEditor key={question.id} quizId={quizId} question={question} />
      ))}

      {adding ? (
        <QuestionEditor
          quizId={quizId}
          question={{
            id: '',
            question_text: '',
            explanation: null,
            sequence: data.questions.length + 1,
            options: [
              { option_text: '', is_correct: true },
              { option_text: '', is_correct: false },
              { option_text: '', is_correct: false },
              { option_text: '', is_correct: false },
            ],
          }}
          onDone={() => setAdding(false)}
        />
      ) : (
        <Button variant="outline" onClick={() => setAdding(true)}>
          <Plus className="h-4 w-4" aria-hidden="true" />
          Add a question
        </Button>
      )}
    </Panel>
  );
}

function QuestionEditor({
  quizId,
  question,
  onDone,
}: {
  quizId: string;
  question: AuthoringQuestion;
  onDone?: () => void;
}) {
  const save = useSaveQuizQuestion();
  const remove = useDeleteQuizQuestion();

  const [text, setText] = useState(question.question_text);
  const [explanation, setExplanation] = useState(question.explanation ?? '');
  const [options, setOptions] = useState<AuthoringOption[]>(question.options);
  const [saved, setSaved] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  // Re-seed the boxes when the saved question actually changes — compared by
  // content, not by array identity, because a refetch hands back an equal-but-new
  // `options` array and resetting on that would discard what is being typed.
  const serverState = JSON.stringify(question);
  useEffect(() => {
    const fresh = JSON.parse(serverState) as AuthoringQuestion;
    setText(fresh.question_text);
    setExplanation(fresh.explanation ?? '');
    setOptions(fresh.options);
    // `saved` is deliberately left alone: the refetch that lands here is the one
    // our own save triggered, and clearing it would flash the confirmation away.
  }, [serverState]);

  const isNew = question.id === '';
  const explanationId = `explanation-${question.id || 'new'}`;
  const dirty = isNew
    ? // A blank new question has nothing to save. Saying so with a disabled
      // button beats letting the server refuse it.
      text.trim().length > 0
    : text !== question.question_text ||
      explanation !== (question.explanation ?? '') ||
      JSON.stringify(options) !== JSON.stringify(question.options);

  function setOption(index: number, patch: Partial<AuthoringOption>) {
    setOptions((current) =>
      current.map((option, i) => (i === index ? { ...option, ...patch } : option)),
    );
    setSaved(false);
  }

  /** Exactly one option is correct, so choosing one clears the rest. */
  function markCorrect(index: number) {
    setOptions((current) => current.map((option, i) => ({ ...option, is_correct: i === index })));
    setSaved(false);
  }

  return (
    <div className="rounded-md border border-white/[0.08] bg-panel/60 p-4">
      <AutoTextarea
        aria-label="Question"
        value={text}
        onChange={(event) => {
          setText(event.target.value);
          setSaved(false);
        }}
        placeholder="What is the question?"
        className="font-medium"
      />

      {/*
        One answer is correct, so these behave as radio buttons and are announced
        as such. Only the chosen one carries a tick: an earlier draft drew a tick
        on every option, which made a screen full of answers look like a screen
        full of correct answers.
      */}
      <div role="radiogroup" aria-label="Which option is the correct answer?" className="mt-3 space-y-2">
        {options.map((option, index) => (
          <div key={index} className="flex items-center gap-2">
            <button
              type="button"
              role="radio"
              aria-checked={option.is_correct}
              onClick={() => markCorrect(index)}
              aria-label={`Option ${index + 1} is the correct answer`}
              className={cn(
                'flex h-11 w-11 shrink-0 items-center justify-center rounded-full border transition-colors',
                option.is_correct
                  ? 'border-success/60 bg-success/20 text-success'
                  : 'border-white/15 hover:bg-white/[0.06]',
              )}
            >
              {option.is_correct ? (
                <Check className="h-4 w-4" strokeWidth={3} aria-hidden="true" />
              ) : (
                <span className="h-3.5 w-3.5 rounded-full border border-white/25" aria-hidden="true" />
              )}
            </button>
            <AutoTextarea
              aria-label={`Option ${index + 1}`}
              value={option.option_text}
              onChange={(event) => setOption(index, { option_text: event.target.value })}
              placeholder={`Option ${index + 1}`}
              className="min-h-[44px] py-2.5"
            />
          </div>
        ))}
      </div>
      <p className="mt-2 text-xs text-muted-foreground">
        The ticked option is the correct answer. Choosing another moves it.
      </p>

      <div className="mt-3 space-y-1.5">
        <label htmlFor={explanationId} className="block text-sm font-medium">
          Explanation <span className="font-normal text-muted-foreground">(shown only after a pass)</span>
        </label>
        <AutoTextarea
          id={explanationId}
          value={explanation}
          onChange={(event) => {
            setExplanation(event.target.value);
            setSaved(false);
          }}
          placeholder="Why is that the right answer?"
        />
      </div>

      <div className="mt-3 flex flex-wrap items-center gap-2">
        <Button
          size="sm"
          disabled={!dirty}
          isLoading={save.isPending}
          onClick={async () => {
            await save.mutateAsync({
              quizId,
              questionId: isNew ? null : question.id,
              questionText: text,
              explanation: explanation || null,
              sequence: question.sequence,
              options,
            });
            setSaved(true);
            onDone?.();
          }}
        >
          {isNew ? 'Add question' : 'Save question'}
        </Button>

        {saved && !dirty && <span className="console-label text-success">Saved</span>}

        <span className="flex-1" />

        {!isNew &&
          (confirmDelete ? (
            <>
              <span className="text-sm text-warning">Delete this question?</span>
              <Button
                size="sm"
                variant="danger"
                isLoading={remove.isPending}
                onClick={() => void remove.mutateAsync({ questionId: question.id })}
              >
                Delete
              </Button>
              <Button size="sm" variant="ghost" onClick={() => setConfirmDelete(false)}>
                Keep
              </Button>
            </>
          ) : (
            <Button size="sm" variant="ghost" onClick={() => setConfirmDelete(true)}>
              <Trash2 className="h-4 w-4" aria-hidden="true" />
              Delete
            </Button>
          ))}

        {onDone && isNew && (
          <Button size="sm" variant="ghost" onClick={onDone}>
            Cancel
          </Button>
        )}
      </div>

      {(save.isError || remove.isError) && (
        <p role="alert" className="mt-2 text-sm font-medium text-danger">
          {(save.error ?? remove.error) instanceof Error
            ? ((save.error ?? remove.error) as Error).message
            : 'That did not save.'}
        </p>
      )}
    </div>
  );
}
