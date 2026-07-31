import { Link } from 'react-router-dom';
import { UserPlus } from 'lucide-react';
import { useAllAdvisors, today } from '@/api/enrolments';
import { usePublicHolidays, useSettings } from '@/api/settings';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { ProgressBadge } from '@/components/ui/StatusBadge';
import { calculateProgress, createCalendar, type ProgressResult } from '@/lib/workingDays';
import type { Enrolment } from '@/types/database';

/**
 * Every advisor, with the drift that answers "who is behind schedule?".
 *
 * The table collapses to cards below the medium breakpoint rather than
 * scrolling horizontally, because a manager checking on someone from their
 * phone should not have to pan sideways to read a status.
 */
export function AdvisorListPage() {
  const { data: advisors, isLoading, error, refetch } = useAllAdvisors();
  const { data: settings } = useSettings();
  const { data: holidays } = usePublicHolidays();

  if (isLoading) return <LoadingState label="Loading advisors…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load your advisors"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  function progressFor(enrolment: Enrolment | null): ProgressResult | null {
    if (!enrolment || !settings) return null;
    return calculateProgress({
      startDate: enrolment.start_date,
      asOf: today(),
      currentDay: enrolment.current_day,
      programmeLengthDays: settings.programmeLengthDays,
      calendar: createCalendar(holidays ?? [], settings.workingWeekdays),
      thresholds: {
        onTrackDays: settings.driftOnTrackDays,
        attentionDays: settings.driftAttentionDays,
      },
    });
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1>Advisors</h1>
        <Link
          to="/manage/enrol"
          className="inline-flex min-h-[44px] items-center gap-2 rounded-md bg-accent px-4 text-sm font-medium text-accent-foreground hover:bg-accent/90"
        >
          <UserPlus className="h-4 w-4" aria-hidden="true" />
          Enrol an advisor
        </Link>
      </div>

      {!advisors || advisors.length === 0 ? (
        <EmptyState
          title="No advisors yet"
          description="Advisors appear here once an administrator has created their accounts."
        />
      ) : (
        <>
          {/* Mobile */}
          <div className="space-y-3 md:hidden">
            {advisors.map(({ profile, enrolment }) => {
              const progress = progressFor(enrolment);
              return (
                <Link key={profile.id} to={`/manage/advisors/${profile.id}`} className="block">
                  <Card className="hover:border-accent/40">
                    <CardBody className="space-y-2">
                      <div className="flex items-start justify-between gap-2">
                        <p className="font-medium">{profile.full_name}</p>
                        {progress && <ProgressBadge status={progress.status} />}
                      </div>
                      <p className="text-sm text-muted-foreground">
                        {enrolment
                          ? `Day ${enrolment.current_day}${progress && progress.driftDays > 0 ? ` · ${progress.driftDays} days behind` : ''}`
                          : 'Not enrolled'}
                      </p>
                    </CardBody>
                  </Card>
                </Link>
              );
            })}
          </div>

          {/* Desktop */}
          <Card className="hidden md:block">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="border-b border-border bg-muted/50 text-left">
                  <tr>
                    <th scope="col" className="px-5 py-3 font-medium">Advisor</th>
                    <th scope="col" className="px-5 py-3 font-medium">Day</th>
                    <th scope="col" className="px-5 py-3 font-medium">Drift</th>
                    <th scope="col" className="px-5 py-3 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {advisors.map(({ profile, enrolment }) => {
                    const progress = progressFor(enrolment);
                    return (
                      <tr key={profile.id} className="hover:bg-muted/40">
                        <td className="px-5 py-3">
                          <Link
                            to={`/manage/advisors/${profile.id}`}
                            className="font-medium text-accent hover:underline"
                          >
                            {profile.full_name}
                          </Link>
                        </td>
                        <td className="px-5 py-3">
                          {enrolment ? `${enrolment.current_day} of ${settings?.programmeLengthDays ?? 30}` : '—'}
                        </td>
                        <td className="px-5 py-3">
                          {progress
                            ? progress.isAhead
                              ? 'Ahead'
                              : progress.driftDays === 0
                                ? 'On pace'
                                : `${progress.driftDays} days`
                            : '—'}
                        </td>
                        <td className="px-5 py-3">
                          {progress ? (
                            <ProgressBadge status={progress.status} />
                          ) : (
                            <span className="text-muted-foreground">Not enrolled</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </Card>
        </>
      )}
    </div>
  );
}
