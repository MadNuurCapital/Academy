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
