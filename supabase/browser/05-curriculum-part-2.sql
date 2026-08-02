-- =========================================================================
-- ATLAS Academy — Curriculum, part 2 of 3
--
-- BUNDLE 5 OF 6. Paste this whole file into the Supabase SQL Editor
-- and press Run. Run the bundles in numeric order; each one depends on the
-- ones before it.
--
-- This file is generated. Do not edit it by hand — edit the source files
-- listed below and regenerate with scripts/build-browser-sql.sh
--
-- Source files, concatenated in this order:
--   supabase/seed/06-curriculum-savings.sql
--   supabase/seed/07-curriculum-conversation.sql
-- =========================================================================



-- ----------------------------------------------------------------------
-- supabase/seed/06-curriculum-savings.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — seed: Days 12, 13, 14 and 16 (Singapore Financial Foundations)
--
-- Endowment plans, Investment-Linked Policies, a savings and investment case
-- study, and HDB and housing commitments.
--
-- INDEXED UNIVERSAL LIFE IS DELIBERATELY ABSENT. It was judged too advanced for
-- a 30-day programme and may be introduced later as an advanced module.
--
-- HDB is not an insurance product and is never described as one. It sits here
-- because housing is the single largest financial commitment most Singaporean
-- clients have, and an advisor who does not understand it will misread almost
-- every fact-find.
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
-- DAY 12 — Endowment Plans
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000012-0000-4000-8000-000000000001', pg_temp.day_id(12),
  'Endowment Plans', 'savings',
  'Structured saving over a fixed period, usually with some insurance element. Simple in outline, and routinely mis-sold on the illustration.',
  '["Explain how an endowment plan works and what the client commits to","Distinguish guaranteed from non-guaranteed values","Identify when an endowment is the wrong instrument"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000012-1000-4000-8000-000000000001','0f000012-0000-4000-8000-000000000001',
 'Saving with a deadline attached',
 'An endowment plan is a savings contract with a fixed term. The client pays regularly, and at maturity receives a lump sum. Most include some life cover, though usually modest.

WHAT NEED IT ADDRESSES

A goal with a date on it. University fees in fourteen years. A deposit in eight. A wedding, a sabbatical, a specific sum needed at a specific time.

The value is partly the return and partly the discipline: money in an endowment is harder to spend on something else, and for many clients that is the point.

WHO MAY BENEFIT

Someone with a defined goal and a defined horizon who will not need the money before then.

Someone who has tried to save in a deposit account and has repeatedly spent it. That is a real client profile, and there is no shame in recognising it.

WHO MAY NOT

Someone who may need the money early. This is the crucial one.

An endowment surrendered early typically returns considerably less than has been paid in — sometimes dramatically less in the first years. A client who might need access should not be in one.

Someone whose protection gaps are unaddressed. Saving while uninsured is building on sand.

Someone seeking maximum growth and comfortable with volatility. An endowment is not designed to be the highest-returning instrument available; it is designed to be a disciplined one.

GUARANTEED AND NON-GUARANTEED — THE PART THAT MATTERS

Illustrations typically show two figures: a guaranteed maturity value, and a higher projected value including non-guaranteed bonuses.

The second number is a projection. It is not a promise, it depends on performance, and it may not be achieved.

An advisor who shows a client the higher number and lets them remember it as "what I will get" has mis-sold the plan, whatever the paperwork says. The client will feel deceived at maturity and they will be entitled to.

Say it this way: "This part is guaranteed. This part is not — it depends on how the fund performs, and it could be less. When we talk about whether this meets your goal, I would rather we work from the guaranteed figure and treat the rest as a bonus."

THE COMMITMENT QUESTION TO ASK BEFORE RECOMMENDING

"This is a fourteen-year commitment. If your income dropped for six months in year three, could you keep paying it? What would you do?"

If the honest answer is "I would have to stop", the term or the premium is wrong, and it is far better to find that out now.',
 1, 16)
on conflict (id) do nothing;

insert into public.terminology (module_id, term, definition, sequence) values
('0f000012-0000-4000-8000-000000000001','Guaranteed maturity value','The amount contractually payable at maturity, independent of investment performance.',1),
('0f000012-0000-4000-8000-000000000001','Non-guaranteed bonus','Additional amounts that depend on performance. A projection, never a promise.',2),
('0f000012-0000-4000-8000-000000000001','Surrender value','What the client receives if they end the plan early. Typically far less than premiums paid, especially in early years.',3)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000012-2000-4000-8000-000000000001','0f000012-0000-4000-8000-000000000001','Day 12 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000012-3000-4000-8000-000000000001','0f000012-2000-4000-8000-000000000001',
 'An illustration shows a guaranteed value of $40,000 and a projected value of $58,000. Which should you plan the client''s goal around?','scenario',
 'The guaranteed figure. The projection depends on performance and may not be achieved; planning a goal around it sets the client up for a shortfall.',1),
('0f000012-3000-4000-8000-000000000002','0f000012-2000-4000-8000-000000000001',
 'A client may need access to their money within three years. Is an endowment appropriate?','scenario',
 'No. Early surrender typically returns far less than premiums paid. A client who may need access should not be in one.',2),
('0f000012-3000-4000-8000-000000000003','0f000012-2000-4000-8000-000000000001',
 'What question should you ask before recommending a long-term endowment?','mcq',
 'Whether they could sustain the premium through a period of reduced income. If not, the term or premium is wrong and it is better to know now.',3),
('0f000012-3000-4000-8000-000000000004','0f000012-2000-4000-8000-000000000001',
 'A client with no hospitalisation or life cover wants to start an endowment for their child''s education. What should you raise first?','scenario',
 'The protection gap. Saving for a child''s education while the earner is uninsured means the plan collapses precisely when the child needs it most.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000012-3000-4000-8000-000000000001','The guaranteed value, treating the rest as a bonus',true,1),
('0f000012-3000-4000-8000-000000000001','The projected value, since illustrations are conservative',false,2),
('0f000012-3000-4000-8000-000000000001','The midpoint of the two',false,3),
('0f000012-3000-4000-8000-000000000001','Whichever figure the client prefers',false,4),
('0f000012-3000-4000-8000-000000000002','No — early surrender typically returns far less than the premiums paid',true,1),
('0f000012-3000-4000-8000-000000000002','Yes, provided the term is at least ten years',false,2),
('0f000012-3000-4000-8000-000000000002','Yes, since they can borrow against it',false,3),
('0f000012-3000-4000-8000-000000000002','Yes, endowments can be surrendered without penalty',false,4),
('0f000012-3000-4000-8000-000000000003','Whether they could sustain the premium if their income dropped for several months',true,1),
('0f000012-3000-4000-8000-000000000003','Whether they prefer a shorter or longer term',false,2),
('0f000012-3000-4000-8000-000000000003','Whether they have used an endowment before',false,3),
('0f000012-3000-4000-8000-000000000003','Which insurer they would prefer',false,4),
('0f000012-3000-4000-8000-000000000004','The protection gap — an uninsured earner means the plan fails when it is most needed',true,1),
('0f000012-3000-4000-8000-000000000004','Nothing — proceed, since education saving is time-sensitive',false,2),
('0f000012-3000-4000-8000-000000000004','Recommend a larger endowment to compensate',false,3),
('0f000012-3000-4000-8000-000000000004','Suggest they invest directly instead',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 13 — Investment-Linked Policies
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000013-0000-4000-8000-000000000001', pg_temp.day_id(13),
  'Investment-Linked Policies', 'savings',
  'Insurance and investment in one contract. Introductory treatment only — structure, risk, charges, suitability and limits.',
  '["Explain the two components of an ILP and how they interact","Explain that returns are not guaranteed and the value can fall","Describe charges and time horizon honestly","Identify when an ILP is not appropriate"]'::jsonb,
  50, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000013-1000-4000-8000-000000000001','0f000013-0000-4000-8000-000000000001',
 'Two things in one contract',
 'An investment-linked policy combines insurance cover with investment in funds. The client pays a premium; part provides cover and charges, and part buys units in funds they select.

You are not expected to master every fund or every insurer''s variation in your first thirty days. What you must understand is the structure, the risks, the charges and the circumstances in which an ILP is the wrong answer.

THE TWO COMPONENTS

**The insurance component.** Cover, paid for by deducting charges — often from the units held.

**The investment component.** Units in funds. Their value rises and falls with the funds.

They interact, and this is what clients find surprising: if fund performance is poor, the units being deducted to pay for cover are worth less, so more units go. In adverse conditions a policy can require additional premium or reduce cover to stay in force.

INVESTMENT RISK — SAY IT PLAINLY

The value can fall. The client can get back less than they paid in. There is no guaranteed maturity value in the way an endowment has one.

That sentence must be said out loud, not left to the documentation.

FEES AND CHARGES

Fund management charges. Policy and administration charges. Insurance charges, which typically rise with age. In early years, charges consume a significant share of the premium.

A client who expects their fund value after two years to resemble what they have paid in will be surprised. Tell them beforehand.

TIME HORIZON

ILPs are long-term. Early surrender commonly produces a poor outcome, because charges are front-loaded and there has been little time for growth.

A client who might need the money in a few years should not be in one.

NON-GUARANTEED OUTCOMES

Every projection is an illustration at an assumed rate. It is not a forecast and certainly not a promise. Presenting a projected value as what the client will receive is the most serious compliance failure available in this category.

WHEN AN ILP MAY NOT BE APPROPRIATE

- The client wants certainty about what they will get back
- The client may need access within a few years
- The client does not understand — or is not comfortable with — the value falling
- The client''s protection needs would be better and more cheaply met by term cover, with any investing done separately
- The client''s income is unstable enough that sustaining premiums is doubtful

WHY FURTHER FACT-FINDING IS ALWAYS NEEDED

An ILP recommendation depends on risk tolerance, time horizon, existing cover, existing investments, capacity for loss and stability of income. A recommendation made without all of those is not advice.

WHAT TO SAY

"This does two things at once — it provides cover and it invests. That means the value can go down as well as up, and you could get back less than you put in. It also means charges come out along the way, so in the early years the fund value will look lower than what you have paid. Before I could say whether it suits you, I need to understand how you would feel if the value fell, and when you might need this money."

WHEN TO ESCALATE

Fund selection. Switching. Any question about a specific insurer''s charging structure. Anything involving an existing ILP the client already holds.

That is not a gap in your training — it is the boundary of a thirty-day programme, and recognising it is one of the things you are being assessed on.',
 1, 18)
on conflict (id) do nothing;

insert into public.terminology (module_id, term, definition, sequence) values
('0f000013-0000-4000-8000-000000000001','Units','Shares of a fund bought with the investment portion of the premium. Their value rises and falls.',1),
('0f000013-0000-4000-8000-000000000001','Insurance charge','The cost of the cover, typically deducted from units and usually rising with age.',2),
('0f000013-0000-4000-8000-000000000001','Front-loaded charges','Charges weighted towards early years, which is why early surrender values are poor.',3)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000013-2000-4000-8000-000000000001','0f000013-0000-4000-8000-000000000001','Day 13 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000013-3000-4000-8000-000000000001','0f000013-2000-4000-8000-000000000001',
 'A client asks what they are guaranteed to receive from an ILP at maturity. What is the honest answer?','scenario',
 'There is no guaranteed maturity value in the way an endowment has one. The value depends on fund performance and can fall below what was paid in.',1),
('0f000013-3000-4000-8000-000000000002','0f000013-2000-4000-8000-000000000001',
 'Why does poor fund performance create a compounding problem in an ILP?','mcq',
 'Insurance charges are deducted from units. If units are worth less, more must be deducted, which can require additional premium or a reduction in cover.',2),
('0f000013-3000-4000-8000-000000000003','0f000013-2000-4000-8000-000000000001',
 'A client wants cover and is uncomfortable with any possibility of loss. What should you consider?','scenario',
 'Term cover with any investing done separately. An ILP is not appropriate for a client who needs certainty about what they get back.',3),
('0f000013-3000-4000-8000-000000000004','0f000013-2000-4000-8000-000000000001',
 'A client asks which specific funds they should choose. You are 13 days into the programme. What do you do?','scenario',
 'Escalate. Fund selection is outside a new advisor''s competence, and recognising that boundary is part of what this programme assesses.',4),
('0f000013-3000-4000-8000-000000000005','0f000013-2000-4000-8000-000000000001',
 'Why will an ILP fund value often look lower than premiums paid after two years?','mcq',
 'Charges are front-loaded, and there has been little time for growth. A client not told this beforehand will assume something has gone wrong.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000013-3000-4000-8000-000000000001','Nothing is guaranteed — the value depends on fund performance and can fall below what was paid in',true,1),
('0f000013-3000-4000-8000-000000000001','The total premiums paid, as a minimum',false,2),
('0f000013-3000-4000-8000-000000000001','The projected value shown in the illustration',false,3),
('0f000013-3000-4000-8000-000000000001','The sum assured, at maturity',false,4),
('0f000013-3000-4000-8000-000000000002','Charges are deducted from units, so poor performance means more units are consumed',true,1),
('0f000013-3000-4000-8000-000000000002','The insurer increases the premium automatically each year',false,2),
('0f000013-3000-4000-8000-000000000002','Cover is suspended until performance recovers',false,3),
('0f000013-3000-4000-8000-000000000002','Fund switching becomes mandatory',false,4),
('0f000013-3000-4000-8000-000000000003','Term cover, with any investing arranged separately',true,1),
('0f000013-3000-4000-8000-000000000003','An ILP with a lower-risk fund, which removes the possibility of loss',false,2),
('0f000013-3000-4000-8000-000000000003','An ILP with a longer term, which guarantees recovery',false,3),
('0f000013-3000-4000-8000-000000000003','Recommend the ILP anyway and explain the risk again',false,4),
('0f000013-3000-4000-8000-000000000004','Escalate to a senior advisor — fund selection is outside your competence',true,1),
('0f000013-3000-4000-8000-000000000004','Recommend a balanced fund as a safe default',false,2),
('0f000013-3000-4000-8000-000000000004','Suggest whichever fund performed best last year',false,3),
('0f000013-3000-4000-8000-000000000004','Let the client choose without guidance',false,4),
('0f000013-3000-4000-8000-000000000005','Charges are front-loaded and there has been little time for growth',true,1),
('0f000013-3000-4000-8000-000000000005','Insurers withhold returns for the first three years',false,2),
('0f000013-3000-4000-8000-000000000005','Units are only allocated from year three onwards',false,3),
('0f000013-3000-4000-8000-000000000005','It indicates the policy has been set up incorrectly',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 14 — Savings and Investment Case Study
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000014-0000-4000-8000-000000000001', pg_temp.day_id(14),
  'Savings and Investment Case Study', 'savings',
  'A fictional client with competing goals. Practice in identifying what is missing before deciding anything.',
  '["Identify missing information in an incomplete picture","Order competing goals defensibly","Explain why a product decision is premature"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000014-1000-4000-8000-000000000001','0f000014-0000-4000-8000-000000000001',
 'The case of Wei Ming and Sarah',
 'Read this once, then answer the questions before reading the discussion.

THE SITUATION

Wei Ming is 34 and Sarah is 32. They have a daughter aged 2 and Sarah is expecting their second child in four months.

Wei Ming earns $6,500 a month as an engineer. Sarah earns $4,200 in marketing but intends to reduce to part-time after the birth, roughly halving her income for at least two years.

They bought a four-room flat eighteen months ago. The mortgage has 23 years remaining and takes $1,900 a month, largely from CPF.

They have $18,000 in a savings account.

Wei Ming has hospitalisation cover through his employer and a small term policy his father bought him at 21. He does not know the sum assured. Sarah has hospitalisation cover only.

Wei Ming''s mother is 68, widowed, and lives alone. He sends her $500 most months. She has some CPF savings and no other income he is aware of.

They tell you they want to "start investing for the children''s education".

WHAT THEY ASKED FOR IS NOT WHERE YOU SHOULD START

They asked about education savings. That is a real goal and you should not dismiss it.

But look at what happens if Wei Ming cannot work.

Sarah''s income is about to halve. The mortgage continues. There are about to be two children rather than one. His mother''s $500 stops. Their $18,000 covers roughly three months of the household as it currently stands, and less once Sarah reduces her hours.

They have a term policy of unknown value and employer cover that ends with the job.

The education goal is fourteen years away. The protection gap is live right now.

WHAT IS MISSING FROM THE PICTURE

You cannot responsibly recommend anything until you know:

- The sum assured on Wei Ming''s existing term policy, and its term
- Whether either employer scheme includes any life or critical illness cover
- Their actual monthly expenditure, not their income
- The outstanding mortgage balance, not just the payment
- Whether Wei Ming''s mother has other support, and whether $500 is discretionary or essential
- Whether they have CPF balances beyond the mortgage
- What "reduce to part-time" means in figures, and for how long

Seven items. This is normal. A first meeting that ends with seven open questions has gone well, not badly.

A DEFENSIBLE ORDER

1. Establish what protection already exists — you cannot size a gap without this
2. Address the income-protection gap, which is largest just as capacity is about to shrink
3. Build the emergency fund towards a realistic number for a family of four
4. Then education savings, which has fourteen years and can start smaller

WHAT TO SAY TO THEM

"I want to come back to the education savings, because it matters and we should plan it. Before that, can I ask about something? If you were unable to work for a year, what would happen to the mortgage? I ask because Sarah''s hours are about to change and there is about to be another child, and that is the point at which I would want to be sure you were covered. Would you mind if we looked at that first?"

That is not a diversion from what they asked. It is the reason they hired you.',
 1, 18)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000014-2000-4000-8000-000000000001','0f000014-0000-4000-8000-000000000001','Day 14 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000014-3000-4000-8000-000000000001','0f000014-2000-4000-8000-000000000001',
 'The couple asked about education savings. What should you address first?','scenario',
 'The protection gap. Sarah''s income is about to halve, a second child is arriving and the mortgage continues. The education goal is fourteen years away; the protection gap is live now.',1),
('0f000014-3000-4000-8000-000000000002','0f000014-2000-4000-8000-000000000001',
 'Which piece of missing information most limits what you can recommend?','mcq',
 'The sum assured on the existing term policy. You cannot size a gap without knowing what is already filled.',2),
('0f000014-3000-4000-8000-000000000003','0f000014-2000-4000-8000-000000000001',
 'Wei Ming sends his mother $500 a month. How should this feature in your analysis?','scenario',
 'As a dependant obligation to be established properly. Ageing parents are the most commonly missed dependant in Singapore and often the largest single exposure.',3),
('0f000014-3000-4000-8000-000000000004','0f000014-2000-4000-8000-000000000001',
 'You end the first meeting with seven open questions. What does that indicate?','mcq',
 'A normal, well-conducted first meeting. Recommending without the answers would be guessing.',4),
('0f000014-3000-4000-8000-000000000005','0f000014-2000-4000-8000-000000000001',
 'Why is employer-provided cover insufficient as the basis for a plan?','mcq',
 'It ends with the job, and the client does not control it. It is a useful component, not a foundation.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000014-3000-4000-8000-000000000001','The protection gap, which is live now while the education goal is fourteen years away',true,1),
('0f000014-3000-4000-8000-000000000001','Education savings, because that is what they asked for',false,2),
('0f000014-3000-4000-8000-000000000001','Refinancing the mortgage to free up cash',false,3),
('0f000014-3000-4000-8000-000000000001','Investing the $18,000 for growth',false,4),
('0f000014-3000-4000-8000-000000000002','The sum assured on Wei Ming''s existing term policy',true,1),
('0f000014-3000-4000-8000-000000000002','Which school they intend the children to attend',false,2),
('0f000014-3000-4000-8000-000000000002','Their preferred investment risk level',false,3),
('0f000014-3000-4000-8000-000000000002','The name of Wei Ming''s employer',false,4),
('0f000014-3000-4000-8000-000000000003','As a dependant obligation to be established properly',true,1),
('0f000014-3000-4000-8000-000000000003','As discretionary spending that can be cut if needed',false,2),
('0f000014-3000-4000-8000-000000000003','As irrelevant, since she is not a legal dependant',false,3),
('0f000014-3000-4000-8000-000000000003','As a reason to recommend a larger investment plan',false,4),
('0f000014-3000-4000-8000-000000000004','A normal and well-conducted first meeting',true,1),
('0f000014-3000-4000-8000-000000000004','That you failed to prepare adequately',false,2),
('0f000014-3000-4000-8000-000000000004','That the clients were being unhelpful',false,3),
('0f000014-3000-4000-8000-000000000004','That you should recommend something provisional',false,4),
('0f000014-3000-4000-8000-000000000005','It ends with the job and the client does not control it',true,1),
('0f000014-3000-4000-8000-000000000005','It is always smaller than personal cover',false,2),
('0f000014-3000-4000-8000-000000000005','It excludes pre-existing conditions more strictly',false,3),
('0f000014-3000-4000-8000-000000000005','It cannot be claimed alongside personal cover',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 16 — HDB, Housing Commitments and Financial Planning
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000016-0000-4000-8000-000000000001', pg_temp.day_id(16),
  'HDB and Housing Commitments', 'singapore_foundations',
  'Housing is the largest financial commitment most clients have. Not an insurance product — the context every other conversation sits inside.',
  '["Explain how housing interacts with CPF and cash flow","Recognise the planning implications of a mortgage","Escalate housing-specific questions appropriately"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000016-1000-4000-8000-000000000001','0f000016-0000-4000-8000-000000000001',
 'The commitment that shapes everything else',
 'HDB housing is not a financial product you advise on and it is certainly not insurance. It appears in this programme because it is the largest commitment most of your clients have, and an advisor who does not understand its shape will misread almost every fact-find.

WHY IT MATTERS TO YOU

**It consumes CPF.** Ordinary Account savings used for a flat are not available for retirement. Two clients on identical salaries can be in entirely different positions at 55 because one serviced a mortgage from CPF and the other did not.

**It is a long obligation.** Twenty-five years is longer than most protection policies a new advisor will discuss, and it does not stop if income does.

**It is the largest single reason a family loses their home.** When you ask "what would happen if your income stopped", the mortgage is usually the answer.

WHAT TO ESTABLISH IN A FACT-FIND

Not the property''s value — the **outstanding balance** and the **remaining term**. The balance is the obligation; the value is not available unless they sell.

How the mortgage is serviced: CPF, cash, or a mix. This changes both the retirement picture and what happens if income stops, because CPF contributions stop when employment does.

Whether there is existing mortgage-related cover, and what it actually covers.

THE PLANNING IMPLICATIONS

A client with 23 years remaining has a 23-year obligation. That is a defensible basis for a term length, and it comes from their situation rather than from a round number.

A client servicing a mortgage largely from CPF should understand what that means for their Retirement Account at 55. Not as a criticism — most people do exactly this — but as something they should see rather than discover.

WHAT NOT TO DO

Do not advise on property purchase, timing or financing. That is not your role and it is not what you are licensed for.

Do not present figures for HDB schemes, grants or loan eligibility. Rules change, they are detailed, and they are published — a client who acts on a remembered figure and finds it wrong has been failed.

Do not describe CPF or HDB arrangements as insurance. They are not.

WHERE THE LINE IS

Understanding housing well enough to plan around it: your job.
Advising on the housing decision itself: not your job.

If a client asks whether they should upgrade, refinance or use more CPF, the correct answer is that you can help them understand how the options affect their protection and retirement position, and that the housing decision itself needs someone qualified in that area.',
 1, 15)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000016-2000-4000-8000-000000000001','0f000016-0000-4000-8000-000000000001','Day 16 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000016-3000-4000-8000-000000000001','0f000016-2000-4000-8000-000000000001',
 'In a fact-find, which housing figure matters most for protection planning?','mcq',
 'The outstanding balance and remaining term. That is the obligation; the property''s value is not available unless they sell.',1),
('0f000016-3000-4000-8000-000000000002','0f000016-2000-4000-8000-000000000001',
 'Why does servicing a mortgage from CPF matter to a retirement conversation?','scenario',
 'Ordinary Account savings used for housing are not available for retirement, so two clients on identical salaries can reach 55 in very different positions.',2),
('0f000016-3000-4000-8000-000000000003','0f000016-2000-4000-8000-000000000001',
 'A client asks whether they should upgrade to a larger flat. How should you respond?','scenario',
 'Explain you can help them understand how the options affect their protection and retirement position, but the housing decision itself needs someone qualified in that area.',3),
('0f000016-3000-4000-8000-000000000004','0f000016-2000-4000-8000-000000000001',
 'A client with 23 years left on their mortgage asks what term length they need. What is the defensible basis?','mcq',
 'The remaining mortgage term. Term lengths should follow the client''s actual obligations rather than a round number.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000016-3000-4000-8000-000000000001','The outstanding balance and remaining term',true,1),
('0f000016-3000-4000-8000-000000000001','The current market value of the flat',false,2),
('0f000016-3000-4000-8000-000000000001','The original purchase price',false,3),
('0f000016-3000-4000-8000-000000000001','The estimated value in ten years',false,4),
('0f000016-3000-4000-8000-000000000002','CPF used for housing is not available for retirement',true,1),
('0f000016-3000-4000-8000-000000000002','CPF-serviced mortgages carry higher interest',false,2),
('0f000016-3000-4000-8000-000000000002','It prevents the client from buying insurance',false,3),
('0f000016-3000-4000-8000-000000000002','It has no effect on the retirement position',false,4),
('0f000016-3000-4000-8000-000000000003','Offer to help them understand the planning impact, and refer the housing decision itself',true,1),
('0f000016-3000-4000-8000-000000000003','Advise them based on current property market conditions',false,2),
('0f000016-3000-4000-8000-000000000003','Tell them upgrading is generally a good investment',false,3),
('0f000016-3000-4000-8000-000000000003','Calculate their loan eligibility for them',false,4),
('0f000016-3000-4000-8000-000000000004','The remaining mortgage term, since that is the actual obligation',true,1),
('0f000016-3000-4000-8000-000000000004','25 years, as a standard',false,2),
('0f000016-3000-4000-8000-000000000004','Until age 65, regardless of the mortgage',false,3),
('0f000016-3000-4000-8000-000000000004','10 years, then review',false,4)
on conflict do nothing;

commit;


-- ----------------------------------------------------------------------
-- supabase/seed/07-curriculum-conversation.sql
-- ----------------------------------------------------------------------

-- ATLAS Academy — seed: Days 17 to 22 (Client Conversation Skills)
--
-- Prospecting, the advisor introduction, first appointments, concept
-- presentation, product explanation, and objection handling.
--
-- Day 18 is "Advisor Introduction & Value Pitch". It is never called a sales
-- pitch, and the lesson explains why the distinction is not cosmetic.
--
-- Objection handling is taught as understanding the concern before responding.
-- Nothing here treats an objection as something to defeat.
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
-- DAY 17 — Prospecting and Appointment Setting
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000017-0000-4000-8000-000000000001', pg_temp.day_id(17),
  'Prospecting and Appointment Setting', 'conversation',
  'Where clients come from, and how to secure twenty minutes without overpromising.',
  '["Describe the main prospecting routes and what each demands","Set an appointment without misrepresenting its purpose","Follow up professionally and know when to stop"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000017-1000-4000-8000-000000000001','0f000017-0000-4000-8000-000000000001',
 'Where clients come from',
 'Every advisor needs people to talk to. There are four common routes and they are not equally comfortable.

COLD CALLING

Calling people who do not know you. Low conversion, high volume, and genuinely unpleasant for most people at first.

It teaches you something the other routes do not: how to be rejected without taking it personally. Advisors who never do it often struggle later, because every difficult conversation feels like a crisis.

The goal of a cold call is one thing only: a short meeting. Not a sale, not a product discussion, not a "quick question about your insurance". Twenty minutes.

WARM MARKET

People you already know. Higher conversion, and the route most new advisors are pushed towards.

Two cautions, and they are not small.

First, your warm market is finite. An advisor who builds a first year on friends and family and never develops another source has a very difficult second year.

Second, the relationship costs more than the sale is worth if it goes wrong. Sell a friend something unsuitable and you lose both.

Treat them exactly as you would a stranger: full fact-find, honest recommendation, and a genuine willingness to say there is nothing they need.

REFERRALS

Someone you have helped introduces someone else. The best route by a distance, and the one requiring most patience.

You earn referrals by doing good work and then asking, at a moment when the client feels well served. Not at the point of sale — after delivery, after a claim handled well, after a review that was useful.

SOCIAL MEDIA AND ONLINE ENQUIRIES

Someone responds to a post or an advertisement. Interest decays fast; reply the same day.

Do not attempt to answer a substantive financial question in writing. A general answer may not apply to them, and a specific one before a fact-find is not something you should be giving.

WHAT ALL FOUR HAVE IN COMMON

The objective is always a meeting, never a sale. An advisor who tries to sell on the phone gets neither.

And a person who declines is not a failure. They are a person who declined. Record it, honour it, move on.',
 1, 15),
('0f000017-1000-4000-8000-000000000002','0f000017-0000-4000-8000-000000000001',
 'Reducing the barriers to saying yes',
 'People do not refuse meetings because they are hostile. They refuse because a meeting sounds costly — in time, in obligation, or in the risk of being sold something.

Lower each of those and more people say yes.

TIME

"Twenty minutes" is easier to agree to than "a meeting". Say a number and then honour it. An advisor who says twenty minutes and takes ninety will not get a second appointment.

OBLIGATION

Say plainly that they are not committing to anything. "I am not going to recommend anything at this meeting — I would rather understand your situation first." This is both true and reassuring, and it removes the most common reason for hesitation.

THE FEAR OF BEING SOLD TO

Address it directly. "If there is nothing useful I can do, I will tell you." Say it, and then actually do it when the situation arises. Word gets around either way.

PLACE

Offer to come to them, or to meet somewhere convenient. A small courtesy that removes a real obstacle.

CHOICE

Offer two specific times rather than asking when they are free. An open question requires them to do work; two options require a decision.

CONFIRMING

Confirm in writing the day before: time, place, duration, what you will cover, and that nothing needs preparing. This single habit prevents most no-shows.

FOLLOWING UP

If someone does not reply, follow up once, and again after a week. Then stop.

Persistence past that point does not produce clients. It produces people who avoid you, and who tell other people to avoid you.

"I do not want to keep appearing in your inbox. I will leave it with you — if it becomes useful, you know where I am." Then actually leave it.

WHAT NOT TO DO

Do not misrepresent the purpose of the meeting. Do not manufacture urgency. Do not say "I am in your area anyway" if you are not. Do not imply an existing relationship you do not have.

These get meetings. They do not get clients, and they can get you a complaint.',
 2, 13)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000017-2000-4000-8000-000000000001','0f000017-0000-4000-8000-000000000001','Day 17 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000017-3000-4000-8000-000000000001','0f000017-2000-4000-8000-000000000001',
 'What is the objective of a cold call?','mcq',
 'A short meeting. An advisor who tries to sell on the phone gets neither the sale nor the meeting.',1),
('0f000017-3000-4000-8000-000000000002','0f000017-2000-4000-8000-000000000001',
 'Why should a new advisor be cautious about relying on their warm market?','scenario',
 'It is finite, and a poor recommendation costs the relationship as well as the client. An advisor whose first year is built on friends has a difficult second year.',2),
('0f000017-3000-4000-8000-000000000003','0f000017-2000-4000-8000-000000000001',
 'When is the best moment to ask for a referral?','mcq',
 'After you have delivered something useful — a review, a claim handled well — rather than at the point of sale.',3),
('0f000017-3000-4000-8000-000000000004','0f000017-2000-4000-8000-000000000001',
 'A prospect has not replied to two follow-ups. What should you do?','scenario',
 'Stop, having told them where to find you. Persistence past this point produces avoidance, not clients.',4),
('0f000017-3000-4000-8000-000000000005','0f000017-2000-4000-8000-000000000001',
 'Which of these most reduces the barrier to agreeing a meeting?','mcq',
 'Saying plainly that you will not recommend anything at this meeting. It removes the most common reason for hesitation, and it is true.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000017-3000-4000-8000-000000000001','To secure a short meeting',true,1),
('0f000017-3000-4000-8000-000000000001','To identify which product they need',false,2),
('0f000017-3000-4000-8000-000000000001','To complete a brief fact-find over the phone',false,3),
('0f000017-3000-4000-8000-000000000001','To establish their budget',false,4),
('0f000017-3000-4000-8000-000000000002','It is finite, and a poor recommendation costs the relationship too',true,1),
('0f000017-3000-4000-8000-000000000002','Friends and family rarely qualify for cover',false,2),
('0f000017-3000-4000-8000-000000000002','Regulations restrict advising people you know',false,3),
('0f000017-3000-4000-8000-000000000002','Conversion rates are lower than cold calling',false,4),
('0f000017-3000-4000-8000-000000000003','After delivering something useful, such as a review or a claim handled well',true,1),
('0f000017-3000-4000-8000-000000000003','At the point of sale, while enthusiasm is high',false,2),
('0f000017-3000-4000-8000-000000000003','During the first appointment',false,3),
('0f000017-3000-4000-8000-000000000003','Only when the client offers unprompted',false,4),
('0f000017-3000-4000-8000-000000000004','Stop, having told them where to find you',true,1),
('0f000017-3000-4000-8000-000000000004','Continue weekly until they respond either way',false,2),
('0f000017-3000-4000-8000-000000000004','Call from a different number',false,3),
('0f000017-3000-4000-8000-000000000004','Send a final message noting an offer is expiring',false,4),
('0f000017-3000-4000-8000-000000000005','Saying plainly that you will not recommend anything at this meeting',true,1),
('0f000017-3000-4000-8000-000000000005','Mentioning a limited-time promotion',false,2),
('0f000017-3000-4000-8000-000000000005','Explaining how many clients you already have',false,3),
('0f000017-3000-4000-8000-000000000005','Asking them to prepare their financial documents',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 18 — Advisor Introduction & Value Pitch
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000018-0000-4000-8000-000000000001', pg_temp.day_id(18),
  'Advisor Introduction & Value Pitch', 'conversation',
  'How to introduce yourself and explain what you do, briefly, without it becoming a sales pitch.',
  '["Introduce yourself in under two minutes","Explain the advisory process and set expectations","Communicate value without overclaiming"]'::jsonb,
  40, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000018-1000-4000-8000-000000000001','0f000018-0000-4000-8000-000000000001',
 'Why this is not a sales pitch',
 'This module is called an Advisor Introduction, and the naming is deliberate.

A sales pitch is designed to make someone want a thing. An introduction is designed to make someone understand who you are, what happens next, and what they can expect. The second is what a first meeting needs, and it is what compliant advice looks like from the outside.

If your opening leaves the client thinking "that sounds good, where do I sign", you have pitched. If it leaves them thinking "I understand what this will involve", you have introduced yourself.

WHAT AN INTRODUCTION CONTAINS

**Who you are.** Name, firm, and how long you have been doing this. If the honest answer is "I joined recently", say so. Clients discover it anyway, and having concealed it is worse than being new.

**What you actually do.** Not "I help people achieve their financial goals" — that could describe anyone. Something concrete: "I help people work out what would happen to their household if their income stopped, and what to do about it."

**How the process works.** Understand first, recommend second, decide third. Say it in that order, because the order is the reassurance.

**What you will not do.** You will not recommend anything today. If nothing is suitable, you will say so.

**How long it takes.** A number.

WHAT IT DOES NOT CONTAIN

Your firm''s history. Awards. How many clients you have. Product names. Anything about returns.

None of that answers a question the client is actually asking, and all of it consumes the attention you need for the fact-find.

A WORKED EXAMPLE, ABOUT NINETY SECONDS

"I''m {name}, I''m a financial advisor with {firm}, and I joined earlier this year.

What I do, in practice, is help people understand two things: what would happen financially if something went wrong, and whether what they''re already doing gets them where they want to be.

The way I work is that today I''d mostly like to listen. I''ll ask about your income, your commitments, who depends on you, and what you already have in place. Then I''ll go away and think about it, and come back with what I''d suggest — or with the view that you''re fine as you are, which does happen.

I won''t recommend anything today. I''d rather understand properly first.

Should take about forty minutes. Does that work?"

WHY BEING NEW IS NOT A WEAKNESS

Clients are not primarily buying experience. They are buying attention and honesty, and a new advisor with time to spend often provides more of both than a busy one.

What loses trust is pretending. "I''m new, and I''ve got a senior colleague I can bring in whenever we hit something I''m not sure about" is a strong position — it tells the client they get two people.

COMMUNICATING VALUE HONESTLY

Do not claim outcomes you cannot deliver. You cannot promise returns, you cannot promise a claim will be paid, and you cannot promise they will be better off.

What you can promise: that you will understand their situation before recommending anything, that you will explain the limitations as clearly as the benefits, and that you will tell them when something is not suitable.

Those are real commitments, entirely within your control, and more persuasive than any claim about performance.',
 1, 15)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000018-2000-4000-8000-000000000001','0f000018-0000-4000-8000-000000000001','Day 18 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000018-3000-4000-8000-000000000001','0f000018-2000-4000-8000-000000000001',
 'What distinguishes an advisor introduction from a sales pitch?','mcq',
 'An introduction helps the client understand who you are and what happens next. A pitch is designed to make them want something.',1),
('0f000018-3000-4000-8000-000000000002','0f000018-2000-4000-8000-000000000001',
 'A client asks how long you have been an advisor. You joined two months ago. What do you say?','scenario',
 'Say so, and mention the senior colleague you can involve. Concealing it is worse, because clients find out, and having been misled damages trust more than inexperience does.',2),
('0f000018-3000-4000-8000-000000000003','0f000018-2000-4000-8000-000000000001',
 'Which of these belongs in an introduction?','mcq',
 'That you will not recommend anything today. It sets expectations honestly and removes the client''s main anxiety.',3),
('0f000018-3000-4000-8000-000000000004','0f000018-2000-4000-8000-000000000001',
 'What can an advisor honestly promise a client?','mcq',
 'That you will understand their situation first, explain limitations as clearly as benefits, and say when something is unsuitable. All within your control.',4)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000018-3000-4000-8000-000000000001','An introduction helps them understand what happens next; a pitch makes them want something',true,1),
('0f000018-3000-4000-8000-000000000001','An introduction is longer and more detailed',false,2),
('0f000018-3000-4000-8000-000000000001','A pitch is used with warm market, an introduction with cold',false,3),
('0f000018-3000-4000-8000-000000000001','They are the same thing under different names',false,4),
('0f000018-3000-4000-8000-000000000002','Say so plainly, and mention the senior colleague you can bring in',true,1),
('0f000018-3000-4000-8000-000000000002','Say you have been in financial services for several years',false,2),
('0f000018-3000-4000-8000-000000000002','Avoid the question and return to their situation',false,3),
('0f000018-3000-4000-8000-000000000002','Say your firm has decades of experience',false,4),
('0f000018-3000-4000-8000-000000000003','That you will not recommend anything at this meeting',true,1),
('0f000018-3000-4000-8000-000000000003','A summary of your firm''s awards',false,2),
('0f000018-3000-4000-8000-000000000003','The products you most often recommend',false,3),
('0f000018-3000-4000-8000-000000000003','Typical returns your clients have seen',false,4),
('0f000018-3000-4000-8000-000000000004','That you will understand their situation before recommending anything',true,1),
('0f000018-3000-4000-8000-000000000004','That they will be financially better off',false,2),
('0f000018-3000-4000-8000-000000000004','That any claim will be paid',false,3),
('0f000018-3000-4000-8000-000000000004','That returns will beat inflation',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 19 — First Appointment and Fact-Finding
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000019-0000-4000-8000-000000000001', pg_temp.day_id(19),
  'The First Appointment', 'conversation',
  'Running the meeting: rapport, agenda, permission, discovery, summary, next step.',
  '["Open a meeting so the client knows its shape","Ask permission before personal questions","Summarise accurately and agree a specific next step"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000019-1000-4000-8000-000000000001','0f000019-0000-4000-8000-000000000001',
 'The shape of a first meeting',
 'A first appointment has six parts. Run them in order and the meeting largely runs itself.

1. RAPPORT — TWO MINUTES, NOT TWENTY

Enough to be human. Ask about the journey, the office, the child in the photograph. Then move.

Extended small talk is not rapport; it is avoidance, usually of the moment where you have to start asking real questions.

2. AGENDA

Say what you will cover, roughly how long, and invite them to add to it.

People relax when they know the shape of a conversation. The agenda is not administrative — it is the thing that lets them stop wondering what you are about to do.

3. PERMISSION

"Some of this is quite personal — income, what you owe, who depends on you. Tell me if you would rather not answer something."

Almost everyone says yes. The ones who hesitate have told you something useful about how the meeting should go.

4. DISCOVERY

The six areas: income, expenses, assets and liabilities, dependants, existing cover, objectives.

Ask open, then narrow. "Tell me about your family" before "how many children". The open version surfaces the parent nobody mentioned.

Write down what they say, not what you understood. These differ more than you would expect.

Let silences run. When someone pauses after answering, they are deciding whether to tell you the rest.

5. SUMMARY

"Let me check I have this right." Then say it back — position, commitments, dependants, what they said matters most.

Two things happen. You catch your errors while they are cheap. And the client hears their own situation described clearly, often for the first time, which is frequently the moment they decide you are worth listening to.

6. NEXT STEP

Specific. A day, a purpose, a method. "I''ll come back to you on Thursday with what I''d suggest — shall I call, or would you rather meet?"

Not "I''ll be in touch".

WHAT NOT TO DO

Do not recommend anything. You do not yet have enough, and a recommendation formed in the room is a guess with a product attached.

Do not fill silence.

Do not talk more than a third of the time. If you are, you are not learning anything.

Do not skip the summary because you are running late. It is the most valuable ninety seconds in the meeting.',
 1, 16)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000019-2000-4000-8000-000000000001','0f000019-0000-4000-8000-000000000001','Day 19 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000019-3000-4000-8000-000000000001','0f000019-2000-4000-8000-000000000001',
 'Why set an agenda at the start of a first meeting?','mcq',
 'People relax when they know the shape of a conversation. It stops them wondering what you are about to do.',1),
('0f000019-3000-4000-8000-000000000002','0f000019-2000-4000-8000-000000000001',
 'Why ask permission before personal questions?','scenario',
 'It makes the personal questions feel appropriate rather than intrusive, and a hesitation tells you something useful about how to run the meeting.',2),
('0f000019-3000-4000-8000-000000000003','0f000019-2000-4000-8000-000000000001',
 'You are running short of time. Which part should you not cut?','mcq',
 'The summary. It catches your errors cheaply and is often the moment the client decides you are worth listening to.',3),
('0f000019-3000-4000-8000-000000000004','0f000019-2000-4000-8000-000000000001',
 'What is wrong with ending a meeting saying "I''ll be in touch"?','mcq',
 'It is not a specific next step. Agree a day, a purpose and a method.',4),
('0f000019-3000-4000-8000-000000000005','0f000019-2000-4000-8000-000000000001',
 'Roughly what proportion of a first appointment should the advisor be talking?','mcq',
 'No more than a third. If you are talking more, you are not learning anything about the client.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000019-3000-4000-8000-000000000001','It tells the client the shape of the conversation, which lets them relax',true,1),
('0f000019-3000-4000-8000-000000000001','It demonstrates professionalism to the client',false,2),
('0f000019-3000-4000-8000-000000000001','It is a regulatory requirement',false,3),
('0f000019-3000-4000-8000-000000000001','It shortens the meeting',false,4),
('0f000019-3000-4000-8000-000000000002','It makes personal questions appropriate rather than intrusive',true,1),
('0f000019-3000-4000-8000-000000000002','It transfers responsibility for the answers to the client',false,2),
('0f000019-3000-4000-8000-000000000002','It is required before collecting any data',false,3),
('0f000019-3000-4000-8000-000000000002','It allows you to skip questions they find awkward',false,4),
('0f000019-3000-4000-8000-000000000003','The summary',true,1),
('0f000019-3000-4000-8000-000000000003','The rapport-building at the start',false,2),
('0f000019-3000-4000-8000-000000000003','The questions about existing cover',false,3),
('0f000019-3000-4000-8000-000000000003','The agenda',false,4),
('0f000019-3000-4000-8000-000000000004','It is not specific — a next step needs a day, a purpose and a method',true,1),
('0f000019-3000-4000-8000-000000000004','It sounds unprofessional',false,2),
('0f000019-3000-4000-8000-000000000004','It commits you to contacting them too soon',false,3),
('0f000019-3000-4000-8000-000000000004','Nothing — it is a normal way to close',false,4),
('0f000019-3000-4000-8000-000000000005','No more than about a third',true,1),
('0f000019-3000-4000-8000-000000000005','About half',false,2),
('0f000019-3000-4000-8000-000000000005','Most of it, since you are explaining the process',false,3),
('0f000019-3000-4000-8000-000000000005','It does not matter provided the fact-find is completed',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 20 — Concept Presentation
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000020-0000-4000-8000-000000000001', pg_temp.day_id(20),
  'Concept Presentation', 'conversation',
  'Using the Four Pillars and the Family Income Ladder to make a situation visible without selling anything.',
  '["Deliver both required concepts in five minutes each","Choose the right concept for the client in front of you","Recognise when a concept is the wrong tool"]'::jsonb,
  55, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000020-1000-4000-8000-000000000001','0f000020-0000-4000-8000-000000000001',
 'Making a situation visible',
 'A concept presentation is a structured way of showing a client something about their own position that they had not seen clearly.

It is not a product presentation. Nothing is being recommended. If a concept ends with "and that is why you need this policy", it has been misused.

You must be able to deliver two, and the full detail of each is in the Concepts section of ATLAS:

**Four Pillars of Financial Planning** — for a client with no structure at all, or a scattered collection of products bought one at a time.

**Family Income Ladder** — for a client with dependants, particularly one who says they "probably have enough".

WHAT MAKES A CONCEPT WORK

**You ask; you do not tell.** The pillars get filled in by the client, not by you. The gap the client identifies themselves is worth ten that you point out.

**You use their numbers.** What their household actually costs, what they actually have. Generic figures make it a lecture.

**You stop talking at the right moment.** After the months figure in the Income Ladder, say nothing. The silence is where the thinking happens, and advisors ruin this constantly by filling it.

**Five minutes.** Not fifteen. It is a device for producing a realisation, not a seminar.

CHOOSING BETWEEN THEM

Dependants and an income the household relies on → Family Income Ladder.
No structure, or a scattered collection of products → Four Pillars.
Both apply → Four Pillars first for the overview, Income Ladder next meeting for depth.

WHEN NOT TO USE ONE AT ALL

A client with a well-organised plan and a specific question does not need a framework — they need an answer. Presenting one anyway is condescending.

A client with no dependants does not need the Income Ladder, and using it anyway edges into manufacturing a worry.

Someone recently bereaved: use judgement. The concept may be exactly right, or exactly wrong, and the difference is whether they raised it.

THE ETHICAL LINE

A concept exists to help someone see their situation. It does not exist to make them anxious enough to buy.

The test: could you show a compliance officer a recording of this and be comfortable? If the answer depends on tone rather than content, look at the tone.

WHAT YOU WILL BE ASSESSED ON

Two concept presentations must be passed before your readiness review. You will present to a manager, scored against the twelve-criterion rubric. Accuracy, clarity, structure, question quality, listening, and ethical language all count.',
 1, 16)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000020-2000-4000-8000-000000000001','0f000020-0000-4000-8000-000000000001','Day 20 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000020-3000-4000-8000-000000000001','0f000020-2000-4000-8000-000000000001',
 'A concept presentation ends with "and that is why you need this policy". What has gone wrong?','scenario',
 'It has become a product presentation. A concept exists to make a situation visible, not to justify a recommendation.',1),
('0f000020-3000-4000-8000-000000000002','0f000020-2000-4000-8000-000000000001',
 'Who should fill in the pillars in a Four Pillars presentation?','mcq',
 'The client. A gap they identify themselves is worth ten you point out.',2),
('0f000020-3000-4000-8000-000000000003','0f000020-2000-4000-8000-000000000001',
 'After stating how many months the client''s savings would last, what should you do?','scenario',
 'Stop talking. The silence is where the thinking happens, and filling it removes the effect entirely.',3),
('0f000020-3000-4000-8000-000000000004','0f000020-2000-4000-8000-000000000001',
 'Which client should NOT be shown the Family Income Ladder?','mcq',
 'A client with no dependants. Using it anyway edges into manufacturing a worry that does not apply to them.',4),
('0f000020-3000-4000-8000-000000000005','0f000020-2000-4000-8000-000000000001',
 'How long should a concept presentation take?','mcq',
 'About five minutes. It is a device for producing a realisation, not a seminar.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000020-3000-4000-8000-000000000001','It has become a product presentation rather than a concept',true,1),
('0f000020-3000-4000-8000-000000000001','Nothing — that is the natural conclusion',false,2),
('0f000020-3000-4000-8000-000000000001','The concept was the wrong one for that client',false,3),
('0f000020-3000-4000-8000-000000000001','It should have come earlier in the meeting',false,4),
('0f000020-3000-4000-8000-000000000002','The client',true,1),
('0f000020-3000-4000-8000-000000000002','The advisor, using the fact-find',false,2),
('0f000020-3000-4000-8000-000000000002','The advisor, to save time',false,3),
('0f000020-3000-4000-8000-000000000002','Nobody — the pillars are illustrative only',false,4),
('0f000020-3000-4000-8000-000000000003','Stop talking and let the silence do the work',true,1),
('0f000020-3000-4000-8000-000000000003','Explain immediately how the gap could be closed',false,2),
('0f000020-3000-4000-8000-000000000003','Move on quickly so they do not feel uncomfortable',false,3),
('0f000020-3000-4000-8000-000000000003','Compare their position to the average household',false,4),
('0f000020-3000-4000-8000-000000000004','A client with no dependants',true,1),
('0f000020-3000-4000-8000-000000000004','A parent with young children',false,2),
('0f000020-3000-4000-8000-000000000004','A sole earner with a mortgage',false,3),
('0f000020-3000-4000-8000-000000000004','Someone who says they probably have enough cover',false,4),
('0f000020-3000-4000-8000-000000000005','About five minutes',true,1),
('0f000020-3000-4000-8000-000000000005','Fifteen to twenty minutes',false,2),
('0f000020-3000-4000-8000-000000000005','As long as the client stays engaged',false,3),
('0f000020-3000-4000-8000-000000000005','A full meeting on its own',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 21 — Product Explanation
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000021-0000-4000-8000-000000000001', pg_temp.day_id(21),
  'Explaining a Product Category', 'conversation',
  'Connecting a category to an identified need, stating limitations as clearly as benefits, and checking understanding.',
  '["Explain a category in plain language","State limitations and risks without burying them","Check understanding rather than assuming it"]'::jsonb,
  45, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000021-1000-4000-8000-000000000001','0f000021-0000-4000-8000-000000000001',
 'Explaining without overclaiming',
 'By this point you have found a need. Now you explain a category that addresses it.

A good explanation has five parts and takes about three minutes.

1. CONNECT IT TO WHAT THEY TOLD YOU

Start from their situation, not the product. "You said if your income stopped, the household would be in trouble within about two months. This is the thing designed for that."

If you cannot connect it to something they said, you should not be explaining it.

2. SAY WHAT IT DOES, PLAINLY

One or two sentences, no jargon. "If you die during the next twenty years, it pays your family a lump sum."

If you find yourself using a term you have not defined, stop and define it.

3. SAY WHAT IT DOES NOT DO

This is where advisors go quiet, and it is the part that protects everyone.

"It does not pay anything if you are alive at the end of the twenty years."
"It covers accidents, not illness."
"It pays for conditions on a defined list, at defined severities — not any serious illness."

State the limitation in the same tone as the benefit. A limitation delivered apologetically sounds like something you were hoping they would not notice.

4. STATE THE RISKS

Where value can fall, say so. Where returns are not guaranteed, say so. Where charges reduce early value, say so.

Never say "guaranteed" unless the thing is contractually guaranteed and you have verified it.

5. CHECK THEY UNDERSTOOD

Not "does that make sense?" — everyone says yes to that.

"Just so I know I explained it properly — how would you describe this to your wife?"

Their answer tells you what actually landed. If it comes back wrong, that is not the client failing; it is your explanation, and you get to fix it now rather than at a complaint.

WHEN TO ESCALATE INSTEAD

Specific definitions in a particular insurer''s policy. Tax treatment. Anything about an existing product they hold. Fund selection. Anything where you catch yourself thinking "I think it works like this".

"That is exactly the kind of question I want to get right rather than fast. Let me bring in a senior colleague."

WHAT NEVER TO SAY

"It covers everything." "You are fully protected." "This is guaranteed to grow." "Everyone your age has one." "This offer ends Friday."

Each is either untrue, unverifiable, or pressure. All three are how advisors end up explaining themselves to a regulator.',
 1, 15)
on conflict (id) do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000021-2000-4000-8000-000000000001','0f000021-0000-4000-8000-000000000001','Day 21 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000021-3000-4000-8000-000000000001','0f000021-2000-4000-8000-000000000001',
 'What is wrong with asking "does that make sense?" to check understanding?','scenario',
 'Everyone says yes. Ask them to explain it back to someone instead — their answer shows what actually landed.',1),
('0f000021-3000-4000-8000-000000000002','0f000021-2000-4000-8000-000000000001',
 'How should limitations be delivered relative to benefits?','mcq',
 'In the same tone. A limitation delivered apologetically sounds like something you hoped they would not notice.',2),
('0f000021-3000-4000-8000-000000000003','0f000021-2000-4000-8000-000000000001',
 'You cannot connect a product category to anything the client told you. What does that mean?','scenario',
 'You should not be explaining it. An explanation that does not follow from the fact-find is a product looking for a buyer.',3),
('0f000021-3000-4000-8000-000000000004','0f000021-2000-4000-8000-000000000001',
 'A client explains the product back to you incorrectly. Whose problem is that?','mcq',
 'Yours. It is a signal your explanation did not land, and you can fix it now rather than at a complaint.',4),
('0f000021-3000-4000-8000-000000000005','0f000021-2000-4000-8000-000000000001',
 'Which of these phrases should never be used?','mcq',
 'All of them are untrue, unverifiable or pressure. "This offer ends Friday" manufactures urgency.',5)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000021-3000-4000-8000-000000000001','Everyone says yes to it — ask them to explain it back instead',true,1),
('0f000021-3000-4000-8000-000000000001','It sounds condescending',false,2),
('0f000021-3000-4000-8000-000000000001','It takes too long to answer',false,3),
('0f000021-3000-4000-8000-000000000001','Nothing — it is the standard check',false,4),
('0f000021-3000-4000-8000-000000000002','In the same tone as the benefits',true,1),
('0f000021-3000-4000-8000-000000000002','Briefly at the end, so as not to lose momentum',false,2),
('0f000021-3000-4000-8000-000000000002','In the documentation rather than out loud',false,3),
('0f000021-3000-4000-8000-000000000002','Only if the client asks directly',false,4),
('0f000021-3000-4000-8000-000000000003','You should not be explaining it — it does not follow from the fact-find',true,1),
('0f000021-3000-4000-8000-000000000003','Explain it anyway, since they may not have mentioned everything',false,2),
('0f000021-3000-4000-8000-000000000003','Ask more questions until a connection appears',false,3),
('0f000021-3000-4000-8000-000000000003','Present it as general education rather than a recommendation',false,4),
('0f000021-3000-4000-8000-000000000004','Yours — it is a signal your explanation did not land',true,1),
('0f000021-3000-4000-8000-000000000004','Theirs, if they were not paying attention',false,2),
('0f000021-3000-4000-8000-000000000004','Nobody''s — the documentation covers it',false,3),
('0f000021-3000-4000-8000-000000000004','The product''s, for being too complex',false,4),
('0f000021-3000-4000-8000-000000000005','"This offer ends Friday"',true,1),
('0f000021-3000-4000-8000-000000000005','"It does not cover illness, only accidents"',false,2),
('0f000021-3000-4000-8000-000000000005','"I want to check that with a colleague"',false,3),
('0f000021-3000-4000-8000-000000000005','"The value can fall as well as rise"',false,4)
on conflict do nothing;

-- ===========================================================================
-- DAY 22 — Objection Handling, Closing and Follow-Up
-- ===========================================================================

insert into public.modules (id, programme_day_id, title, category, description, objectives, est_minutes, is_required, sequence, status)
values ('0f000022-0000-4000-8000-000000000001', pg_temp.day_id(22),
  'Objections, Closing and Follow-Up', 'conversation',
  'Understanding the concern before responding to it. Objection handling is not about winning.',
  '["Identify the concern underneath a stated objection","Respond to the eight common objections without pressure","Close and follow up professionally, and stop when told to"]'::jsonb,
  50, true, 1, 'draft')
on conflict (id) do nothing;

insert into public.lessons (id, module_id, title, body, sequence, est_minutes) values
('0f000022-1000-4000-8000-000000000001','0f000022-0000-4000-8000-000000000001',
 'The concern underneath',
 'An objection is rarely the real reason. It is the socially acceptable version of it.

The single most useful skill in this module is asking one question before you respond.

"Can I ask what specifically is making you hesitate?"

That question does more than any prepared answer, because it finds out what you are actually dealing with. An advisor who answers the stated objection is usually answering the wrong question, and the client knows it.

WHAT THIS MODULE IS NOT

It is not a set of techniques for overcoming resistance. A client who is pressured into buying something will lapse it, complain about it, or resent it — and they will tell people.

Your objective is not to win the conversation. It is to find out whether this is right for them, and to help them decide.

Sometimes the honest conclusion is that they should not buy. Reaching it is a success.

THE EIGHT COMMON OBJECTIONS

**"I need to think about it."**
Usually true, and usually reasonable. Underneath is often an unasked question or someone they need to consult.
Ask: "Of course. Is there something specific you want to think through — or something I did not explain well?"

**"I already have an advisor."**
Sometimes true, sometimes a polite exit.
Ask: "That is good — when did you last review things together?" If the answer is years, there may be a genuine gap. If they are well served, say so and leave.

**"I cannot afford it."**
May mean the amount is wrong, or the priority is wrong, or they have other commitments you do not know about.
Ask: "That is fair. Can I ask — is it the amount, or is it that this is not the most pressing thing right now?" Both answers are useful, and both may lead to a smaller recommendation or none.

**"Send me the information."**
Frequently a polite way to end a meeting.
Ask: "I can. Is there something specific you want to see, or would it be more useful to talk it through once more?" If they genuinely want to read it, send it and follow up once.

**"I want to discuss it with my spouse."**
Almost always legitimate and should be encouraged.
Ask: "That makes sense. Would it be easier if I explained it to both of you, so you are not relaying it second-hand?" That is a service, not a tactic.

**"I am not interested."**
Take it at face value.
Say: "That is completely fine. Thank you for your time." Then stop. Pushing past a clear no achieves nothing and costs your reputation.

**"Insurance is too expensive."**
Often a general belief rather than a judgement about your recommendation.
Ask: "Compared with what, out of interest?" It usually opens a real conversation about priorities.

**"I prefer to invest myself."**
Frequently true and frequently sensible.
Ask: "That is fair enough — what are you doing at the moment?" Then listen. If they have a coherent approach, the honest response may be that they do not need investment help, though the protection conversation may still be relevant.

CLOSING

Closing is agreeing a next step, not extracting a signature.

"Where would you like to leave it?" is a legitimate close. So is "shall I get the application ready, or would you rather sit with it for a few days?"

What is not legitimate: manufactured deadlines, implied scarcity, or repeating the ask until they give in from fatigue.

FOLLOWING UP

Once after a few days. Once more after a week. Then stop, having told them where to find you.

If they say no, record it and honour it.

THE STANDARD

Could you describe this conversation to the client''s spouse, word for word, and be comfortable? If not, something in it needs to change.',
 1, 18)
on conflict (id) do nothing;

insert into public.revision_cards (module_id, front, back, sequence) values
('0f000022-0000-4000-8000-000000000001','What is the one question to ask before responding to any objection?','"Can I ask what specifically is making you hesitate?" It finds out what you are actually dealing with.',1),
('0f000022-0000-4000-8000-000000000001','What is the correct response to "I am not interested"?','Take it at face value, thank them, and stop.',2),
('0f000022-0000-4000-8000-000000000001','What is closing, properly understood?','Agreeing a next step — not extracting a signature.',3)
on conflict do nothing;

insert into public.quizzes (id, module_id, title) values
('0f000022-2000-4000-8000-000000000001','0f000022-0000-4000-8000-000000000001','Day 22 knowledge check')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, question_text, question_type, explanation, sequence) values
('0f000022-3000-4000-8000-000000000001','0f000022-2000-4000-8000-000000000001',
 'What should you do before responding to any objection?','mcq',
 'Ask what specifically is making them hesitate. An objection is rarely the real reason, and answering the stated one usually answers the wrong question.',1),
('0f000022-3000-4000-8000-000000000002','0f000022-2000-4000-8000-000000000001',
 'A client says "I am not interested." What is the correct response?','scenario',
 'Take it at face value, thank them and stop. Pushing past a clear no achieves nothing and costs your reputation.',2),
('0f000022-3000-4000-8000-000000000003','0f000022-2000-4000-8000-000000000001',
 'A client wants to discuss it with their spouse. What is the best response?','scenario',
 'Encourage it, and offer to explain it to both so it is not relayed second-hand. That is a service, not a tactic.',3),
('0f000022-3000-4000-8000-000000000004','0f000022-2000-4000-8000-000000000001',
 'A client says they prefer to invest themselves and describes a coherent approach. What is the honest response?','scenario',
 'That they may not need investment help. The protection conversation may still be relevant, but agreeing with them where they are right builds more trust than arguing.',4),
('0f000022-3000-4000-8000-000000000005','0f000022-2000-4000-8000-000000000001',
 'Which of these is a legitimate close?','mcq',
 'Asking where they would like to leave it. Manufactured deadlines and implied scarcity are pressure, not closing.',5),
('0f000022-3000-4000-8000-000000000006','0f000022-2000-4000-8000-000000000001',
 'What is the test for whether a conversation was conducted properly?','mcq',
 'Whether you could describe it to the client''s spouse word for word and be comfortable.',6)
on conflict (id) do nothing;

insert into public.quiz_options (question_id, option_text, is_correct, sequence) values
('0f000022-3000-4000-8000-000000000001','Ask what specifically is making them hesitate',true,1),
('0f000022-3000-4000-8000-000000000001','Restate the benefits more clearly',false,2),
('0f000022-3000-4000-8000-000000000001','Offer a cheaper alternative',false,3),
('0f000022-3000-4000-8000-000000000001','Acknowledge it and move to the close',false,4),
('0f000022-3000-4000-8000-000000000002','Take it at face value, thank them, and stop',true,1),
('0f000022-3000-4000-8000-000000000002','Ask what would make them interested',false,2),
('0f000022-3000-4000-8000-000000000002','Explain what they would be giving up',false,3),
('0f000022-3000-4000-8000-000000000002','Offer to call back in a month',false,4),
('0f000022-3000-4000-8000-000000000003','Encourage it, and offer to explain it to both of them',true,1),
('0f000022-3000-4000-8000-000000000003','Point out that the decision is theirs alone to make',false,2),
('0f000022-3000-4000-8000-000000000003','Ask them to decide before the rate changes',false,3),
('0f000022-3000-4000-8000-000000000003','Treat it as a polite refusal and close the file',false,4),
('0f000022-3000-4000-8000-000000000004','Acknowledge they may not need investment help, and check whether protection is still relevant',true,1),
('0f000022-3000-4000-8000-000000000004','Explain why professional management outperforms self-investing',false,2),
('0f000022-3000-4000-8000-000000000004','Ask about their returns to find a weakness',false,3),
('0f000022-3000-4000-8000-000000000004','End the meeting, as there is nothing to offer',false,4),
('0f000022-3000-4000-8000-000000000005','"Where would you like to leave it?"',true,1),
('0f000022-3000-4000-8000-000000000005','"This rate is only held until Friday"',false,2),
('0f000022-3000-4000-8000-000000000005','"Most people in your situation sign today"',false,3),
('0f000022-3000-4000-8000-000000000005','"If you do not do this now, you may not qualify later"',false,4),
('0f000022-3000-4000-8000-000000000006','Whether you could describe it to the client''s spouse word for word and be comfortable',true,1),
('0f000022-3000-4000-8000-000000000006','Whether the client signed',false,2),
('0f000022-3000-4000-8000-000000000006','Whether it stayed within the allotted time',false,3),
('0f000022-3000-4000-8000-000000000006','Whether every objection was answered',false,4)
on conflict do nothing;

commit;
