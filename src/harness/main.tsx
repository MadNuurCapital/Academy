/**
 * Render harness — development only, never built or shipped.
 *
 * It mounts real page components against a pre-seeded React Query cache, so a
 * screen can be photographed and measured without a database, a session or a
 * network. The point is that these are the actual components: no mock copies to
 * drift out of step with the ones advisors and managers use.
 */
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { AuthContext, type AuthState } from '@/auth/AuthContext';
import { AdminLayout } from '@/components/layout/AdminLayout';
import { ContentPage } from '@/pages/admin/ContentPage';
import { ModuleEditorPage } from '@/pages/admin/ModuleEditorPage';
import { ScriptsAdminPage } from '@/pages/admin/ScriptsAdminPage';
import { ConceptsAdminPage } from '@/pages/admin/ConceptsAdminPage';
import { HolidaysPage } from '@/pages/admin/HolidaysPage';
import { AuditPage } from '@/pages/admin/AuditPage';
import type {
  ConceptPresentation,
  Lesson,
  Module,
  ProgrammeDay,
  Script,
} from '@/types/database';
import '@/styles/index.css';

const now = '2026-08-04T00:00:00Z';

function day(number: number, phase: string, title: string): ProgrammeDay {
  return {
    id: `day-${number}`,
    template_id: 'template-1',
    day_number: number,
    phase,
    title,
    description: null,
    created_at: now,
    updated_at: now,
  };
}

function module_(
  id: string,
  dayId: string,
  title: string,
  status: Module['status'],
): Module {
  return {
    id,
    programme_day_id: dayId,
    title,
    category: 'foundation',
    description: 'What this module covers and why it matters on the job.',
    objectives: [],
    est_minutes: 45,
    is_required: true,
    sequence: 1,
    status,
    version: 1,
    owner_id: null,
    last_reviewed_at: null,
    next_review_at: null,
    created_at: now,
    updated_at: now,
  };
}

const days: ProgrammeDay[] = [
  day(1, 'Foundation', 'Welcome, the firm and how the programme works'),
  day(2, 'Foundation', 'Regulation, licensing and your obligations'),
  day(3, 'Foundation', 'Singapore Financial Foundations: CPF, BRS, FRS and ERS'),
  day(11, 'Products', 'Investment-linked plans: how they actually work'),
  day(18, 'Client conversations', 'Advisor Introduction & Value Pitch'),
];

const outline = [
  {
    day: days[0]!,
    modules: [
      module_('m-1', 'day-1', 'Who we are and what an advisor does here', 'published'),
      module_('m-1b', 'day-1', 'How the thirty days are structured', 'published'),
    ],
  },
  {
    day: days[1]!,
    modules: [module_('m-2', 'day-2', 'The regulatory framework you work inside', 'draft')],
  },
  {
    day: days[2]!,
    modules: [
      module_('m-3', 'day-3', 'CPF, the Retirement Sums and what they are not', 'draft'),
    ],
  },
  { day: days[3]!, modules: [module_('m-4', 'day-11', 'Investment-linked plans', 'draft')] },
  {
    day: days[4]!,
    modules: [
      module_('m-5', 'day-18', 'Introducing yourself and the value you bring', 'draft'),
    ],
  },
];

const lessons: Lesson[] = [
  {
    id: 'lesson-1',
    module_id: 'm-3',
    title: 'What the CPF Retirement Sums are',
    body:
      'The Basic Retirement Sum, the Full Retirement Sum and the Enhanced Retirement Sum are\n' +
      'thresholds inside a member’s CPF Retirement Account. They are not products, and nothing\n' +
      'about them is bought or sold.\n\n' +
      'A client who asks "should I top up to the FRS?" is asking about their own CPF account.\n' +
      'Answer that question on its own terms before any conversation about what you advise on.\n\n' +
      'The figures change most years. Check the current year’s sums on the CPF Board site each\n' +
      'January rather than repeating a number you learned here.',
    sequence: 1,
    est_minutes: 20,
    lesson_type: 'text',
    video_url: null,
    created_at: now,
    updated_at: now,
  },
];

const quiz = {
  quiz: { id: 'quiz-1', title: 'CPF foundations', pass_mark_pct: 80, is_final: false },
  questions: [
    {
      id: 'q-1',
      question_text: 'A client asks whether the Full Retirement Sum is an insurance policy. What is the accurate answer?',
      explanation:
        'The FRS is a threshold within a CPF Retirement Account, not a product of any kind. ' +
        'Saying otherwise misleads the client about what they hold.',
      sequence: 1,
      options: [
        { id: 'o-1', option_text: 'It is a CPF savings threshold, not a product', is_correct: true, sequence: 1 },
        { id: 'o-2', option_text: 'It is a government annuity you can buy', is_correct: false, sequence: 2 },
        { id: 'o-3', option_text: 'It is an insurance policy issued by CPF Board', is_correct: false, sequence: 3 },
        { id: 'o-4', option_text: 'It is a unit trust held inside CPF', is_correct: false, sequence: 4 },
      ],
    },
    {
      id: 'q-2',
      question_text: 'How often should you check the published Retirement Sum figures?',
      explanation: null,
      sequence: 2,
      options: [
        { id: 'o-5', option_text: 'Every January, from the CPF Board', is_correct: true, sequence: 1 },
        { id: 'o-6', option_text: 'Once, when you are licensed', is_correct: false, sequence: 2 },
        { id: 'o-7', option_text: 'Only when a client asks', is_correct: false, sequence: 3 },
      ],
    },
  ],
};

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false, staleTime: Infinity, gcTime: Infinity } },
});

queryClient.setQueryData(['content-outline'], outline);
queryClient.setQueryData(['module-editing', 'm-3'], {
  module: outline[2]!.modules[0]!,
  lessons,
  quizId: 'quiz-1',
});
queryClient.setQueryData(['quiz-authoring', 'quiz-1'], quiz);

const scripts: Script[] = [
  {
    id: 'script-1',
    title: 'Asking someone you know for an introduction',
    situation:
      'You have finished your licensing and are building a first list of people to speak to.',
    objective:
      'Ask plainly for an introduction, in a way the other person can say no to without it costing anything.',
    wording:
      'I have just started as a financial advisor with Integrated Barakah Wealth Advisory.\n\n' +
      'I am not asking you to buy anything, and I am not going to pitch you. I am building up\n' +
      'the practice of having the conversation properly. If you know someone who would not mind\n' +
      'half an hour with me so I can practise, I would be grateful. And if not, that is\n' +
      'completely fine.',
    talking_points: [
      'Say who you work for and what you do, in one sentence.',
      'Make the ask specific: half an hour, a conversation, not a sale.',
      'Give them a way to decline that costs them nothing.',
    ],
    variations: [
      'If they ask what you would talk about, describe the fact-find, not a product.',
      'If they offer to be the one you practise on, take it — that is a better outcome.',
    ],
    common_mistakes: [
      'Describing a product before there is any reason to.',
      'Asking for "anyone who needs insurance", which is a question nobody can answer.',
      'Apologising so much that the other person feels awkward saying yes.',
    ],
    compliance_note:
      'You are asking for an introduction, not giving advice. Do not describe or recommend any product in this conversation.',
    sequence: 1,
    version: 1,
    status: 'published',
    approved_at: '2026-08-01T00:00:00Z',
  },
  {
    id: 'script-2',
    title: 'Opening a first meeting',
    situation: 'The first time you sit down with someone who has agreed to meet you.',
    objective: 'Set out what the meeting is and is not, so nobody is waiting for a sales pitch.',
    wording:
      'Thank you for the time. Before anything else — this meeting is me understanding your\n' +
      'situation. I am not going to recommend anything today, because I do not know enough yet\n' +
      'to recommend anything responsibly.',
    talking_points: [
      'Say what will happen in this meeting and what will not.',
      'Explain that a recommendation comes later, after a fact-find.',
    ],
    variations: [],
    common_mistakes: ['Moving to a product because the silence feels uncomfortable.'],
    compliance_note: null,
    sequence: 2,
    version: 1,
    status: 'draft',
    approved_at: null,
  },
];

const concepts: ConceptPresentation[] = [
  {
    id: 'concept-1',
    name: 'The Four Pillars',
    purpose:
      'Show how protection, savings, investment and retirement sit alongside each other, so a client can see what they already have and what is missing.',
    suitable_situations:
      'A first conversation with someone who has never mapped out their finances.',
    when_not_to_use:
      'When the client already knows exactly what they want to talk about. Walking them through a framework they did not ask for wastes the meeting.',
    diagram_svg: null,
    steps: [
      'Draw the four pillars and name them.',
      'Ask which one they feel most confident about.',
      'Ask which one they have thought about least.',
      'Stop there. The gap they name is the conversation.',
    ],
    discovery_questions: [
      'If your income stopped tomorrow, how long could the household carry on as it is?',
      'Which of these four have you already put something in place for?',
    ],
    transition:
      'Once the client names a gap, move to fact-finding about that gap rather than presenting anything.',
    common_mistakes: [
      'Presenting all four pillars as problems to be solved at once.',
      'Filling the silence after a question instead of letting them answer.',
    ],
    compliance_note:
      'This is an explanation, not a recommendation. Nothing here is specific to a product.',
    is_required: true,
    sequence: 1,
    status: 'published',
  },
  {
    id: 'concept-2',
    name: 'Life Journey Timeline',
    purpose: 'Place known future commitments on a timeline so their order becomes visible.',
    suitable_situations: 'Clients with children, or with a dependant whose needs change by year.',
    when_not_to_use: 'When the client finds a long horizon distressing rather than clarifying.',
    diagram_svg: null,
    steps: ['Draw the years ahead.', 'Mark the commitments the client already knows about.'],
    discovery_questions: ['What is already fixed in the next ten years?'],
    transition: null,
    common_mistakes: ['Putting a product on the timeline before the client has put a need on it.'],
    compliance_note: null,
    is_required: false,
    sequence: 3,
    status: 'draft',
  },
];

queryClient.setQueryData(['authoring-scripts'], scripts);
queryClient.setQueryData(['authoring-concepts'], concepts);

queryClient.setQueryData(
  ['holidays-admin'],
  [
    { id: 'h-1', holiday_date: '2026-01-01', name: "New Year's Day" },
    { id: 'h-2', holiday_date: '2026-02-17', name: 'Chinese New Year' },
    { id: 'h-3', holiday_date: '2026-02-18', name: 'Chinese New Year' },
    { id: 'h-4', holiday_date: '2026-04-03', name: 'Good Friday' },
    { id: 'h-5', holiday_date: '2026-05-01', name: 'Labour Day' },
    { id: 'h-6', holiday_date: '2026-05-27', name: 'Hari Raya Haji' },
    { id: 'h-7', holiday_date: '2026-06-01', name: 'Vesak Day (in lieu of Sun 31 May)' },
    { id: 'h-8', holiday_date: '2026-08-10', name: 'National Day (in lieu of Sun 9 Aug)' },
    // Deliberately wrong, so the screen is photographed saying so.
    { id: 'h-9', holiday_date: '2026-11-08', name: 'Deepavali' },
    { id: 'h-10', holiday_date: '2026-12-25', name: 'Christmas Day' },
  ],
);

queryClient.setQueryData(
  ['admin-users'],
  [
    { profile: { id: 'admin-1', full_name: 'Nur Iman' }, roles: ['admin'] },
    { profile: { id: 'mgr-1', full_name: 'Siti Rahmah' }, roles: ['manager'] },
  ],
);

queryClient.setQueryData(
  ['audit-log', { actorId: undefined, from: undefined, to: undefined, limit: 100 }],
  [
    {
      id: 'a-1',
      actor_id: 'admin-1',
      entity_type: 'module',
      entity_id: 'm-3',
      action: 'set_module_status',
      reason: null,
      before: { status: 'draft', title: 'CPF, the Retirement Sums and what they are not' },
      after: { status: 'published' },
      created_at: '2026-08-04T02:14:00Z',
    },
    {
      id: 'a-2',
      actor_id: 'mgr-1',
      entity_type: 'quiz_attempt',
      entity_id: 'att-1',
      action: 'reset_quiz_attempts',
      reason: 'Three attempts used on a question that turned out to be worded ambiguously.',
      before: { attempts: 3 },
      after: { attempts: 0 },
      created_at: '2026-08-03T09:41:00Z',
    },
    {
      id: 'a-3',
      actor_id: 'mgr-1',
      entity_type: 'enrolment',
      entity_id: 'e-1',
      action: 'pause_enrolment',
      reason: 'Family emergency. Agreed to resume on the 17th.',
      before: { status: 'active' },
      after: { status: 'paused', paused_from: '2026-07-28' },
      created_at: '2026-07-28T01:02:00Z',
    },
  ],
);

const auth: AuthState = {
  session: null,
  profile: {
    id: 'admin-1',
    full_name: 'Nur Iman',
    email: 'admin@example.com',
    phone: null,
    status: 'active',
    avatar_url: null,
    created_at: now,
    updated_at: now,
  },
  roles: ['admin'],
  isResolving: false,
  error: null,
  hasRole: (role) => role === 'admin',
  isManagerOrAdmin: true,
  isAdmin: true,
  isAdvisor: false,
  signIn: async () => ({ error: null }),
  signOut: async () => {},
  refresh: async () => {},
};

const route = new URLSearchParams(window.location.search).get('route') ?? '/admin/content';

createRoot(document.getElementById('root')!).render(
  <AuthContext.Provider value={auth}>
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[route]}>
        <Routes>
          <Route element={<AdminLayout />}>
            <Route path="/admin/content" element={<ContentPage />} />
            <Route path="/admin/content/modules/:moduleId" element={<ModuleEditorPage />} />
            <Route path="/admin/scripts" element={<ScriptsAdminPage />} />
            <Route path="/admin/concepts" element={<ConceptsAdminPage />} />
            <Route path="/admin/holidays" element={<HolidaysPage />} />
            <Route path="/admin/audit" element={<AuditPage />} />
          </Route>
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  </AuthContext.Provider>,
);
