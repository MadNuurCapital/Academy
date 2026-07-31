-- ATLAS Academy — 0006 · Advisor progress
--
-- The division of labour here matters:
--
--   An advisor may record that they *did* something — read a lesson, chose
--   these answers. They may not record what it *means*. Whether a module is
--   complete, whether an attempt passed, whether a day is finished and the next
--   one opens: all of that is written by the security-definer functions in
--   migration 0007, never by the client.
--
-- So lesson_progress and quiz_answers accept advisor inserts. module_progress,
-- the scored fields on quiz_attempts, and enrolment_days do not.

create type public.module_progress_status as enum ('not_started', 'in_progress', 'complete');

-- ---------------------------------------------------------------------------
-- lesson_progress — advisor-writable
-- ---------------------------------------------------------------------------

create table public.lesson_progress (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (enrolment_id, lesson_id)
);

comment on table public.lesson_progress is
  'One row per lesson an advisor has marked as read. The unique constraint makes re-marking idempotent rather than an error.';

create index lesson_progress_enrolment_idx on public.lesson_progress (enrolment_id);

-- ---------------------------------------------------------------------------
-- module_progress — derived, never written by an advisor
-- ---------------------------------------------------------------------------

create table public.module_progress (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  module_id uuid not null references public.modules (id) on delete cascade,
  status public.module_progress_status not null default 'not_started',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (enrolment_id, module_id)
);

comment on table public.module_progress is
  'Derived state. Written only by public.evaluate_module_completion, which requires every lesson read and the quiz passed.';

create index module_progress_enrolment_idx on public.module_progress (enrolment_id, status);

create trigger module_progress_set_updated_at
  before update on public.module_progress
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- quiz_attempts
-- ---------------------------------------------------------------------------

create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  quiz_id uuid not null references public.quizzes (id) on delete cascade,
  attempt_no integer not null,
  -- Null until submitted. Written only by submit_quiz_attempt.
  score integer check (score is null or score between 0 and 100),
  passed boolean,
  pass_mark_applied integer,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  reset_by uuid references public.profiles (id) on delete set null,
  reset_reason text,
  created_at timestamptz not null default now(),
  unique (enrolment_id, quiz_id, attempt_no)
);

comment on table public.quiz_attempts is
  'Attempts are unlimited: a failure already blocks the next day, so capping attempts would only create administrative work unlocking people.';

comment on column public.quiz_attempts.pass_mark_applied is
  'The pass mark in force when this attempt was scored. Recorded so that changing the organisation-wide default later does not retroactively alter whether a historical attempt passed.';

create index quiz_attempts_enrolment_idx on public.quiz_attempts (enrolment_id, quiz_id);
create index quiz_attempts_open_idx on public.quiz_attempts (enrolment_id) where submitted_at is null;

-- ---------------------------------------------------------------------------
-- quiz_answers
-- ---------------------------------------------------------------------------

create table public.quiz_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.quiz_attempts (id) on delete cascade,
  question_id uuid not null references public.quiz_questions (id) on delete cascade,
  option_id uuid not null references public.quiz_options (id) on delete cascade,
  -- Graded server-side by submit_quiz_attempt. An advisor supplies the choice,
  -- never the verdict.
  is_correct boolean,
  created_at timestamptz not null default now(),
  unique (attempt_id, question_id)
);

comment on column public.quiz_answers.is_correct is
  'Written by submit_quiz_attempt after comparing against quiz_options. Advisors have no privilege on this column.';

create index quiz_answers_attempt_idx on public.quiz_answers (attempt_id);

-- ---------------------------------------------------------------------------
-- knowledge_check_responses — the in-lesson checks, not graded
-- ---------------------------------------------------------------------------

create table public.knowledge_check_responses (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  question_key text not null,
  was_correct boolean not null,
  created_at timestamptz not null default now()
);

comment on table public.knowledge_check_responses is
  'Formative checks inside a lesson. Recorded for the advisor''s own benefit and never used to gate progress, so self-reporting here is harmless.';

create index knowledge_check_enrolment_idx on public.knowledge_check_responses (enrolment_id, lesson_id);
