import { CalendarDays, FileText, History, Layers, Settings, User, Users } from 'lucide-react';
import { AppShell, type NavItem } from './AppShell';

const items: NavItem[] = [
  { to: '/admin/content', label: 'Content', icon: Layers, primary: true },
  { to: '/admin/scripts', label: 'Scripts', icon: FileText, primary: true },
  { to: '/admin/users', label: 'Users', icon: Users, primary: true },
  { to: '/admin/holidays', label: 'Holidays', icon: CalendarDays, primary: true },
  { to: '/admin/settings', label: 'Settings', icon: Settings, primary: true },
  { to: '/admin/audit', label: 'Audit log', icon: History },
  { to: '/profile', label: 'Profile', icon: User },
];

export function AdminLayout() {
  return <AppShell items={items} sectionLabel="Administrator navigation" />;
}
