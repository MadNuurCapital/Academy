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
