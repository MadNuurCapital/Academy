import { describe, expect, it } from 'vitest';
import {
  addDays,
  addWorkingDays,
  buildRoadmap,
  calculateProgress,
  calculateTargetEndDate,
  countPausedWorkingDays,
  countWorkingDays,
  createCalendar,
  daysBetween,
  fromIsoDate,
  isoWeekday,
  isPausedOn,
  isWorkingDay,
  nextWorkingDayOnOrAfter,
  programmeDayToDate,
  toIsoDate,
} from './workingDays';

/**
 * Fixture holidays. These are test fixtures chosen to exercise the awkward
 * cases (a holiday on a Monday, two in the same week, one adjacent to a
 * weekend) — they are not a claim about any particular year's gazetted
 * Singapore holidays. Real dates are maintained by an administrator in the
 * public_holidays table.
 */
const HOLIDAYS = [
  '2026-08-10', // Monday
  '2026-08-11', // Tuesday, back-to-back with the above
  '2026-08-21', // Friday, running into a weekend
  '2026-12-25', // Christmas, crosses a year boundary in one test
  '2027-01-01',
];

const calendar = createCalendar(HOLIDAYS);
const noHolidays = createCalendar([]);

describe('date primitives', () => {
  it('round-trips ISO dates through Date without timezone drift', () => {
    expect(toIsoDate(fromIsoDate('2026-08-03'))).toBe('2026-08-03');
    expect(toIsoDate(fromIsoDate('2026-01-01'))).toBe('2026-01-01');
    expect(toIsoDate(fromIsoDate('2026-12-31'))).toBe('2026-12-31');
  });

  it('rejects malformed and impossible dates rather than guessing', () => {
    expect(() => fromIsoDate('03-08-2026')).toThrow(/YYYY-MM-DD/);
    expect(() => fromIsoDate('2026-8-3')).toThrow(/YYYY-MM-DD/);
    expect(() => fromIsoDate('2026-02-30')).toThrow(/not a real calendar date/);
    expect(() => fromIsoDate('2026-13-01')).toThrow(/not a real calendar date/);
  });

  it('maps weekdays to ISO numbers', () => {
    expect(isoWeekday('2026-08-03')).toBe(1); // Monday
    expect(isoWeekday('2026-08-07')).toBe(5); // Friday
    expect(isoWeekday('2026-08-08')).toBe(6); // Saturday
    expect(isoWeekday('2026-08-09')).toBe(7); // Sunday
  });

  it('adds days across month and year boundaries', () => {
    expect(addDays('2026-08-31', 1)).toBe('2026-09-01');
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
  });

  it('handles a leap year', () => {
    expect(addDays('2028-02-28', 1)).toBe('2028-02-29');
    expect(addDays('2028-02-29', 1)).toBe('2028-03-01');
    expect(daysBetween('2028-02-01', '2028-03-01')).toBe(29);
  });
});

describe('isWorkingDay', () => {
  it('counts Monday to Friday', () => {
    expect(isWorkingDay('2026-08-03', noHolidays)).toBe(true); // Mon
    expect(isWorkingDay('2026-08-07', noHolidays)).toBe(true); // Fri
  });

  it('excludes weekends', () => {
    expect(isWorkingDay('2026-08-08', noHolidays)).toBe(false); // Sat
    expect(isWorkingDay('2026-08-09', noHolidays)).toBe(false); // Sun
  });

  it('excludes public holidays', () => {
    expect(isWorkingDay('2026-08-10', calendar)).toBe(false);
    expect(isWorkingDay('2026-08-10', noHolidays)).toBe(true);
  });

  it('honours a Monday-to-Saturday configuration', () => {
    const sixDayWeek = createCalendar([], [1, 2, 3, 4, 5, 6]);
    expect(isWorkingDay('2026-08-08', sixDayWeek)).toBe(true); // Sat
    expect(isWorkingDay('2026-08-09', sixDayWeek)).toBe(false); // Sun
  });

  it('refuses a calendar with no working weekdays', () => {
    expect(() => createCalendar([], [])).toThrow(/at least one working weekday/);
  });
});

describe('nextWorkingDayOnOrAfter', () => {
  it('returns the same date when it is already a working day', () => {
    expect(nextWorkingDayOnOrAfter('2026-08-03', calendar)).toBe('2026-08-03');
  });

  it('rolls a Saturday start forward to Monday', () => {
    expect(nextWorkingDayOnOrAfter('2026-08-08', calendar)).toBe('2026-08-12');
  });

  it('skips a weekend followed by two consecutive holidays', () => {
    // Sat 8th → Sun 9th → Mon 10th (holiday) → Tue 11th (holiday) → Wed 12th.
    expect(nextWorkingDayOnOrAfter('2026-08-08', calendar)).toBe('2026-08-12');
  });

  it('skips a Friday holiday into the following Monday', () => {
    expect(nextWorkingDayOnOrAfter('2026-08-21', calendar)).toBe('2026-08-24');
  });
});

describe('addWorkingDays', () => {
  it('treats offset zero as the first working day', () => {
    expect(addWorkingDays('2026-08-03', 0, noHolidays)).toBe('2026-08-03');
    expect(addWorkingDays('2026-08-08', 0, noHolidays)).toBe('2026-08-10');
  });

  it('steps over weekends', () => {
    // Mon 3rd + 4 working days = Fri 7th; + 5 = Mon 10th.
    expect(addWorkingDays('2026-08-03', 4, noHolidays)).toBe('2026-08-07');
    expect(addWorkingDays('2026-08-03', 5, noHolidays)).toBe('2026-08-10');
  });

  it('steps over holidays as well as weekends', () => {
    // Mon 3rd + 5 working days would be Mon 10th, but that and the 11th are
    // holidays, so it lands on Wed 12th.
    expect(addWorkingDays('2026-08-03', 5, calendar)).toBe('2026-08-12');
  });

  it('rejects negative offsets', () => {
    expect(() => addWorkingDays('2026-08-03', -1, calendar)).toThrow(/negative/);
  });
});

describe('countWorkingDays', () => {
  it('counts an inclusive range', () => {
    expect(countWorkingDays('2026-08-03', '2026-08-07', noHolidays)).toBe(5);
  });

  it('excludes weekends from the range', () => {
    expect(countWorkingDays('2026-08-03', '2026-08-09', noHolidays)).toBe(5);
  });

  it('excludes holidays from the range', () => {
    // 10th-14th is Mon-Fri, but the 10th and 11th are holidays.
    expect(countWorkingDays('2026-08-10', '2026-08-14', calendar)).toBe(3);
  });

  it('returns zero when the range is inverted', () => {
    expect(countWorkingDays('2026-08-07', '2026-08-03', noHolidays)).toBe(0);
  });

  it('counts a single working day as one', () => {
    expect(countWorkingDays('2026-08-03', '2026-08-03', noHolidays)).toBe(1);
  });
});

describe('calculateTargetEndDate', () => {
  it('places day 30 six calendar weeks out on a clean calendar', () => {
    // Mon 2026-08-03 + 29 further working days = Fri 2026-09-11.
    expect(calculateTargetEndDate('2026-08-03', 30, noHolidays)).toBe('2026-09-11');
  });

  it('pushes the target out by each holiday inside the window', () => {
    // Three of the fixture holidays fall inside the 30-day window, so the
    // target moves three working days later than the clean calendar.
    expect(calculateTargetEndDate('2026-08-03', 30, calendar)).toBe('2026-09-16');
  });

  it('starts from the next working day when enrolled on a weekend', () => {
    const fromSaturday = calculateTargetEndDate('2026-08-08', 30, noHolidays);
    const fromMonday = calculateTargetEndDate('2026-08-10', 30, noHolidays);
    expect(fromSaturday).toBe(fromMonday);
  });

  it('crosses a year boundary correctly', () => {
    // Starting Mon 14 Dec, Christmas and New Year's Day each remove a working
    // day, so the thirtieth lands on Tue 26 Jan rather than Fri 22 Jan.
    const target = calculateTargetEndDate('2026-12-14', 30, calendar);
    expect(target).toBe('2027-01-26');
    expect(isoWeekday(target)).toBe(2);
  });

  it('rejects a non-positive programme length', () => {
    expect(() => calculateTargetEndDate('2026-08-03', 0, calendar)).toThrow(/positive integer/);
  });
});

describe('programmeDayToDate', () => {
  it('maps day 1 to the start date', () => {
    expect(programmeDayToDate('2026-08-03', 1, noHolidays)).toBe('2026-08-03');
  });

  it('maps day 30 to the target end date', () => {
    expect(programmeDayToDate('2026-08-03', 30, calendar)).toBe(
      calculateTargetEndDate('2026-08-03', 30, calendar),
    );
  });

  it('rejects day zero and fractional days', () => {
    expect(() => programmeDayToDate('2026-08-03', 0, calendar)).toThrow(/positive integer/);
    expect(() => programmeDayToDate('2026-08-03', 1.5, calendar)).toThrow(/positive integer/);
  });
});

describe('pauses', () => {
  const pauses = [{ pausedFrom: '2026-08-05', resumedOn: '2026-08-07' }];

  it('recognises dates inside a closed pause, inclusive of both ends', () => {
    expect(isPausedOn('2026-08-04', pauses)).toBe(false);
    expect(isPausedOn('2026-08-05', pauses)).toBe(true);
    expect(isPausedOn('2026-08-06', pauses)).toBe(true);
    expect(isPausedOn('2026-08-07', pauses)).toBe(true);
    expect(isPausedOn('2026-08-08', pauses)).toBe(false);
  });

  it('treats an open pause as ongoing', () => {
    const open = [{ pausedFrom: '2026-08-05', resumedOn: null }];
    expect(isPausedOn('2027-01-01', open)).toBe(true);
  });

  it('counts only working days lost to a pause', () => {
    // 5th-7th Aug is Wed-Fri: three working days.
    expect(countPausedWorkingDays('2026-08-03', '2026-08-14', pauses, noHolidays)).toBe(3);
  });

  it('does not double-count a pause spanning a weekend', () => {
    // Fri 7th to Mon 10th covers four calendar days but two working days.
    const overWeekend = [{ pausedFrom: '2026-08-07', resumedOn: '2026-08-10' }];
    expect(countPausedWorkingDays('2026-08-03', '2026-08-14', overWeekend, noHolidays)).toBe(2);
  });

  it('does not count a holiday that falls inside a pause', () => {
    // The 10th and 11th are holidays, so a pause covering them loses only the
    // 12th and 13th.
    const overHoliday = [{ pausedFrom: '2026-08-10', resumedOn: '2026-08-13' }];
    expect(countPausedWorkingDays('2026-08-03', '2026-08-20', overHoliday, calendar)).toBe(2);
  });
});

describe('calculateProgress', () => {
  const base = {
    startDate: '2026-08-03',
    programmeLengthDays: 30,
    calendar: noHolidays,
  };

  it('reports on track when the advisor is keeping pace', () => {
    // Fri 7th is the 5th working day, and they are on day 5.
    const result = calculateProgress({ ...base, asOf: '2026-08-07', currentDay: 5 });
    expect(result.expectedDay).toBe(5);
    expect(result.driftDays).toBe(0);
    expect(result.status).toBe('on_track');
    expect(result.isAhead).toBe(false);
  });

  it('tolerates two days of drift as on track', () => {
    const result = calculateProgress({ ...base, asOf: '2026-08-07', currentDay: 3 });
    expect(result.driftDays).toBe(2);
    expect(result.status).toBe('on_track');
  });

  it('flags attention needed between three and five days of drift', () => {
    const result = calculateProgress({ ...base, asOf: '2026-08-14', currentDay: 6 });
    expect(result.expectedDay).toBe(10);
    expect(result.driftDays).toBe(4);
    expect(result.status).toBe('attention_needed');
  });

  it('flags behind schedule beyond five days of drift', () => {
    const result = calculateProgress({ ...base, asOf: '2026-08-21', currentDay: 7 });
    expect(result.expectedDay).toBe(15);
    expect(result.driftDays).toBe(8);
    expect(result.status).toBe('behind_schedule');
  });

  it('treats working ahead as zero drift, not negative', () => {
    const result = calculateProgress({ ...base, asOf: '2026-08-07', currentDay: 12 });
    expect(result.driftDays).toBe(0);
    expect(result.isAhead).toBe(true);
    expect(result.status).toBe('on_track');
  });

  it('does not accrue drift while the advisor is paused', () => {
    // A week off from Mon 10th to Fri 14th. By Fri 21st, fifteen working days
    // have elapsed but five were paused, so day 10 is on pace.
    const result = calculateProgress({
      ...base,
      asOf: '2026-08-21',
      currentDay: 10,
      pauses: [{ pausedFrom: '2026-08-10', resumedOn: '2026-08-14' }],
    });
    expect(result.pausedDays).toBe(5);
    expect(result.expectedDay).toBe(10);
    expect(result.driftDays).toBe(0);
    expect(result.status).toBe('on_track');
  });

  it('keeps the target end date fixed while pushing the projection out', () => {
    const result = calculateProgress({ ...base, asOf: '2026-08-21', currentDay: 7 });
    expect(result.targetEndDate).toBe('2026-09-11');
    expect(result.projectedEndDate).toBe('2026-09-23'); // eight working days later
  });

  it('leaves the projection on target when there is no drift', () => {
    const result = calculateProgress({ ...base, asOf: '2026-08-07', currentDay: 5 });
    expect(result.projectedEndDate).toBe(result.targetEndDate);
  });

  it('reports nothing before the programme has opened', () => {
    const result = calculateProgress({ ...base, asOf: '2026-07-30', currentDay: 1 });
    expect(result.expectedDay).toBe(1);
    expect(result.driftDays).toBe(0);
    expect(result.status).toBe('on_track');
    expect(result.percentComplete).toBe(0);
  });

  it('caps the expected day at the programme length', () => {
    // Long after the programme should have finished.
    const result = calculateProgress({ ...base, asOf: '2026-12-31', currentDay: 30 });
    expect(result.expectedDay).toBe(30);
  });

  it('reports completion percentage against days finished, not days unlocked', () => {
    // On day 1 nothing is complete; on day 30 twenty-nine days are behind them.
    expect(calculateProgress({ ...base, asOf: '2026-08-03', currentDay: 1 }).percentComplete).toBe(0);
    expect(calculateProgress({ ...base, asOf: '2026-09-11', currentDay: 16 }).percentComplete).toBe(50);
    expect(calculateProgress({ ...base, asOf: '2026-09-11', currentDay: 30 }).percentComplete).toBe(97);
  });

  it('respects custom drift thresholds', () => {
    const strict = calculateProgress({
      ...base,
      asOf: '2026-08-07',
      currentDay: 4,
      thresholds: { onTrackDays: 0, attentionDays: 1 },
    });
    expect(strict.driftDays).toBe(1);
    expect(strict.status).toBe('attention_needed');
  });

  it('excludes holidays from the expected day so nobody drifts for a day off', () => {
    // By Fri 14th on the holiday calendar only eight working days have passed,
    // because the 10th and 11th were public holidays.
    const result = calculateProgress({
      startDate: '2026-08-03',
      programmeLengthDays: 30,
      calendar,
      asOf: '2026-08-14',
      currentDay: 8,
    });
    expect(result.expectedDay).toBe(8);
    expect(result.driftDays).toBe(0);
  });
});

describe('buildRoadmap', () => {
  it('produces one entry per programme day', () => {
    const roadmap = buildRoadmap('2026-08-03', 30, calendar);
    expect(roadmap).toHaveLength(30);
    expect(roadmap[0]).toEqual({ dayNumber: 1, expectedDate: '2026-08-03' });
  });

  it('lands its final day on the target end date', () => {
    const roadmap = buildRoadmap('2026-08-03', 30, calendar);
    expect(roadmap.at(-1)?.expectedDate).toBe(calculateTargetEndDate('2026-08-03', 30, calendar));
  });

  it('contains no weekends or holidays', () => {
    const roadmap = buildRoadmap('2026-08-03', 30, calendar);
    for (const { expectedDate } of roadmap) {
      expect(isWorkingDay(expectedDate, calendar)).toBe(true);
    }
  });

  it('increases strictly in date order', () => {
    const roadmap = buildRoadmap('2026-08-03', 30, calendar);
    for (let i = 1; i < roadmap.length; i += 1) {
      expect(daysBetween(roadmap[i - 1]!.expectedDate, roadmap[i]!.expectedDate)).toBeGreaterThan(0);
    }
  });
});
