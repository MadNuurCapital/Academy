import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft, Download } from 'lucide-react';
import { useAllAdvisors } from '@/api/enrolments';
import { useAttendanceHistory } from '@/api/attendance';
import { Button } from '@/components/ui/Button';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatLongDate } from '@/lib/formatDate';
import { downloadCsv, toCsv } from '@/lib/csv';
import { cn } from '@/lib/cn';

const STATUS_STYLES: Record<string, string> = {
  present: 'text-success',
  late: 'text-warning',
  absent: 'text-danger',
};

export function AttendanceHistoryPage() {
  const [advisorId, setAdvisorId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  const { data: advisors } = useAllAdvisors();
  const { data: records, isLoading, error, refetch } = useAttendanceHistory({
    advisorId: advisorId || undefined,
    from: from || undefined,
    to: to || undefined,
  });

  function handleExport() {
    const csv = toCsv(
      ['Date', 'Advisor', 'Status', 'Remarks'],
      (records ?? []).map((record) => [
        record.attendance_date,
        record.profiles?.full_name ?? '',
        record.status,
        record.remarks ?? '',
      ]),
    );
    downloadCsv(`atlas-attendance-${new Date().toISOString().slice(0, 10)}`, csv);
  }

  return (
    <div className="space-y-6">
      <div>
        <Link
          to="/manage/attendance"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Today's attendance
        </Link>
        <h1 className="mt-2">Attendance history</h1>
      </div>

      <Card>
        <CardBody className="grid gap-4 sm:grid-cols-3">
          <div className="space-y-1.5">
            <label htmlFor="filter-advisor" className="block text-sm font-medium">
              Advisor
            </label>
            <select
              id="filter-advisor"
              value={advisorId}
              onChange={(event) => setAdvisorId(event.target.value)}
              className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
            >
              <option value="">All advisors</option>
              {(advisors ?? []).map(({ profile }) => (
                <option key={profile.id} value={profile.id}>
                  {profile.full_name}
                </option>
              ))}
            </select>
          </div>
          <div className="space-y-1.5">
            <label htmlFor="filter-from" className="block text-sm font-medium">
              From
            </label>
            <input
              id="filter-from"
              type="date"
              value={from}
              onChange={(event) => setFrom(event.target.value)}
              className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
            />
          </div>
          <div className="space-y-1.5">
            <label htmlFor="filter-to" className="block text-sm font-medium">
              To
            </label>
            <input
              id="filter-to"
              type="date"
              value={to}
              onChange={(event) => setTo(event.target.value)}
              className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
            />
          </div>
        </CardBody>
      </Card>

      {isLoading ? (
        <LoadingState label="Loading attendance…" />
      ) : error ? (
        <ErrorState
          title="We could not load attendance history"
          description={error instanceof Error ? error.message : undefined}
          onRetry={() => void refetch()}
        />
      ) : !records || records.length === 0 ? (
        <EmptyState
          title="No attendance records"
          description="Nothing matches those filters. Try widening the date range."
        />
      ) : (
        <>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <p className="text-sm text-muted-foreground">
              {records.length} {records.length === 1 ? 'record' : 'records'}
            </p>
            <Button variant="outline" onClick={handleExport}>
              <Download className="h-4 w-4" aria-hidden="true" />
              Export CSV
            </Button>
          </div>

          {/* Mobile */}
          <div className="space-y-2 md:hidden">
            {records.map((record) => (
              <Card key={record.id}>
                <CardBody className="py-3">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium">
                        {record.profiles?.full_name ?? 'Unknown'}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {formatLongDate(record.attendance_date)}
                      </p>
                    </div>
                    <span
                      className={cn(
                        'shrink-0 text-sm font-medium capitalize',
                        STATUS_STYLES[record.status],
                      )}
                    >
                      {record.status}
                    </span>
                  </div>
                  {record.remarks && (
                    <p className="mt-1 text-xs text-muted-foreground">{record.remarks}</p>
                  )}
                </CardBody>
              </Card>
            ))}
          </div>

          {/* Desktop */}
          <Card className="hidden md:block">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="border-b border-border bg-muted/50 text-left">
                  <tr>
                    <th scope="col" className="px-5 py-3 font-medium">Date</th>
                    <th scope="col" className="px-5 py-3 font-medium">Advisor</th>
                    <th scope="col" className="px-5 py-3 font-medium">Status</th>
                    <th scope="col" className="px-5 py-3 font-medium">Remarks</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {records.map((record) => (
                    <tr key={record.id}>
                      <td className="px-5 py-3">{formatLongDate(record.attendance_date)}</td>
                      <td className="px-5 py-3">{record.profiles?.full_name ?? 'Unknown'}</td>
                      <td className={cn('px-5 py-3 font-medium capitalize', STATUS_STYLES[record.status])}>
                        {record.status}
                      </td>
                      <td className="px-5 py-3 text-muted-foreground">{record.remarks ?? '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        </>
      )}
    </div>
  );
}
