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
