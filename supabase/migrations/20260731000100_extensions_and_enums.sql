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
