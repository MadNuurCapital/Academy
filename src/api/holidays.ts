import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import type { IsoDate } from '@/lib/workingDays';

/**
 * Public holidays.
 *
 * The whole programme is counted in working days, and this table is the only
 * thing that stops Chinese New Year being treated as two ordinary training days
 * on which an advisor was absent. Admins maintain it; everyone reads it.
 */

export interface PublicHoliday {
  id: string;
  holiday_date: IsoDate;
  name: string;
}

export function useHolidays() {
  return useQuery({
    queryKey: ['holidays-admin'],
    queryFn: async (): Promise<PublicHoliday[]> => {
      const { data, error } = await supabase
        .from('public_holidays')
        .select('id, holiday_date, name')
        .order('holiday_date');
      if (error) throw new Error(error.message);
      return (data ?? []) as PublicHoliday[];
    },
  });
}

function useHolidayMutation<TInput>(
  run: (input: TInput) => PromiseLike<{ error: { message: string; code?: string } | null }>,
) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: TInput) => {
      const { error } = await run(input);
      if (error) {
        // 23505 is the unique violation on holiday_date. The raw message names
        // the constraint, which tells an administrator nothing.
        if (error.code === '23505') {
          throw new Error('That date is already in the list.');
        }
        throw new Error(error.message);
      }
    },
    onSuccess: () => {
      // Everything that counts a working day depends on this list.
      for (const key of ['holidays-admin', 'public-holidays', 'roadmap', 'progress']) {
        void queryClient.invalidateQueries({ queryKey: [key] });
      }
    },
  });
}

export function useAddHoliday() {
  return useHolidayMutation<{ date: IsoDate; name: string }>((input) =>
    supabase.from('public_holidays').insert({
      holiday_date: input.date,
      name: input.name.trim(),
    }),
  );
}

export function useDeleteHoliday() {
  return useHolidayMutation<{ id: string }>((input) =>
    supabase.from('public_holidays').delete().eq('id', input.id),
  );
}
