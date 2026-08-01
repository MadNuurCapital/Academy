-- ATLAS Academy — seed: Days 28 to 30 (Assessment and Readiness)
--
-- The Day 28 quiz and Day 29 practical are marked is_final = true. That flag is
-- not decorative: evaluate_completion_requirements looks for a passed final
-- knowledge assessment and a passed final practical, and both appear as
-- blockers on the readiness review until they exist.
--
-- Day 30 has no quiz. It is the manager's review, and the module exists to tell
-- the advisor what is being assessed and what the four outcomes actually mean.
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
-- DAY 28 — Final Knowledge Assessment
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000028-0000-4000-8000-000000000001', pg_temp.day_id(28),
  'Final Knowledge Assessment', 'assessment',
  'Everything from Days 1 to 27, in one assessment. Passing it is required before a readiness decision.',
  '["Demonstrate knowledge across all ten assessed areas","Apply judgement to scenarios rather than recalling facts","Recognise the limits of your own competence"]'::jsonb,
  60, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000028-1000-4000-8000-000000000001','0f000028-0000-4000-8000-000000000001',
 'What is assessed, and how to prepare',
 'This assessment covers the whole programme. You need 80% to pass, and there is no limit on attempts — but the next day stays locked until you do, and passing it is a requirement for your readiness review.

THE TEN AREAS

1. Advisor foundations — the role, professional conduct, knowing your limits
2. Financial planning fundamentals — needs versus products, and the usual order
3. Protection categories — hospitalisation, personal accident, term, whole life, critical illness, cancer, long-term care
4. Endowment plans — guaranteed versus non-guaranteed, and early surrender
5. Investment-linked policies — structure, risk, charges, suitability
6. CPF, BRS, FRS and ERS
7. HDB and housing commitments
8. Fact-finding — the six areas, and how to ask
9. Client conversation structure — introduction, appointment, concept, explanation, objections
10. Ethical and suitability awareness

WHAT IS ACTUALLY BEING TESTED

Not recall. Most questions are scenarios, and the right answer usually depends on judgement rather than memory.

Three themes run through the whole assessment:

**Do you know what a product does not do?** More questions turn on limitations than on benefits, because that is where clients are failed.

**Do you know when to escalate?** Several questions have a plausible-looking answer and a correct answer, and the correct one is often "check with a senior advisor". Recognising the edge of your competence is a competency in its own right.

**Would you guess?** Options that involve estimating a figure, approximating a definition, or giving a general answer to a specific question are wrong. Consistently.

HOW TO PREPARE

Work through the revision cards for each module. Re-read the Day 11 comparison lesson — the distinctions between categories account for a disproportionate share of the questions.

Re-read your own failed quiz attempts. The system keeps them, and the questions you got wrong the first time are the ones to look at.

Do not memorise answers to the module quizzes. The questions here are different, and an advisor who has memorised rather than understood is exactly what this assessment is designed to catch.

IF YOU DO NOT PASS

You may retake it. Nobody is judged on needing two attempts; several good advisors have.

What matters is the gap it reveals. Your manager will see which areas you scored poorly on, and the sensible response is to go back to those modules rather than immediately resitting.',
 1, 12)
on conflict (id) do nothing;

-- is_final drives the readiness blocker in evaluate_completion_requirements.
insert into public.quizzes (id, module_id, title, is_final, randomise_questions, randomise_answers) values
('0f000028-2000-4000-8000-000000000001','0f000028-0000-4000-8000-000000000001',
 'ATLAS Academy final knowledge assessment', true, true, true)
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000028-3000-4000-8000-000000000001','0f000028-2000-4000-8000-000000000001',
 'A client with no hospitalisation cover, no critical illness cover and two young children asks you about personal accident cover because a colleague recommended it. What is the most defensible response?','scenario',
 'Personal accident is narrow and covers accidents only. With no hospitalisation or critical illness cover, the larger exposures are unaddressed. Establish those first.',1),
('0f000028-3000-4000-8000-000000000002','0f000028-2000-4000-8000-000000000001',
 'Which statement about critical illness cover is accurate?','mcq',
 'It pays for defined conditions at defined severities. Describing it as covering serious illness generally is how claims come to be disputed.',2),
('0f000028-3000-4000-8000-000000000003','0f000028-2000-4000-8000-000000000001',
 'A client turning 55 asks what the Full Retirement Sum is. You are not certain of this year''s figure. What should you do?','scenario',
 'Check before answering. The retirement sums are revised annually, and a client acting on a remembered figure has been failed.',3),
('0f000028-3000-4000-8000-000000000004','0f000028-2000-4000-8000-000000000001',
 'An ILP illustration projects a value of $95,000 at maturity. How should this be presented?','scenario',
 'As a projection at an assumed rate, not a forecast. The value can fall and the client may get back less than they paid.',4),
('0f000028-3000-4000-8000-000000000005','0f000028-2000-4000-8000-000000000001',
 'Which is a client need rather than a product?','mcq',
 'A need describes something true about the client''s circumstances. The others name instruments.',5),
('0f000028-3000-4000-8000-000000000006','0f000028-2000-4000-8000-000000000001',
 'A client mentions in passing that they were investigated for a heart condition three years ago but "nothing came of it". What must happen?','scenario',
 'It must be declared. Non-disclosure can void a claim years later, and the client will remember who told them not to worry.',6),
('0f000028-3000-4000-8000-000000000007','0f000028-2000-4000-8000-000000000001',
 'During a first appointment the client falls silent after answering a question about their family. What should you do?','scenario',
 'Wait. A pause after an answer usually means they are deciding whether to tell you the rest.',7),
('0f000028-3000-4000-8000-000000000008','0f000028-2000-4000-8000-000000000001',
 'A client says "I need to think about it." What should you do first?','scenario',
 'Ask what specifically is making them hesitate. The stated objection is rarely the real one.',8),
('0f000028-3000-4000-8000-000000000009','0f000028-2000-4000-8000-000000000001',
 'Which client is a 25-year whole life policy least appropriate for?','scenario',
 'Someone whose need ends when the mortgage is repaid. Paying for permanent cover to meet a temporary need costs more than required.',9),
('0f000028-3000-4000-8000-00000000000a','0f000028-2000-4000-8000-000000000001',
 'A client asks how a policy payout would be taxed. You have not been trained on tax treatment. What is correct?','scenario',
 'Escalate. Tax is explicitly outside a new advisor''s competence, and an approximate answer the client acts on is a real harm.',10),
('0f000028-3000-4000-8000-00000000000b','0f000028-2000-4000-8000-000000000001',
 'Which of these should never appear in a client conversation?','mcq',
 'Manufactured urgency. The others are honest statements an advisor should be comfortable making.',11),
('0f000028-3000-4000-8000-00000000000c','0f000028-2000-4000-8000-000000000001',
 'A client servicing their mortgage largely from CPF asks about retirement. What is most relevant to mention?','scenario',
 'Ordinary Account savings used for housing are not available for retirement, so their position at 55 differs from someone who paid in cash.',12),
('0f000028-3000-4000-8000-00000000000d','0f000028-2000-4000-8000-000000000001',
 'You complete a fact-find and conclude the client needs nothing at present. What should you do?','scenario',
 'Tell them so. Recommending nothing when nothing is suitable is a correct outcome, and it is the fastest route to being trusted.',13),
('0f000028-3000-4000-8000-00000000000e','0f000028-2000-4000-8000-000000000001',
 'What distinguishes hospitalisation cover from critical illness cover?','mcq',
 'One pays the hospital; the other pays the client a lump sum on diagnosis, usable for anything.',14),
('0f000028-3000-4000-8000-00000000000f','0f000028-2000-4000-8000-000000000001',
 'A client surrenders an endowment after two years. What should they have been told at the outset?','scenario',
 'That early surrender typically returns considerably less than the premiums paid.',15)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000028-3000-4000-8000-000000000001','Explain what it covers, then establish their hospitalisation and critical illness position first',true,1),
('0f000028-3000-4000-8000-000000000001','Recommend it, since it is affordable and they asked',false,2),
('0f000028-3000-4000-8000-000000000001','Tell them their colleague is mistaken',false,3),
('0f000028-3000-4000-8000-000000000001','Recommend it alongside everything else in one package',false,4),

('0f000028-3000-4000-8000-000000000002','It pays for defined conditions at defined severities',true,1),
('0f000028-3000-4000-8000-000000000002','It covers any serious illness requiring hospitalisation',false,2),
('0f000028-3000-4000-8000-000000000002','It reimburses medical bills as they arise',false,3),
('0f000028-3000-4000-8000-000000000002','It pays out repeatedly for the same condition',false,4),

('0f000028-3000-4000-8000-000000000003','Say you will confirm the current figure and come back to them',true,1),
('0f000028-3000-4000-8000-000000000003','Give last year''s figure, noting it may have changed',false,2),
('0f000028-3000-4000-8000-000000000003','Estimate it from the Basic Retirement Sum',false,3),
('0f000028-3000-4000-8000-000000000003','Tell them the figure varies too much to state',false,4),

('0f000028-3000-4000-8000-000000000004','As a projection at an assumed rate — the value can fall and they may get back less',true,1),
('0f000028-3000-4000-8000-000000000004','As the expected maturity value',false,2),
('0f000028-3000-4000-8000-000000000004','As a conservative estimate of the likely outcome',false,3),
('0f000028-3000-4000-8000-000000000004','As guaranteed provided premiums are maintained',false,4),

('0f000028-3000-4000-8000-000000000005','If his income stopped, the household would run out of money in six weeks',true,1),
('0f000028-3000-4000-8000-000000000005','He needs a critical illness plan',false,2),
('0f000028-3000-4000-8000-000000000005','She needs an endowment for the children',false,3),
('0f000028-3000-4000-8000-000000000005','They need to increase their monthly premium',false,4),

('0f000028-3000-4000-8000-000000000006','It must be declared in full on the application',true,1),
('0f000028-3000-4000-8000-000000000006','It need not be declared, as nothing was diagnosed',false,2),
('0f000028-3000-4000-8000-000000000006','Declare it only if the insurer asks specifically',false,3),
('0f000028-3000-4000-8000-000000000006','Advise them to apply after five years have passed',false,4),

('0f000028-3000-4000-8000-000000000007','Wait — they may be deciding whether to tell you more',true,1),
('0f000028-3000-4000-8000-000000000007','Move to the next question to keep to time',false,2),
('0f000028-3000-4000-8000-000000000007','Rephrase, in case they misunderstood',false,3),
('0f000028-3000-4000-8000-000000000007','Offer an example answer to help them',false,4),

('0f000028-3000-4000-8000-000000000008','Ask what specifically is making them hesitate',true,1),
('0f000028-3000-4000-8000-000000000008','Summarise the benefits once more',false,2),
('0f000028-3000-4000-8000-000000000008','Offer a lower premium option',false,3),
('0f000028-3000-4000-8000-000000000008','Agree, and arrange to call in a week',false,4),

('0f000028-3000-4000-8000-000000000009','A client whose need ends when their mortgage is repaid in 20 years',true,1),
('0f000028-3000-4000-8000-000000000009','A client with a dependant who will always need support',false,2),
('0f000028-3000-4000-8000-000000000009','A client with an obligation that has no end date',false,3),
('0f000028-3000-4000-8000-000000000009','A client who specifically wants cover for life',false,4),

('0f000028-3000-4000-8000-00000000000a','Tell them you will check and come back, then escalate',true,1),
('0f000028-3000-4000-8000-00000000000a','Give your general understanding, flagged as approximate',false,2),
('0f000028-3000-4000-8000-00000000000a','Look it up during the meeting and read out what you find',false,3),
('0f000028-3000-4000-8000-00000000000a','Say advisors are not permitted to discuss tax at all',false,4),

('0f000028-3000-4000-8000-00000000000b','"This rate is only available until Friday"',true,1),
('0f000028-3000-4000-8000-00000000000b','"It covers accidents, not illness"',false,2),
('0f000028-3000-4000-8000-00000000000b','"I would like to check that with a colleague"',false,3),
('0f000028-3000-4000-8000-00000000000b','"You may get back less than you put in"',false,4),

('0f000028-3000-4000-8000-00000000000c','CPF used for housing is not available for retirement',true,1),
('0f000028-3000-4000-8000-00000000000c','CPF-serviced mortgages attract a higher interest rate',false,2),
('0f000028-3000-4000-8000-00000000000c','They should switch to servicing it in cash',false,3),
('0f000028-3000-4000-8000-00000000000c','Housing has no bearing on the retirement position',false,4),

('0f000028-3000-4000-8000-00000000000d','Tell them so — it is a correct outcome',true,1),
('0f000028-3000-4000-8000-00000000000d','Review the fact-find again to find something',false,2),
('0f000028-3000-4000-8000-00000000000d','Recommend a small policy so the meeting has an outcome',false,3),
('0f000028-3000-4000-8000-00000000000d','Pass them to a more experienced advisor',false,4),

('0f000028-3000-4000-8000-00000000000e','One pays the hospital; the other pays the client a lump sum on diagnosis',true,1),
('0f000028-3000-4000-8000-00000000000e','Critical illness covers more conditions',false,2),
('0f000028-3000-4000-8000-00000000000e','Hospitalisation pays faster',false,3),
('0f000028-3000-4000-8000-00000000000e','They are broadly equivalent',false,4),

('0f000028-3000-4000-8000-00000000000f','That early surrender typically returns far less than the premiums paid',true,1),
('0f000028-3000-4000-8000-00000000000f','That surrender values are set by the regulator',false,2),
('0f000028-3000-4000-8000-00000000000f','That the policy could not be surrendered before maturity',false,3),
('0f000028-3000-4000-8000-00000000000f','That surrendering would return all premiums plus interest',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 29 — Final Practical Assessment
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000029-0000-4000-8000-000000000001', pg_temp.day_id(29),
  'Final Practical Assessment', 'assessment',
  'One simulated client conversation containing all nine elements, assessed in person against the twelve-criterion rubric.',
  '["Conduct a complete client conversation from introduction to next step","Present a concept and explain a product category with its limitations","Handle an objection without pressure"]'::jsonb,
  90, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000029-1000-4000-8000-000000000001','0f000029-0000-4000-8000-000000000001',
 'The nine elements',
 'One conversation, about forty-five minutes, with a manager playing a client. It contains nine elements and you are assessed on all of them.

There is no recording. What your assessor writes at the time is the entire record, which is why the written feedback is as important as the score.

THE NINE ELEMENTS

1. **Professional introduction.** Who you are, what you do, how the process works, and that you will not recommend anything today. Under two minutes.

2. **Agenda setting.** What you will cover, roughly how long, and an invitation to add to it.

3. **Fact-finding.** All six areas: income, expenses, assets and liabilities, dependants, existing cover, objectives. Permission asked before the personal questions.

4. **Identification of a planning concern.** Something real, drawn from what they told you — not something you arrived intending to find.

5. **Concept presentation.** Four Pillars or Family Income Ladder, chosen for this client and justified. Five minutes. They fill it in, not you.

6. **General product-category explanation.** Connected to the concern you identified. Plain language. No named products required.

7. **Explanation of limitations or risks.** In the same tone as the benefits, not appended apologetically at the end.

8. **Objection handling.** Your assessor will raise at least one. Ask what is behind it before responding.

9. **Agreement on a next step.** A day, a purpose, a method.

HOW IT IS SCORED

The twelve-criterion rubric: accuracy, clarity, structure, confidence, client engagement, question quality, listening, suitability awareness, risk explanation, professionalism, ethical and compliant language, and next-step transition.

Each scored 0 to 5. You need 70% overall.

THE THINGS THAT FAIL PEOPLE

**Recommending a specific product.** You are explaining a category. Naming and recommending a product from a simulated fact-find is outside what this assessment asks for.

**Guessing.** You will be asked something you cannot answer. Say you will check.

**Overclaiming.** "Fully covered", "guaranteed to grow", "everyone your age has one". Any of these costs you the ethical language criterion outright.

**Talking too much.** If you are speaking more than a third of the time during fact-finding, you are not learning anything.

**Skipping the summary** because you are running out of time. Manage the time so you do not have to.

**Pressuring after the objection.** The assessor may push. Accepting a reasonable no is a pass; pushing through it is a fail on two criteria.

IF YOU DO NOT PASS

You may retake it. Your manager will give written feedback on which criteria fell short, and you must acknowledge it before resitting.

Needing a second attempt is not unusual and is not held against you. What is assessed is whether you can do it, not how quickly you got there.',
 1, 14)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000029-2000-4000-8000-000000000001','0f000029-0000-4000-8000-000000000001','Day 29 preparation check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000029-3000-4000-8000-000000000001','0f000029-2000-4000-8000-000000000001',
 'Your assessor raises an objection and then pushes back on your response. What is the correct behaviour?','scenario',
 'Ask what is behind the concern, respond honestly, and accept a reasonable no. Pushing through fails two criteria.',1),
('0f000029-3000-4000-8000-000000000002','0f000029-2000-4000-8000-000000000001',
 'Should you name and recommend a specific product in the final practical?','mcq',
 'No. You are explaining a category connected to a concern you identified. Recommending a specific product from a simulated fact-find is outside what is being assessed.',2),
('0f000029-3000-4000-8000-000000000003','0f000029-2000-4000-8000-000000000001',
 'You are running short of time and have not summarised. What should you do?','scenario',
 'Summarise anyway. It is the most valuable part of the meeting, and skipping it costs both the structure and listening criteria.',3),
('0f000029-3000-4000-8000-000000000004','0f000029-2000-4000-8000-000000000001',
 'Why does written feedback matter more here than elsewhere?','mcq',
 'There is no recording. What the assessor writes at the time is the entire record of how the conversation went.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000029-3000-4000-8000-000000000001','Ask what is behind the concern, respond honestly, and accept a reasonable no',true,1),
('0f000029-3000-4000-8000-000000000001','Restate the benefits until the concern is resolved',false,2),
('0f000029-3000-4000-8000-000000000001','Offer a discount or a smaller premium',false,3),
('0f000029-3000-4000-8000-000000000001','Move on quickly to the next element',false,4),
('0f000029-3000-4000-8000-000000000002','No — explain a category connected to the concern you identified',true,1),
('0f000029-3000-4000-8000-000000000002','Yes, that demonstrates product knowledge',false,2),
('0f000029-3000-4000-8000-000000000002','Only if the assessor asks for one',false,3),
('0f000029-3000-4000-8000-000000000002','Yes, but only for protection products',false,4),
('0f000029-3000-4000-8000-000000000003','Summarise anyway — it is the most valuable part of the meeting',true,1),
('0f000029-3000-4000-8000-000000000003','Skip it and go straight to the next step',false,2),
('0f000029-3000-4000-8000-000000000003','Ask the assessor for more time',false,3),
('0f000029-3000-4000-8000-000000000003','Send the summary in writing afterwards instead',false,4),
('0f000029-3000-4000-8000-000000000004','There is no recording — what is written at the time is the entire record',true,1),
('0f000029-3000-4000-8000-000000000004','It is required by the regulator',false,2),
('0f000029-3000-4000-8000-000000000004','It determines the advisor''s commission band',false,3),
('0f000029-3000-4000-8000-000000000004','It replaces the rubric score',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 30 — Coaching and Readiness Review
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000030-0000-4000-8000-000000000001', pg_temp.day_id(30),
  'Readiness Review', 'assessment',
  'What your manager reviews, what the four outcomes mean, and what happens next.',
  '["Understand what is reviewed at Day 30","Understand what each of the four outcomes means","Understand that completing ATLAS means ready for SUPERVISED fieldwork"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000030-1000-4000-8000-000000000001','0f000030-0000-4000-8000-000000000001',
 'What happens on Day 30',
 'Your manager reviews everything and records one of four outcomes. This lesson exists so that nothing about it is a surprise.

WHAT IS REVIEWED

- Attendance
- Module completion
- Quiz scores, including how many attempts each took
- Practical assessment scores and the written feedback
- Role-play performance
- Concept presentation results
- Joint fieldwork, and your reflection on it
- Coaching actions, and whether they were completed
- Your strengths
- Your development areas

The system shows your manager a checklist of the completion requirements, marked met or unmet. They can see exactly what is outstanding, and so can you before the meeting.

ON ATTENDANCE

Attendance is reported but does not on its own block completion. That is a deliberate decision by the business.

It is not ignored, though. It appears in the review, and a pattern of absence will be part of the conversation — just not as an automatic barrier.

THE FOUR OUTCOMES

**Ready for Supervised Fieldwork.** You may take part in client-facing activity with a senior advisor present. Not independently.

**Ready with Development Actions.** The same, with specific areas recorded that you are expected to work on.

**Additional Training Required.** Not yet. Specific gaps will be identified and you will work through them before being reviewed again.

**Programme Extended.** The programme continues. No readiness decision is made yet. This is common where circumstances interrupted the thirty days rather than where performance was poor.

WHAT NONE OF THEM MEANS

None of these outcomes says you are a fully qualified independent advisor, and none of them is intended to.

Thirty days makes a competent beginner. You understand the foundations, you can conduct a basic fact-find, you can explain product categories and their limitations, and — importantly — you know where your competence ends.

That last one matters more than the rest. An advisor who knows when to escalate is safe. An advisor who does not is a risk to clients regardless of how much they have memorised.

IF THE OUTCOME IS NOT WHAT YOU HOPED

Additional Training Required is not a judgement about your potential. It means specific gaps exist and rushing past them would put clients at risk.

Ask for the specifics. Your manager records development areas, and they are the most useful thing you will receive from the whole programme.

WHAT COMES AFTER

Supervised fieldwork. Continued coaching. Gradually increasing responsibility as your manager judges you ready — observe, assist, present a section, lead with supervision, and eventually lead alone.

That progression has no fixed timetable. It depends on you, on the clients in front of you, and on your manager''s judgement. Thirty days was the beginning of it.',
 1, 14)
on conflict (id) do nothing;

insert into public.revision_cards (module_id, front, back, sequence) values
('0f000030-0000-4000-8000-000000000001','What are the four readiness outcomes?','Ready for Supervised Fieldwork · Ready with Development Actions · Additional Training Required · Programme Extended.',1),
('0f000030-0000-4000-8000-000000000001','Does completing ATLAS mean you can advise independently?','No. It means ready for SUPERVISED fieldwork. Independence comes later, at your manager''s judgement.',2),
('0f000030-0000-4000-8000-000000000001','Does attendance block completion?','No. It is reported and forms part of the conversation, but it is not an automatic barrier.',3)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000030-2000-4000-8000-000000000001','0f000030-0000-4000-8000-000000000001','Day 30 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000030-3000-4000-8000-000000000001','0f000030-2000-4000-8000-000000000001',
 'What does "Ready for Supervised Fieldwork" mean?','mcq',
 'Client-facing activity with a senior advisor present. It is explicitly not independence.',1),
('0f000030-3000-4000-8000-000000000002','0f000030-2000-4000-8000-000000000001',
 'Does low attendance on its own prevent programme completion?','mcq',
 'No. It is reported and forms part of the conversation, but it is not an automatic barrier — a deliberate decision by the business.',2),
('0f000030-3000-4000-8000-000000000003','0f000030-2000-4000-8000-000000000001',
 'Your outcome is "Additional Training Required". What is the most useful thing to do?','scenario',
 'Ask for the specifics. The recorded development areas are the most useful thing you take from the programme.',3),
('0f000030-3000-4000-8000-000000000004','0f000030-2000-4000-8000-000000000001',
 'Which capability matters most for client safety?','mcq',
 'Knowing when to escalate. An advisor who knows where their competence ends is safe; one who does not is a risk however much they have memorised.',4),
('0f000030-3000-4000-8000-000000000005','0f000030-2000-4000-8000-000000000001',
 'When is "Programme Extended" typically used?','mcq',
 'Where circumstances interrupted the thirty days, rather than where performance was poor.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000030-3000-4000-8000-000000000001','Client-facing activity with a senior advisor present',true,1),
('0f000030-3000-4000-8000-000000000001','Full authority to advise clients independently',false,2),
('0f000030-3000-4000-8000-000000000001','Certification as a qualified financial advisor',false,3),
('0f000030-3000-4000-8000-000000000001','Permission to advise on any product category',false,4),
('0f000030-3000-4000-8000-000000000002','No — it is reported but is not an automatic barrier',true,1),
('0f000030-3000-4000-8000-000000000002','Yes, below 90% the programme cannot be completed',false,2),
('0f000030-3000-4000-8000-000000000002','Yes, unless an administrator overrides it',false,3),
('0f000030-3000-4000-8000-000000000002','Attendance is not recorded at all',false,4),
('0f000030-3000-4000-8000-000000000003','Ask for the specific development areas your manager recorded',true,1),
('0f000030-3000-4000-8000-000000000003','Request an immediate re-review',false,2),
('0f000030-3000-4000-8000-000000000003','Retake the final assessments straight away',false,3),
('0f000030-3000-4000-8000-000000000003','Treat it as a judgement about your potential',false,4),
('0f000030-3000-4000-8000-000000000004','Knowing when to escalate a question beyond your competence',true,1),
('0f000030-3000-4000-8000-000000000004','Memorising the full range of product features',false,2),
('0f000030-3000-4000-8000-000000000004','Handling objections confidently',false,3),
('0f000030-3000-4000-8000-000000000004','Securing appointments consistently',false,4),
('0f000030-3000-4000-8000-000000000005','Where circumstances interrupted the thirty days',true,1),
('0f000030-3000-4000-8000-000000000005','Where the advisor failed both final assessments',false,2),
('0f000030-3000-4000-8000-000000000005','Where attendance fell below target',false,3),
('0f000030-3000-4000-8000-000000000005','Where the advisor requested more time',false,4)
on conflict do nothing;

commit;
