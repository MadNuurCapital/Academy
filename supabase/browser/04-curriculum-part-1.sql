-- =========================================================================
-- ATLAS Academy — Curriculum, part 1 of 3
--
-- BUNDLE 4 OF 6. Paste this whole file into the Supabase SQL Editor
-- and press Run. Run the bundles in numeric order; each one depends on the
-- ones before it.
--
-- This file is generated. Do not edit it by hand — edit the source files
-- listed below and regenerate with scripts/build-browser-sql.sh
--
-- Source files, concatenated in this order:
--   supabase/seed/03-curriculum-protection.sql
--   supabase/seed/04-curriculum-foundations.sql
--   supabase/seed/05-curriculum-protection-2.sql
-- =========================================================================



-- ----------------------------------------------------------------------
-- supabase/seed/03-curriculum-protection.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — seed: Phase 2 curriculum, Days 4 to 11 (Protection Knowledge)
--
-- Optional and idempotent. Everything lands as `draft`.
--
-- Written to PRODUCT CATEGORY, never to a named product. No insurer is
-- mentioned, no premium is quoted and no specific policy wording is described,
-- because those vary by insurer and by year and would be wrong within months.
-- Integrated Barakah Wealth Advisory's actual product shelf is layered on top of
-- this by whoever publishes it.
--
-- Each module follows the agreed product template: what need it addresses, who
-- may benefit, who may not, how it works, benefits, limitations, exclusions,
-- risks, comparison with related categories, and when it may be unsuitable.
--
-- COMPLIANCE: every statement here about suitability, disclosure and advice
-- standards needs approval by someone with MAS/FAA accountability before
-- publishing.

begin;

-- Helper: attach a module to a numbered day of the default template.
-- This file depends on 01-programme.sql having created the template and its
-- thirty days. Seed files are applied in filename order for that reason; the
-- check below turns a confusing not-null violation into a clear instruction.
do $$
begin
  if not exists (
    select 1 from public.programme_days
    where template_id = '0a715000-0000-4000-8000-000000000001'
  ) then
    raise exception
      'Run supabase/seed/01-programme.sql first — this file attaches modules to programme days that do not exist yet.';
  end if;
end;
$$;

create or replace function pg_temp.day_id(n integer) returns uuid
language sql stable as $$
  select id from public.programme_days
  where template_id = '0a715000-0000-4000-8000-000000000001' and day_number = n;
$$;

-- ===========================================================================
-- DAY 4 — Hospitalisation
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values (
  '0f000004-0000-4000-8000-000000000001', pg_temp.day_id(4),
  'Hospitalisation Cover', 'protection',
  'What hospitalisation cover pays for, what it does not, and why almost every client conversation starts here.',
  '["Explain what hospitalisation cover pays for in plain language","Describe the main limitations and common exclusions","Explain why it is usually addressed before other protection"]'::jsonb,
  45, true, 1, 'draft'
) on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000004-1000-4000-8000-000000000001', '0f000004-0000-4000-8000-000000000001',
 'What hospitalisation cover does',
 'Hospitalisation cover pays medical bills arising from being admitted to hospital.

That is the need it addresses: a large, unpredictable bill arriving at a moment when the person is least able to deal with it.

WHY IT USUALLY COMES FIRST

Of everything in a financial plan, this is the gap most likely to be tested, and the one where the consequences arrive fastest.

Serious illness is more common than serious accident. A hospital stay can produce a bill in days that would take years to save. And unlike most financial problems, it arrives without warning and while the person is unwell.

A client with no hospitalisation cover and a well-funded investment portfolio has their priorities in an unusual order. Part of your job is to notice that.

HOW IT GENERALLY WORKS

The client is admitted to hospital. The insurer pays some or all of the eligible bill, subject to the limits and conditions of the plan.

Three mechanics matter, and clients routinely misunderstand all three.

**The deductible.** An amount the client pays before the insurer pays anything. It resets, usually annually.

**Co-insurance.** A percentage of the remaining bill that the client pays. This is the one that surprises people — they assume "covered" means "paid in full", and on a large bill the percentage is a real amount of money.

**Ward or hospital class.** Most plans are priced around a level of accommodation. Being treated above that level does not usually void the claim, but it can reduce what is paid substantially.

WHAT IT DOES NOT COVER

Outpatient treatment that does not involve admission, in most cases.

Anything cosmetic or elective.

Pre-existing conditions, usually — either excluded outright or subject to a waiting period. This is the single most important thing to establish before recommending anything, and it is why the medical questions on an application are not a formality.

Loss of income while unable to work. Hospitalisation cover pays the hospital. It does not pay the mortgage. Clients conflate these constantly.

WHAT TO SAY

"Hospitalisation cover pays the hospital bill. It does not replace your income while you are unable to work, and it does not pay you a lump sum for being ill — those are different things, and we should look at whether you need them separately."',
 1, 15),
('0f000004-1000-4000-8000-000000000002', '0f000004-0000-4000-8000-000000000001',
 'Limitations, exclusions and honest conversations',
 'The conversations that go wrong are the ones where a client believed they were covered for something they were not.

Almost always, that belief was formed at the point of sale.

PRE-EXISTING CONDITIONS

If a client has been treated for something, investigated for something, or has symptoms they have not yet had looked at, it must be declared.

Advisors sometimes soften this, because a full declaration can mean an exclusion, a higher premium or a decline. That instinct is understandable and it is seriously wrong. A non-disclosed condition can void a claim years later, at the worst possible moment, and the client will remember exactly who told them not to worry about it.

Say instead: "Declare everything, including things you think are trivial. An exclusion you know about is far better than a claim that fails."

WAITING PERIODS

Most plans do not pay for certain conditions in the first months of cover. A client who takes out a policy and is admitted six weeks later may find they are not covered.

Say it before they buy, not after.

THE RIDER QUESTION

Many clients hold a rider that reduces the deductible and co-insurance. Riders change over time, and the amount a client pays out of pocket can change with them.

For a new advisor, the correct position is: understand that riders affect what the client pays, establish what the client currently has, and escalate the detail to a senior advisor. Do not guess at how a specific rider behaves.

WHAT AN HONEST EXPLANATION SOUNDS LIKE

"This covers your hospital bill, subject to a deductible and a share of the cost that you pay. If you go above the ward class the plan is built around, you may pay considerably more. Anything you have already been treated for probably will not be covered unless we declare it and it is accepted. Shall we go through your medical history properly?"

Nobody has ever complained about being told the truth clearly at the outset.',
 2, 14)
on conflict (id) do nothing;

insert into public.terminology (module_id, term, definition, sequence) values
('0f000004-0000-4000-8000-000000000001', 'Deductible', 'The amount the client pays before the insurer pays anything. Usually resets each policy year.', 1),
('0f000004-0000-4000-8000-000000000001', 'Co-insurance', 'A percentage of the remaining bill the client pays after the deductible. On a large bill this is a substantial sum.', 2),
('0f000004-0000-4000-8000-000000000001', 'Pre-existing condition', 'A condition that existed, was treated or showed symptoms before cover began. Usually excluded unless declared and accepted.', 3),
('0f000004-0000-4000-8000-000000000001', 'Waiting period', 'A period after cover starts during which certain conditions are not covered.', 4)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000004-2000-4000-8000-000000000001', '0f000004-0000-4000-8000-000000000001', 'Day 4 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000004-3000-4000-8000-000000000001', '0f000004-2000-4000-8000-000000000001',
 'A client says "I have hospitalisation cover, so I am fine if I get seriously ill." What is missing from that?', 'scenario',
 'Hospitalisation cover pays the hospital. It does not replace income and does not pay a lump sum on diagnosis. Clients conflate these constantly, and it is the advisor''s job to separate them.', 1),
('0f000004-3000-4000-8000-000000000002', '0f000004-2000-4000-8000-000000000001',
 'A client mentions they saw a doctor about chest pain two years ago but "it was nothing". What should you do?', 'scenario',
 'It must be declared. A non-disclosed condition can void a claim years later. An exclusion the client knows about is far better than a claim that fails when they need it.', 2),
('0f000004-3000-4000-8000-000000000003', '0f000004-2000-4000-8000-000000000001',
 'What does co-insurance mean?', 'mcq',
 'A percentage of the remaining bill that the client pays after the deductible. On a large bill this is a meaningful amount, and clients routinely assume "covered" means "paid in full".', 3),
('0f000004-3000-4000-8000-000000000004', '0f000004-2000-4000-8000-000000000001',
 'A client asks exactly how their existing rider affects what they would pay. You have not been trained on riders. What is the correct response?', 'scenario',
 'Riders vary and change over time. Escalate rather than guess. Guessing at a figure the client may act on is the failure mode this programme exists to prevent.', 4),
('0f000004-3000-4000-8000-000000000005', '0f000004-2000-4000-8000-000000000001',
 'Why is hospitalisation usually addressed before investment?', 'mcq',
 'It is the gap most likely to be tested and the one where consequences arrive fastest, without warning and while the client is unwell.', 5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000004-3000-4000-8000-000000000001', 'It pays the hospital bill but does not replace lost income or pay a lump sum on diagnosis', true, 1),
('0f000004-3000-4000-8000-000000000001', 'Nothing — that is broadly correct', false, 2),
('0f000004-3000-4000-8000-000000000001', 'It only applies to accidents, not illness', false, 3),
('0f000004-3000-4000-8000-000000000001', 'It covers outpatient treatment as well', false, 4),

('0f000004-3000-4000-8000-000000000002', 'Declare it fully on the application, even though it may lead to an exclusion', true, 1),
('0f000004-3000-4000-8000-000000000002', 'Leave it out, since nothing was diagnosed', false, 2),
('0f000004-3000-4000-8000-000000000002', 'Mention it only if the insurer asks a specific question about chest pain', false, 3),
('0f000004-3000-4000-8000-000000000002', 'Advise them to wait two more years and then apply', false, 4),

('0f000004-3000-4000-8000-000000000003', 'A percentage of the remaining bill that the client pays after the deductible', true, 1),
('0f000004-3000-4000-8000-000000000003', 'The total amount the insurer will pay in a year', false, 2),
('0f000004-3000-4000-8000-000000000003', 'The premium shared between the client and their employer', false, 3),
('0f000004-3000-4000-8000-000000000003', 'The waiting period before cover begins', false, 4),

('0f000004-3000-4000-8000-000000000004', 'Tell them you want to give an accurate answer and will check with a senior advisor', true, 1),
('0f000004-3000-4000-8000-000000000004', 'Give your best estimate and say it is approximate', false, 2),
('0f000004-3000-4000-8000-000000000004', 'Tell them riders are too complicated to explain', false, 3),
('0f000004-3000-4000-8000-000000000004', 'Suggest they call the insurer themselves', false, 4),

('0f000004-3000-4000-8000-000000000005', 'The consequences arrive fastest and without warning, while the client is least able to deal with them', true, 1),
('0f000004-3000-4000-8000-000000000005', 'It is more profitable for the advisor', false, 2),
('0f000004-3000-4000-8000-000000000005', 'Regulations require it to be sold first', false, 3),
('0f000004-3000-4000-8000-000000000005', 'Investment products require a longer application', false, 4)
on conflict do nothing;

-- ===========================================================================
-- DAY 5 — Personal Accident
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values (
  '0f000005-0000-4000-8000-000000000001', pg_temp.day_id(5),
  'Personal Accident Cover', 'protection',
  'A narrow cover that is easy to over-recommend because it is inexpensive.',
  '["Explain that personal accident covers accidents and not illness","Identify clients for whom it is a poor first recommendation","Read exclusions carefully for clients with hazardous activities"]'::jsonb,
  40, true, 1, 'draft'
) on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000005-1000-4000-8000-000000000001', '0f000005-0000-4000-8000-000000000001',
 'Accidents, not illness',
 'Personal accident cover pays out when injury results from an accident. The word doing all the work is "accident".

WHAT COUNTS AS AN ACCIDENT

Sudden, external, unintended. A fall. A road collision. A burn.

WHAT DOES NOT

Illness of any kind, however suddenly it arrives. A heart attack is not an accident. A stroke is not an accident. A cancer diagnosis is not an accident.

This is the single most common client misunderstanding in this category. You will correct it in almost every conversation where personal accident comes up, and if you do not correct it, the client is walking away believing they have bought something they have not.

WHAT IT TYPICALLY COVERS

Accidental death. Permanent disablement, usually on a scale where the amount depends on the severity. Medical reimbursement for treating the injury. Sometimes a weekly benefit while the person cannot work as a result.

COMMON EXCLUSIONS

Injuries sustained while intoxicated. While committing an offence. During certain hazardous activities.

And, importantly in Singapore, while riding a motorcycle — often excluded or restricted unless specifically added. For a client who rides to work daily, that is not a detail.

WHY IT IS EASY TO OVER-RECOMMEND

Personal accident cover is usually inexpensive relative to what it pays out. That makes it attractive, and it makes it easy to add to a recommendation without asking whether it is the right thing.

It addresses a narrow risk. A client with no hospitalisation cover, no income protection and no critical illness cover does not have their most serious gaps filled by buying personal accident cover, however affordable it is.

Recommend it for what it is: targeted cover for accidental injury, usually alongside broader protection rather than instead of it.',
 1, 13),
('0f000005-1000-4000-8000-000000000002', '0f000005-0000-4000-8000-000000000001',
 'When it is the wrong first recommendation',
 'Four situations where personal accident cover is a poor place to start.

THE CLIENT WITH NO HOSPITALISATION COVER

Fix the larger gap first. Illness is statistically far more likely to produce a serious claim than accidental injury, and the bills are larger.

THE CLIENT WHOSE EMPLOYER ALREADY PROVIDES IT

Many employers include personal accident cover in group benefits. Check before recommending. Duplicating cover the client already holds is not advice — it is a sale.

THE CLIENT WHO WANTS "SOMETHING CHEAP"

Affordability is a real constraint and deserves respect. But a cheap policy addressing a risk the client is not especially exposed to is not good value. It is a small amount of money spent on the wrong thing, and it can leave the client believing they are protected when they are not.

THE CLIENT WITH A DANGEROUS OCCUPATION OR HOBBY

Counter-intuitively, this is where you must read the exclusions most carefully. The activity creating the exposure is very often the activity the policy excludes. A client who rides a motorcycle, works at height or dives at weekends may find precisely their risk written out.

WHAT TO SAY

"Personal accident cover is genuinely useful, but it only pays out for accidents — not illness. Before we look at it, I would like to understand what you have in place for hospitalisation and for a serious illness, because those are usually the bigger exposures. Can we start there?"

That sentence is honest, it is compliant, and it demonstrates that you are working from the client''s situation rather than from a product.',
 2, 12)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000005-2000-4000-8000-000000000001', '0f000005-0000-4000-8000-000000000001', 'Day 5 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000005-3000-4000-8000-000000000001', '0f000005-2000-4000-8000-000000000001',
 'A client asks whether their personal accident policy would pay out if they had a heart attack. What is the correct answer?', 'scenario',
 'A heart attack is an illness, not an accident, however sudden. This is the distinction clients most often get wrong in this category.', 1),
('0f000005-3000-4000-8000-000000000002', '0f000005-2000-4000-8000-000000000001',
 'Which client is personal accident cover LEAST suitable for as a first recommendation?', 'mcq',
 'Someone with no hospitalisation or critical illness cover has larger gaps. Filling a narrow one first leaves the serious exposures open.', 2),
('0f000005-3000-4000-8000-000000000003', '0f000005-2000-4000-8000-000000000001',
 'Why must exclusions be read especially carefully for a client with a hazardous hobby?', 'scenario',
 'The activity creating the exposure is very often the activity the policy excludes.', 3),
('0f000005-3000-4000-8000-000000000004', '0f000005-2000-4000-8000-000000000001',
 'A client says their employer provides personal accident cover. What should you do?', 'scenario',
 'Establish what the existing cover actually provides before recommending anything further. Duplicating cover the client already has is not advice.', 4),
('0f000005-3000-4000-8000-000000000005', '0f000005-2000-4000-8000-000000000001',
 'Personal accident cover is inexpensive relative to its payout. Why is that a risk for an advisor?', 'mcq',
 'Affordability makes it easy to add without asking whether it is the right thing, and can leave a client believing they are protected against risks it does not cover.', 5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000005-3000-4000-8000-000000000001', 'No — a heart attack is an illness, not an accident, so it falls outside this cover', true, 1),
('0f000005-3000-4000-8000-000000000001', 'Yes, provided it resulted in hospitalisation', false, 2),
('0f000005-3000-4000-8000-000000000001', 'Yes, if it happened at work', false, 3),
('0f000005-3000-4000-8000-000000000001', 'It depends on whether they had a pre-existing condition', false, 4),

('0f000005-3000-4000-8000-000000000002', 'A client with no hospitalisation or critical illness cover at all', true, 1),
('0f000005-3000-4000-8000-000000000002', 'A client who cycles to work daily', false, 2),
('0f000005-3000-4000-8000-000000000002', 'A client with comprehensive health cover already in place', false, 3),
('0f000005-3000-4000-8000-000000000002', 'A self-employed tradesperson with existing hospitalisation cover', false, 4),

('0f000005-3000-4000-8000-000000000003', 'The activity creating the exposure is often the activity the policy excludes', true, 1),
('0f000005-3000-4000-8000-000000000003', 'Premiums are calculated differently for hazardous activities', false, 2),
('0f000005-3000-4000-8000-000000000003', 'The client will need a longer waiting period', false, 3),
('0f000005-3000-4000-8000-000000000003', 'Underwriting takes longer for these clients', false, 4),

('0f000005-3000-4000-8000-000000000004', 'Find out what it actually covers before recommending anything further', true, 1),
('0f000005-3000-4000-8000-000000000004', 'Recommend more, since employer cover is always insufficient', false, 2),
('0f000005-3000-4000-8000-000000000004', 'Move on — this need is met', false, 3),
('0f000005-3000-4000-8000-000000000004', 'Advise them to opt out of the employer scheme', false, 4),

('0f000005-3000-4000-8000-000000000005', 'It is easy to add without asking whether it addresses the client''s real exposure', true, 1),
('0f000005-3000-4000-8000-000000000005', 'Cheap policies are more likely to be declined', false, 2),
('0f000005-3000-4000-8000-000000000005', 'It pays lower commission', false, 3),
('0f000005-3000-4000-8000-000000000005', 'It requires more underwriting', false, 4)
on conflict do nothing;

commit;


-- ----------------------------------------------------------------------
-- supabase/seed/04-curriculum-foundations.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — seed: Day 11 (Protection Comparison) and Day 15 (CPF)
--
-- These two days were called out specifically in the requirements. Day 11 is
-- where an advisor learns the distinctions between categories that clients
-- routinely conflate; Day 15 carries figures that change annually and must be
-- maintained.
--
-- CPF AND HDB ARE NOT INSURANCE PRODUCTS and are never described as such. They
-- sit under "Singapore Financial Foundations".
--
-- FIGURES IN THIS FILE ARE FOR 2026 AND EXPIRE. The retirement sums below were
-- taken from cpf.gov.sg in July 2026. They are revised every year. An
-- administrator must verify and update them each January — the terminology
-- entries at the end of the CPF module exist to make that a five-minute edit
-- rather than a content rewrite.

begin;

-- This file depends on 01-programme.sql having created the template and its
-- thirty days. Seed files are applied in filename order for that reason; the
-- check below turns a confusing not-null violation into a clear instruction.
do $$
begin
  if not exists (
    select 1 from public.programme_days
    where template_id = '0a715000-0000-4000-8000-000000000001'
  ) then
    raise exception
      'Run supabase/seed/01-programme.sql first — this file attaches modules to programme days that do not exist yet.';
  end if;
end;
$$;

create or replace function pg_temp.day_id(n integer) returns uuid
language sql stable as $$
  select id from public.programme_days
  where template_id = '0a715000-0000-4000-8000-000000000001' and day_number = n;
$$;

-- ===========================================================================
-- DAY 11 — Protection Comparison
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values (
  '0f000011-0000-4000-8000-000000000001', pg_temp.day_id(11),
  'What Each Category Does Not Cover', 'protection',
  'The distinctions clients get wrong, and how to correct them without sounding pedantic.',
  '["Distinguish hospitalisation from critical illness","Distinguish critical illness from cancer-specific cover","Distinguish term from whole life","Explain what each category does not cover"]'::jsonb,
  50, true, 1, 'draft'
) on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000011-1000-4000-8000-000000000001', '0f000011-0000-4000-8000-000000000001',
 'Hospitalisation versus critical illness',
 'These two are confused more often than any other pair, and the confusion matters because they solve different problems.

HOSPITALISATION COVER PAYS THE HOSPITAL

It reimburses medical bills. The money goes towards treatment. If the client is treated and discharged, the cover has done its job.

CRITICAL ILLNESS COVER PAYS THE CLIENT

On diagnosis of a defined condition at a defined severity, it pays a lump sum. The client can spend it on anything: the mortgage, replacing lost income, a carer, adapting the house, or a holiday. Nobody checks.

WHY THAT DIFFERENCE IS THE WHOLE POINT

Consider someone diagnosed with a serious illness. Their hospital bills are covered. Good.

They cannot work for a year. Their income stops. The mortgage does not. Their spouse reduces hours to look after them, so a second income drops too. None of that is a medical bill, and hospitalisation cover pays none of it.

That gap is what critical illness cover exists for.

WHAT CRITICAL ILLNESS DOES NOT DO

It does not pay medical bills as they arise — it pays once, on diagnosis.

It pays only for **defined conditions at defined severities**. This is the part clients find hardest, and the part advisors most often gloss over. A condition that sounds serious in ordinary language may not meet the policy definition. Early-stage conditions frequently do not.

Saying "it covers cancer" is not accurate enough to be honest. It covers cancer meeting the definition in the policy, at the severity stated.

HOW TO EXPLAIN THE PAIR

"They do different jobs. One pays the hospital, the other pays you. If you were seriously ill, the hospital bill is one problem and the fact that your income stopped is another. Most people need to think about both."',
 1, 15),
('0f000011-1000-4000-8000-000000000002', '0f000011-0000-4000-8000-000000000001',
 'The other distinctions, and what each category misses',
 'CRITICAL ILLNESS VERSUS CANCER-SPECIFIC COVER

Critical illness covers a defined list of conditions — typically several dozen, of which cancer is one.

Cancer-specific cover addresses cancer only, but often across a wider range of stages, including earlier ones that a general critical illness definition may exclude.

Neither is simply better. A client with a strong family history of one disease has a different profile from a client worried about serious illness in general.

The honest framing: "One covers a list of conditions. The other covers one condition more thoroughly. Which is more useful depends on what you are actually worried about, and we should talk about that before choosing."

TERM VERSUS WHOLE LIFE

Term insurance covers a fixed period. If the client dies within it, it pays. If they do not, it pays nothing and ends. That is not a flaw — it is the design, and it is why term costs less for the same sum assured.

Whole life is intended to cover the whole of life and typically builds a cash value over time.

The mistake advisors make is presenting term as "cheap" and whole life as "better". They are different instruments. Term suits a defined obligation with an end date — a mortgage, or the years until children are independent. Whole life suits a need with no end date.

A client who buys whole life for a twenty-year need has paid for something they did not need. A client who buys term for a permanent need finds their cover ends at exactly the age it becomes hardest to replace.

PERSONAL ACCIDENT VERSUS BROADER HEALTH PROTECTION

Personal accident covers accidents only. Not illness. It is narrow and inexpensive, and its narrowness is easy to forget when it is being added to a recommendation.

CARESHIELD AND LONG-TERM CARE

Long-term care addresses the inability to perform activities of daily living — not treatment, and not diagnosis. A person can be neither in hospital nor recently diagnosed and still need substantial daily help for years.

This is a genuinely different need from everything above, and it is the one clients think about least.

WHAT EACH CATEGORY DOES NOT COVER — THE SHORT VERSION

- Hospitalisation: does not replace income, does not pay a lump sum on diagnosis
- Critical illness: does not pay medical bills as they arise, does not cover conditions below the defined severity
- Cancer cover: does not cover other conditions
- Term: pays nothing if the client survives the term
- Whole life: costs more for the same sum assured
- Personal accident: does not cover illness
- Long-term care: does not pay for treatment

Learn this list. It is the fastest way to correct a client''s misunderstanding without lecturing them.',
 2, 16)
on conflict (id) do nothing;

insert into public.revision_cards (module_id, front, back, sequence) values
('0f000011-0000-4000-8000-000000000001', 'Hospitalisation versus critical illness — in one sentence?', 'One pays the hospital, the other pays the client. Different problems.', 1),
('0f000011-0000-4000-8000-000000000001', 'Why is "it covers cancer" not an honest answer?', 'It covers cancer meeting the policy definition, at the stated severity. Early-stage conditions frequently do not qualify.', 2),
('0f000011-0000-4000-8000-000000000001', 'When does term insurance suit a client better than whole life?', 'When the need has an end date — a mortgage, or the years until children are independent.', 3)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000011-2000-4000-8000-000000000001', '0f000011-0000-4000-8000-000000000001', 'Day 11 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000011-3000-4000-8000-000000000001', '0f000011-2000-4000-8000-000000000001',
 'A client has hospitalisation cover and asks whether they need critical illness cover as well. What is the key distinction?', 'scenario',
 'Hospitalisation pays the hospital; critical illness pays the client a lump sum they can use for anything, including replacing lost income.', 1),
('0f000011-3000-4000-8000-000000000002', '0f000011-2000-4000-8000-000000000001',
 'Why is "critical illness covers cancer" an inadequate explanation?', 'mcq',
 'It covers cancer meeting the policy definition at the stated severity. Early-stage conditions often do not qualify, and a client told otherwise may discover this at the worst moment.', 2),
('0f000011-3000-4000-8000-000000000003', '0f000011-2000-4000-8000-000000000001',
 'A client needs cover for the twenty years until their mortgage is repaid and their children are independent. Which is likely more appropriate?', 'scenario',
 'Term suits a defined obligation with an end date. Whole life for a twenty-year need means paying for something beyond what was required.', 3),
('0f000011-3000-4000-8000-000000000004', '0f000011-2000-4000-8000-000000000001',
 'What need does long-term care cover address that the others do not?', 'mcq',
 'Inability to perform activities of daily living — not treatment and not diagnosis. A person can need years of daily help without being in hospital.', 4),
('0f000011-3000-4000-8000-000000000005', '0f000011-2000-4000-8000-000000000001',
 'A client survives the full term of their term insurance policy. What do they receive?', 'mcq',
 'Nothing. That is the design, not a defect, and it is why term costs less for the same sum assured. A client who does not understand this before buying will feel misled.', 5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000011-3000-4000-8000-000000000001', 'Hospitalisation pays the hospital; critical illness pays the client a lump sum they can use for anything', true, 1),
('0f000011-3000-4000-8000-000000000001', 'Critical illness covers more conditions than hospitalisation', false, 2),
('0f000011-3000-4000-8000-000000000001', 'They are broadly the same, so one is enough', false, 3),
('0f000011-3000-4000-8000-000000000001', 'Critical illness pays the hospital directly and faster', false, 4),

('0f000011-3000-4000-8000-000000000002', 'It covers cancer meeting the policy definition at the stated severity — early stages often do not qualify', true, 1),
('0f000011-3000-4000-8000-000000000002', 'Cancer is usually excluded from critical illness policies', false, 2),
('0f000011-3000-4000-8000-000000000002', 'Cancer is only covered after a waiting period of five years', false, 3),
('0f000011-3000-4000-8000-000000000002', 'It is accurate — no further qualification is needed', false, 4),

('0f000011-3000-4000-8000-000000000003', 'Term insurance, because the need has a defined end date', true, 1),
('0f000011-3000-4000-8000-000000000003', 'Whole life, because it is always the better product', false, 2),
('0f000011-3000-4000-8000-000000000003', 'Personal accident, because it is cheaper', false, 3),
('0f000011-3000-4000-8000-000000000003', 'Critical illness, because it pays a lump sum', false, 4),

('0f000011-3000-4000-8000-000000000004', 'Inability to perform activities of daily living, rather than treatment or diagnosis', true, 1),
('0f000011-3000-4000-8000-000000000004', 'Hospital bills over an extended stay', false, 2),
('0f000011-3000-4000-8000-000000000004', 'Loss of income following an accident', false, 3),
('0f000011-3000-4000-8000-000000000004', 'The cost of medication after discharge', false, 4),

('0f000011-3000-4000-8000-000000000005', 'Nothing — the cover ends. That is the design, and why it costs less', true, 1),
('0f000011-3000-4000-8000-000000000005', 'A return of all premiums paid', false, 2),
('0f000011-3000-4000-8000-000000000005', 'The accumulated cash value', false, 3),
('0f000011-3000-4000-8000-000000000005', 'Automatic conversion to whole life cover', false, 4)
on conflict do nothing;

-- ===========================================================================
-- DAY 15 — CPF, BRS, FRS and ERS
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values (
  '0f000015-0000-4000-8000-000000000001', pg_temp.day_id(15),
  'CPF and the Retirement Sums', 'singapore_foundations',
  'How CPF works, what the three retirement sums mean, and why the figures in this module must be checked every January.',
  '["Explain the CPF accounts and what each is for","Explain BRS, FRS and ERS and how they relate","Describe what happens at 55 and at the payout age","Recognise that these figures change annually"]'::jsonb,
  50, true, 1, 'draft'
) on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000015-1000-4000-8000-000000000001', '0f000015-0000-4000-8000-000000000001',
 'How CPF is structured',
 'CPF is a compulsory savings scheme. It is not insurance, it is not an investment product, and it is not something an advisor sells. It is the foundation almost every other conversation sits on top of.

You need to understand it because your clients half-understand it, and the half they have wrong is usually the part that matters.

THE ACCOUNTS

**Ordinary Account.** Housing, insurance premiums under certain schemes, approved investments, and some education costs. This is the account most clients have spent from, usually on a flat.

**Special Account.** Retirement. Earns a higher interest rate than the Ordinary Account, and is correspondingly restricted.

**MediSave.** Healthcare — hospitalisation costs, approved outpatient treatments, and premiums for certain medical insurance schemes.

**Retirement Account.** Created at 55, funded from the Special and Ordinary Accounts, and used to provide monthly payouts later.

WHAT HAPPENS AT 55

A Retirement Account is created. Savings move into it from the Special and Ordinary Accounts up to the applicable retirement sum. Anything above that can generally be withdrawn.

This is where the retirement sums come in, and where most client confusion lives.

WHY THIS MATTERS TO YOUR CONVERSATIONS

Two clients with identical salaries can be in completely different positions at 55, because one used most of their Ordinary Account on property and the other did not.

A client who says "I''ll be fine, I have CPF" has usually never looked at what their balance would actually produce as a monthly payout. Helping them look is genuinely useful, and it costs you nothing.

WHAT NOT TO DO

Do not present CPF as inadequate in order to create a need. It may be adequate for a particular client, and saying otherwise when it is not true is both dishonest and easy to disprove.

Do not quote figures you have not checked. They change every year.',
 1, 15),
('0f000015-1000-4000-8000-000000000002', '0f000015-0000-4000-8000-000000000001',
 'The three retirement sums',
 'There are three reference points for how much a member sets aside at 55. They are guideposts, not obligations.

⚠️ THE FIGURES BELOW ARE FOR MEMBERS TURNING 55 IN 2026 AND WILL BE OUT OF DATE NEXT YEAR. Verify them at cpf.gov.sg before using them with a client. Your administrator updates them in this module each January.

**Basic Retirement Sum (BRS) — $110,200 in 2026**
Intended to cover basic living needs in retirement, excluding rent. A member can set aside the BRS rather than the FRS if they own property and meet the conditions. Estimated monthly payout from 65: around $950.

**Full Retirement Sum (FRS) — $220,400 in 2026**
Twice the BRS. The standard reference point. Estimated monthly payout from 65: around $1,780.

**Enhanced Retirement Sum (ERS) — $440,800 in 2026**
Twice the FRS. The maximum a member aged 55 and above can top up their Retirement Account to. Estimated monthly payout from 65: around $2,610.

HOW TO TALK ABOUT THEM

Most clients have never seen these numbers next to a monthly payout. Putting the two together is often the most useful thing you do in a first meeting.

"If you set aside the Full Retirement Sum, that produces somewhere around $1,780 a month from 65. Have a look at what your household costs to run now. Is that number close?"

Then stop talking. The client does the arithmetic themselves, and the conclusion is theirs rather than yours.

THE HONEST CAVEATS, WHICH YOU MUST GIVE

These payout figures are **estimates**, published by CPF and subject to change.

The sums rise each year, so a client turning 55 in ten years faces a different figure.

Payouts depend on the CPF LIFE plan chosen and other factors. Do not present a single number as a certainty.

A client who owns their home outright has different requirements from one still paying a mortgage.

WHEN TO ESCALATE

Specific projections for an individual client, CPF LIFE plan selection, and anything involving property pledges or transfers between accounts: escalate to a senior advisor.

You are thirty days into this. Explaining the structure accurately is a genuine achievement. Projecting someone''s retirement income is not yet your job.',
 2, 16)
on conflict (id) do nothing;

-- Editable figures. An administrator updates these four rows each January and
-- the module is current again — no lesson rewriting required.
insert into public.terminology (module_id, term, definition, sequence) values
('0f000015-0000-4000-8000-000000000001', 'Basic Retirement Sum (2026)', '$110,200 for members turning 55 in 2026. Estimated payout around $950 per month from 65. VERIFY ANNUALLY at cpf.gov.sg.', 1),
('0f000015-0000-4000-8000-000000000001', 'Full Retirement Sum (2026)', '$220,400 for members turning 55 in 2026, twice the BRS. Estimated payout around $1,780 per month from 65. VERIFY ANNUALLY.', 2),
('0f000015-0000-4000-8000-000000000001', 'Enhanced Retirement Sum (2026)', '$440,800 for 2026, twice the FRS. The maximum top-up for members aged 55 and above. Estimated payout around $2,610 per month from 65. VERIFY ANNUALLY.', 3),
('0f000015-0000-4000-8000-000000000001', 'Retirement Account', 'Created at 55 from Special and Ordinary Account savings, used to provide monthly payouts later.', 4)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000015-2000-4000-8000-000000000001', '0f000015-0000-4000-8000-000000000001', 'Day 15 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000015-3000-4000-8000-000000000001', '0f000015-2000-4000-8000-000000000001',
 'How does the Enhanced Retirement Sum relate to the Full Retirement Sum?', 'mcq',
 'The ERS is twice the FRS, and is the maximum a member aged 55 and above may top up their Retirement Account to.', 1),
('0f000015-3000-4000-8000-000000000002', '0f000015-2000-4000-8000-000000000001',
 'A client says "I will be fine, I have CPF." What is the most useful response?', 'scenario',
 'Help them look at what their balance would actually produce as a monthly payout against what their household costs. The conclusion is then theirs, and it may well be that they are fine.', 2),
('0f000015-3000-4000-8000-000000000003', '0f000015-2000-4000-8000-000000000001',
 'Which CPF account is created at age 55?', 'mcq',
 'The Retirement Account, funded from the Special and Ordinary Accounts up to the applicable retirement sum.', 3),
('0f000015-3000-4000-8000-000000000004', '0f000015-2000-4000-8000-000000000001',
 'A client asks you to project exactly what their CPF payout will be at 65. What should you do?', 'scenario',
 'Escalate. Individual projections depend on the CPF LIFE plan, property arrangements and future rule changes. Quoting a single figure as certain is precisely the failure this programme exists to prevent.', 4),
('0f000015-3000-4000-8000-000000000005', '0f000015-2000-4000-8000-000000000001',
 'Why must the retirement sum figures in this module be checked before use?', 'mcq',
 'They are revised every year. A figure quoted from memory will be wrong within months, and the client may act on it.', 5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000015-3000-4000-8000-000000000001', 'The ERS is twice the FRS', true, 1),
('0f000015-3000-4000-8000-000000000001', 'The ERS is half the FRS', false, 2),
('0f000015-3000-4000-8000-000000000001', 'They are the same amount, calculated differently', false, 3),
('0f000015-3000-4000-8000-000000000001', 'The ERS applies only to members who do not own property', false, 4),

('0f000015-3000-4000-8000-000000000002', 'Help them look at what their balance would actually produce each month against what their household costs', true, 1),
('0f000015-3000-4000-8000-000000000002', 'Explain that CPF is never enough for anyone', false, 2),
('0f000015-3000-4000-8000-000000000002', 'Accept it and move on to another topic', false, 3),
('0f000015-3000-4000-8000-000000000002', 'Recommend a retirement product immediately', false, 4),

('0f000015-3000-4000-8000-000000000003', 'The Retirement Account', true, 1),
('0f000015-3000-4000-8000-000000000003', 'The Special Account', false, 2),
('0f000015-3000-4000-8000-000000000003', 'The MediSave Account', false, 3),
('0f000015-3000-4000-8000-000000000003', 'The Ordinary Account', false, 4),

('0f000015-3000-4000-8000-000000000004', 'Escalate to a senior advisor — individual projections depend on factors beyond your current competence', true, 1),
('0f000015-3000-4000-8000-000000000004', 'Give the standard FRS payout figure as their answer', false, 2),
('0f000015-3000-4000-8000-000000000004', 'Estimate it from their current salary', false, 3),
('0f000015-3000-4000-8000-000000000004', 'Tell them CPF cannot be projected at all', false, 4),

('0f000015-3000-4000-8000-000000000005', 'They are revised every year, so a remembered figure will soon be wrong', true, 1),
('0f000015-3000-4000-8000-000000000005', 'They differ between employers', false, 2),
('0f000015-3000-4000-8000-000000000005', 'They are confidential and cannot be shared', false, 3),
('0f000015-3000-4000-8000-000000000005', 'They apply only to members born after 1980', false, 4)
on conflict do nothing;

commit;


-- ----------------------------------------------------------------------
-- supabase/seed/05-curriculum-protection-2.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — seed: Days 6 to 10 (Protection Knowledge, continued)
--
-- Term, Whole Life, Critical Illness, Cancer Cover, CareShield and long-term
-- care. Optional and idempotent; everything lands as `draft`.
--
-- Written to PRODUCT CATEGORY. No insurer, no premium, no policy wording.
-- Compliance sign-off required before publishing.

begin;

do $$
begin
  if not exists (select 1 from public.programme_days
                 where template_id = '0a715000-0000-4000-8000-000000000001') then
    raise exception 'Run supabase/seed/01-programme.sql first.';
  end if;
end;
$$;

create or replace function pg_temp.day_id(n integer) returns uuid
language sql stable as $$
  select id from public.programme_days
  where template_id = '0a715000-0000-4000-8000-000000000001' and day_number = n;
$$;

-- ===========================================================================
-- DAY 6 — Term Insurance
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000006-0000-4000-8000-000000000001', pg_temp.day_id(6),
  'Term Insurance', 'protection',
  'Cover for a defined period. The simplest product in the range, and the one most often mis-sold by omission.',
  '["Explain what term insurance does and what happens at the end of the term","Match a term length to a client obligation","Explain plainly that nothing is paid if the client survives the term"]'::jsonb,
  40, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000006-1000-4000-8000-000000000001', '0f000006-0000-4000-8000-000000000001',
 'Cover with an end date',
 'Term insurance pays a sum of money if the insured person dies during a fixed period. If they are still alive when the period ends, the policy ends and pays nothing.

That last sentence is the whole product, and it is the sentence advisors skip.

WHAT NEED IT ADDRESSES

Someone depends on this person''s income, and would be in difficulty without it. Term insurance converts that risk into a fixed monthly cost.

WHO MAY BENEFIT

A parent with young children. Someone with a mortgage. Anyone supporting a partner who could not maintain the household alone. Someone supporting ageing parents — the dependant most often forgotten in Singapore.

WHO MAY NOT NEED IT

Someone with no dependants and no debts that would pass to anyone. A person whose assets already exceed any obligation their death would create.

If a client has nobody depending on them financially, saying so is the correct advice. It is also the fastest way to be trusted.

HOW IT GENERALLY WORKS

A sum assured, a term, and a premium. If death occurs within the term, the sum is paid to the beneficiary. Premiums are typically level for the term.

WHY IT COSTS LESS

Because most policies never pay out. That is not a criticism — it is the arithmetic that makes the cover affordable. A client who understands this is not disappointed later; a client who does not will feel cheated at the end of the term.

MATCHING THE TERM TO THE NEED

This is the part that requires thought rather than recall.

A mortgage with 22 years to run is a 22-year obligation. A child of six will plausibly be independent in 18 to 20 years. A client of 40 who wants cover to retirement at 65 needs 25 years.

Term lengths should come from the client''s obligations, not from a round number.

THE FAILURE MODE

A client buys a 10-year term at 35 because it is cheap. At 45 it expires. They are now ten years older, possibly with a medical history, and the same cover costs considerably more — or is unavailable.

Say this before they buy: "This ends at 45. If you still need cover then, it will cost more, and if your health has changed it may be harder to get. Should we look at a longer term now?"',
 1, 14)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000006-2000-4000-8000-000000000001', '0f000006-0000-4000-8000-000000000001', 'Day 6 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000006-3000-4000-8000-000000000001','0f000006-2000-4000-8000-000000000001',
 'A client asks what they get back if they outlive their term policy. What is the answer?','scenario',
 'Nothing. The cover ends. This is the design and the reason it costs less, and a client who learns it at expiry rather than at purchase will feel misled.',1),
('0f000006-3000-4000-8000-000000000002','0f000006-2000-4000-8000-000000000001',
 'A client of 35 has a mortgage with 22 years remaining and a child aged 4. What term length is most defensible?','scenario',
 'Term length should follow the client''s actual obligations. Around 20 years covers both the mortgage and the child reaching independence.',2),
('0f000006-3000-4000-8000-000000000003','0f000006-2000-4000-8000-000000000001',
 'Which client most likely does NOT need term insurance?','mcq',
 'Someone with no dependants and no debts passing to anyone. Saying so is correct advice, not a lost sale.',3),
('0f000006-3000-4000-8000-000000000004','0f000006-2000-4000-8000-000000000001',
 'Why is a short term chosen purely for affordability a risk to the client?','scenario',
 'When it expires the client is older and may have a medical history, so replacement cover costs more or is unavailable — precisely when they may still need it.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000006-3000-4000-8000-000000000001','Nothing — the cover simply ends',true,1),
('0f000006-3000-4000-8000-000000000001','A refund of all premiums paid',false,2),
('0f000006-3000-4000-8000-000000000001','A reduced paid-up sum assured',false,3),
('0f000006-3000-4000-8000-000000000001','Automatic renewal at the same premium',false,4),
('0f000006-3000-4000-8000-000000000002','Around 20 years, covering the mortgage and the child reaching independence',true,1),
('0f000006-3000-4000-8000-000000000002','5 years, so it is affordable now',false,2),
('0f000006-3000-4000-8000-000000000002','Whole of life, since needs never really end',false,3),
('0f000006-3000-4000-8000-000000000002','10 years, then review',false,4),
('0f000006-3000-4000-8000-000000000003','A single person with no dependants and no debts',true,1),
('0f000006-3000-4000-8000-000000000003','A parent with two young children',false,2),
('0f000006-3000-4000-8000-000000000003','A sole earner supporting ageing parents',false,3),
('0f000006-3000-4000-8000-000000000003','A couple with a large mortgage',false,4),
('0f000006-3000-4000-8000-000000000004','The cover expires when they are older and possibly less insurable',true,1),
('0f000006-3000-4000-8000-000000000004','Short terms have higher exclusions',false,2),
('0f000006-3000-4000-8000-000000000004','Premiums increase every year during the term',false,3),
('0f000006-3000-4000-8000-000000000004','Short-term policies pay a reduced sum assured',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 7 — Whole Life Insurance
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000007-0000-4000-8000-000000000001', pg_temp.day_id(7),
  'Whole Life Insurance', 'protection',
  'Cover intended to last for life, usually with a cash value. More expensive for the same sum assured, and appropriate for different reasons.',
  '["Explain how whole life differs from term","Explain cash value without implying it is a savings account","Identify when whole life is and is not appropriate"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000007-1000-4000-8000-000000000001','0f000007-0000-4000-8000-000000000001',
 'Cover without an end date',
 'Whole life insurance is intended to remain in force for the whole of the insured person''s life, rather than for a fixed period.

Because a claim is effectively certain rather than probable, it costs considerably more than term for the same sum assured.

WHAT NEED IT ADDRESSES

An obligation that does not expire. Someone who will always be dependent. A wish to leave something regardless of when death occurs. In some cases, a desire for a policy that also accumulates a value.

CASH VALUE — EXPLAIN THIS CAREFULLY

Most whole life policies build a cash value over time, which the client may be able to surrender or borrow against.

Three things must be said plainly, and advisors routinely say none of them:

**It builds slowly.** In the early years the surrender value is usually far less than the premiums paid. A client who surrenders after three years will typically get back much less than they put in.

**Guaranteed and non-guaranteed are different.** Illustrations commonly show both. The non-guaranteed portion depends on performance and is not a promise. Presenting a projected total as though it were certain is the single most common compliance failure in this category.

**It is not a savings account.** A client who needs accessible savings should have accessible savings. A whole life policy is protection that happens to accumulate value, not a deposit that happens to include cover.

WHEN WHOLE LIFE IS APPROPRIATE

A dependant with lifelong needs. An estate obligation that will exist whenever death occurs. A client who genuinely wants permanent cover and can sustain the premium for decades.

WHEN IT IS NOT

A twenty-year need. A client whose budget means buying whole life would leave them underinsured — a smaller permanent policy is worse than an adequate term policy if the family cannot manage on the smaller sum.

A client who may not sustain the premium. Early lapse is the most damaging outcome in this category: they paid for years and receive little back.

HOW TO PRESENT THE CHOICE

"Term is cheaper because most policies never pay out. Whole life costs more because it is designed to pay out eventually and builds a value along the way. Which suits you depends on whether the need you are covering has an end date. Does it?"',
 1, 15)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000007-2000-4000-8000-000000000001','0f000007-0000-4000-8000-000000000001','Day 7 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000007-3000-4000-8000-000000000001','0f000007-2000-4000-8000-000000000001',
 'An illustration shows guaranteed and non-guaranteed values. How should you present the non-guaranteed portion?','scenario',
 'As dependent on performance and not promised. Presenting a projected total as certain is the most common compliance failure in this category.',1),
('0f000007-3000-4000-8000-000000000002','0f000007-2000-4000-8000-000000000001',
 'A client surrenders a whole life policy after three years. What should they expect?','mcq',
 'Typically considerably less than the premiums paid. Cash value builds slowly, and a client not told this in advance will feel deceived.',2),
('0f000007-3000-4000-8000-000000000003','0f000007-2000-4000-8000-000000000001',
 'A client can afford either adequate term cover or a much smaller whole life policy. Which is generally more defensible?','scenario',
 'Adequate term cover. A smaller permanent policy that leaves the family underinsured fails the need it was bought to address.',3),
('0f000007-3000-4000-8000-000000000004','0f000007-2000-4000-8000-000000000001',
 'Why is whole life more expensive than term for the same sum assured?','mcq',
 'A claim is effectively certain rather than probable, and the policy also accumulates a value.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000007-3000-4000-8000-000000000001','As dependent on performance and not guaranteed',true,1),
('0f000007-3000-4000-8000-000000000001','As the expected outcome, since illustrations are usually conservative',false,2),
('0f000007-3000-4000-8000-000000000001','As guaranteed, provided premiums are maintained',false,3),
('0f000007-3000-4000-8000-000000000001','It need not be mentioned unless the client asks',false,4),
('0f000007-3000-4000-8000-000000000002','Considerably less than the premiums they have paid',true,1),
('0f000007-3000-4000-8000-000000000002','Approximately what they paid in',false,2),
('0f000007-3000-4000-8000-000000000002','All premiums plus accrued interest',false,3),
('0f000007-3000-4000-8000-000000000002','The full sum assured',false,4),
('0f000007-3000-4000-8000-000000000003','Adequate term cover, so the family is not left underinsured',true,1),
('0f000007-3000-4000-8000-000000000003','The whole life policy, because it lasts for life',false,2),
('0f000007-3000-4000-8000-000000000003','The whole life policy, because it builds cash value',false,3),
('0f000007-3000-4000-8000-000000000003','Neither — advise them to wait until they earn more',false,4),
('0f000007-3000-4000-8000-000000000004','A claim is effectively certain rather than probable, and it accumulates value',true,1),
('0f000007-3000-4000-8000-000000000004','Whole life policies have fewer exclusions',false,2),
('0f000007-3000-4000-8000-000000000004','Underwriting is stricter',false,3),
('0f000007-3000-4000-8000-000000000004','It covers illness as well as death',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 8 — Critical Illness
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000008-0000-4000-8000-000000000001', pg_temp.day_id(8),
  'Critical Illness Cover', 'protection',
  'A lump sum on diagnosis of a defined condition at a defined severity. The word "defined" is doing most of the work.',
  '["Explain what critical illness cover pays and when","Explain severity definitions honestly","Distinguish early-stage from advanced-stage cover"]'::jsonb,
  50, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000008-1000-4000-8000-000000000001','0f000008-0000-4000-8000-000000000001',
 'A lump sum, on diagnosis, for defined conditions',
 'Critical illness cover pays a lump sum when the insured person is diagnosed with one of a defined list of conditions, at a defined severity.

The money is the client''s. It is not tied to medical bills and nobody audits how it is spent — mortgage, replacing income, a carer, adapting a home, or taking six months off.

WHAT NEED IT ADDRESSES

Serious illness costs far more than treatment. Income stops or reduces. A spouse cuts their hours. Ordinary commitments continue regardless. Hospitalisation cover addresses none of that.

THE PART THAT MATTERS MOST: DEFINITIONS

A policy does not cover "cancer". It covers cancer **as defined in the policy, at the stated severity**.

A condition that sounds serious in ordinary language may not meet the definition. Early-stage conditions frequently do not meet an advanced-stage definition.

This is where claims are disputed, and disputes almost always trace back to what the advisor said at the point of sale.

EARLY, INTERMEDIATE AND ADVANCED STAGES

Many plans now pay at multiple severities, typically a smaller proportion at earlier stages.

For a new advisor the important points are: know whether the plan being discussed covers early stages, know that a payout at an earlier stage often reduces what remains available later, and escalate the specifics.

WHAT IT DOES NOT DO

It does not pay medical bills as they arise — it pays once, on diagnosis.
It does not cover conditions outside the list, however serious.
It does not cover conditions below the defined severity.
It does not usually pay again for the same condition.

SURVIVAL PERIODS

Most policies require the insured to survive a short period after diagnosis. It is not a technicality to a family, and it should be mentioned.

HOW TO EXPLAIN IT HONESTLY

"This pays you a lump sum if you are diagnosed with one of the conditions on the list, at the severity the policy describes. It is not a general illness policy — the list and the definitions matter, and I would rather walk you through them now than have you find out at claim time."

An advisor who says that has protected the client and themselves. An advisor who says "it covers the major illnesses" has protected neither.',
 1, 16)
on conflict (id) do nothing;

insert into public.terminology (module_id, term, definition, sequence) values
('0f000008-0000-4000-8000-000000000001','Severity definition','The specific clinical criteria a condition must meet for a claim to be admitted. Sounding serious is not the same as meeting the definition.',1),
('0f000008-0000-4000-8000-000000000001','Survival period','A short period the insured must survive after diagnosis for the claim to be paid.',2),
('0f000008-0000-4000-8000-000000000001','Multi-stage cover','Plans paying a proportion at early or intermediate severity, usually reducing what remains available later.',3)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000008-2000-4000-8000-000000000001','0f000008-0000-4000-8000-000000000001','Day 8 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000008-3000-4000-8000-000000000001','0f000008-2000-4000-8000-000000000001',
 'A client asks "so it covers cancer?" What is the accurate answer?','scenario',
 'It covers cancer as defined in the policy at the stated severity. Early stages frequently do not meet an advanced-stage definition, and this is where claims are disputed.',1),
('0f000008-3000-4000-8000-000000000002','0f000008-2000-4000-8000-000000000001',
 'What can the client spend a critical illness payout on?','mcq',
 'Anything. It is a lump sum paid to them, not a reimbursement of medical costs.',2),
('0f000008-3000-4000-8000-000000000003','0f000008-2000-4000-8000-000000000001',
 'A client is diagnosed with a serious condition that is not on the policy list. What happens?','scenario',
 'No payout. The list is exhaustive, which is precisely why an advisor must not describe the cover as protecting against "serious illness" generally.',3),
('0f000008-3000-4000-8000-000000000004','0f000008-2000-4000-8000-000000000001',
 'Why should a survival period be mentioned at the point of sale?','mcq',
 'Because it determines whether a family receives anything at all in the worst cases, and discovering it at claim time is indefensible.',4),
('0f000008-3000-4000-8000-000000000005','0f000008-2000-4000-8000-000000000001',
 'A client asks precisely how their plan defines a specific heart condition. You have not been trained on it. What do you do?','scenario',
 'Escalate. Definitions vary by insurer and by plan, and an approximate answer to a definition question is worse than no answer.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000008-3000-4000-8000-000000000001','It covers cancer as defined in the policy, at the stated severity',true,1),
('0f000008-3000-4000-8000-000000000001','Yes, all cancers at any stage',false,2),
('0f000008-3000-4000-8000-000000000001','Only cancers requiring hospitalisation',false,3),
('0f000008-3000-4000-8000-000000000001','Only if diagnosed after the first policy year',false,4),
('0f000008-3000-4000-8000-000000000002','Anything — it is a lump sum paid to them, not a medical reimbursement',true,1),
('0f000008-3000-4000-8000-000000000002','Approved medical treatment only',false,2),
('0f000008-3000-4000-8000-000000000002','Hospital bills and prescribed medication',false,3),
('0f000008-3000-4000-8000-000000000002','Whatever the insurer approves in writing',false,4),
('0f000008-3000-4000-8000-000000000003','No payout — the list of covered conditions is exhaustive',true,1),
('0f000008-3000-4000-8000-000000000003','A reduced payout at the insurer''s discretion',false,2),
('0f000008-3000-4000-8000-000000000003','Full payout, since the condition is serious',false,3),
('0f000008-3000-4000-8000-000000000003','A refund of premiums paid',false,4),
('0f000008-3000-4000-8000-000000000004','It can determine whether the family receives anything at all',true,1),
('0f000008-3000-4000-8000-000000000004','It affects the premium calculation',false,2),
('0f000008-3000-4000-8000-000000000004','It determines the waiting period for new conditions',false,3),
('0f000008-3000-4000-8000-000000000004','It only applies to accidental causes',false,4),
('0f000008-3000-4000-8000-000000000005','Escalate to a senior advisor rather than approximate a definition',true,1),
('0f000008-3000-4000-8000-000000000005','Describe the general industry standard definition',false,2),
('0f000008-3000-4000-8000-000000000005','Tell them all insurers define it the same way',false,3),
('0f000008-3000-4000-8000-000000000005','Read out a definition from a different insurer''s brochure',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 9 — Cancer Cover
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000009-0000-4000-8000-000000000001', pg_temp.day_id(9),
  'Cancer-Specific Cover', 'protection',
  'One condition, covered more thoroughly. Neither better nor worse than general critical illness cover — different.',
  '["Explain how cancer-specific cover differs from general critical illness","Identify clients for whom it may be relevant","Avoid presenting either as universally superior"]'::jsonb,
  40, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000009-1000-4000-8000-000000000001','0f000009-0000-4000-8000-000000000001',
 'One condition, covered more thoroughly',
 'Cancer-specific cover addresses cancer alone, but frequently across a wider range of stages than a general critical illness definition — including earlier stages that a general plan may exclude.

THE HONEST COMPARISON

General critical illness: a list of conditions, typically several dozen, with cancer among them. Broad, but each condition must meet its severity definition.

Cancer-specific: one condition, often covering earlier stages and sometimes providing ongoing benefits during treatment. Deeper, but narrower.

Neither is simply better. An advisor who presents one as superior is selling rather than advising, and it will be obvious to any client who does their own reading afterwards.

WHO MAY BENEFIT FROM CONSIDERING IT

A client with a significant family history of cancer specifically.
A client who already holds general critical illness cover and wants deeper cover for the condition that concerns them most.
A client whose general cover excludes early-stage conditions they are worried about.

WHO MAY NOT

A client with no critical illness cover of any kind. Filling the narrow gap before the broad one leaves them exposed to everything else.
A client whose concern is serious illness in general rather than cancer particularly.

WHAT TO ASK FIRST

"When you think about being seriously ill, is there something specific in your mind, or is it the general possibility?"

The answer usually determines which category fits, and it comes from the client rather than from you.

THE COMPLIANCE POINT

Do not use family history to create alarm. Establish it as a fact in the fact-find, reflect it in the recommendation, and let the client draw their own conclusion. There is a real line between "your family history is relevant here" and "with your family history you would be foolish not to", and the second one is not advice.',
 1, 13)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000009-2000-4000-8000-000000000001','0f000009-0000-4000-8000-000000000001','Day 9 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000009-3000-4000-8000-000000000001','0f000009-2000-4000-8000-000000000001',
 'How does cancer-specific cover typically differ from general critical illness cover?','mcq',
 'It addresses one condition, often across a wider range of stages including earlier ones. Narrower but deeper.',1),
('0f000009-3000-4000-8000-000000000002','0f000009-2000-4000-8000-000000000001',
 'A client with no critical illness cover of any kind asks about cancer-specific cover. What is the better first step?','scenario',
 'Establish whether the broader gap should be addressed first. Filling a narrow gap before a broad one leaves everything else exposed.',2),
('0f000009-3000-4000-8000-000000000003','0f000009-2000-4000-8000-000000000001',
 'A client mentions a strong family history of cancer. How should that influence your conversation?','scenario',
 'Record it as a fact and let it inform the recommendation. Using it to create alarm crosses the line from advice into pressure.',3),
('0f000009-3000-4000-8000-000000000004','0f000009-2000-4000-8000-000000000001',
 'Which statement is appropriate when comparing the two categories?','mcq',
 'Neither is universally better; which fits depends on what the client is actually worried about.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000009-3000-4000-8000-000000000001','It covers one condition, often across more stages including earlier ones',true,1),
('0f000009-3000-4000-8000-000000000001','It covers more conditions than general critical illness',false,2),
('0f000009-3000-4000-8000-000000000001','It pays medical bills rather than a lump sum',false,3),
('0f000009-3000-4000-8000-000000000001','It has no severity definitions',false,4),
('0f000009-3000-4000-8000-000000000002','Discuss whether the broader critical illness gap should be addressed first',true,1),
('0f000009-3000-4000-8000-000000000002','Recommend cancer cover, since it is what they asked about',false,2),
('0f000009-3000-4000-8000-000000000002','Recommend both immediately',false,3),
('0f000009-3000-4000-8000-000000000002','Tell them cancer cover is unnecessary',false,4),
('0f000009-3000-4000-8000-000000000003','Record it in the fact-find and let it inform the recommendation',true,1),
('0f000009-3000-4000-8000-000000000003','Emphasise the risk so they understand the urgency',false,2),
('0f000009-3000-4000-8000-000000000003','Avoid mentioning it, as it may cause distress',false,3),
('0f000009-3000-4000-8000-000000000003','Use it to justify the largest available sum assured',false,4),
('0f000009-3000-4000-8000-000000000004','Neither is universally better — it depends on what the client is worried about',true,1),
('0f000009-3000-4000-8000-000000000004','Cancer cover is better because cancer is most common',false,2),
('0f000009-3000-4000-8000-000000000004','General critical illness is better because it covers more',false,3),
('0f000009-3000-4000-8000-000000000004','Clients should always hold both',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 10 — CareShield and Long-Term Care
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000010-0000-4000-8000-000000000001', pg_temp.day_id(10),
  'CareShield and Long-Term Care', 'protection',
  'Cover for being unable to perform activities of daily living. Not treatment, not diagnosis — daily help, often for years.',
  '["Explain activities of daily living and why they are the trigger","Distinguish long-term care from health and critical illness cover","Explain why clients think about this least"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000010-1000-4000-8000-000000000001','0f000010-0000-4000-8000-000000000001',
 'A different need entirely',
 'Long-term care cover addresses the inability to look after oneself. Not treatment. Not a diagnosis. The ordinary business of daily life becoming impossible without help.

CareShield Life is Singapore''s national long-term care insurance scheme, providing monthly payouts to those with severe disability. Supplements are available from private insurers.

Your job as a new advisor is to understand the need and the structure, and to escalate specifics about the national scheme''s current parameters, which change.

ACTIVITIES OF DAILY LIVING

Claims in this category turn on the inability to perform a number of basic activities — typically washing, dressing, feeding, toileting, mobility and transferring.

The trigger is usually being unable to perform a specified number of them without assistance. This is quite different from being ill, and clients find it genuinely surprising.

WHY THIS NEED IS DIFFERENT

Someone may be neither in hospital nor recently diagnosed, and still need substantial help every day for years.

Hospitalisation cover does not apply — they are not admitted.
Critical illness may not apply — there may be no qualifying diagnosis, or it may have been claimed years earlier.
Income protection may have ended.

And the cost is not a single large bill. It is a moderate recurring cost, for an unknown number of years. That combination is difficult to save against, which is precisely what insurance handles well.

WHY CLIENTS THINK ABOUT IT LEAST

It is distant, it is unpleasant to imagine, and it happens to a version of themselves they have not met.

There is a legitimate way to raise it: "Has anyone in your family needed daily help for a long period?" Many people in Singapore have watched a parent or grandparent go through exactly this, and the conversation becomes concrete rather than theoretical.

THE COMPLIANCE POINT

Do not overstate what the national scheme provides or fails to provide. Do not present a supplement as necessary without establishing the client''s actual position, including family support and existing arrangements.

Escalate current payout levels and scheme parameters to a senior advisor. They are published, they change, and quoting them from memory is exactly the mistake this programme exists to prevent.',
 1, 15)
on conflict (id) do nothing;

insert into public.terminology (module_id, term, definition, sequence) values
('0f000010-0000-4000-8000-000000000001','Activities of daily living','Basic self-care activities — typically washing, dressing, feeding, toileting, mobility and transferring. Inability to perform a specified number is the usual claim trigger.',1),
('0f000010-0000-4000-8000-000000000001','CareShield Life','Singapore''s national long-term care insurance scheme, providing monthly payouts on severe disability. Parameters change — verify before quoting.',2)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000010-2000-4000-8000-000000000001','0f000010-0000-4000-8000-000000000001','Day 10 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000010-3000-4000-8000-000000000001','0f000010-2000-4000-8000-000000000001',
 'What triggers a long-term care claim?','mcq',
 'Inability to perform a specified number of activities of daily living — not diagnosis and not hospitalisation.',1),
('0f000010-3000-4000-8000-000000000002','0f000010-2000-4000-8000-000000000001',
 'Why do hospitalisation and critical illness cover not address this need?','scenario',
 'The person may be neither admitted nor recently diagnosed, yet still need daily help for years. It is a different need with a different shape of cost.',2),
('0f000010-3000-4000-8000-000000000003','0f000010-2000-4000-8000-000000000001',
 'A client asks the exact monthly payout under the national scheme. You are not certain. What do you do?','scenario',
 'Escalate. The parameters are published and they change; quoting from memory is precisely the failure mode to avoid.',3),
('0f000010-3000-4000-8000-000000000004','0f000010-2000-4000-8000-000000000001',
 'What is an appropriate way to raise long-term care with a client?','mcq',
 'Ask whether anyone in their family has needed daily help for a long period. It makes an abstract risk concrete without applying pressure.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000010-3000-4000-8000-000000000001','Inability to perform a specified number of activities of daily living',true,1),
('0f000010-3000-4000-8000-000000000001','Diagnosis of a defined critical illness',false,2),
('0f000010-3000-4000-8000-000000000001','Admission to hospital for an extended period',false,3),
('0f000010-3000-4000-8000-000000000001','Reaching a specified age',false,4),
('0f000010-3000-4000-8000-000000000002','The person may be neither admitted nor newly diagnosed, yet still need years of daily help',true,1),
('0f000010-3000-4000-8000-000000000002','They do address it, so additional cover is unnecessary',false,2),
('0f000010-3000-4000-8000-000000000002','They only exclude it for clients over 65',false,3),
('0f000010-3000-4000-8000-000000000002','They cover it but with a long waiting period',false,4),
('0f000010-3000-4000-8000-000000000003','Escalate — the parameters are published and change over time',true,1),
('0f000010-3000-4000-8000-000000000003','Give an approximate figure and note it is approximate',false,2),
('0f000010-3000-4000-8000-000000000003','Say the scheme pays too little to rely on',false,3),
('0f000010-3000-4000-8000-000000000003','Tell them it varies too much to describe',false,4),
('0f000010-3000-4000-8000-000000000004','Ask whether anyone in their family has needed daily help for a long period',true,1),
('0f000010-3000-4000-8000-000000000004','Describe the worst outcomes in detail so they take it seriously',false,2),
('0f000010-3000-4000-8000-000000000004','Explain that the national scheme is inadequate',false,3),
('0f000010-3000-4000-8000-000000000004','Leave it until they are older',false,4)
on conflict do nothing;

commit;
