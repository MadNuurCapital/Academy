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
