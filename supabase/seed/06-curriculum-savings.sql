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
