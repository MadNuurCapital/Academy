import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/auth/AuthProvider';
import { ProtectedRoute } from '@/auth/ProtectedRoute';
import { AdvisorLayout } from '@/components/layout/AdvisorLayout';
import { ManagerLayout } from '@/components/layout/ManagerLayout';
import { AdminLayout } from '@/components/layout/AdminLayout';
import { ProfileLayout } from '@/components/layout/ProfileLayout';
import { LoginPage } from '@/pages/auth/LoginPage';
import { ForgotPasswordPage } from '@/pages/auth/ForgotPasswordPage';
import { SetPasswordPage } from '@/pages/auth/SetPasswordPage';
import { AdvisorDashboard } from '@/pages/advisor/AdvisorDashboard';
import { RoadmapPage } from '@/pages/advisor/RoadmapPage';
import { DayPage } from '@/pages/advisor/DayPage';
import { ModulePage } from '@/pages/advisor/ModulePage';
import { LessonPage } from '@/pages/advisor/LessonPage';
import { QuizPage } from '@/pages/advisor/QuizPage';
import { ProgressPage } from '@/pages/advisor/ProgressPage';
import { ProfilePage } from '@/pages/advisor/ProfilePage';
import { ManagerDashboard } from '@/pages/manager/ManagerDashboard';
import { AdvisorListPage } from '@/pages/manager/AdvisorListPage';
import { AdvisorDetailPage } from '@/pages/manager/AdvisorDetailPage';
import { EnrolPage } from '@/pages/manager/EnrolPage';
import { TodayAttendancePage } from '@/pages/manager/TodayAttendancePage';
import { AttendanceHistoryPage } from '@/pages/manager/AttendanceHistoryPage';
import { MyAttendancePage } from '@/pages/advisor/MyAttendancePage';
import { ScriptsPage, ScriptDetailPage } from '@/pages/advisor/ScriptsPage';
import { ConceptsPage } from '@/pages/advisor/ConceptsPage';
import { CoachingPage, CoachingDetailPage } from '@/pages/advisor/CoachingPage';
import { FieldworkPage } from '@/pages/advisor/FieldworkPage';
import { FeedbackPage } from '@/pages/advisor/FeedbackPage';
import { NotificationsPage } from '@/pages/advisor/NotificationsPage';
import { ReviewQueuePage, ScorePracticalPage } from '@/pages/manager/ReviewQueuePage';
import { CoachingManagePage, ScheduleCoachingPage } from '@/pages/manager/CoachingManagePage';
import { RecordFieldworkPage } from '@/pages/manager/FieldworkManagePage';
import { ReadinessPage } from '@/pages/manager/ReadinessPage';
import { ReportsPage } from '@/pages/manager/ReportsPage';
import { SettingsPage } from '@/pages/admin/SettingsPage';
import { UsersPage } from '@/pages/admin/UsersPage';
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
                <Route path="/roadmap" element={<RoadmapPage />} />
                <Route path="/day/:dayNumber" element={<DayPage />} />
                <Route path="/module/:moduleId" element={<ModulePage />} />
                <Route path="/lesson/:lessonId" element={<LessonPage />} />
                <Route path="/quiz/:quizId" element={<QuizPage />} />
                <Route path="/attendance" element={<MyAttendancePage />} />
                <Route path="/scripts" element={<ScriptsPage />} />
                <Route path="/scripts/:scriptId" element={<ScriptDetailPage />} />
                <Route path="/concepts" element={<ConceptsPage />} />
                <Route path="/coaching" element={<CoachingPage />} />
                <Route path="/coaching/:sessionId" element={<CoachingDetailPage />} />
                <Route path="/fieldwork" element={<FieldworkPage />} />
                <Route path="/feedback" element={<FeedbackPage />} />
                <Route path="/progress" element={<ProgressPage />} />
                <Route path="/notifications" element={<NotificationsPage />} />
              </Route>
            </Route>

            {/*
              Everyone gets their own profile, whatever their role. This lived
              inside the advisor block, which meant a manager or an admin could
              not reach the one screen that edits their own name.
            */}
            <Route element={<ProtectedRoute />}>
              <Route element={<ProfileLayout />}>
                <Route path="/profile" element={<ProfilePage />} />
              </Route>
            </Route>

            {/* Manager */}
            <Route element={<ProtectedRoute allowedRoles={['manager', 'admin']} />}>
              <Route element={<ManagerLayout />}>
                <Route path="/manage" element={<ManagerDashboard />} />
                <Route path="/manage/attendance" element={<TodayAttendancePage />} />
                <Route path="/manage/attendance/history" element={<AttendanceHistoryPage />} />
                <Route path="/manage/advisors" element={<AdvisorListPage />} />
                <Route path="/manage/advisors/:advisorId" element={<AdvisorDetailPage />} />
                <Route path="/manage/enrol" element={<EnrolPage />} />
                <Route path="/manage/reviews" element={<ReviewQueuePage />} />
                <Route path="/manage/reviews/:assessmentId" element={<ScorePracticalPage />} />
                <Route path="/manage/coaching" element={<CoachingManagePage />} />
                <Route path="/manage/coaching/new" element={<ScheduleCoachingPage />} />
                <Route path="/manage/fieldwork" element={<RecordFieldworkPage />} />
                <Route path="/manage/fieldwork/new" element={<RecordFieldworkPage />} />
                <Route path="/manage/readiness/:enrolmentId" element={<ReadinessPage />} />
                <Route path="/manage/reports" element={<ReportsPage />} />
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
                <Route path="/admin/users" element={<UsersPage />} />
                <Route path="/admin/holidays" element={<PlaceholderPage title="Public holidays" phase="Phase 3" />} />
                <Route path="/admin/settings" element={<SettingsPage />} />
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
