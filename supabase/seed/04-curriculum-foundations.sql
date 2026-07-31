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
