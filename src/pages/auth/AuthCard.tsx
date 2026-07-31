export function AuthCard({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 py-10">
      <div className="w-full max-w-sm">
        <div className="mb-6 text-center">
          <div className="flex items-baseline justify-center gap-2">
            <span className="text-2xl font-bold tracking-tight text-foreground">ATLAS</span>
            <span className="text-base font-medium text-muted-foreground">Academy</span>
          </div>
          <p className="mt-1 text-xs text-muted-foreground">
            Advisor Training, Learning &amp; Assessment System
          </p>
        </div>

        <div className="rounded-lg border border-border bg-surface p-6 shadow-sm">
          <h1 className="text-xl font-semibold text-foreground">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-muted-foreground">{subtitle}</p>}
          <div className="mt-6">{children}</div>
        </div>
      </div>
    </div>
  );
}
