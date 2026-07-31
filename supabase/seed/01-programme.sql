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
  45, true, 1, 'published'
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
  40, true, 1, 'published'
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
  40, true, 1, 'published'
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
