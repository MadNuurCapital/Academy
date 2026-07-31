import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/auth/useAuth';
import type {
  CoachingAction,
  CoachingSession,
  ConceptPresentation,
  FieldworkRecord,
  PracticalAssessment,
  ReadinessOutcome,
  RubricCriterion,
  Script,
} from '@/types/database';

/**
 * Practical development: scripts, concepts, assessment, coaching, fieldwork.
 *
 * Two things are absent from this file on purpose, and their absence is the
 * design:
 *
 *   * No upload of any kind. Practicals are conducted in person; the system
 *     records a rubric score and written feedback and nothing else.
 *   * No access to candid coaching notes. Those live in coaching_private_notes,
 *     which advisors have no policy on at all, so a query from an advisor's
 *     session returns nothing regardless of what it asks for.
 */

// ---------------------------------------------------------------------------
// Scripts and concepts
// ---------------------------------------------------------------------------

export function useScripts() {
  return useQuery({
    queryKey: ['scripts'],
    queryFn: async (): Promise<Script[]> => {
      const { data, error } = await supabase.from('scripts').select('*').order('sequence');
      if (error) throw new Error(error.message);
      return (data ?? []) as Script[];
    },
  });
}

export function useScript(scriptId: string | undefined) {
  return useQuery({
    queryKey: ['script', scriptId],
    enabled: Boolean(scriptId),
    queryFn: async (): Promise<Script | null> => {
      const { data, error } = await supabase
        .from('scripts')
        .select('*')
        .eq('id', scriptId!)
        .maybeSingle();
      if (error) throw new Error(error.message);
      return (data as Script | null) ?? null;
    },
  });
}

export function useConceptPresentations() {
  return useQuery({
    queryKey: ['concepts'],
    queryFn: async (): Promise<ConceptPresentation[]> => {
      const { data, error } = await supabase
        .from('concept_presentations')
        .select('*')
        .order('sequence');
      if (error) throw new Error(error.message);
      return (data ?? []) as ConceptPresentation[];
    },
  });
}

// ---------------------------------------------------------------------------
// Practical assessment
// ---------------------------------------------------------------------------

export function useMyAssessments(enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['practical-assessments', enrolmentId],
    enabled: Boolean(enrolmentId),
    queryFn: async (): Promise<PracticalAssessment[]> => {
      const { data, error } = await supabase
        .from('practical_assessments')
        .select('*')
        .eq('enrolment_id', enrolmentId!)
        .order('created_at', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as PracticalAssessment[];
    },
  });
}

/** The manager's review queue: everything awaiting a score. */
export function useReviewQueue() {
  return useQuery({
    queryKey: ['review-queue'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('practical_assessments')
        .select('*, enrolments(advisor_id, profiles:advisor_id(full_name))')
        .in('status', ['pending', 'retry_required'])
        .order('created_at');
      if (error) throw new Error(error.message);
      return (data ?? []) as (PracticalAssessment & {
        enrolments: { advisor_id: string; profiles: { full_name: string } | null } | null;
      })[];
    },
  });
}

export function useRubric(rubricId: string | undefined) {
  return useQuery({
    queryKey: ['rubric', rubricId],
    enabled: Boolean(rubricId),
    queryFn: async (): Promise<RubricCriterion[]> => {
      const { data, error } = await supabase
        .from('rubric_criteria')
        .select('*')
        .eq('rubric_id', rubricId!)
        .order('sequence');
      if (error) throw new Error(error.message);
      return (data ?? []) as RubricCriterion[];
    },
  });
}

export function useScorePractical() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: {
      assessmentId: string;
      scores: { criterion_id: string; score: number; comment?: string }[];
      feedback: string;
    }) => {
      const { data, error } = await supabase.rpc('score_practical', {
        target_assessment_id: input.assessmentId,
        scores: input.scores,
        feedback: input.feedback,
      });
      if (error) throw new Error(error.message);
      return data as { total_score: number; max_score: number; passed: boolean };
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['review-queue'] });
      void queryClient.invalidateQueries({ queryKey: ['practical-assessments'] });
      void queryClient.invalidateQueries({ queryKey: ['readiness'] });
    },
  });
}

export function useAcknowledgeFeedback() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (assessmentId: string) => {
      const { error } = await supabase.rpc('acknowledge_feedback', {
        target_assessment_id: assessmentId,
      });
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['practical-assessments'] });
    },
  });
}

// ---------------------------------------------------------------------------
// Coaching
// ---------------------------------------------------------------------------

export function useMyCoaching() {
  const { session } = useAuth();
  const userId = session?.user.id;

  return useQuery({
    queryKey: ['coaching', 'mine', userId],
    enabled: Boolean(userId),
    queryFn: async (): Promise<CoachingSession[]> => {
      const { data, error } = await supabase
        .from('coaching_sessions')
        .select('*')
        .eq('advisor_id', userId!)
        .order('scheduled_at', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as CoachingSession[];
    },
  });
}

export function useAllCoaching() {
  return useQuery({
    queryKey: ['coaching', 'all'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('coaching_sessions')
        .select('*, profiles:advisor_id(full_name)')
        .order('scheduled_at', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as (CoachingSession & { profiles: { full_name: string } | null })[];
    },
  });
}

export function useCoachingSession(sessionId: string | undefined) {
  return useQuery({
    queryKey: ['coaching', sessionId],
    enabled: Boolean(sessionId),
    queryFn: async () => {
      const [sessionResult, actionsResult] = await Promise.all([
        supabase.from('coaching_sessions').select('*').eq('id', sessionId!).maybeSingle(),
        supabase.from('coaching_actions').select('*').eq('session_id', sessionId!).order('due_date'),
      ]);
      if (sessionResult.error) throw new Error(sessionResult.error.message);
      if (actionsResult.error) throw new Error(actionsResult.error.message);
      return {
        session: (sessionResult.data as CoachingSession | null) ?? null,
        actions: (actionsResult.data ?? []) as CoachingAction[],
      };
    },
  });
}

export function useScheduleCoaching() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: {
      advisorId: string;
      scheduledAt: string;
      topic: string;
      reason?: string;
      preparation?: string;
    }) => {
      const { data, error } = await supabase.rpc('schedule_coaching', {
        target_advisor_id: input.advisorId,
        scheduled_at: input.scheduledAt,
        topic: input.topic,
        reason: input.reason ?? null,
        preparation: input.preparation ?? null,
      });
      if (error) throw new Error(error.message);
      return data as string;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['coaching'] });
    },
  });
}

export function useCompleteCoachingAction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (actionId: string) => {
      const { error } = await supabase.rpc('complete_coaching_action', {
        target_action_id: actionId,
      });
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['coaching'] });
      void queryClient.invalidateQueries({ queryKey: ['readiness'] });
    },
  });
}

// ---------------------------------------------------------------------------
// Fieldwork
// ---------------------------------------------------------------------------

export function useFieldwork(advisorId: string | undefined) {
  return useQuery({
    queryKey: ['fieldwork', advisorId],
    enabled: Boolean(advisorId),
    queryFn: async (): Promise<FieldworkRecord[]> => {
      const { data, error } = await supabase
        .from('fieldwork_records')
        .select('*')
        .eq('advisor_id', advisorId!)
        .order('session_date', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as FieldworkRecord[];
    },
  });
}

export function useRecordFieldwork() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: Partial<FieldworkRecord> & { advisor_id: string }) => {
      const { error } = await supabase.from('fieldwork_records').insert(input);
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['fieldwork'] });
      void queryClient.invalidateQueries({ queryKey: ['readiness'] });
    },
  });
}

/** The advisor's own reflection — the one field on a fieldwork record they own. */
export function useSubmitReflection() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: { recordId: string; reflection: string }) => {
      const { error } = await supabase
        .from('fieldwork_records')
        .update({ advisor_reflection: input.reflection })
        .eq('id', input.recordId);
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['fieldwork'] });
    },
  });
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

export function useNotifications() {
  const { session } = useAuth();
  const userId = session?.user.id;

  return useQuery({
    queryKey: ['notifications', userId],
    enabled: Boolean(userId),
    refetchInterval: 60_000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      if (error) throw new Error(error.message);
      return data ?? [];
    },
  });
}

export function useMarkNotificationRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (notificationId: string) => {
      const { error } = await supabase
        .from('notifications')
        .update({ read_at: new Date().toISOString() })
        .eq('id', notificationId);
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
  });
}

// ---------------------------------------------------------------------------
// Readiness
// ---------------------------------------------------------------------------

export interface RequirementCheck {
  key: string;
  label: string;
  met: boolean;
  blocks: boolean;
  detail: string;
}

export interface ReadinessEvaluation {
  enrolment_id: string;
  requirements: RequirementCheck[];
  blocker_count: number;
  can_complete_without_override: boolean;
  attendance_pct: number | null;
  modules_complete: number;
  modules_required: number;
  quizzes_passed: number;
}

export function useReadinessEvaluation(enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['readiness', enrolmentId],
    enabled: Boolean(enrolmentId),
    queryFn: async (): Promise<ReadinessEvaluation> => {
      const { data, error } = await supabase.rpc('evaluate_completion_requirements', {
        target_enrolment_id: enrolmentId!,
      });
      if (error) throw new Error(error.message);
      return data as ReadinessEvaluation;
    },
  });
}

export function useRecordReadinessDecision() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: {
      enrolmentId: string;
      outcome: ReadinessOutcome;
      strengths?: string;
      developmentAreas?: string;
      notes?: string;
      overrideReason?: string;
    }) => {
      const { data, error } = await supabase.rpc('record_readiness_decision', {
        target_enrolment_id: input.enrolmentId,
        outcome: input.outcome,
        strengths: input.strengths ?? null,
        development_areas: input.developmentAreas ?? null,
        notes: input.notes ?? null,
        override_reason: input.overrideReason ?? null,
      });
      if (error) throw new Error(error.message);
      return data as string;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['readiness'] });
      void queryClient.invalidateQueries({ queryKey: ['all-advisors'] });
    },
  });
}

export function useReadinessReviews(enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['readiness-reviews', enrolmentId],
    enabled: Boolean(enrolmentId),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('readiness_reviews')
        .select('*')
        .eq('enrolment_id', enrolmentId!)
        .order('decided_at', { ascending: false });
      if (error) throw new Error(error.message);
      return data ?? [];
    },
  });
}
