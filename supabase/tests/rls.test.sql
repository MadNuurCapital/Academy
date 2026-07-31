-- ATLAS Academy — Row Level Security tests
--
-- RLS is the real permission boundary, so it needs a test suite of its own.
-- These assertions are what stop a future migration quietly widening access.
--
-- Run against a scratch database that already has the migrations applied:
--
--   psql -v ON_ERROR_STOP=1 -d atlas_test -f supabase/tests/rls.test.sql
--
-- Every check raises an exception on failure, so a non-zero exit means a policy
-- regressed. The whole file runs inside a transaction and rolls back, leaving
-- no data behind.
--
-- Note on running locally: `set local role` only takes effect inside a
-- transaction block. Outside one it is silently ignored, the query runs as the
-- superuser, RLS is bypassed entirely, and every test passes for the wrong
-- reason.

begin;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function pg_temp.assert_eq(actual bigint, expected bigint, label text)
returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL: % — expected %, got %', label, expected, actual;
  end if;
  raise notice 'pass: %', label;
end;
$$;

create or replace function pg_temp.act_as(user_id uuid)
returns void language plpgsql as $$
begin
  execute format('set local role authenticated');
  execute format('set local request.jwt.claim.sub = %L', user_id);
end;
$$;

create or replace function pg_temp.act_as_owner()
returns void language plpgsql as $$
begin
  reset role;
end;
$$;

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------

\set alice   '11111111-1111-1111-1111-111111111111'
\set bob     '22222222-2222-2222-2222-222222222222'
\set manager '33333333-3333-3333-3333-333333333333'
\set admin   '44444444-4444-4444-4444-444444444444'
\set template 'aaaaaaaa-0000-0000-0000-000000000001'

insert into auth.users (id, email) values
  (:'alice',   'alice.rls@example.test'),
  (:'bob',     'bob.rls@example.test'),
  (:'manager', 'manager.rls@example.test'),
  (:'admin',   'admin.rls@example.test');

insert into public.user_roles (user_id, role) values
  (:'alice',   'advisor'),
  (:'bob',     'advisor'),
  (:'manager', 'manager'),
  (:'admin',   'admin');

insert into public.programme_templates (id, name, status, is_default)
values (:'template', 'RLS Test Programme', 'published', false);

insert into public.programme_days (template_id, day_number, phase, title)
select :'template', n, 'Phase 1', 'Day ' || n from generate_series(1, 30) n;

insert into public.enrolments (advisor_id, template_id, start_date, target_end_date) values
  (:'alice', :'template', '2026-08-03', '2026-09-11'),
  (:'bob',   :'template', '2026-08-03', '2026-09-11');

-- The seed trigger should have built both roadmaps.
select pg_temp.assert_eq(
  (select count(*) from public.enrolment_days),
  60, 'roadmap trigger generates 30 days per enrolment');

select pg_temp.assert_eq(
  (select count(*) from public.enrolment_days where status = 'unlocked'),
  2, 'only day 1 starts unlocked');

-- ---------------------------------------------------------------------------
-- Advisor reads: own records only
-- ---------------------------------------------------------------------------

select pg_temp.act_as(:'alice');

select pg_temp.assert_eq(
  (select count(*) from public.enrolments),
  1, 'advisor sees only their own enrolment');

select pg_temp.assert_eq(
  (select count(*) from public.enrolments where advisor_id = :'bob'),
  0, 'advisor cannot read another advisor''s enrolment');

select pg_temp.assert_eq(
  (select count(*) from public.enrolment_days),
  30, 'advisor sees only their own programme days');

select pg_temp.assert_eq(
  (select count(*) from public.profiles),
  1, 'advisor sees only their own profile');

select pg_temp.assert_eq(
  (select count(*) from public.audit_log),
  0, 'advisor cannot read the audit log');

select pg_temp.assert_eq(
  (select count(*) from public.app_settings),
  12, 'advisor can read settings (needed to render their dashboard)');

-- ---------------------------------------------------------------------------
-- Advisor writes: no path to progress, attendance or roles
-- ---------------------------------------------------------------------------

with attempt as (
  update public.enrolments set current_day = 30 where advisor_id = :'alice' returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 0,
  'advisor cannot advance their own programme day');

with attempt as (
  update public.enrolment_days set status = 'complete' where day_number = 5 returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 0,
  'advisor cannot mark a programme day complete');

with attempt as (
  update public.app_settings set value = '10'::jsonb where key = 'quiz_pass_mark' returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 0,
  'advisor cannot lower the quiz pass mark');

with attempt as (
  update public.profiles set full_name = 'Tampered' where id = :'bob' returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 0,
  'advisor cannot edit another advisor''s profile');

-- An advisor may maintain their own contact details.
with attempt as (
  update public.profiles set phone = '+6591234567' where id = :'alice' returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 1,
  'advisor can update their own phone number');

-- Privilege escalation and self-deactivation must be rejected outright rather
-- than silently filtered, so both are checked for a raised exception.
do $$
begin
  begin
    insert into public.user_roles (user_id, role)
    values ('11111111-1111-1111-1111-111111111111', 'admin');
    raise exception 'FAIL: advisor was able to grant themselves the admin role';
  exception when insufficient_privilege or check_violation then
    raise notice 'pass: advisor cannot grant themselves a role';
  end;
end;
$$;

do $$
begin
  begin
    update public.profiles set status = 'inactive'
    where id = '11111111-1111-1111-1111-111111111111';
    raise exception 'FAIL: advisor was able to change their own status';
  exception when insufficient_privilege or check_violation then
    raise notice 'pass: advisor cannot change their own profile status';
  end;
end;
$$;

-- ---------------------------------------------------------------------------
-- Manager: sees everything, but settings and the audit log stay admin-only
-- ---------------------------------------------------------------------------

select pg_temp.act_as(:'manager');

select pg_temp.assert_eq(
  (select count(*) from public.enrolments),
  2, 'manager sees every advisor''s enrolment');

select pg_temp.assert_eq(
  (select count(*) from public.profiles),
  4, 'manager sees every profile');

select pg_temp.assert_eq(
  (select count(*) from public.enrolment_days),
  60, 'manager sees every advisor''s programme days');

with attempt as (
  update public.enrolments set current_day = 3 where advisor_id = :'alice' returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 1,
  'manager can update an advisor''s enrolment');

with attempt as (
  update public.app_settings set value = '10'::jsonb where key = 'quiz_pass_mark' returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 0,
  'manager cannot change settings — admin only');

select pg_temp.assert_eq(
  (select count(*) from public.audit_log),
  0, 'manager cannot read the audit log — admin only');

-- ---------------------------------------------------------------------------
-- Administrator
-- ---------------------------------------------------------------------------

select pg_temp.act_as(:'admin');

with attempt as (
  update public.app_settings set value = '85'::jsonb where key = 'quiz_pass_mark' returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 1,
  'admin can change settings');

with attempt as (
  insert into public.public_holidays (holiday_date, name)
  values ('2026-08-09', 'National Day') returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 1,
  'admin can add a public holiday');

with attempt as (
  insert into public.user_roles (user_id, role) values (:'bob', 'manager') returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 1,
  'admin can grant a role');

-- ---------------------------------------------------------------------------
-- Unpublished content is invisible to advisors
-- ---------------------------------------------------------------------------

select pg_temp.act_as_owner();

insert into public.programme_templates (id, name, status)
values ('bbbbbbbb-0000-0000-0000-000000000002', 'Draft Programme', 'draft');

select pg_temp.act_as(:'alice');

select pg_temp.assert_eq(
  (select count(*) from public.programme_templates),
  1, 'advisor sees published templates only, never drafts');

select pg_temp.act_as(:'manager');

select pg_temp.assert_eq(
  (select count(*) from public.programme_templates),
  2, 'manager sees drafts as well as published templates');

-- ---------------------------------------------------------------------------
-- Notifications are strictly per-recipient
-- ---------------------------------------------------------------------------

select pg_temp.act_as_owner();

insert into public.notifications (user_id, type, title) values
  (:'alice', 'test', 'For Alice'),
  (:'bob',   'test', 'For Bob');

select pg_temp.act_as(:'alice');

select pg_temp.assert_eq(
  (select count(*) from public.notifications),
  1, 'advisor sees only notifications addressed to them');

-- ===========================================================================
-- PHASE 2 — content, progression and the cheat paths
-- ===========================================================================
--
-- The assertions below are the ones that matter most in the whole suite. Each
-- corresponds to a way a determined advisor could otherwise defeat the quiz
-- gate: reading the answer key, scoring themselves, unlocking their own days,
-- or reading content for a day they have not reached.

select pg_temp.act_as_owner();

\set module_d1  'cccccccc-0000-0000-0000-000000000001'
\set module_d3  'cccccccc-0000-0000-0000-000000000003'
\set lesson_a   '11111111-aaaa-0000-0000-000000000001'
\set lesson_b   '11111111-aaaa-0000-0000-000000000002'
\set quiz_d1    '99999999-0000-0000-0000-000000000001'

-- Day 1 module: two lessons and a five-question quiz.
insert into public.modules (id, programme_day_id, title, status, is_required)
select :'module_d1', pd.id, 'Advisor Role', 'published', true
from public.programme_days pd
where pd.template_id = :'template' and pd.day_number = 1;

-- A Day 3 module, used to prove locked days stay unreadable.
insert into public.modules (id, programme_day_id, title, status, is_required)
select :'module_d3', pd.id, 'Fact-Finding', 'published', true
from public.programme_days pd
where pd.template_id = :'template' and pd.day_number = 3;

-- A draft module must never be visible to an advisor, published day or not.
insert into public.modules (id, programme_day_id, title, status, is_required)
select 'cccccccc-0000-0000-0000-0000000000ff', pd.id, 'Unfinished Draft', 'draft', true
from public.programme_days pd
where pd.template_id = :'template' and pd.day_number = 1;

insert into public.lessons (id, module_id, title, sequence) values
  (:'lesson_a', :'module_d1', 'What an advisor does', 1),
  (:'lesson_b', :'module_d1', 'Professional conduct', 2);

insert into public.lessons (module_id, title, sequence)
values (:'module_d3', 'Locked-day lesson', 1);

insert into public.quizzes (id, module_id, title)
values (:'quiz_d1', :'module_d1', 'Day 1 knowledge check');

insert into public.quiz_questions (id, quiz_id, question_text, explanation, sequence)
select ('88888888-0000-0000-0000-00000000000' || n)::uuid, :'quiz_d1',
       'Question ' || n, 'Because of reason ' || n, n
from generate_series(1, 5) n;

insert into public.quiz_options (id, question_id, option_text, is_correct, sequence)
select ('77777777-0000-0000-0000-00000000000' || n)::uuid,
       ('88888888-0000-0000-0000-00000000000' || n)::uuid, 'Correct answer', true, 1
from generate_series(1, 5) n;

insert into public.quiz_options (id, question_id, option_text, is_correct, sequence)
select ('66666666-0000-0000-0000-00000000000' || n)::uuid,
       ('88888888-0000-0000-0000-00000000000' || n)::uuid, 'Wrong answer', false, 2
from generate_series(1, 5) n;

-- ---------------------------------------------------------------------------
-- The answer key is unreachable
-- ---------------------------------------------------------------------------

select pg_temp.act_as(:'alice');

-- Column privileges raise rather than filter, so these are checked by trapping
-- the exception. A silent empty result would mean the protection had been
-- replaced by something weaker.
do $$
begin
  begin
    perform is_correct from public.quiz_options limit 1;
    raise exception 'FAIL: advisor could read quiz_options.is_correct';
  exception when insufficient_privilege then
    raise notice 'pass: advisor cannot read quiz_options.is_correct';
  end;
end;
$$;

do $$
begin
  begin
    perform * from public.quiz_options limit 1;
    raise exception 'FAIL: select * on quiz_options leaked the answer key';
  exception when insufficient_privilege then
    raise notice 'pass: select * on quiz_options is refused';
  end;
end;
$$;

do $$
begin
  begin
    perform explanation from public.quiz_questions limit 1;
    raise exception 'FAIL: advisor could read a question explanation before passing';
  exception when insufficient_privilege then
    raise notice 'pass: advisor cannot read quiz_questions.explanation';
  end;
end;
$$;

-- The legitimate route must still work, or advisors could not sit a quiz.
select pg_temp.assert_eq(
  (select count(*) from public.quiz_options),
  10, 'advisor can read option text for an available quiz');

select pg_temp.assert_eq(
  (select count(*) from public.quiz_questions_for_attempt),
  10, 'advisor can read questions and options through the safe view');

-- ---------------------------------------------------------------------------
-- Content visibility follows the unlock, not just publication
-- ---------------------------------------------------------------------------

select pg_temp.assert_eq(
  (select count(*) from public.modules),
  1, 'advisor sees only the published module on their unlocked day');

select pg_temp.assert_eq(
  (select count(*) from public.modules where status = 'draft'),
  0, 'advisor never sees draft content');

select pg_temp.assert_eq(
  (select count(*) from public.lessons),
  2, 'advisor cannot read lessons belonging to a locked day');

-- ---------------------------------------------------------------------------
-- Self-scoring and self-unlocking
-- ---------------------------------------------------------------------------

select pg_temp.act_as_owner();

insert into public.quiz_attempts (enrolment_id, quiz_id, attempt_no, score, passed, submitted_at)
select e.id, :'quiz_d1', 1, 40, false, now()
from public.enrolments e where e.advisor_id = :'alice';

select pg_temp.act_as(:'alice');

with attempt as (
  update public.quiz_attempts set passed = true, score = 100 where passed = false returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 0,
  'advisor cannot mark their own failed attempt as passed');

with attempt as (
  update public.enrolment_days set status = 'unlocked' where day_number = 3 returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 0,
  'advisor cannot unlock a later programme day');

-- An INSERT blocked by WITH CHECK raises rather than filtering to zero rows,
-- so this one is checked by trapping the exception.
do $$
begin
  begin
    insert into public.module_progress (enrolment_id, module_id, status)
    select e.id, 'cccccccc-0000-0000-0000-000000000003', 'complete'
    from public.enrolments e
    where e.advisor_id = '11111111-1111-1111-1111-111111111111';
    raise exception 'FAIL: advisor was able to declare a module complete';
  exception when insufficient_privilege or check_violation then
    raise notice 'pass: advisor cannot declare a module complete';
  end;
end;
$$;

-- An advisor may record that they read a lesson; that is self-reported either
-- way and gates nothing on its own.
with attempt as (
  insert into public.lesson_progress (enrolment_id, lesson_id)
  select e.id, :'lesson_a' from public.enrolments e where e.advisor_id = :'alice'
  returning 1
)
select pg_temp.assert_eq((select count(*) from attempt), 1,
  'advisor can record that they read a lesson');

-- ---------------------------------------------------------------------------
-- The manager override refuses to run unattributed
-- ---------------------------------------------------------------------------

do $$
begin
  begin
    perform public.manager_unlock_day(
      (select id from public.enrolments where advisor_id = '11111111-1111-1111-1111-111111111111'),
      3, 'let me through');
    raise exception 'FAIL: an advisor was able to unlock their own day';
  exception when raise_exception then
    if position('manager or administrator' in sqlerrm) = 0 then raise; end if;
    raise notice 'pass: advisor cannot call manager_unlock_day';
  end;
end;
$$;

select pg_temp.act_as(:'manager');

do $$
begin
  begin
    perform public.manager_unlock_day(
      (select id from public.enrolments where advisor_id = '11111111-1111-1111-1111-111111111111'),
      3, '   ');
    raise exception 'FAIL: manager_unlock_day accepted a blank reason';
  exception when raise_exception then
    if position('reason is required' in sqlerrm) = 0 then raise; end if;
    raise notice 'pass: manager_unlock_day requires a reason';
  end;
end;
$$;

select public.manager_unlock_day(
  (select id from public.enrolments where advisor_id = :'alice'),
  3, 'Advisor sat the assessment offline while travelling');

select pg_temp.act_as_owner();

select pg_temp.assert_eq(
  (select count(*) from public.enrolment_days ed
   join public.enrolments e on e.id = ed.enrolment_id
   where e.advisor_id = :'alice' and ed.day_number = 3
     and ed.status = 'unlocked' and ed.unlocked_by_override),
  1, 'manager override unlocks the day and flags it as an override');

select pg_temp.assert_eq(
  (select count(*) from public.audit_log
   where action = 'manager_unlock_day'
     and reason = 'Advisor sat the assessment offline while travelling'),
  1, 'manager override writes an audit row carrying the reason');

rollback;
