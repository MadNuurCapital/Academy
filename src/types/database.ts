/**
 * Database types.
 *
 * Hand-written for Phase 1 so the app is typed end-to-end before a Supabase
 * project is reachable. Once the migrations are applied, regenerate against the
 * real schema with:
 *
 *   npm run db:types
 *
 * That command overwrites this file, which is why it is excluded from linting.
 */

export type AppRole = 'advisor' | 'manager' | 'admin';
export type ProfileStatus = 'active' | 'inactive';
export type EnrolmentStatus = 'active' | 'paused' | 'completed' | 'extended' | 'withdrawn';
export type EnrolmentDayStatus = 'locked' | 'unlocked' | 'complete';
export type AttendanceStatus = 'present' | 'late' | 'absent';
export type ContentStatus = 'draft' | 'pending_review' | 'approved' | 'published' | 'archived';
export type ReadinessOutcome =
  | 'ready_for_supervised_fieldwork'
  | 'ready_with_development_actions'
  | 'additional_training_required'
  | 'programme_extended';

export interface Profile {
  id: string;
  full_name: string;
  email: string;
  phone: string | null;
  status: ProfileStatus;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserRole {
  id: string;
  user_id: string;
  role: AppRole;
  granted_by: string | null;
  created_at: string;
}

export interface AppSetting {
  key: string;
  value: unknown;
  description: string;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface PublicHoliday {
  id: string;
  holiday_date: string;
  name: string;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProgrammeTemplate {
  id: string;
  name: string;
  description: string | null;
  version: number;
  status: ContentStatus;
  is_default: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProgrammeDay {
  id: string;
  template_id: string;
  day_number: number;
  phase: string;
  title: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface Enrolment {
  id: string;
  advisor_id: string;
  template_id: string;
  start_date: string;
  target_end_date: string;
  current_day: number;
  status: EnrolmentStatus;
  intake_label: string | null;
  enrolled_by: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface EnrolmentPause {
  id: string;
  enrolment_id: string;
  paused_from: string;
  resumed_on: string | null;
  reason: string;
  actioned_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface EnrolmentDay {
  id: string;
  enrolment_id: string;
  programme_day_id: string;
  day_number: number;
  status: EnrolmentDayStatus;
  unlocked_at: string | null;
  completed_at: string | null;
  unlocked_by_override: boolean;
  created_at: string;
  updated_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body: string | null;
  link: string | null;
  read_at: string | null;
  created_at: string;
}

export interface AuditLogEntry {
  id: string;
  actor_id: string | null;
  entity_type: string;
  entity_id: string | null;
  action: string;
  reason: string | null;
  before: unknown;
  after: unknown;
  created_at: string;
}

// ---------------------------------------------------------------------------
// Phase 2 — curriculum content
// ---------------------------------------------------------------------------

export type ModuleProgressStatus = 'not_started' | 'in_progress' | 'complete';
export type LessonType = 'text' | 'video' | 'external';
export type QuestionType = 'mcq' | 'scenario';
export type ResourceType = 'pdf' | 'link' | 'slides' | 'document';

export interface Module {
  id: string;
  programme_day_id: string;
  title: string;
  category: string;
  description: string | null;
  objectives: string[];
  est_minutes: number;
  is_required: boolean;
  sequence: number;
  status: ContentStatus;
  version: number;
  owner_id: string | null;
  last_reviewed_at: string | null;
  next_review_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Lesson {
  id: string;
  module_id: string;
  title: string;
  body: string;
  sequence: number;
  est_minutes: number;
  lesson_type: LessonType;
  video_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface Resource {
  id: string;
  module_id: string;
  title: string;
  storage_path: string | null;
  external_url: string | null;
  resource_type: ResourceType;
  downloadable: boolean;
  sequence: number;
}

export interface Terminology {
  id: string;
  module_id: string;
  term: string;
  definition: string;
  sequence: number;
}

export interface RevisionCard {
  id: string;
  module_id: string;
  front: string;
  back: string;
  sequence: number;
}

export interface Quiz {
  id: string;
  module_id: string;
  title: string;
  /** Null means fall back to app_settings.quiz_pass_mark. */
  pass_mark: number | null;
  randomise_questions: boolean;
  randomise_answers: boolean;
  is_final: boolean;
}

// ---------------------------------------------------------------------------
// Phase 2 — progress
// ---------------------------------------------------------------------------

export interface LessonProgress {
  id: string;
  enrolment_id: string;
  lesson_id: string;
  completed_at: string;
}

export interface ModuleProgress {
  id: string;
  enrolment_id: string;
  module_id: string;
  status: ModuleProgressStatus;
  completed_at: string | null;
}

export interface QuizAttempt {
  id: string;
  enrolment_id: string;
  quiz_id: string;
  attempt_no: number;
  score: number | null;
  passed: boolean | null;
  pass_mark_applied: number | null;
  started_at: string;
  submitted_at: string | null;
  reset_by: string | null;
  reset_reason: string | null;
}

// ---------------------------------------------------------------------------
// RPC payloads
//
// These mirror the jsonb returned by the security-definer functions in
// migration 0007. Note what is absent from AttemptQuestion: the correct option
// is never part of the payload an advisor receives when starting a quiz.
// ---------------------------------------------------------------------------

export interface AttemptOption {
  option_id: string;
  option_text: string;
}

export interface AttemptQuestion {
  question_id: string;
  question_text: string;
  question_type: QuestionType;
  options: AttemptOption[];
}

export interface StartedAttempt {
  attempt_id: string;
  quiz_id: string;
  questions: AttemptQuestion[];
}

export interface SubmittedAnswer {
  question_id: string;
  option_id: string;
}

/** Returned only on a pass — null after a failure, by design. */
export interface AttemptReviewItem {
  question_id: string;
  question_text: string;
  explanation: string | null;
  your_option_id: string | null;
  was_correct: boolean | null;
  correct_option_id: string | null;
}

export interface AttemptResult {
  score: number;
  pass_mark: number;
  passed: boolean;
  correct_answers: number;
  total_questions: number;
  day_complete: boolean;
  review: AttemptReviewItem[] | null;
}

export interface MarkLessonReadResult {
  module_complete: boolean;
  day_complete: boolean;
}
