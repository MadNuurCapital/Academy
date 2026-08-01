# Launching ATLAS Academy

A step-by-step runbook for taking this from a repository to advisors logging in. Follow it
in order — each step depends on the one before, and each ends with a way to check it
actually worked.

Allow about two hours for steps 1–7, plus however long your content review takes.

---

## Before you start

**Read this first, because it changes how you plan the work.**

Everything an advisor or a manager touches day to day is a real screen. The advisor journey
is complete, and so is every manager screen — attendance, enrolment, the review queue,
coaching, fieldwork, readiness decisions and reports.

**The administrator screens are not built.** `/admin/content`, `/admin/users`,
`/admin/holidays`, `/admin/scripts`, `/admin/concepts` and `/admin/audit` currently render a
"Not built yet" placeholder. Only `/admin/settings` is real.

So the administrative jobs in this runbook — publishing content, creating accounts, loading
public holidays — are done with SQL in the Supabase dashboard's SQL Editor. That is
workable because of how rarely they happen: publishing is once, holidays once a year,
accounts around twenty a year. It is not elegant. It is written down here precisely so it
does not depend on anyone remembering it.

Every SQL snippet below has been run against the real schema. Copy them as they are.

---

## Step 1 — Create the Supabase project and apply the schema

Create a project at [supabase.com](https://supabase.com). Choose **Singapore** as the
region: it is where your users are, and it keeps the data in-country.

Install the [Supabase CLI](https://supabase.com/docs/guides/cli), then from the repository
root:

```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

That applies the twelve files in `supabase/migrations/` in filename order — every table,
enum, trigger, function and Row Level Security policy.

> ⚠️ **Do this against a throwaway project first.** The migrations themselves are tested
> thoroughly against PostgreSQL, but `supabase db push` talking to a *hosted* project is the
> one step never exercised during development, because Docker was not available in the build
> environment. Push to a scratch project, confirm it completes, then delete it and do the
> real one. Ten minutes now against a two-hour recovery later.

**Check it worked:** Dashboard → Table Editor. You should see roughly forty tables including
`profiles`, `enrolments`, `modules`, `quiz_options` and `coaching_private_notes`.

---

## Step 2 — Create your own account and make yourself administrator

There are no seeded users and no default password anywhere in this repository. The first
account is created by hand.

1. Dashboard → **Authentication → Users → Add user → Create new user**
2. Enter your email and a password.
3. Tick **Auto Confirm User** — without it you cannot sign in until you click an email link.
4. Expand **User Metadata** and add:
   ```json
   { "full_name": "Your Name" }
   ```
   This matters. A trigger creates the matching `profiles` row automatically, and if
   `full_name` is missing it falls back to the part of your email before the `@` — so you
   would appear throughout the app as "evo.inub". Set it for every account you create.

Then grant yourself the admin role. Dashboard → **SQL Editor**, replacing the email:

```sql
insert into public.user_roles (user_id, role)
select id, 'admin' from public.profiles where email = 'you@example.com'
on conflict (user_id, role) do nothing;
```

**Check it worked:**

```sql
select p.email, p.full_name, r.role
from public.user_roles r
join public.profiles p on p.id = r.user_id;
```

One row, showing your name and `admin`.

---

## Step 3 — Load the curriculum

In the SQL Editor, run these files **in numeric order**, one at a time, pasting the contents
of each:

```
supabase/seed/01-programme.sql
supabase/seed/02-scripts-concepts-rubrics.sql
supabase/seed/03-curriculum-protection.sql
supabase/seed/04-curriculum-foundations.sql
supabase/seed/05-curriculum-protection-2.sql
supabase/seed/06-curriculum-savings.sql
supabase/seed/07-curriculum-conversation.sql
supabase/seed/08-curriculum-practical.sql
supabase/seed/09-curriculum-assessment.sql
```

Order is not a suggestion — the later files depend on rows the earlier ones create, and they
carry guards that stop with a clear message rather than leaving the database half-loaded.

Do **not** run `99-publish-all.sql` yet. That is step 5.

**Check it worked:**

```sql
select
  (select count(*) from public.programme_days)   as days,       -- 30
  (select count(*) from public.modules)          as modules,    -- 30
  (select count(*) from public.lessons)          as lessons,    -- 37
  (select count(*) from public.quiz_questions)   as questions,  -- 144
  (select count(*) from public.quiz_options)     as options,    -- 576
  (select count(*) from public.scripts)          as scripts,    -- 6
  (select count(*) from public.concept_presentations) as concepts; -- 4
```

All seven numbers should match the comments exactly.

---

## Step 4 — Load the public holidays

**Nothing is seeded here, and the programme will be wrong without it.** The entire schedule
is counted in working days. With no holidays loaded, the system treats Chinese New Year as
two ordinary training days, expects attendance, and tells the advisor they are behind.

What matters is the **observed** date — the day nobody is in the office. Where a holiday
falls on a Sunday, Singapore takes the Monday in lieu, and it is that Monday that belongs in
this table. Holidays landing on a Saturday need no entry at all: the working week here is
Monday to Friday, so Saturday is already excluded.

The 2026 list, with the three Sunday holidays entered as their Monday in lieu:

```sql
insert into public.public_holidays (holiday_date, name) values
  ('2026-01-01', 'New Year''s Day'),
  ('2026-02-17', 'Chinese New Year'),
  ('2026-02-18', 'Chinese New Year'),
  ('2026-04-03', 'Good Friday'),
  ('2026-05-01', 'Labour Day'),
  ('2026-05-27', 'Hari Raya Haji'),
  ('2026-06-01', 'Vesak Day (in lieu of Sun 31 May)'),
  ('2026-08-10', 'National Day (in lieu of Sun 9 Aug)'),
  ('2026-11-09', 'Deepavali (in lieu of Sun 8 Nov)'),
  ('2026-12-25', 'Christmas Day')
on conflict (holiday_date) do nothing;
```

Hari Raya Puasa 2026 falls on Saturday 21 March and so is deliberately absent — it costs no
working day. If your office grants a day off in lieu, add that day instead.

⚠️ **Check these against MOM before running.** Hari Raya Puasa and Hari Raya Haji follow
moon sighting and can shift; the rest move year to year anyway. The authority is
[MOM's published list](https://www.mom.gov.sg/employment-practices/public-holidays), also
available as an [open dataset on data.gov.sg](https://data.gov.sg/datasets/d_149b61ad0a22f61c09dc80f2df5bbec8/view).

Put a note in your calendar for each December to add the following year's list.

**Check it worked:**

```sql
select holiday_date, name from public.public_holidays order by holiday_date;
```

---

## Step 5 — Review the content, then publish it

Everything loaded in step 3 is **Draft**. Advisors cannot see draft content — the RLS
policies stop it at the database, and a day whose required module is unpublished counts as
incomplete rather than complete, so nobody gets advanced past material you have not cleared.

You are the licensed advisor releasing this to new joiners, so the review is yours. Read
each module before publishing it.

**Publish one day at a time as you clear it:**

```sql
update public.modules m
set status = 'published', last_reviewed_at = current_date
from public.programme_days pd
where pd.id = m.programme_day_id
  and pd.day_number = 1;          -- change the day number each time
```

**See what is left:**

```sql
select pd.day_number, m.title, m.status
from public.modules m
join public.programme_days pd on pd.id = m.programme_day_id
order by pd.day_number, m.sequence;
```

**The scripts and concept presentations publish separately.** They are not tied to a day, so
the per-day statement above does not touch them — and an advisor with an unpublished script
library sees an empty Scripts page from Day 1. Publish them once you have read the six
scripts and four concept presentations:

```sql
update public.scripts set status = 'published', approved_at = now() where status = 'draft';
update public.concept_presentations set status = 'published' where status = 'draft';
```

**Once you have reviewed the whole set**, `supabase/seed/99-publish-all.sql` does all three
of these at once — every remaining module, script and concept presentation. It exists for
after the review, not instead of it.

**Check it worked:**

```sql
select 'modules' as kind,
       count(*) filter (where status = 'draft')     as still_draft,
       count(*) filter (where status = 'published') as published
from public.modules
union all
select 'scripts', count(*) filter (where status = 'draft'), count(*) filter (where status = 'published')
from public.scripts
union all
select 'concepts', count(*) filter (where status = 'draft'), count(*) filter (where status = 'published')
from public.concept_presentations;
```

You can launch with only the first week published and keep reviewing ahead of the advisors —
they cannot reach Day 6 in week one anyway.

---

## Step 6 — Configure the authentication URLs

Dashboard → **Authentication → URL Configuration**. Set the **Site URL** to your live domain,
and add all four of these as **Redirect URLs**:

```
http://localhost:5173/accept-invite
http://localhost:5173/reset-password
https://<your-site>.netlify.app/accept-invite
https://<your-site>.netlify.app/reset-password
```

Miss these and password-reset links land on an error page instead of the app. Include the
localhost pair so you can still test locally.

---

## Step 7 — Deploy to Netlify

Connect the GitHub repository in Netlify. Build command, publish directory, Node version,
security headers and the single-page-app redirect all come from `netlify.toml`, so leave the
build settings alone.

Add two variables under **Site settings → Environment variables**:

| Variable | Where to find it |
|---|---|
| `VITE_SUPABASE_URL` | Supabase → Project Settings → API → Project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase → Project Settings → API → anon / public key |

The anon key is public by design — it names the project, not the user, and every permission
is enforced by Row Level Security in the database.

> 🔒 **The `service_role` key never leaves the Supabase dashboard.** It bypasses every
> security policy in the system. Nothing in this application uses it, nothing needs it, and
> it must never be pasted into Netlify, into `.env`, or into any file under `src/`. Anything
> prefixed `VITE_` is compiled into the JavaScript every visitor downloads.

Deploy. **Check it worked:** open your site, land on the login screen, sign in with the
admin account from step 2. Then refresh the page on a deep URL such as
`/manage/attendance` — it should reload the screen, not 404.

---

## Step 8 — Create the managers and advisors

This is the step you will repeat. Same as step 2:

1. **Authentication → Users → Add user**, tick Auto Confirm, set `full_name` in User Metadata.
2. Grant the role:

```sql
-- One manager
insert into public.user_roles (user_id, role)
select id, 'manager' from public.profiles where email = 'manager@example.com'
on conflict (user_id, role) do nothing;

-- Several advisors at once
insert into public.user_roles (user_id, role)
select id, 'advisor' from public.profiles
where email in ('advisor1@example.com', 'advisor2@example.com')
on conflict (user_id, role) do nothing;
```

Roles are `advisor`, `manager` and `admin`. One person can hold more than one — grant both
rows if a manager also needs to see the advisor view.

Give each person their password directly and have them change it, or send them to
**Forgotten your password?** on the login screen to set their own.

**Check it worked:**

```sql
select p.full_name, p.email, r.role
from public.profiles p
left join public.user_roles r on r.user_id = p.id
order by r.role, p.full_name;
```

Anyone showing a null role can sign in but will land on a "no access" screen.

---

## Step 9 — Enrol the first advisor

This one is a real screen. Sign in as a manager or admin → **Enrol** (`/manage/enrol`).

Pick the advisor, pick a start date, optionally label the intake ("August 2026" — used for
grouping reports only). Before you commit, the screen shows you which date becomes Day 1 and
which date is the Day 30 target. If your chosen date is a weekend or a public holiday, Day 1
moves to the next working day and the screen says so.

The dates are recomputed on the server when you submit. A browser cannot supply a flattering
target date, which is what makes "behind schedule" mean anything.

**Check it worked:** the advisor appears on `/manage/advisors` with Day 1 of 30, and signing
in as them shows Day 1 unlocked and everything after it locked.

---

## Step 10 — Smoke test before anyone real arrives

Sign in as each of the three roles and confirm:

- **Advisor** — sees Day 1 only; can open a lesson, mark it read, take the quiz. Try
  answering badly: below 80% it should refuse to pass and offer another attempt.
- **Manager** — `/manage/attendance` lists today's advisors with Present / Late / Absent.
  Mark one and confirm it saves.
- **Admin** — `/admin/settings` loads and the values are editable.

Then open the site on a phone. Advisors will read lessons on a phone far more than on a
laptop, and that is the layout worth trusting your own eyes on.

---

## Before the first intake

Three things only you can decide:

1. **Office arrival time.** `/admin/settings` currently holds a placeholder of `10:00`,
   recorded as "not yet finalised by the business". It determines who is marked Late. Set it
   to whatever you actually expect.

2. **The other thresholds.** Also in `/admin/settings`: the 80% quiz pass mark, and how many
   days of drift count as "needs attention" versus "behind". The defaults are reasonable;
   they are yours to change.

3. **The CPF figures.** Day 15 teaches the Basic, Full and Enhanced Retirement Sums using the
   2026 figures. These are revised every January. They are stored as editable `terminology`
   rows rather than baked into lesson text, so correcting them is one update statement —
   but nothing will remind you. Check them each January.

---

## When something goes wrong

**"No published programme template is available"** on the enrol screen — step 3 did not
complete. Re-run `01-programme.sql`.

**An advisor sees an empty Day 1** — the modules for that day are still Draft. Step 5.

**An advisor is told they are behind on a public holiday** — the holiday is missing from
`public_holidays`. Step 4.

**Someone signs in and lands on "no access"** — they have an account but no role. Step 8.

**A password-reset link opens an error page** — the redirect URLs in step 6 are missing or do
not match the live domain exactly.

---

## What is not built

For the record, so nobody hunts for a screen that does not exist:

| Route | Status | How the job gets done instead |
|---|---|---|
| `/admin/content` | Placeholder | Publish with SQL — step 5 |
| `/admin/users` | Placeholder | Supabase dashboard + SQL — step 8 |
| `/admin/holidays` | Placeholder | SQL — step 4 |
| `/admin/scripts` | Placeholder | Seeded; edit with SQL |
| `/admin/concepts` | Placeholder | Seeded; edit with SQL |
| `/admin/audit` | Placeholder | Query `public.audit_log` directly |
| `/admin/settings` | **Built** | — |

Creating accounts from inside the browser is the one of these that cannot simply be built as
another screen: it needs a server-side function holding the `service_role` key, since
creating an auth user is a privileged operation. That is a deliberate piece of work with real
security weight attached, not an afternoon's wiring.

Run one intake on this runbook first. You will know by the end of it which of these you
actually want, rather than guessing now.
