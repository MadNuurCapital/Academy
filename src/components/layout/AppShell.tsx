import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { LogOut, Menu, X } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { cn } from '@/lib/cn';
import { Button } from '@/components/ui/Button';

export interface NavItem {
  to: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  /** Shown in the mobile bottom bar. Space is limited, so only the primary few. */
  primary?: boolean;
  end?: boolean;
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
    <div className="min-h-screen bg-background">
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 hidden w-64 flex-col border-r border-border bg-surface lg:flex">
        <div className="flex h-16 items-center border-b border-border px-5">
          <Brand />
        </div>
        <nav aria-label={sectionLabel} className="flex-1 space-y-1 overflow-y-auto p-3">
          {items.map((item) => (
            <SidebarLink key={item.to} item={item} />
          ))}
        </nav>
        <div className="border-t border-border p-3">
          <UserSummary name={profile?.full_name} roles={roles} />
          <Button variant="ghost" size="sm" className="mt-2 w-full justify-start" onClick={handleSignOut}>
            <LogOut className="h-4 w-4" aria-hidden="true" />
            Sign out
          </Button>
        </div>
      </aside>

      {/* Mobile top bar */}
      <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-border bg-surface px-4 lg:hidden">
        <Brand />
        <button
          type="button"
          onClick={() => setIsMenuOpen((open) => !open)}
          aria-expanded={isMenuOpen}
          aria-controls="mobile-menu"
          aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
          className="inline-flex h-11 w-11 items-center justify-center rounded-md text-foreground hover:bg-muted"
        >
          {isMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
      </header>

      {/* Mobile slide-over */}
      {isMenuOpen && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div
            className="absolute inset-0 bg-foreground/40"
            onClick={() => setIsMenuOpen(false)}
            aria-hidden="true"
          />
          <div
            id="mobile-menu"
            className="absolute inset-y-0 right-0 flex w-72 flex-col bg-surface shadow-xl"
          >
            <div className="flex h-16 items-center justify-between border-b border-border px-4">
              <span className="text-sm font-semibold">{sectionLabel}</span>
              <button
                type="button"
                onClick={() => setIsMenuOpen(false)}
                aria-label="Close menu"
                className="inline-flex h-11 w-11 items-center justify-center rounded-md hover:bg-muted"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <nav aria-label={sectionLabel} className="flex-1 space-y-1 overflow-y-auto p-3">
              {items.map((item) => (
                <SidebarLink key={item.to} item={item} onNavigate={() => setIsMenuOpen(false)} />
              ))}
            </nav>
            <div className="border-t border-border p-3">
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
        <main className="mx-auto max-w-5xl px-4 py-6 pb-28 sm:px-6 lg:pb-10">
          <Outlet />
        </main>
      </div>

      {/* Mobile bottom tabs */}
      {primaryItems.length > 0 && (
        <nav
          aria-label={`${sectionLabel} primary`}
          className="fixed inset-x-0 bottom-0 z-30 flex border-t border-border bg-surface pb-safe lg:hidden"
        >
          {primaryItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                cn(
                  'flex flex-1 flex-col items-center gap-1 px-1 pt-2 text-xs font-medium',
                  isActive ? 'text-accent' : 'text-muted-foreground',
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

function Brand() {
  return (
    <div className="flex items-baseline gap-2">
      {/* Placeholder wordmark. Swap for the MadNuur Capital logo when supplied. */}
      <span className="text-lg font-bold tracking-tight text-foreground">ATLAS</span>
      <span className="text-sm font-medium text-muted-foreground">Academy</span>
    </div>
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
          'flex min-h-[44px] items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
          isActive ? 'bg-accent/10 text-accent' : 'text-foreground hover:bg-muted',
        )
      }
    >
      <item.icon className="h-4 w-4 shrink-0" aria-hidden="true" />
      {item.label}
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
