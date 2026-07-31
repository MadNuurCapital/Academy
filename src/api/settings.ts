import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import type { IsoWeekday } from '@/lib/workingDays';

/**
 * Runtime configuration.
 *
 * These values also exist server-side: the progression functions read
 * app_settings themselves rather than trusting anything the client sends. This
 * hook exists so the interface can *display* the right numbers ("you need 80%
 * to pass"), not so it can enforce them. A stale cache here can make a label
 * wrong; it can never loosen a rule.
 */

export interface AppSettings {
  programmeLengthDays: number;
  workingWeekdays: IsoWeekday[];
  officeStartTime: string;
  lateAfterTime: string;
  quizPassMark: number;
  attendanceTargetPct: number;
  attendanceBlocksCompletion: boolean;
  driftOnTrackDays: number;
  driftAttentionDays: number;
  requiredConceptPresentations: number;
  requiredFieldworkSessions: number;
  finalAssessmentsBlockCompletion: boolean;
}

/**
 * Defaults matching the migration. Used only if a settings row is missing —
 * the application should degrade to sensible behaviour rather than crash on a
 * half-configured database.
 */
const FALLBACK: AppSettings = {
  programmeLengthDays: 30,
  workingWeekdays: [1, 2, 3, 4, 5],
  officeStartTime: '10:00',
  lateAfterTime: '10:15',
  quizPassMark: 80,
  attendanceTargetPct: 90,
  attendanceBlocksCompletion: false,
  driftOnTrackDays: 2,
  driftAttentionDays: 5,
  requiredConceptPresentations: 2,
  requiredFieldworkSessions: 1,
  finalAssessmentsBlockCompletion: true,
};

function readNumber(raw: Record<string, unknown>, key: string, fallback: number): number {
  const value = raw[key];
  return typeof value === 'number' ? value : fallback;
}

function readBoolean(raw: Record<string, unknown>, key: string, fallback: boolean): boolean {
  const value = raw[key];
  return typeof value === 'boolean' ? value : fallback;
}

function readString(raw: Record<string, unknown>, key: string, fallback: string): string {
  const value = raw[key];
  return typeof value === 'string' ? value : fallback;
}

export function useSettings() {
  return useQuery({
    queryKey: ['app-settings'],
    // Settings change rarely; there is no value in refetching them constantly.
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<AppSettings> => {
      const { data, error } = await supabase.from('app_settings').select('key, value');
      if (error) throw new Error(error.message);

      const raw: Record<string, unknown> = {};
      for (const row of data ?? []) {
        const typed = row as { key: string; value: unknown };
        raw[typed.key] = typed.value;
      }

      const weekdays = raw['working_weekdays'];

      return {
        programmeLengthDays: readNumber(raw, 'programme_length_days', FALLBACK.programmeLengthDays),
        workingWeekdays: Array.isArray(weekdays)
          ? (weekdays as IsoWeekday[])
          : FALLBACK.workingWeekdays,
        officeStartTime: readString(raw, 'office_start_time', FALLBACK.officeStartTime),
        lateAfterTime: readString(raw, 'late_after_time', FALLBACK.lateAfterTime),
        quizPassMark: readNumber(raw, 'quiz_pass_mark', FALLBACK.quizPassMark),
        attendanceTargetPct: readNumber(raw, 'attendance_target_pct', FALLBACK.attendanceTargetPct),
        attendanceBlocksCompletion: readBoolean(
          raw,
          'attendance_blocks_completion',
          FALLBACK.attendanceBlocksCompletion,
        ),
        driftOnTrackDays: readNumber(raw, 'drift_on_track_days', FALLBACK.driftOnTrackDays),
        driftAttentionDays: readNumber(raw, 'drift_attention_days', FALLBACK.driftAttentionDays),
        requiredConceptPresentations: readNumber(
          raw,
          'required_concept_presentations',
          FALLBACK.requiredConceptPresentations,
        ),
        requiredFieldworkSessions: readNumber(
          raw,
          'required_fieldwork_sessions',
          FALLBACK.requiredFieldworkSessions,
        ),
        finalAssessmentsBlockCompletion: readBoolean(
          raw,
          'final_assessments_block_completion',
          FALLBACK.finalAssessmentsBlockCompletion,
        ),
      };
    },
  });
}

export function usePublicHolidays() {
  return useQuery({
    queryKey: ['public-holidays'],
    staleTime: 60 * 60 * 1000,
    queryFn: async (): Promise<string[]> => {
      const { data, error } = await supabase.from('public_holidays').select('holiday_date');
      if (error) throw new Error(error.message);
      return (data ?? []).map((row) => (row as { holiday_date: string }).holiday_date);
    },
  });
}
