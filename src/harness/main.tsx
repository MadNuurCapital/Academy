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
import type { Lesson, Module, ProgrammeDay } from '@/types/database';
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
          </Route>
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  </AuthContext.Provider>,
);
