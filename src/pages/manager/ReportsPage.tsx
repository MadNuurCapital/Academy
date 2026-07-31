import { Download } from 'lucide-react';
import { useAllAdvisors, today } from '@/api/enrolments';
import { usePublicHolidays, useSettings } from '@/api/settings';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { ProgressBadge } from '@/components/ui/StatusBadge';
import { calculateProgress, createCalendar, type ProgressResult } from '@/lib/workingDays';
import { downloadCsv, toCsv } from '@/lib/csv';

const STATUS_LABELS: Record<string, string> = {
  on_track: 'On Track',
  attention_needed: 'Attention Needed',
  behind_schedule: 'Behind Schedule',
};

/**
 * Cohort progress reporting.
 *
 * Drift is computed with the same `calculateProgress` the dashboards use, so a
 * figure exported to a spreadsheet always matches the figure on screen. Two
 * implementations of the same arithmetic would eventually disagree, and the
 * report is the one people forward.
 */
export function ReportsPage() {
  const { data: advisors, isLoading } = useAllAdvisors();
  const { data: settings } = useSettings();
  const { data: holidays } = usePublicHolidays();

  if (isLoading) return <LoadingState label="Loading reports…" />;

  const enrolled = (advisors ?? []).filter((row) => row.enrolment !== null);

  const rows = enrolled.map((row) => {
    let progress: ProgressResult | null = null;
    if (row.enrolment && settings) {
      progress = calculateProgress({
        startDate: row.enrolment.start_date,
        asOf: today(),
        currentDay: row.enrolment.current_day,
        programmeLengthDays: settings.programmeLengthDays,
        calendar: createCalendar(holidays ?? [], settings.workingWeekdays),
        thresholds: {
          onTrackDays: settings.driftOnTrackDays,
          attentionDays: settings.driftAttentionDays,
        },
      });
    }
    return { ...row, progress };
  });

  function handleExport() {
    const csv = toCsv(
      [
        'Advisor', 'Email', 'Intake', 'Status', 'Day', 'Programme length',
        'Start date', 'Target end', 'Projected end', 'Drift (working days)', 'Progress',
      ],
      rows.map((row) => [
        row.profile.full_name,
        row.profile.email,
        row.enrolment?.intake_label ?? '',
        row.enrolment?.status ?? '',
        row.enrolment?.current_day ?? '',
        settings?.programmeLengthDays ?? '',
        row.enrolment?.start_date ?? '',
        row.progress?.targetEndDate ?? '',
        row.progress?.projectedEndDate ?? '',
        row.progress?.driftDays ?? '',
        row.progress ? STATUS_LABELS[row.progress.status] : '',
      ]),
    );
    downloadCsv(`atlas-progress-${new Date().toISOString().slice(0, 10)}`, csv);
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1>Reports</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Programme progress across every enrolled advisor.
          </p>
        </div>
        {rows.length > 0 && (
          <Button variant="outline" onClick={handleExport}>
            <Download className="h-4 w-4" aria-hidden="true" />
            Export CSV
          </Button>
        )}
      </div>

      {rows.length === 0 ? (
        <EmptyState
          title="Nothing to report yet"
          description="Reports appear once advisors are enrolled in the programme."
        />
      ) : (
        <Card>
          <CardHeader>
            <CardTitle>Programme progress</CardTitle>
          </CardHeader>
          <CardBody className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="border-b border-border bg-muted/50 text-left">
                  <tr>
                    <th scope="col" className="px-5 py-3 font-medium">Advisor</th>
                    <th scope="col" className="px-5 py-3 font-medium">Day</th>
                    <th scope="col" className="px-5 py-3 font-medium">Drift</th>
                    <th scope="col" className="px-5 py-3 font-medium">Projected finish</th>
                    <th scope="col" className="px-5 py-3 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {rows.map((row) => (
                    <tr key={row.profile.id}>
                      <td className="px-5 py-3 font-medium">{row.profile.full_name}</td>
                      <td className="px-5 py-3">
                        {row.enrolment?.current_day} of {settings?.programmeLengthDays ?? 30}
                      </td>
                      <td className="px-5 py-3">
                        {row.progress
                          ? row.progress.isAhead
                            ? 'Ahead'
                            : row.progress.driftDays === 0
                              ? 'On pace'
                              : `${row.progress.driftDays} days`
                          : '—'}
                      </td>
                      <td className="px-5 py-3">{row.progress?.projectedEndDate ?? '—'}</td>
                      <td className="px-5 py-3">
                        {row.progress && <ProgressBadge status={row.progress.status} />}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardBody>
        </Card>
      )}
    </div>
  );
}
