import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/auth/useAuth';
import { useSettings, usePublicHolidays } from './settings';
import {
  calculateProgress,
  createCalendar,
  toIsoDate,
  type ProgressResult,
} from '@/lib/workingDays';
import type { Enrolment, EnrolmentDay, EnrolmentPause, Profile, ProgrammeDay } from '@/types/database';

/** Today in Singapore, as a plain date string. */
export function today(): string {
  return toIsoDate(new Date());
}

export interface EnrolmentDayWithProgramme extends EnrolmentDay {
  programme_days: Pick<ProgrammeDay, 'day_number' | 'phase' | 'title' | 'description'> | null;
}

/**
 * The signed-in advisor's own enrolment, or null if they have not been enrolled.
 *
 * RLS already restricts this to their own row, so no filter is needed here —
 * but one is applied anyway. Defence in depth costs nothing, and it makes the
 * intent obvious to the next reader.
 */
export function useMyEnrolment() {
  const { session } = useAuth();
  const advisorId = session?.user.id;

  return useQuery({
    queryKey: ['my-enrolment', advisorId],
    enabled: Boolean(advisorId),
    queryFn: async (): Promise<Enrolment | null> => {
      const { data, error } = await supabase
        .from('enrolments')
        .select('*')
        .eq('advisor_id', advisorId!)
        .in('status', ['active', 'paused', 'extended'])
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
      if (error) throw new Error(error.message);
      return (data as Enrolment | null) ?? null;
    },
  });
}

export function useEnrolmentDays(enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['enrolment-days', enrolmentId],
    enabled: Boolean(enrolmentId),
    queryFn: async (): Promise<EnrolmentDayWithProgramme[]> => {
      const { data, error } = await supabase
        .from('enrolment_days')
        .select('*, programme_days(day_number, phase, title, description)')
        .eq('enrolment_id', enrolmentId!)
        .order('day_number');
      if (error) throw new Error(error.message);
      return (data ?? []) as EnrolmentDayWithProgramme[];
    },
  });
}

export function useEnrolmentPauses(enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['enrolment-pauses', enrolmentId],
    enabled: Boolean(enrolmentId),
    queryFn: async (): Promise<EnrolmentPause[]> => {
      const { data, error } = await supabase
        .from('enrolment_pauses')
        .select('*')
        .eq('enrolment_id', enrolmentId!);
      if (error) throw new Error(error.message);
      return (data ?? []) as EnrolmentPause[];
    },
  });
}

/**
 * Drift, status and projected finish for an enrolment.
 *
 * All the arithmetic lives in src/lib/workingDays.ts and is covered by unit
 * tests; this hook only assembles the inputs. Nothing here recomputes dates.
 */
export function useProgress(enrolment: Enrolment | null | undefined): ProgressResult | null {
  const { data: settings } = useSettings();
  const { data: holidays } = usePublicHolidays();
  const { data: pauses } = useEnrolmentPauses(enrolment?.id);

  if (!enrolment || !settings) return null;

  const calendar = createCalendar(holidays ?? [], settings.workingWeekdays);

  return calculateProgress({
    startDate: enrolment.start_date,
    asOf: today(),
    currentDay: enrolment.current_day,
    programmeLengthDays: settings.programmeLengthDays,
    pauses: (pauses ?? []).map((pause) => ({
      pausedFrom: pause.paused_from,
      resumedOn: pause.resumed_on,
    })),
    calendar,
    thresholds: {
      onTrackDays: settings.driftOnTrackDays,
      attentionDays: settings.driftAttentionDays,
    },
  });
}

// ---------------------------------------------------------------------------
// Manager views
// ---------------------------------------------------------------------------

export interface AdvisorRow {
  profile: Profile;
  enrolment: Enrolment | null;
}

/** Every advisor with their current enrolment. Managers and admins only. */
export function useAllAdvisors() {
  return useQuery({
    queryKey: ['all-advisors'],
    queryFn: async (): Promise<AdvisorRow[]> => {
      const { data: roleRows, error: roleError } = await supabase
        .from('user_roles')
        .select('user_id')
        .eq('role', 'advisor');
      if (roleError) throw new Error(roleError.message);

      const advisorIds = (roleRows ?? []).map((row) => (row as { user_id: string }).user_id);
      if (advisorIds.length === 0) return [];

      const [profileResult, enrolmentResult] = await Promise.all([
        supabase.from('profiles').select('*').in('id', advisorIds).order('full_name'),
        supabase
          .from('enrolments')
          .select('*')
          .in('advisor_id', advisorIds)
          .in('status', ['active', 'paused', 'extended', 'completed']),
      ]);

      if (profileResult.error) throw new Error(profileResult.error.message);
      if (enrolmentResult.error) throw new Error(enrolmentResult.error.message);

      const enrolmentsByAdvisor = new Map<string, Enrolment>();
      for (const row of (enrolmentResult.data ?? []) as Enrolment[]) {
        enrolmentsByAdvisor.set(row.advisor_id, row);
      }

      return ((profileResult.data ?? []) as Profile[]).map((profile) => ({
        profile,
        enrolment: enrolmentsByAdvisor.get(profile.id) ?? null,
      }));
    },
  });
}

/** Advisors who hold the role but have no live enrolment — the enrol candidates. */
export function useUnenrolledAdvisors() {
  const { data, ...rest } = useAllAdvisors();
  return {
    ...rest,
    data: data?.filter((row) => row.enrolment === null || row.enrolment.status === 'completed'),
  };
}

export function usePublishedTemplate() {
  return useQuery({
    queryKey: ['default-template'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('programme_templates')
        .select('*')
        .eq('status', 'published')
        .order('is_default', { ascending: false })
        .limit(1)
        .maybeSingle();
      if (error) throw new Error(error.message);
      return data;
    },
  });
}

/**
 * Enrols an advisor.
 *
 * Goes through the enrol_advisor RPC rather than inserting directly, because
 * the target end date must be computed server-side — a client-supplied one
 * could be flattering, and the whole "behind schedule" signal depends on it.
 */
export function useEnrolAdvisor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: {
      advisorId: string;
      templateId: string;
      startDate: string;
      intakeLabel?: string;
    }) => {
      const { data, error } = await supabase.rpc('enrol_advisor', {
        target_advisor_id: input.advisorId,
        target_template_id: input.templateId,
        start_date: input.startDate,
        intake_label: input.intakeLabel ?? null,
      });
      if (error) throw new Error(error.message);
      return data as string;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['all-advisors'] });
    },
  });
}

/** Manager force-unlock. The reason is mandatory and recorded in the audit log. */
export function useManagerUnlockDay() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: { enrolmentId: string; dayNumber: number; reason: string }) => {
      const { error } = await supabase.rpc('manager_unlock_day', {
        target_enrolment_id: input.enrolmentId,
        target_day_number: input.dayNumber,
        reason: input.reason,
      });
      if (error) throw new Error(error.message);
    },
    onSuccess: (_result, variables) => {
      void queryClient.invalidateQueries({ queryKey: ['enrolment-days', variables.enrolmentId] });
      void queryClient.invalidateQueries({ queryKey: ['all-advisors'] });
    },
  });
}

// ---------------------------------------------------------------------------
// Enrolment corrections
//
// Pause, resume and withdraw all go through database functions rather than
// direct writes. Pausing in particular is two changes — the enrolment's status
// and a row recording the period — and if only the first landed, the programme
// would read as paused with no pause period and every drift figure afterwards
// would be quietly wrong.
// ---------------------------------------------------------------------------

function useEnrolmentAction<TInput>(
  run: (input: TInput) => PromiseLike<{ error: { message: string } | null }>,
) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: TInput) => {
      const { error } = await run(input);
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['all-advisors'] });
      void queryClient.invalidateQueries({ queryKey: ['my-enrolment'] });
      void queryClient.invalidateQueries({ queryKey: ['enrolment-pauses'] });
    },
  });
}

export function usePauseEnrolment() {
  return useEnrolmentAction<{ enrolmentId: string; reason: string; pausedFrom?: string }>(
    (input) =>
      supabase.rpc('pause_enrolment', {
        target_enrolment_id: input.enrolmentId,
        reason: input.reason,
        ...(input.pausedFrom ? { paused_from: input.pausedFrom } : {}),
      }),
  );
}

export function useResumeEnrolment() {
  return useEnrolmentAction<{ enrolmentId: string; resumeDate?: string }>((input) =>
    supabase.rpc('resume_enrolment', {
      target_enrolment_id: input.enrolmentId,
      ...(input.resumeDate ? { resume_date: input.resumeDate } : {}),
    }),
  );
}

export function useWithdrawEnrolment() {
  return useEnrolmentAction<{ enrolmentId: string; reason: string }>((input) =>
    supabase.rpc('withdraw_enrolment', {
      target_enrolment_id: input.enrolmentId,
      reason: input.reason,
    }),
  );
}
