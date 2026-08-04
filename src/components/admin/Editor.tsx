import { useLayoutEffect, useRef } from 'react';
import { ChevronDown, ChevronUp, Plus, X } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { inputClass } from './editorState';
import { cn } from '@/lib/cn';
import type { ContentStatus } from '@/types/database';

/**
 * The parts every authoring screen needs.
 *
 * Modules, scripts and concept presentations are different shapes but the same
 * job: read what is there, correct the wording, publish when it is right. These
 * are the pieces that job is made of, kept in one place so a fix to any of them
 * reaches all three.
 */

/**
 * A text box that grows to fit what is in it.
 *
 * Most of what an author reads here is one to three lines on a laptop and three
 * to six on a phone. A fixed height clips it, and clipped text on screens whose
 * entire purpose is reading and correcting wording is a bad trade for a tidier
 * column.
 */
export function AutoTextarea({
  value,
  onChange,
  className,
  singleLine,
  ...rest
}: React.TextareaHTMLAttributes<HTMLTextAreaElement> & {
  value: string;
  /**
   * For titles: wraps onto as many lines as it needs to be read, but refuses to
   * take a line break, because a title with a newline in it renders as one long
   * run everywhere else in the application.
   */
  singleLine?: boolean;
}) {
  const ref = useRef<HTMLTextAreaElement>(null);

  useLayoutEffect(() => {
    const element = ref.current;
    if (!element) return;

    function fit() {
      if (!element) return;
      element.style.height = 'auto';
      element.style.height = `${element.scrollHeight}px`;
    }

    fit();
    // Narrowing the window rewraps the text, which changes the height it needs.
    window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, [value]);

  return (
    <textarea
      ref={ref}
      rows={1}
      value={value}
      onChange={onChange}
      onKeyDown={
        singleLine
          ? (event) => {
              if (event.key === 'Enter') event.preventDefault();
            }
          : undefined
      }
      className={cn(inputClass, 'resize-none overflow-hidden', className)}
      {...rest}
    />
  );
}

/** A labelled field. The label is always a real one, tied to its control. */
export function Field({
  id,
  label,
  hint,
  value,
  onChange,
  singleLine,
  className,
  placeholder,
}: {
  id: string;
  label: string;
  hint?: string;
  value: string;
  onChange: (next: string) => void;
  singleLine?: boolean;
  className?: string;
  placeholder?: string;
}) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={id} className="block text-sm font-medium">
        {label}
        {hint && <span className="ml-1.5 font-normal text-muted-foreground">{hint}</span>}
      </label>
      <AutoTextarea
        id={id}
        singleLine={singleLine}
        value={value}
        placeholder={placeholder}
        onChange={(event) =>
          onChange(singleLine ? event.target.value.replace(/\s*\n\s*/g, ' ') : event.target.value)
        }
        className={className}
      />
    </div>
  );
}

/**
 * A list of short strings — talking points, common mistakes, the steps of a
 * concept presentation.
 *
 * These are stored as jsonb arrays. Editing them as one textarea of newline-
 * separated lines was the tempting shortcut; it breaks the moment a point runs
 * to two lines, which several of them do.
 */
export function ListEditor({
  label,
  hint,
  items,
  onChange,
  addLabel = 'Add',
}: {
  label: string;
  hint?: string;
  items: string[];
  onChange: (next: string[]) => void;
  addLabel?: string;
}) {
  function move(index: number, delta: number) {
    const target = index + delta;
    if (target < 0 || target >= items.length) return;
    const next = [...items];
    const [moved] = next.splice(index, 1);
    next.splice(target, 0, moved!);
    onChange(next);
  }

  return (
    <div className="space-y-1.5">
      <p className="text-sm font-medium">
        {label}
        {hint && <span className="ml-1.5 font-normal text-muted-foreground">{hint}</span>}
      </p>

      {items.length === 0 ? (
        <p className="text-sm text-muted-foreground">Nothing here yet.</p>
      ) : (
        <ul className="space-y-2">
          {items.map((item, index) => (
            <li key={index} className="flex items-start gap-2">
              <div className="flex shrink-0 flex-col pt-1">
                <button
                  type="button"
                  onClick={() => move(index, -1)}
                  disabled={index === 0}
                  aria-label={`Move "${item.slice(0, 30)}" up`}
                  className="flex h-6 w-8 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-white/[0.06] hover:text-foreground disabled:opacity-30 disabled:hover:bg-transparent"
                >
                  <ChevronUp className="h-4 w-4" aria-hidden="true" />
                </button>
                <button
                  type="button"
                  onClick={() => move(index, 1)}
                  disabled={index === items.length - 1}
                  aria-label={`Move "${item.slice(0, 30)}" down`}
                  className="flex h-6 w-8 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-white/[0.06] hover:text-foreground disabled:opacity-30 disabled:hover:bg-transparent"
                >
                  <ChevronDown className="h-4 w-4" aria-hidden="true" />
                </button>
              </div>
              <AutoTextarea
                aria-label={`${label}, item ${index + 1}`}
                value={item}
                onChange={(event) =>
                  onChange(items.map((existing, i) => (i === index ? event.target.value : existing)))
                }
              />
              <button
                type="button"
                onClick={() => onChange(items.filter((_, i) => i !== index))}
                aria-label={`Remove "${item.slice(0, 30)}"`}
                className="mt-0.5 flex h-11 w-11 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-danger/15 hover:text-danger"
              >
                <X className="h-4 w-4" aria-hidden="true" />
              </button>
            </li>
          ))}
        </ul>
      )}

      <Button size="sm" variant="outline" onClick={() => onChange([...items, ''])}>
        <Plus className="h-4 w-4" aria-hidden="true" />
        {addLabel}
      </Button>
    </div>
  );
}

/** Draft or published, in words rather than a colour alone. */
export function StatusLabel({ status }: { status: ContentStatus }) {
  const isPublished = status === 'published';
  return (
    <span className={cn('console-label', isPublished ? 'text-success' : 'text-warning')}>
      {isPublished ? 'Published' : 'Draft'}
    </span>
  );
}

export function SaveRow({
  dirty,
  saved,
  pending,
  error,
  onSave,
  label = 'Save',
}: {
  dirty: boolean;
  saved: boolean;
  pending: boolean;
  error: unknown;
  onSave: () => Promise<void>;
  label?: string;
}) {
  return (
    <div className="flex flex-wrap items-center gap-3">
      <Button size="sm" disabled={!dirty} isLoading={pending} onClick={() => void onSave()}>
        {label}
      </Button>
      {saved && !dirty && <span className="console-label text-success">Saved</span>}
      {error instanceof Error && (
        <span role="alert" className="text-sm font-medium text-danger">
          {error.message}
        </span>
      )}
    </div>
  );
}
