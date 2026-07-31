#!/usr/bin/env bash
#
# ATLAS Academy — run the Row Level Security test suite.
#
# Builds a scratch database, applies every migration in order, then runs the
# assertions in supabase/tests/rls.test.sql. Exits non-zero if any policy has
# regressed.
#
#   ./scripts/test-rls.sh
#
# Requires a running PostgreSQL 14+ and psql on PATH. Set PGDATABASE_ADMIN if
# your superuser connection differs from the default.

set -euo pipefail

DB_NAME="${ATLAS_TEST_DB:-atlas_rls_test}"
PSQL="${PSQL:-psql}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "→ Recreating scratch database ${DB_NAME}"
$PSQL -q -c "drop database if exists ${DB_NAME};" >/dev/null
$PSQL -q -c "create database ${DB_NAME};" >/dev/null

# Supabase supplies auth.users, auth.uid() and the authenticated role. Stub them
# so the migrations and tests run against plain PostgreSQL.
echo "→ Installing Supabase auth stubs"
$PSQL -q -v ON_ERROR_STOP=1 -d "${DB_NAME}" <<'SQL' >/dev/null
create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text,
  raw_user_meta_data jsonb default '{}'::jsonb
);

create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated;
  end if;
end;
$$;

grant usage on schema auth to authenticated;
SQL

echo "→ Applying migrations"
for migration in "${REPO_ROOT}"/supabase/migrations/*.sql; do
  echo "   $(basename "${migration}")"
  $PSQL -q -v ON_ERROR_STOP=1 -d "${DB_NAME}" -f "${migration}" >/dev/null
done

# Grants Supabase applies to the authenticated role by default. Without them the
# tests would fail on a missing grant rather than on the policy being checked.
$PSQL -q -v ON_ERROR_STOP=1 -d "${DB_NAME}" <<'SQL' >/dev/null
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
SQL

echo "→ Running RLS assertions"
if $PSQL -v ON_ERROR_STOP=1 -d "${DB_NAME}" \
     -f "${REPO_ROOT}/supabase/tests/rls.test.sql" 2>&1 |
     grep -E 'pass:|FAIL|ERROR'; then
  :
fi

# grep swallows the exit status, so re-run quietly to get psql's real result.
if $PSQL -q -v ON_ERROR_STOP=1 -d "${DB_NAME}" \
     -f "${REPO_ROOT}/supabase/tests/rls.test.sql" >/dev/null 2>&1; then
  echo "✓ All RLS assertions passed"
  $PSQL -q -c "drop database if exists ${DB_NAME};" >/dev/null
  exit 0
fi

echo "✗ RLS assertions FAILED — database ${DB_NAME} left in place for inspection"
exit 1
