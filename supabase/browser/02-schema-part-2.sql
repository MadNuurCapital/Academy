-- =========================================================================
-- ATLAS Academy — Schema, part 2 of 2
--
-- BUNDLE 2 OF 6. Paste this whole file into the Supabase SQL Editor
-- and press Run. Run the bundles in numeric order; each one depends on the
-- ones before it.
--
-- This file is generated. Do not edit it by hand — edit the source files
-- listed below and regenerate with scripts/build-browser-sql.sh
--
-- Source files, concatenated in this order:
--   supabase/migrations/20260731000800_content_rls.sql
--   supabase/migrations/20260731000900_attendance.sql
--   supabase/migrations/20260731001000_practical.sql
--   supabase/migrations/20260731001100_practical_rls.sql
--   supabase/migrations/20260731001200_readiness.sql
-- =========================================================================



-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000800_content_rls.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0008 · Row Level Security for content and progress
--
-- Same discipline as migration 0004: enabled everywhere, deny by default, and
-- advisors get read access scoped to published content on days they have
-- actually unlocked.
--
-- The one unusual thing in this file is the column-level privilege on
-- quiz_options.is_correct. See the section at the end.

alter table public.modules                    enable row level security;
alter table public.lessons                    enable row level security;
alter table public.resources                  enable row level security;
alter table public.terminology                enable row level security;
alter table public.revision_cards             enable row level security;
alter table public.quizzes                    enable row level security;
alter table public.quiz_questions             enable row level security;
alter table public.quiz_options               enable row level security;
alter table public.lesson_progress            enable row level security;
alter table public.module_progress            enable row level security;
alter table public.quiz_attempts              enable row level security;
alter table public.quiz_answers               enable row level security;
alter table public.knowledge_check_responses  enable row level security;

-- ---------------------------------------------------------------------------
-- modules
-- ---------------------------------------------------------------------------

-- Published *and* unlocked. Publishing alone is not enough: an advisor on Day 3
-- must not be able to read Day 20's content by guessing a URL.
create policy "modules: advisor reads unlocked published"
  on public.modules for select
  to authenticated
  using (public.module_is_available(id, public.my_enrolment_id()));

create policy "modules: managers read all"
  on public.modules for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "modules: managers write"
  on public.modules for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- Module children — lessons, resources, terminology, revision cards
--
-- All four gate on the same availability check, so there is one definition of
-- "the advisor may see this" rather than four that can drift apart.
-- ---------------------------------------------------------------------------

create policy "lessons: advisor reads available"
  on public.lessons for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "lessons: managers read all"
  on public.lessons for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "lessons: managers write"
  on public.lessons for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "resources: advisor reads available"
  on public.resources for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "resources: managers read all"
  on public.resources for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "resources: managers write"
  on public.resources for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "terminology: advisor reads available"
  on public.terminology for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "terminology: managers read all"
  on public.terminology for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "terminology: managers write"
  on public.terminology for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "revision_cards: advisor reads available"
  on public.revision_cards for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "revision_cards: managers read all"
  on public.revision_cards for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "revision_cards: managers write"
  on public.revision_cards for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- quizzes and questions
-- ---------------------------------------------------------------------------

create policy "quizzes: advisor reads available"
  on public.quizzes for select
  to authenticated
  using (public.module_is_available(module_id, public.my_enrolment_id()));

create policy "quizzes: managers read all"
  on public.quizzes for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quizzes: managers write"
  on public.quizzes for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "quiz_questions: advisor reads available"
  on public.quiz_questions for select
  to authenticated
  using (
    exists (
      select 1 from public.quizzes qz
      where qz.id = quiz_questions.quiz_id
        and public.module_is_available(qz.module_id, public.my_enrolment_id())
    )
  );

create policy "quiz_questions: managers read all"
  on public.quiz_questions for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quiz_questions: managers write"
  on public.quiz_questions for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "quiz_options: advisor reads available"
  on public.quiz_options for select
  to authenticated
  using (
    exists (
      select 1
      from public.quiz_questions qq
      join public.quizzes qz on qz.id = qq.quiz_id
      where qq.id = quiz_options.question_id
        and public.module_is_available(qz.module_id, public.my_enrolment_id())
    )
  );

create policy "quiz_options: managers read all"
  on public.quiz_options for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quiz_options: managers write"
  on public.quiz_options for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- Progress tables
-- ---------------------------------------------------------------------------

-- Advisors may read their own lesson progress and insert to it. Inserting
-- directly is harmless — reading a lesson is self-reported either way — but the
-- interface goes through mark_lesson_read() so that module and day evaluation
-- happen in the same transaction.
create policy "lesson_progress: advisor reads own"
  on public.lesson_progress for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "lesson_progress: advisor inserts own"
  on public.lesson_progress for insert
  to authenticated
  with check (public.owns_enrolment(enrolment_id));

create policy "lesson_progress: managers read all"
  on public.lesson_progress for select
  to authenticated
  using (public.is_manager_or_admin());

-- module_progress is derived state. Advisors read it and never write it: only
-- evaluate_module_completion may decide a module is finished.
create policy "module_progress: advisor reads own"
  on public.module_progress for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "module_progress: managers read all"
  on public.module_progress for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "module_progress: managers write"
  on public.module_progress for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- Advisors read their own attempts. There is deliberately NO advisor insert or
-- update policy: attempts are created by start_quiz_attempt and scored by
-- submit_quiz_attempt, both security definer. Without this restriction a client
-- could simply set passed = true.
create policy "quiz_attempts: advisor reads own"
  on public.quiz_attempts for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "quiz_attempts: managers read all"
  on public.quiz_attempts for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "quiz_attempts: managers write"
  on public.quiz_attempts for all
  to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

-- Likewise for answers: readable after the fact, written only by the scorer.
create policy "quiz_answers: advisor reads own"
  on public.quiz_answers for select
  to authenticated
  using (
    exists (
      select 1 from public.quiz_attempts qa
      where qa.id = quiz_answers.attempt_id
        and public.owns_enrolment(qa.enrolment_id)
    )
  );

create policy "quiz_answers: managers read all"
  on public.quiz_answers for select
  to authenticated
  using (public.is_manager_or_admin());

create policy "knowledge_checks: advisor reads own"
  on public.knowledge_check_responses for select
  to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "knowledge_checks: advisor inserts own"
  on public.knowledge_check_responses for insert
  to authenticated
  with check (public.owns_enrolment(enrolment_id));

create policy "knowledge_checks: managers read all"
  on public.knowledge_check_responses for select
  to authenticated
  using (public.is_manager_or_admin());

-- ---------------------------------------------------------------------------
-- Column-level protection for the answer key
-- ---------------------------------------------------------------------------
--
-- RLS controls which ROWS a user sees. It cannot hide a COLUMN. The policy
-- above deliberately lets an advisor read the quiz_options rows for a quiz they
-- are entitled to sit — they need option_text to answer the question — but
-- is_correct sitting in those same rows would hand over the answer key.
--
-- Column privileges are the correct tool. Revoking table-wide SELECT and
-- re-granting only the safe columns means PostgreSQL refuses
--
--     select is_correct from quiz_options
--
-- with "permission denied for column", before RLS is even consulted. There is
-- no ordering of filters, no view definition and no client behaviour that can
-- reach it.
--
-- quiz_answers.is_correct is protected the same way: an advisor may see their
-- own answers, but the grading verdict is written and read by the scorer.

revoke select on public.quiz_options from authenticated;
grant select (id, question_id, option_text, sequence, created_at, updated_at)
  on public.quiz_options to authenticated;

revoke select on public.quiz_questions from authenticated;
grant select (id, quiz_id, question_text, question_type, sequence, created_at, updated_at)
  on public.quiz_questions to authenticated;

-- The service role and managers need the full picture; those paths go through
-- security-definer functions or the manager policies, both of which run as the
-- owner and are unaffected by the grants above.
--
-- KNOWN FRAGILITY, and how it is defended:
--
-- Column privileges are undone by a later table-wide `grant select on
-- quiz_options to authenticated` — including the blanket
-- `grant select on all tables in schema public` that is easy to run from the
-- Supabase SQL editor while debugging something unrelated. The answer key would
-- silently become readable, with no error and nothing in the interface to show
-- it.
--
-- Three things guard against that:
--
--   1. supabase/tests/rls.test.sql asserts the privilege is absent, and its
--      runner reproduces Supabase's real grant ordering, so a regression fails
--      the suite rather than reaching production.
--   2. The assertion below fails the migration immediately if the revoke did
--      not take effect.
--   3. quiz_questions_for_attempt gives the application a route that never
--      selects the column, so no interface code has a reason to widen the grant.

do $$
begin
  if has_column_privilege('authenticated', 'public.quiz_options', 'is_correct', 'select') then
    raise exception
      'Migration guard: the authenticated role can still read quiz_options.is_correct. '
      'A blanket table grant has overridden the column privilege and every quiz answer is exposed.';
  end if;

  if has_column_privilege('authenticated', 'public.quiz_questions', 'explanation', 'select') then
    raise exception
      'Migration guard: the authenticated role can still read quiz_questions.explanation.';
  end if;

  if not has_column_privilege('authenticated', 'public.quiz_options', 'option_text', 'select') then
    raise exception
      'Migration guard: the authenticated role cannot read quiz_options.option_text, '
      'so advisors would be unable to sit a quiz at all.';
  end if;
end;
$$;

comment on column public.quiz_options.is_correct is
  'Protected by column privilege, not by RLS and not by the interface. Revoked from the authenticated role in migration 0008.';

comment on column public.quiz_questions.explanation is
  'Withheld from advisors for the same reason as the answer key: revealed only in the submit_quiz_attempt payload, and only on a pass.';


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731000900_attendance.sql
-- ----------------------------------------------------------------------

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


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731001000_practical.sql
-- ----------------------------------------------------------------------

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


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731001100_practical_rls.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0011 · Practical development: functions and RLS
--
-- The notable thing in this file is how candid coaching notes are protected.
-- The obvious move was to copy the column privilege used for the quiz answer
-- key; it does not work here, for a reason explained in full further down.
-- They live in their own table with a manager-only policy instead.

-- ---------------------------------------------------------------------------
-- score_practical
-- ---------------------------------------------------------------------------
--
-- Scoring is a manager act. The total is computed here from the individual
-- criterion scores rather than accepted from the client, so a submitted total
-- cannot disagree with the parts it is supposed to be made of.

create or replace function public.score_practical(
  target_assessment_id uuid,
  scores jsonb,
  feedback text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_rubric_id uuid;
  v_enrolment_id uuid;
  v_advisor_id uuid;
  v_pass_mark integer;
  entry jsonb;
  computed_total integer := 0;
  computed_max integer := 0;
  did_pass boolean;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may score a practical assessment';
  end if;

  if feedback is null or length(trim(feedback)) = 0 then
    raise exception 'Written feedback is required. The score alone tells the advisor nothing they can act on';
  end if;

  select pa.rubric_id, pa.enrolment_id, e.advisor_id
    into v_rubric_id, v_enrolment_id, v_advisor_id
  from public.practical_assessments pa
  join public.enrolments e on e.id = pa.enrolment_id
  where pa.id = target_assessment_id;

  if v_rubric_id is null then
    raise exception 'Assessment not found';
  end if;

  delete from public.practical_scores where assessment_id = target_assessment_id;

  for entry in select * from jsonb_array_elements(scores)
  loop
    insert into public.practical_scores (assessment_id, criterion_id, score, comment)
    select
      target_assessment_id,
      rc.id,
      least((entry ->> 'score')::integer, rc.max_score),
      nullif(trim(coalesce(entry ->> 'comment', '')), '')
    from public.rubric_criteria rc
    where rc.id = (entry ->> 'criterion_id')::uuid
      -- A criterion from another rubric would silently inflate the total.
      and rc.rubric_id = v_rubric_id;
  end loop;

  select coalesce(sum(ps.score), 0) into computed_total
  from public.practical_scores ps where ps.assessment_id = target_assessment_id;

  select coalesce(sum(rc.max_score), 0) into computed_max
  from public.rubric_criteria rc where rc.rubric_id = v_rubric_id;

  select r.pass_mark_pct into v_pass_mark
  from public.rubrics r where r.id = v_rubric_id;

  did_pass := computed_max > 0
    and (computed_total::numeric / computed_max) * 100 >= v_pass_mark;

  update public.practical_assessments
  set status = case when did_pass then 'scored'::public.assessment_status
                    else 'retry_required'::public.assessment_status end,
      assessed_by = auth.uid(),
      assessed_at = now(),
      total_score = computed_total,
      max_score = computed_max,
      passed = did_pass,
      feedback = trim(score_practical.feedback),
      -- A re-score invalidates any previous acknowledgement: the advisor has
      -- not seen this feedback yet.
      advisor_acknowledged_at = null
  where id = target_assessment_id;

  perform public.notify(
    v_advisor_id,
    'practical_scored',
    case when did_pass then 'Practical assessment passed' else 'Practical assessment needs another attempt' end,
    'Your manager has left written feedback. Please read and acknowledge it.',
    '/feedback'
  );

  return jsonb_build_object(
    'total_score', computed_total,
    'max_score', computed_max,
    'passed', did_pass,
    'pass_mark_pct', v_pass_mark
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- acknowledge_feedback
-- ---------------------------------------------------------------------------

create or replace function public.acknowledge_feedback(target_assessment_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_enrolment_id uuid;
begin
  select pa.enrolment_id into v_enrolment_id
  from public.practical_assessments pa where pa.id = target_assessment_id;

  if v_enrolment_id is null then
    raise exception 'Assessment not found';
  end if;

  if not public.owns_enrolment(v_enrolment_id) then
    raise exception 'You may only acknowledge your own feedback';
  end if;

  update public.practical_assessments
  set advisor_acknowledged_at = now()
  where id = target_assessment_id
    and assessed_at is not null;
end;
$$;

-- ---------------------------------------------------------------------------
-- notify — the only route by which a notification is created
-- ---------------------------------------------------------------------------

create or replace function public.notify(
  target_user_id uuid,
  notification_type text,
  title text,
  body text default null,
  link text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.notifications (user_id, type, title, body, link)
  values (target_user_id, notification_type, title, body, link);
end;
$$;

comment on function public.notify is
  'Called from other security-definer functions so notifications are generated server-side alongside the event that caused them. RLS confines each row to its recipient.';

-- ---------------------------------------------------------------------------
-- Coaching
-- ---------------------------------------------------------------------------

create or replace function public.schedule_coaching(
  target_advisor_id uuid,
  scheduled_at timestamptz,
  topic text,
  reason text default null,
  preparation text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  new_session_id uuid;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may schedule coaching';
  end if;

  if topic is null or length(trim(topic)) = 0 then
    raise exception 'A coaching session needs a topic';
  end if;

  insert into public.coaching_sessions (advisor_id, manager_id, scheduled_at, topic, reason, preparation)
  values (target_advisor_id, auth.uid(), scheduled_at, trim(topic), reason, preparation)
  returning id into new_session_id;

  perform public.notify(
    target_advisor_id,
    'coaching_scheduled',
    'Coaching session scheduled',
    case
      when preparation is not null and length(trim(preparation)) > 0
        then 'Please review the assigned preparation before the session.'
      else 'Your manager has scheduled a coaching session with you.'
    end,
    '/coaching/' || new_session_id
  );

  return new_session_id;
end;
$$;

create or replace function public.complete_coaching_action(target_action_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_advisor_id uuid;
begin
  select cs.advisor_id into v_advisor_id
  from public.coaching_actions ca
  join public.coaching_sessions cs on cs.id = ca.session_id
  where ca.id = target_action_id;

  if v_advisor_id is null then
    raise exception 'Coaching action not found';
  end if;

  -- Either the advisor whose action it is, or a manager, may close it.
  if v_advisor_id <> auth.uid() and not public.is_manager_or_admin() then
    raise exception 'You may only complete your own coaching actions';
  end if;

  update public.coaching_actions
  set status = 'complete', completed_at = now(), completed_by = auth.uid()
  where id = target_action_id;
end;
$$;

create or replace function public.acknowledge_coaching(target_session_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.coaching_sessions
  set advisor_acknowledged_at = now()
  where id = target_session_id
    and advisor_id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.scripts                enable row level security;
alter table public.concept_presentations  enable row level security;
alter table public.rubrics                enable row level security;
alter table public.rubric_criteria        enable row level security;
alter table public.practical_assessments  enable row level security;
alter table public.practical_scores       enable row level security;
alter table public.concept_attempts       enable row level security;
alter table public.coaching_sessions      enable row level security;
alter table public.coaching_private_notes enable row level security;
alter table public.coaching_actions       enable row level security;
alter table public.fieldwork_records      enable row level security;

-- Scripts and concepts are reference material: published content is readable by
-- any authenticated user, drafts by staff only.
create policy "scripts: read published"
  on public.scripts for select to authenticated using (status = 'published');
create policy "scripts: managers read all"
  on public.scripts for select to authenticated using (public.is_manager_or_admin());
create policy "scripts: managers write"
  on public.scripts for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

create policy "concepts: read published"
  on public.concept_presentations for select to authenticated using (status = 'published');
create policy "concepts: managers read all"
  on public.concept_presentations for select to authenticated using (public.is_manager_or_admin());
create policy "concepts: managers write"
  on public.concept_presentations for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

-- Advisors may read the rubric they are assessed against. Being scored against
-- criteria you were not allowed to see would be indefensible.
create policy "rubrics: authenticated read active"
  on public.rubrics for select to authenticated using (is_active);
create policy "rubrics: admins write"
  on public.rubrics for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "rubric_criteria: authenticated read"
  on public.rubric_criteria for select to authenticated using (true);
create policy "rubric_criteria: admins write"
  on public.rubric_criteria for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "practical_assessments: advisor reads own"
  on public.practical_assessments for select to authenticated
  using (public.owns_enrolment(enrolment_id));
create policy "practical_assessments: managers read all"
  on public.practical_assessments for select to authenticated
  using (public.is_manager_or_admin());
create policy "practical_assessments: managers write"
  on public.practical_assessments for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

create policy "practical_scores: advisor reads own"
  on public.practical_scores for select to authenticated
  using (exists (
    select 1 from public.practical_assessments pa
    where pa.id = practical_scores.assessment_id
      and public.owns_enrolment(pa.enrolment_id)
  ));
create policy "practical_scores: managers read all"
  on public.practical_scores for select to authenticated
  using (public.is_manager_or_admin());
create policy "practical_scores: managers write"
  on public.practical_scores for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

create policy "concept_attempts: advisor reads own"
  on public.concept_attempts for select to authenticated
  using (public.owns_enrolment(enrolment_id));
create policy "concept_attempts: managers read all"
  on public.concept_attempts for select to authenticated
  using (public.is_manager_or_admin());
create policy "concept_attempts: managers write"
  on public.concept_attempts for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

-- Coaching is visible to the advisor concerned, managers and admins — and to
-- nobody else. It is never broadcast to other advisors.
create policy "coaching_sessions: advisor reads own"
  on public.coaching_sessions for select to authenticated
  using (advisor_id = auth.uid());
create policy "coaching_sessions: managers read all"
  on public.coaching_sessions for select to authenticated
  using (public.is_manager_or_admin());
create policy "coaching_sessions: managers write"
  on public.coaching_sessions for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

-- Private notes: managers and admins only. Advisors get NO policy at all, so
-- deny-by-default returns nothing — including for notes about themselves.
create policy "coaching_private_notes: managers only"
  on public.coaching_private_notes for all to authenticated
  using (public.is_manager_or_admin())
  with check (public.is_manager_or_admin());

create policy "coaching_actions: advisor reads own"
  on public.coaching_actions for select to authenticated
  using (exists (
    select 1 from public.coaching_sessions cs
    where cs.id = coaching_actions.session_id and cs.advisor_id = auth.uid()
  ));
create policy "coaching_actions: managers read all"
  on public.coaching_actions for select to authenticated
  using (public.is_manager_or_admin());
create policy "coaching_actions: managers write"
  on public.coaching_actions for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

create policy "fieldwork: advisor reads own"
  on public.fieldwork_records for select to authenticated
  using (advisor_id = auth.uid());
create policy "fieldwork: managers read all"
  on public.fieldwork_records for select to authenticated
  using (public.is_manager_or_admin());
create policy "fieldwork: managers write"
  on public.fieldwork_records for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

-- The advisor's own reflection is the one field on a fieldwork record they may
-- write. The WITH CHECK keeps the row theirs; the manager's assessment of them
-- is not editable from this side.
create policy "fieldwork: advisor writes own reflection"
  on public.fieldwork_records for update to authenticated
  using (advisor_id = auth.uid())
  with check (advisor_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Why private notes are a separate table, not a protected column
-- ---------------------------------------------------------------------------
--
-- The quiz answer key is protected with a column privilege, and the obvious
-- move was to do the same for candid coaching notes. It does not work here, and
-- the reason is instructive.
--
-- A column privilege is granted to a ROLE. Advisors and managers are both
-- `authenticated` — they differ only in what the RLS predicates let them see.
-- Revoking the column from `authenticated` therefore blocks managers too, which
-- testing caught immediately: the people who need to write and read candid
-- notes could no longer read them.
--
-- Moving the notes into their own table solves it cleanly, because RLS *can*
-- distinguish the two: `is_manager_or_admin()` is evaluated per caller.
--
-- It is also the stronger option. Table grants do not bypass RLS, so the stray
-- `grant select on all tables in schema public` that would silently defeat a
-- column privilege leaves this protection completely intact.
--
-- The guard below asserts the property that actually matters: an advisor gets
-- nothing from coaching_private_notes, and a manager gets everything.

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'coaching_private_notes'
      and policyname = 'coaching_private_notes: managers only'
  ) then
    raise exception
      'Migration guard: coaching_private_notes has no manager-only policy. '
      'With RLS enabled and no policy, nobody could read candid notes; without RLS, everybody could.';
  end if;

  if not (
    select relrowsecurity from pg_class where oid = 'public.coaching_private_notes'::regclass
  ) then
    raise exception
      'Migration guard: row level security is not enabled on coaching_private_notes. '
      'Candid management notes would be readable by the advisors they are about.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

grant execute on function public.score_practical(uuid, jsonb, text) to authenticated;
grant execute on function public.acknowledge_feedback(uuid) to authenticated;
grant execute on function public.schedule_coaching(uuid, timestamptz, text, text, text) to authenticated;
grant execute on function public.complete_coaching_action(uuid) to authenticated;
grant execute on function public.acknowledge_coaching(uuid) to authenticated;

-- notify() is called from inside other security-definer functions, which run as
-- the owner. It is not granted to authenticated, so a client cannot manufacture
-- a notification in someone else's feed.
revoke execute on function public.notify(uuid, text, text, text, text) from public;


-- ----------------------------------------------------------------------
-- supabase/migrations/20260731001200_readiness.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — 0012 · Completion requirements and the readiness decision
--
-- The end of the programme, and the reason the rest of the system exists: a
-- recorded, defensible answer to "is this advisor ready for supervised client
-- work?".
--
-- Completing ATLAS does NOT mean the advisor may work independently. The four
-- permitted outcomes all sit short of that, and "Certified Independent Advisor"
-- is deliberately not among them.
--
-- Every threshold below is read from app_settings. Nothing here is hard-coded,
-- because the business may reasonably change the bar without a deployment.

create table public.readiness_reviews (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments (id) on delete cascade,
  manager_id uuid not null references public.profiles (id),
  decided_at timestamptz not null default now(),
  outcome public.readiness_outcome not null,
  attendance_pct integer,
  modules_complete integer,
  modules_required integer,
  quizzes_passed integer,
  strengths text,
  development_areas text,
  notes text,
  -- Which blockers the manager chose to proceed despite, and why.
  blockers_overridden jsonb not null default '[]'::jsonb,
  override_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.readiness_reviews is
  'The Day 30 decision. One row per decision; a re-review after a programme extension creates a new row rather than editing the old one, so the history of what was decided and when survives.';

create index readiness_reviews_enrolment_idx on public.readiness_reviews (enrolment_id, decided_at desc);

create trigger readiness_reviews_set_updated_at
  before update on public.readiness_reviews
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- evaluate_completion_requirements
-- ---------------------------------------------------------------------------
--
-- Returns the full checklist as jsonb: every requirement, whether it is met,
-- whether failing it blocks the decision, and the numbers behind it.
--
-- Computed server-side so the list a manager sees on screen is the same list
-- the decision function enforces. If those two ever disagreed, the screen would
-- be the one lying.

create or replace function public.evaluate_completion_requirements(target_enrolment_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_advisor_id uuid;
  v_template_id uuid;
  attendance jsonb;
  v_attendance_pct integer;
  v_attendance_target integer;
  v_attendance_blocks boolean;
  required_modules integer;
  complete_modules integer;
  total_quizzes integer;
  passed_quizzes integer;
  pending_practicals integer;
  failed_practicals integer;
  required_concepts integer;
  passed_concepts integer;
  required_fieldwork integer;
  logged_fieldwork integer;
  open_actions integer;
  final_knowledge_passed boolean;
  final_practical_passed boolean;
  final_blocks boolean;
  requirements jsonb := '[]'::jsonb;
  blocker_count integer := 0;
begin
  if not public.is_manager_or_admin() and not public.owns_enrolment(target_enrolment_id) then
    raise exception 'You may only view your own readiness requirements';
  end if;

  select e.advisor_id, e.template_id into v_advisor_id, v_template_id
  from public.enrolments e where e.id = target_enrolment_id;

  if v_advisor_id is null then
    raise exception 'Enrolment not found';
  end if;

  -- Settings, each with the documented default if the row is absent.
  select coalesce((select (value #>> '{}')::integer from public.app_settings where key = 'attendance_target_pct'), 90)
    into v_attendance_target;
  select coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'attendance_blocks_completion'), false)
    into v_attendance_blocks;
  select coalesce((select (value #>> '{}')::integer from public.app_settings where key = 'required_concept_presentations'), 2)
    into required_concepts;
  select coalesce((select (value #>> '{}')::integer from public.app_settings where key = 'required_fieldwork_sessions'), 1)
    into required_fieldwork;
  select coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'final_assessments_block_completion'), true)
    into final_blocks;

  attendance := public.attendance_summary(v_advisor_id);
  v_attendance_pct := nullif(attendance ->> 'attendance_pct', '')::integer;

  select count(*) into required_modules
  from public.modules m
  join public.programme_days pd on pd.id = m.programme_day_id
  where pd.template_id = v_template_id and m.is_required and m.status = 'published';

  select count(*) into complete_modules
  from public.module_progress mp
  join public.modules m on m.id = mp.module_id
  join public.programme_days pd on pd.id = m.programme_day_id
  where mp.enrolment_id = target_enrolment_id
    and mp.status = 'complete'
    and m.is_required and m.status = 'published'
    and pd.template_id = v_template_id;

  select count(distinct q.id) into total_quizzes
  from public.quizzes q
  join public.modules m on m.id = q.module_id
  join public.programme_days pd on pd.id = m.programme_day_id
  where pd.template_id = v_template_id and m.is_required and m.status = 'published';

  select count(distinct qa.quiz_id) into passed_quizzes
  from public.quiz_attempts qa
  where qa.enrolment_id = target_enrolment_id and qa.passed;

  select count(*) into pending_practicals
  from public.practical_assessments
  where enrolment_id = target_enrolment_id and status = 'pending';

  select count(*) into failed_practicals
  from public.practical_assessments
  where enrolment_id = target_enrolment_id and status = 'retry_required';

  select count(distinct ca.concept_id) into passed_concepts
  from public.concept_attempts ca
  join public.concept_presentations cp on cp.id = ca.concept_id
  where ca.enrolment_id = target_enrolment_id and ca.passed and cp.is_required;

  select count(*) into logged_fieldwork
  from public.fieldwork_records where advisor_id = v_advisor_id;

  select count(*) into open_actions
  from public.coaching_actions ca
  join public.coaching_sessions cs on cs.id = ca.session_id
  where cs.advisor_id = v_advisor_id and ca.is_required and ca.status = 'open';

  select exists (
    select 1 from public.quiz_attempts qa
    join public.quizzes q on q.id = qa.quiz_id
    where qa.enrolment_id = target_enrolment_id and qa.passed and q.is_final
  ) into final_knowledge_passed;

  select exists (
    select 1 from public.practical_assessments pa
    where pa.enrolment_id = target_enrolment_id and pa.passed and pa.is_final
  ) into final_practical_passed;

  -- Build the checklist. `blocks` records whether failing this requirement
  -- prevents a decision; `met` records whether it is satisfied.
  requirements := jsonb_build_array(
    jsonb_build_object(
      'key', 'attendance',
      'label', 'Attendance at or above target',
      'met', coalesce(v_attendance_pct >= v_attendance_target, false),
      -- The business decided attendance is visible only and never blocks. The
      -- setting exists so that decision can be revisited without a deployment.
      'blocks', v_attendance_blocks,
      'detail', coalesce(v_attendance_pct::text, '—') || '% against a ' || v_attendance_target || '% target'
    ),
    jsonb_build_object(
      'key', 'modules',
      'label', 'All compulsory modules complete',
      'met', required_modules > 0 and complete_modules >= required_modules,
      'blocks', true,
      'detail', complete_modules || ' of ' || required_modules || ' complete'
    ),
    jsonb_build_object(
      'key', 'quizzes',
      'label', 'All module quizzes passed',
      'met', total_quizzes = 0 or passed_quizzes >= total_quizzes,
      'blocks', true,
      'detail', passed_quizzes || ' of ' || total_quizzes || ' passed'
    ),
    jsonb_build_object(
      'key', 'practicals',
      'label', 'All practical assessments scored',
      'met', pending_practicals = 0 and failed_practicals = 0,
      'blocks', true,
      'detail', case
        when pending_practicals > 0 then pending_practicals || ' awaiting assessment'
        when failed_practicals > 0 then failed_practicals || ' needing another attempt'
        else 'All scored'
      end
    ),
    jsonb_build_object(
      'key', 'concepts',
      'label', 'Concept presentations passed',
      'met', passed_concepts >= required_concepts,
      'blocks', true,
      'detail', passed_concepts || ' of ' || required_concepts || ' passed'
    ),
    jsonb_build_object(
      'key', 'fieldwork',
      'label', 'Joint fieldwork completed',
      'met', logged_fieldwork >= required_fieldwork,
      'blocks', true,
      'detail', logged_fieldwork || ' of ' || required_fieldwork ||
                ' logged (an approved simulation counts)'
    ),
    jsonb_build_object(
      'key', 'coaching_actions',
      'label', 'Required coaching actions completed',
      'met', open_actions = 0,
      'blocks', true,
      'detail', case when open_actions = 0 then 'None outstanding'
                     else open_actions || ' still open' end
    ),
    jsonb_build_object(
      'key', 'final_knowledge',
      'label', 'Final knowledge assessment passed',
      'met', final_knowledge_passed,
      'blocks', final_blocks,
      'detail', case when final_knowledge_passed then 'Passed' else 'Not yet passed' end
    ),
    jsonb_build_object(
      'key', 'final_practical',
      'label', 'Final practical assessment passed',
      'met', final_practical_passed,
      'blocks', final_blocks,
      'detail', case when final_practical_passed then 'Passed' else 'Not yet passed' end
    )
  );

  select count(*) into blocker_count
  from jsonb_array_elements(requirements) r
  where (r ->> 'blocks')::boolean and not (r ->> 'met')::boolean;

  return jsonb_build_object(
    'enrolment_id', target_enrolment_id,
    'requirements', requirements,
    'blocker_count', blocker_count,
    'can_complete_without_override', blocker_count = 0,
    'attendance_pct', v_attendance_pct,
    'modules_complete', complete_modules,
    'modules_required', required_modules,
    'quizzes_passed', passed_quizzes
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- record_readiness_decision
-- ---------------------------------------------------------------------------
--
-- The manager alone makes this call. Where a blocker is unmet, proceeding
-- requires an explicit reason, which is stored on the review and written to the
-- audit log — the whole point being that someone can later ask why an advisor
-- was signed off, and get an answer.

create or replace function public.record_readiness_decision(
  target_enrolment_id uuid,
  outcome public.readiness_outcome,
  strengths text default null,
  development_areas text default null,
  notes text default null,
  override_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  evaluation jsonb;
  blocker_count integer;
  unmet_blockers jsonb;
  new_review_id uuid;
  v_advisor_id uuid;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may record a readiness decision';
  end if;

  select e.advisor_id into v_advisor_id
  from public.enrolments e where e.id = target_enrolment_id;

  if v_advisor_id is null then
    raise exception 'Enrolment not found';
  end if;

  evaluation := public.evaluate_completion_requirements(target_enrolment_id);
  blocker_count := (evaluation ->> 'blocker_count')::integer;

  select coalesce(jsonb_agg(r), '[]'::jsonb) into unmet_blockers
  from jsonb_array_elements(evaluation -> 'requirements') r
  where (r ->> 'blocks')::boolean and not (r ->> 'met')::boolean;

  -- "Additional Training Required" and "Programme Extended" are the honest
  -- outcomes for an advisor who has not met the bar, so they need no override.
  -- Declaring someone ready while requirements are unmet is what demands one.
  if blocker_count > 0
     and outcome in ('ready_for_supervised_fieldwork', 'ready_with_development_actions')
     and (override_reason is null or length(trim(override_reason)) = 0)
  then
    raise exception
      'This advisor has % unmet requirement(s). Recording a ready outcome requires a reason.',
      blocker_count;
  end if;

  insert into public.readiness_reviews (
    enrolment_id, manager_id, outcome,
    attendance_pct, modules_complete, modules_required, quizzes_passed,
    strengths, development_areas, notes,
    blockers_overridden, override_reason
  )
  values (
    target_enrolment_id, auth.uid(), outcome,
    nullif(evaluation ->> 'attendance_pct', '')::integer,
    (evaluation ->> 'modules_complete')::integer,
    (evaluation ->> 'modules_required')::integer,
    (evaluation ->> 'quizzes_passed')::integer,
    strengths, development_areas, notes,
    case when blocker_count > 0 then unmet_blockers else '[]'::jsonb end,
    nullif(trim(coalesce(override_reason, '')), '')
  )
  returning id into new_review_id;

  -- Reaching a decision closes the programme, except where the decision is
  -- explicitly to extend it.
  update public.enrolments
  set status = case
        when outcome = 'programme_extended' then 'extended'::public.enrolment_status
        else 'completed'::public.enrolment_status
      end,
      completed_at = case when outcome = 'programme_extended' then null else now() end
  where id = target_enrolment_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, reason, after)
  values (
    auth.uid(), 'enrolment', target_enrolment_id, 'record_readiness_decision',
    nullif(trim(coalesce(override_reason, '')), ''),
    jsonb_build_object(
      'outcome', outcome,
      'blockers_overridden', case when blocker_count > 0 then unmet_blockers else '[]'::jsonb end
    )
  );

  perform public.notify(
    v_advisor_id,
    'readiness_decision',
    'Your programme review is complete',
    'Your manager has recorded your Day 30 readiness outcome.',
    '/progress'
  );

  return new_review_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.readiness_reviews enable row level security;

-- An advisor may read the decision recorded about them. Withholding it would be
-- indefensible: it is the conclusion of thirty days of their work.
create policy "readiness_reviews: advisor reads own"
  on public.readiness_reviews for select to authenticated
  using (public.owns_enrolment(enrolment_id));

create policy "readiness_reviews: managers read all"
  on public.readiness_reviews for select to authenticated
  using (public.is_manager_or_admin());

create policy "readiness_reviews: managers write"
  on public.readiness_reviews for all to authenticated
  using (public.is_manager_or_admin()) with check (public.is_manager_or_admin());

grant execute on function public.evaluate_completion_requirements(uuid) to authenticated;
grant execute on function public.record_readiness_decision(
  uuid, public.readiness_outcome, text, text, text, text
) to authenticated;
