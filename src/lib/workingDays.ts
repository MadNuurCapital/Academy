/**
 * ATLAS Academy — working-day engine
 *
 * The single place in the codebase that converts between programme day numbers
 * and calendar dates. Roadmap generation, target end dates, drift, projected
 * finish and every report call into this module. Nothing else should reimplement
 * date arithmetic.
 *
 * Two rules govern everything here:
 *
 *   1. A programme day is a *working* day — Monday to Friday by default, minus
 *      Singapore public holidays. Which weekdays count is configurable, because
 *      the business has not ruled out Saturdays forever.
 *
 *   2. Day unlocking shifts when an advisor is absent or paused, but the target
 *      end date fixed at enrolment does not. The gap between them is drift, and
 *      drift is what the manager dashboard means by "behind schedule".
 *
 * Dates are handled as plain `YYYY-MM-DD` strings throughout, never as Date
 * objects carrying a time component. Attendance on the 3rd of August is the 3rd
 * of August in Singapore regardless of where the server is; introducing a
 * timestamp would let UTC conversion silently move it to the 2nd.
 */

/** A calendar date in `YYYY-MM-DD` form. */
export type IsoDate = string;

/** ISO weekday numbers: 1 = Monday … 7 = Sunday. */
export type IsoWeekday = 1 | 2 | 3 | 4 | 5 | 6 | 7;

export const DEFAULT_WORKING_WEEKDAYS: readonly IsoWeekday[] = [1, 2, 3, 4, 5];

export interface PausePeriod {
  /** First date of the pause, inclusive. */
  pausedFrom: IsoDate;
  /** Date the advisor resumed, inclusive. `null` means still paused. */
  resumedOn: IsoDate | null;
}

export interface WorkingDayCalendar {
  /** Dates excluded from the count — Singapore public holidays. */
  holidays: ReadonlySet<IsoDate>;
  /** Which ISO weekdays count as programme days. */
  workingWeekdays: readonly IsoWeekday[];
}

const ISO_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const MS_PER_DAY = 86_400_000;

/**
 * Guard against silent nonsense. A malformed date here would corrupt an
 * advisor's entire roadmap, so it fails loudly instead.
 */
function assertIsoDate(value: string, label: string): void {
  if (!ISO_DATE_PATTERN.test(value)) {
    throw new Error(`${label} must be a YYYY-MM-DD date, received "${value}"`);
  }
  const parsed = Date.parse(`${value}T00:00:00Z`);
  if (Number.isNaN(parsed)) {
    throw new Error(`${label} is not a real calendar date: "${value}"`);
  }
  // Date.parse accepts 2026-02-30 on some engines by rolling forward, so
  // round-trip the value to confirm it survived unchanged.
  if (toIsoDate(new Date(parsed)) !== value) {
    throw new Error(`${label} is not a real calendar date: "${value}"`);
  }
}

/** Formats a UTC Date as `YYYY-MM-DD`. */
export function toIsoDate(date: Date): IsoDate {
  const year = date.getUTCFullYear().toString().padStart(4, '0');
  const month = (date.getUTCMonth() + 1).toString().padStart(2, '0');
  const day = date.getUTCDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/** Parses `YYYY-MM-DD` into a Date pinned to UTC midnight. */
export function fromIsoDate(value: IsoDate): Date {
  assertIsoDate(value, 'Date');
  return new Date(`${value}T00:00:00Z`);
}

/** ISO weekday for a date: 1 = Monday … 7 = Sunday. */
export function isoWeekday(value: IsoDate): IsoWeekday {
  const jsDay = fromIsoDate(value).getUTCDay(); // 0 = Sunday
  return (jsDay === 0 ? 7 : jsDay) as IsoWeekday;
}

/** Adds (or subtracts) whole calendar days. */
export function addDays(value: IsoDate, days: number): IsoDate {
  const base = fromIsoDate(value).getTime();
  return toIsoDate(new Date(base + days * MS_PER_DAY));
}

/** Whole calendar days from `start` to `end`. Negative when `end` precedes `start`. */
export function daysBetween(start: IsoDate, end: IsoDate): number {
  return Math.round((fromIsoDate(end).getTime() - fromIsoDate(start).getTime()) / MS_PER_DAY);
}

export function createCalendar(
  holidays: Iterable<IsoDate> = [],
  workingWeekdays: readonly IsoWeekday[] = DEFAULT_WORKING_WEEKDAYS,
): WorkingDayCalendar {
  if (workingWeekdays.length === 0) {
    throw new Error('A calendar must have at least one working weekday');
  }
  const holidaySet = new Set<IsoDate>();
  for (const holiday of holidays) {
    assertIsoDate(holiday, 'Holiday date');
    holidaySet.add(holiday);
  }
  return { holidays: holidaySet, workingWeekdays: [...workingWeekdays] };
}

/** True when the date is a programme day: a working weekday that is not a holiday. */
export function isWorkingDay(value: IsoDate, calendar: WorkingDayCalendar): boolean {
  if (calendar.holidays.has(value)) return false;
  return calendar.workingWeekdays.includes(isoWeekday(value));
}

/**
 * The first working day on or after `value`.
 *
 * Used when an advisor is enrolled with a start date that lands on a weekend or
 * a public holiday — their Day 1 becomes the next day the office is open.
 */
export function nextWorkingDayOnOrAfter(value: IsoDate, calendar: WorkingDayCalendar): IsoDate {
  let cursor = value;
  // A full fortnight is far more than enough to clear any weekend plus holiday
  // run; the bound exists so a misconfigured calendar cannot hang the app.
  for (let guard = 0; guard < 400; guard += 1) {
    if (isWorkingDay(cursor, calendar)) return cursor;
    cursor = addDays(cursor, 1);
  }
  throw new Error('No working day found within 400 days — check the working weekday configuration');
}

/**
 * Adds a number of working days to a date.
 *
 * `addWorkingDays(start, 0)` returns the first working day on or after `start`,
 * which is Day 1 of the programme. `addWorkingDays(start, 29)` therefore returns
 * Day 30 — the thirtieth working day, not the thirtieth day after the start.
 */
export function addWorkingDays(
  start: IsoDate,
  workingDaysToAdd: number,
  calendar: WorkingDayCalendar,
): IsoDate {
  if (workingDaysToAdd < 0) {
    throw new Error('addWorkingDays does not support negative offsets');
  }
  let cursor = nextWorkingDayOnOrAfter(start, calendar);
  let remaining = workingDaysToAdd;
  while (remaining > 0) {
    cursor = nextWorkingDayOnOrAfter(addDays(cursor, 1), calendar);
    remaining -= 1;
  }
  return cursor;
}

/**
 * Counts working days in `[start, end]` inclusive.
 * Returns 0 when `end` falls before `start`.
 */
export function countWorkingDays(
  start: IsoDate,
  end: IsoDate,
  calendar: WorkingDayCalendar,
): number {
  if (daysBetween(start, end) < 0) return 0;
  let count = 0;
  let cursor = start;
  while (daysBetween(cursor, end) >= 0) {
    if (isWorkingDay(cursor, calendar)) count += 1;
    cursor = addDays(cursor, 1);
  }
  return count;
}

/** True when `value` falls inside any pause period, inclusive of both ends. */
export function isPausedOn(value: IsoDate, pauses: readonly PausePeriod[]): boolean {
  return pauses.some((pause) => {
    if (daysBetween(pause.pausedFrom, value) < 0) return false;
    if (pause.resumedOn === null) return true;
    return daysBetween(value, pause.resumedOn) >= 0;
  });
}

/** Working days inside `[start, end]` that were lost to a pause. */
export function countPausedWorkingDays(
  start: IsoDate,
  end: IsoDate,
  pauses: readonly PausePeriod[],
  calendar: WorkingDayCalendar,
): number {
  if (pauses.length === 0) return 0;
  if (daysBetween(start, end) < 0) return 0;

  let count = 0;
  let cursor = start;
  while (daysBetween(cursor, end) >= 0) {
    if (isWorkingDay(cursor, calendar) && isPausedOn(cursor, pauses)) count += 1;
    cursor = addDays(cursor, 1);
  }
  return count;
}

/**
 * The calendar date an advisor is expected to reach a given programme day.
 * Day 1 is their start date (or the next working day, if they were enrolled on
 * a weekend or holiday).
 */
export function programmeDayToDate(
  startDate: IsoDate,
  dayNumber: number,
  calendar: WorkingDayCalendar,
): IsoDate {
  if (!Number.isInteger(dayNumber) || dayNumber < 1) {
    throw new Error(`Programme day must be a positive integer, received ${dayNumber}`);
  }
  return addWorkingDays(startDate, dayNumber - 1, calendar);
}

/**
 * The target end date fixed at enrolment.
 *
 * Computed once and stored on the enrolment row. It is never recalculated when
 * an advisor falls behind — that is precisely what makes drift measurable.
 */
export function calculateTargetEndDate(
  startDate: IsoDate,
  programmeLengthDays: number,
  calendar: WorkingDayCalendar,
): IsoDate {
  if (!Number.isInteger(programmeLengthDays) || programmeLengthDays < 1) {
    throw new Error(`Programme length must be a positive integer, received ${programmeLengthDays}`);
  }
  return programmeDayToDate(startDate, programmeLengthDays, calendar);
}

export type ProgressStatus = 'on_track' | 'attention_needed' | 'behind_schedule';

export interface DriftThresholds {
  /** Drift at or below this many working days is On Track. */
  onTrackDays: number;
  /** Drift at or below this is Attention Needed; above it is Behind Schedule. */
  attentionDays: number;
}

export const DEFAULT_DRIFT_THRESHOLDS: DriftThresholds = {
  onTrackDays: 2,
  attentionDays: 5,
};

export interface ProgressInput {
  startDate: IsoDate;
  /** Today, or any date the report is being run for. */
  asOf: IsoDate;
  /** The advisor's furthest unlocked day. */
  currentDay: number;
  programmeLengthDays: number;
  pauses?: readonly PausePeriod[];
  calendar: WorkingDayCalendar;
  thresholds?: DriftThresholds;
}

export interface ProgressResult {
  /** The day the advisor is on. */
  currentDay: number;
  /** The day they would be on had they worked every available day. */
  expectedDay: number;
  /** Working days behind the expected day. Never negative — working ahead is not drift. */
  driftDays: number;
  /** True when the advisor is ahead of the expected day. */
  isAhead: boolean;
  status: ProgressStatus;
  /** Fixed at enrolment; does not move. */
  targetEndDate: IsoDate;
  /** Where they will finish at the current rate, accounting for drift. */
  projectedEndDate: IsoDate;
  /** Whole percent of the programme unlocked. */
  percentComplete: number;
  /** Working days lost to pauses so far. */
  pausedDays: number;
}

/**
 * Everything the dashboards need to answer "am I on track?" and "who is behind?".
 *
 * Expected day is derived from working days elapsed *minus* days lost to a
 * pause, so a paused advisor does not accumulate drift while their clock is
 * stopped.
 */
export function calculateProgress(input: ProgressInput): ProgressResult {
  const {
    startDate,
    asOf,
    currentDay,
    programmeLengthDays,
    pauses = [],
    calendar,
    thresholds = DEFAULT_DRIFT_THRESHOLDS,
  } = input;

  const firstDay = nextWorkingDayOnOrAfter(startDate, calendar);
  const targetEndDate = calculateTargetEndDate(startDate, programmeLengthDays, calendar);

  // Before the programme opens there is no drift to report.
  if (daysBetween(firstDay, asOf) < 0) {
    return {
      currentDay,
      expectedDay: 1,
      driftDays: 0,
      isAhead: false,
      status: 'on_track',
      targetEndDate,
      projectedEndDate: targetEndDate,
      percentComplete: 0,
      pausedDays: 0,
    };
  }

  const elapsedWorkingDays = countWorkingDays(firstDay, asOf, calendar);
  const pausedDays = countPausedWorkingDays(firstDay, asOf, pauses, calendar);

  const expectedDay = Math.min(
    Math.max(elapsedWorkingDays - pausedDays, 1),
    programmeLengthDays,
  );

  const rawDrift = expectedDay - currentDay;
  const driftDays = Math.max(rawDrift, 0);
  const isAhead = rawDrift < 0;

  let status: ProgressStatus;
  if (driftDays <= thresholds.onTrackDays) {
    status = 'on_track';
  } else if (driftDays <= thresholds.attentionDays) {
    status = 'attention_needed';
  } else {
    status = 'behind_schedule';
  }

  // Drift pushes the finish out by the same number of working days. An advisor
  // who is ahead is not projected to finish before the target, because days
  // unlock sequentially but the remaining work still has to be done.
  const projectedEndDate =
    driftDays > 0 ? addWorkingDays(targetEndDate, driftDays, calendar) : targetEndDate;

  const percentComplete = Math.min(
    100,
    Math.round(((currentDay - 1) / programmeLengthDays) * 100),
  );

  return {
    currentDay,
    expectedDay,
    driftDays,
    isAhead,
    status,
    targetEndDate,
    projectedEndDate,
    percentComplete,
    pausedDays,
  };
}

/**
 * The full roadmap: every programme day mapped to the date it is expected on.
 * Used to render the advisor's 30-day view and to seed reporting.
 */
export function buildRoadmap(
  startDate: IsoDate,
  programmeLengthDays: number,
  calendar: WorkingDayCalendar,
): { dayNumber: number; expectedDate: IsoDate }[] {
  const roadmap: { dayNumber: number; expectedDate: IsoDate }[] = [];
  let cursor = nextWorkingDayOnOrAfter(startDate, calendar);

  for (let dayNumber = 1; dayNumber <= programmeLengthDays; dayNumber += 1) {
    roadmap.push({ dayNumber, expectedDate: cursor });
    if (dayNumber < programmeLengthDays) {
      cursor = nextWorkingDayOnOrAfter(addDays(cursor, 1), calendar);
    }
  }

  return roadmap;
}
