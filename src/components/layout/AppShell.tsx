import { useState } from 'react';
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { LogOut, Menu, X } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { cn } from '@/lib/cn';
import { Button } from '@/components/ui/Button';
import { Brand } from '@/components/ui/Brand';

export interface NavItem {
  to: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  /** Shown in the mobile bottom bar. Space is limited, so only the primary few. */
  primary?: boolean;
  end?: boolean;
  /**
   * Marks a screen that is not built yet. Saying so in the navigation is kinder
   * than letting someone tap it and find out — particularly on a phone, where
   * getting back is a deliberate act.
   */
  pending?: boolean;
}

/**
 * The application shell.
 *
 * Sidebar on desktop, bottom tab bar on mobile. Both are first-class: advisors
 * read lessons and check scripts on a phone, while managers mark attendance and
 * score practicals on a laptop.
 */
export function AppShell({ items, sectionLabel }: { items: NavItem[]; sectionLabel: string }) {
  const { profile, roles, signOut } = useAuth();
  const navigate = useNavigate();
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const primaryItems = items.filter((item) => item.primary).slice(0, 5);

  async function handleSignOut() {
    await signOut();
    navigate('/login', { replace: true });
  }

  return (
    <div className="min-h-screen">
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r border-white/[0.07] bg-white/[0.03] backdrop-blur-xl lg:flex">
        <div className="flex h-[4.5rem] items-center border-b border-white/[0.07] px-5">
          <HomeLink />
        </div>
        <nav aria-label={sectionLabel} className="flex-1 space-y-1 overflow-y-auto p-3">
          {items.map((item) => (
            <SidebarLink key={item.to} item={item} />
          ))}
        </nav>
        <div className="border-t border-white/[0.07] p-3">
          <UserSummary name={profile?.full_name} roles={roles} />
          <Button variant="ghost" size="sm" className="mt-2 w-full justify-start" onClick={handleSignOut}>
            <LogOut className="h-4 w-4" aria-hidden="true" />
            Sign out
          </Button>
        </div>
      </aside>

      {/* Mobile top bar */}
      <header className="sticky top-0 z-30 flex h-[4.5rem] items-center justify-between border-b border-white/[0.07] bg-background/80 px-4 backdrop-blur-xl lg:hidden">
        <HomeLink />
        <button
          type="button"
          onClick={() => setIsMenuOpen((open) => !open)}
          aria-expanded={isMenuOpen}
          aria-controls="mobile-menu"
          aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
          className="inline-flex h-11 w-11 items-center justify-center rounded-md text-foreground transition-colors hover:bg-white/[0.07]"
        >
          {isMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
      </header>

      {/* Mobile slide-over */}
      {isMenuOpen && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div
            className="absolute inset-0 bg-background/70 backdrop-blur-sm"
            onClick={() => setIsMenuOpen(false)}
            aria-hidden="true"
          />
          <div
            id="mobile-menu"
            className="absolute inset-y-0 right-0 flex w-72 flex-col border-l border-white/10 bg-background/95 shadow-2xl backdrop-blur-xl"
          >
            <div className="flex h-[4.5rem] items-center justify-between border-b border-white/[0.07] px-4">
              <span className="console-label">{sectionLabel}</span>
              <button
                type="button"
                onClick={() => setIsMenuOpen(false)}
                aria-label="Close menu"
                className="inline-flex h-11 w-11 items-center justify-center rounded-md transition-colors hover:bg-white/[0.07]"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <nav aria-label={sectionLabel} className="flex-1 space-y-1 overflow-y-auto p-3">
              {items.map((item) => (
                <SidebarLink key={item.to} item={item} onNavigate={() => setIsMenuOpen(false)} />
              ))}
            </nav>
            <div className="border-t border-white/[0.07] p-3">
              <UserSummary name={profile?.full_name} roles={roles} />
              <Button variant="ghost" size="sm" className="mt-2 w-full justify-start" onClick={handleSignOut}>
                <LogOut className="h-4 w-4" aria-hidden="true" />
                Sign out
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Content */}
      <div className="lg:pl-64">
        <main className="mx-auto max-w-6xl px-4 py-6 pb-28 sm:px-6 lg:pb-10">
          <Outlet />
        </main>
      </div>

      {/* Mobile bottom tabs */}
      {primaryItems.length > 0 && (
        <nav
          aria-label={`${sectionLabel} primary`}
          className="fixed inset-x-0 bottom-0 z-30 flex border-t border-white/[0.07] bg-background/85 pb-safe backdrop-blur-xl lg:hidden"
        >
          {primaryItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                cn(
                  'flex flex-1 flex-col items-center gap-1 px-1 pt-2 text-xs font-medium',
                  'transition-colors duration-150',
                  isActive ? 'text-highlight' : 'text-muted-foreground',
                )
              }
            >
              <item.icon className="h-5 w-5" aria-hidden="true" />
              <span className="truncate">{item.label}</span>
            </NavLink>
          ))}
        </nav>
      )}
    </div>
  );
}

/**
 * The logo, as a link home.
 *
 * It points at "/" rather than at a role's dashboard directly, so RoleHomeRedirect
 * stays the single place that decides where home is. An advisor lands on their
 * day, a manager on their dashboard, an admin on Users.
 *
 * The visible text already reads "ATLAS Academy Integrated Barakah Wealth
 * Advisory", which is a mouthful for a screen reader to announce as a
 * destination, so the link carries its own shorter label.
 */
function HomeLink() {
  return (
    <Link
      to="/"
      aria-label="ATLAS Academy — go to my dashboard"
      className="-mx-2 rounded-md px-2 py-1 transition-colors duration-150 hover:bg-white/[0.05]"
    >
      <Brand />
    </Link>
  );
}

function SidebarLink({ item, onNavigate }: { item: NavItem; onNavigate?: () => void }) {
  return (
    <NavLink
      to={item.to}
      end={item.end}
      onClick={onNavigate}
      className={({ isActive }) =>
        cn(
          'relative flex min-h-[44px] items-center gap-3 rounded-md px-3 py-2 text-sm font-medium',
          'transition-[background-color,color] duration-150 ease-console',
          // The active item gets a tan spine at its leading edge as well as the
          // lifted plate, so the current section is legible without relying on
          // a colour difference alone.
          isActive
            ? 'bg-white/[0.07] text-foreground before:absolute before:inset-y-1.5 before:left-0 before:w-0.5 before:rounded-full before:bg-highlight'
            : 'text-muted-foreground hover:bg-white/[0.04] hover:text-foreground',
        )
      }
    >
      <item.icon className="h-4 w-4 shrink-0" aria-hidden="true" />
      <span className="flex-1">{item.label}</span>
      {item.pending && (
        <span className="console-label shrink-0 text-[10px] opacity-70">Soon</span>
      )}
    </NavLink>
  );
}

function UserSummary({ name, roles }: { name: string | undefined; roles: string[] }) {
  return (
    <div className="px-3 py-2">
      <p className="truncate text-sm font-medium text-foreground">{name ?? 'Signed in'}</p>
      <p className="truncate text-xs capitalize text-muted-foreground">
        {roles.length > 0 ? roles.join(' · ') : 'No role assigned'}
      </p>
    </div>
  );
}
