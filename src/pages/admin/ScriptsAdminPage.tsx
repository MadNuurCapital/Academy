import { useState } from 'react';
import { CheckCircle2, ChevronDown, ChevronRight } from 'lucide-react';
import {
  useAllScripts,
  useSetScriptStatus,
  useUpdateScript,
} from '@/api/authoring';
import { Panel, Well } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { Field, ListEditor, SaveRow, StatusLabel } from '@/components/admin/Editor';
import { useDraft } from '@/components/admin/editorState';
import type { Script } from '@/types/database';

/**
 * The script library, from the author's side.
 *
 * These are the words a new advisor will say to a member of the public, so this
 * screen exists to be read carefully rather than filled in quickly. Each script
 * opens in place; nothing is published until someone has read it.
 */
export function ScriptsAdminPage() {
  const { data: scripts, isLoading, error, refetch } = useAllScripts();
  const [openId, setOpenId] = useState<string | null>(null);

  if (isLoading) return <LoadingState label="Loading the scripts…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load the scripts"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!scripts || scripts.length === 0) {
    return (
      <div className="space-y-6">
        <h1>Scripts</h1>
        <EmptyState
          title="No scripts loaded"
          description="Run bundle 03 from supabase/browser/ in the Supabase SQL Editor."
        />
      </div>
    );
  }

  const published = scripts.filter((script) => script.status === 'published').length;

  return (
    <div className="space-y-5">
      <div>
        <h1>Scripts</h1>
        <p className="mt-1 text-sm text-muted-foreground tabular">
          {published} of {scripts.length} published
        </p>
      </div>

      <Panel className="p-4">
        <p className="text-sm text-muted-foreground">
          Advisors are taught the structure and the purpose of each script. Reading one aloud
          word for word is explicitly not the goal, and the wording here should read as
          something a person would actually say.
        </p>
      </Panel>

      {scripts.map((script) => (
        <ScriptRow
          key={script.id}
          script={script}
          isOpen={openId === script.id}
          onToggle={() => setOpenId((current) => (current === script.id ? null : script.id))}
        />
      ))}
    </div>
  );
}

function ScriptRow({
  script,
  isOpen,
  onToggle,
}: {
  script: Script;
  isOpen: boolean;
  onToggle: () => void;
}) {
  const update = useUpdateScript();
  const setStatus = useSetScriptStatus();
  const { draft, set, dirty, saved, markSaved } = useDraft(script);
  const isPublished = script.status === 'published';

  return (
    <Panel className="p-4">
      <div className="flex flex-wrap items-center gap-2">
        <button
          type="button"
          onClick={onToggle}
          aria-expanded={isOpen}
          className="flex min-h-[44px] min-w-0 flex-1 items-center gap-2 rounded-md px-1 text-left transition-colors hover:bg-white/[0.04]"
        >
          {isOpen ? (
            <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
          ) : (
            <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
          )}
          <span className="min-w-0">
            <span className="block text-sm font-medium">{script.title}</span>
            <span className="mt-0.5 block">
              <StatusLabel status={script.status} />
            </span>
          </span>
        </button>

        <Button
          size="sm"
          variant={isPublished ? 'ghost' : 'primary'}
          isLoading={setStatus.isPending}
          onClick={() =>
            void setStatus.mutateAsync({
              scriptId: script.id,
              status: isPublished ? 'draft' : 'published',
            })
          }
        >
          {isPublished ? (
            'Unpublish'
          ) : (
            <>
              <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
              Publish
            </>
          )}
        </Button>
      </div>

      {isOpen && (
        <div className="mt-4 space-y-4 border-t border-white/[0.07] pt-4">
          <Field
            id={`script-title-${script.id}`}
            label="Title"
            singleLine
            value={draft.title}
            onChange={(next) => set('title', next)}
          />
          <Field
            id={`script-situation-${script.id}`}
            label="Situation"
            hint="(when an advisor would use this)"
            value={draft.situation}
            onChange={(next) => set('situation', next)}
          />
          <Field
            id={`script-objective-${script.id}`}
            label="Objective"
            hint="(what the conversation is for)"
            value={draft.objective}
            onChange={(next) => set('objective', next)}
          />
          <Field
            id={`script-wording-${script.id}`}
            label="Wording"
            hint="(the script itself)"
            value={draft.wording}
            onChange={(next) => set('wording', next)}
            className="font-mono text-sm leading-relaxed"
          />

          <ListEditor
            label="Talking points"
            items={draft.talking_points}
            onChange={(next) => set('talking_points', next)}
            addLabel="Add a talking point"
          />
          <ListEditor
            label="Variations"
            hint="(how it changes by situation)"
            items={draft.variations}
            onChange={(next) => set('variations', next)}
            addLabel="Add a variation"
          />
          <ListEditor
            label="Common mistakes"
            items={draft.common_mistakes}
            onChange={(next) => set('common_mistakes', next)}
            addLabel="Add a common mistake"
          />

          <Field
            id={`script-compliance-${script.id}`}
            label="Compliance note"
            hint="(shown to the advisor alongside the script)"
            value={draft.compliance_note ?? ''}
            onChange={(next) => set('compliance_note', next || null)}
          />

          <Well>
            <p className="text-sm text-muted-foreground">
              Publishing records the date this wording was cleared. Returning a script to
              draft hides it from advisors but leaves that date alone — it is a fact about a
              past approval, not a claim about today.
            </p>
          </Well>

          <SaveRow
            dirty={dirty}
            saved={saved}
            pending={update.isPending}
            error={update.error}
            onSave={async () => {
              await update.mutateAsync({
                scriptId: script.id,
                changes: {
                  title: draft.title.trim(),
                  situation: draft.situation.trim(),
                  objective: draft.objective.trim(),
                  wording: draft.wording,
                  talking_points: draft.talking_points.filter((item) => item.trim()),
                  variations: draft.variations.filter((item) => item.trim()),
                  common_mistakes: draft.common_mistakes.filter((item) => item.trim()),
                  compliance_note: draft.compliance_note?.trim() || null,
                },
              });
              markSaved();
            }}
          />
        </div>
      )}

      {setStatus.isError && (
        <p role="alert" className="mt-2 text-sm font-medium text-danger">
          {setStatus.error instanceof Error ? setStatus.error.message : 'We could not change that.'}
        </p>
      )}
    </Panel>
  );
}
