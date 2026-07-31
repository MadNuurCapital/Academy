-- ATLAS Academy — 0009 · Attendance
--
-- Deliberately minimal. The statuses are Present, Late and Absent, and that is
-- the whole vocabulary. Explicitly excluded, by decision rather than oversight:
-- QR codes, GPS, wifi verification, device checks, advisor self-check-in, and
-- the medical-leave / approved-leave / off-day statuses.
--
-- Two design choices shape this file:
--
--   1. Attendance is keyed on a CALENDAR DATE, not a programme day. Advisors
--      start individually, so on any given Tuesday the room contains people on
--      Day 3, Day 17 and Day 28. The manager marks a room, not a cohort.
--
--   2. The whole room saves in ONE call. The business target is that daily
--      attendance takes under a minute; fifteen individual round-trips would
--      not achieve that, however fast each one is.
--
-- Attendance is separate from competency. An advisor can attend every day and
-- still fail, and the percentage never blocks completion — it is reported, and
-- the conversation happens in person.

create type public.makeup_status as enum ('outstanding', 'complete', 'waived');

-- ---------------------------------------------------------------------------
-- attendance_records
-- ---------------------------------------------------------------------------

create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  advisor_id uuid not null references public.profiles (id) on delete cascade,
  attendance_date date not null,
  status public.attendance_status not null,
  remarks text,
  recorded_by uuid references public.profiles (id) on delete set null,
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (advisor_id, attendance_date)
);

comment on table public.attendance_records is
  'One row per advisor per working day. No arrival time is recorded: the business decided Late is simply Late.';

comment on column public.attendance_records.attendance_date is
  'A date, never a timestamp. Attendance on the 3rd of August is the 3rd of August in Singapore regardless of server timezone; a timestamp would let UTC conversion move it to the 2nd.';

create index attendance_records_date_idx on public.attendance_records (attendance_date desc);
create index attendance_records_advisor_idx on public.attendance_records (advisor_id, attendance_date desc);

create trigger attendance_records_set_updated_at
  before update on public.attendance_records
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- attendance_audit
-- ---------------------------------------------------------------------------

create table public.attendance_audit (
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references public.attendance_records (id) on delete cascade,
  advisor_id uuid not null references public.profiles (id) on delete cascade,
  attendance_date date not null,
  previous_status public.attendance_status not null,
  new_status public.attendance_status not null,
  changed_by uuid references public.profiles (id) on delete set null,
  changed_at timestamptz not null default now(),
  reason text not null check (length(trim(reason)) > 0)
);

comment on table public.attendance_audit is
  'Because managers may edit a saved record and there are no correction requests, every change carries a mandatory reason. This table is the reason the edit path is trustworthy.';

create index attendance_audit_record_idx on public.attendance_audit (record_id, changed_at desc);
create index attendance_audit_advisor_idx on public.attendance_audit (advisor_id, attendance_date);

-- ---------------------------------------------------------------------------
-- makeup_tasks
-- ---------------------------------------------------------------------------

create table public.makeup_tasks (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  attendance_date date not null,
  programme_day integer,
  status public.makeup_status not null default 'outstanding',
  resolved_at timestamptz,
  resolved_by uuid references public.profiles (id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (enrolment_id, attendance_date)
);

comment on table public.makeup_tasks is
  'Created automatically when an advisor is marked absent. The missed day''s content is already sitting in their queue because the clock shifts; this row is what makes it visible as outstanding on both dashboards.';

create index makeup_tasks_outstanding_idx
  on public.makeup_tasks (enrolment_id)
  where status = 'outstanding';

create trigger makeup_tasks_set_updated_at
  before update on public.makeup_tasks
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- is_working_day — one definition, used by both the RPC and reporting
-- ---------------------------------------------------------------------------

create or replace function public.is_working_day(target_date date)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    extract(isodow from target_date)::integer = any(
      coalesce(
        (select array(select jsonb_array_elements_text(value)::integer)
         from public.app_settings where key = 'working_weekdays'),
        array[1, 2, 3, 4, 5]
      )
    )
    and not exists (
      select 1 from public.public_holidays where holiday_date = target_date
    );
$$;

comment on function public.is_working_day is
  'Mirrors isWorkingDay in src/lib/workingDays.ts. Both read the same configured weekdays and the same holiday table.';

-- ---------------------------------------------------------------------------
-- save_attendance — the whole room, one call
-- ---------------------------------------------------------------------------
--
-- `entries` is [{"advisor_id": uuid, "status": "present|late|absent",
--                "remarks": text|null, "reason": text|null}, ...]
--
-- `reason` is required only when changing a status that was already saved. A
-- first save needs no justification; revising one does.

create or replace function public.save_attendance(
  target_date date,
  entries jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  entry jsonb;
  v_advisor_id uuid;
  v_status public.attendance_status;
  v_remarks text;
  v_reason text;
  existing public.attendance_records%rowtype;
  v_record_id uuid;
  v_enrolment_id uuid;
  v_current_day integer;
  present_count integer := 0;
  late_count integer := 0;
  absent_count integer := 0;
  changed_count integer := 0;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may record attendance';
  end if;

  -- Marking a day that has not happened yet is always a mistake, and usually a
  -- mis-typed date rather than an intention.
  if target_date > current_date then
    raise exception 'Attendance cannot be recorded for a future date';
  end if;

  -- Recording attendance on a weekend or public holiday would corrupt every
  -- percentage derived from it, so it is refused rather than warned about.
  if not public.is_working_day(target_date) then
    raise exception 'Attendance cannot be recorded for %, which is not a working day', target_date;
  end if;

  for entry in select * from jsonb_array_elements(entries)
  loop
    v_advisor_id := (entry ->> 'advisor_id')::uuid;
    v_status := (entry ->> 'status')::public.attendance_status;
    v_remarks := nullif(trim(coalesce(entry ->> 'remarks', '')), '');
    v_reason := nullif(trim(coalesce(entry ->> 'reason', '')), '');

    select * into existing
    from public.attendance_records
    where advisor_id = v_advisor_id and attendance_date = target_date;

    if existing.id is not null then
      -- Nothing to do when neither the status nor the remark has moved.
      if existing.status = v_status and existing.remarks is not distinct from v_remarks then
        v_record_id := existing.id;
      else
        if existing.status <> v_status and v_reason is null then
          raise exception
            'Changing saved attendance for % on % requires a reason',
            v_advisor_id, target_date;
        end if;

        update public.attendance_records
        set status = v_status,
            remarks = v_remarks,
            recorded_by = auth.uid(),
            recorded_at = now()
        where id = existing.id;

        if existing.status <> v_status then
          insert into public.attendance_audit (
            record_id, advisor_id, attendance_date,
            previous_status, new_status, changed_by, reason
          )
          values (
            existing.id, v_advisor_id, target_date,
            existing.status, v_status, auth.uid(), v_reason
          );
          changed_count := changed_count + 1;
        end if;

        v_record_id := existing.id;
      end if;
    else
      insert into public.attendance_records (
        advisor_id, attendance_date, status, remarks, recorded_by
      )
      values (v_advisor_id, target_date, v_status, v_remarks, auth.uid())
      returning id into v_record_id;
    end if;

    -- An absence creates a make-up task; correcting an absence to present or
    -- late withdraws it, so a mis-click does not leave a task behind.
    select e.id, e.current_day into v_enrolment_id, v_current_day
    from public.enrolments e
    where e.advisor_id = v_advisor_id
      and e.status in ('active', 'paused', 'extended')
    order by e.created_at desc
    limit 1;

    if v_enrolment_id is not null then
      if v_status = 'absent' then
        insert into public.makeup_tasks (enrolment_id, attendance_date, programme_day)
        values (v_enrolment_id, target_date, v_current_day)
        on conflict (enrolment_id, attendance_date) do nothing;
      else
        delete from public.makeup_tasks
        where enrolment_id = v_enrolment_id
          and attendance_date = target_date
          and status = 'outstanding';
      end if;
    end if;

    case v_status
      when 'present' then present_count := present_count + 1;
      when 'late' then late_count := late_count + 1;
      when 'absent' then absent_count := absent_count + 1;
    end case;
  end loop;

  return jsonb_build_object(
    'date', target_date,
    'present', present_count,
    'late', late_count,
    'absent', absent_count,
    'changed', changed_count
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- attendance_summary
-- ---------------------------------------------------------------------------
--
-- Computed here rather than in the browser so the figure on an advisor's
-- dashboard and the figure in a manager's report cannot disagree.

create or replace function public.attendance_summary(target_advisor_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  present_count integer;
  late_count integer;
  absent_count integer;
  total_recorded integer;
  target_pct integer;
begin
  -- An advisor may read their own summary; anyone else needs to be staff.
  if target_advisor_id <> auth.uid() and not public.is_manager_or_admin() then
    raise exception 'You may only view your own attendance';
  end if;

  select
    count(*) filter (where status = 'present'),
    count(*) filter (where status = 'late'),
    count(*) filter (where status = 'absent'),
    count(*)
  into present_count, late_count, absent_count, total_recorded
  from public.attendance_records
  where advisor_id = target_advisor_id;

  select coalesce(
    (select (value #>> '{}')::integer from public.app_settings where key = 'attendance_target_pct'),
    90
  ) into target_pct;

  return jsonb_build_object(
    'present', present_count,
    'late', late_count,
    'absent', absent_count,
    'total_recorded', total_recorded,
    -- Late still counts as attendance: the advisor was there. Repeated lateness
    -- is surfaced separately as a flag rather than folded into this percentage.
    'attendance_pct', case
      when total_recorded = 0 then null
      else round(((present_count + late_count)::numeric / total_recorded) * 100)::integer
    end,
    'target_pct', target_pct,
    'below_target', case
      when total_recorded = 0 then false
      else round(((present_count + late_count)::numeric / total_recorded) * 100) < target_pct
    end
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- attendance_not_recorded_today — drives the manager banner
-- ---------------------------------------------------------------------------

create or replace function public.attendance_pending_for(target_date date)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when not public.is_working_day(target_date) then 0
    else (
      select count(*)::integer
      from public.enrolments e
      where e.status in ('active', 'extended')
        and not exists (
          select 1 from public.attendance_records ar
          where ar.advisor_id = e.advisor_id
            and ar.attendance_date = target_date
        )
    )
  end;
$$;

comment on function public.attendance_pending_for is
  'How many active advisors have no attendance record for the date. Returns 0 on a non-working day so the banner stays quiet at weekends. Paused enrolments are excluded — they are not expected in the office.';

-- ---------------------------------------------------------------------------
-- resolve_makeup_task
-- ---------------------------------------------------------------------------

create or replace function public.resolve_makeup_task(
  target_task_id uuid,
  new_status public.makeup_status,
  note text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may resolve a make-up task';
  end if;

  if new_status = 'outstanding' then
    raise exception 'Use complete or waived to resolve a make-up task';
  end if;

  if new_status = 'waived' and (note is null or length(trim(note)) = 0) then
    raise exception 'Waiving a make-up task requires a note';
  end if;

  update public.makeup_tasks
  set status = new_status,
      resolved_at = now(),
      resolved_by = auth.uid(),
      note = coalesce(nullif(trim(coalesce(note, '')), ''), makeup_tasks.note)
  where id = target_task_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, reason)
  values (auth.uid(), 'makeup_task', target_task_id, 'resolve_makeup_task', note);
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.attendance_records enable row level security;
alter table public.attendance_audit   enable row level security;
alter table public.makeup_tasks       enable row level security;

-- Advisors read their own attendance and nothing else. There is deliberately no
-- insert, update or delete policy for them anywhere in this file: attendance is
-- manager-controlled, and the absence of a correction-request workflow means
-- there is no advisor write path at all.
create policy "attendance_records: advisor reads own"
  on public.attendance_records for select
  to authenticated
  using (advisor_id = auth.uid());

create policy "attendance_records: managers read all"
  on public.attendance_records for select
  to authenticated
  using (public.is_manager_or_admin());

-- Writes go through save_attendance, which enforces the working-day rule and
-- the mandatory reason. These policies exist so a manager can correct data
-- directly in an emergency; the RPC remains the only route the interface uses.
create policy "attendance_records: managers write"
  on public.attendance_records for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- An advisor can see that their own record was changed, and why. Transparency
-- about a correction costs nothing and pre-empts the argument.
create policy "attendance_audit: advisor reads own"
  on public.attendance_audit for select
  to authenticated
  using (advisor_id = auth.uid());

create policy "attendance_audit: managers read all"
  on public.attendance_audit for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "makeup_tasks: advisor reads own"
  on public.makeup_tasks for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "makeup_tasks: managers read all"
  on public.makeup_tasks for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "makeup_tasks: managers write"
  on public.makeup_tasks for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

grant execute on function public.is_working_day(date) to authenticated;
grant execute on function public.save_attendance(date, jsonb) to authenticated;
grant execute on function public.attendance_summary(uuid) to authenticated;
grant execute on function public.attendance_pending_for(date) to authenticated;
grant execute on function public.resolve_makeup_task(uuid, public.makeup_status, text) to authenticated;
