import { Link } from 'react-router-dom';
import { CheckCircle2, ChevronRight, FileEdit } from 'lucide-react';
import { useContentOutline, useSetModuleStatus } from '@/api/authoring';
import { Panel } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { cn } from '@/lib/cn';

/**
 * The curriculum, by day.
 *
 * Publishing is the point of this screen. Everything arrives as Draft, which
 * advisors cannot see — the policies stop it at the database, and a day whose
 * required module is unpublished counts as incomplete, so nobody is advanced
 * past material that has not been reviewed.
 */
export function ContentPage() {
  const { data: outline, isLoading, error, refetch } = useContentOutline();
  const setStatus = useSetModuleStatus();

  if (isLoading) return <LoadingState label="Loading the curriculum…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load the curriculum"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!outline || outline.length === 0) {
    return (
      <div className="space-y-6">
        <h1>Content</h1>
        <EmptyState
          title="No curriculum loaded"
          description="Run the curriculum bundles from supabase/browser/ in the Supabase SQL Editor."
        />
      </div>
    );
  }

  const allModules = outline.flatMap((entry) => entry.modules);
  const published = allModules.filter((module) => module.status === 'published').length;

  // Group by phase, preserving curriculum order rather than sorting.
  const phases: { phase: string; entries: typeof outline }[] = [];
  for (const entry of outline) {
    const phase = entry.day.phase ?? 'Programme';
    const existing = phases.find((group) => group.phase === phase);
    if (existing) existing.entries.push(entry);
    else phases.push({ phase, entries: [entry] });
  }

  return (
    <div className="space-y-6">
      <div>
        <h1>Content</h1>
        <p className="mt-1 text-sm text-muted-foreground tabular">
          {published} of {allModules.length} modules published
        </p>
      </div>

      <Panel className="p-4">
        <p className="text-sm text-muted-foreground">
          Draft modules are invisible to advisors, and a day whose required module is still
          draft counts as incomplete — so nobody is advanced past material you have not
          cleared. Read a module, correct anything that needs it, then publish.
        </p>
      </Panel>

      {phases.map((group) => (
        <section key={group.phase} className="space-y-2">
          <h2 className="console-label">{group.phase}</h2>

          {group.entries.map(({ day, modules }) => (
            <Panel key={day.id} className="p-4">
              <p className="text-sm font-medium">
                <span className="tabular text-muted-foreground">
                  {String(day.day_number).padStart(2, '0')}
                </span>
                <span className="mx-2 text-white/15" aria-hidden="true">
                  /
                </span>
                {day.title}
              </p>

              {modules.length === 0 ? (
                <p className="mt-2 text-sm text-muted-foreground">No modules on this day.</p>
              ) : (
                <ul className="mt-3 space-y-2">
                  {modules.map((module) => {
                    const isPublished = module.status === 'published';
                    return (
                      <li
                        key={module.id}
                        className="flex flex-wrap items-center gap-2 rounded-md border border-white/[0.06] bg-panel/60 p-3"
                      >
                        <div className="min-w-0 flex-1">
                          <p className="text-sm font-medium">{module.title}</p>
                          <p className="mt-0.5 flex items-center gap-2 text-xs">
                            <span
                              className={cn(
                                'console-label',
                                isPublished ? 'text-success' : 'text-warning',
                              )}
                            >
                              {isPublished ? 'Published' : 'Draft'}
                            </span>
                            {module.is_required && (
                              <span className="console-label">Required</span>
                            )}
                          </p>
                        </div>

                        <Link
                          to={`/admin/content/modules/${module.id}`}
                          className="inline-flex min-h-[36px] items-center gap-1.5 rounded-md border border-white/15 bg-white/[0.04] px-3 text-sm font-medium transition-colors hover:bg-white/[0.09]"
                        >
                          <FileEdit className="h-3.5 w-3.5" aria-hidden="true" />
                          Review
                          <ChevronRight className="h-3.5 w-3.5" aria-hidden="true" />
                        </Link>

                        <Button
                          size="sm"
                          variant={isPublished ? 'ghost' : 'primary'}
                          isLoading={setStatus.isPending}
                          onClick={() =>
                            void setStatus.mutateAsync({
                              moduleId: module.id,
                              status: isPublished ? 'draft' : 'published',
                            })
                          }
                        >
                          {isPublished ? (
                            'Unpublish'
                          ) : (
                            <>
                              <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
                              Publish
                            </>
                          )}
                        </Button>
                      </li>
                    );
                  })}
                </ul>
              )}
            </Panel>
          ))}
        </section>
      ))}

      {setStatus.isError && (
        <p role="alert" className="text-sm font-medium text-danger">
          {setStatus.error instanceof Error
            ? setStatus.error.message
            : 'We could not change that.'}
        </p>
      )}
    </div>
  );
}
