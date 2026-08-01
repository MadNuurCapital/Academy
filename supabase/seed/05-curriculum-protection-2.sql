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
