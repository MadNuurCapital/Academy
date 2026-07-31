import { BookOpen, CalendarCheck, FileText, Home, Map, MessageSquare, User } from 'lucide-react';
import { AppShell, type NavItem } from './AppShell';

/**
 * Advisor navigation.
 *
 * The five primary items map to the questions the dashboard exists to answer:
 * what do I do today, am I on track, what is my attendance, what is my next
 * action. Everything else is secondary.
 */
const items: NavItem[] = [
  { to: '/today', label: 'Today', icon: Home, primary: true, end: true },
  { to: '/roadmap', label: 'Roadmap', icon: Map, primary: true },
  { to: '/attendance', label: 'Attendance', icon: CalendarCheck, primary: true },
  { to: '/scripts', label: 'Scripts', icon: FileText, primary: true },
  { to: '/coaching', label: 'Coaching', icon: MessageSquare, primary: true },
  { to: '/concepts', label: 'Concepts', icon: BookOpen },
  { to: '/profile', label: 'Profile', icon: User },
];

export function AdvisorLayout() {
  return <AppShell items={items} sectionLabel="Advisor navigation" />;
}
