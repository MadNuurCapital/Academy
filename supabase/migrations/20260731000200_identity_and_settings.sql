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
