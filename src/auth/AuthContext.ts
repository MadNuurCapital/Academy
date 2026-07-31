import { createContext } from 'react';
import type { Session } from '@supabase/supabase-js';
import type { AppRole, Profile } from '@/types/database';

/**
 * Kept in its own module, separate from the provider component, so that the
 * provider file exports only components and Fast Refresh keeps working during
 * development.
 */
export interface AuthState {
  session: Session | null;
  profile: Profile | null;
  roles: AppRole[];
  /** True until the session, profile and roles have all settled. */
  isResolving: boolean;
  /** Set when the profile or roles could not be loaded for a valid session. */
  error: string | null;
  hasRole: (role: AppRole) => boolean;
  isManagerOrAdmin: boolean;
  isAdmin: boolean;
  isAdvisor: boolean;
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
}

export const AuthContext = createContext<AuthState | undefined>(undefined);
