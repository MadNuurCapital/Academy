-- =========================================================================
-- ATLAS Academy — update 1: enrolment actions
--
-- FOR AN EXISTING PROJECT. Paste into the Supabase SQL Editor and Run.
--
-- A brand new project does not need this — bundles 01 and 02 already contain
-- it. Applying it twice is harmless; the file drops and recreates rather than
-- assuming what is there.
--
-- Source: supabase/migrations/20260802000100_enrolment_actions.sql
-- This file is generated. See scripts/build-browser-sql.sh
-- =========================================================================

-- ATLAS Academy — pause, resume and withdraw an enrolment
--
-- The schema has supported `paused` and `withdrawn` since the first migration,
-- and enrolment_pauses has been sitting there unused. Nothing could ever reach
-- them: a manager whose advisor went on leave had no way to say so.
--
-- These are functions rather than direct table writes for one reason that
-- matters and one that is merely tidy.
--
-- The one that matters: pausing is TWO writes — the enrolment's status and a
-- row in enrolment_pauses recording the period. If the first succeeds and the
-- second does not, the programme reads as paused with no pause period, and
-- every drift calculation afterwards is quietly wrong, because
-- countPausedWorkingDays has nothing to subtract. A function makes the pair
-- atomic.
--
-- The one that is tidy: an audit entry, written in the same transaction, in the
-- same shape as manager_unlock_day.

-- Dropped rather than replaced. `create or replace function` refuses to change
-- the NAME of an input parameter — "cannot change name of input parameter" —
-- so a file that only replaces is not re-runnable across a rename, which is
-- exactly what happened while writing this one. Dropping first makes it safe to
-- apply over any earlier version.
drop function if exists public.pause_enrolment(uuid, text, date);
drop function if exists public.resume_enrolment(uuid, date);
drop function if exists public.withdraw_enrolment(uuid, text);

-- ---------------------------------------------------------------------------
-- pause_enrolment
-- ---------------------------------------------------------------------------

create or replace function public.pause_enrolment(
  target_enrolment_id uuid,
  reason text,
  paused_from date default current_date
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status public.enrolment_status;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may pause an enrolment';
  end if;

  if reason is null or length(trim(reason)) = 0 then
    raise exception 'A reason is required when pausing an enrolment';
  end if;

  select status into previous_status
  from public.enrolments where id = target_enrolment_id;

  if previous_status is null then
    raise exception 'That enrolment does not exist';
  end if;

  if previous_status not in ('active', 'extended') then
    raise exception 'Only a live enrolment can be paused. This one is %', previous_status;
  end if;

  -- An open pause already existing would mean the two records disagree.
  if exists (
    select 1 from public.enrolment_pauses
    where enrolment_id = target_enrolment_id and resumed_on is null
  ) then
    raise exception 'This enrolment already has an open pause';
  end if;

  update public.enrolments set status = 'paused' where id = target_enrolment_id;

  insert into public.enrolment_pauses (enrolment_id, paused_from, reason, actioned_by)
  values (target_enrolment_id, paused_from, trim(reason), auth.uid());

  insert into public.audit_log (actor_id, entity_type, entity_id, action, reason, before, after)
  values (
    auth.uid(), 'enrolment', target_enrolment_id, 'pause_enrolment', trim(reason),
    jsonb_build_object('status', previous_status),
    jsonb_build_object('status', 'paused', 'paused_from', paused_from)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- resume_enrolment
-- ---------------------------------------------------------------------------

-- The parameter is `resume_date`, not `resumed_on`. A parameter sharing a name
-- with a column it is compared against is ambiguous inside PL/pgSQL, and the
-- failure is at run time rather than at definition time — this function was
-- written with the collision and only the first test caught it. Renaming
-- removes the hazard instead of qualifying every reference and hoping the next
-- edit remembers to.
create or replace function public.resume_enrolment(
  target_enrolment_id uuid,
  resume_date date default current_date
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status public.enrolment_status;
  open_pause_id uuid;
  open_pause_from date;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may resume an enrolment';
  end if;

  select status into previous_status
  from public.enrolments where id = target_enrolment_id;

  if previous_status is null then
    raise exception 'That enrolment does not exist';
  end if;

  if previous_status <> 'paused' then
    raise exception 'Only a paused enrolment can be resumed. This one is %', previous_status;
  end if;

  select id, paused_from into open_pause_id, open_pause_from
  from public.enrolment_pauses
  where enrolment_id = target_enrolment_id and resumed_on is null
  order by paused_from desc
  limit 1;

  if open_pause_id is null then
    raise exception 'This enrolment is paused but has no open pause period to close';
  end if;

  if resume_date < open_pause_from then
    raise exception 'A programme cannot resume before it was paused';
  end if;

  update public.enrolment_pauses
  set resumed_on = resume_date
  where id = open_pause_id;

  update public.enrolments set status = 'active' where id = target_enrolment_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, before, after)
  values (
    auth.uid(), 'enrolment', target_enrolment_id, 'resume_enrolment',
    jsonb_build_object('status', 'paused', 'paused_from', open_pause_from),
    jsonb_build_object('status', 'active', 'resumed_on', resume_date)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- withdraw_enrolment
--
-- Ends the programme without completing it. Nothing is deleted: the days,
-- attendance, scores and any readiness decision stay exactly where they are,
-- because a withdrawal is part of someone's record rather than an erasure of
-- it. Re-enrolling later is a new enrolment, started from the Enrol screen.
-- ---------------------------------------------------------------------------

create or replace function public.withdraw_enrolment(
  target_enrolment_id uuid,
  reason text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status public.enrolment_status;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may withdraw an enrolment';
  end if;

  if reason is null or length(trim(reason)) = 0 then
    raise exception 'A reason is required when withdrawing an enrolment';
  end if;

  select status into previous_status
  from public.enrolments where id = target_enrolment_id;

  if previous_status is null then
    raise exception 'That enrolment does not exist';
  end if;

  if previous_status in ('completed', 'withdrawn') then
    raise exception 'That enrolment has already ended. It is %', previous_status;
  end if;

  -- Close any open pause, so the record does not keep a period that never ended.
  update public.enrolment_pauses
  set resumed_on = current_date
  where enrolment_id = target_enrolment_id and resumed_on is null;

  update public.enrolments set status = 'withdrawn' where id = target_enrolment_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, reason, before, after)
  values (
    auth.uid(), 'enrolment', target_enrolment_id, 'withdraw_enrolment', trim(reason),
    jsonb_build_object('status', previous_status),
    jsonb_build_object('status', 'withdrawn')
  );
end;
$$;

revoke all on function public.pause_enrolment(uuid, text, date) from public;
revoke all on function public.resume_enrolment(uuid, date) from public;
revoke all on function public.withdraw_enrolment(uuid, text) from public;
grant execute on function public.pause_enrolment(uuid, text, date) to authenticated;
grant execute on function public.resume_enrolment(uuid, date) to authenticated;
grant execute on function public.withdraw_enrolment(uuid, text) to authenticated;
