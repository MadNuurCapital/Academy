import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/auth/useAuth';
import { today } from './enrolments';
import type { AttendanceStatus } from '@/types/database';

/**
 * Attendance.
 *
 * Every write goes through `save_attendance`, which takes the whole room in one
 * call. That is what makes the under-a-minute target achievable — fifteen
 * separate requests would not be, however fast each one is. It is also where
 * the working-day rule and the mandatory reason for an edit are enforced, so
 * there is no route by which the interface can bypass either.
 *
 * Advisors have no write path at all. Not a disabled button — no policy.
 */

export interface AttendanceRecord {
  id: string;
  advisor_id: string;
  attendance_date: string;
  status: AttendanceStatus;
  remarks: string | null;
  recorded_by: string | null;
  recorded_at: string;
}

export interface AttendanceEntry {
  advisor_id: string;
  status: AttendanceStatus;
  remarks?: string | null;
  /** Required only when changing a status that was already saved. */
  reason?: string | null;
}

export interface SaveAttendanceResult {
  date: string;
  present: number;
  late: number;
  absent: number;
  changed: number;
}

export interface AttendanceSummary {
  present: number;
  late: number;
  absent: number;
  total_recorded: number;
  attendance_pct: number | null;
  target_pct: number;
  below_target: boolean;
}

export interface MakeupTask {
  id: string;
  enrolment_id: string;
  attendance_date: string;
  programme_day: number | null;
  status: 'outstanding' | 'complete' | 'waived';
  resolved_at: string | null;
  note: string | null;
}

/** Attendance for one date across every advisor. Managers and admins. */
export function useAttendanceForDate(date: string) {
  return useQuery({
    queryKey: ['attendance', 'date', date],
    queryFn: async (): Promise<AttendanceRecord[]> => {
      const { data, error } = await supabase
        .from('attendance_records')
        .select('*')
        .eq('attendance_date', date);
      if (error) throw new Error(error.message);
      return (data ?? []) as AttendanceRecord[];
    },
  });
}

/** Is the given date a working day? Weekends and holidays are excluded. */
export function useIsWorkingDay(date: string) {
  return useQuery({
    queryKey: ['is-working-day', date],
    staleTime: 60 * 60 * 1000,
    queryFn: async (): Promise<boolean> => {
      const { data, error } = await supabase.rpc('is_working_day', { target_date: date });
      if (error) throw new Error(error.message);
      return Boolean(data);
    },
  });
}

/** How many active advisors are still unmarked. Drives the manager banner. */
export function useAttendancePending(date: string = today()) {
  return useQuery({
    queryKey: ['attendance', 'pending', date],
    queryFn: async (): Promise<number> => {
      const { data, error } = await supabase.rpc('attendance_pending_for', { target_date: date });
      if (error) throw new Error(error.message);
      return Number(data ?? 0);
    },
  });
}

export function useSaveAttendance() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: {
      date: string;
      entries: AttendanceEntry[];
    }): Promise<SaveAttendanceResult> => {
      const { data, error } = await supabase.rpc('save_attendance', {
        target_date: input.date,
        entries: input.entries,
      });
      if (error) throw new Error(error.message);
      return data as SaveAttendanceResult;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['attendance'] });
      void queryClient.invalidateQueries({ queryKey: ['makeup-tasks'] });
    },
  });
}

/** An advisor's own summary, or any advisor's if the caller is staff. */
export function useAttendanceSummary(advisorId: string | undefined) {
  return useQuery({
    queryKey: ['attendance', 'summary', advisorId],
    enabled: Boolean(advisorId),
    queryFn: async (): Promise<AttendanceSummary> => {
      const { data, error } = await supabase.rpc('attendance_summary', {
        target_advisor_id: advisorId!,
      });
      if (error) throw new Error(error.message);
      return data as AttendanceSummary;
    },
  });
}

export function useMyAttendanceHistory() {
  const { session } = useAuth();
  const advisorId = session?.user.id;

  return useQuery({
    queryKey: ['attendance', 'history', advisorId],
    enabled: Boolean(advisorId),
    queryFn: async (): Promise<AttendanceRecord[]> => {
      const { data, error } = await supabase
        .from('attendance_records')
        .select('*')
        .eq('advisor_id', advisorId!)
        .order('attendance_date', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as AttendanceRecord[];
    },
  });
}

/** Full history with optional filters. Managers and admins. */
export function useAttendanceHistory(filters: { advisorId?: string; from?: string; to?: string }) {
  return useQuery({
    queryKey: ['attendance', 'history', 'all', filters],
    queryFn: async () => {
      let query = supabase
        .from('attendance_records')
        .select('*, profiles!attendance_records_advisor_id_fkey(full_name)')
        .order('attendance_date', { ascending: false })
        .limit(500);

      if (filters.advisorId) query = query.eq('advisor_id', filters.advisorId);
      if (filters.from) query = query.gte('attendance_date', filters.from);
      if (filters.to) query = query.lte('attendance_date', filters.to);

      const { data, error } = await query;
      if (error) throw new Error(error.message);
      return (data ?? []) as (AttendanceRecord & { profiles: { full_name: string } | null })[];
    },
  });
}

export function useMyMakeupTasks(enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['makeup-tasks', enrolmentId],
    enabled: Boolean(enrolmentId),
    queryFn: async (): Promise<MakeupTask[]> => {
      const { data, error } = await supabase
        .from('makeup_tasks')
        .select('*')
        .eq('enrolment_id', enrolmentId!)
        .order('attendance_date', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as MakeupTask[];
    },
  });
}

export function useOutstandingMakeupTasks() {
  return useQuery({
    queryKey: ['makeup-tasks', 'outstanding'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('makeup_tasks')
        .select('*, enrolments(advisor_id, profiles:advisor_id(full_name))')
        .eq('status', 'outstanding')
        .order('attendance_date', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as (MakeupTask & {
        enrolments: { advisor_id: string; profiles: { full_name: string } | null } | null;
      })[];
    },
  });
}

export function useResolveMakeupTask() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: {
      taskId: string;
      status: 'complete' | 'waived';
      note?: string;
    }) => {
      const { error } = await supabase.rpc('resolve_makeup_task', {
        target_task_id: input.taskId,
        new_status: input.status,
        note: input.note ?? null,
      });
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['makeup-tasks'] });
    },
  });
}
