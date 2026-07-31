-- ATLAS Academy — 0005 · Curriculum content
--
-- Modules hang off a programme day; lessons, resources, terminology, revision
-- cards and a quiz hang off a module. Everything carries a content status so an
-- administrator can draft, review and publish without a deployment, and archive
-- outdated material without deleting it — historical completions must stay
-- meaningful.
--
-- The one genuinely security-sensitive object here is quiz_options.is_correct.
-- See the view at the bottom of this file.

-- ---------------------------------------------------------------------------
-- modules
-- ---------------------------------------------------------------------------

create table public.modules (
  id uuid primary key default gen_random_uuid(),
  programme_day_id uuid not null references public.programme_days (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  category text not null default 'general',
  description text,
  objectives jsonb not null default '[]'::jsonb,
  est_minutes integer not null default 15 check (est_minutes > 0),
  is_required boolean not null default true,
  sequence integer not null default 1,
  status public.content_status not null default 'draft',
  version integer not null default 1,
  owner_id uuid references public.profiles (id) on delete set null,
  last_reviewed_at date,
  next_review_at date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.modules is
  'A unit of learning within a programme day. Optional modules (is_required = false) never block day completion.';

comment on column public.modules.is_required is
  'Required modules gate the next day. The extra concept presentations (Life Journey Timeline, Education Funding Timeline) are optional and must not block progress.';

create index modules_day_idx on public.modules (programme_day_id, sequence);
create index modules_status_idx on public.modules (status);

create trigger modules_set_updated_at
  before update on public.modules
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- lessons
-- ---------------------------------------------------------------------------

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  body text not null default '',
  sequence integer not null default 1,
  est_minutes integer not null default 10 check (est_minutes > 0),
  lesson_type text not null default 'text' check (lesson_type in ('text', 'video', 'external')),
  video_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.lessons.video_url is
  'No video ships in the MVP, but the column exists so recorded lessons can be attached later without a migration.';

comment on column public.lessons.est_minutes is
  'Microlearning: lessons are 5-15 minutes. Longer material should be split.';

create index lessons_module_idx on public.lessons (module_id, sequence);

create trigger lessons_set_updated_at
  before update on public.lessons
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- resources, terminology, revision cards
-- ---------------------------------------------------------------------------

create table public.resources (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules (id) on delete cascade,
  title text not null,
  storage_path text,
  external_url text,
  resource_type text not null default 'pdf'
    check (resource_type in ('pdf', 'link', 'slides', 'document')),
  downloadable boolean not null default true,
  sequence integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint resources_needs_a_target check (storage_path is not null or external_url is not null)
);

comment on column public.resources.downloadable is
  'Advisors may download resources. Scripts are most useful on a phone before an appointment.';

create index resources_module_idx on public.resources (module_id, sequence);

create trigger resources_set_updated_at
  before update on public.resources
  for each row execute function public.set_updated_at();

create table public.terminology (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules (id) on delete cascade,
  term text not null,
  definition text not null,
  sequence integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index terminology_module_idx on public.terminology (module_id, sequence);

create trigger terminology_set_updated_at
  before update on public.terminology
  for each row execute function public.set_updated_at();

create table public.revision_cards (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules (id) on delete cascade,
  front text not null,
  back text not null,
  sequence integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index revision_cards_module_idx on public.revision_cards (module_id, sequence);

create trigger revision_cards_set_updated_at
  before update on public.revision_cards
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- quizzes
-- ---------------------------------------------------------------------------

create table public.quizzes (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules (id) on delete cascade,
  title text not null default 'Knowledge check',
  -- Null means "use app_settings.quiz_pass_mark". Storing null rather than
  -- copying 80 in means changing the organisation-wide pass mark actually
  -- changes every quiz, instead of only new ones.
  pass_mark integer check (pass_mark is null or pass_mark between 1 and 100),
  randomise_questions boolean not null default true,
  randomise_answers boolean not null default true,
  is_final boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id)
);

comment on column public.quizzes.pass_mark is
  'Per-quiz override. Null falls back to app_settings.quiz_pass_mark (80), so the organisation-wide default stays configurable in one place.';

comment on column public.quizzes.is_final is
  'Marks the Day 28 final knowledge assessment, which gates the readiness decision in Phase 5.';

create trigger quizzes_set_updated_at
  before update on public.quizzes
  for each row execute function public.set_updated_at();

create table public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes (id) on delete cascade,
  question_text text not null check (length(trim(question_text)) > 0),
  question_type text not null default 'mcq' check (question_type in ('mcq', 'scenario')),
  -- Shown only once the attempt has been passed. Never sent to an advisor who
  -- has failed, because the retry would become a memory test.
  explanation text,
  sequence integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index quiz_questions_quiz_idx on public.quiz_questions (quiz_id, sequence);

create trigger quiz_questions_set_updated_at
  before update on public.quiz_questions
  for each row execute function public.set_updated_at();

create table public.quiz_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.quiz_questions (id) on delete cascade,
  option_text text not null check (length(trim(option_text)) > 0),
  is_correct boolean not null default false,
  sequence integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.quiz_options is
  'SECURITY: is_correct is protected by a column-level privilege, not by hiding it in the interface. Migration 0008 revokes table-wide SELECT from the authenticated role and re-grants only the safe columns, so "select is_correct from quiz_options" is refused by PostgreSQL itself even on a row the advisor is otherwise allowed to read.';

create index quiz_options_question_idx on public.quiz_options (question_id, sequence);

create trigger quiz_options_set_updated_at
  before update on public.quiz_options
  for each row execute function public.set_updated_at();

-- Every question needs at least one correct option, or an advisor could never
-- pass. Enforced as a deferred trigger so options can be inserted one at a time.
create or replace function public.assert_question_has_correct_option()
returns trigger
language plpgsql
as $$
declare
  affected_question uuid := coalesce(new.question_id, old.question_id);
  correct_count integer;
begin
  -- The question may have been deleted outright, in which case there is nothing
  -- to validate.
  if not exists (select 1 from public.quiz_questions where id = affected_question) then
    return null;
  end if;

  select count(*) into correct_count
  from public.quiz_options
  where question_id = affected_question and is_correct;

  if correct_count = 0 then
    raise exception 'Question % has no correct option — advisors could never pass this quiz',
      affected_question;
  end if;

  return null;
end;
$$;

create constraint trigger quiz_options_require_a_correct_answer
  after insert or update or delete on public.quiz_options
  deferrable initially deferred
  for each row execute function public.assert_question_has_correct_option();

-- ---------------------------------------------------------------------------
-- quiz_questions_for_attempt — what an advisor is allowed to see
-- ---------------------------------------------------------------------------
--
-- The whole point of this view is the column that is absent.
--
-- Two independent mechanisms protect is_correct, and they fail in different
-- ways, which is deliberate:
--
--   1. Column privilege (migration 0008). The authenticated role is granted
--      SELECT on the safe columns only, so asking for is_correct is refused by
--      PostgreSQL before RLS is even consulted.
--   2. This view, which simply never selects the column.
--
-- security_invoker = true means the caller's own RLS still decides which *rows*
-- they see, so the view widens the available columns without widening row
-- access. An advisor querying it gets exactly the options for questions on a
-- published module of a day they have unlocked.

create view public.quiz_questions_for_attempt
with (security_invoker = true)
as
select
  q.id            as question_id,
  q.quiz_id,
  q.question_text,
  q.question_type,
  q.sequence      as question_sequence,
  o.id            as option_id,
  o.option_text,
  o.sequence      as option_sequence
from public.quiz_questions q
join public.quiz_options o on o.question_id = q.id;

comment on view public.quiz_questions_for_attempt is
  'Questions and options with is_correct and explanation deliberately omitted. This is the only route by which an advisor reads quiz content.';
