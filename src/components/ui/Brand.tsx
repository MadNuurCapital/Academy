import { cn } from '@/lib/cn';

/**
 * The wordmark.
 *
 * One component, used by both the app shell and the login screens, so the two
 * cannot drift apart. When a real logo arrives it replaces the markup here and
 * nothing at the call sites has to change.
 *
 * `sm` is the sidebar and mobile header; `lg` is the login screens.
 */
export function Brand({ size = 'sm', className }: { size?: 'sm' | 'lg'; className?: string }) {
  const isLarge = size === 'lg';

  return (
    <div className={cn(isLarge && 'text-center', className)}>
      <div className={cn('flex items-baseline gap-2', isLarge && 'justify-center')}>
        <span
          className={cn(
            'font-bold tracking-tight text-foreground',
            isLarge ? 'text-2xl' : 'text-lg',
          )}
        >
          ATLAS
        </span>
        <span className={cn('font-medium text-muted-foreground', isLarge ? 'text-base' : 'text-sm')}>
          Academy
        </span>
      </div>
      <p
        className={cn(
          'leading-tight text-muted-foreground',
          isLarge ? 'mt-1 text-sm font-medium' : 'mt-0.5 text-[11px]',
        )}
      >
        Integrated Barakah Wealth Advisory
      </p>
    </div>
  );
}
