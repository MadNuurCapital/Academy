import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import type { AppRole, Profile } from '@/types/database';

/**
 * User and role administration.
 *
 * Every operation here was already permitted by the database — `profiles:
 * admins update any` and `user_roles: admins manage` have existed since the
 * first migration. What was missing was a screen, so the work was being done by
 * hand in the SQL editor.
 *
 * Creating an account is deliberately absent. That requires the service-role
 * key, which bypasses every policy in the system and must never reach a
 * browser, so new accounts still start in the Supabase dashboard.
 */

export interface UserWithRoles {
  profile: Profile;
  roles: AppRole[];
}

export function useUsers() {
  return useQuery({
    queryKey: ['admin-users'],
    queryFn: async (): Promise<UserWithRoles[]> => {
      const [profileResult, roleResult] = await Promise.all([
        supabase.from('profiles').select('*').order('full_name'),
        supabase.from('user_roles').select('user_id, role'),
      ]);
      if (profileResult.error) throw new Error(profileResult.error.message);
      if (roleResult.error) throw new Error(roleResult.error.message);

      const rolesByUser = new Map<string, AppRole[]>();
      for (const row of (roleResult.data ?? []) as { user_id: string; role: AppRole }[]) {
        rolesByUser.set(row.user_id, [...(rolesByUser.get(row.user_id) ?? []), row.role]);
      }

      return ((profileResult.data ?? []) as Profile[]).map((profile) => ({
        profile,
        roles: rolesByUser.get(profile.id) ?? [],
      }));
    },
  });
}

/** Rename someone, or correct the phone number. */
export function useUpdateProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: { userId: string; fullName: string; phone: string | null }) => {
      const { error } = await supabase
        .from('profiles')
        .update({ full_name: input.fullName.trim(), phone: input.phone?.trim() || null })
        .eq('id', input.userId);
      if (error) throw new Error(error.message);
    },
    onSuccess: () => invalidate(queryClient),
  });
}

/**
 * Grant or revoke a role.
 *
 * Roles are additive rather than exclusive — one person can be both manager and
 * advisor, which is why this toggles a single role rather than setting one.
 */
export function useSetRole() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: { userId: string; role: AppRole; granted: boolean }) => {
      if (input.granted) {
        const { error } = await supabase
          .from('user_roles')
          .upsert({ user_id: input.userId, role: input.role }, { onConflict: 'user_id,role' });
        if (error) throw new Error(error.message);
      } else {
        const { error } = await supabase
          .from('user_roles')
          .delete()
          .eq('user_id', input.userId)
          .eq('role', input.role);
        if (error) throw new Error(error.message);
      }
    },
    onSuccess: () => invalidate(queryClient),
  });
}

/**
 * Deactivate or reinstate.
 *
 * There is no delete. A departed advisor's attendance, scores and readiness
 * decision are part of the record, and the schema has no DELETE policy on
 * profiles for exactly that reason.
 */
export function useSetProfileStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: { userId: string; status: 'active' | 'inactive' }) => {
      const { error } = await supabase
        .from('profiles')
        .update({ status: input.status })
        .eq('id', input.userId);
      if (error) throw new Error(error.message);
    },
    onSuccess: () => invalidate(queryClient),
  });
}

function invalidate(queryClient: ReturnType<typeof useQueryClient>) {
  void queryClient.invalidateQueries({ queryKey: ['admin-users'] });
  void queryClient.invalidateQueries({ queryKey: ['all-advisors'] });
}
