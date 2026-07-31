import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { CalendarOff, Check, CheckCircle2, History } from 'lucide-react';
import { useAllAdvisors, today } from '@/api/enrolments';
import {
  useAttendanceForDate,
  useIsWorkingDay,
  useSaveAttendance,
  type AttendanceEntry,
} from '@/api/attendance';
import { Button } from '@/components/ui/Button';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { formatWeekdayDate } from '@/lib/formatDate';
import { cn } from '@/lib/cn';
import type { AttendanceStatus } from '@/types/database';

/**
 * Today's attendance.
 *
 * The whole point of this screen is speed: open it, press Mark All Present,
 * adjust the two or three exceptions, save. It should be under a minute for the
 * whole room, so the entire save is a single call rather than one request per
 * advisor.
 *
 * The one place it deliberately slows down is changing something already saved.
 * There are no correction requests in this system — a manager simply edits the
 * record — so an edit demands a reason, which is recorded permanently.
 */
export function TodayAttendancePage() {
  const [date, setDate] = useState(today());
  const { data: advisors, isLoading: advisorsLoading, error: advisorsError } = useAllAdvisors();
  const { data: existing, isLoading: existingLoading } = useAttendanceForDate(date);
  const { data: isWorkingDay, isLoading: workingDayLoading } = useIsWorkingDay(date);
  const save = useSaveAttendance();

  const [draft, setDraft] = useState<Record<string, AttendanceStatus>>({});
  const [remarks, setRemarks] = useState<Record<string, string>>({});
  const [reasons, setReasons] = useState<Record<string, string>>({});
  const [saved, setSaved] = useState<{ present: number; late: number; absent: number } | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);

  // Only advisors on a live programme are expected in the office. A paused or
  // completed enrolment should not appear in the room.
  const expected = useMemo(
    () =>
      (advisors ?? []).filter(
        (row) => row.enrolment && ['active', 'extended'].includes(row.enrolment.status),
      ),
    [advisors],
  );

  const existingByAdvisor = useMemo(() => {
    const map = new Map<string, { status: AttendanceStatus; remarks: string | null }>();
    for (const record of existing ?? []) {
      map.set(record.advisor_id, { status: record.status, remarks: record.remarks });
    }
    return map;
  }, [existing]);

  // Seed the form from what is already saved, so reopening the screen shows the
  // room as it stands rather than a blank slate.
  useEffect(() => {
    const seededDraft: Record<string, AttendanceStatus> = {};
    const seededRemarks: Record<string, string> = {};
    for (const [advisorId, record] of existingByAdvisor) {
      seededDraft[advisorId] = record.status;
      if (record.remarks) seededRemarks[advisorId] = record.remarks;
    }
    setDraft(seededDraft);
    setRemarks(seededRemarks);
    setReasons({});
    setSaved(null);
  }, [existingByAdvisor, date]);

  if (advisorsLoading || existingLoading || workingDayLoading) {
    return <LoadingState label="Loading today's room…" />;
  }

  if (advisorsError) {
    return (
      <ErrorState
        title="We could not load your advisors"
        description={advisorsError instanceof Error ? advisorsError.message : undefined}
      />
    );
  }

  function markAllPresent() {
    const next: Record<string, AttendanceStatus> = { ...draft };
    for (const row of expected) next[row.profile.id] = 'present';
    setDraft(next);
  }

  /** Which advisors have a saved status that this draft would change. */
  const changedAdvisors = expected.filter((row) => {
    const current = existingByAdvisor.get(row.profile.id);
    const next = draft[row.profile.id];
    return current && next && current.status !== next;
  });

  const missingReasons = changedAdvisors.filter(
    (row) => !reasons[row.profile.id]?.trim(),
  );

  async function handleSave() {
    setSaveError(null);
    const entries: AttendanceEntry[] = expected
      .filter((row) => draft[row.profile.id])
      .map((row) => ({
        advisor_id: row.profile.id,
        status: draft[row.profile.id]!,
        remarks: remarks[row.profile.id]?.trim() || null,
        reason: reasons[row.profile.id]?.trim() || null,
      }));

    if (entries.length === 0) {
      setSaveError('Mark at least one advisor before saving.');
      return;
    }

    try {
      const result = await save.mutateAsync({ date, entries });
      setSaved({ present: result.present, late: result.late, absent: result.absent });
      setReasons({});
    } catch (error) {
      setSaveError(error instanceof Error ? error.message : 'We could not save attendance.');
    }
  }

  const markedCount = expected.filter((row) => draft[row.profile.id]).length;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1>Today's attendance</h1>
          <p className="mt-1 text-sm text-muted-foreground">{formatWeekdayDate(date)}</p>
        </div>
        <Link
          to="/manage/attendance/history"
          className="inline-flex min-h-[44px] items-center gap-2 rounded-md border border-border bg-surface px-4 text-sm font-medium hover:bg-muted"
        >
          <History className="h-4 w-4" aria-hidden="true" />
          History
        </Link>
      </div>

      <div className="space-y-1.5">
        <label htmlFor="attendance-date" className="block text-sm font-medium">
          Date
        </label>
        <input
          id="attendance-date"
          type="date"
          value={date}
          max={today()}
          onChange={(event) => setDate(event.target.value)}
          className="min-h-[44px] rounded-md border border-input bg-surface px-3 py-2 text-base"
        />
      </div>

      {/*
        Weekends and public holidays are refused by the database, not merely
        discouraged here — recording attendance on one would corrupt every
        percentage derived from it.
      */}
      {isWorkingDay === false ? (
        <EmptyState
          icon={CalendarOff}
          title="Not a working day"
          description="Attendance is only recorded on working days. Weekends and Singapore public holidays are excluded from the programme."
        />
      ) : expected.length === 0 ? (
        <EmptyState
          title="Nobody is expected in the office"
          description="No advisors are currently on a live programme. Paused and completed enrolments are not shown here."
        />
      ) : (
        <>
          {saved && (
            <div
              role="status"
              className="flex items-start gap-3 rounded-md border border-success/30 bg-success/5 px-4 py-3"
            >
              <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success" aria-hidden="true" />
              <div>
                <p className="font-medium">Today's attendance completed</p>
                <p className="text-sm text-muted-foreground">
                  {saved.present} Present, {saved.late} Late, {saved.absent} Absent
                </p>
              </div>
            </div>
          )}

          <div className="flex flex-wrap items-center justify-between gap-3">
            <p className="text-sm text-muted-foreground">
              {markedCount} of {expected.length} marked
            </p>
            <Button variant="outline" onClick={markAllPresent}>
              <Check className="h-4 w-4" aria-hidden="true" />
              Mark all present
            </Button>
          </div>

          <div className="space-y-2">
            {expected.map((row) => {
              const advisorId = row.profile.id;
              const current = existingByAdvisor.get(advisorId);
              const selected = draft[advisorId];
              const isChanged = Boolean(current && selected && current.status !== selected);

              return (
                <Card key={advisorId}>
                  <CardBody className="space-y-3 py-3">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div className="min-w-0">
                        <p className="truncate font-medium">{row.profile.full_name}</p>
                        {row.enrolment && (
                          <p className="text-xs text-muted-foreground">
                            Day {row.enrolment.current_day}
                          </p>
                        )}
                      </div>

                      <div
                        role="radiogroup"
                        aria-label={`Attendance for ${row.profile.full_name}`}
                        className="flex gap-1"
                      >
                        {(['present', 'late', 'absent'] as const).map((status) => (
                          <button
                            key={status}
                            type="button"
                            role="radio"
                            aria-checked={selected === status}
                            onClick={() => setDraft((prev) => ({ ...prev, [advisorId]: status }))}
                            className={cn(
                              'min-h-[44px] rounded-md border px-3 text-sm font-medium capitalize transition-colors',
                              selected === status
                                ? status === 'present'
                                  ? 'border-success bg-success/10 text-success'
                                  : status === 'late'
                                    ? 'border-warning bg-warning/10 text-warning'
                                    : 'border-danger bg-danger/10 text-danger'
                                : 'border-border bg-surface text-muted-foreground hover:bg-muted',
                            )}
                          >
                            {status}
                          </button>
                        ))}
                      </div>
                    </div>

                    <input
                      type="text"
                      value={remarks[advisorId] ?? ''}
                      onChange={(event) =>
                        setRemarks((prev) => ({ ...prev, [advisorId]: event.target.value }))
                      }
                      placeholder="Remarks (optional)"
                      aria-label={`Remarks for ${row.profile.full_name}`}
                      className="w-full rounded-md border border-input bg-surface px-3 py-2 text-sm"
                    />

                    {/*
                      Changing something already saved is the one slow path, on
                      purpose. The reason is written to the audit trail.
                    */}
                    {isChanged && (
                      <div className="space-y-1.5 rounded-md border border-warning/30 bg-warning/5 p-3">
                        <label
                          htmlFor={`reason-${advisorId}`}
                          className="block text-sm font-medium text-warning"
                        >
                          Reason for changing {current!.status} to {selected}
                        </label>
                        <input
                          id={`reason-${advisorId}`}
                          type="text"
                          value={reasons[advisorId] ?? ''}
                          onChange={(event) =>
                            setReasons((prev) => ({ ...prev, [advisorId]: event.target.value }))
                          }
                          placeholder="Required — recorded against your name"
                          className="w-full rounded-md border border-input bg-surface px-3 py-2 text-sm"
                        />
                      </div>
                    )}
                  </CardBody>
                </Card>
              );
            })}
          </div>

          {saveError && (
            <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
              {saveError}
            </p>
          )}

          {missingReasons.length > 0 && (
            <p className="text-sm text-warning">
              A reason is required for {missingReasons.length}{' '}
              {missingReasons.length === 1 ? 'change' : 'changes'} before you can save.
            </p>
          )}

          <Button
            variant="accent"
            size="lg"
            onClick={() => void handleSave()}
            isLoading={save.isPending}
            disabled={markedCount === 0 || missingReasons.length > 0}
          >
            Save attendance
          </Button>
        </>
      )}
    </div>
  );
}
