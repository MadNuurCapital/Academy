# ATLAS Academy

**Advisor Training, Learning & Assessment System**

A 30-working-day onboarding programme for brand-new financial advisors. Each advisor moves
through **LEARN → PRACTISE → DEMONSTRATE → RECEIVE COACHING → READY FOR SUPERVISED
FIELDWORK**, ending in a recorded manager readiness decision.

The goal is a **competent beginner** ready for *supervised* client work — deliberately not
an independent certified advisor at Day 30.

---

## Status

**The application is functionally complete.** A manager enrols an advisor; the advisor
works through lessons and quizzes with the 80% gate enforced by the database; attendance is
marked daily in under a minute; coaching, fieldwork and practical assessment are recorded;
and the programme ends in a readiness decision with an explicit blocker checklist.

**All 30 days are written.** 30 modules, 37 lessons, 144 quiz questions, 6 scripts, 4
concept presentations with original diagrams, and the 12-criterion rubric — all as Draft,
pending compliance sign-off.

| Phase | Scope | Status |
|---|---|:--:|
| 1 | Foundation — auth, roles, schema, RLS, deployment | ✅ Done |
| 2 | Core training — enrolment, roadmap, modules, quizzes, advisor dashboard | ✅ Done |
| 3 | Attendance — daily marking, history, audit trail, make-up tasks | ✅ Done |
| 4 | Practical development — scripts, concepts, rubrics, coaching, fieldwork | ✅ Done |
| 5 | Reporting & readiness — reports, final assessments, readiness decision | ✅ Done |
| 6 | Content authoring — the 30 days of curriculum | ✅ Done |

**The administrator screens are not built.** `/admin/content`, `/admin/users`,
`/admin/holidays`, `/admin/scripts`, `/admin/concepts` and `/admin/audit` render a
placeholder; only `/admin/settings` is real. Those jobs — publishing content, creating
accounts, loading public holidays — are done with SQL in the Supabase dashboard, which is
workable because of how rarely they happen: publishing once, holidays once a year, accounts
around twenty a year. **[`LAUNCH.md`](LAUNCH.md) is the runbook** — browser only, no terminal, with the exact SQL
for each, all of it tested against the real schema.

---

## Quick start

```bash
git clone <this repository>
cd Academy
npm install
cp .env.example .env      # then fill in the two values — see below
npm run dev               # http://localhost:5173
```

The app will not start without valid Supabase credentials; it fails with a clear message
rather than a blank screen.

---

## Setting up Supabase

### 1. Get your project credentials

In your Supabase dashboard, go to **Project Settings → API** and copy:

| Value | Goes into |
|---|---|
| **Project URL** | `VITE_SUPABASE_URL` |
| **anon / public key** | `VITE_SUPABASE_ANON_KEY` |

Put both in your local `.env`. The anon key is public by design — it identifies the
project, not the user. Every permission is enforced by Row Level Security in the database.

> **Never put the `service_role` key in `.env` or anywhere under `src/`.** It bypasses all
> security policies. It belongs only in Netlify's environment variables, used by server-side
> functions.

### 2. Apply the migrations

**The quickest route needs no tooling at all.** `supabase/browser/` holds the same SQL
concatenated into seven files sized to paste into the Supabase dashboard's SQL Editor —
schema, curriculum, and an optional one that records the schema in the CLI's migration
ledger. [`LAUNCH.md`](LAUNCH.md) walks through it. The bundles are generated from the source
files by `./scripts/build-browser-sql.sh`; regenerate and commit them after changing
anything under `supabase/migrations/` or `supabase/seed/`.

With the [Supabase CLI](https://supabase.com/docs/guides/cli) instead:

```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

Either way you get every table, enum, trigger and RLS policy in `supabase/migrations/`,
applied in filename order — the two routes were compared against each other and produce an
identical database, including all 78 RLS assertions.

To develop against a local database instead:

```bash
supabase start           # local Postgres + Auth on Docker
supabase db reset        # apply all migrations from scratch
npm run db:types         # regenerate src/types/database.ts from the real schema
```

### 3. Create the first administrator

There are no hard-coded users and no seeded credentials. Bootstrap the first admin by hand:

1. In the Supabase dashboard, go to **Authentication → Users → Add user**. Enter an email
   and password, tick *Auto Confirm User*, and set `{"full_name": "Your Name"}` under User
   Metadata — without it the profile falls back to the part of the email before the `@`.
2. A `profiles` row is created automatically by a trigger.
3. Grant the admin role — **SQL Editor**, replacing the email:

```sql
insert into public.user_roles (user_id, role)
select id, 'admin' from public.profiles where email = 'you@example.com'
on conflict (user_id, role) do nothing;
```

Sign in. **Every subsequent account is created the same way** — the dashboard, then a role
grant. There is no user-management screen; see [`LAUNCH.md`](LAUNCH.md) step 9.

### 4. Configure auth redirect URLs

Under **Authentication → URL Configuration**, add your site URL and these redirects, so
invitation and password-reset links land in the right place:

```
http://localhost:5173/accept-invite
http://localhost:5173/reset-password
https://<your-site>.netlify.app/accept-invite
https://<your-site>.netlify.app/reset-password
```

---

## Deploying to Netlify

Connect the GitHub repository. Build settings come from `netlify.toml`, so nothing needs
setting by hand:

| Setting | Value |
|---|---|
| Build command | `npm run build` |
| Publish directory | `dist` |
| Node version | 20 |

Then add the environment variables under **Site settings → Environment variables**:

| Variable | Value |
|---|---|
| `VITE_SUPABASE_URL` | Your project URL |
| `VITE_SUPABASE_ANON_KEY` | Your anon key |

### Why refreshing a page works

Single-page applications commonly 404 when you refresh a deep URL or paste a direct link.
Two things prevent that here:

1. **`public/_redirects`** serves `index.html` with a **200** for every path, so
   `/manage/attendance` reaches React Router instead of Netlify's file system. The 200
   matters — a redirect would rewrite the address bar and lose the route.
2. **The auth guard never redirects while the session is still resolving.** It renders a
   loading state instead. Redirecting during that window is what causes the familiar flash
   of the login page followed by a bounce to the wrong screen.

Both are verified: every deep route returns 200 and serves the app shell.

---

## Commands

| Command | What it does |
|---|---|
| `npm run dev` | Development server on :5173 |
| `npm run build` | Typecheck, then production build to `dist/` |
| `npm run preview` | Serve the built bundle locally |
| `npm test` | Run the unit tests once |
| `npm run test:watch` | Unit tests in watch mode |
| `npm run test:rls` | Apply migrations to a scratch database and assert every RLS policy |
| `npm run typecheck` | TypeScript, no emit |
| `npm run lint` | ESLint |
| `npm run db:types` | Regenerate database types from a local Supabase |
| `./scripts/build-browser-sql.sh` | Rebuild the paste-into-the-dashboard SQL bundles |

---

## Project structure

```
src/
  auth/           AuthProvider, AuthContext, useAuth, ProtectedRoute
  components/
    layout/       AppShell + per-role layouts (advisor, manager, admin)
    ui/           Button, Field, Card, loading/empty/error states
  lib/
    workingDays.ts    The working-day engine — see below
    supabase.ts       Browser client (anon key only)
    cn.ts             Tailwind class merging
  api/            TanStack Query hooks, one module per domain
  pages/          Route components, grouped by role
  styles/
    theme.css     Every brand colour, in one file
  types/          Database types
supabase/
  migrations/     Ordered SQL — schema, then RLS
  seed/           Optional programme content
  browser/        The same SQL, bundled for pasting into the dashboard (generated)
  tests/          RLS assertions
```

---

## How progression works

Days unlock **sequentially**, with no date gate. Day N+1 opens the moment every required
module on Day N is complete and its quiz passed — whether that is today or next Tuesday. An
advisor who works quickly finishes early; one who is absent simply resumes where they left
off.

The rules that matter are enforced in the database, not the interface:

| Rule | Where it lives |
|---|---|
| 80% to pass, unlimited attempts | `submit_quiz_attempt`, reading `app_settings` |
| Failed quiz blocks the next day | `evaluate_day_completion` |
| Correct answers revealed only on a pass | `submit_quiz_attempt` returns `review` only when `passed` |
| Advisors cannot score themselves | No advisor UPDATE policy on `quiz_attempts` |
| Advisors cannot unlock their own days | No advisor write policy on `enrolment_days` |
| Manager override needs a reason | `manager_unlock_day` raises on a blank one, writes `audit_log` |

### Why the browser is never trusted with a quiz

Two failure modes drive the design, and both are invisible in the interface:

1. **The answer key.** If `quiz_options.is_correct` were readable, every quiz would be one
   API call away from being defeated, no matter what the screen renders. A **column-level
   privilege** — not RLS, not the UI — makes PostgreSQL refuse the read. Advisors can still
   read `option_text`, which they need in order to answer.
2. **The score.** If the client computed the score and posted it, someone would post 100.
   Scoring happens inside `submit_quiz_attempt`, which compares against the real answers,
   ignores any answer belonging to another quiz, and counts unanswered questions as wrong.

A guard at the end of migration 0008 fails loudly if a blanket table grant has undone the
column privilege — the failure mode is otherwise silent, and a stray
`grant select on all tables` in the SQL editor would expose every answer with nothing
visible to show it.

## Seed content

The files in `supabase/seed/` are **optional and idempotent**, and must be applied in
filename order — later files attach modules to programme days the first one creates:

```bash
for f in supabase/seed/*.sql; do psql -d <database> -f "$f"; done
```

| File | Contents |
|---|---|
| `01-programme.sql` | The 30-day programme skeleton, plus full content for Days 1–3 |
| `02-scripts-concepts-rubrics.sql` | Six scripts, four concept presentations, the 12-criterion rubric |
| `03-curriculum-protection.sql` | Days 4–5 — Hospitalisation, Personal Accident |
| `04-curriculum-foundations.sql` | Day 11 — Protection Comparison; Day 15 — CPF |
| `05-curriculum-protection-2.sql` | Days 6–10 — Term, Whole Life, Critical Illness, Cancer, CareShield |
| `06-curriculum-savings.sql` | Days 12–14, 16 — Endowment, ILP, case study, HDB |
| `07-curriculum-conversation.sql` | Days 17–22 — Prospecting through objection handling |
| `08-curriculum-practical.sql` | Days 23–27 — Role-plays, case study, joint fieldwork |
| `09-curriculum-assessment.sql` | Days 28–30 — Final assessments and readiness review |
| `99-publish-all.sql` | Optional bulk publish, **after** compliance review |

Everything lands as **Draft**. Nothing self-publishes.

Production does not depend on any of it. A fresh deployment works with no content at all,
and an administrator can author everything through the interface instead. The scripts
create no users and no credentials.

### Curriculum

| Days | Phase | Content |
|---|---|:--:|
| 1–3 | Advisor Foundations | ✅ |
| 4–11 | Protection Knowledge | ✅ |
| 12–16 | Singapore Financial Foundations | ✅ |
| 17–22 | Client Conversation Skills | ✅ |
| 23–27 | Practical Application | ✅ |
| 28–30 | Assessment & Readiness | ✅ |

Written to **product category** — no insurer, no premium, no policy wording, since those
vary and would be wrong within months. Adding the firm's actual product shelf is a
publishing decision, not a code change.

Deliberately absent: **Indexed Universal Life**, judged too advanced for a 30-day
programme. CPF and HDB sit under Singapore Financial Foundations and are never described
as insurance products. Day 18 is *Advisor Introduction & Value Pitch*, never a sales pitch.
Objection handling is taught as understanding the concern, never as overcoming resistance.

### Publishing

Everything seeds as **Draft**, so advisors see nothing until it is published — and
`evaluate_day_completion` treats a day with no published required module as *incomplete*,
so nobody is advanced past unreviewed content.

Publish module by module through the admin interface, which also produces the audit trail.
For a demo or test environment, or for bulk publishing *after* a review has actually
happened:

```bash
psql -d <database> -f supabase/seed/99-publish-all.sql
```

It is numbered 99 so a wholesale `seed/*.sql` loop runs it last, and so nobody applies it
by accident.

### ⚠️ CPF figures expire

Day 15 carries the 2026 retirement sums — **BRS $110,200, FRS $220,400, ERS $440,800** —
verified against cpf.gov.sg in July 2026. **These are revised every year.**

They live in the module's `terminology` rows precisely so that updating them each January is
a four-row edit in the admin interface rather than a rewrite of the lesson text.

## The working-day engine

`src/lib/workingDays.ts` is the single place the codebase converts between programme day
numbers and calendar dates. Roadmap generation, target end dates, drift, projected finish
and every report call into it. Nothing else does date arithmetic.

Two rules it enforces:

1. **A programme day is a working day** — Mon–Fri by default, minus Singapore public
   holidays held in an admin-editable table. Which weekdays count is configurable.
2. **Unlocking shifts, the target does not.** Day unlocking moves when an advisor is absent
   or paused, but the `target_end_date` fixed at enrolment never moves. The gap between them
   is *drift*, and drift is what the manager dashboard means by "behind schedule".

Dates are handled as plain `YYYY-MM-DD` strings, never `Date` objects with a time
component. Attendance on the 3rd of August is the 3rd of August regardless of server
timezone; a timestamp would let UTC conversion silently move it to the 2nd.

Covered by 53 unit tests including leap years, year boundaries, back-to-back holidays,
pauses spanning weekends, and enrolment on a non-working day.

---

## Security model

**Row Level Security is the real boundary.** Frontend role checks exist for the user
interface; a user who defeats them still cannot read a row the database policies forbid.

- RLS is enabled on every table, deny-by-default. No matching policy means no rows.
- Advisors read only their own records. They have **no write path at all** to attendance,
  scores, completion state or readiness decisions — not in the UI, not through a direct API
  call.
- Role lookups go through `security definer` functions with a pinned `search_path`, so a
  user cannot shadow `public.user_roles` to grant themselves a role.
- Managers and admins see all advisors. There is no coach role and no per-advisor
  assignment boundary.
- Private coaching notes (Phase 4) will be protected at the column level, not hidden in the
  UI.
- The service-role key never reaches the browser.
- Audit trail on attendance edits, manager overrides, quiz resets, content publishing and
  readiness decisions.
- No hard-coded users, no seeded production credentials, no secrets committed.

### Verified, not assumed

`supabase/tests/rls.test.sql` asserts the policies against a real database — 78 checks
covering read isolation, write restrictions, privilege escalation, draft-content
visibility, notification scoping, and every route by which an advisor might defeat the quiz
gate. Run with `npm run test:rls`; it exits non-zero if a migration widens access.

The runner applies Supabase's default privileges **before** the migrations, mirroring
production. Doing it the other way round — migrations first, then a blanket
`grant select on all tables` — silently re-grants the column privileges migration 0008
revokes, and the suite passes for the wrong reason.

A note for anyone extending it: `set local role` only takes effect **inside a transaction
block**. Outside one it is silently ignored, the query runs as superuser, RLS is bypassed
entirely, and every test passes for the wrong reason.

---

## Configuration, not code

Thresholds live in the `app_settings` table so an administrator can change them without a
deployment:

| Setting | Default | Note |
|---|---|---|
| `programme_length_days` | 30 | Working days |
| `working_weekdays` | Mon–Fri | ISO weekday numbers |
| `office_start_time` | 10:00 | Not yet finalised by the business |
| `late_after_time` | 10:15 | Not yet finalised |
| `quiz_pass_mark` | 80 | Percent |
| `attendance_target_pct` | 90 | Reported, but never blocks completion |
| `required_concept_presentations` | 2 | |
| `required_fieldwork_sessions` | 1 | An approved simulation counts |

---

## Branding

The lockup lives in one place, **`src/components/ui/Brand.tsx`** — the mark, `ATLAS Academy`,
and `Integrated Barakah Wealth Advisory` beneath. Both the app shell and the login screens
render that same component, so they cannot drift apart.

The mark is **rebuilt as SVG geometry**, not cropped from the supplied file. The original
artwork is kept at `docs/brand/atlas-academy-logo.jpg` as the reference; it is a JPEG on
baked-in white, which would show as a white square on any surface that is not white and
would go soft as soon as it scaled. Every rectangle in the component was measured off that
artwork, and the recreation was diffed against it pixel by pixel.

On a dark canvas the logo's own blue is unusable as interface colour — `#0e558b` scores
1.6:1 on navy — so the mark is **reversed** for dark, in a lifted `#8abee9` with the tan
square unchanged. Geometry is untouched; only the ink changes, which is what a reversed
lockup is. The positive version still sits on the favicon's white plate and in
`docs/brand/`.

---

## The console

The interface is a **dark command centre**: a navy field built from the brand blue rather
than from black, glass panels, a bento dashboard and mission-based progression.

All colour is CSS custom properties in **`src/styles/theme.css`** — canvas `#071a2b`
lifting to `#0b2740`, accent `#5aa4e0`, tan `#e7cf9f`, status colours lifted for dark.

Three rules hold it together, and each is written into the code where it applies:

1. **Glass never sits on glass.** `.panel` is translucent, so nesting one inside another
   makes contrast unknowable. Anything needing its own ground inside a panel uses the solid
   `bg-panel` token or the `Well` component. Because of that rule, every ratio in
   `theme.css` stays true — accent on a panel is 4.8:1, body text 11:1.
2. **The tan signals, it never speaks.** On white it managed 1.5:1 and could only ever be
   decoration; on this navy it reaches 8.5:1, so here it marks the current mission and the
   active nav item. It is still never body text, and a word always accompanies it.
3. **Motion is decoration on a layout that is already correct.** Under
   `prefers-reduced-motion: reduce` animations and transforms are removed outright rather
   than slowed, and nothing depends on an animation having run to become usable. Verified:
   24 animated elements become 0, and the layout is byte-identical either way.

`Card` is a re-export of `Panel`, which is what lets roughly thirty screens inherit the
console surface without being individually rewritten.

The two concept-presentation diagrams keep a **white plate** on the dark canvas. They are
drawn in front of a client in ink on paper-white, so re-colouring them for dark would leave
an advisor practising on something that looks nothing like what they will actually draw.

Mobile and desktop are both first-class. Advisors read lessons and check scripts on a
phone; managers mark attendance and score on a laptop. Sidebar on desktop, bottom tab bar
on mobile, 44px minimum touch targets throughout. The bento grid collapses to a single
column in source order, so the tiles are written in priority order.

---

## Contributing notes

- **Never** hard-code a threshold that belongs in `app_settings`.
- **Never** rely on a frontend check for a permission — add the RLS policy.
- Any new date arithmetic goes through `workingDays.ts`, with tests.
- Every screen needs explicit loading, empty and error states. Use the shared components in
  `src/components/ui/States.tsx`.
- Content is archived, never deleted, so historical completions stay meaningful.
