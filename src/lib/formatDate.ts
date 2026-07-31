import { fromIsoDate, type IsoDate } from './workingDays';

/**
 * Date formatting for display.
 *
 * Everything is formatted from the UTC fields of a date pinned to UTC midnight,
 * so a `YYYY-MM-DD` never renders as the previous day for a user east of
 * Greenwich — which, in Singapore, would otherwise be every user.
 */

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const WEEKDAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

/** "3 August 2026" */
export function formatLongDate(value: IsoDate): string {
  const date = fromIsoDate(value);
  return `${date.getUTCDate()} ${MONTHS[date.getUTCMonth()]} ${date.getUTCFullYear()}`;
}

/** "3 Aug" */
export function formatShortDate(value: IsoDate): string {
  const date = fromIsoDate(value);
  return `${date.getUTCDate()} ${MONTHS[date.getUTCMonth()]!.slice(0, 3)}`;
}

/** "Monday 3 August" */
export function formatWeekdayDate(value: IsoDate): string {
  const date = fromIsoDate(value);
  return `${WEEKDAYS[date.getUTCDay()]} ${date.getUTCDate()} ${MONTHS[date.getUTCMonth()]}`;
}

/** "45 minutes" or "1 hour 15 minutes" */
export function formatMinutes(minutes: number): string {
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const remainder = minutes % 60;
  const hourLabel = `${hours} hour${hours === 1 ? '' : 's'}`;
  return remainder === 0 ? hourLabel : `${hourLabel} ${remainder} min`;
}
