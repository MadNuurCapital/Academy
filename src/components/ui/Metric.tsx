import { useEffect, useState } from 'react';
import { cn } from '@/lib/cn';

/**
 * A single readout: label above, figure below, optional note.
 *
 * Figures use tabular numerals so a column of them lines up and a counter that
 * changes does not shift the layout under the reader.
 */
export function Metric({
  label,
  value,
  unit,
  note,
  tone = 'default',
  className,
}: {
  label: string;
  value: React.ReactNode;
  unit?: string;
  note?: string;
  tone?: 'default' | 'accent' | 'highlight' | 'success' | 'warning' | 'danger';
  className?: string;
}) {
  const toneClass = {
    default: 'text-foreground',
    accent: 'text-accent',
    highlight: 'text-highlight',
    success: 'text-success',
    warning: 'text-warning',
    danger: 'text-danger',
  }[tone];

  return (
    <div className={className}>
      <p className="console-label">{label}</p>
      <p className={cn('mt-1 text-3xl font-semibold tabular tracking-tight', toneClass)}>
        {value}
        {unit && <span className="ml-1 text-base font-normal text-muted-foreground">{unit}</span>}
      </p>
      {note && <p className="mt-1 text-sm text-muted-foreground">{note}</p>}
    </div>
  );
}

/**
 * The completion ring.
 *
 * Drawn as a stroked circle rather than an arc path so there is no trigonometry
 * to get wrong, and animated by transitioning `stroke-dashoffset` — a property
 * that costs nothing to animate and degrades to an instant fill when the
 * reduced-motion rule collapses its duration.
 *
 * The figure inside is the accessible value; the ring is its illustration.
 * `role="img"` with a written label means a screen reader gets the number and
 * never the geometry.
 */
export function ProgressRing({
  percent,
  label,
  caption,
  size = 132,
}: {
  percent: number;
  label: string;
  caption?: string;
  size?: number;
}) {
  const clamped = Math.max(0, Math.min(100, Math.round(percent)));
  const stroke = 8;
  const radius = (100 - stroke) / 2;
  const circumference = 2 * Math.PI * radius;

  // The ring sweeps from empty on mount. It starts at zero and moves to the
  // real value on the next frame, so the transition has something to animate;
  // the number in the middle is correct from the first paint either way, which
  // is what matters if the animation is suppressed or never runs.
  const [drawn, setDrawn] = useState(0);
  useEffect(() => {
    const frame = requestAnimationFrame(() => setDrawn(clamped));
    return () => cancelAnimationFrame(frame);
  }, [clamped]);

  return (
    <div
      className="relative inline-flex shrink-0 items-center justify-center"
      style={{ width: size, height: size }}
      role="img"
      aria-label={`${label}: ${clamped} per cent`}
    >
      <svg viewBox="0 0 100 100" className="h-full w-full -rotate-90" aria-hidden="true">
        <circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          strokeWidth={stroke}
          className="stroke-white/[0.07]"
        />
        <circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          strokeWidth={stroke}
          strokeLinecap="round"
          className="stroke-accent transition-[stroke-dashoffset] duration-[900ms] ease-console"
          style={{
            strokeDasharray: circumference,
            strokeDashoffset: circumference * (1 - drawn / 100),
          }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-2xl font-semibold tabular tracking-tight">{clamped}%</span>
        {caption && <span className="console-label mt-0.5">{caption}</span>}
      </div>
    </div>
  );
}
