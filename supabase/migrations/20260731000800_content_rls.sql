-- ATLAS Academy — 0008 · Row Level Security for content and progress
--
-- Same discipline as migration 0004: enabled everywhere, deny by default, and
-- advisors get read access scoped to published content on days they have
-- actually unlocked.
--
-- The one unusual thing in this file is the column-level privilege on
-- quiz_options.is_correct. See the section at the end.

alter table public.modules                    enable row level security;
alter table public.lessons                    enable row level security;
alter table public.resources                  enable row level security;
alter table public.terminology                enable row level security;
alter table public.revision_cards             enable row level security;
alter table public.quizzes                    enable row level security;
alter table public.quiz_questions             enable row level security;
alter table public.quiz_options               enable row level security;
alter table public.lesson_progress            enable row level security;
alter table public.module_progress            enable row level security;
alter table public.quiz_attempts              enable row level security;
alter table public.quiz_answers               enable row level security;
alter table public.knowledge_check_responses  enable row level security;

-- ---------------------------------------------------------------------------
-- modules
-- ---------------------------------------------------------------------------

-- Published *and* unlocked. Publishing alone is not enough: an advisor on Day 3
-- must not be able to read Day 20's content by guessing a URL.
create policy "modules: advisor reads unlocked published"
  on public.modules for select
  to authenticated
  using (public.module_is_available(id, public.my_enrolment_id()));

create policy "modules: managers read all"
  on public.modules for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "modules: managers write"
  on public.modules for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- Module children — lessons, resources, terminology, revision cards
--
-- All four gate on the same availability check, so there is one definition of
-- "the advisor may see this" rather than four that can drift apart.
-- ---------------------------------------------------------------------------

create policy "lessons: advisor reads available"
  on public.lessons for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "lessons: managers read all"
  on public.lessons for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "lessons: managers write"
  on public.lessons for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "resources: advisor reads available"
  on public.resources for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "resources: managers read all"
  on public.resources for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "resources: managers write"
  on public.resources for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "terminology: advisor reads available"
  on public.terminology for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "terminology: managers read all"
  on public.terminology for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "terminology: managers write"
  on public.terminology for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "revision_cards: advisor reads available"
  on public.revision_cards for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "revision_cards: managers read all"
  on public.revision_cards for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "revision_cards: managers write"
  on public.revision_cards for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- quizzes and questions
-- ---------------------------------------------------------------------------

create policy "quizzes: advisor reads available"
  on public.quizzes for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "quizzes: managers read all"
  on public.quizzes for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quizzes: managers write"
  on public.quizzes for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "quiz_questions: advisor reads available"
  on public.quiz_questions for select
  to authenticated
  using (
    exists (
      select 1 from public.quizzes qz
      where qz.id = quiz_questions.quiz_id
        and public.module_is_available(qz.module_id, public.my_enrolment_id())
    )
  );

create policy "quiz_questions: managers read all"
  on public.quiz_questions for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quiz_questions: managers write"
  on public.quiz_questions for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "quiz_options: advisor reads available"
  on public.quiz_options for select
  to authenticated
  using (
    exists (
      select 1
      from public.quiz_questions qq
      join public.quizzes qz on qz.id = qq.quiz_id
      where qq.id = quiz_options.question_id
        and public.module_is_available(qz.module_id, public.my_enrolment_id())
    )
  );

create policy "quiz_options: managers read all"
  on public.quiz_options for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quiz_options: managers write"
  on public.quiz_options for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- Progress tables
-- ---------------------------------------------------------------------------

-- Advisors may read their own lesson progress and insert to it. Inserting
-- directly is harmless — reading a lesson is self-reported either way — but the
-- interface goes through mark_lesson_read() so that module and day evaluation
-- happen in the same transaction.
create policy "lesson_progress: advisor reads own"
  on public.lesson_progress for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "lesson_progress: advisor inserts own"
  on public.lesson_progress for insert
  to authenticated
  with check (public.owns_enrolment(enrolment_id));

create policy "lesson_progress: managers read all"
  on public.lesson_progress for select
  to authenticated
  using (public.is_manager_or_admin());

-- module_progress is derived state. Advisors read it and never write it: only
-- evaluate_module_completion may decide a module is finished.
create policy "module_progress: advisor reads own"
  on public.module_progress for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "module_progress: managers read all"
  on public.module_progress for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "module_progress: managers write"
  on public.module_progress for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- Advisors read their own attempts. There is deliberately NO advisor insert or
-- update policy: attempts are created by start_quiz_attempt and scored by
-- submit_quiz_attempt, both security definer. Without this restriction a client
-- could simply set passed = true.
create policy "quiz_attempts: advisor reads own"
  on public.quiz_attempts for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "quiz_attempts: managers read all"
  on public.quiz_attempts for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quiz_attempts: managers write"
  on public.quiz_attempts for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- Likewise for answers: readable after the fact, written only by the scorer.
create policy "quiz_answers: advisor reads own"
  on public.quiz_answers for select
  to authenticated
  using (
    exists (
      select 1 from public.quiz_attempts qa
      where qa.id = quiz_answers.attempt_id
        and public.owns_enrolment(qa.enrolment_id)
    )
  );

create policy "quiz_answers: managers read all"
  on public.quiz_answers for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "knowledge_checks: advisor reads own"
  on public.knowledge_check_responses for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "knowledge_checks: advisor inserts own"
  on public.knowledge_check_responses for insert
  to authenticated
  with check (public.owns_enrolment(enrolment_id));

create policy "knowledge_checks: managers read all"
  on public.knowledge_check_responses for select
  to authenticated
  using (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- Column-level protection for the answer key
-- ---------------------------------------------------------------------------
--
-- RLS controls which ROWS a user sees. It cannot hide a COLUMN. The policy
-- above deliberately lets an advisor read the quiz_options rows for a quiz they
-- are entitled to sit — they need option_text to answer the question — but
-- is_correct sitting in those same rows would hand over the answer key.
--
-- Column privileges are the correct tool. Revoking table-wide SELECT and
-- re-granting only the safe columns means PostgreSQL refuses
--
--     select is_correct from quiz_options
--
-- with "permission denied for column", before RLS is even consulted. There is
-- no ordering of filters, no view definition and no client behaviour that can
-- reach it.
--
-- quiz_answers.is_correct is protected the same way: an advisor may see their
-- own answers, but the grading verdict is written and read by the scorer.

revoke select on public.quiz_options from authenticated;
grant select (id, question_id, option_text, sequence, created_at, updated_at)
  on public.quiz_options to authenticated;

revoke select on public.quiz_questions from authenticated;
grant select (id, quiz_id, question_text, question_type, sequence, created_at, updated_at)
  on public.quiz_questions to authenticated;

-- The service role and managers need the full picture; those paths go through
-- security-definer functions or the manager policies, both of which run as the
-- owner and are unaffected by the grants above.
--
-- KNOWN FRAGILITY, and how it is defended:
--
-- Column privileges are undone by a later table-wide `grant select on
-- quiz_options to authenticated` — including the blanket
-- `grant select on all tables in schema public` that is easy to run from the
-- Supabase SQL editor while debugging something unrelated. The answer key would
-- silently become readable, with no error and nothing in the interface to show
-- it.
--
-- Three things guard against that:
--
--   1. supabase/tests/rls.test.sql asserts the privilege is absent, and its
--      runner reproduces Supabase's real grant ordering, so a regression fails
--      the suite rather than reaching production.
--   2. The assertion below fails the migration immediately if the revoke did
--      not take effect.
--   3. quiz_questions_for_attempt gives the application a route that never
--      selects the column, so no interface code has a reason to widen the grant.

do $$
begin
  if has_column_privilege('authenticated', 'public.quiz_options', 'is_correct', 'select') then
    raise exception
      'Migration guard: the authenticated role can still read quiz_options.is_correct. '
      'A blanket table grant has overridden the column privilege and every quiz answer is exposed.';
  end if;

  if has_column_privilege('authenticated', 'public.quiz_questions', 'explanation', 'select') then
    raise exception
      'Migration guard: the authenticated role can still read quiz_questions.explanation.';
  end if;

  if not has_column_privilege('authenticated', 'public.quiz_options', 'option_text', 'select') then
    raise exception
      'Migration guard: the authenticated role cannot read quiz_options.option_text, '
      'so advisors would be unable to sit a quiz at all.';
  end if;
end;
$$;

comment on column public.quiz_options.is_correct is
  'Protected by column privilege, not by RLS and not by the interface. Revoked from the authenticated role in migration 0008.';

comment on column public.quiz_questions.explanation is
  'Withheld from advisors for the same reason as the answer key: revealed only in the submit_quiz_attempt payload, and only on a pass.';
