-- =========================================================================
-- ATLAS Academy — Programme, scripts, concepts and rubrics
--
-- BUNDLE 3 OF 6. Paste this whole file into the Supabase SQL Editor
-- and press Run. Run the bundles in numeric order; each one depends on the
-- ones before it.
--
-- This file is generated. Do not edit it by hand — edit the source files
-- listed below and regenerate with scripts/build-browser-sql.sh
--
-- Source files, concatenated in this order:
--   supabase/seed/01-programme.sql
--   supabase/seed/02-scripts-concepts-rubrics.sql
-- =========================================================================



-- ----------------------------------------------------------------------
-- supabase/seed/01-programme.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — optional seed
--
-- Creates the 30-day programme skeleton and real content for Days 1 to 3, so
-- the progression engine can be exercised end to end before the full
-- curriculum is authored in Phase 6.
--
--   psql -d <database> -f supabase/seed/programme.sql
--
-- This script is OPTIONAL and idempotent. Production does not depend on it: a
-- fresh deployment works with an empty content set, and an administrator can
-- author everything through the interface instead.
--
-- It creates no users and no credentials. Advisors are invited through the
-- application; the first administrator is bootstrapped by hand as described in
-- the README.

begin;

-- ---------------------------------------------------------------------------
-- Programme template and the thirty days
-- ---------------------------------------------------------------------------

insert into public.programme_templates (id, name, description, status, is_default)
values (
  '0a715000-0000-4000-8000-000000000001',
  'ATLAS Academy — 30 Working Days',
  'The standard onboarding programme for new financial advisors.',
  'published',
  true
)
on conflict (id) do nothing;

-- Phase names and titles follow the agreed curriculum. CPF and HDB sit under
-- "Singapore Financial Foundations" and are never described as insurance
-- products; Day 18 is an Advisor Introduction, never a "sales pitch".
insert into public.programme_days (template_id, day_number, phase, title, description)
values
  ('0a715000-0000-4000-8000-000000000001',  1, 'Advisor Foundations', 'Introduction & the Advisor Role', 'What a financial advisor actually does, and the standards you are held to.'),
  ('0a715000-0000-4000-8000-000000000001',  2, 'Advisor Foundations', 'Financial Planning Fundamentals', 'Protection, healthcare, savings, investment and retirement — and how they fit together.'),
  ('0a715000-0000-4000-8000-000000000001',  3, 'Advisor Foundations', 'Fact-Finding & Needs Analysis', 'Understanding a client''s position before recommending anything.'),
  ('0a715000-0000-4000-8000-000000000001',  4, 'Protection Knowledge', 'Hospitalisation', null),
  ('0a715000-0000-4000-8000-000000000001',  5, 'Protection Knowledge', 'Personal Accident', null),
  ('0a715000-0000-4000-8000-000000000001',  6, 'Protection Knowledge', 'Term Insurance', null),
  ('0a715000-0000-4000-8000-000000000001',  7, 'Protection Knowledge', 'Whole Life Insurance', null),
  ('0a715000-0000-4000-8000-000000000001',  8, 'Protection Knowledge', 'Critical Illness', null),
  ('0a715000-0000-4000-8000-000000000001',  9, 'Protection Knowledge', 'Cancer Cover', null),
  ('0a715000-0000-4000-8000-000000000001', 10, 'Protection Knowledge', 'CareShield & Long-Term Care', null),
  ('0a715000-0000-4000-8000-000000000001', 11, 'Protection Knowledge', 'Protection Comparison & Case Study', 'What each category does — and does not — cover.'),
  ('0a715000-0000-4000-8000-000000000001', 12, 'Singapore Financial Foundations', 'Endowment Plans', null),
  ('0a715000-0000-4000-8000-000000000001', 13, 'Singapore Financial Foundations', 'Investment-Linked Policies', null),
  ('0a715000-0000-4000-8000-000000000001', 14, 'Singapore Financial Foundations', 'Savings & Investment Case Study', null),
  ('0a715000-0000-4000-8000-000000000001', 15, 'Singapore Financial Foundations', 'CPF, BRS, FRS & ERS', 'Figures change annually and are maintained by your administrator.'),
  ('0a715000-0000-4000-8000-000000000001', 16, 'Singapore Financial Foundations', 'HDB, Housing Commitments & Financial Planning', null),
  ('0a715000-0000-4000-8000-000000000001', 17, 'Client Conversation Skills', 'Prospecting & Appointment Setting', null),
  ('0a715000-0000-4000-8000-000000000001', 18, 'Client Conversation Skills', 'Advisor Introduction & Value Pitch', null),
  ('0a715000-0000-4000-8000-000000000001', 19, 'Client Conversation Skills', 'First Appointment & Fact-Finding', null),
  ('0a715000-0000-4000-8000-000000000001', 20, 'Client Conversation Skills', 'Concept Presentation', 'Four Pillars of Financial Planning and the Family Income Ladder.'),
  ('0a715000-0000-4000-8000-000000000001', 21, 'Client Conversation Skills', 'Product Explanation', null),
  ('0a715000-0000-4000-8000-000000000001', 22, 'Client Conversation Skills', 'Objection Handling, Closing & Follow-Up', null),
  ('0a715000-0000-4000-8000-000000000001', 23, 'Practical Application', 'Call & Appointment Role-Play', null),
  ('0a715000-0000-4000-8000-000000000001', 24, 'Practical Application', 'Fact-Finding Role-Play', null),
  ('0a715000-0000-4000-8000-000000000001', 25, 'Practical Application', 'Concept & Product Explanation', null),
  ('0a715000-0000-4000-8000-000000000001', 26, 'Practical Application', 'Objection Handling & Case Study', null),
  ('0a715000-0000-4000-8000-000000000001', 27, 'Practical Application', 'Joint Fieldwork or Simulated Appointment', null),
  ('0a715000-0000-4000-8000-000000000001', 28, 'Assessment & Readiness', 'Final Knowledge Assessment', null),
  ('0a715000-0000-4000-8000-000000000001', 29, 'Assessment & Readiness', 'Final Practical Assessment', null),
  ('0a715000-0000-4000-8000-000000000001', 30, 'Assessment & Readiness', 'Coaching & Readiness Review', null)
on conflict (template_id, day_number) do nothing;

-- ---------------------------------------------------------------------------
-- Day 1 — Introduction & the Advisor Role
-- ---------------------------------------------------------------------------

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
select
  '0a715001-0000-4000-8000-000000000001',
  pd.id,
  'What a Financial Advisor Does',
  'foundations',
  'The role, the responsibilities, and the standards you will be held to from your first client meeting onwards.',
  '["Explain the role of a financial advisor in plain language","Describe what happens before, during and after a client appointment","Recognise when a question is beyond your current competence"]'::jsonb,
  45, true, 1, 'draft'
from public.programme_days pd
where pd.template_id = '0a715000-0000-4000-8000-000000000001' and pd.day_number = 1
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
(
  '0a715002-0000-4000-8000-000000000001',
  '0a715001-0000-4000-8000-000000000001',
  'The advisor''s role',
  'A financial advisor helps people make decisions about money that they cannot easily make alone.

That sounds simple. In practice it means three distinct things.

FIRST, YOU FIND OUT WHERE SOMEONE ACTUALLY IS.

Most people do not have a clear picture of their own finances. They know roughly what they earn. They are less sure what they spend, what they owe, what they already own, and what would happen to the people who depend on them if their income stopped tomorrow.

Your first job is to build that picture with them. Not to sell anything. Not to recommend anything. Simply to understand.

SECOND, YOU HELP THEM SEE WHAT MATTERS.

Once the picture exists, gaps become visible. A young parent with no income protection. A family whose savings would last three weeks. Someone approaching retirement who has never checked what their CPF will actually provide.

Your job is to explain what you see in language they understand, and let them decide what matters most. It is their money and their life. You are not there to decide for them.

THIRD, YOU RECOMMEND ONLY WHAT FITS.

A recommendation that does not follow from the facts you gathered is not advice. It is a guess with a product attached.

WHAT THIS ROLE IS NOT

You are not a salesperson who happens to work in finance. The distinction matters, and it will be tested throughout this programme.

A salesperson starts with a product and looks for someone to sell it to. An advisor starts with a person and looks for what they need — including, sometimes, the conclusion that they need nothing at all today.

If you finish a meeting having recommended nothing because nothing was suitable, you have done your job correctly.

THE PART NOBODY TELLS YOU

You will be asked questions you cannot answer. This happens to advisors in their first week and it happens to advisors in their twentieth year.

The correct response is: "That is a good question and I want to give you an accurate answer rather than a quick one. Let me check and come back to you."

Nobody has ever lost a client by saying that. People have lost clients — and their licence — by guessing.',
  1, 15
),
(
  '0a715002-0000-4000-8000-000000000002',
  '0a715001-0000-4000-8000-000000000001',
  'Before, during and after an appointment',
  'Client meetings feel unpredictable when you are new. They are less unpredictable than they appear, because the same structure sits underneath almost all of them.

BEFORE

Confirm the appointment in writing the day before. Time, place, roughly how long, and what you will cover. This single habit prevents most no-shows.

Know why you are meeting. "To discuss your finances" is not a reason. "To understand your current position and see whether there are gaps worth addressing" is.

Bring what you need and nothing you do not. A fact-finding form. Something to write with. No product brochures — you do not yet know what, if anything, is relevant.

DURING

Open by setting the agenda. Say what you will cover, ask if there is anything they want to add, and give them a sense of how long it will take. People relax when they know the shape of a conversation.

Ask permission before fact-finding. "To give you anything useful I need to understand your situation properly. Some of it is personal — are you comfortable with that?" Almost everyone says yes. The ones who hesitate have told you something important.

Listen more than you speak. If you are talking for more than a third of a first appointment, something has gone wrong.

Summarise before you finish. "Let me check I have understood." Then say it back. This is where you catch the thing you misheard, and it is where the client hears their own situation described clearly, sometimes for the first time.

Agree a specific next step. Not "I will be in touch." A day, a purpose, and a method.

AFTER

Write your notes the same day. Not tomorrow. The details you are certain you will remember are the ones that vanish.

Do what you said you would do, when you said you would do it. Reliability in small things is how trust in large things is built.

If you promised to check something, check it — and come back even if the answer is unhelpful. Especially then.',
  2, 12
),
(
  '0a715002-0000-4000-8000-000000000003',
  '0a715001-0000-4000-8000-000000000001',
  'Knowing your limits',
  'The most dangerous advisor is not the one who knows too little. It is the one who does not know what they do not know.

You are thirty days into a career that takes years to master. There is no shame in that, and no client expects otherwise. What they do expect is honesty about it.

QUESTIONS YOU SHOULD ESCALATE, NOT ANSWER

Anything involving tax treatment. Anything involving a trust, an estate, or a will. Anything about a product you have not been trained on. Anything where the client''s situation involves a business, overseas assets, or a divorce.

Anything at all where you find yourself thinking "I think it works like this."

HOW TO ESCALATE WELL

Escalating is not admitting defeat, and it should not sound like one.

"That is exactly the kind of question I want to get right rather than fast. I work with a senior advisor who handles this regularly — let me bring them in so you get a proper answer."

You have just told the client two things: that you take their question seriously, and that they have access to more expertise than one person. Both are reassuring.

WHAT NEVER TO DO

Never guess at a figure. Never say a product is guaranteed unless you have verified that it is. Never tell someone what a policy will pay out in a situation you have not confirmed.

A client who acts on your guess and finds out later that it was wrong has been harmed by you, whatever your intentions were. And the record of what you said will exist.

THE STANDARD

Ask yourself, before every recommendation: could I explain to a regulator why I said this, based on what I knew at the time?

If the answer is yes, proceed. If you hesitate, stop and ask someone.',
  3, 10
)
on conflict (id) do nothing;

insert into public.terminology (module_id, term, definition, sequence) values
('0a715001-0000-4000-8000-000000000001', 'Fact-find', 'The structured conversation in which an advisor gathers a client''s financial position, commitments, dependants and objectives before making any recommendation.', 1),
('0a715001-0000-4000-8000-000000000001', 'Suitability', 'Whether a recommendation genuinely fits the client''s circumstances, needs and risk tolerance. A suitable recommendation must follow from the facts gathered.', 2),
('0a715001-0000-4000-8000-000000000001', 'Escalation', 'Referring a question or case to a senior advisor because it falls outside your competence or authority.', 3)
on conflict do nothing;

insert into public.revision_cards (module_id, front, back, sequence) values
('0a715001-0000-4000-8000-000000000001', 'What are the three parts of an advisor''s role?', 'Understand where the client actually is; help them see what matters; recommend only what fits the facts you gathered.', 1),
('0a715001-0000-4000-8000-000000000001', 'What is the correct response to a question you cannot answer?', 'Say you want to give an accurate answer rather than a quick one, and that you will check and come back. Never guess.', 2),
('0a715001-0000-4000-8000-000000000001', 'What is the test to apply before any recommendation?', 'Could I explain to a regulator why I said this, based on what I knew at the time?', 3)
on conflict do nothing;

insert into public.quizzes (id, module_id, title, randomise_questions, randomise_answers)
values ('0a715003-0000-4000-8000-000000000001', '0a715001-0000-4000-8000-000000000001', 'Day 1 knowledge check', true, true)
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0a715004-0000-4000-8000-000000000001', '0a715003-0000-4000-8000-000000000001',
 'A client asks how a policy payout would be taxed. You have not been trained on tax treatment. What should you do?',
 'scenario',
 'Tax treatment is explicitly an escalation topic. Offering your best guess exposes the client to acting on wrong information, and exposes you to a complaint you cannot defend.', 1),
('0a715004-0000-4000-8000-000000000002', '0a715003-0000-4000-8000-000000000001',
 'What should an advisor do first in a first appointment with a new client?',
 'mcq',
 'Understanding the client''s position comes before any recommendation. A recommendation made before fact-finding is a guess with a product attached.', 2),
('0a715004-0000-4000-8000-000000000003', '0a715003-0000-4000-8000-000000000001',
 'You finish a fact-finding meeting and conclude the client needs nothing today. What does this mean?',
 'scenario',
 'Recommending nothing when nothing is suitable is a correct outcome. An advisor who always finds something to recommend is not advising.', 3),
('0a715004-0000-4000-8000-000000000004', '0a715003-0000-4000-8000-000000000001',
 'Which of these is the clearest sign that a first appointment is going badly?',
 'mcq',
 'A first appointment is for understanding the client. If the advisor is doing most of the talking, they are not learning anything.', 4),
('0a715004-0000-4000-8000-000000000005', '0a715003-0000-4000-8000-000000000001',
 'When should client meeting notes be written up?',
 'mcq',
 'The same day. Details you are certain you will remember are exactly the ones that disappear overnight.', 5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
-- Q1
('0a715004-0000-4000-8000-000000000001', 'Tell the client you will check and come back with an accurate answer, then escalate to a senior advisor', true, 1),
('0a715004-0000-4000-8000-000000000001', 'Give your best understanding, making clear it is only your opinion', false, 2),
('0a715004-0000-4000-8000-000000000001', 'Explain that tax is not something advisors discuss', false, 3),
('0a715004-0000-4000-8000-000000000001', 'Look it up on your phone during the meeting and read out what you find', false, 4),
-- Q2
('0a715004-0000-4000-8000-000000000002', 'Understand the client''s current position through fact-finding', true, 1),
('0a715004-0000-4000-8000-000000000002', 'Present the product range so the client knows what is available', false, 2),
('0a715004-0000-4000-8000-000000000002', 'Establish the client''s budget so you know what they can afford', false, 3),
('0a715004-0000-4000-8000-000000000002', 'Explain your commission structure for transparency', false, 4),
-- Q3
('0a715004-0000-4000-8000-000000000003', 'This is a correct outcome — recommending nothing is appropriate when nothing is suitable', true, 1),
('0a715004-0000-4000-8000-000000000003', 'You have missed something and should review the fact-find again for an opportunity', false, 2),
('0a715004-0000-4000-8000-000000000003', 'You should recommend a small policy so the meeting produces an outcome', false, 3),
('0a715004-0000-4000-8000-000000000003', 'You should pass the client to a more experienced advisor who can find a need', false, 4),
-- Q4
('0a715004-0000-4000-8000-000000000004', 'The advisor is doing most of the talking', true, 1),
('0a715004-0000-4000-8000-000000000004', 'The client asks a lot of questions', false, 2),
('0a715004-0000-4000-8000-000000000004', 'The meeting runs longer than planned', false, 3),
('0a715004-0000-4000-8000-000000000004', 'The client has not brought their financial documents', false, 4),
-- Q5
('0a715004-0000-4000-8000-000000000005', 'The same day as the meeting', true, 1),
('0a715004-0000-4000-8000-000000000005', 'Within the week, once you have time to do them properly', false, 2),
('0a715004-0000-4000-8000-000000000005', 'Only if the meeting resulted in a recommendation', false, 3),
('0a715004-0000-4000-8000-000000000005', 'Before the follow-up appointment, so they are fresh', false, 4)
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Days 2 and 3 — enough structure to prove sequential unlocking
-- ---------------------------------------------------------------------------

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
select
  '0a715001-0000-4000-8000-000000000002',
  pd.id,
  'The Financial Planning Process',
  'foundations',
  'Protection, healthcare, emergency funds, savings, investment and retirement — what each is for, and the order they are usually addressed in.',
  '["Name the main areas of a financial plan","Explain why protection is usually addressed before investment","Distinguish a client need from a product"]'::jsonb,
  40, true, 1, 'draft'
from public.programme_days pd
where pd.template_id = '0a715000-0000-4000-8000-000000000001' and pd.day_number = 2
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
(
  '0a715002-0000-4000-8000-000000000004',
  '0a715001-0000-4000-8000-000000000002',
  'Needs before products',
  'A need is something true about a client''s life. A product is something you can buy.

They are not the same thing, and confusing them is the most common mistake new advisors make.

"This client needs a critical illness plan" is not a need. It is a product wearing a need''s clothing.

The need underneath it might be: "If this client were diagnosed with something serious and could not work for a year, their family would run out of money in about six weeks, and their mother''s care costs would fall to their brother."

That is a need. It is specific, it is true, and it came from fact-finding. Several different products might address it. So might a change in savings behaviour. So might nothing, if the client already has cover through their employer that you have not yet checked.

THE ORDER THINGS ARE USUALLY ADDRESSED IN

There is a rough sequence most financial plans follow, and it is worth understanding why.

Protection comes early because it is the only part that fails catastrophically. If an investment underperforms, the client is poorer than they hoped. If an uninsured earner dies, a family loses its home.

Emergency funds come early for the same reason — they stop a small problem becoming a large one.

Savings and investment come after, because they assume the client will still be there and still earning.

Retirement runs alongside everything, because it is the one certainty in the list.

This is a general pattern, not a rule. A client of sixty with no dependants and a full CPF balance has a very different starting point from a thirty-year-old with two children and a mortgage. The order follows the facts, not the other way round.',
  1, 14
)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title)
values ('0a715003-0000-4000-8000-000000000002', '0a715001-0000-4000-8000-000000000002', 'Day 2 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0a715004-0000-4000-8000-000000000006', '0a715003-0000-4000-8000-000000000002',
 'Which of these is a client need rather than a product?', 'mcq',
 'A need describes something true about the client''s circumstances. A product is one possible response to it.', 1),
('0a715004-0000-4000-8000-000000000007', '0a715003-0000-4000-8000-000000000002',
 'Why is protection usually addressed before investment?', 'mcq',
 'Protection covers the outcomes that fail catastrophically. An underperforming investment disappoints; an uninsured death can cost a family their home.', 2),
('0a715004-0000-4000-8000-000000000008', '0a715003-0000-4000-8000-000000000002',
 'A client already has critical illness cover through their employer. What should you do?', 'scenario',
 'Existing cover is part of the fact-find. Recommending on top of cover you have not examined is not advice.', 3)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0a715004-0000-4000-8000-000000000006', 'If this client stopped working tomorrow, their family would run out of money in six weeks', true, 1),
('0a715004-0000-4000-8000-000000000006', 'This client needs a critical illness plan', false, 2),
('0a715004-0000-4000-8000-000000000006', 'This client needs an endowment policy for their child''s education', false, 3),
('0a715004-0000-4000-8000-000000000006', 'This client needs to increase their monthly premium', false, 4),

('0a715004-0000-4000-8000-000000000007', 'Protection covers the outcomes that fail catastrophically rather than merely disappointingly', true, 1),
('0a715004-0000-4000-8000-000000000007', 'Protection products pay higher commission', false, 2),
('0a715004-0000-4000-8000-000000000007', 'Investment products require more paperwork', false, 3),
('0a715004-0000-4000-8000-000000000007', 'Regulations require protection to be sold first', false, 4),

('0a715004-0000-4000-8000-000000000008', 'Find out what the existing cover actually provides before recommending anything further', true, 1),
('0a715004-0000-4000-8000-000000000008', 'Recommend additional cover, since employer schemes are always insufficient', false, 2),
('0a715004-0000-4000-8000-000000000008', 'Move on to another area, since this need is already met', false, 3),
('0a715004-0000-4000-8000-000000000008', 'Advise them to cancel the employer cover and replace it', false, 4)
on conflict do nothing;

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
select
  '0a715001-0000-4000-8000-000000000003',
  pd.id,
  'Conducting a Fact-Find',
  'foundations',
  'What to ask, how to ask it, and why a recommendation made before this point is not advice.',
  '["Gather income, expenses, assets, liabilities, dependants and existing cover","Ask permission before personal questions","Summarise a client''s position back to them accurately"]'::jsonb,
  40, true, 1, 'draft'
from public.programme_days pd
where pd.template_id = '0a715000-0000-4000-8000-000000000001' and pd.day_number = 3
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
(
  '0a715002-0000-4000-8000-000000000005',
  '0a715001-0000-4000-8000-000000000003',
  'What to ask, and how',
  'A fact-find covers six areas. Most new advisors can list them. Fewer can ask about them without sounding like they are reading a form.

THE SIX AREAS

Income — what comes in, from where, and how reliably. A salaried employee and a commission-earning business owner have different exposure to the same event.

Expenses — what goes out. Most people underestimate this by a wide margin. Asking "what do you spend each month?" produces a guess. Asking "what are your fixed commitments — housing, transport, dependants, insurance?" produces a figure.

Assets and liabilities — what they own and what they owe. The mortgage matters more than the property value for most planning purposes.

Dependants — who relies on this person financially. Not just children. Ageing parents are the commonly missed answer in Singapore, and often the largest single exposure.

Existing cover — what they already have, including through their employer and through CPF. You cannot identify a gap without knowing what is already filled.

Objectives — what they actually want. Ask, do not assume.

HOW TO ASK

Ask permission first. "Some of this is personal — is that alright?"

Ask open questions, then narrow. "Tell me about your family" before "how many children do you have?" The open version tells you about the parent nobody mentioned.

Let silence do some work. When someone pauses after answering, they are often deciding whether to tell you the rest. Filling that silence costs you the rest.

Write down what they say, not what you understood. These differ more often than you would expect.

SUMMARISE BEFORE YOU FINISH

"Let me check I have this right." Then say it back — position, commitments, dependants, what they said matters most.

Two things happen. You catch your errors while they are still cheap to fix. And the client hears their own situation described clearly, often for the first time, which is frequently the moment they decide you are worth listening to.

WHY THIS COMES FIRST

A recommendation that does not follow from a fact-find cannot be justified — not to the client, not to your manager, and not to a regulator.

If you find yourself forming a recommendation in the first ten minutes of a meeting, you are guessing. Write the thought down and carry on asking.',
  1, 15
)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title)
values ('0a715003-0000-4000-8000-000000000003', '0a715001-0000-4000-8000-000000000003', 'Day 3 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0a715004-0000-4000-8000-000000000009', '0a715003-0000-4000-8000-000000000003',
 'Which dependant is most commonly missed during fact-finding in Singapore?', 'mcq',
 'Ageing parents are frequently overlooked and often represent the largest single financial exposure a client has.', 1),
('0a715004-0000-4000-8000-00000000000a', '0a715003-0000-4000-8000-000000000003',
 'A client pauses for several seconds after answering a question. What is usually the best response?', 'scenario',
 'A pause after an answer often means the client is deciding whether to tell you the rest. Filling the silence costs you that information.', 2),
('0a715004-0000-4000-8000-00000000000b', '0a715003-0000-4000-8000-000000000003',
 'You form a clear view of what the client needs ten minutes into the first meeting. What should you do?', 'scenario',
 'A view formed before the fact-find is complete is a guess. Note it and keep gathering facts — you may be right, but you cannot yet justify it.', 3)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0a715004-0000-4000-8000-000000000009', 'Ageing parents', true, 1),
('0a715004-0000-4000-8000-000000000009', 'Children under 18', false, 2),
('0a715004-0000-4000-8000-000000000009', 'A spouse who works full time', false, 3),
('0a715004-0000-4000-8000-000000000009', 'Siblings living overseas', false, 4),

('0a715004-0000-4000-8000-00000000000a', 'Wait — they may be deciding whether to tell you more', true, 1),
('0a715004-0000-4000-8000-00000000000a', 'Move to the next question to keep the meeting on schedule', false, 2),
('0a715004-0000-4000-8000-00000000000a', 'Rephrase the question, as they may not have understood', false, 3),
('0a715004-0000-4000-8000-00000000000a', 'Offer an example answer to make it easier for them', false, 4),

('0a715004-0000-4000-8000-00000000000b', 'Note the thought and continue fact-finding until it is complete', true, 1),
('0a715004-0000-4000-8000-00000000000b', 'Share it immediately, as clients value decisiveness', false, 2),
('0a715004-0000-4000-8000-00000000000b', 'Steer the remaining questions towards confirming your view', false, 3),
('0a715004-0000-4000-8000-00000000000b', 'End the fact-find early, since you have what you need', false, 4)
on conflict do nothing;

commit;


-- ----------------------------------------------------------------------
-- supabase/seed/02-scripts-concepts-rubrics.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — seed: scripts, concept presentations and scoring rubrics
--
-- Optional and idempotent. Everything lands as `draft` for review; nothing here
-- self-publishes, because statements about suitability and disclosure need a
-- human with MAS/FAA accountability to approve them before an advisor learns
-- from them.
--
-- All wording and every diagram is original work authored for ATLAS. Nothing
-- reproduces another organisation's training material.

begin;

-- ===========================================================================
-- SCRIPTS — the six launch conversations
-- ===========================================================================

insert into public.scripts (id, title, situation, objective, wording, talking_points, variations, common_mistakes, compliance_note, sequence, status)
values
(
  '0c000000-0000-4000-8000-000000000001',
  'Cold call',
  'Calling someone who does not know you, from a list you are entitled to call.',
  'Secure a short meeting. Nothing else. You are not selling anything on this call.',
  'Hello, is that {name}? My name is {your name}, I''m a financial advisor with {firm}.

I''ll be brief — I know I''ve caught you unexpectedly.

I work with people in {area or profession} on their insurance and retirement planning. I''m not going to try to sell you anything over the phone; that isn''t how this works.

What I''d like is twenty minutes to understand your situation and tell you whether there''s anything worth looking at. If there isn''t, I''ll say so.

Would sometime next week suit you better, or is this a bad time entirely?',
  '["Say who you are and where you are from in the first sentence","Acknowledge that you have interrupted them","State plainly that you are not selling on this call","Ask for a specific, small commitment: twenty minutes","Offer them an easy way to say no"]'::jsonb,
  '["If they sound rushed: \"I can hear you''re busy — shall I try you another time?\" and mean it","If they ask what it is about: \"Protection and retirement planning, mostly. Whether any of it applies to you is exactly what I''d want twenty minutes to find out.\""]'::jsonb,
  '["Talking for more than about thirty seconds before asking a question","Promising something you cannot deliver to get the meeting","Pushing after a clear no. It costs you the referral and your reputation","Reading this aloud word for word — it is audible, and it works against you"]'::jsonb,
  'Do not describe or recommend any product on a cold call. Do not claim or imply an endorsement by any organisation. If the person asks not to be contacted again, record it and honour it.',
  1, 'draft'
),
(
  '0c000000-0000-4000-8000-000000000002',
  'Referral call',
  'Calling someone whose name an existing client gave you, with that client''s permission.',
  'Convert the goodwill of the referral into a meeting, without leaning on it too heavily.',
  'Hi {name}, this is {your name} — {referrer} suggested I give you a call.

I''m the financial advisor {referrer} works with. They mentioned you''d recently {reason: bought a flat / had a baby / changed jobs}, and thought a conversation might be useful.

I should say straight away that {referrer} hasn''t told me anything about your finances — just that you might find it worth a chat.

Would you be open to twenty minutes so I can understand your situation? If there''s nothing useful I can do, I''ll tell you that.',
  '["Name the referrer immediately — it is the reason they are still on the line","Say why they were referred, if you know","Make clear the referrer shared nothing confidential","Ask for the same small commitment as a cold call"]'::jsonb,
  '["If they seem unsure who the referrer is: \"You may know them from {context}. Either way, I don''t want to presume — would a short conversation be useful or not?\""]'::jsonb,
  '["Overstating what the referrer said. It gets back to them","Implying the referrer endorses a product","Treating the referral as an obligation on their part","Forgetting to thank the referrer afterwards, whatever the outcome"]'::jsonb,
  'Never disclose anything about the referrer''s own financial situation, holdings or arrangements. Confirm you have the referrer''s permission before making the call.',
  2, 'draft'
),
(
  '0c000000-0000-4000-8000-000000000003',
  'Social media lead follow-up',
  'Someone has responded to a post, an advertisement or an enquiry form online.',
  'Move the conversation off the platform and into a proper meeting, quickly, while their interest is live.',
  'Hi {name}, thanks for getting in touch about {topic}.

I''m {your name}, a financial advisor with {firm}.

Rather than trying to answer this properly over messages, it would be much more useful to speak — twenty minutes, and I can give you an answer that actually fits your situation rather than a general one.

Are you free {two specific options}? If neither works, tell me what does.',
  '["Reply fast. Interest from an online enquiry decays within hours","Do not attempt to answer a substantive financial question in a message","Offer two concrete times rather than asking when they are free","Keep it short — long messages read as a sales pitch"]'::jsonb,
  '["If they push for an answer in writing: \"I can give you a general answer here, but it may not apply to you, and I would rather not give you something misleading. Twenty minutes and I can be accurate.\""]'::jsonb,
  '["Giving specific advice in a public comment thread","Answering at length in writing, which usually ends the conversation","Waiting a day to reply","Copying the same message to everyone regardless of what they asked"]'::jsonb,
  'Do not give personal recommendations in writing before a fact-find. Public replies must not name products or imply suitability. Follow your firm''s rules on personal social media use.',
  3, 'draft'
),
(
  '0c000000-0000-4000-8000-000000000004',
  'Appointment confirmation',
  'Sent the day before a scheduled meeting.',
  'Prevent a no-show, and set expectations so the meeting starts well.',
  'Hi {name}, confirming our meeting tomorrow at {time}, at {place}.

We''ll spend about {duration} going through your current situation — income, commitments, anything you already have in place, and what you''d like to be true in a few years.

Nothing to prepare. If you happen to have details of any existing policies to hand, that''s useful, but don''t go hunting for them.

See you tomorrow. If anything changes, just message me.',
  '["Restate the time and place — it is the single most effective thing you can do to prevent a no-show","Say what will happen, so they arrive without dread","Ask for little or nothing in preparation","Make it easy to reschedule rather than simply not turn up"]'::jsonb,
  '["For a virtual meeting, include the link in the same message","If they have never met you: add one line on what you look like or where to find you"]'::jsonb,
  '["Not sending it at all, which is the most common cause of a wasted morning","Asking them to prepare a lot of documents, which creates a reason to postpone","Sending it a week ahead rather than the day before"]'::jsonb,
  'Do not include product information or any recommendation in a confirmation message.',
  4, 'draft'
),
(
  '0c000000-0000-4000-8000-000000000005',
  'First appointment opening',
  'The first few minutes of a first meeting, face to face.',
  'Set the agenda, get permission to ask personal questions, and establish that this meeting is about them rather than about you.',
  'Thanks for making the time.

Let me tell you how I''d like to use the next {duration}, and you can tell me if you''d rather do it differently.

First, I''d like to understand where you are now — what comes in, what goes out, what you already have in place, and who depends on you. Some of that is quite personal, so tell me if you''d rather not answer something.

Then I''d like to hear what you actually want. Not in general terms — specifically, what you''d like to be true in five or ten years.

At the end I''ll tell you honestly whether there''s anything worth doing. Sometimes the answer is no, and if that''s the case I''ll say so.

I''m not going to recommend anything today. I''d rather understand properly first.

Does that sound reasonable? Anything you''d like to add to the list?',
  '["Set the shape of the meeting in the first minute — people relax when they know what is coming","Ask permission before personal questions","Say explicitly that you may recommend nothing","Say explicitly that you will not recommend anything today","Invite them to add to the agenda, and mean it"]'::jsonb,
  '["If they open by asking about a specific product: \"Happy to come to that — can I understand your situation first, so I can tell you whether it fits?\""]'::jsonb,
  '["Talking about yourself and your firm for ten minutes","Skipping the permission step, which makes the personal questions feel intrusive","Promising a recommendation today, which pressures you into a bad one","Not agreeing a finish time"]'::jsonb,
  'Do not make any recommendation before the fact-find is complete. A recommendation that does not follow from the facts gathered cannot be justified.',
  5, 'draft'
),
(
  '0c000000-0000-4000-8000-000000000006',
  'Follow-up after a presentation',
  'A few days after presenting a recommendation, with no decision yet.',
  'Find out where they actually are, without applying pressure.',
  'Hi {name}, following up on our conversation on {day}.

No pressure at all — I''m not chasing a decision. I wanted to check whether anything I said didn''t land properly, or whether a question has come up since.

That happens often. People think of the important question on the drive home.

If you''d like to talk it through again, or with your {spouse/partner}, I''m happy to. And if you''ve decided it isn''t for you, that''s completely fine — just tell me, and I''ll stop following up.',
  '["Open by removing the pressure, honestly","Invite the question they thought of afterwards","Offer to include the person they need to consult","Give them explicit permission to say no, and honour it"]'::jsonb,
  '["If they have gone quiet after two attempts: \"I don''t want to keep appearing in your inbox. I''ll leave it with you — if it becomes useful, you know where I am.\""]'::jsonb,
  '["Manufacturing urgency that does not exist","Following up more often than weekly","Treating silence as encouragement","Never actually stopping"]'::jsonb,
  'Do not create false urgency about rates, availability or deadlines. If the client says no, record it and stop.',
  6, 'draft'
)
on conflict (id) do nothing;

-- ===========================================================================
-- CONCEPT PRESENTATIONS
--
-- Both diagrams below are original SVG authored for ATLAS.
-- ===========================================================================

insert into public.concept_presentations (
  id, name, purpose, suitable_situations, when_not_to_use, diagram_svg,
  steps, discovery_questions, transition, common_mistakes, compliance_note,
  is_required, sequence, status
)
values
(
  '0d000000-0000-4000-8000-000000000001',
  'Four Pillars of Financial Planning',
  'Shows a client that a financial plan has several distinct jobs, and that they are usually addressed in a particular order. Useful for someone who has never thought about their finances as a whole.',
  'A first appointment with someone who has no existing plan, or a scattered collection of products bought one at a time without a structure.',
  'Do not use it with a client who already has a well-organised plan and a specific question — it will feel like being taught something they already know. Do not use it to imply they need a product in every pillar.',
  '<svg viewBox="0 0 480 260" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Four pillars of financial planning: Protection, Emergency Fund, Savings and Investment, Retirement, supporting a roof labelled Financial Security">
  <title>Four Pillars of Financial Planning</title>
  <rect x="30" y="34" width="420" height="26" rx="4" fill="#082f4e"/>
  <text x="240" y="52" text-anchor="middle" fill="#f8fafc" font-family="sans-serif" font-size="14" font-weight="600">Financial Security</text>
  <g font-family="sans-serif" font-size="11" fill="#0f172a" text-anchor="middle">
    <rect x="42" y="72" width="88" height="140" rx="4" fill="#0e558b" opacity="0.12" stroke="#0e558b"/>
    <text x="86" y="132" font-weight="600">Protection</text>
    <text x="86" y="150" font-size="9" fill="#64748b">If income stops</text>
    <rect x="146" y="72" width="88" height="140" rx="4" fill="#0e558b" opacity="0.12" stroke="#0e558b"/>
    <text x="190" y="132" font-weight="600">Emergency</text>
    <text x="190" y="146" font-weight="600">Fund</text>
    <text x="190" y="164" font-size="9" fill="#64748b">If something breaks</text>
    <rect x="250" y="72" width="88" height="140" rx="4" fill="#0e558b" opacity="0.12" stroke="#0e558b"/>
    <text x="294" y="126" font-weight="600">Savings &amp;</text>
    <text x="294" y="140" font-weight="600">Investment</text>
    <text x="294" y="158" font-size="9" fill="#64748b">To grow</text>
    <rect x="354" y="72" width="88" height="140" rx="4" fill="#0e558b" opacity="0.12" stroke="#0e558b"/>
    <text x="398" y="132" font-weight="600">Retirement</text>
    <text x="398" y="150" font-size="9" fill="#64748b">When work stops</text>
  </g>
  <rect x="30" y="220" width="420" height="14" rx="3" fill="#64748b" opacity="0.35"/>
  <text x="240" y="250" text-anchor="middle" fill="#64748b" font-family="sans-serif" font-size="10">Built on knowing where you actually are today</text>
</svg>',
  '["Draw the roof first and name it: financial security, or whatever phrase the client used","Explain that a roof needs pillars, and that a missing pillar is not obvious until it is tested","Take each pillar in turn, in order, and ask what they have there now","Do not fill in the pillars yourself — ask, and write down what they say","Stand back and let them look at it. The gaps become their observation rather than your claim","Ask which gap concerns them most, and start there"]'::jsonb,
  '["If your income stopped tomorrow, how long could the household continue as it is?","If something expensive broke this month, where would the money come from?","What are you setting aside at the moment, and what is it for?","Have you ever looked at what your CPF would actually provide at 65?","Of the four, which one keeps you awake?"]'::jsonb,
  'You have told me a fair amount. Can I show you how I think about all of this — it will take about five minutes, and it might make the rest of the conversation easier.',
  '["Presenting all four pillars and then recommending a product for each","Filling in the pillars yourself instead of asking","Using it as a diagnostic to find the largest sale rather than the largest gap","Rushing it. It takes five minutes and works because it is unhurried"]'::jsonb,
  'This is an explanatory framework, not a recommendation. Do not imply that every client needs a product in every pillar, and do not use it to justify a recommendation that the fact-find does not support.',
  true, 1, 'draft'
),
(
  '0d000000-0000-4000-8000-000000000002',
  'Family Income Ladder',
  'Makes visible how long a household could continue if the main income stopped. Turns an abstract worry into a number of months.',
  'A client with dependants and an income the household relies on. Particularly effective with someone who says they "probably have enough".',
  'Do not use it with a client who has no dependants and no financial obligations to anyone — it will not land, and it risks sounding like fear-selling. Do not use it immediately after a bereavement without judgement.',
  '<svg viewBox="0 0 480 280" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Family income ladder showing months of household expenses covered by savings, then a gap, then the years of support still needed">
  <title>Family Income Ladder</title>
  <line x1="60" y1="40" x2="60" y2="230" stroke="#94a3b8" stroke-width="2"/>
  <line x1="60" y1="230" x2="450" y2="230" stroke="#94a3b8" stroke-width="2"/>
  <text x="30" y="46" font-family="sans-serif" font-size="10" fill="#64748b">$</text>
  <text x="440" y="252" font-family="sans-serif" font-size="10" fill="#64748b">time</text>
  <rect x="70" y="60" width="70" height="170" fill="#15803d" opacity="0.18" stroke="#15803d"/>
  <text x="105" y="150" text-anchor="middle" font-family="sans-serif" font-size="10" font-weight="600" fill="#0f172a">Savings</text>
  <text x="105" y="165" text-anchor="middle" font-family="sans-serif" font-size="9" fill="#64748b">3 months</text>
  <rect x="150" y="60" width="290" height="170" fill="#b91c1c" opacity="0.10" stroke="#b91c1c" stroke-dasharray="5 4"/>
  <text x="295" y="140" text-anchor="middle" font-family="sans-serif" font-size="11" font-weight="600" fill="#b91c1c">The gap</text>
  <text x="295" y="158" text-anchor="middle" font-family="sans-serif" font-size="9" fill="#64748b">Years the household still needs support</text>
  <line x1="70" y1="52" x2="440" y2="52" stroke="#0e558b" stroke-width="1.5"/>
  <text x="255" y="44" text-anchor="middle" font-family="sans-serif" font-size="10" fill="#0e558b">Monthly cost of running the household</text>
</svg>',
  '["Ask what the household costs to run each month, and write the figure down","Ask what is available in accessible savings, and draw that as the first block","Convert it into months out loud, and let the number sit","Ask how long the household would need support for — until the youngest finishes school, usually","Draw that span. The gap between the two is the concept","Ask what they would want to happen in that gap. Do not answer for them"]'::jsonb,
  '["Roughly what does it cost to run your household each month?","What could you get hold of quickly if you needed it?","Who depends on your income, and for how many more years?","Has anyone in the family ever been through this?","What would you want to happen for them?"]'::jsonb,
  'Can I sketch something out? It takes a few minutes and it usually makes this easier to think about than talking in the abstract.',
  '["Exaggerating the gap for effect. The real number is usually alarming enough","Presenting it and moving straight to a product","Using it on someone with no dependants","Not pausing after the months figure. The silence is doing the work","Guessing at figures instead of asking"]'::jsonb,
  'Use only figures the client has given you. Do not present projections as certainties, and do not imply a specific product is the only answer to the gap.',
  true, 2, 'draft'
),
(
  '0d000000-0000-4000-8000-000000000003',
  'Life Journey Timeline',
  'Maps expected life events against the years, so a client can see when demands on their money cluster.',
  'A client in their late twenties or thirties with several life events ahead — marriage, property, children — that they have not yet thought about together.',
  'Not useful for a client already past most of the events on it.',
  null,
  '["Draw a line and mark today","Ask what they expect over the next fifteen years, and mark each one","Ask roughly what each event costs","Let them see where events cluster"]'::jsonb,
  '["What do you expect to happen in the next ten years?","Which of these have you already started putting money aside for?"]'::jsonb,
  'Shall we map out what''s coming?',
  '["Assuming a conventional life path","Presenting it as inevitable rather than as their plan"]'::jsonb,
  'Explanatory only. Do not present life events as certainties or use the timeline to imply urgency.',
  false, 3, 'draft'
),
(
  '0d000000-0000-4000-8000-000000000004',
  'Education Funding Timeline',
  'Shows the years remaining before a child''s education costs begin, and what regular saving over that period looks like.',
  'A parent with young children who has not started saving for education.',
  'Not appropriate where more urgent protection gaps are unaddressed — fix those first.',
  null,
  '["Ask the child''s age and work forward to the first year of tertiary education","Mark the number of years available","Discuss what regular saving over that period could look like, without projecting returns"]'::jsonb,
  '["How old are your children?","Have you thought about what you would like to be able to provide?"]'::jsonb,
  'Can I show you how the timing works?',
  '["Projecting investment returns as though they were certain","Using it before protection gaps are addressed"]'::jsonb,
  'Do not present any projected return as guaranteed. Education cost figures are illustrative and must be described as such.',
  false, 4, 'draft'
)
on conflict (id) do nothing;

-- ===========================================================================
-- RUBRIC — the twelve practical scoring categories
-- ===========================================================================

insert into public.rubrics (id, name, scope, description, pass_mark_pct, is_active)
values (
  '0e000000-0000-4000-8000-000000000001',
  'Client conversation',
  'practical',
  'Used for role-plays, concept presentations and the final practical assessment. Each criterion is scored 0 to 5.',
  70,
  true
)
on conflict (id) do nothing;

insert into public.rubric_criteria (rubric_id, name, description, max_score, sequence)
values
  ('0e000000-0000-4000-8000-000000000001', 'Accuracy', 'Everything stated was factually correct. Nothing was invented or guessed at.', 5, 1),
  ('0e000000-0000-4000-8000-000000000001', 'Clarity', 'A client with no financial background would have followed it.', 5, 2),
  ('0e000000-0000-4000-8000-000000000001', 'Structure', 'The conversation had a shape. The client knew where it was going.', 5, 3),
  ('0e000000-0000-4000-8000-000000000001', 'Confidence', 'Composed without being brittle. Comfortable saying "I don''t know".', 5, 4),
  ('0e000000-0000-4000-8000-000000000001', 'Client engagement', 'The client did a fair share of the talking and stayed involved.', 5, 5),
  ('0e000000-0000-4000-8000-000000000001', 'Question quality', 'Questions opened the conversation up rather than closing it down.', 5, 6),
  ('0e000000-0000-4000-8000-000000000001', 'Listening', 'Answers were heard and used. Follow-up questions built on what was said.', 5, 7),
  ('0e000000-0000-4000-8000-000000000001', 'Suitability awareness', 'Nothing was suggested that the gathered facts did not support.', 5, 8),
  ('0e000000-0000-4000-8000-000000000001', 'Risk explanation', 'Limitations, exclusions and risks were stated plainly, not buried.', 5, 9),
  ('0e000000-0000-4000-8000-000000000001', 'Professionalism', 'Manner, punctuality and presentation were appropriate throughout.', 5, 10),
  ('0e000000-0000-4000-8000-000000000001', 'Ethical and compliant language', 'No guarantees implied, no pressure applied, no overstatement.', 5, 11),
  ('0e000000-0000-4000-8000-000000000001', 'Next-step transition', 'The meeting closed with a specific, agreed next step.', 5, 12)
on conflict do nothing;

commit;
