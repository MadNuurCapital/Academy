import { forwardRef, useId } from 'react';
import { cn } from '@/lib/cn';

export interface FieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string | undefined;
  hint?: string | undefined;
}

/**
 * A labelled input.
 *
 * The label is always a real <label> bound to the input, and errors are wired
 * through aria-describedby with role="alert", so a screen reader announces the
 * problem rather than leaving the field silently red.
 */
export const Field = forwardRef<HTMLInputElement, FieldProps>(
  ({ label, error, hint, className, id, ...props }, ref) => {
    const generatedId = useId();
    const inputId = id ?? generatedId;
    const errorId = `${inputId}-error`;
    const hintId = `${inputId}-hint`;

    const describedBy = [error ? errorId : null, hint ? hintId : null].filter(Boolean).join(' ');

    return (
      <div className="space-y-1.5">
        <label htmlFor={inputId} className="block text-sm font-medium text-foreground">
          {label}
        </label>
        <input
          ref={ref}
          id={inputId}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy || undefined}
          className={cn(
            'w-full rounded-md border border-input bg-surface px-3 py-2.5 text-base',
            'placeholder:text-muted-foreground',
            'disabled:cursor-not-allowed disabled:bg-muted',
            error && 'border-danger',
            className,
          )}
          {...props}
        />
        {hint && !error && (
          <p id={hintId} className="text-sm text-muted-foreground">
            {hint}
          </p>
        )}
        {error && (
          <p id={errorId} role="alert" className="text-sm font-medium text-danger">
            {error}
          </p>
        )}
      </div>
    );
  },
);

Field.displayName = 'Field';
