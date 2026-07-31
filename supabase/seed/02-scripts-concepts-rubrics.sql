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
  <rect x="30" y="34" width="420" height="26" rx="4" fill="#1e293b"/>
  <text x="240" y="52" text-anchor="middle" fill="#f8fafc" font-family="sans-serif" font-size="14" font-weight="600">Financial Security</text>
  <g font-family="sans-serif" font-size="11" fill="#0f172a" text-anchor="middle">
    <rect x="42" y="72" width="88" height="140" rx="4" fill="#0d9488" opacity="0.12" stroke="#0d9488"/>
    <text x="86" y="132" font-weight="600">Protection</text>
    <text x="86" y="150" font-size="9" fill="#64748b">If income stops</text>
    <rect x="146" y="72" width="88" height="140" rx="4" fill="#0d9488" opacity="0.12" stroke="#0d9488"/>
    <text x="190" y="132" font-weight="600">Emergency</text>
    <text x="190" y="146" font-weight="600">Fund</text>
    <text x="190" y="164" font-size="9" fill="#64748b">If something breaks</text>
    <rect x="250" y="72" width="88" height="140" rx="4" fill="#0d9488" opacity="0.12" stroke="#0d9488"/>
    <text x="294" y="126" font-weight="600">Savings &amp;</text>
    <text x="294" y="140" font-weight="600">Investment</text>
    <text x="294" y="158" font-size="9" fill="#64748b">To grow</text>
    <rect x="354" y="72" width="88" height="140" rx="4" fill="#0d9488" opacity="0.12" stroke="#0d9488"/>
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
  <line x1="70" y1="52" x2="440" y2="52" stroke="#1e293b" stroke-width="1.5"/>
  <text x="255" y="44" text-anchor="middle" font-family="sans-serif" font-size="10" fill="#1e293b">Monthly cost of running the household</text>
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
