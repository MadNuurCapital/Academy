import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';
import { AuthContext, type AuthState } from './AuthContext';
import type { AppRole, Profile } from '@/types/database';

/**
 * Authentication state for the whole application.
 *
 * The important property of this provider is `isResolving`. Until Supabase has
 * finished restoring a persisted session AND the user's profile and roles have
 * loaded, no route renders. That is what stops the classic single-page
 * application failure where refreshing a protected page flashes the login
 * screen for a moment and then redirects — the router never sees an
 * "unauthenticated" state that is really just "not loaded yet".
 */

interface LoadedIdentity {
  profile: Profile | null;
  roles: AppRole[];
}

async function loadIdentity(userId: string): Promise<LoadedIdentity> {
  const [profileResult, rolesResult] = await Promise.all([
    supabase.from('profiles').select('*').eq('id', userId).maybeSingle(),
    supabase.from('user_roles').select('role').eq('user_id', userId),
  ]);

  if (profileResult.error) throw new Error(profileResult.error.message);
  if (rolesResult.error) throw new Error(rolesResult.error.message);

  return {
    profile: (profileResult.data as Profile | null) ?? null,
    roles: (rolesResult.data ?? []).map((row) => (row as { role: AppRole }).role),
  };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [roles, setRoles] = useState<AppRole[]>([]);
  const [isResolving, setIsResolving] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Guards against a slow identity fetch resolving after the user has already
  // signed out and writing stale state back in.
  const activeUserId = useRef<string | null>(null);

  const applySession = useCallback(async (nextSession: Session | null) => {
    const userId = nextSession?.user.id ?? null;
    activeUserId.current = userId;
    setSession(nextSession);

    if (!userId) {
      setProfile(null);
      setRoles([]);
      setError(null);
      setIsResolving(false);
      return;
    }

    try {
      const identity = await loadIdentity(userId);
      if (activeUserId.current !== userId) return; // superseded
      setProfile(identity.profile);
      setRoles(identity.roles);
      setError(
        identity.profile
          ? null
          : 'Your account exists but has no profile. Please contact an administrator.',
      );
    } catch (loadError) {
      if (activeUserId.current !== userId) return;
      setProfile(null);
      setRoles([]);
      setError(loadError instanceof Error ? loadError.message : 'Could not load your account.');
    } finally {
      if (activeUserId.current === userId) setIsResolving(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;

    // Restore any persisted session before the first render of the router.
    void supabase.auth.getSession().then(({ data }) => {
      if (cancelled) return;
      void applySession(data.session);
    });

    const { data: subscription } = supabase.auth.onAuthStateChange((event, nextSession) => {
      if (cancelled) return;
      // A token refresh keeps the same user; re-fetching the profile on every
      // refresh would cause a needless request roughly once an hour.
      if (event === 'TOKEN_REFRESHED' && nextSession?.user.id === activeUserId.current) {
        setSession(nextSession);
        return;
      }
      setIsResolving(true);
      void applySession(nextSession);
    });

    return () => {
      cancelled = true;
      subscription.subscription.unsubscribe();
    };
  }, [applySession]);

  const signIn = useCallback(async (email: string, password: string) => {
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });
    if (signInError) {
      // Supabase returns the same message for a wrong password and an unknown
      // address, which is the correct behaviour — it avoids confirming whether
      // an email is registered.
      return { error: 'That email address and password do not match an account.' };
    }
    return { error: null };
  }, []);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    activeUserId.current = null;
    setSession(null);
    setProfile(null);
    setRoles([]);
    setError(null);
    setIsResolving(false);
  }, []);

  const refresh = useCallback(async () => {
    const { data } = await supabase.auth.getSession();
    setIsResolving(true);
    await applySession(data.session);
  }, [applySession]);

  const value = useMemo<AuthState>(() => {
    const hasRole = (role: AppRole) => roles.includes(role);
    return {
      session,
      profile,
      roles,
      isResolving,
      error,
      hasRole,
      isAdmin: hasRole('admin'),
      isManagerOrAdmin: hasRole('admin') || hasRole('manager'),
      isAdvisor: hasRole('advisor'),
      signIn,
      signOut,
      refresh,
    };
  }, [session, profile, roles, isResolving, error, signIn, signOut, refresh]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
