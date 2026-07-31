import { useNavigate } from 'react-router-dom';
import { ShieldAlert } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { Button } from '@/components/ui/Button';

export function NoAccessPage() {
  const { profile, roles, signOut } = useAuth();
  const navigate = useNavigate();

  async function handleSignOut() {
    await signOut();
    navigate('/login', { replace: true });
  }

  const hasNoRole = roles.length === 0;

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="w-full max-w-md rounded-lg border border-border bg-surface p-6 text-center shadow-sm">
        <ShieldAlert className="mx-auto h-8 w-8 text-warning" aria-hidden="true" />
        <h1 className="mt-4 text-xl font-semibold">
          {hasNoRole ? 'Your account is not set up yet' : 'You do not have access to that page'}
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          {hasNoRole
            ? 'Your sign-in worked, but no role has been assigned to your account yet. An administrator needs to finish setting you up.'
            : 'That page is restricted to a different role. If you believe this is wrong, speak to your manager.'}
        </p>
        {profile && (
          <p className="mt-4 text-xs text-muted-foreground">
            Signed in as {profile.email}
            {roles.length > 0 && ` · ${roles.join(', ')}`}
          </p>
        )}
        <div className="mt-6 flex flex-col gap-2">
          {!hasNoRole && (
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
