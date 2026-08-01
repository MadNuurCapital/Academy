-- ATLAS Academy — seed: Days 23 to 27 (Practical Application)
--
-- These days are practice, not reading. Each module is a short briefing
-- followed by a role-play or fieldwork session assessed in person by a manager
-- against the twelve-criterion rubric.
--
-- Day 27 explicitly does NOT require a new advisor to lead a complete real
-- client meeting independently. Observe, assist or present one section — and an
-- approved simulation counts where no real appointment is available.
--
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
-- DAY 23 — Call and Appointment Role-Play
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000023-0000-4000-8000-000000000001', pg_temp.day_id(23),
  'Call and Appointment Role-Play', 'practical',
  'Four calls, practised aloud with a manager. The first time you say these words should not be to a real person.',
  '["Deliver a cold call, a referral call, an appointment set and a confirmation","Handle a refusal without becoming defensive","Sound like yourself rather than like a script"]'::jsonb,
  60, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000023-1000-4000-8000-000000000001','0f000023-0000-4000-8000-000000000001',
 'Briefing: four calls',
 'Today you practise aloud. Your manager plays the prospect and will not make it easy, because real prospects do not.

You will run four calls. Each is scored against the twelve-criterion rubric; the ones that matter most here are clarity, structure, listening and professionalism.

CALL 1 — COLD CALL

Objective: secure twenty minutes. Nothing else.

You will be interrupted. You will be asked what it is about. You may be told it is a bad time. All of that is normal.

Watch for: talking too long before asking a question; promising something to get the meeting; continuing after a clear no.

CALL 2 — REFERRAL CALL

Objective: convert goodwill into a meeting without leaning on it too heavily.

Name the referrer immediately, say why they suggested you, and make clear the referrer shared nothing confidential.

Watch for: overstating what the referrer said; implying an endorsement; treating the referral as an obligation on the prospect.

CALL 3 — SETTING THE APPOINTMENT

Objective: get a specific time in the diary.

Offer two concrete options. State a duration. Say plainly that you will not be recommending anything at this meeting.

Watch for: asking "when are you free?", which makes them do the work; leaving the duration vague; failing to confirm the location.

CALL 4 — CONFIRMATION

Objective: prevent a no-show.

Time, place, duration, what you will cover, nothing to prepare.

Watch for: forgetting it entirely, which is the most common cause of a wasted morning; asking them to gather documents, which creates a reason to postpone.

HOW TO PREPARE

Read the six scripts in the Script Library, then put them away.

You are not being assessed on reciting them. You are being assessed on whether you understand what each call is for and can conduct it in your own words. An advisor reading a script aloud is audible from the first sentence, and prospects hang up on it.

Practise once out loud before you arrive. Reading silently does not prepare your mouth for the words.

WHAT YOUR MANAGER WILL BE LOOKING FOR

Did you say who you were and where you were from, in the first sentence?
Did you ask for something small and specific?
Did you listen, or wait for your turn to speak?
When you were refused, did you accept it gracefully?
Did you sound like a person?',
 1, 12)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000023-2000-4000-8000-000000000001','0f000023-0000-4000-8000-000000000001','Day 23 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000023-3000-4000-8000-000000000001','0f000023-2000-4000-8000-000000000001',
 'Why should you put the script away before a role-play?','scenario',
 'You are assessed on understanding what the call is for, not on recitation. Reading aloud is audible from the first sentence and prospects hang up on it.',1),
('0f000023-3000-4000-8000-000000000002','0f000023-2000-4000-8000-000000000001',
 'When setting an appointment, why offer two specific times rather than asking when they are free?','mcq',
 'An open question makes the prospect do the work. Two options require only a decision.',2),
('0f000023-3000-4000-8000-000000000003','0f000023-2000-4000-8000-000000000001',
 'On a referral call, what must you make clear about the referrer?','mcq',
 'That they shared nothing confidential about the prospect''s finances. Overstating what a referrer said gets back to them.',3),
('0f000023-3000-4000-8000-000000000004','0f000023-2000-4000-8000-000000000001',
 'What is the most common cause of a wasted morning?','mcq',
 'Not sending the confirmation. It is the single most effective thing you can do to prevent a no-show.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000023-3000-4000-8000-000000000001','You are assessed on understanding the call, not reciting it — and reading aloud is audible',true,1),
('0f000023-3000-4000-8000-000000000001','Scripts are confidential and cannot be used in role-play',false,2),
('0f000023-3000-4000-8000-000000000001','It saves time during the assessment',false,3),
('0f000023-3000-4000-8000-000000000001','The rubric penalises any use of prepared wording',false,4),
('0f000023-3000-4000-8000-000000000002','An open question makes them do the work; two options require only a decision',true,1),
('0f000023-3000-4000-8000-000000000002','It makes you appear busier than you are',false,2),
('0f000023-3000-4000-8000-000000000002','It is required by the appointment-setting script',false,3),
('0f000023-3000-4000-8000-000000000002','It shortens the call',false,4),
('0f000023-3000-4000-8000-000000000003','That the referrer shared nothing confidential about their finances',true,1),
('0f000023-3000-4000-8000-000000000003','That the referrer is also a client of your firm',false,2),
('0f000023-3000-4000-8000-000000000003','That the referrer recommends the same products',false,3),
('0f000023-3000-4000-8000-000000000003','That the referrer will be told the outcome',false,4),
('0f000023-3000-4000-8000-000000000004','Not sending the appointment confirmation',true,1),
('0f000023-3000-4000-8000-000000000004','Arriving without product brochures',false,2),
('0f000023-3000-4000-8000-000000000004','Booking meetings too far ahead',false,3),
('0f000023-3000-4000-8000-000000000004','Failing to ask for referrals',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 24 — Fact-Finding Role-Play
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000024-0000-4000-8000-000000000001', pg_temp.day_id(24),
  'Fact-Finding Role-Play', 'practical',
  'A full first appointment, practised end to end. The single most important skill in the programme.',
  '["Run all six parts of a first meeting in order","Ask open questions and let silences work","Summarise a client''s position back accurately"]'::jsonb,
  75, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000024-1000-4000-8000-000000000001','0f000024-0000-4000-8000-000000000001',
 'Briefing: a full first appointment',
 'Forty minutes, start to finish, with your manager playing a client who has a complicated situation and will not volunteer it.

This is the most important practical in the programme. Everything downstream — the concept, the recommendation, the readiness decision — rests on whether you can do this.

THE SIX PARTS, IN ORDER

1. Rapport — two minutes
2. Agenda — say what you will cover, invite them to add
3. Permission — before the personal questions
4. Discovery — income, expenses, assets and liabilities, dependants, existing cover, objectives
5. Summary — say it back
6. Next step — a day, a purpose, a method

WHAT YOUR MANAGER WILL DO

They will give you a client with something buried: an ageing parent they support, a policy they have forgotten, a second job, a health issue they mention in passing and move on from.

They will not raise it unprompted. Whether you find it depends on whether you ask open questions and listen to the answers.

They may also give you a client who is guarded, or talkative and off-topic, or who wants to jump straight to products. Each requires different handling and none is unusual.

THE FOUR THINGS THAT SEPARATE A PASS FROM A FAIL

**Open before narrow.** "Tell me about your family" surfaces the parent that "how many children do you have?" never will.

**Silence.** When the client pauses after answering, wait. They are deciding whether to tell you the rest. Advisors lose more information to filling silence than to any other habit.

**Writing down what they said.** Not what you understood. These differ, and the difference is where recommendations go wrong.

**The summary.** Say their position back. If you get something wrong, they will correct you — and that correction is worth more than another ten minutes of questions.

WHAT WILL FAIL YOU

Recommending something. You do not have enough, and a recommendation formed in the room is a guess with a product attached.

Talking more than a third of the time.

Skipping permission and then asking about income.

Ending with "I''ll be in touch".

Missing the buried fact entirely — though how you respond when you find it late matters too.

HOW TO PREPARE

Re-read the Day 3 and Day 19 lessons. Write out the six areas on a single sheet and bring it. Using a prompt sheet is not cheating; forgetting to ask about dependants because you were trying to remember the list is worse.',
 1, 12)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000024-2000-4000-8000-000000000001','0f000024-0000-4000-8000-000000000001','Day 24 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000024-3000-4000-8000-000000000001','0f000024-2000-4000-8000-000000000001',
 'Your role-play client mentions a health issue in passing and moves on. What should you do?','scenario',
 'Come back to it. Something mentioned and moved past quickly is usually significant, and existing conditions materially affect what can be recommended.',1),
('0f000024-3000-4000-8000-000000000002','0f000024-2000-4000-8000-000000000001',
 'Which question is more likely to surface a dependant the client has not mentioned?','mcq',
 'The open one. "Tell me about your family" surfaces the parent that a closed question about children never will.',2),
('0f000024-3000-4000-8000-000000000003','0f000024-2000-4000-8000-000000000001',
 'Is bringing a prompt sheet to a fact-find acceptable?','scenario',
 'Yes. Forgetting to ask about dependants because you were trying to remember the list is far worse than referring to a sheet.',3),
('0f000024-3000-4000-8000-000000000004','0f000024-2000-4000-8000-000000000001',
 'What single action will fail this role-play regardless of everything else?','mcq',
 'Making a recommendation. You do not have enough information, and a recommendation formed in the room cannot be justified.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000024-3000-4000-8000-000000000001','Come back to it — something mentioned and moved past quickly is usually significant',true,1),
('0f000024-3000-4000-8000-000000000001','Let it go, as they clearly do not want to discuss it',false,2),
('0f000024-3000-4000-8000-000000000001','Note it for the application form later',false,3),
('0f000024-3000-4000-8000-000000000001','Ask about it only if recommending medical cover',false,4),
('0f000024-3000-4000-8000-000000000002','"Tell me about your family"',true,1),
('0f000024-3000-4000-8000-000000000002','"How many children do you have?"',false,2),
('0f000024-3000-4000-8000-000000000002','"Are you married?"',false,3),
('0f000024-3000-4000-8000-000000000002','"Does anyone else live with you?"',false,4),
('0f000024-3000-4000-8000-000000000003','Yes — forgetting to ask something because you were recalling the list is worse',true,1),
('0f000024-3000-4000-8000-000000000003','No, it signals inexperience to the client',false,2),
('0f000024-3000-4000-8000-000000000003','Only if the client agrees in advance',false,3),
('0f000024-3000-4000-8000-000000000003','Only during training, never with a real client',false,4),
('0f000024-3000-4000-8000-000000000004','Making a recommendation during the meeting',true,1),
('0f000024-3000-4000-8000-000000000004','Running slightly over time',false,2),
('0f000024-3000-4000-8000-000000000004','Referring to a prompt sheet',false,3),
('0f000024-3000-4000-8000-000000000004','Asking a question twice',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 25 — Concept and Product Explanation
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000025-0000-4000-8000-000000000001', pg_temp.day_id(25),
  'Concept and Product Explanation', 'practical',
  'Deliver one concept and explain two product categories, including their limitations.',
  '["Deliver a concept presentation in five minutes","Explain a protection and a savings category plainly","State limitations and risks, and check understanding"]'::jsonb,
  75, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000025-1000-4000-8000-000000000001','0f000025-0000-4000-8000-000000000001',
 'Briefing: five deliverables',
 'You will deliver five things today, to a manager playing a client who asks awkward questions.

1. ONE CONCEPT PRESENTATION

Four Pillars or Family Income Ladder — your choice, but justify it from the client profile you are given.

Five minutes. The client fills in the content; you ask the questions. Stop talking after the key figure.

2. ONE PROTECTION CATEGORY

Any of Days 4 to 11. Connect it to something the client told you, say what it does, say what it does not do, state the risks.

3. ONE SAVINGS OR INVESTMENT CATEGORY

Endowment or ILP. If you choose ILP, you must state plainly that the value can fall and the client may get back less than they paid.

4. LIMITATIONS AND RISKS

Not a separate section — woven into each explanation, in the same tone as the benefits. A limitation delivered apologetically fails this criterion.

5. CHECKING UNDERSTANDING

Not "does that make sense?". Ask them to explain it back to their spouse. Their answer tells you what actually landed, and if it comes back wrong, that is your explanation to fix.

WHAT YOUR MANAGER WILL ASK

Expect at least one question you cannot answer. That is deliberate.

The correct response is not to guess. "That is a good question and I want to get it right rather than fast — let me check and come back to you" scores well. A confident wrong answer scores zero and would, with a real client, be the beginning of a complaint.

Expect also a question testing whether you will overclaim: "So I''m fully covered then?" or "This is guaranteed to grow, right?"

The answer to both is no, said clearly.

COMMON FAILURES

Explaining a product that does not connect to anything the client said.
Rushing the limitations, or leaving them to the documentation.
Using a term without defining it.
Saying "guaranteed" about something that is not.
Answering a definition question from memory rather than escalating.',
 1, 12)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000025-2000-4000-8000-000000000001','0f000025-0000-4000-8000-000000000001','Day 25 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000025-3000-4000-8000-000000000001','0f000025-2000-4000-8000-000000000001',
 'Your assessor asks a question you cannot answer. What scores best?','scenario',
 'Saying you want to get it right rather than fast, and that you will check. A confident wrong answer scores zero and would begin a complaint with a real client.',1),
('0f000025-3000-4000-8000-000000000002','0f000025-2000-4000-8000-000000000001',
 'The client asks "so I''m fully covered then?" What is the correct answer?','scenario',
 'No, said clearly, followed by what is and is not covered. "Fully covered" is a phrase an advisor should never accept or use.',2),
('0f000025-3000-4000-8000-000000000003','0f000025-2000-4000-8000-000000000001',
 'If you explain an ILP, what must you state plainly?','mcq',
 'That the value can fall and the client may get back less than they paid in.',3),
('0f000025-3000-4000-8000-000000000004','0f000025-2000-4000-8000-000000000001',
 'Where should limitations appear in a product explanation?','mcq',
 'Woven through, in the same tone as the benefits. Delivered apologetically or left to the documentation, they fail the criterion.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000025-3000-4000-8000-000000000001','Say you want an accurate answer rather than a fast one, and that you will check',true,1),
('0f000025-3000-4000-8000-000000000001','Give your best understanding, flagged as approximate',false,2),
('0f000025-3000-4000-8000-000000000001','Redirect to something you do know',false,3),
('0f000025-3000-4000-8000-000000000001','Say the question is too technical for this meeting',false,4),
('0f000025-3000-4000-8000-000000000002','No, clearly — followed by what is and is not covered',true,1),
('0f000025-3000-4000-8000-000000000002','Yes, for the risks we have discussed',false,2),
('0f000025-3000-4000-8000-000000000002','Broadly, subject to the policy terms',false,3),
('0f000025-3000-4000-8000-000000000002','Yes, provided premiums are maintained',false,4),
('0f000025-3000-4000-8000-000000000003','That the value can fall and they may get back less than they paid',true,1),
('0f000025-3000-4000-8000-000000000003','That returns have historically exceeded inflation',false,2),
('0f000025-3000-4000-8000-000000000003','That the insurance component is guaranteed',false,3),
('0f000025-3000-4000-8000-000000000003','That charges are fixed for the life of the policy',false,4),
('0f000025-3000-4000-8000-000000000004','Woven through, in the same tone as the benefits',true,1),
('0f000025-3000-4000-8000-000000000004','At the end, briefly, so as not to lose momentum',false,2),
('0f000025-3000-4000-8000-000000000004','In the documentation the client takes away',false,3),
('0f000025-3000-4000-8000-000000000004','Only where the client asks about them',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 26 — Objection Handling and Case Study
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000026-0000-4000-8000-000000000001', pg_temp.day_id(26),
  'Objection Handling and Case Study', 'practical',
  'Respond to objections without pressure, then analyse a fictional client and resist deciding too early.',
  '["Find the concern underneath a stated objection","Identify missing information in a client profile","Explain why a product decision would be premature"]'::jsonb,
  75, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000026-1000-4000-8000-000000000001','0f000026-0000-4000-8000-000000000001',
 'Briefing: objections, then a case',
 'Two exercises today.

PART ONE — OBJECTIONS

Your manager will put five of the eight common objections to you, in a realistic tone rather than as a quiz.

For each, they are watching for one thing above all: do you ask what is actually behind it before responding?

"Can I ask what specifically is making you hesitate?"

An advisor who produces a polished answer to the stated objection has usually answered the wrong question. An advisor who asks first — and then listens — finds out whether there is a real obstacle, a misunderstanding, or a polite no.

You will also be tested on whether you accept a refusal. At some point your manager will say a clear no. The correct response is to thank them and stop. Continuing costs you the criterion, and with a real client costs you rather more.

PART TWO — THE CASE STUDY

You will be given a written client profile that is deliberately incomplete. You have twenty minutes to prepare, then you present your analysis.

What you must produce:

**What is missing.** The information you would need before recommending anything. Expect to find five or more gaps. Finding them is the exercise.

**What concerns you.** The planning issues visible from what you do have.

**Which concept you would use, and why.** Justified from their circumstances, not from preference.

**Why a product decision would be premature.** This is the criterion most advisors fail. There will be an obvious-looking product answer in the profile, and reaching for it is the trap.

WHAT A STRONG ANSWER SOUNDS LIKE

"On what I have, the largest visible exposure is that the household would run out of money in about two months if his income stopped, and Sarah''s income is about to reduce. But I do not know the sum assured on his existing policy, I do not know their actual expenditure as opposed to income, and I do not know whether the support to his mother is essential or discretionary. I would not recommend anything until I did — the gap could be a third of what it looks like, or twice."

That answer scores well because it separates what is known from what is assumed, and declines to guess at the difference.

WHAT A WEAK ANSWER SOUNDS LIKE

"He needs term cover of about half a million and a critical illness plan, and they should start an education endowment."

Confident, specific, and unsupported by the facts given. In a real meeting it would be a recommendation you could not justify to anyone who asked.',
 1, 13)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000026-2000-4000-8000-000000000001','0f000026-0000-4000-8000-000000000001','Day 26 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000026-3000-4000-8000-000000000001','0f000026-2000-4000-8000-000000000001',
 'In the case study, you spot an obvious-looking product answer. What should you do?','scenario',
 'Treat it as the trap it is. Explain what is missing and why a decision would be premature. Reaching for the obvious answer is the criterion most advisors fail.',1),
('0f000026-3000-4000-8000-000000000002','0f000026-2000-4000-8000-000000000001',
 'What distinguishes a strong case-study answer from a weak one?','mcq',
 'A strong answer separates what is known from what is assumed and declines to guess at the difference.',2),
('0f000026-3000-4000-8000-000000000003','0f000026-2000-4000-8000-000000000001',
 'Your manager gives a clear no during the objection exercise. What is the correct response?','scenario',
 'Thank them and stop. Continuing costs the criterion, and with a real client costs considerably more.',3),
('0f000026-3000-4000-8000-000000000004','0f000026-2000-4000-8000-000000000001',
 'You find only two gaps in the case profile. What does that most likely mean?','mcq',
 'You have not looked hard enough. These profiles are built with five or more gaps, and finding them is the exercise.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000026-3000-4000-8000-000000000001','Explain what is missing and why a decision would be premature',true,1),
('0f000026-3000-4000-8000-000000000001','Recommend it, since it clearly fits',false,2),
('0f000026-3000-4000-8000-000000000001','Recommend it with a caveat about needing more information',false,3),
('0f000026-3000-4000-8000-000000000001','Present two options and let the client choose',false,4),
('0f000026-3000-4000-8000-000000000002','It separates what is known from what is assumed, and does not guess at the difference',true,1),
('0f000026-3000-4000-8000-000000000002','It reaches a specific recommendation with figures',false,2),
('0f000026-3000-4000-8000-000000000002','It covers every product category available',false,3),
('0f000026-3000-4000-8000-000000000002','It is delivered confidently and without hesitation',false,4),
('0f000026-3000-4000-8000-000000000003','Thank them and stop',true,1),
('0f000026-3000-4000-8000-000000000003','Ask one more question to understand why',false,2),
('0f000026-3000-4000-8000-000000000003','Offer a smaller alternative',false,3),
('0f000026-3000-4000-8000-000000000003','Ask whether you may follow up in a few months',false,4),
('0f000026-3000-4000-8000-000000000004','You have not looked hard enough — these profiles carry five or more',true,1),
('0f000026-3000-4000-8000-000000000004','The profile was unusually complete',false,2),
('0f000026-3000-4000-8000-000000000004','Two gaps is the expected number',false,3),
('0f000026-3000-4000-8000-000000000004','The remaining gaps are not material',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 27 — Joint Fieldwork or Simulated Appointment
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000027-0000-4000-8000-000000000001', pg_temp.day_id(27),
  'Joint Fieldwork', 'practical',
  'A real appointment with a senior advisor, or an approved simulation. Observe, assist, or present one section — not lead.',
  '["Observe or assist at a real or simulated appointment","Present one section under supervision, if ready","Write a reflection that is honest rather than flattering"]'::jsonb,
  90, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000027-1000-4000-8000-000000000001','0f000027-0000-4000-8000-000000000001',
 'Briefing: watching someone who knows what they are doing',
 'Today you attend an appointment with a senior advisor. If no suitable real appointment is available, an approved simulation counts in full — that is deliberate, because a brand-new advisor should not be held back by whether a client happened to book that week.

YOU ARE NOT LEADING THIS

There are four roles, and you will be assigned one:

**Observe.** Sit in, take notes, say nothing except hello and goodbye.
**Assist.** Take notes formally, hand over documents, answer if asked directly.
**Present one section.** Deliver a defined part — usually your concept presentation — and hand back.
**Lead with supervision.** Rare at Day 27, and only if your manager judges you ready.

Nobody is required to lead a complete client meeting independently by Day 27. If you are asked to observe only, that is not a judgement about your ability — it is what the appointment needed.

WHAT TO WATCH FOR

**How they open.** Notice how quickly the agenda is set and how briefly they talk about themselves.

**How they ask.** Count the open questions. Notice what they do after an answer — most experienced advisors pause where you would speak.

**How they handle not knowing.** They will hit something they cannot answer. Watch what they do. It is almost never what a nervous new advisor expects.

**What they do not say.** No guarantees, no pressure, no manufactured urgency. Notice how much of good advising is restraint.

**The close.** Notice that it is usually an agreement about a next step, not an attempt at a signature.

CLIENT PRIVACY

You are attending someone else''s client meeting. Say almost nothing unless invited. Do not take away any client-identifying information — the fieldwork record has no field for it, and you should not have it in your notes either.

YOUR REFLECTION

You must write a reflection afterwards. It is part of the record and your manager reads it.

Write what you actually noticed, including what you would have got wrong. "I would have jumped in when she went quiet, and the pause got us the thing about her mother" is worth more than "it was a good meeting and I learned a lot".

An honest reflection showing you noticed something specific scores well. A flattering one shows you were not really paying attention.

WHAT IS RECORDED

Your manager completes a fieldwork record: appointment category, your role, skills observed, strengths, areas to improve, and a readiness recommendation. At least one such session — real or simulated — is required before your Day 30 review.',
 1, 13)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000027-2000-4000-8000-000000000001','0f000027-0000-4000-8000-000000000001','Day 27 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000027-3000-4000-8000-000000000001','0f000027-2000-4000-8000-000000000001',
 'Are you expected to lead a complete client meeting independently at Day 27?','mcq',
 'No. Observe, assist or present one section. Leading independently is not a Day 30 expectation, let alone a Day 27 one.',1),
('0f000027-3000-4000-8000-000000000002','0f000027-2000-4000-8000-000000000001',
 'No real client appointment is available in your window. What happens?','scenario',
 'An approved simulation counts in full. Nobody should be held back by whether a client happened to book that week.',2),
('0f000027-3000-4000-8000-000000000003','0f000027-2000-4000-8000-000000000001',
 'What makes a strong reflection?','mcq',
 'Something specific you noticed, including what you would have got wrong. A flattering reflection shows you were not paying close attention.',3),
('0f000027-3000-4000-8000-000000000004','0f000027-2000-4000-8000-000000000001',
 'What should you record about the client you observed?','mcq',
 'Nothing identifying. The fieldwork record captures the appointment category only, and your own notes should hold no more.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000027-3000-4000-8000-000000000001','No — observe, assist or present one section under supervision',true,1),
('0f000027-3000-4000-8000-000000000001','Yes, that is the purpose of Day 27',false,2),
('0f000027-3000-4000-8000-000000000001','Only if the client agrees in advance',false,3),
('0f000027-3000-4000-8000-000000000001','Yes, but with a senior advisor present',false,4),
('0f000027-3000-4000-8000-000000000002','An approved simulation counts in full towards the requirement',true,1),
('0f000027-3000-4000-8000-000000000002','The programme is extended until one is available',false,2),
('0f000027-3000-4000-8000-000000000002','The requirement is waived at the manager''s discretion',false,3),
('0f000027-3000-4000-8000-000000000002','You must find your own appointment to attend',false,4),
('0f000027-3000-4000-8000-000000000003','Something specific you noticed, including what you would have got wrong',true,1),
('0f000027-3000-4000-8000-000000000003','A positive summary showing you engaged with the process',false,2),
('0f000027-3000-4000-8000-000000000003','A full transcript of what was said',false,3),
('0f000027-3000-4000-8000-000000000003','An assessment of the senior advisor''s performance',false,4),
('0f000027-3000-4000-8000-000000000004','Nothing identifying — category only',true,1),
('0f000027-3000-4000-8000-000000000004','Their name and contact details for follow-up',false,2),
('0f000027-3000-4000-8000-000000000004','Their financial position, for your own learning',false,3),
('0f000027-3000-4000-8000-000000000004','Whatever the senior advisor recorded',false,4)
on conflict do nothing;

commit;
