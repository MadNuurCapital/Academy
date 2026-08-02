import { cn } from '@/lib/cn';

/**
 * The glass surface everything sits on.
 *
 * `interactive` adds the hover lift and press settle — use it only where the
 * whole panel is a link or a button, never as decoration, or the interface
 * promises a click it does not honour.
 *
 * `tone` tints the hairline and adds a left edge for panels that carry a state:
 * `current` is where the advisor is now, `warning` is something outstanding.
 * The tone is never the only signal — every panel using one also carries a word.
 */
export function Panel({
  className,
  interactive = false,
  tone = 'neutral',
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement> & {
  interactive?: boolean;
  tone?: 'neutral' | 'current' | 'warning';
}) {
  return (
    <div
      className={cn(
        'panel',
        interactive && 'panel-interactive',
        tone === 'current' && 'border-l-2 border-l-highlight',
        tone === 'warning' && 'border-l-2 border-l-warning',
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}

/**
 * Card is Panel.
 *
 * Kept as a separate export because roughly thirty screens already import it.
 * Pointing it at the same surface is what lets the whole application inherit
 * the console look without every page being rewritten.
 */
export function Card({ className, children, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <Panel className={className} {...props}>
      {children}
    </Panel>
  );
}

export function CardHeader({
  className,
  children,
}: {
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div className={cn('border-b border-white/[0.08] px-5 py-4', className)}>{children}</div>
  );
}

export function CardTitle({
  className,
  children,
}: {
  className?: string;
  children: React.ReactNode;
}) {
  return <h2 className={cn('text-base font-semibold text-foreground', className)}>{children}</h2>;
}

export function CardBody({ className, children }: { className?: string; children: React.ReactNode }) {
  return <div className={cn('px-5 py-4', className)}>{children}</div>;
}

/**
 * A well: a recessed surface for content that needs its own ground inside a
 * panel. Solid rather than glass, because glass on glass is the fastest way to
 * make a translucent interface unreadable.
 */
export function Well({ className, children }: { className?: string; children: React.ReactNode }) {
  return (
    <div className={cn('rounded-md border border-white/[0.06] bg-panel/60 p-3', className)}>
      {children}
    </div>
  );
}
