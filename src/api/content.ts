import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import type {
  Lesson,
  Module,
  ModuleProgress,
  Quiz,
  Resource,
  RevisionCard,
  Terminology,
} from '@/types/database';

/**
 * Curriculum reads.
 *
 * None of these queries filter by status or by whether the day is unlocked.
 * They do not need to: the RLS policies in migration 0008 already restrict an
 * advisor to published modules on days they have reached, so an advisor
 * requesting Day 20 content on Day 3 receives an empty result rather than an
 * error. Managers using the same hooks see everything.
 */

export interface ModuleWithProgress extends Module {
  progress: ModuleProgress | null;
  lesson_count: number;
  has_quiz: boolean;
}

export function useModulesForDay(programmeDayId: string | undefined, enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['modules-for-day', programmeDayId, enrolmentId],
    enabled: Boolean(programmeDayId),
    queryFn: async (): Promise<ModuleWithProgress[]> => {
      const { data, error } = await supabase
        .from('modules')
        .select('*, lessons(id), quizzes(id)')
        .eq('programme_day_id', programmeDayId!)
        .order('sequence');
      if (error) throw new Error(error.message);

      const modules = (data ?? []) as (Module & {
        lessons: { id: string }[];
        quizzes: { id: string }[];
      })[];

      let progressByModule = new Map<string, ModuleProgress>();
      if (enrolmentId && modules.length > 0) {
        const { data: progressRows, error: progressError } = await supabase
          .from('module_progress')
          .select('*')
          .eq('enrolment_id', enrolmentId)
          .in(
            'module_id',
            modules.map((module) => module.id),
          );
        if (progressError) throw new Error(progressError.message);
        progressByModule = new Map(
          ((progressRows ?? []) as ModuleProgress[]).map((row) => [row.module_id, row]),
        );
      }

      return modules.map((module) => ({
        ...module,
        progress: progressByModule.get(module.id) ?? null,
        lesson_count: module.lessons?.length ?? 0,
        has_quiz: (module.quizzes?.length ?? 0) > 0,
      }));
    },
  });
}

export interface ModuleDetail {
  module: Module;
  lessons: Lesson[];
  resources: Resource[];
  terminology: Terminology[];
  revisionCards: RevisionCard[];
  quiz: Quiz | null;
  completedLessonIds: Set<string>;
  quizPassed: boolean;
}

export function useModuleDetail(moduleId: string | undefined, enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['module-detail', moduleId, enrolmentId],
    enabled: Boolean(moduleId),
    queryFn: async (): Promise<ModuleDetail | null> => {
      const { data: moduleRow, error: moduleError } = await supabase
        .from('modules')
        .select('*')
        .eq('id', moduleId!)
        .maybeSingle();
      if (moduleError) throw new Error(moduleError.message);
      if (!moduleRow) return null;

      const [lessons, resources, terminology, revisionCards, quiz] = await Promise.all([
        supabase.from('lessons').select('*').eq('module_id', moduleId!).order('sequence'),
        supabase.from('resources').select('*').eq('module_id', moduleId!).order('sequence'),
        supabase.from('terminology').select('*').eq('module_id', moduleId!).order('sequence'),
        supabase.from('revision_cards').select('*').eq('module_id', moduleId!).order('sequence'),
        supabase.from('quizzes').select('*').eq('module_id', moduleId!).maybeSingle(),
      ]);

      for (const result of [lessons, resources, terminology, revisionCards, quiz]) {
        if (result.error) throw new Error(result.error.message);
      }

      const lessonRows = (lessons.data ?? []) as Lesson[];
      const quizRow = (quiz.data as Quiz | null) ?? null;

      let completedLessonIds = new Set<string>();
      let quizPassed = false;

      if (enrolmentId) {
        const { data: progressRows } = await supabase
          .from('lesson_progress')
          .select('lesson_id')
          .eq('enrolment_id', enrolmentId)
          .in(
            'lesson_id',
            lessonRows.map((lesson) => lesson.id),
          );
        completedLessonIds = new Set(
          ((progressRows ?? []) as { lesson_id: string }[]).map((row) => row.lesson_id),
        );

        if (quizRow) {
          const { data: passedAttempt } = await supabase
            .from('quiz_attempts')
            .select('id')
            .eq('enrolment_id', enrolmentId)
            .eq('quiz_id', quizRow.id)
            .eq('passed', true)
            .limit(1)
            .maybeSingle();
          quizPassed = Boolean(passedAttempt);
        }
      }

      return {
        module: moduleRow as Module,
        lessons: lessonRows,
        resources: (resources.data ?? []) as Resource[],
        terminology: (terminology.data ?? []) as Terminology[],
        revisionCards: (revisionCards.data ?? []) as RevisionCard[],
        quiz: quizRow,
        completedLessonIds,
        quizPassed,
      };
    },
  });
}

export interface LessonWithContext {
  lesson: Lesson;
  module: Module;
  siblings: Lesson[];
  isComplete: boolean;
}

export function useLesson(lessonId: string | undefined, enrolmentId: string | undefined) {
  return useQuery({
    queryKey: ['lesson', lessonId, enrolmentId],
    enabled: Boolean(lessonId),
    queryFn: async (): Promise<LessonWithContext | null> => {
      const { data: lessonRow, error } = await supabase
        .from('lessons')
        .select('*, modules(*)')
        .eq('id', lessonId!)
        .maybeSingle();
      if (error) throw new Error(error.message);
      if (!lessonRow) return null;

      const typed = lessonRow as Lesson & { modules: Module };

      const { data: siblingRows } = await supabase
        .from('lessons')
        .select('*')
        .eq('module_id', typed.module_id)
        .order('sequence');

      let isComplete = false;
      if (enrolmentId) {
        const { data: progressRow } = await supabase
          .from('lesson_progress')
          .select('id')
          .eq('enrolment_id', enrolmentId)
          .eq('lesson_id', lessonId!)
          .maybeSingle();
        isComplete = Boolean(progressRow);
      }

      return {
        lesson: typed,
        module: typed.modules,
        siblings: (siblingRows ?? []) as Lesson[],
        isComplete,
      };
    },
  });
}
