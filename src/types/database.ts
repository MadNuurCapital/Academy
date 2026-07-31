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
