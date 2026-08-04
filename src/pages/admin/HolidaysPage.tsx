import { useState } from 'react';
import { CalendarPlus, Trash2 } from 'lucide-react';
import { useAddHoliday, useDeleteHoliday, useHolidays } from '@/api/holidays';
import { Panel, Well } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import { ErrorState, LoadingState } from '@/components/ui/States';
import { inputClass } from '@/components/admin/editorState';
import { formatWeekdayDate } from '@/lib/formatDate';
import { addDays, isoWeekday, type IsoDate } from '@/lib/workingDays';
import { cn } from '@/lib/cn';

/**
 * Public holidays.
 *
 * Small screen, disproportionate consequences. Every date the programme
 * calculates — the target end date, whether an advisor is behind, which day
 * unlocks tomorrow — is counted in working days, and this table is the only
 * thing that excludes a holiday from that count. An empty year means the
 * programme quietly tells someone they are behind for not attending on Hari
 * Raya.
 */
export function HolidaysPage() {
  const { data: holidays, isLoading, error, refetch } = useHolidays();
  const currentYear = new Date().getFullYear();
  const [year, setYear] = useState(currentYear);

  if (isLoading) return <LoadingState label="Loading the holidays…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load the holidays"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  const all = holidays ?? [];
  const years = [currentYear - 1, currentYear, currentYear + 1];
  const shown = all.filter((holiday) => holiday.holiday_date.startsWith(String(year)));

  const nextYear = currentYear + 1;
  const nextYearIsEmpty = !all.some((holiday) =>
    holiday.holiday_date.startsWith(String(nextYear)),
  );

  return (
    <div className="space-y-5">
      <div>
        <h1>Public holidays</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Dates excluded from the working-day count.
        </p>
      </div>

      <Panel className="p-4">
        <p className="text-sm text-muted-foreground">
          Enter the <strong className="font-medium text-foreground">observed</strong> date —
          the day nobody is in the office. Where a holiday falls on a Sunday, Singapore takes
          the Monday in lieu, and it is that Monday that belongs here. A holiday on a Saturday
          needs no entry at all: the working week is Monday to Friday, so Saturday is already
          excluded.
        </p>
        <p className="mt-2 text-sm text-muted-foreground">
          Check the dates against{' '}
          <a
            href="https://www.mom.gov.sg/employment-practices/public-holidays"
            target="_blank"
            rel="noreferrer"
            className="font-medium text-accent hover:underline"
          >
            MOM's published list
          </a>
          . Hari Raya Puasa and Hari Raya Haji follow moon sighting and can shift.
        </p>
      </Panel>

      {nextYearIsEmpty && (
        <Panel tone="warning" className="p-4">
          <p className="text-sm">
            <span className="font-medium">Nothing is loaded for {nextYear}.</span> Any advisor
            whose programme runs into January will be counted as behind over the New Year.
            Add next year's dates before the first intake that reaches them.
          </p>
        </Panel>
      )}

      <div className="flex flex-wrap gap-2" role="group" aria-label="Choose a year">
        {years.map((option) => (
          <button
            key={option}
            type="button"
            onClick={() => setYear(option)}
            aria-pressed={year === option}
            className={cn(
              'tabular min-h-[40px] rounded-md border px-4 text-sm font-medium transition-colors',
              year === option
                ? 'border-highlight/40 bg-white/[0.09] text-foreground'
                : 'border-white/10 text-muted-foreground hover:bg-white/[0.05]',
            )}
          >
            {option}
          </button>
        ))}
      </div>

      <AddHoliday year={year} />

      <Panel className="p-4">
        <p className="console-label">
          {year} · {shown.length} {shown.length === 1 ? 'holiday' : 'holidays'}
        </p>

        {shown.length === 0 ? (
          <p className="mt-3 text-sm text-muted-foreground">
            Nothing entered for {year} yet.
          </p>
        ) : (
          <ul className="mt-3 space-y-2">
            {shown.map((holiday) => (
              <HolidayRow key={holiday.id} id={holiday.id} date={holiday.holiday_date} name={holiday.name} />
            ))}
          </ul>
        )}
      </Panel>
    </div>
  );
}

function HolidayRow({ id, date, name }: { id: string; date: IsoDate; name: string }) {
  const remove = useDeleteHoliday();
  const [confirming, setConfirming] = useState(false);
  const weekday = isoWeekday(date);
  const isWeekend = weekday === 6 || weekday === 7;

  return (
    <li className="flex flex-wrap items-center gap-2 rounded-md border border-white/[0.06] bg-panel/60 p-3">
      <div className="min-w-0 flex-1">
        <p className="text-sm font-medium">{name}</p>
        <p className="tabular mt-0.5 text-xs text-muted-foreground">
          {formatWeekdayDate(date)}
          {isWeekend && (
            <span className="ml-2 text-warning">
              — a weekend, so this changes nothing
            </span>
          )}
        </p>
      </div>

      {confirming ? (
        <>
          <span className="text-sm text-warning">Remove it?</span>
          <Button
            size="sm"
            variant="danger"
            isLoading={remove.isPending}
            onClick={() => void remove.mutateAsync({ id })}
          >
            Remove
          </Button>
          <Button size="sm" variant="ghost" onClick={() => setConfirming(false)}>
            Keep
          </Button>
        </>
      ) : (
        <Button size="sm" variant="ghost" onClick={() => setConfirming(true)}>
          <Trash2 className="h-4 w-4" aria-hidden="true" />
          Remove
        </Button>
      )}

      {remove.isError && (
        <p role="alert" className="w-full text-sm font-medium text-danger">
          {remove.error instanceof Error ? remove.error.message : 'We could not remove that.'}
        </p>
      )}
    </li>
  );
}

function AddHoliday({ year }: { year: number }) {
  const add = useAddHoliday();
  const [date, setDate] = useState('');
  const [name, setName] = useState('');

  const weekday = date ? isoWeekday(date as IsoDate) : null;
  const isSaturday = weekday === 6;
  const isSunday = weekday === 7;
  const mondayInLieu = isSunday ? addDays(date as IsoDate, 1) : null;

  const canSubmit = Boolean(date) && name.trim().length > 0;

  async function submit(dateToUse: string) {
    await add.mutateAsync({ date: dateToUse as IsoDate, name });
    setDate('');
    setName('');
  }

  return (
    <Panel className="space-y-3 p-4">
      <p className="console-label">Add a holiday to {year}</p>

      <div className="grid gap-3 sm:grid-cols-[minmax(0,12rem)_1fr]">
        <div className="space-y-1.5">
          <label htmlFor="holiday-date" className="block text-sm font-medium">
            Observed date
          </label>
          <input
            id="holiday-date"
            type="date"
            value={date}
            min={`${year}-01-01`}
            max={`${year}-12-31`}
            onChange={(event) => setDate(event.target.value)}
            className={cn(inputClass, 'tabular')}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="holiday-name" className="block text-sm font-medium">
            Name
          </label>
          <input
            id="holiday-name"
            value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder="Chinese New Year"
            className={inputClass}
          />
        </div>
      </div>

      {/*
        A weekend date is not an error — it is simply a date that will do
        nothing, and finding that out three months later, when an advisor's
        schedule is already wrong, is the outcome worth preventing. Say so
        before it is saved, and offer the date that would have been meant.
      */}
      {isSunday && (
        <Well>
          <p className="text-sm">
            <span className="font-medium text-warning">That is a Sunday.</span> Singapore
            observes the Monday in lieu, and it is the Monday that costs a working day. Saving
            the Sunday changes nobody's schedule.
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            <Button
              size="sm"
              disabled={!canSubmit}
              isLoading={add.isPending}
              onClick={() => void submit(mondayInLieu!)}
            >
              Use {formatWeekdayDate(mondayInLieu!)} instead
            </Button>
            <Button
              size="sm"
              variant="ghost"
              disabled={!canSubmit}
              isLoading={add.isPending}
              onClick={() => void submit(date)}
            >
              Save the Sunday anyway
            </Button>
          </div>
        </Well>
      )}

      {isSaturday && (
        <Well>
          <p className="text-sm">
            <span className="font-medium text-warning">That is a Saturday.</span> The working
            week is Monday to Friday, so Saturday is already excluded and this entry would
            change nothing. If your office grants a day off in lieu, enter that day instead.
          </p>
          <Button
            size="sm"
            variant="ghost"
            className="mt-3"
            disabled={!canSubmit}
            isLoading={add.isPending}
            onClick={() => void submit(date)}
          >
            Save it anyway
          </Button>
        </Well>
      )}

      {!isSaturday && !isSunday && (
        <div className="flex flex-wrap items-center gap-3">
          <Button disabled={!canSubmit} isLoading={add.isPending} onClick={() => void submit(date)}>
            <CalendarPlus className="h-4 w-4" aria-hidden="true" />
            Add holiday
          </Button>
          {date && (
            <span className="text-sm text-muted-foreground">{formatWeekdayDate(date as IsoDate)}</span>
          )}
        </div>
      )}

      {add.isError && (
        <p role="alert" className="text-sm font-medium text-danger">
          {add.error instanceof Error ? add.error.message : 'We could not add that.'}
        </p>
      )}
    </Panel>
  );
}
