-- =========================================================================
-- ATLAS Academy — record the schema in the migration ledger
--
-- OPTIONAL. Nothing in the application depends on this, and you can skip it.
--
-- Run it only if you set the database up by pasting the bundles in
-- supabase/browser/ rather than with `supabase db push`.
--
-- The Supabase CLI keeps a ledger of which migrations it has applied. Pasting
-- SQL into the dashboard bypasses that ledger, so the CLI still believes the
-- database is empty. If anyone later runs `supabase db push` against this
-- project, it will try to apply all twelve migrations again — over a schema
-- that already has them — and fail partway through.
--
-- This tells the ledger the truth, so the browser route and the CLI route stay
-- interchangeable. Run it once, after the two schema bundles.
--
-- This file is generated. See scripts/build-browser-sql.sh
-- =========================================================================

create schema if not exists supabase_migrations;

create table if not exists supabase_migrations.schema_migrations (
  version text primary key,
  statements text[],
  name text
);

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260731000100', 'extensions_and_enums'),
  ('20260731000200', 'identity_and_settings'),
  ('20260731000300', 'enrolments'),
  ('20260731000400', 'rls'),
  ('20260731000500', 'content'),
  ('20260731000600', 'progress'),
  ('20260731000700', 'progression'),
  ('20260731000800', 'content_rls'),
  ('20260731000900', 'attendance'),
  ('20260731001000', 'practical'),
  ('20260731001100', 'practical_rls'),
  ('20260731001200', 'readiness')
on conflict (version) do nothing;

-- Expect 12 rows.
select count(*) as migrations_recorded from supabase_migrations.schema_migrations;
