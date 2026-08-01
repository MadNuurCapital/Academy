-- ATLAS Academy — publish all seed content
--
-- ⚠️  DO NOT RUN THIS UNTIL THE CONTENT HAS BEEN REVIEWED AND APPROVED.
--
-- Every module, script and concept in the seed set is created as `draft`, on
-- purpose. Statements about suitability, disclosure and advice standards need
-- approval from someone with MAS/FAA accountability before an advisor learns
-- from them, and a seed script cannot provide that.
--
-- Until something is published, advisors cannot see it — the RLS policies in
-- migration 0008 restrict them to published content — and
-- evaluate_day_completion treats a day with no published required module as
-- INCOMPLETE rather than complete, so nobody is advanced past content that has
-- not been signed off.
--
-- The normal route is to review and publish through the admin interface, module
-- by module, which is also what produces a sensible audit trail. This file
-- exists for two narrower purposes:
--
--   * standing up a demonstration or test environment quickly; and
--   * publishing in bulk AFTER a review has actually happened, when clicking
--     through thirty modules would serve no one.
--
-- Usage:
--
--   psql -d <database> -f supabase/seed/99-publish-all.sql
--
-- It is deliberately NOT numbered in the 01-09 range, so a loop over
-- `supabase/seed/*.sql` in filename order will run it last — and anyone
-- applying the seed set wholesale should know they are doing so.

begin;

do $$
declare
  module_count integer;
  script_count integer;
  concept_count integer;
begin
  update public.modules
  set status = 'published', last_reviewed_at = current_date
  where status = 'draft';
  get diagnostics module_count = row_count;

  update public.scripts
  set status = 'published', approved_at = now()
  where status = 'draft';
  get diagnostics script_count = row_count;

  update public.concept_presentations
  set status = 'published'
  where status = 'draft';
  get diagnostics concept_count = row_count;

  raise notice 'Published % modules, % scripts, % concept presentations.',
    module_count, script_count, concept_count;
  raise notice 'This content is now visible to advisors. Confirm the compliance review actually took place.';
end;
$$;

commit;
