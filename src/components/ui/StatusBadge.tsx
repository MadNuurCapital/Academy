import { cn } from '@/lib/cn';
import type { ProgressStatus } from '@/lib/workingDays';

/**
 * Plain status labels, deliberately not gamified.
 *
 * Colour is never the only signal — each badge carries its own words — so the
 * meaning survives greyscale printing and colour-blindness.
 */

const PROGRESS_LABELS: Record<ProgressStatus, string> = {
  on_track: 'On Track',
  attention_needed: 'Attention Needed',
  behind_schedule: 'Behind Schedule',
};

const PROGRESS_STYLES: Record<ProgressStatus, string> = {
  on_track: 'bg-success/10 text-success border-success/20',
  attention_needed: 'bg-warning/10 text-warning border-warning/20',
  behind_schedule: 'bg-danger/10 text-danger border-danger/20',
};

export function ProgressBadge({ status }: { status: ProgressStatus }) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium',
        PROGRESS_STYLES[status],
      )}
    >
      {PROGRESS_LABELS[status]}
    </span>
  );
}

export type DayState = 'locked' | 'unlocked' | 'complete';

const DAY_LABELS: Record<DayState, string> = {
  locked: 'Locked',
  unlocked: 'Available',
  complete: 'Complete',
};

const DAY_STYLES: Record<DayState, string> = {
  locked: 'bg-muted text-muted-foreground border-border',
  unlocked: 'bg-accent/10 text-accent border-accent/20',
  complete: 'bg-success/10 text-success border-success/20',
};

export function DayBadge({ state }: { state: DayState }) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium',
        DAY_STYLES[state],
      )}
    >
      {DAY_LABELS[state]}
    </span>
  );
}

export function ProgressBar({ percent, label }: { percent: number; label?: string }) {
  const clamped = Math.max(0, Math.min(100, percent));
  return (
    <div className="space-y-1">
      <div
        className="h-1.5 w-full overflow-hidden rounded-full bg-white/[0.07]"
        role="progressbar"
        aria-valuenow={clamped}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={label ?? 'Programme progress'}
      >
        <div
          className="h-full origin-left rounded-full bg-accent transition-[width] duration-[600ms] ease-console"
          style={{ width: `${clamped}%` }}
        />
      </div>
    </div>
  );
}
