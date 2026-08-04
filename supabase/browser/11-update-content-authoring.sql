-- =========================================================================
-- ATLAS Academy — update 2: content authoring
--
-- RUN THIS ON EVERY PROJECT, new or existing. Paste into the Supabase SQL
-- Editor and press Run.
--
-- Bundles 01 and 02 are the frozen launch baseline and do not contain this, so
-- a database that has only had those pasted into it still needs this file.
-- Applying it twice is harmless: it drops and recreates rather than assuming
-- what is already there.
--
-- Source: supabase/migrations/20260802000200_content_authoring.sql
-- This file is generated. See scripts/build-browser-sql.sh
-- =========================================================================

-- ATLAS Academy — let an author see the answer key
--
-- Managers have had write access to every content table since migration 0008.
-- What they have never had is READ access to two columns:
--
--   quiz_questions.explanation
--   quiz_options.is_correct
--
-- Those were revoked from the `authenticated` role by a column privilege, so
-- that an advisor sitting a quiz cannot fetch the answers no matter what they
-- send. The catch is that a manager is `authenticated` too — the grant is to the
-- role, not to the person — so the protection applies to the author as well.
-- The same trap caught coaching notes earlier in this project, and the fix there
-- was a separate table. Here a separate table would be wrong: is_correct belongs
-- with the option it describes.
--
-- So: a security-definer function, which runs as the owner and is therefore
-- unaffected by the column grants, with an explicit role check of its own. The
-- privilege stays revoked for everybody; this is the single, audited doorway
-- through it.

-- ---------------------------------------------------------------------------
-- FIRST, a latent bug in the shipped schema.
--
-- quiz_options carries a deferred constraint trigger that guarantees every
-- question keeps at least one correct option. To check that, it counts rows
-- `where is_correct` — and it was declared without `security definer`, so it
-- runs as whoever caused the write.
--
-- Which means it runs as `authenticated`, and `authenticated` cannot read
-- is_correct. Any attempt to write a quiz option from the application therefore
-- failed at COMMIT with "permission denied for table quiz_options", from inside
-- a trigger the author never called and cannot see.
--
-- Nobody had hit it because nothing had ever written a quiz option from the
-- client — the curriculum was loaded by pasting SQL as the owner. It surfaced
-- the moment an authoring screen was attempted, which is exactly when it would
-- have surfaced for a real author.
--
-- The trigger is redefined as security definer so it runs as the owner. That is
-- correct rather than merely convenient: it is an integrity check, not an access
-- decision, and it needs to see the data it is validating. It grants nobody any
-- new read: it returns a boolean verdict, never the column.
-- ---------------------------------------------------------------------------

create or replace function public.assert_question_has_correct_option()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
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

-- ---------------------------------------------------------------------------
-- quiz_for_authoring — the whole quiz, answers included
-- ---------------------------------------------------------------------------

create or replace function public.quiz_for_authoring(target_quiz_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  result jsonb;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may view quiz answers';
  end if;

  select jsonb_build_object(
    'quiz', to_jsonb(q) - 'created_at' - 'updated_at',
    'questions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', qq.id,
            'question_text', qq.question_text,
            'question_type', qq.question_type,
            'explanation', qq.explanation,
            'sequence', qq.sequence,
            'options', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', qo.id,
                    'option_text', qo.option_text,
                    'is_correct', qo.is_correct,
                    'sequence', qo.sequence
                  )
                  order by qo.sequence
                )
                from public.quiz_options qo
                where qo.question_id = qq.id
              ),
              '[]'::jsonb
            )
          )
          order by qq.sequence
        )
        from public.quiz_questions qq
        where qq.quiz_id = q.id
      ),
      '[]'::jsonb
    )
  )
  into result
  from public.quizzes q
  where q.id = target_quiz_id;

  if result is null then
    raise exception 'That quiz does not exist';
  end if;

  return result;
end;
$$;

-- ---------------------------------------------------------------------------
-- save_quiz_question — one question and all of its options, atomically
--
-- A question and its options are a single editable unit. Saving them as
-- separate statements from the browser risks a question whose options no longer
-- match it, or worse, a question left with no correct option at all — which the
-- deferred constraint in migration 0005 would reject on commit anyway, but only
-- after the earlier writes had landed in a half-applied state.
--
-- Options are replaced wholesale rather than diffed. A quiz question has four
-- options; reconciling them by identity would be more code and more ways to be
-- wrong than simply writing the set the author submitted.
-- ---------------------------------------------------------------------------

create or replace function public.save_quiz_question(
  target_quiz_id uuid,
  question_id uuid,
  question_text text,
  explanation text,
  sequence integer,
  options jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  saved_id uuid;
  correct_count integer;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may edit a quiz';
  end if;

  if question_text is null or length(trim(question_text)) = 0 then
    raise exception 'A question needs some text';
  end if;

  if jsonb_array_length(options) < 2 then
    raise exception 'A question needs at least two options';
  end if;

  select count(*) into correct_count
  from jsonb_array_elements(options) o
  where (o ->> 'is_correct')::boolean;

  -- Caught here as well as by the deferred constraint, because an error raised
  -- at save time can name the problem; a constraint violation on commit cannot.
  if correct_count = 0 then
    raise exception 'Mark one option as the correct answer';
  end if;
  if correct_count > 1 then
    raise exception 'Only one option may be marked correct';
  end if;

  if question_id is null then
    insert into public.quiz_questions (quiz_id, question_text, explanation, sequence)
    values (target_quiz_id, trim(question_text), nullif(trim(coalesce(explanation, '')), ''), sequence)
    returning id into saved_id;
  else
    update public.quiz_questions
    set question_text = trim(save_quiz_question.question_text),
        explanation = nullif(trim(coalesce(save_quiz_question.explanation, '')), ''),
        sequence = save_quiz_question.sequence
    where id = question_id
    returning id into saved_id;

    if saved_id is null then
      raise exception 'That question does not exist';
    end if;

    delete from public.quiz_options where public.quiz_options.question_id = saved_id;
  end if;

  insert into public.quiz_options (question_id, option_text, is_correct, sequence)
  select
    saved_id,
    trim(o ->> 'option_text'),
    (o ->> 'is_correct')::boolean,
    coalesce((o ->> 'sequence')::integer, ordinality::integer)
  from jsonb_array_elements(options) with ordinality as t(o, ordinality);

  insert into public.audit_log (actor_id, entity_type, entity_id, action, after)
  values (
    auth.uid(), 'quiz_question', saved_id,
    case when question_id is null then 'create_quiz_question' else 'update_quiz_question' end,
    jsonb_build_object('quiz_id', target_quiz_id, 'question_text', trim(question_text))
  );

  return saved_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- delete_quiz_question
-- ---------------------------------------------------------------------------

create or replace function public.delete_quiz_question(question_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  removed_text text;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may delete a quiz question';
  end if;

  select question_text into removed_text
  from public.quiz_questions where id = question_id;

  if removed_text is null then
    raise exception 'That question does not exist';
  end if;

  delete from public.quiz_questions where id = question_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, before)
  values (
    auth.uid(), 'quiz_question', question_id, 'delete_quiz_question',
    jsonb_build_object('question_text', removed_text)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- set_module_status — publish or return to draft, with an audit entry
--
-- Publishing is the moment content becomes visible to advisors, and it is the
-- record of a licensed advisor's review. It is worth a line in the audit log.
-- ---------------------------------------------------------------------------

create or replace function public.set_module_status(
  target_module_id uuid,
  new_status public.content_status
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status public.content_status;
  module_title text;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may publish content';
  end if;

  select status, title into previous_status, module_title
  from public.modules where id = target_module_id;

  if previous_status is null then
    raise exception 'That module does not exist';
  end if;

  update public.modules
  set status = new_status,
      last_reviewed_at = case when new_status = 'published' then current_date else last_reviewed_at end
  where id = target_module_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, before, after)
  values (
    auth.uid(), 'module', target_module_id, 'set_module_status',
    jsonb_build_object('status', previous_status, 'title', module_title),
    jsonb_build_object('status', new_status)
  );
end;
$$;

revoke all on function public.quiz_for_authoring(uuid) from public;
revoke all on function public.save_quiz_question(uuid, uuid, text, text, integer, jsonb) from public;
revoke all on function public.delete_quiz_question(uuid) from public;
revoke all on function public.set_module_status(uuid, public.content_status) from public;
grant execute on function public.quiz_for_authoring(uuid) to authenticated;
grant execute on function public.save_quiz_question(uuid, uuid, text, text, integer, jsonb) to authenticated;
grant execute on function public.delete_quiz_question(uuid) to authenticated;
grant execute on function public.set_module_status(uuid, public.content_status) to authenticated;

-- The column privilege must still be revoked. If a future migration ever grants
-- table-wide select on quiz_options, this fails loudly rather than silently
-- handing the answer key to every advisor.
do $$
begin
  if has_column_privilege('authenticated', 'public.quiz_options', 'is_correct', 'select') then
    raise exception 'Migration guard: authenticated can read quiz_options.is_correct. The authoring function exists precisely so that grant is not needed.';
  end if;
end;
$$;


-- ---------------------------------------------------------------------------
-- Record this update in the migration ledger, so that pasting SQL and
-- `supabase db push` stay interchangeable. Safe if you skipped bundle 07.
-- ---------------------------------------------------------------------------

create schema if not exists supabase_migrations;

create table if not exists supabase_migrations.schema_migrations (
  version text primary key,
  statements text[],
  name text
);

insert into supabase_migrations.schema_migrations (version, name)
values ('20260802000200', 'content_authoring')
on conflict (version) do nothing;
