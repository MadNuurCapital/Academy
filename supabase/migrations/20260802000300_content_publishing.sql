-- ATLAS Academy — publish a script or a concept presentation
--
-- Managers have been able to write to `scripts` and `concept_presentations`
-- since migration 0011, and the ordinary policies are enough for editing the
-- wording. Publishing is different in kind: it is the moment a form of words
-- becomes something a new advisor will say to a member of the public, and the
-- record that a licensed advisor read it first.
--
-- So it goes through a function that writes an audit entry, exactly as
-- set_module_status does. The status column itself is still writable by a
-- manager directly — this is not a security boundary and does not pretend to
-- be. It is the difference between a change that is logged and one that is not,
-- and the application always takes the logged route.

create or replace function public.set_script_status(
  target_script_id uuid,
  new_status public.content_status
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status public.content_status;
  script_title text;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may publish a script';
  end if;

  select status, title into previous_status, script_title
  from public.scripts where id = target_script_id;

  if previous_status is null then
    raise exception 'That script does not exist';
  end if;

  update public.scripts
  set status = new_status,
      -- approved_at records when the wording was last cleared for use. Returning
      -- a script to draft leaves the old timestamp alone: it is a historical
      -- fact about a past approval, not a claim about the current state.
      approved_at = case when new_status = 'published' then now() else approved_at end
  where id = target_script_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, before, after)
  values (
    auth.uid(), 'script', target_script_id, 'set_script_status',
    jsonb_build_object('status', previous_status, 'title', script_title),
    jsonb_build_object('status', new_status)
  );
end;
$$;

create or replace function public.set_concept_status(
  target_concept_id uuid,
  new_status public.content_status
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status public.content_status;
  concept_name text;
begin
  if not public.is_manager_or_admin() then
    raise exception 'Only a manager or administrator may publish a concept presentation';
  end if;

  select status, name into previous_status, concept_name
  from public.concept_presentations where id = target_concept_id;

  if previous_status is null then
    raise exception 'That concept presentation does not exist';
  end if;

  update public.concept_presentations
  set status = new_status
  where id = target_concept_id;

  insert into public.audit_log (actor_id, entity_type, entity_id, action, before, after)
  values (
    auth.uid(), 'concept_presentation', target_concept_id, 'set_concept_status',
    jsonb_build_object('status', previous_status, 'name', concept_name),
    jsonb_build_object('status', new_status)
  );
end;
$$;

revoke all on function public.set_script_status(uuid, public.content_status) from public;
revoke all on function public.set_concept_status(uuid, public.content_status) from public;
grant execute on function public.set_script_status(uuid, public.content_status) to authenticated;
grant execute on function public.set_concept_status(uuid, public.content_status) to authenticated;
