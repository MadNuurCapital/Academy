import { useNavigate } from 'react-router-dom';
import { ShieldAlert } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { Button } from '@/components/ui/Button';

/**
 * Three different problems land here, and they need three different answers.
 *
 * The one that used to be wrong: an account with no profile row. The sign-in
 * succeeds, the session is valid, and this page said "you do not have access",
 * which sends the reader looking for a permissions problem that does not exist.
 * The account is half-created — the fix is a database repair, not a role.
 */
export function NoAccessPage() {
  const { session, profile, roles, signOut, error } = useAuth();
  const navigate = useNavigate();

  async function handleSignOut() {
    await signOut();
    navigate('/login', { replace: true });
  }

  const hasNoProfile = Boolean(session) && !profile;
  const hasNoRole = Boolean(profile) && roles.length === 0;

  const title = hasNoProfile
    ? 'Your account is missing its profile'
    : hasNoRole
      ? 'Your account is not set up yet'
      : 'You do not have access to that page';

  const body = hasNoProfile
    ? 'Your sign-in worked, but there is no profile record behind it, so nothing in the app knows who you are. This is a setup problem rather than a permissions one, and an administrator fixes it by running supabase/browser/08-repair.sql in the Supabase SQL Editor.'
    : hasNoRole
      ? 'Your sign-in worked, but no role has been assigned to your account yet. An administrator switches one on for you under Admin → Users.'
      : 'That page is restricted to a different role. If you believe this is wrong, speak to your manager.';

  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <div className="panel w-full max-w-md p-6 text-center">
        <ShieldAlert className="mx-auto h-8 w-8 text-warning" aria-hidden="true" />
        <h1 className="mt-4 text-xl font-semibold">{title}</h1>
        <p className="mt-2 text-sm text-muted-foreground">{body}</p>

        {/*
          The provider already knows what went wrong. Showing it saves an
          administrator a round of guessing, and it is the user's own account —
          nothing here is another person's data.
        */}
        {error && (
          <p className="mt-3 rounded-md bg-warning/10 px-3 py-2 text-left text-xs text-warning">
            {error}
          </p>
        )}

        <p className="mt-4 text-xs text-muted-foreground">
          {profile?.email ?? session?.user.email ?? 'Signed in'}
          {roles.length > 0 && ` · ${roles.join(', ')}`}
        </p>

        <div className="mt-6 flex flex-col gap-2">
          {!hasNoRole && !hasNoProfile && (
            <Button variant="outline" size="full" onClick={() => navigate('/')}>
              Go to my dashboard
            </Button>
          )}
          <Button variant="ghost" size="full" onClick={handleSignOut}>
            Sign out
          </Button>
        </div>
      </div>
    </div>
  );
}
