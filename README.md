# ATLAS Academy

**Advisor Training, Learning & Assessment System**

A 30-working-day onboarding programme for brand-new financial advisors. Each advisor moves
through **LEARN → PRACTISE → DEMONSTRATE → RECEIVE COACHING → READY FOR SUPERVISED
FIELDWORK**, ending in a recorded manager readiness decision.

The goal is a **competent beginner** ready for *supervised* client work — deliberately not
an independent certified advisor at Day 30.

---

## Status

**Phase 1 of 6 complete.** Foundation only: authentication, roles, route guards, database
schema, Row Level Security, the working-day engine, and deployment configuration.

Every route from the specification is registered and permission-guarded, but screens
arriving in later phases render a placeholder. This is deliberate — it lets navigation,
role guards and direct-URL refresh be verified before the features exist.

| Phase | Scope | Status |
|---|---|:--:|
| 1 | Foundation — auth, roles, schema, RLS, deployment | ✅ Done |
| 2 | Core training — enrolment, roadmap, modules, quizzes, advisor dashboard | ⬜ |
| 3 | Attendance — daily marking, history, audit trail, make-up tasks | ⬜ |
| 4 | Practical development — scripts, concepts, rubrics, coaching, fieldwork | ⬜ |
| 5 | Reporting & readiness — reports, final assessments, readiness decision | ⬜ |
| 6 | Content authoring — the 30 days of seed content | ⬜ |

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

Install the [Supabase CLI](https://supabase.com/docs/guides/cli), then:

```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

This creates every table, enum, trigger and RLS policy in `supabase/migrations/`, applied
in filename order.

To develop against a local database instead:

```bash
supabase start           # local Postgres + Auth on Docker
supabase db reset        # apply all migrations from scratch
npm run db:types         # regenerate src/types/database.ts from the real schema
```

### 3. Create the first administrator

There are no hard-coded users and no seeded credentials. Bootstrap the first admin by hand:

1. In the Supabase dashboard, go to **Authentication → Users → Add user**. Enter an email
   and password, and tick *Auto Confirm User*.
2. A `profiles` row is created automatically by a trigger.
3. Grant the admin role — **SQL Editor**, replacing the email:

```sql
insert into public.user_roles (user_id, role)
select id, 'admin' from public.profiles where email = 'you@example.com';
```

Sign in. Every subsequent user is created through the application.

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
  pages/          Route components, grouped by role
  styles/
    theme.css     Every brand colour, in one file
  types/          Database types
supabase/
  migrations/     Ordered SQL — schema, then RLS
```

---

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

`supabase/tests/rls.test.sql` asserts the policies against a real database — 27 checks
covering read isolation, write restrictions, privilege escalation, draft-content visibility
and notification scoping. Run with `npm run test:rls`; it exits non-zero if a migration
widens access.

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

All colours are CSS custom properties in **`src/styles/theme.css`** — the only file to edit
when the MadNuur Capital palette arrives. The current palette is a restrained placeholder:
deep slate with a single teal accent.

Mobile and desktop are both first-class. Advisors read lessons and check scripts on a
phone; managers mark attendance and score on a laptop. Sidebar on desktop, bottom tab bar
on mobile, 44px minimum touch targets throughout.

---

## Contributing notes

- **Never** hard-code a threshold that belongs in `app_settings`.
- **Never** rely on a frontend check for a permission — add the RLS policy.
- Any new date arithmetic goes through `workingDays.ts`, with tests.
- Every screen needs explicit loading, empty and error states. Use the shared components in
  `src/components/ui/States.tsx`.
- Content is archived, never deleted, so historical completions stay meaningful.
