# Launching ATLAS Academy

**Everything here is done in a web browser.** No terminal, nothing to install, no Node, no
Git, no Supabase CLI. Two tabs — Supabase and Netlify — and this page.

Every step ends with something you can check, and a line telling you what to do when that
check fails.

Allow about **90 minutes**, plus however long your content review takes. You can stop after
step 7 with a working site and come back to the content later.

---

## Why there is no terminal

The command line only ever did two things here: run the app on your own laptop before it was
live, and apply the database schema.

The first is optional — Netlify gives you the real site within the hour, which is a better
thing to look at anyway.

The second turned out not to need it. The schema is just SQL, and Supabase has a SQL editor
built into its dashboard. So the twelve migration files and the nine curriculum files have
been concatenated into **seven files you paste in**, in `supabase/browser/`. Same SQL, same
order, same result.

That is not a shortcut with a cost attached — it removes one. `supabase db push` against a
hosted project was the single step in this whole build that had never been run and could not
be tested here. Pasting SQL into an editor is something you can watch succeed or fail one
bundle at a time.

**Proof rather than assurance:** the seven bundles were applied to a clean database in order,
and the result was compared against the command-line route. Identical — 39 tables, 30 days,
30 modules, 37 lessons, 144 questions, 576 options, 6 scripts, 4 concept presentations, 12
rubric criteria. The full security suite, all 78 assertions, passes on the browser-built
schema exactly as it does on the other one. The quiz answer key is unreadable to advisors
either way.

---

## Before you start

**Read this, because it changes how you plan the work.**

Everything an advisor or a manager touches day to day is a real screen. The advisor journey
is complete, and so is every manager screen — attendance, enrolment, the review queue,
coaching, fieldwork, readiness decisions and reports.

**The administrator screens are not built.** `/admin/content`, `/admin/users`,
`/admin/holidays`, `/admin/scripts`, `/admin/concepts` and `/admin/audit` render a
"Not built yet" placeholder. Only `/admin/settings` is real.

So the administrative jobs here — publishing content, creating accounts, loading public
holidays — are done with SQL in the same editor. That is workable because of how rarely they
happen: publishing once, holidays once a year, accounts around twenty a year. It is not
elegant. It is written down precisely so it does not depend on anyone remembering it.

Every SQL snippet below has been run against the real schema. Copy them as they are.

---

## How to copy a file from GitHub

You will do this seven times, so here it is once.

1. Open the repository: <https://github.com/MadNuurCapital/Academy>
2. Switch the branch selector to **`claude/atlas-academy-planning-vgf3ym`**.
3. Navigate to the file, for example `supabase/browser/01-schema-part-1.sql`.
4. Click the **copy icon** at the top right of the file view — the two overlapping squares.
   That copies the whole file, however long it is.

Then paste it into the Supabase SQL Editor and press **Run**.

> **If the copy icon is not there**, click **Raw**, then select all (Ctrl-A / ⌘-A) and copy.

---

## Step 1 — Create the Supabase project

Sign up at [supabase.com](https://supabase.com) and create a project.

- **Region: Singapore.** Your users are there, and it keeps the data in-country.
- **Database password:** it generates one. Save it in a password manager. You do not need it
  for anything in this guide, but you will want it one day and it is not shown again.
- Wait for provisioning to finish. Two or three minutes.

> **The check:** the project dashboard loads and the left sidebar shows Table Editor, SQL
> Editor, Authentication and so on.

---

## Step 2 — Paste in the schema

Dashboard → **SQL Editor** → **New query**.

Copy each of these from GitHub, paste, press **Run**, wait for *Success*, then clear the
editor and do the next one. **In this order:**

| # | File | What it creates |
|---|---|---|
| 1 | `supabase/browser/01-schema-part-1.sql` | Tables, roles, enrolments, security policies |
| 2 | `supabase/browser/02-schema-part-2.sql` | Progression, attendance, practical, readiness |

Each takes a few seconds. Order matters — the second depends on the first.

Then, **optionally**, run `supabase/browser/07-record-migrations.sql`. It does nothing for
the app; it tells the Supabase command-line tool that this schema is already applied, so that
if anyone ever does use the CLI on this project it does not try to apply everything twice.
Thirty seconds now, saves a confusing failure later.

> **The check:** Table Editor now lists **39 tables**, including `profiles`, `enrolments`,
> `modules`, `quiz_options` and `coaching_private_notes`.
>
> **If a bundle errors partway**, do not patch it and carry on. Delete the project and start
> again from step 1 — it takes three minutes, and a half-applied schema is far more painful
> to unpick than a fresh project is to create.

---

## Step 3 — Create your own account and make yourself administrator

There are no seeded users and no default password anywhere in this repository. The first
account is created by hand.

1. Dashboard → **Authentication → Users → Add user → Create new user**
2. Enter your email and a password.
3. Tick **Auto Confirm User** — without it you cannot sign in until you click an email link.
4. **Create user.** That is everything. If you see a user-metadata box, ignore it.

A trigger creates the matching profile row automatically. Because you did not supply a name,
it falls back to the part of your email before the `@` — so you will appear as "evo.inub"
until you fix it, which takes two clicks in **Admin → Users** once you are signed in.

Then grant yourself the admin role. **SQL Editor**, replacing the email:

```sql
insert into public.user_roles (user_id, role)
select id, 'admin' from public.profiles where email = 'you@example.com'
on conflict (user_id, role) do nothing;
```

> **The check:**
>
> ```sql
> select p.email, p.full_name, r.role
> from public.user_roles r
> join public.profiles p on p.id = r.user_id;
> ```
>
> One row, showing your name and `admin`.
>
> **If it returns nothing:** the email did not match. Run `select email from public.profiles;`
> to see what was actually stored, and use that.

---

## Step 4 — Paste in the curriculum

Same routine as step 2. Four files, in order:

| # | File | What it loads |
|---|---|---|
| 3 | `supabase/browser/03-programme-and-scripts.sql` | The 30-day programme, 6 scripts, 4 concept presentations, the 12-criterion rubric |
| 4 | `supabase/browser/04-curriculum-part-1.sql` | Foundations and protection |
| 5 | `supabase/browser/05-curriculum-part-2.sql` | Savings, investment and client conversation |
| 6 | `supabase/browser/06-curriculum-part-3.sql` | Practical and assessment |

Order is not a suggestion — later files depend on rows the earlier ones create, and they
carry guards that stop with a clear message rather than leaving the database half-loaded.

> **The check:**
>
> ```sql
> select
>   (select count(*) from public.programme_days)   as days,       -- 30
>   (select count(*) from public.modules)          as modules,    -- 30
>   (select count(*) from public.lessons)          as lessons,    -- 37
>   (select count(*) from public.quiz_questions)   as questions,  -- 144
>   (select count(*) from public.quiz_options)     as options,    -- 576
>   (select count(*) from public.scripts)          as scripts,    -- 6
>   (select count(*) from public.concept_presentations) as concepts; -- 4
> ```
>
> All seven numbers should match the comments exactly.
>
> **If a file errors** with *"Run supabase/seed/01-programme.sql first"*, you have run them
> out of order. Go back to bundle 3 — the guards exist to stop a half-loaded curriculum, and
> re-running one that already succeeded is harmless.

---

## Step 5 — Load the public holidays

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

> **The check:**
>
> ```sql
> select holiday_date, to_char(holiday_date, 'Dy') as day, name
> from public.public_holidays order by holiday_date;
> ```
>
> Every row should fall on a weekday. A Saturday or Sunday in that list means you have
> entered a nominal date rather than the observed one, and it will silently do nothing.

---

## Step 6 — Review the content, then publish it

Everything loaded in step 4 is **Draft**. Advisors cannot see draft content — the RLS
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
of these at once — every remaining module, script and concept presentation. Copy it from
GitHub the same way as the bundles. It exists for after the review, not instead of it.

> **The check:**
>
> ```sql
> select 'modules' as kind,
>        count(*) filter (where status = 'draft')     as still_draft,
>        count(*) filter (where status = 'published') as published
> from public.modules
> union all
> select 'scripts', count(*) filter (where status = 'draft'), count(*) filter (where status = 'published')
> from public.scripts
> union all
> select 'concepts', count(*) filter (where status = 'draft'), count(*) filter (where status = 'published')
> from public.concept_presentations;
> ```

You can launch with only the first week published and keep reviewing ahead of the advisors —
they cannot reach Day 6 in week one anyway.

> **If an advisor reports an empty day:** that day's modules are still Draft. It is this
> step, not a bug.

---

## Step 7 — Configure the authentication URLs

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

> **The check:** on the sign-on screen choose *Forgotten your password?*, enter your own
> address, and confirm the email that arrives links back to your site rather than to a
> Supabase error page.
>
> **If the link errors:** the redirect URL must match the live domain exactly, including
> `https://` and with no trailing slash.

---

## Step 8 — Deploy to Netlify

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

Then **Deploy site**. The first build takes two to three minutes.

> **The check:** open your site, land on the sign-on screen, and sign in with the admin
> account from step 2. Then refresh the page on a deep URL such as `/manage/attendance` — it
> should reload the screen, not 404.
>
> **If the build fails**, open the deploy log in Netlify. `Missing Supabase configuration`
> means the two environment variables are not set, or were added after the build started —
> add them, then **Trigger deploy → Clear cache and deploy site**.
>
> **If the site loads but sign-in fails**, the variables are set but wrong. They are on one
> page in Supabase: Project Settings → API.

---

## Step 9 — Create the managers and advisors

This is the step you will repeat — but only the account creation part. Everything else now
lives in the app.

1. **Authentication → Users → Add user**. Email, password, tick **Auto Confirm User**, create.
2. Sign in to ATLAS as an admin and open **Admin → Users**. The new person is in the list.
   Set their name, and switch on Advisor, Manager or Admin. Roles are additive — one person
   can be both.

That is it. The SQL below is kept only for the case where you are setting up several people
at once and would rather do it in one statement, or where you have somehow locked yourself
out of the admin screen:

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

> **The check:**
>
> ```sql
> select p.full_name, p.email, r.role
> from public.profiles p
> left join public.user_roles r on r.user_id = p.id
> order by r.role, p.full_name;
> ```
>
> Every person you created appears, with a role. Anyone showing a null role can sign in but
> will land on a "no access" screen — that is the symptom of a missed role grant.

---

## Step 10 — Enrol the first advisor

This one is a real screen. Sign in as a manager or admin → **Enrol** (`/manage/enrol`).

Pick the advisor, pick a start date, optionally label the intake ("August 2026" — used for
grouping reports only). Before you commit, the screen shows you which date becomes Day 1 and
which date is the Day 30 target. If your chosen date is a weekend or a public holiday, Day 1
moves to the next working day and the screen says so.

The dates are recomputed on the server when you submit. A browser cannot supply a flattering
target date, which is what makes "behind schedule" mean anything.

> **The check:** the advisor appears on `/manage/advisors` at Day 1 of 30, and signing in as
> them shows Day 1 unlocked with everything after it locked.
>
> **If the advisor is not in the dropdown:** they are already enrolled, or they do not hold
> the `advisor` role. Step 8.
>
> **If it says no published programme template is available:** step 3 did not finish.

---

## Step 11 — Smoke test before anyone real arrives

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

**"No published programme template is available"** on the enrol screen — bundle 3 in step 4
did not complete. Paste it again.

**An advisor sees an empty Day 1** — the modules for that day are still Draft. Step 6.

**An advisor is told they are behind on a public holiday** — the holiday is missing from
`public_holidays`. Step 5.

**Someone signs in and lands on "no access"** — they have an account but no role. Step 9.

**A password-reset link opens an error page** — the redirect URLs in step 7 are missing or do
not match the live domain exactly.

**You created someone in Supabase but they are not in Admin → Users** — their profile row is
missing. Paste `supabase/browser/08-repair.sql` into the SQL Editor and run it. It backfills
every missing profile, puts the profile-creation trigger back if it has gone, and prints a
table saying what it found. Safe to run as often as you like.

**You sign in and land on "Your account is missing its profile"** — same thing, same fix.

**A printed readiness report comes out blank or pale** — your browser is set to skip
background graphics. It should not matter: the report is designed to print as ink on white
with no backgrounds at all. If it does not, tell me, because that is a bug in the stylesheet
rather than in your printer settings.

---

## What is not built

For the record, so nobody hunts for a screen that does not exist:

| Route | Status | How the job gets done instead |
|---|---|---|
| `/admin/content` | Placeholder | Publish with SQL — step 6 |
| `/admin/users` | Placeholder | Supabase dashboard + SQL — step 9 |
| `/admin/holidays` | Placeholder | SQL — step 5 |
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
