import { BarChart3, CalendarCheck, ClipboardCheck, LayoutDashboard, MessageSquare, User, Users } from 'lucide-react';
import { AppShell, type NavItem } from './AppShell';

/**
 * Manager navigation.
 *
 * Attendance sits second because recording it is the one thing a manager does
 * every single morning, and it should take under a minute.
 */
const items: NavItem[] = [
  { to: '/manage', label: 'Dashboard', icon: LayoutDashboard, primary: true, end: true },
  { to: '/manage/attendance', label: 'Attendance', icon: CalendarCheck, primary: true },
  { to: '/manage/advisors', label: 'Advisors', icon: Users, primary: true },
  { to: '/manage/reviews', label: 'Reviews', icon: ClipboardCheck, primary: true },
  { to: '/manage/coaching', label: 'Coaching', icon: MessageSquare, primary: true },
  { to: '/manage/reports', label: 'Reports', icon: BarChart3 },
  { to: '/profile', label: 'Profile', icon: User },
];

export function ManagerLayout() {
  return <AppShell items={items} sectionLabel="Manager navigation" />;
}
