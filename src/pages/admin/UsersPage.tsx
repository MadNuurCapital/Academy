import { useState } from 'react';
import { Check, Pencil, UserPlus, X } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import {
  useSetProfileStatus,
  useSetRole,
  useUpdateProfile,
  useUsers,
  type UserWithRoles,
} from '@/api/users';
import { Panel, Well } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { cn } from '@/lib/cn';
import type { AppRole } from '@/types/database';

const ROLES: { role: AppRole; label: string; note: string }[] = [
  { role: 'advisor', label: 'Advisor', note: 'Works through the programme' },
  { role: 'manager', label: 'Manager', note: 'Marks attendance, scores, decides readiness' },
  { role: 'admin', label: 'Admin', note: 'Everything a manager can do, plus this screen' },
];

/**
 * Users and roles.
 *
 * Everything here was always permitted by the database; until now it was being
 * done by hand in the SQL editor. Roles are additive, so this shows three
 * independent toggles rather than a single picker — one person can be both a
 * manager and an advisor working through the programme themselves.
 */
export function UsersPage() {
  const { profile: me } = useAuth();
  const { data: users, isLoading, error, refetch } = useUsers();
  const [editingId, setEditingId] = useState<string | null>(null);

  if (isLoading) return <LoadingState label="Loading users…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load the users"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  const active = (users ?? []).filter((u) => u.profile.status === 'active');
  const inactive = (users ?? []).filter((u) => u.profile.status !== 'active');

  return (
    <div className="space-y-6">
      <div>
        <h1>Users and roles</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Rename anyone, change what they can do, or deactivate someone who has left.
        </p>
      </div>

      {/*
        Account creation is not here, and cannot be: it needs the service-role
        key, which bypasses every security policy in the system and must never
        be sent to a browser. Saying where it does happen is more useful than
        leaving someone hunting for a button.
      */}
      <Panel className="flex items-start gap-3 p-4">
        <UserPlus className="mt-0.5 h-5 w-5 shrink-0 text-muted-foreground" aria-hidden="true" />
        <div className="text-sm">
          <p className="font-medium">New accounts start in Supabase</p>
          <p className="mt-1 text-muted-foreground">
            Authentication → Users → Add user. Tick <em>Auto Confirm User</em> and set{' '}
            <code className="rounded bg-white/[0.07] px-1 py-0.5 text-[13px]">
              {'{"full_name": "Their Name"}'}
            </code>{' '}
            as user metadata. They appear here within a few seconds, and you give them a role
            below. Creating the account itself needs a key that would be unsafe in a browser.
          </p>
        </div>
      </Panel>

      {active.length === 0 ? (
        <EmptyState title="No active users" description="Create the first account in Supabase." />
      ) : (
        <div className="space-y-2">
          {active.map((user) => (
            <UserRow
              key={user.profile.id}
              user={user}
              isSelf={user.profile.id === me?.id}
              isEditing={editingId === user.profile.id}
              onEdit={() => setEditingId(user.profile.id)}
              onDone={() => setEditingId(null)}
            />
          ))}
        </div>
      )}

      {inactive.length > 0 && (
        <section className="space-y-2">
          <h2 className="console-label">Deactivated</h2>
          <p className="text-sm text-muted-foreground">
            They cannot sign in. Their attendance, scores and readiness decisions stay in the
            record — nobody is ever deleted.
          </p>
          {inactive.map((user) => (
            <UserRow
              key={user.profile.id}
              user={user}
              isSelf={user.profile.id === me?.id}
              isEditing={editingId === user.profile.id}
              onEdit={() => setEditingId(user.profile.id)}
              onDone={() => setEditingId(null)}
            />
          ))}
        </section>
      )}
    </div>
  );
}

function UserRow({
  user,
  isSelf,
  isEditing,
  onEdit,
  onDone,
}: {
  user: UserWithRoles;
  isSelf: boolean;
  isEditing: boolean;
  onEdit: () => void;
  onDone: () => void;
}) {
  const updateProfile = useUpdateProfile();
  const setRole = useSetRole();
  const setStatus = useSetProfileStatus();

  const [fullName, setFullName] = useState(user.profile.full_name);
  const [phone, setPhone] = useState(user.profile.phone ?? '');
  const [failure, setFailure] = useState<string | null>(null);

  const isInactive = user.profile.status !== 'active';

  async function save() {
    setFailure(null);
    if (!fullName.trim()) {
      setFailure('A name cannot be empty.');
      return;
    }
    try {
      await updateProfile.mutateAsync({
        userId: user.profile.id,
        fullName,
        phone: phone || null,
      });
      onDone();
    } catch (e) {
      setFailure(e instanceof Error ? e.message : 'We could not save that.');
    }
  }

  async function toggleRole(role: AppRole, granted: boolean) {
    setFailure(null);
    try {
      await setRole.mutateAsync({ userId: user.profile.id, role, granted });
    } catch (e) {
      setFailure(e instanceof Error ? e.message : 'We could not change that role.');
    }
  }

  return (
    <Panel className={cn('p-4', isInactive && 'opacity-60')}>
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          {isEditing ? (
            <div className="grid gap-2 sm:max-w-md sm:grid-cols-2">
              <input
                aria-label="Full name"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                className="min-h-[44px] rounded-md border border-input bg-surface px-3 text-base"
                placeholder="Full name"
              />
              <input
                aria-label="Phone"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="min-h-[44px] rounded-md border border-input bg-surface px-3 text-base"
                placeholder="Phone (optional)"
              />
            </div>
          ) : (
            <>
              <p className="font-medium">
                {user.profile.full_name}
                {isSelf && <span className="ml-2 console-label">You</span>}
              </p>
              <p className="text-sm text-muted-foreground">
                {user.profile.email}
                {user.profile.phone && ` · ${user.profile.phone}`}
              </p>
            </>
          )}
        </div>

        <div className="flex shrink-0 gap-2">
          {isEditing ? (
            <>
              <Button size="sm" onClick={() => void save()} isLoading={updateProfile.isPending}>
                <Check className="h-4 w-4" aria-hidden="true" />
                Save
              </Button>
              <Button size="sm" variant="ghost" onClick={onDone}>
                <X className="h-4 w-4" aria-hidden="true" />
                Cancel
              </Button>
            </>
          ) : (
            <Button size="sm" variant="outline" onClick={onEdit}>
              <Pencil className="h-4 w-4" aria-hidden="true" />
              Edit
            </Button>
          )}
        </div>
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        {ROLES.map(({ role, label, note }) => {
          const granted = user.roles.includes(role);
          // Removing your own admin role locks you out of this screen with no
          // way back except SQL, so it is the one toggle that is disabled.
          const wouldLockMeOut = isSelf && role === 'admin' && granted;
          return (
            <button
              key={role}
              type="button"
              disabled={wouldLockMeOut || setRole.isPending}
              onClick={() => void toggleRole(role, !granted)}
              title={wouldLockMeOut ? 'You cannot remove your own admin role' : note}
              className={cn(
                'inline-flex min-h-[36px] items-center gap-2 rounded-full border px-3 text-sm font-medium',
                'transition-colors duration-150 disabled:cursor-not-allowed disabled:opacity-50',
                granted
                  ? 'border-accent/40 bg-accent/15 text-accent'
                  : 'border-white/12 text-muted-foreground hover:bg-white/[0.06] hover:text-foreground',
              )}
            >
              {granted && <Check className="h-3.5 w-3.5" aria-hidden="true" />}
              {label}
            </button>
          );
        })}

        <span className="flex-1" />

        {!isSelf && (
          <Button
            size="sm"
            variant={isInactive ? 'outline' : 'ghost'}
            onClick={() =>
              void setStatus.mutateAsync({
                userId: user.profile.id,
                status: isInactive ? 'active' : 'inactive',
              })
            }
            isLoading={setStatus.isPending}
          >
            {isInactive ? 'Reinstate' : 'Deactivate'}
          </Button>
        )}
      </div>

      {user.roles.length === 0 && !isInactive && (
        <Well className="mt-3">
          <p className="text-sm text-warning">
            No role. They can sign in but will land on a &ldquo;no access&rdquo; screen until
            you give them one.
          </p>
        </Well>
      )}

      {failure && (
        <p role="alert" className="mt-3 text-sm font-medium text-danger">
          {failure}
        </p>
      )}
    </Panel>
  );
}
