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
