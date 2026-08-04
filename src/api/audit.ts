import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

/**
 * The audit log.
 *
 * Append-only by policy: managers may insert, admins may read, and nobody may
 * update or delete. That is what makes it worth reading — an entry here was
 * written by the action it describes and cannot have been tidied up afterwards.
 */

export interface AuditEntry {
  id: string;
  actor_id: string | null;
  entity_type: string;
  entity_id: string | null;
  action: string;
  reason: string | null;
  before: unknown;
  after: unknown;
  created_at: string;
}

export interface AuditFilters {
  actorId?: string;
  from?: string;
  to?: string;
  limit: number;
}

export function useAuditLog(filters: AuditFilters) {
  return useQuery({
    queryKey: ['audit-log', filters],
    queryFn: async (): Promise<AuditEntry[]> => {
      let query = supabase
        .from('audit_log')
        // No embedded join to profiles. The screen already loads every profile
        // for its "person" filter, so the name is looked up there — one fewer
        // thing depending on PostgREST resolving a relationship by name.
        .select('*')
        .order('created_at', { ascending: false })
        .limit(filters.limit);

      if (filters.actorId) query = query.eq('actor_id', filters.actorId);
      if (filters.from) query = query.gte('created_at', `${filters.from}T00:00:00Z`);
      // `to` is inclusive of the whole day, which is what a person picking a
      // date means by it.
      if (filters.to) query = query.lte('created_at', `${filters.to}T23:59:59Z`);

      const { data, error } = await query;
      if (error) throw new Error(error.message);
      return (data ?? []) as AuditEntry[];
    },
  });
}
