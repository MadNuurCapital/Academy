-- ATLAS Academy — 0010 · Practical development
--
-- Scripts, concept presentations, rubrics, in-person practical assessment,
-- coaching and joint fieldwork.
--
-- Two decisions from the requirements shape this file and are worth stating
-- before the tables:
--
--   1. PRACTICALS ARE ASSESSED IN PERSON. The system records a rubric score and
--      written feedback, and nothing else. There are no audio, video or file
--      uploads anywhere here. The trade-off was accepted knowingly: there is no
--      recording to re-watch at Day 30, so the rubric captured at the time is
--      the record.
--
--   2. FIELDWORK COLLECTS NO CLIENT DATA. There is no column for a client's
--      name, contact details or identity — only the appointment *category*.
--      The absence of the field is the control; a policy saying "do not enter
--      client names" would be obeyed unevenly.

create type public.assessment_status as enum ('pending', 'scored', 'retry_required');
create type public.coaching_status as enum ('scheduled', 'completed', 'cancelled');
create type public.action_status as enum ('open', 'complete', 'waived');
create type public.advisor_fieldwork_role as enum (
  'observe', 'assist', 'present_section', 'lead_supervised'
);

-- ---------------------------------------------------------------------------
-- scripts
-- ---------------------------------------------------------------------------

create table public.scripts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  situation text not null,
  objective text not null,
  wording text not null,
  talking_points jsonb not null default '[]'::jsonb,
  variations jsonb not null default '[]'::jsonb,
  common_mistakes jsonb not null default '[]'::jsonb,
  compliance_note text,
  sequence integer not null default 1,
  version integer not null default 1,
  status public.content_status not null default 'draft',
  owner_id uuid references public.profiles (id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.scripts is
  'Approved wording for the six launch conversations. Advisors are taught the structure and purpose; reading one aloud verbatim is explicitly not the goal.';

create index scripts_status_idx on public.scripts (status, sequence);

create trigger scripts_set_updated_at
  before update on public.scripts
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- concept_presentations
-- ---------------------------------------------------------------------------

create table public.concept_presentations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  purpose text not null,
  suitable_situations text,
  when_not_to_use text,
  -- Original artwork authored for ATLAS. Nothing here reproduces a copyrighted
  -- diagram from another organisation's training material.
  diagram_svg text,
  steps jsonb not null default '[]'::jsonb,
  discovery_questions jsonb not null default '[]'::jsonb,
  transition text,
  common_mistakes jsonb not null default '[]'::jsonb,
  compliance_note text,
  is_required boolean not null default true,
  sequence integer not null default 1,
  version integer not null default 1,
  status public.content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.concept_presentations.is_required is
  'Four Pillars and Family Income Ladder are required. Life Journey Timeline and Education Funding Timeline are optional and never block completion.';

create trigger concept_presentations_set_updated_at
  before update on public.concept_presentations
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- rubrics
-- ---------------------------------------------------------------------------

create table public.rubrics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  scope text not null default 'general',
  description text,
  pass_mark_pct integer not null default 70 check (pass_mark_pct between 1 and 100),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger rubrics_set_updated_at
  before update on public.rubrics
  for each row execute function public.set_updated_at();

create table public.rubric_criteria (
  id uuid primary key default gen_random_uuid(),
  rubric_id uuid not null references public.rubrics (id) on delete cascade,
  name text not null,
  description text,
  max_score integer not null default 5 check (max_score > 0),
  sequence integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index rubric_criteria_rubric_idx on public.rubric_criteria (rubric_id, sequence);

create trigger rubric_criteria_set_updated_at
  before update on public.rubric_criteria
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- practical_assessments
-- ---------------------------------------------------------------------------

create table public.practical_assessments (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  module_id uuid references public.modules (id) on delete set null,
  rubric_id uuid not null references public.rubrics (id),
  title text not null,
  status public.assessment_status not null default 'pending',
  assessed_by uuid references public.profiles (id) on delete set null,
  assessed_at timestamptz,
  total_score integer,
  max_score integer,
  passed boolean,
  feedback text,
  is_final boolean not null default false,
  advisor_acknowledged_at timestamptz,
  attempt_no integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.practical_assessments is
  'Conducted face to face. The system holds the rubric score and written feedback only — no recording exists to review later, so what is captured here at the time is the whole record.';

comment on column public.practical_assessments.is_final is
  'Marks the Day 29 final practical assessment, which gates the readiness decision.';

create index practical_assessments_enrolment_idx on public.practical_assessments (enrolment_id, status);
create index practical_assessments_pending_idx on public.practical_assessments (status) where status = 'pending';

create trigger practical_assessments_set_updated_at
  before update on public.practical_assessments
  for each row execute function public.set_updated_at();

create table public.practical_scores (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.practical_assessments (id) on delete cascade,
  criterion_id uuid not null references public.rubric_criteria (id) on delete cascade,
  score integer not null check (score >= 0),
  comment text,
  created_at timestamptz not null default now(),
  unique (assessment_id, criterion_id)
);

-- ---------------------------------------------------------------------------
-- concept_attempts
-- ---------------------------------------------------------------------------

create table public.concept_attempts (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  concept_id uuid not null references public.concept_presentations (id) on delete cascade,
  attempt_no integer not null default 1,
  passed boolean not null default false,
  assessed_by uuid references public.profiles (id) on delete set null,
  assessed_at timestamptz not null default now(),
  feedback text,
  created_at timestamptz not null default now()
);

create index concept_attempts_enrolment_idx on public.concept_attempts (enrolment_id, concept_id);

-- ---------------------------------------------------------------------------
-- coaching_sessions
-- ---------------------------------------------------------------------------

create table public.coaching_sessions (
  id uuid primary key default gen_random_uuid(),
  advisor_id uuid not null references public.profiles (id) on delete cascade,
  manager_id uuid not null references public.profiles (id) on delete cascade,
  scheduled_at timestamptz not null,
  topic text not null,
  reason text,
  preparation text,
  current_challenge text,
  observed_behaviour text,
  strengths text,
  improvement_areas text,
  supporting_evidence text,
  follow_up_date date,
  status public.coaching_status not null default 'scheduled',
  outcome text,
  advisor_acknowledged_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.coaching_sessions is
  'Individual coaching, conducted by managers. Visible only to the advisor concerned, managers and administrators — never broadcast to other advisors.';

create index coaching_sessions_advisor_idx on public.coaching_sessions (advisor_id, scheduled_at desc);
create index coaching_sessions_upcoming_idx on public.coaching_sessions (scheduled_at)
  where status = 'scheduled';

create trigger coaching_sessions_set_updated_at
  before update on public.coaching_sessions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- coaching_private_notes — candid staff observations
-- ---------------------------------------------------------------------------
--
-- A SEPARATE TABLE rather than a column on coaching_sessions, and the reason is
-- worth recording.
--
-- The first attempt made this a private_notes column protected by a column
-- privilege, mirroring quiz_options.is_correct. That failed in testing for a
-- reason the quiz case does not have: managers hold the `authenticated` role
-- too, so revoking the column from `authenticated` blocked the very people who
-- need to read it. Column privileges cannot distinguish between two roles that
-- are both `authenticated` and differ only by an RLS predicate.
--
-- A separate table is also strictly more robust. RLS is not affected by table
-- grants, so a stray `grant select on all tables in schema public` — which
-- would silently defeat a column privilege — leaves this protection intact.
--
-- Managers need somewhere to write candidly ("struggles under pressure",
-- "attitude concern"). Such a note becoming visible to its subject would be
-- worse than never having written it.

create table public.coaching_private_notes (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.coaching_sessions (id) on delete cascade,
  advisor_id uuid not null references public.profiles (id) on delete cascade,
  author_id uuid references public.profiles (id) on delete set null,
  note text not null check (length(trim(note)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.coaching_private_notes is
  'Staff-only observations. Advisors have NO policy on this table whatsoever, so deny-by-default returns nothing for them. advisor_id is denormalised so a manager can retrieve everything written about one advisor without joining through sessions.';

create index coaching_private_notes_session_idx on public.coaching_private_notes (session_id);
create index coaching_private_notes_advisor_idx on public.coaching_private_notes (advisor_id, created_at desc);

create trigger coaching_private_notes_set_updated_at
  before update on public.coaching_private_notes
  for each row execute function public.set_updated_at();

create table public.coaching_actions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.coaching_sessions (id) on delete cascade,
  description text not null check (length(trim(description)) > 0),
  due_date date,
  is_required boolean not null default true,
  status public.action_status not null default 'open',
  completed_at timestamptz,
  completed_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.coaching_actions.is_required is
  'Outstanding required actions surface as a blocker on the readiness review. Optional ones are tracked but never block.';

create index coaching_actions_session_idx on public.coaching_actions (session_id);
create index coaching_actions_open_idx on public.coaching_actions (status) where status = 'open';

create trigger coaching_actions_set_updated_at
  before update on public.coaching_actions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- fieldwork_records
-- ---------------------------------------------------------------------------

create table public.fieldwork_records (
  id uuid primary key default gen_random_uuid(),
  advisor_id uuid not null references public.profiles (id) on delete cascade,
  manager_id uuid not null references public.profiles (id) on delete cascade,
  session_date date not null,
  -- Category only. There is deliberately no column for who the client was.
  appointment_category text not null,
  is_simulated boolean not null default false,
  advisor_role public.advisor_fieldwork_role not null,
  skills_observed jsonb not null default '[]'::jsonb,
  concept_presented text,
  product_category text,
  strengths text,
  improvement_areas text,
  manager_comments text,
  advisor_reflection text,
  follow_up_action text,
  follow_up_due date,
  rating integer check (rating is null or rating between 1 and 5),
  readiness_recommendation text,
  next_requirement text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.fieldwork_records is
  'Joint fieldwork. NO CLIENT PERSONAL INFORMATION is collected — there is no column for it. Only the appointment category is recorded.';

comment on column public.fieldwork_records.is_simulated is
  'An approved simulation counts towards the requirement. Real client appointments cannot be guaranteed within 30 days for a brand-new advisor, and nobody should be held back by circumstances outside their control.';

create index fieldwork_records_advisor_idx on public.fieldwork_records (advisor_id, session_date desc);

create trigger fieldwork_records_set_updated_at
  before update on public.fieldwork_records
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- A view advisors use, which cannot expose private notes
-- ---------------------------------------------------------------------------

-- Private notes live in their own table, so coaching_sessions itself carries
-- nothing an advisor may not see and needs no view to filter it. The comment
-- below exists so that anyone adding a candid field later puts it in the right
-- place.

comment on table public.coaching_sessions is
  'Individual coaching, conducted by managers. Visible to the advisor concerned, managers and administrators — never broadcast to other advisors. EVERY COLUMN HERE IS VISIBLE TO THE ADVISOR: anything candid belongs in coaching_private_notes.';
