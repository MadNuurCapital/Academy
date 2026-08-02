import { cn } from '@/lib/cn';

/**
 * The ATLAS Academy lockup: the mark, the wordmark, and the firm beneath.
 *
 * One component, used by both the app shell and the login screens, so the two
 * cannot drift apart.
 *
 * `sm` is the sidebar and mobile header; `lg` is the login screens.
 */
export function Brand({ size = 'sm', className }: { size?: 'sm' | 'lg'; className?: string }) {
  const isLarge = size === 'lg';

  return (
    <div className={cn(isLarge && 'text-center', className)}>
      <div className={cn('flex items-center gap-2.5', isLarge && 'justify-center gap-3')}>
        {/*
         * In the artwork the mark stands about a fifth taller than the two
         * lines of wordmark beside it. These sizes keep that proportion.
         */}
        <BrandMark className={isLarge ? 'h-14 w-14' : 'h-9 w-9'} />
        <div className="leading-none">
          <div
            className={cn(
              'font-bold tracking-tight text-brand',
              isLarge ? 'text-2xl' : 'text-[15px]',
            )}
          >
            ATLAS
          </div>
          <div
            className={cn('mt-1 font-medium text-brand', isLarge ? 'text-xl' : 'text-[13px]')}
          >
            Academy
          </div>
        </div>
      </div>
      <p
        className={cn(
          'leading-tight text-muted-foreground',
          isLarge ? 'mt-3 text-sm font-medium' : 'mt-1 text-[11px]',
        )}
      >
        Integrated Barakah Wealth Advisory
      </p>
    </div>
  );
}

/**
 * The mark, rebuilt as vector geometry from the supplied artwork
 * (docs/brand/atlas-academy-logo.jpg) rather than cropped out of it: the file
 * is a JPEG on baked-in white, which would show as a white square on any
 * surface that is not white, and would go soft as soon as it scaled.
 *
 * Every rectangle below was measured off that artwork. The mark is 160px there;
 * normalised to a 100-unit box, the stroke is 21 units, the top bar begins at
 * 32 and the left arm at 32. The inner square is drawn centred: the artwork
 * measures a half-unit right and low of centre, which is a sub-pixel difference
 * at every size this renders and reads as a scan artefact rather than intent.
 *
 * Colours come from --colour-brand and --colour-brand-accent, which exist so
 * the logo does not change if someone later retunes the interface accent.
 */
export function BrandMark({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 100 100"
      className={cn('shrink-0', className)}
      role="img"
      aria-label="ATLAS Academy"
    >
      <rect x="0" y="0" width="21" height="21" className="fill-brand-accent" />
      <g className="fill-brand">
        <rect x="32" y="0" width="68" height="21" />
        <rect x="79" y="0" width="21" height="100" />
        <rect x="0" y="79" width="100" height="21" />
        <rect x="0" y="32" width="21" height="47" />
        <rect x="39.5" y="39.5" width="21" height="21" />
      </g>
    </svg>
  );
}
