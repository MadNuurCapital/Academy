import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import type { ContentStatus, Lesson, Module, ProgrammeDay } from '@/types/database';

/**
 * Content authoring.
 *
 * Managers have always had write access to the content tables; what was missing
 * was a screen. Two things here do go through database functions rather than
 * direct writes:
 *
 *   - the quiz, because the answer key is unreadable from the browser by design
 *     and a question plus its options must be saved as one unit; and
 *   - publishing, because it is the moment content becomes visible to advisors
 *     and is worth an audit entry.
 *
 * Everything else is an ordinary update, guarded by the policies already there.
 */

export interface DayWithModules {
  day: ProgrammeDay;
  modules: Module[];
}

/** The whole 30-day programme, with each day's modules and their status. */
export function useContentOutline() {
  return useQuery({
    queryKey: ['content-outline'],
    queryFn: async (): Promise<DayWithModules[]> => {
      const [dayResult, moduleResult] = await Promise.all([
        supabase.from('programme_days').select('*').order('day_number'),
        supabase.from('modules').select('*').order('sequence'),
      ]);
      if (dayResult.error) throw new Error(dayResult.error.message);
      if (moduleResult.error) throw new Error(moduleResult.error.message);

      const modulesByDay = new Map<string, Module[]>();
      for (const row of (moduleResult.data ?? []) as Module[]) {
        modulesByDay.set(row.programme_day_id, [
          ...(modulesByDay.get(row.programme_day_id) ?? []),
          row,
        ]);
      }

      return ((dayResult.data ?? []) as ProgrammeDay[]).map((day) => ({
        day,
        modules: modulesByDay.get(day.id) ?? [],
      }));
    },
  });
}

export interface ModuleForEditing {
  module: Module;
  lessons: Lesson[];
  quizId: string | null;
}

export function useModuleForEditing(moduleId: string | undefined) {
  return useQuery({
    queryKey: ['module-editing', moduleId],
    enabled: Boolean(moduleId),
    queryFn: async (): Promise<ModuleForEditing | null> => {
      const [moduleResult, lessonResult, quizResult] = await Promise.all([
        supabase.from('modules').select('*').eq('id', moduleId!).maybeSingle(),
        supabase.from('lessons').select('*').eq('module_id', moduleId!).order('sequence'),
        supabase.from('quizzes').select('id').eq('module_id', moduleId!).maybeSingle(),
      ]);
      if (moduleResult.error) throw new Error(moduleResult.error.message);
      if (lessonResult.error) throw new Error(lessonResult.error.message);
      if (quizResult.error) throw new Error(quizResult.error.message);
      if (!moduleResult.data) return null;

      return {
        module: moduleResult.data as Module,
        lessons: (lessonResult.data ?? []) as Lesson[],
        quizId: (quizResult.data as { id: string } | null)?.id ?? null,
      };
    },
  });
}

function useAuthoringMutation<TInput>(
  run: (input: TInput) => PromiseLike<{ error: { message: string } | null }>,
) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: TInput) => {
      const { error } = await run(input);
      if (error) throw new Error(error.message);
    },
    onSuccess: () => invalidateContent(queryClient),
  });
}

export function useUpdateModule() {
  return useAuthoringMutation<{
    moduleId: string;
    title: string;
    description: string | null;
    estMinutes: number;
  }>((input) =>
    supabase
      .from('modules')
      .update({
        title: input.title.trim(),
        description: input.description?.trim() || null,
        est_minutes: input.estMinutes,
      })
      .eq('id', input.moduleId),
  );
}

export function useUpdateLesson() {
  return useAuthoringMutation<{ lessonId: string; title: string; body: string }>((input) =>
    supabase
      .from('lessons')
      .update({ title: input.title.trim(), body: input.body })
      .eq('id', input.lessonId),
  );
}

/**
 * Publish, or return to draft.
 *
 * Draft content is invisible to advisors — the policies stop it at the database
 * — and a day whose required module is unpublished counts as incomplete, so
 * nobody is advanced past material that has not been signed off.
 */
export function useSetModuleStatus() {
  return useAuthoringMutation<{ moduleId: string; status: ContentStatus }>((input) =>
    supabase.rpc('set_module_status', {
      target_module_id: input.moduleId,
      new_status: input.status,
    }),
  );
}

// ---------------------------------------------------------------------------
// Quizzes
// ---------------------------------------------------------------------------

export interface AuthoringOption {
  id?: string;
  option_text: string;
  is_correct: boolean;
  sequence?: number;
}

export interface AuthoringQuestion {
  id: string;
  question_text: string;
  explanation: string | null;
  sequence: number;
  options: AuthoringOption[];
}

export interface QuizForAuthoring {
  quiz: { id: string; title: string; pass_mark_pct: number; is_final: boolean };
  questions: AuthoringQuestion[];
}

/**
 * The quiz with its answers.
 *
 * This is the only route to `is_correct` in the whole application. The column is
 * revoked from the `authenticated` role, which includes managers — the grant is
 * to the role, not the person — so reading it needs a function that runs as the
 * owner and checks the role itself.
 */
export function useQuizForAuthoring(quizId: string | undefined) {
  return useQuery({
    queryKey: ['quiz-authoring', quizId],
    enabled: Boolean(quizId),
    queryFn: async (): Promise<QuizForAuthoring> => {
      const { data, error } = await supabase.rpc('quiz_for_authoring', {
        target_quiz_id: quizId!,
      });
      if (error) throw new Error(error.message);
      return data as QuizForAuthoring;
    },
  });
}

export function useSaveQuizQuestion() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: {
      quizId: string;
      questionId: string | null;
      questionText: string;
      explanation: string | null;
      sequence: number;
      options: AuthoringOption[];
    }) => {
      const { error } = await supabase.rpc('save_quiz_question', {
        target_quiz_id: input.quizId,
        question_id: input.questionId,
        question_text: input.questionText,
        explanation: input.explanation,
        sequence: input.sequence,
        options: input.options.map((option, index) => ({
          option_text: option.option_text,
          is_correct: option.is_correct,
          sequence: index + 1,
        })),
      });
      if (error) throw new Error(error.message);
    },
    onSuccess: () => invalidateContent(queryClient),
  });
}

export function useDeleteQuizQuestion() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: { questionId: string }) => {
      const { error } = await supabase.rpc('delete_quiz_question', {
        question_id: input.questionId,
      });
      if (error) throw new Error(error.message);
    },
    onSuccess: () => invalidateContent(queryClient),
  });
}

function invalidateContent(queryClient: ReturnType<typeof useQueryClient>) {
  for (const key of [
    'content-outline',
    'module-editing',
    'quiz-authoring',
    'module-detail',
    'modules-for-day',
    'lesson',
  ]) {
    void queryClient.invalidateQueries({ queryKey: [key] });
  }
}
