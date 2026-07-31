import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/auth/AuthProvider';
import { ProtectedRoute } from '@/auth/ProtectedRoute';
import { AdvisorLayout } from '@/components/layout/AdvisorLayout';
import { ManagerLayout } from '@/components/layout/ManagerLayout';
import { AdminLayout } from '@/components/layout/AdminLayout';
import { LoginPage } from '@/pages/auth/LoginPage';
import { ForgotPasswordPage } from '@/pages/auth/ForgotPasswordPage';
import { SetPasswordPage } from '@/pages/auth/SetPasswordPage';
import { AdvisorDashboard } from '@/pages/advisor/AdvisorDashboard';
import { ManagerDashboard } from '@/pages/manager/ManagerDashboard';
import { PlaceholderPage } from '@/pages/PlaceholderPage';
import { RoleHomeRedirect } from '@/pages/RoleHomeRedirect';
import { NoAccessPage } from '@/pages/NoAccessPage';
import { NotFoundPage } from '@/pages/NotFoundPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

/**
 * Every route from the specification is registered here from Phase 1, even
 * where the screen itself lands in a later phase. Registering them early is
 * what lets the Netlify SPA redirect, the role guards and direct-URL refresh be
 * verified before there is anything to look at.
 */
export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            {/* Public */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<SetPasswordPage mode="reset" />} />
            <Route path="/accept-invite" element={<SetPasswordPage mode="invite" />} />

            {/* Signed in, but wrong role or no role */}
            <Route element={<ProtectedRoute />}>
              <Route path="/no-access" element={<NoAccessPage />} />
            </Route>

            {/* Root sends each user to the home screen matching their roles */}
            <Route element={<ProtectedRoute />}>
              <Route path="/" element={<RoleHomeRedirect />} />
            </Route>

            {/* Advisor */}
            <Route element={<ProtectedRoute allowedRoles={['advisor']} />}>
              <Route element={<AdvisorLayout />}>
                <Route path="/today" element={<AdvisorDashboard />} />
                <Route path="/roadmap" element={<PlaceholderPage title="My roadmap" phase="Phase 2" />} />
                <Route path="/day/:dayNumber" element={<PlaceholderPage title="Programme day" phase="Phase 2" />} />
                <Route path="/module/:moduleId" element={<PlaceholderPage title="Module" phase="Phase 2" />} />
                <Route path="/lesson/:lessonId" element={<PlaceholderPage title="Lesson" phase="Phase 2" />} />
                <Route path="/quiz/:quizId" element={<PlaceholderPage title="Quiz" phase="Phase 2" />} />
                <Route path="/attendance" element={<PlaceholderPage title="My attendance" phase="Phase 3" />} />
                <Route path="/scripts" element={<PlaceholderPage title="Script library" phase="Phase 4" />} />
                <Route path="/scripts/:scriptId" element={<PlaceholderPage title="Script" phase="Phase 4" />} />
                <Route path="/concepts" element={<PlaceholderPage title="Concept presentations" phase="Phase 4" />} />
                <Route path="/coaching" element={<PlaceholderPage title="My coaching" phase="Phase 4" />} />
                <Route path="/coaching/:sessionId" element={<PlaceholderPage title="Coaching session" phase="Phase 4" />} />
                <Route path="/fieldwork" element={<PlaceholderPage title="Joint fieldwork" phase="Phase 4" />} />
                <Route path="/feedback" element={<PlaceholderPage title="Feedback" phase="Phase 4" />} />
                <Route path="/progress" element={<PlaceholderPage title="My progress" phase="Phase 2" />} />
                <Route path="/notifications" element={<PlaceholderPage title="Notifications" phase="Phase 4" />} />
                <Route path="/profile" element={<PlaceholderPage title="My profile" phase="Phase 2" />} />
              </Route>
            </Route>

            {/* Manager */}
            <Route element={<ProtectedRoute allowedRoles={['manager', 'admin']} />}>
              <Route element={<ManagerLayout />}>
                <Route path="/manage" element={<ManagerDashboard />} />
                <Route path="/manage/attendance" element={<PlaceholderPage title="Today's attendance" phase="Phase 3" />} />
                <Route path="/manage/attendance/history" element={<PlaceholderPage title="Attendance history" phase="Phase 3" />} />
                <Route path="/manage/advisors" element={<PlaceholderPage title="Advisors" phase="Phase 2" />} />
                <Route path="/manage/advisors/:advisorId" element={<PlaceholderPage title="Advisor detail" phase="Phase 2" />} />
                <Route path="/manage/enrol" element={<PlaceholderPage title="Enrol an advisor" phase="Phase 2" />} />
                <Route path="/manage/reviews" element={<PlaceholderPage title="Review queue" phase="Phase 4" />} />
                <Route path="/manage/reviews/:assessmentId" element={<PlaceholderPage title="Score a practical" phase="Phase 4" />} />
                <Route path="/manage/coaching" element={<PlaceholderPage title="Coaching" phase="Phase 4" />} />
                <Route path="/manage/coaching/new" element={<PlaceholderPage title="Schedule coaching" phase="Phase 4" />} />
                <Route path="/manage/fieldwork" element={<PlaceholderPage title="Joint fieldwork" phase="Phase 4" />} />
                <Route path="/manage/fieldwork/new" element={<PlaceholderPage title="Record fieldwork" phase="Phase 4" />} />
                <Route path="/manage/readiness/:enrolmentId" element={<PlaceholderPage title="Readiness review" phase="Phase 5" />} />
                <Route path="/manage/reports" element={<PlaceholderPage title="Reports" phase="Phase 5" />} />
              </Route>
            </Route>

            {/* Administrator */}
            <Route element={<ProtectedRoute allowedRoles={['admin']} />}>
              <Route element={<AdminLayout />}>
                <Route path="/admin" element={<Navigate to="/admin/content" replace />} />
                <Route path="/admin/content" element={<PlaceholderPage title="Content management" phase="Phase 2" />} />
                <Route path="/admin/content/modules/:moduleId" element={<PlaceholderPage title="Edit module" phase="Phase 2" />} />
                <Route path="/admin/content/lessons/:lessonId" element={<PlaceholderPage title="Edit lesson" phase="Phase 2" />} />
                <Route path="/admin/content/quizzes/:quizId" element={<PlaceholderPage title="Edit quiz" phase="Phase 2" />} />
                <Route path="/admin/scripts" element={<PlaceholderPage title="Script library" phase="Phase 4" />} />
                <Route path="/admin/concepts" element={<PlaceholderPage title="Concept presentations" phase="Phase 4" />} />
                <Route path="/admin/rubrics" element={<PlaceholderPage title="Scoring rubrics" phase="Phase 4" />} />
                <Route path="/admin/users" element={<PlaceholderPage title="Users and roles" phase="Phase 2" />} />
                <Route path="/admin/holidays" element={<PlaceholderPage title="Public holidays" phase="Phase 3" />} />
                <Route path="/admin/settings" element={<PlaceholderPage title="Settings" phase="Phase 2" />} />
                <Route path="/admin/audit" element={<PlaceholderPage title="Audit log" phase="Phase 3" />} />
              </Route>
            </Route>

            <Route path="*" element={<NotFoundPage />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
