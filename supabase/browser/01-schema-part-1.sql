-- =========================================================================
-- ATLAS Academy — Schema, part 1 of 2
--
-- BUNDLE 1 OF 6. Paste this whole file into the Supabase SQL Editor
-- and press Run. Run the bundles in numeric order; each one depends on the
-- ones before it.
--
-- This file is generated. Do not edit it by hand — edit the source files
-- listed below and regenerate with scripts/build-browser-sql.sh
--
-- Source files, concatenated in this order:
--   supabase/migrations/20260731000100_extensions_and_enums.sql
--   supabase/migrations/20260731000200_identity_and_settings.sql
--   supabase/migrations/20260731000300_enrolments.sql
--   supabase/migrations/20260731000400_rls.sql
--   supabase/migrations/20260731000500_content.sql
--   supabase/migrations/20260731000600_progress.sql
--   supabase/migrations/20260731000700_progression.sql
-- =========================================================================



-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000100_extensions_and_enums.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0001 · Extensions, enums and shared triggers
--
-- Foundations every later migration depends on. Enums are used instead of text
-- + check constraints so that invalid states are impossible at the database
-- level, not merely discouraged in the UI.

create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

-- Three roles only. The Coach role was deliberately removed during
-- requirements: managers do the coaching, scoring, fieldwork and readiness
-- decisions. A user may hold several roles (see public.user_roles).
create type public.app_role as enum ('advisor', 'manager', 'admin');

create type public.profile_status as enum ('active', 'inactive');

-- Advisors run on individual rolling starts — there are no cohorts.
create type public.enrolment_status as enum (
  'active',
  'paused',
  'completed',
  'extended',
  'withdrawn'
);

-- A programme day unlocks sequentially: it opens when the previous day's
-- required modules are complete and its quizzes passed. There is no date gate,
-- so an advisor may work ahead without limit.
create type public.enrolment_day_status as enum ('locked', 'unlocked', 'complete');

-- Attendance is manager-recorded and deliberately minimal. No medical leave,
-- approved leave or off-day statuses; no self-check-in, QR, GPS or device
-- verification.
create type public.attendance_status as enum ('present', 'late', 'absent');

-- The four permitted Day 30 outcomes. "Certified Independent Advisor" is
-- intentionally absent — completing the programme means ready for *supervised*
-- fieldwork.
create type public.readiness_outcome as enum (
  'ready_for_supervised_fieldwork',
  'ready_with_development_actions',
  'additional_training_required',
  'programme_extended'
);

create type public.content_status as enum (
  'draft',
  'pending_review',
  'approved',
  'published',
  'archived'
);

-- ---------------------------------------------------------------------------
-- Shared trigger: keep updated_at honest
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.set_updated_at is
  'Trigger function applied to every table carrying an updated_at column.';


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000200_identity_and_settings.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0002 · Identity, roles and configuration
--
-- Roles live in their own table rather than a column on the profile, because a
-- person may hold several (a Manager who is also enrolled as an Advisor, for
-- instance). Thresholds live in app_settings rather than in code, so that an
-- administrator can change the pass mark or the attendance target without a
-- deployment.

-- ---------------------------------------------------------------------------
-- profiles — one row per authenticated user
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null check (length(trim(full_name)) > 0),
  email text not null,
  phone text,
  status public.profile_status not null default 'active',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'Application-level user record. Authentication itself lives in auth.users.';

create index profiles_status_idx on public.profiles (status);
create unique index profiles_email_key on public.profiles (lower(email));

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- A profile row is created automatically whenever Supabase Auth creates a user,
-- so there is never an authenticated session without a matching profile.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- user_roles — a user may hold more than one
-- ---------------------------------------------------------------------------

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.app_role not null,
  granted_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);

comment on table public.user_roles is
  'Role grants. Separate from profiles so one person can be both Manager and Advisor.';

create index user_roles_user_id_idx on public.user_roles (user_id);
create index user_roles_role_idx on public.user_roles (role);

-- ---------------------------------------------------------------------------
-- app_settings — every configurable threshold
-- ---------------------------------------------------------------------------

create table public.app_settings (
  key text primary key,
  value jsonb not null,
  description text not null,
  updated_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.app_settings is
  'Runtime configuration. Nothing that belongs here may be hard-coded in the frontend.';

create trigger app_settings_set_updated_at
  before update on public.app_settings
  for each row execute function public.set_updated_at();

insert into public.app_settings (key, value, description) values
  ('programme_length_days', '30'::jsonb,
   'Number of working days in the programme.'),
  ('working_weekdays', '[1,2,3,4,5]'::jsonb,
   'ISO weekday numbers counted as programme days. 1 = Monday, 7 = Sunday.'),
  ('office_start_time', '"10:00"'::jsonb,
   'Expected office arrival time (24h, Asia/Singapore). Not yet finalised by the business.'),
  ('late_after_time', '"10:15"'::jsonb,
   'An advisor arriving after this time is marked Late.'),
  ('quiz_pass_mark', '80'::jsonb,
   'Default percentage required to pass a module quiz.'),
  ('attendance_target_pct', '90'::jsonb,
   'Attendance target. Displayed and reported, but never blocks completion.'),
  ('attendance_blocks_completion', 'false'::jsonb,
   'Whether attendance below target prevents a readiness decision. Business decision: no.'),
  ('drift_on_track_days', '2'::jsonb,
   'Working days of drift from target still counted as On Track.'),
  ('drift_attention_days', '5'::jsonb,
   'Drift above this many working days is Behind Schedule; at or below is Attention Needed.'),
  ('required_concept_presentations', '2'::jsonb,
   'Concept presentations that must be passed before a readiness decision.'),
  ('required_fieldwork_sessions', '1'::jsonb,
   'Joint fieldwork sessions required. An approved simulation counts.'),
  ('final_assessments_block_completion', 'true'::jsonb,
   'Final knowledge and practical assessments must be passed. A manager may override with a reason.');

-- ---------------------------------------------------------------------------
-- public_holidays — Singapore, admin-maintained
-- ---------------------------------------------------------------------------

create table public.public_holidays (
  id uuid primary key default gen_random_uuid(),
  holiday_date date not null unique,
  name text not null,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.public_holidays is
  'Dates excluded from the working-day count. Maintained by an administrator, not hard-coded.';

create index public_holidays_date_idx on public.public_holidays (holiday_date);

create trigger public_holidays_set_updated_at
  before update on public.public_holidays
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- audit_log — who changed what, and why
-- ---------------------------------------------------------------------------

create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  reason text,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

comment on table public.audit_log is
  'Append-only record of consequential changes: attendance edits, manager overrides, quiz resets, content publishing, readiness decisions.';

create index audit_log_entity_idx on public.audit_log (entity_type, entity_id);
create index audit_log_actor_idx on public.audit_log (actor_id);
create index audit_log_created_at_idx on public.audit_log (created_at desc);

-- ---------------------------------------------------------------------------
-- notifications — in-app only for the MVP
-- ---------------------------------------------------------------------------

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  link text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.notifications is
  'In-app notifications. Email dispatch can be added later without a schema change.';

create index notifications_user_unread_idx
  on public.notifications (user_id, created_at desc)
  where read_at is null;


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000300_enrolments.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0003 · Programme templates and enrolments
--
-- There are no cohorts. Each advisor enrols individually and runs their own
-- 30-working-day clock from their own start date.
--
-- Two dates matter and they behave differently:
--
--   start_date       the advisor's first programme day.
--   target_end_date  computed once at enrolment as 30 working days from the
--                    start, skipping weekends and Singapore public holidays.
--
-- Day *unlocking* is sequential and shifts when an advisor is absent or paused.
-- The target does not move. Reporting the gap between the two is what lets a
-- manager answer "who is behind schedule?" even though nobody can mechanically
-- fall behind.

-- ---------------------------------------------------------------------------
-- programme_templates — the curriculum, versioned
-- ---------------------------------------------------------------------------

create table public.programme_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  version integer not null default 1,
  status public.content_status not null default 'draft',
  is_default boolean not null default false,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.programme_templates is
  'A versioned curriculum. Everyone currently follows the same 30 days, but the table allows the curriculum to be revised without disturbing advisors already enrolled on an earlier version.';

-- At most one default template may be published at a time.
create unique index programme_templates_single_default_idx
  on public.programme_templates (is_default)
  where is_default;

create trigger programme_templates_set_updated_at
  before update on public.programme_templates
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- programme_days — the 30 days of a template
-- ---------------------------------------------------------------------------

create table public.programme_days (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.programme_templates (id) on delete cascade,
  day_number integer not null check (day_number between 1 and 90),
  phase text not null,
  title text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (template_id, day_number)
);

comment on column public.programme_days.day_number is
  'Position in the programme, not a calendar date. Day 1 is the advisor''s first working day, whenever that falls. The upper bound allows for the future Days 31-90 development stage.';

create index programme_days_template_idx on public.programme_days (template_id, day_number);

create trigger programme_days_set_updated_at
  before update on public.programme_days
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- enrolments — one advisor, one run through the programme
-- ---------------------------------------------------------------------------

create table public.enrolments (
  id uuid primary key default gen_random_uuid(),
  advisor_id uuid not null references public.profiles (id) on delete cascade,
  template_id uuid not null references public.programme_templates (id),
  start_date date not null,
  target_end_date date not null,
  current_day integer not null default 1 check (current_day >= 1),
  status public.enrolment_status not null default 'active',
  intake_label text,
  enrolled_by uuid references public.profiles (id) on delete set null,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint enrolments_target_after_start check (target_end_date >= start_date)
);

comment on column public.enrolments.target_end_date is
  'Fixed at enrolment: 30 working days from start_date. Never recalculated when an advisor falls behind — drift against this date is the "behind schedule" signal.';

comment on column public.enrolments.intake_label is
  'Optional grouping for reporting only (for example "July 2026"). Carries no scheduling behaviour — advisors start individually.';

-- An advisor may re-enrol after withdrawing, but may hold only one live run.
create unique index enrolments_one_active_per_advisor_idx
  on public.enrolments (advisor_id)
  where status in ('active', 'paused', 'extended');

create index enrolments_advisor_idx on public.enrolments (advisor_id);
create index enrolments_status_idx on public.enrolments (status);

create trigger enrolments_set_updated_at
  before update on public.enrolments
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- enrolment_pauses — stopped clock periods
-- ---------------------------------------------------------------------------

create table public.enrolment_pauses (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  paused_from date not null,
  resumed_on date,
  reason text not null check (length(trim(reason)) > 0),
  actioned_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint enrolment_pauses_resume_after_pause
    check (resumed_on is null or resumed_on >= paused_from)
);

comment on table public.enrolment_pauses is
  'Working days falling inside a pause are excluded from drift. An open pause (resumed_on is null) means the advisor is currently paused.';

create index enrolment_pauses_enrolment_idx on public.enrolment_pauses (enrolment_id);

create unique index enrolment_pauses_one_open_idx
  on public.enrolment_pauses (enrolment_id)
  where resumed_on is null;

create trigger enrolment_pauses_set_updated_at
  before update on public.enrolment_pauses
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- enrolment_days — per-advisor progress through the roadmap
-- ---------------------------------------------------------------------------

create table public.enrolment_days (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  programme_day_id uuid not null references public.programme_days (id) on delete cascade,
  day_number integer not null,
  status public.enrolment_day_status not null default 'locked',
  unlocked_at timestamptz,
  completed_at timestamptz,
  unlocked_by_override boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (enrolment_id, day_number)
);

comment on column public.enrolment_days.unlocked_by_override is
  'True when a manager force-unlocked this day rather than the advisor earning it. The reason is recorded in audit_log.';

create index enrolment_days_enrolment_idx on public.enrolment_days (enrolment_id, day_number);
create index enrolment_days_status_idx on public.enrolment_days (enrolment_id, status);

create trigger enrolment_days_set_updated_at
  before update on public.enrolment_days
  for each row execute function public.set_updated_at();

-- Day 1 is unlocked on enrolment; every later day starts locked and is opened
-- by completing its predecessor.
create or replace function public.seed_enrolment_days()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.enrolment_days (
    enrolment_id, programme_day_id, day_number, status, unlocked_at
  )
  select
    new.id,
    pd.id,
    pd.day_number,
    case when pd.day_number = 1 then 'unlocked'::public.enrolment_day_status
         else 'locked'::public.enrolment_day_status end,
    case when pd.day_number = 1 then now() else null end
  from public.programme_days pd
  where pd.template_id = new.template_id
  order by pd.day_number;

  return new;
end;
$$;

create trigger enrolments_seed_days
  after insert on public.enrolments
  for each row execute function public.seed_enrolment_days();

comment on function public.seed_enrolment_days is
  'Generates the advisor''s roadmap the moment they are enrolled, so the dashboard has something to show immediately.';


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000400_rls.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0004 · Row Level Security
--
-- This file is the real permission boundary. Every check the frontend performs
-- is a convenience for the user interface; the rules below are what actually
-- stop an advisor reading someone else's record.
--
-- Principles applied throughout:
--
--   * RLS is enabled on every table, with no permissive default. A table with
--     no matching policy returns nothing.
--   * Advisors read only rows that belong to them, and have no write path at
--     all to attendance, scores, completion state or readiness decisions.
--   * Role lookups go through security-definer helpers with a pinned
--     search_path, so a user cannot shadow public.user_roles with a temp table
--     and grant themselves a role.
--   * The service-role key is never used by the browser. Operations needing
--     elevation (creating a user, sending an invite) run in a Netlify Function.

-- ---------------------------------------------------------------------------
-- Helper functions
-- ---------------------------------------------------------------------------

create or replace function public.has_role(check_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role = check_role
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.has_role('admin');
$$;

create or replace function public.is_manager_or_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.has_role('admin') or public.has_role('manager');
$$;

comment on function public.is_manager_or_admin is
  'Managers and admins see every advisor. There is no coach role and no per-advisor assignment boundary.';

-- Owns this enrolment? Used to scope advisor reads without repeating the join.
create or replace function public.owns_enrolment(target_enrolment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.enrolments e
    where e.id = target_enrolment_id
      and e.advisor_id = auth.uid()
  );
$$;

revoke execute on function public.has_role(public.app_role) from public;
grant execute on function public.has_role(public.app_role) to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_manager_or_admin() to authenticated;
grant execute on function public.owns_enrolment(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere
-- ---------------------------------------------------------------------------

alter table public.profiles             enable row level security;
alter table public.user_roles           enable row level security;
alter table public.app_settings         enable row level security;
alter table public.public_holidays      enable row level security;
alter table public.audit_log            enable row level security;
alter table public.notifications        enable row level security;
alter table public.programme_templates  enable row level security;
alter table public.programme_days       enable row level security;
alter table public.enrolments           enable row level security;
alter table public.enrolment_pauses     enable row level security;
alter table public.enrolment_days       enable row level security;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create policy "profiles: read own"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

create policy "profiles: managers read all"
  on public.profiles for select
  to authenticated
  using (public.is_manager_or_admin());

-- An advisor may maintain their own contact details, but not their status.
-- Status changes are an administrative act and are blocked by the WITH CHECK.
create policy "profiles: update own contact details"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and status = (select p.status from public.profiles p where p.id = auth.uid())
  );

create policy "profiles: admins update any"
  on public.profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- No INSERT policy: profiles are created by the on_auth_user_created trigger.
-- No DELETE policy: users are deactivated, never deleted, so history survives.

-- ---------------------------------------------------------------------------
-- user_roles — admin-managed only
-- ---------------------------------------------------------------------------

create policy "user_roles: read own"
  on public.user_roles for select
  to authenticated
  using (user_id = auth.uid());

create policy "user_roles: managers read all"
  on public.user_roles for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "user_roles: admins manage"
  on public.user_roles for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- app_settings — readable by all, writable by admins
-- ---------------------------------------------------------------------------

-- Advisors need the pass mark and attendance target to render their dashboard,
-- so reads are open to any authenticated user. Nothing secret lives here.
create policy "app_settings: authenticated read"
  on public.app_settings for select
  to authenticated
  using (true);

create policy "app_settings: admins write"
  on public.app_settings for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- public_holidays — everyone reads, admins maintain
-- ---------------------------------------------------------------------------

create policy "public_holidays: authenticated read"
  on public.public_holidays for select
  to authenticated
  using (true);

create policy "public_holidays: admins write"
  on public.public_holidays for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- audit_log — admins read; nobody updates or deletes
-- ---------------------------------------------------------------------------

create policy "audit_log: admins read"
  on public.audit_log for select
  to authenticated
  using (public.is_admin());

-- Managers write audit entries as a side effect of editing attendance and
-- applying overrides, but may not read the log back or alter it afterwards.
create policy "audit_log: managers append"
  on public.audit_log for insert
  to authenticated
  with check (public.is_manager_or_admin() and actor_id = auth.uid());

-- ---------------------------------------------------------------------------
-- notifications — strictly per-recipient
-- ---------------------------------------------------------------------------

create policy "notifications: read own"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

-- The only field a recipient may change is read_at; the WITH CHECK keeps the
-- row addressed to them.
create policy "notifications: mark own read"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "notifications: managers create"
  on public.notifications for insert
  to authenticated
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- programme_templates and programme_days
-- ---------------------------------------------------------------------------

-- Advisors see published curriculum only. Drafts are invisible until a manager
-- publishes them.
create policy "programme_templates: read published"
  on public.programme_templates for select
  to authenticated
  using (status = 'published');

create policy "programme_templates: managers read all"
  on public.programme_templates for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "programme_templates: managers write"
  on public.programme_templates for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "programme_days: read published templates"
  on public.programme_days for select
  to authenticated
  using (
    exists (
      select 1 from public.programme_templates t
      where t.id = programme_days.template_id
        and t.status = 'published'
    )
  );

create policy "programme_days: managers read all"
  on public.programme_days for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "programme_days: managers write"
  on public.programme_days for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- enrolments — the advisor reads, only managers write
-- ---------------------------------------------------------------------------

create policy "enrolments: advisor reads own"
  on public.enrolments for select
  to authenticated
  using (advisor_id = auth.uid());

create policy "enrolments: managers read all"
  on public.enrolments for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "enrolments: managers write"
  on public.enrolments for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- Deliberately no advisor UPDATE policy. An advisor cannot alter their own
-- current_day, status, target date or completion — not through the UI and not
-- through a direct API call.

-- ---------------------------------------------------------------------------
-- enrolment_pauses
-- ---------------------------------------------------------------------------

create policy "enrolment_pauses: advisor reads own"
  on public.enrolment_pauses for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "enrolment_pauses: managers read all"
  on public.enrolment_pauses for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "enrolment_pauses: managers write"
  on public.enrolment_pauses for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- enrolment_days
-- ---------------------------------------------------------------------------

create policy "enrolment_days: advisor reads own"
  on public.enrolment_days for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "enrolment_days: managers read all"
  on public.enrolment_days for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "enrolment_days: managers write"
  on public.enrolment_days for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- Advisors have no write policy here either. Days are unlocked by completing
-- work, which happens through progress tables added in Phase 2, or by a
-- manager override. An advisor cannot mark their own day complete.


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000500_content.sql
-- ----------------------------------------------------------------------

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


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000600_progress.sql
-- ----------------------------------------------------------------------

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


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000700_progression.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0007 · The progression engine
--
-- Every function here is `security definer` with a pinned search_path. They run
-- with the owner's privileges precisely because the caller must not have those
-- privileges: an advisor may not write their own score, their own module
-- completion, or their own day unlock.
--
-- Each function therefore re-checks the caller's identity itself. Being
-- security definer means RLS is bypassed inside the body, so an authorisation
-- check missed here is an authorisation check missing entirely.
--
-- Progression rules being implemented (all confirmed with the business):
--
--   * Sequential unlock, no date gate. Day N+1 opens the moment Day N is
--     finished, whether that is today or next Tuesday.
--   * A failed quiz blocks the next day. Attempts are unlimited.
--   * Correct answers are revealed only after passing.
--   * Managers may force-unlock with a mandatory reason, recorded in audit_log.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- The organisation-wide pass mark, with a hard fallback if the row is missing.
create or replace function public.default_pass_mark()
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select (value #>> '{}')::integer from public.app_settings where key = 'quiz_pass_mark'),
    80
  );
$$;

-- The enrolment the calling advisor owns, if any.
create or replace function public.my_enrolment_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select e.id
  from public.enrolments e
  where e.advisor_id = auth.uid()
    and e.status in ('active', 'paused', 'extended')
  order by e.created_at desc
  limit 1;
$$;

-- Is the day carrying this module unlocked for this enrolment?
--
-- Used both by RLS policies and by the RPCs below, so there is exactly one
-- definition of "the advisor may see this".
create or replace function public.module_is_available(target_module_id uuid, target_enrolment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.modules m
    join public.programme_days pd on pd.id = m.programme_day_id
    join public.enrolment_days ed
      on ed.programme_day_id = pd.id
     and ed.enrolment_id = target_enrolment_id
    where m.id = target_module_id
      and m.status = 'published'
      and ed.status in ('unlocked', 'complete')
  );
$$;

-- ---------------------------------------------------------------------------
-- evaluate_module_completion
-- ---------------------------------------------------------------------------
--
-- A module is complete when every lesson has been read and, if it has a quiz,
-- that quiz has been passed. Called after a lesson is marked read and after a
-- quiz is submitted.

create or replace function public.evaluate_module_completion(
  target_enrolment_id uuid,
  target_module_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  total_lessons integer;
  read_lessons integer;
  quiz_id_for_module uuid;
  quiz_passed boolean := true;
  is_complete boolean;
begin
  select count(*) into total_lessons
  from public.lessons where module_id = target_module_id;

  select count(*) into read_lessons
  from public.lesson_progress lp
  join public.lessons l on l.id = lp.lesson_id
  where l.module_id = target_module_id
    and lp.enrolment_id = target_enrolment_id;

  select id into quiz_id_for_module
  from public.quizzes where module_id = target_module_id;

  if quiz_id_for_module is not null then
    quiz_passed := exists (
      select 1 from public.quiz_attempts
      where enrolment_id = target_enrolment_id
        and quiz_id = quiz_id_for_module
        and passed
    );
  end if;

  is_complete := (read_lessons >= total_lessons) and quiz_passed;

  insert into public.module_progress (enrolment_id, module_id, status, completed_at)
  values (
    target_enrolment_id,
    target_module_id,
    case
      when is_complete then 'complete'::public.module_progress_status
      when read_lessons > 0 then 'in_progress'::public.module_progress_status
      else 'not_started'::public.module_progress_status
    end,
    case when is_complete then now() else null end
  )
  on conflict (enrolment_id, module_id) do update
    set status = excluded.status,
        -- Keep the original completion timestamp if the module was already
        -- finished; re-reading a lesson should not reset it.
        completed_at = coalesce(public.module_progress.completed_at, excluded.completed_at);

  return is_complete;
end;
$$;

-- ---------------------------------------------------------------------------
-- evaluate_day_completion
-- ---------------------------------------------------------------------------
--
-- A day is complete when every *required* published module on it is complete.
-- Optional modules are tracked but never block. Completing a day unlocks the
-- next one and advances enrolments.current_day.

create or replace function public.evaluate_day_completion(
  target_enrolment_id uuid,
  target_day_number integer
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  required_modules integer;
  completed_modules integer;
  day_is_complete boolean;
  next_day_number integer := target_day_number + 1;
  programme_length integer;
begin
  select count(*) into required_modules
  from public.modules m
  join public.programme_days pd on pd.id = m.programme_day_id
  join public.enrolment_days ed on ed.programme_day_id = pd.id
  where ed.enrolment_id = target_enrolment_id
    and ed.day_number = target_day_number
    and m.is_required
    and m.status = 'published';

  select count(*) into completed_modules
  from public.modules m
  join public.programme_days pd on pd.id = m.programme_day_id
  join public.enrolment_days ed on ed.programme_day_id = pd.id
  join public.module_progress mp
    on mp.module_id = m.id and mp.enrolment_id = target_enrolment_id
  where ed.enrolment_id = target_enrolment_id
    and ed.day_number = target_day_number
    and m.is_required
    and m.status = 'published'
    and mp.status = 'complete';

  -- A day carrying no published required modules is not "complete" — it is
  -- unconfigured. Treating it as complete would let an advisor walk the whole
  -- programme the moment content was missing.
  day_is_complete := required_modules > 0 and completed_modules >= required_modules;

  if not day_is_complete then
    return false;
  end if;

  update public.enrolment_days
  set status = 'complete',
      completed_at = coalesce(completed_at, now())
  where enrolment_id = target_enrolment_id
    and day_number = target_day_number
    and status <> 'complete';

  -- Open the next day. Sequential unlock: no date is consulted, so an advisor
  -- who finishes early simply carries on.
  update public.enrolment_days
  set status = 'unlocked',
      unlocked_at = coalesce(unlocked_at, now())
  where enrolment_id = target_enrolment_id
    and day_number = next_day_number
    and status = 'locked';

  select count(*) into programme_length
  from public.enrolment_days where enrolment_id = target_enrolment_id;

  -- current_day only ever moves forward, so re-evaluating an earlier day after
  -- a manager reset cannot drag an advisor backwards.
  update public.enrolments
  set current_day = greatest(current_day, least(next_day_number, programme_length))
  where id = target_enrolment_id;

  return true;
end;
$$;

-- ---------------------------------------------------------------------------
-- mark_lesson_read
-- ---------------------------------------------------------------------------
--
-- The advisor-facing entry point for lesson progress. Goes through an RPC
-- rather than a direct insert so that module and day evaluation happen in the
-- same transaction — otherwise a client could record the lesson and simply
-- never trigger the re-evaluation.

create or replace function public.mark_lesson_read(target_lesson_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_enrolment_id uuid := public.my_enrolment_id();
  target_module_id uuid;
  v_day_number integer;
  module_complete boolean;
  day_complete boolean;
begin
  if v_enrolment_id is null then
    raise exception 'You are not currently enrolled in a programme';
  end if;

  select m.id, ed.day_number
    into target_module_id, v_day_number
  from public.lessons l
  join public.modules m on m.id = l.module_id
  join public.programme_days pd on pd.id = m.programme_day_id
  join public.enrolment_days ed
    on ed.programme_day_id = pd.id and ed.enrolment_id = v_enrolment_id
  where l.id = target_lesson_id;

  if target_module_id is null then
    raise exception 'Lesson not found';
  end if;

  if not public.module_is_available(target_module_id, v_enrolment_id) then
    raise exception 'That lesson is not available to you yet';
  end if;

  insert into public.lesson_progress (enrolment_id, lesson_id)
  values (v_enrolment_id, target_lesson_id)
  on conflict (enrolment_id, lesson_id) do nothing;

  module_complete := public.evaluate_module_completion(v_enrolment_id, target_module_id);
  day_complete := public.evaluate_day_completion(v_enrolment_id, v_day_number);

  return jsonb_build_object(
    'module_complete', module_complete,
    'day_complete', day_complete
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- start_quiz_attempt
-- ---------------------------------------------------------------------------
--
-- Returns the questions and options in the randomised order the advisor will
-- see them. is_correct is never included in the payload.

create or replace function public.start_quiz_attempt(target_quiz_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_enrolment_id uuid := public.my_enrolment_id();
  target_module_id uuid;
  randomise_q boolean;
  randomise_a boolean;
  next_attempt_no integer;
  attempt_id uuid;
  questions jsonb;
begin
  if v_enrolment_id is null then
    raise exception 'You are not currently enrolled in a programme';
  end if;

  select q.module_id, q.randomise_questions, q.randomise_answers
    into target_module_id, randomise_q, randomise_a
  from public.quizzes q where q.id = target_quiz_id;

  if target_module_id is null then
    raise exception 'Quiz not found';
  end if;

  if not public.module_is_available(target_module_id, v_enrolment_id) then
    raise exception 'That quiz is not available to you yet';
  end if;

  -- Already passed? Re-sitting is pointless and would let an advisor overwrite
  -- a pass with a fail.
  if exists (
    select 1 from public.quiz_attempts qa
    where qa.enrolment_id = v_enrolment_id
      and qa.quiz_id = target_quiz_id
      and qa.passed
  ) then
    raise exception 'You have already passed this quiz';
  end if;

  -- Reuse an abandoned attempt rather than accumulating empty rows when someone
  -- closes the tab and comes back.
  select qa.id into attempt_id
  from public.quiz_attempts qa
  where qa.enrolment_id = v_enrolment_id
    and qa.quiz_id = target_quiz_id
    and qa.submitted_at is null
  order by qa.started_at desc
  limit 1;

  if attempt_id is null then
    select coalesce(max(qa.attempt_no), 0) + 1 into next_attempt_no
    from public.quiz_attempts qa
    where qa.enrolment_id = v_enrolment_id
      and qa.quiz_id = target_quiz_id;

    insert into public.quiz_attempts (enrolment_id, quiz_id, attempt_no)
    values (v_enrolment_id, target_quiz_id, next_attempt_no)
    returning id into attempt_id;
  end if;

  select jsonb_agg(question_payload order by question_payload ->> 'ordering')
    into questions
  from (
    select jsonb_build_object(
             'question_id', qq.id,
             'question_text', qq.question_text,
             'question_type', qq.question_type,
             'ordering', lpad(
               (case when randomise_q
                     then (random() * 1000000)::integer
                     else qq.sequence end)::text, 9, '0'),
             'options', (
               select jsonb_agg(
                        jsonb_build_object('option_id', qo.id, 'option_text', qo.option_text)
                        order by case when randomise_a then random() else qo.sequence end
                      )
               from public.quiz_options qo
               where qo.question_id = qq.id
             )
           ) as question_payload
    from public.quiz_questions qq
    where qq.quiz_id = target_quiz_id
  ) ordered;

  return jsonb_build_object(
    'attempt_id', attempt_id,
    'quiz_id', target_quiz_id,
    'questions', coalesce(questions, '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- submit_quiz_attempt
-- ---------------------------------------------------------------------------
--
-- The only route by which an attempt is scored. quiz_attempts has no advisor
-- UPDATE policy, so a client cannot set passed = true by any other means.
--
-- `answers` is [{"question_id": uuid, "option_id": uuid}, ...].

create or replace function public.submit_quiz_attempt(
  target_attempt_id uuid,
  answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  attempt public.quiz_attempts%rowtype;
  v_enrolment_id uuid := public.my_enrolment_id();
  target_module_id uuid;
  v_day_number integer;
  applied_pass_mark integer;
  total_questions integer;
  correct_answers integer;
  computed_score integer;
  did_pass boolean;
  day_complete boolean;
  review jsonb;
begin
  if v_enrolment_id is null then
    raise exception 'You are not currently enrolled in a programme';
  end if;

  select * into attempt from public.quiz_attempts where id = target_attempt_id;

  if attempt.id is null then
    raise exception 'Attempt not found';
  end if;

  -- The ownership check. Without this, any authenticated user could submit
  -- against anyone else's attempt.
  if attempt.enrolment_id <> v_enrolment_id then
    raise exception 'That attempt does not belong to you';
  end if;

  if attempt.submitted_at is not null then
    raise exception 'That attempt has already been submitted';
  end if;

  select q.module_id, ed.day_number
    into target_module_id, v_day_number
  from public.quizzes q
  join public.modules m on m.id = q.module_id
  join public.programme_days pd on pd.id = m.programme_day_id
  join public.enrolment_days ed
    on ed.programme_day_id = pd.id and ed.enrolment_id = v_enrolment_id
  where q.id = attempt.quiz_id;

  -- Record the submitted choices, grading each against the real answer.
  delete from public.quiz_answers qa where qa.attempt_id = target_attempt_id;

  insert into public.quiz_answers (attempt_id, question_id, option_id, is_correct)
  select
    target_attempt_id,
    (answer ->> 'question_id')::uuid,
    (answer ->> 'option_id')::uuid,
    coalesce(qo.is_correct, false)
  from jsonb_array_elements(answers) as answer
  left join public.quiz_options qo
    on qo.id = (answer ->> 'option_id')::uuid
   and qo.question_id = (answer ->> 'question_id')::uuid
  -- Ignore anything referencing a question outside this quiz, so a crafted
  -- payload cannot pad the score with answers to other quizzes.
  where exists (
    select 1 from public.quiz_questions qq
    where qq.id = (answer ->> 'question_id')::uuid
      and qq.quiz_id = attempt.quiz_id
  );

  select count(*) into total_questions
  from public.quiz_questions where quiz_id = attempt.quiz_id;

  select count(*) into correct_answers
  from public.quiz_answers qa
  where qa.attempt_id = target_attempt_id and qa.is_correct;

  -- Unanswered questions count against the advisor: the denominator is the
  -- number of questions in the quiz, not the number of answers submitted.
  computed_score := case
    when total_questions = 0 then 0
    else floor((correct_answers::numeric / total_questions) * 100)::integer
  end;

  select coalesce(qz.pass_mark, public.default_pass_mark())
    into applied_pass_mark
  from public.quizzes qz where qz.id = attempt.quiz_id;

  did_pass := computed_score >= applied_pass_mark;

  update public.quiz_attempts
  set score = computed_score,
      passed = did_pass,
      pass_mark_applied = applied_pass_mark,
      submitted_at = now()
  where id = target_attempt_id;

  if did_pass then
    perform public.evaluate_module_completion(v_enrolment_id, target_module_id);
    day_complete := public.evaluate_day_completion(v_enrolment_id, v_day_number);
  else
    day_complete := false;
  end if;

  -- Correct answers and explanations are returned ONLY on a pass. After a
  -- failure the retry has to be a test of knowledge, not of memory.
  if did_pass then
    select jsonb_agg(
             jsonb_build_object(
               'question_id', qq.id,
               'question_text', qq.question_text,
               'explanation', qq.explanation,
               'your_option_id', qa.option_id,
               'was_correct', qa.is_correct,
               'correct_option_id', (
                 select qo.id from public.quiz_options qo
                 where qo.question_id = qq.id and qo.is_correct
                 limit 1
               )
             ) order by qq.sequence
           )
      into review
    from public.quiz_questions qq
    left join public.quiz_answers qa
      on qa.question_id = qq.id and qa.attempt_id = target_attempt_id
    where qq.quiz_id = attempt.quiz_id;
  end if;

  return jsonb_build_object(
    'score', computed_score,
    'pass_mark', applied_pass_mark,
    'passed', did_pass,
    'correct_answers', correct_answers,
    'total_questions', total_questions,
    'day_complete', coalesce(day_complete, false),
    'review', coalesce(review, 'null'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- manager_unlock_day — the override
-- ---------------------------------------------------------------------------

create or replace function public.manager_unlock_day(
  target_enrolment_id uuid,
  target_day_number integer,
  reason text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status public.enrolment_day_status;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may unlock a programme day';
  end if;

  -- The reason is not optional. An override with no explanation is exactly the
  -- thing an audit trail exists to prevent.
  if reason is null or length(trim(reason)) = 0 then
    raise exception 'A reason is required when unlocking a programme day';
  end if;

  select status into previous_status
  from public.enrolment_days
  where enrolment_id = target_enrolment_id and day_number = target_day_number;

  if previous_status is null then
    raise exception 'That programme day does not exist for this advisor';
  end if;

  update public.enrolment_days
  set status = 'unlocked',
      unlocked_at = coalesce(unlocked_at, now()),
      unlocked_by_override = true
  where enrolment_id = target_enrolment_id
    and day_number = target_day_number;

  update public.enrolments
  set current_day = greatest(current_day, target_day_number)
  where id = target_enrolment_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, reason, before, after)
  values (
    auth.uid(),
    'enrolment_day',
    target_enrolment_id,
    'manager_unlock_day',
    trim(reason),
    jsonb_build_object('day_number', target_day_number, 'status', previous_status),
    jsonb_build_object('day_number', target_day_number, 'status', 'unlocked')
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- reset_quiz_attempts — manager clears a quiz so an advisor can re-sit
-- ---------------------------------------------------------------------------

create or replace function public.reset_quiz_attempts(
  target_enrolment_id uuid,
  target_quiz_id uuid,
  reason text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may reset a quiz';
  end if;

  if reason is null or length(trim(reason)) = 0 then
    raise exception 'A reason is required when resetting a quiz';
  end if;

  update public.quiz_attempts
  set reset_by = auth.uid(), reset_reason = trim(reason)
  where enrolment_id = target_enrolment_id and quiz_id = target_quiz_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, reason)
  values (auth.uid(), 'quiz', target_quiz_id, 'reset_quiz_attempts', trim(reason));
end;
$$;

-- ---------------------------------------------------------------------------
-- enrol_advisor — creates the enrolment with a correctly computed target date
-- ---------------------------------------------------------------------------
--
-- The working-day arithmetic also exists in TypeScript (src/lib/workingDays.ts)
-- for the interface, but the authoritative target_end_date is computed here so
-- that a client cannot submit a flattering one.

create or replace function public.working_days_from(
  start_date date,
  working_days_to_add integer
)
returns date
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  working_weekdays integer[];
  cursor_date date := start_date;
  remaining integer := working_days_to_add;
  guard integer := 0;
begin
  select coalesce(
    (select array(select jsonb_array_elements_text(value)::integer)
     from public.app_settings where key = 'working_weekdays'),
    array[1, 2, 3, 4, 5]
  ) into working_weekdays;

  -- Advance to the first working day on or after the start date, so enrolling
  -- someone on a Saturday puts their Day 1 on the Monday.
  while guard < 400 and (
    not (extract(isodow from cursor_date)::integer = any(working_weekdays))
    or exists (select 1 from public.public_holidays where holiday_date = cursor_date)
  ) loop
    cursor_date := cursor_date + 1;
    guard := guard + 1;
  end loop;

  while remaining > 0 and guard < 4000 loop
    cursor_date := cursor_date + 1;
    guard := guard + 1;
    if (extract(isodow from cursor_date)::integer = any(working_weekdays))
       and not exists (select 1 from public.public_holidays where holiday_date = cursor_date)
    then
      remaining := remaining - 1;
    end if;
  end loop;

  return cursor_date;
end;
$$;

create or replace function public.enrol_advisor(
  target_advisor_id uuid,
  target_template_id uuid,
  start_date date,
  intake_label text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  programme_length integer;
  first_day date;
  computed_target date;
  new_enrolment_id uuid;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may enrol an advisor';
  end if;

  if not exists (
    select 1 from public.user_roles where user_id = target_advisor_id and role = 'advisor'
  ) then
    raise exception 'That user does not hold the advisor role';
  end if;

  select coalesce(
    (select (value #>> '{}')::integer from public.app_settings where key = 'programme_length_days'),
    30
  ) into programme_length;

  first_day := public.working_days_from(start_date, 0);
  computed_target := public.working_days_from(start_date, programme_length - 1);

  insert into public.enrolments (
    advisor_id, template_id, start_date, target_end_date, intake_label, enrolled_by
  )
  values (
    target_advisor_id, target_template_id, first_day, computed_target, intake_label, auth.uid()
  )
  returning id into new_enrolment_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, after)
  values (
    auth.uid(), 'enrolment', new_enrolment_id, 'enrol_advisor',
    jsonb_build_object(
      'advisor_id', target_advisor_id,
      'start_date', first_day,
      'target_end_date', computed_target
    )
  );

  return new_enrolment_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Execution grants
-- ---------------------------------------------------------------------------
--
-- Default-deny: revoke from public, then grant deliberately. The manager-only
-- functions check the caller's role in their body as well, because an execute
-- grant to `authenticated` covers advisors too.

revoke execute on function public.evaluate_module_completion(uuid, uuid) from public;
revoke execute on function public.evaluate_day_completion(uuid, integer) from public;
revoke execute on function public.working_days_from(date, integer) from public;

grant execute on function public.default_pass_mark() to authenticated;
grant execute on function public.my_enrolment_id() to authenticated;
grant execute on function public.module_is_available(uuid, uuid) to authenticated;
grant execute on function public.mark_lesson_read(uuid) to authenticated;
grant execute on function public.start_quiz_attempt(uuid) to authenticated;
grant execute on function public.submit_quiz_attempt(uuid, jsonb) to authenticated;
grant execute on function public.manager_unlock_day(uuid, integer, text) to authenticated;
grant execute on function public.reset_quiz_attempts(uuid, uuid, text) to authenticated;
grant execute on function public.enrol_advisor(uuid, uuid, date, text) to authenticated;
grant execute on function public.working_days_from(date, integer) to authenticated;
