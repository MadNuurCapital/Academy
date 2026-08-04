import { useLayoutEffect, useState } from 'react';

/**
 * The non-component half of the authoring editors.
 *
 * Kept apart from Editor.tsx so that file exports only components and Fast
 * Refresh keeps working while an editor is being worked on — the same split as
 * AuthContext and AuthProvider.
 */

export const inputClass =
  'w-full rounded-md border border-input bg-surface px-3 py-2.5 text-base';

/**
 * Tracks a form against the record it came from.
 *
 * Every editor here needs the same three things: local state, a "has anything
 * changed" test, and a confirmation that survives the refetch its own save
 * triggers. Written once rather than three times.
 */
export function useDraft<T extends object>(record: T) {
  const [draft, setDraft] = useState(record);
  const [saved, setSaved] = useState(false);

  // Compared by content rather than identity: a refetch hands back an
  // equal-but-new object, and re-seeding on that would discard what is being
  // typed. `saved` is deliberately left alone, so the confirmation from our own
  // save is not flashed away by the refetch it caused.
  const signature = JSON.stringify(record);
  useLayoutEffect(() => {
    setDraft(JSON.parse(signature) as T);
  }, [signature]);

  const dirty = JSON.stringify(draft) !== signature;

  function set<K extends keyof T>(key: K, value: T[K]) {
    setDraft((current) => ({ ...current, [key]: value }));
    setSaved(false);
  }

  return { draft, set, dirty, saved, markSaved: () => setSaved(true) };
}
