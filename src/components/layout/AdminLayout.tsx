import { CalendarDays, FileText, History, Layers, Settings, User, Users } from 'lucide-react';
import { AppShell, type NavItem } from './AppShell';

/**
 * Administrator navigation.
 *
 * Only screens that exist are `primary`. The mobile tab bar shows the first
 * five primary items and nothing else, so filling it with placeholders — as it
 * was — meant an admin on a phone was mostly being offered dead ends. The
 * unbuilt ones stay listed, marked `pending`, because knowing they are coming
 * is useful and tapping into "Not built yet" is not.
 */
const items: NavItem[] = [
  { to: '/admin/users', label: 'Users', icon: Users, primary: true },
  { to: '/admin/settings', label: 'Settings', icon: Settings, primary: true },
  { to: '/profile', label: 'Profile', icon: User, primary: true },
  { to: '/admin/content', label: 'Content', icon: Layers, pending: true },
  { to: '/admin/scripts', label: 'Scripts', icon: FileText, pending: true },
  { to: '/admin/holidays', label: 'Holidays', icon: CalendarDays, pending: true },
  { to: '/admin/audit', label: 'Audit log', icon: History, pending: true },
];

export function AdminLayout() {
  return <AppShell items={items} sectionLabel="Administrator navigation" />;
}
