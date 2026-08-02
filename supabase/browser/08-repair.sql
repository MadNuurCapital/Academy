-- =========================================================================
-- ATLAS Academy — repair: users that never appeared in the app
--
-- Safe to run at any time, as many times as you like. It only adds what is
-- missing and never deletes or overwrites anything.
--
-- WHAT THIS IS FOR
--
-- Someone appears in Supabase under Authentication → Users, but not in
-- ATLAS under Admin → Users.
--
-- The app does not read the auth table directly — it reads public.profiles,
-- and a trigger on auth.users is supposed to write a profile row the moment an
-- account is created. Three things can leave that row missing:
--
--   1. The account was created BEFORE the schema was applied, so the trigger
--      did not exist yet.
--   2. The trigger could not be created. auth.users is owned by Supabase's own
--      auth role, and creating a trigger on it needs ownership. This is the one
--      case the paste-the-SQL route can hit that the command-line route cannot.
--   3. The schema bundle reported an error that was missed.
--
-- This file handles all three: it backfills the missing profiles, puts the
-- trigger back if it is gone, and prints what it found either way.
--
-- Paste the whole file into the SQL Editor and press Run. Read the table at
-- the bottom.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. Backfill a profile for every account that is missing one.
--
-- Uses exactly the rule the trigger uses: the full_name from user metadata if
-- there is one, otherwise the part of the email before the @. You can correct
-- any of them afterwards in Admin → Users.
-- -------------------------------------------------------------------------

insert into public.profiles (id, full_name, email)
select
  u.id,
  coalesce(nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''), split_part(u.email, '@', 1)),
  u.email
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
  and u.email is not null
on conflict (id) do nothing;

-- -------------------------------------------------------------------------
-- 2. Put the trigger back if it is missing.
--
-- Wrapped so that a permissions failure reports itself rather than stopping
-- the file. If this cannot create the trigger, the backfill above is still a
-- complete workaround — you would just re-run this file after adding people.
-- -------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$fn$;

do $$
begin
  if exists (
    select 1 from pg_trigger
    where tgname = 'on_auth_user_created' and not tgisinternal
  ) then
    raise notice 'Trigger already present.';
  else
    begin
      execute 'create trigger on_auth_user_created
                 after insert on auth.users
                 for each row execute function public.handle_new_user()';
      raise notice 'Trigger created.';
    exception when others then
      raise notice 'COULD NOT CREATE THE TRIGGER: %', sqlerrm;
    end;
  end if;
end;
$$;

-- -------------------------------------------------------------------------
-- 3. The report.
--
-- Returned as rows rather than notices, because the SQL Editor shows results
-- reliably and hides notices.
-- -------------------------------------------------------------------------

select 'accounts in Supabase' as check, count(*)::text as value from auth.users
union all
select 'profiles in ATLAS', count(*)::text from public.profiles
union all
select 'still missing a profile',
       (select count(*)::text
        from auth.users u
        left join public.profiles p on p.id = u.id
        where p.id is null)
union all
select 'people with no role yet',
       (select count(*)::text
        from public.profiles p
        left join public.user_roles r on r.user_id = p.id
        where r.user_id is null)
union all
select 'profile-creation trigger',
       case when exists (
         select 1 from pg_trigger
         where tgname = 'on_auth_user_created' and not tgisinternal
       ) then 'installed — new accounts appear automatically'
       else 'MISSING — re-run this file after adding anyone, and tell Claude' end
union all
select 'what to do next',
       case
         when (select count(*) from auth.users u
               left join public.profiles p on p.id = u.id where p.id is null) > 0
           then 'Backfill did not take. Send Claude this whole table and any red error above.'
         when not exists (select 1 from pg_trigger
                          where tgname = 'on_auth_user_created' and not tgisinternal)
           then 'Everyone is in the app now, but re-run this file each time you add someone.'
         else 'Nothing. Everyone is in Admin → Users; set any missing roles there.'
       end;

-- Notes on reading the table above.
--
-- "still missing a profile" should be 0. If it is not, the backfill was
-- blocked — most likely you are running as a role that does not own
-- public.profiles, which has row-level security and no INSERT policy because
-- profiles are meant to be written by the trigger. Running this from the
-- Supabase SQL Editor avoids that, because the editor connects as the owner.
--
-- "people with no role yet" can sign in but will land on a no-access screen
-- until you switch a role on for them in Admin → Users.
