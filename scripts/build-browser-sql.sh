#!/usr/bin/env bash
#
# ATLAS Academy — regenerate the browser-paste SQL bundles.
#
# The migrations and seed files are the source of truth. supabase/browser/
# holds the same SQL concatenated into a handful of files sized to paste
# comfortably into the Supabase SQL Editor, so the whole database can be set up
# without installing anything.
#
# Run this after changing anything under supabase/migrations/ or supabase/seed/:
#
#   ./scripts/build-browser-sql.sh
#
# Then commit the regenerated bundles. They are checked in on purpose: the point
# is that someone can open them on GitHub and copy, with no tooling at all.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

python3 - <<'PY'
import glob, os

HEADER = """-- =========================================================================
-- ATLAS Academy — {title}
--
-- BUNDLE {n} OF {total}. Paste this whole file into the Supabase SQL Editor
-- and press Run. Run the bundles in numeric order; each one depends on the
-- ones before it.
--
-- This file is generated. Do not edit it by hand — edit the source files
-- listed below and regenerate with scripts/build-browser-sql.sh
--
-- Source files, concatenated in this order:
{files}
-- =========================================================================

"""


def bundle(sources, outpath, title, n, total):
    parts = [HEADER.format(title=title, n=n, total=total,
                           files='\n'.join('--   %s' % s for s in sources))]
    for s in sources:
        parts.append('\n\n-- ----------------------------------------------------------------------\n')
        parts.append('-- %s\n' % s)
        parts.append('-- ----------------------------------------------------------------------\n\n')
        parts.append(open(s).read())
    open(outpath, 'w').write(''.join(parts))
    return os.path.getsize(outpath)


migs = sorted(glob.glob('supabase/migrations/*.sql'))
seeds = sorted(glob.glob('supabase/seed/0*.sql'))

# Split only at file boundaries, keeping each bundle comfortably under 100 KB —
# large enough to keep the number of pastes small, small enough that a browser
# text editor does not struggle with it.
plan = [
    (migs[:7],   'supabase/browser/01-schema-part-1.sql',         'Schema, part 1 of 2'),
    (migs[7:],   'supabase/browser/02-schema-part-2.sql',         'Schema, part 2 of 2'),
    (seeds[:2],  'supabase/browser/03-programme-and-scripts.sql', 'Programme, scripts, concepts and rubrics'),
    (seeds[2:5], 'supabase/browser/04-curriculum-part-1.sql',     'Curriculum, part 1 of 3'),
    (seeds[5:7], 'supabase/browser/05-curriculum-part-2.sql',     'Curriculum, part 2 of 3'),
    (seeds[7:],  'supabase/browser/06-curriculum-part-3.sql',     'Curriculum, part 3 of 3'),
]

os.makedirs('supabase/browser', exist_ok=True)
for i, (srcs, out, title) in enumerate(plan, start=1):
    size = bundle(srcs, out, title, i, len(plan))
    print('%-46s %6.1f KB  (%d source files)' % (out, size / 1024, len(srcs)))

# The migration ledger. Pasting SQL bypasses the record the Supabase CLI keeps
# of what it has applied, so this writes that record by hand and keeps the two
# routes interchangeable.
rows = []
for f in migs:
    version, _, name = os.path.basename(f)[:-4].partition('_')
    rows.append("  ('%s', '%s')" % (version, name))

ledger = '''-- =========================================================================
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
%s
on conflict (version) do nothing;

-- Expect %d rows.
select count(*) as migrations_recorded from supabase_migrations.schema_migrations;
''' % (',\n'.join(rows), len(migs))

out = 'supabase/browser/07-record-migrations.sql'
open(out, 'w').write(ledger)
print('%-46s %6.1f KB  (%d migrations recorded)' % (out, os.path.getsize(out) / 1024, len(migs)))

# 08-repair.sql is hand-written rather than generated — it is a diagnostic, not
# a concatenation — so it is only reported here, to keep the listing complete.
repair = 'supabase/browser/08-repair.sql'
if os.path.exists(repair):
    print('%-46s %6.1f KB  (hand-written, not generated)' % (repair, os.path.getsize(repair) / 1024))
PY

echo "✓ Bundles regenerated. Commit supabase/browser/."
