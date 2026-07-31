import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { CalendarDays } from 'lucide-react';
import {
  useEnrolAdvisor,
  usePublishedTemplate,
  useUnenrolledAdvisors,
  today,
} from '@/api/enrolments';
import { usePublicHolidays, useSettings } from '@/api/settings';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { calculateTargetEndDate, createCalendar, nextWorkingDayOnOrAfter } from '@/lib/workingDays';
import { formatLongDate, formatWeekdayDate } from '@/lib/formatDate';

/**
 * Enrol an advisor.
 *
 * The preview below is computed client-side purely so the manager can see the
 * consequences before committing. The authoritative dates are computed again by
 * the enrol_advisor function on the server — a client cannot submit a
 * flattering target date, and the whole "behind schedule" signal depends on
 * that being true.
 */
export function EnrolPage() {
  const navigate = useNavigate();
  const { data: candidates, isLoading } = useUnenrolledAdvisors();
  const { data: template } = usePublishedTemplate();
  const { data: settings } = useSettings();
  const { data: holidays } = usePublicHolidays();
  const enrol = useEnrolAdvisor();

  const [advisorId, setAdvisorId] = useState('');
  const [startDate, setStartDate] = useState(today());
  const [intakeLabel, setIntakeLabel] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);

  if (isLoading) return <LoadingState label="Loading advisors…" />;

  const calendar = settings ? createCalendar(holidays ?? [], settings.workingWeekdays) : null;

  let firstDay: string | null = null;
  let targetEnd: string | null = null;
  if (calendar && settings && startDate) {
    try {
      firstDay = nextWorkingDayOnOrAfter(startDate, calendar);
      targetEnd = calculateTargetEndDate(startDate, settings.programmeLengthDays, calendar);
    } catch {
      // An unparseable date from the picker is not worth surfacing as an error;
      // the preview simply stays hidden until the field is valid.
      firstDay = null;
      targetEnd = null;
    }
  }

  const startsLater = firstDay !== null && firstDay !== startDate;

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    setSubmitError(null);
    if (!template) {
      setSubmitError('No published programme template is available. An administrator must publish one first.');
      return;
    }
    try {
      await enrol.mutateAsync({
        advisorId,
        templateId: (template as { id: string }).id,
        startDate,
        intakeLabel: intakeLabel.trim() || undefined,
      });
      navigate('/manage/advisors');
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'We could not enrol that advisor.');
    }
  }

  return (
    <div className="space-y-6">
      <h1>Enrol an advisor</h1>

      {!candidates || candidates.length === 0 ? (
        <EmptyState
          title="No advisors waiting to be enrolled"
          description="Everyone with the advisor role is already on a programme. An administrator can create new advisor accounts."
        />
      ) : (
        <Card>
          <CardHeader>
            <CardTitle>Programme details</CardTitle>
          </CardHeader>
          <CardBody>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label htmlFor="advisor" className="block text-sm font-medium">
                  Advisor
                </label>
                <select
                  id="advisor"
                  value={advisorId}
                  onChange={(event) => setAdvisorId(event.target.value)}
                  required
                  className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                >
                  <option value="">Select an advisor…</option>
                  {candidates.map(({ profile }) => (
                    <option key={profile.id} value={profile.id}>
                      {profile.full_name} · {profile.email}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-1.5">
                <label htmlFor="start-date" className="block text-sm font-medium">
                  Start date
                </label>
                <input
                  id="start-date"
                  type="date"
                  value={startDate}
                  onChange={(event) => setStartDate(event.target.value)}
                  required
                  className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                />
              </div>

              <div className="space-y-1.5">
                <label htmlFor="intake" className="block text-sm font-medium">
                  Intake label <span className="font-normal text-muted-foreground">(optional)</span>
                </label>
                <input
                  id="intake"
                  type="text"
                  value={intakeLabel}
                  onChange={(event) => setIntakeLabel(event.target.value)}
                  placeholder="For example: July 2026"
                  className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
                />
                <p className="text-sm text-muted-foreground">
                  Used for grouping reports only. Advisors start individually and follow their own
                  clock.
                </p>
              </div>

              {firstDay && targetEnd && settings && (
                <div className="rounded-md border border-border bg-muted/50 p-4">
                  <p className="flex items-center gap-2 text-sm font-medium">
                    <CalendarDays className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                    What this means
                  </p>
                  <dl className="mt-3 space-y-2 text-sm">
                    <div className="flex justify-between gap-4">
                      <dt className="text-muted-foreground">Day 1</dt>
                      <dd className="text-right font-medium">{formatWeekdayDate(firstDay)}</dd>
                    </div>
                    <div className="flex justify-between gap-4">
                      <dt className="text-muted-foreground">
                        Day {settings.programmeLengthDays} (target)
                      </dt>
                      <dd className="text-right font-medium">{formatLongDate(targetEnd)}</dd>
                    </div>
                  </dl>
                  {startsLater && (
                    <p className="mt-3 text-sm text-warning">
                      The date you chose is not a working day, so Day 1 moves to the next one.
                    </p>
                  )}
                </div>
              )}

              {submitError && (
                <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
                  {submitError}
                </p>
              )}

              <Button type="submit" variant="accent" size="lg" isLoading={enrol.isPending} disabled={!advisorId}>
                Enrol advisor
              </Button>
            </form>
          </CardBody>
        </Card>
      )}
    </div>
  );
}
