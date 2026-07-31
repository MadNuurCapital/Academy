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
