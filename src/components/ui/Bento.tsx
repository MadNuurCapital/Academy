import { cn } from '@/lib/cn';

/**
 * The bento grid.
 *
 * Six columns on a laptop, two on a tablet, one on a phone. Tiles declare how
 * many they span and the grid does the rest, so a dashboard is written as an
 * ordered list of tiles rather than as a nest of flex containers.
 *
 * Source order IS priority order. On a phone every tile collapses to full width
 * in the order written, so the most important thing must be written first —
 * which is the discipline that keeps a bento grid from becoming a mosaic of
 * equally-shouting boxes.
 */
export function Bento({ className, children }: { className?: string; children: React.ReactNode }) {
  return (
    <div className={cn('grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-6', className)}>
      {children}
    </div>
  );
}

const SPANS = {
  /** Full width. The hero. */
  hero: 'sm:col-span-2 lg:col-span-6',
  /** Two thirds. */
  wide: 'sm:col-span-2 lg:col-span-4',
  /** Half. */
  half: 'sm:col-span-1 lg:col-span-3',
  /** A third. */
  third: 'sm:col-span-1 lg:col-span-2',
} as const;

/**
 * A tile.
 *
 * Entrance is staggered by index — 40ms apart, capped so a long grid does not
 * take a second to settle. The animation is `both`-filled from an opacity of
 * zero, so under `prefers-reduced-motion` (where the duration collapses to
 * nothing) tiles simply appear rather than never arriving.
 */
export function BentoTile({
  span = 'third',
  index = 0,
  className,
  children,
}: {
  span?: keyof typeof SPANS;
  index?: number;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div
      className={cn(SPANS[span], 'animate-panel-in', className)}
      style={{ animationDelay: `${Math.min(index, 8) * 40}ms` }}
    >
      {children}
    </div>
  );
}
