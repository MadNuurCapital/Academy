import {
  CalendarDays,
  FileText,
  History,
  Layers,
  Presentation,
  Settings,
  User,
  Users,
} from 'lucide-react';
import { AppShell, type NavItem } from './AppShell';

/**
 * Administrator navigation.
 *
 * The mobile tab bar shows the first five `primary` items and nothing else, so
 * those four are the ones an administrator reaches for most: adding people,
 * reviewing content, settings, and their own profile. The rest are a tap away
 * in the menu.
 *
 * Every item here is now a real screen. The `pending` marker the unbuilt ones
 * carried is kept in NavItem for the next thing that is announced before it
 * lands.
 */
const items: NavItem[] = [
  { to: '/admin/users', label: 'Users', icon: Users, primary: true },
  { to: '/admin/content', label: 'Content', icon: Layers, primary: true },
  { to: '/admin/settings', label: 'Settings', icon: Settings, primary: true },
  { to: '/profile', label: 'Profile', icon: User, primary: true },
  { to: '/admin/scripts', label: 'Scripts', icon: FileText },
  { to: '/admin/concepts', label: 'Concepts', icon: Presentation },
  { to: '/admin/holidays', label: 'Holidays', icon: CalendarDays },
  { to: '/admin/audit', label: 'Audit log', icon: History },
];

export function AdminLayout() {
  return <AppShell items={items} sectionLabel="Administrator navigation" />;
}
