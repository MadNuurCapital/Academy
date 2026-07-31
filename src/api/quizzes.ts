import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import type {
  AttemptResult,
  MarkLessonReadResult,
  QuizAttempt,
  StartedAttempt,
  SubmittedAnswer,
} from '@/types/database';

/**
 * Quiz and lesson progression.
 *
 * Everything here goes through an RPC rather than a table write. That is not a
 * style preference: quiz_attempts has no advisor UPDATE policy and
 * enrolment_days has no advisor write policy at all, so these functions are the
 * only route by which an attempt can be scored or a day unlocked.
 *
 * The practical consequence for anyone reading this file: there is no client
 * code that decides whether an answer was right. There cannot be — the browser
 * is never sent the answer key.
 */

/** Marks a lesson read, then re-evaluates module and day completion server-side. */
export function useMarkLessonRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (lessonId: string): Promise<MarkLessonReadResult> => {
      const { data, error } = await supabase.rpc('mark_lesson_read', {
        target_lesson_id: lessonId,
      });
      if (error) throw new Error(error.message);
      return data as MarkLessonReadResult;
    },
    onSuccess: () => {
      // A completed lesson can cascade into a completed module and an unlocked
      // day, so the whole progress surface is refetched rather than guessing
      // which parts moved.
      void queryClient.invalidateQueries({ queryKey: ['lesson'] });
      void queryClient.invalidateQueries({ queryKey: ['module-detail'] });
      void queryClient.invalidateQueries({ queryKey: ['modules-for-day'] });
      void queryClient.invalidateQueries({ queryKey: ['enrolment-days'] });
      void queryClient.invalidateQueries({ queryKey: ['my-enrolment'] });
    },
  });
}

/**
 * Opens an attempt and returns the questions in randomised order.
 *
 * The payload contains option text and nothing else — no is_correct, no
 * explanation. Inspecting this response in the browser's network tab reveals
 * no way to answer correctly.
 */
export function useStartQuizAttempt() {
  return useMutation({
    mutationFn: async (quizId: string): Promise<StartedAttempt> => {
      const { data, error } = await supabase.rpc('start_quiz_attempt', {
        target_quiz_id: quizId,
      });
      if (error) throw new Error(error.message);
      return data as StartedAttempt;
    },
  });
}

/**
 * Submits answers for scoring.
 *
 * The result carries `review` only when `passed` is true. After a failure it is
 * null, so a retry remains a test of knowledge rather than of memory.
 */
export function useSubmitQuizAttempt() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: {
      attemptId: string;
      answers: SubmittedAnswer[];
    }): Promise<AttemptResult> => {
      const { data, error } = await supabase.rpc('submit_quiz_attempt', {
        target_attempt_id: input.attemptId,
        answers: input.answers,
      });
      if (error) throw new Error(error.message);
      return data as AttemptResult;
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['module-detail'] });
      void queryClient.invalidateQueries({ queryKey: ['modules-for-day'] });
      void queryClient.invalidateQueries({ queryKey: ['enrolment-days'] });
      void queryClient.invalidateQueries({ queryKey: ['my-enrolment'] });
      void queryClient.invalidateQueries({ queryKey: ['quiz-attempts'] });
    },
  });
}

/** Attempt history for one quiz — shown so an advisor can see their own progress. */
export function useQuizAttempts(quizId: string | undefined, enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['quiz-attempts', quizId, enrolmentId],
    enabled: Boolean(quizId && enrolmentId),
    queryFn: async (): Promise<QuizAttempt[]> => {
      const { data, error } = await supabase
        .from('quiz_attempts')
        .select('*')
        .eq('quiz_id', quizId!)
        .eq('enrolment_id', enrolmentId!)
        .not('submitted_at', 'is', null)
        .order('attempt_no', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as QuizAttempt[];
    },
  });
}

/** All submitted attempts for an enrolment. Used on the progress screen. */
export function useAllQuizAttempts(enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['quiz-attempts', 'all', enrolmentId],
    enabled: Boolean(enrolmentId),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('quiz_attempts')
        .select('*, quizzes(title, module_id, modules(title))')
        .eq('enrolment_id', enrolmentId!)
        .not('submitted_at', 'is', null)
        .order('submitted_at', { ascending: false });
      if (error) throw new Error(error.message);
      return (data ?? []) as (QuizAttempt & {
        quizzes: { title: string; module_id: string; modules: { title: string } | null } | null;
      })[];
    },
  });
}
