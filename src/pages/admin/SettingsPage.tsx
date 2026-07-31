import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { ErrorState, LoadingState } from '@/components/ui/States';
import type { AppSetting } from '@/types/database';

/**
 * Every configurable threshold, editable without a deployment.
 *
 * This screen is why the specification insists nothing is hard-coded: the pass
 * mark, the attendance target, the drift bands and the office start time all
 * live in one table, and the server-side progression functions read the same
 * rows. Changing a value here changes behaviour immediately and everywhere.
 */
export function SettingsPage() {
  const queryClient = useQueryClient();
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [savedKey, setSavedKey] = useState<string | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-settings'],
    queryFn: async (): Promise<AppSetting[]> => {
      const { data: rows, error: queryError } = await supabase
        .from('app_settings')
        .select('*')
        .order('key');
      if (queryError) throw new Error(queryError.message);
      return (rows ?? []) as AppSetting[];
    },
  });

  const save = useMutation({
    mutationFn: async (input: { key: string; value: string }) => {
      // Values are jsonb. A bare number or boolean must be stored as such, not
      // as a quoted string, or the server-side casts in the progression
      // functions will fail at the worst possible moment.
      let parsed: unknown;
      try {
        parsed = JSON.parse(input.value);
      } catch {
        throw new Error(
          'That is not valid JSON. Use 80 for a number, true or false for a switch, ' +
            'and "10:00" with quotes for a time.',
        );
      }

      const { error: updateError } = await supabase
        .from('app_settings')
        .update({ value: parsed })
        .eq('key', input.key);
      if (updateError) throw new Error(updateError.message);
    },
    onSuccess: (_result, variables) => {
      setSavedKey(variables.key);
      setSaveError(null);
      void queryClient.invalidateQueries({ queryKey: ['admin-settings'] });
      void queryClient.invalidateQueries({ queryKey: ['app-settings'] });
    },
    onError: (mutationError) => {
      setSavedKey(null);
      setSaveError(mutationError instanceof Error ? mutationError.message : 'Could not save.');
    },
  });

  if (isLoading) return <LoadingState label="Loading settings…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load settings"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1>Settings</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          These values take effect immediately, for advisors already part-way through the programme
          as well as new ones.
        </p>
      </div>

      {saveError && (
        <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
          {saveError}
        </p>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Programme configuration</CardTitle>
        </CardHeader>
        <CardBody className="p-0">
          <ul className="divide-y divide-border">
            {(data ?? []).map((setting) => {
              const currentValue = JSON.stringify(setting.value);
              const draft = drafts[setting.key] ?? currentValue;
              const isDirty = draft !== currentValue;

              return (
                <li key={setting.key} className="space-y-2 px-5 py-4">
                  <div>
                    <label htmlFor={`setting-${setting.key}`} className="block text-sm font-medium">
                      {setting.key}
                    </label>
                    <p className="text-sm text-muted-foreground">{setting.description}</p>
                  </div>
                  <div className="flex flex-col gap-2 sm:flex-row">
                    <input
                      id={`setting-${setting.key}`}
                      value={draft}
                      onChange={(event) =>
                        setDrafts((previous) => ({ ...previous, [setting.key]: event.target.value }))
                      }
                      className="min-h-[44px] flex-1 rounded-md border border-input bg-surface px-3 py-2 font-mono text-sm"
                    />
                    <Button
                      size="sm"
                      variant={isDirty ? 'accent' : 'outline'}
                      disabled={!isDirty}
                      isLoading={save.isPending && save.variables?.key === setting.key}
                      onClick={() => save.mutate({ key: setting.key, value: draft })}
                    >
                      Save
                    </Button>
                  </div>
                  {savedKey === setting.key && (
                    <p role="status" className="text-sm font-medium text-success">
                      Saved.
                    </p>
                  )}
                </li>
              );
            })}
          </ul>
        </CardBody>
      </Card>
    </div>
  );
}
