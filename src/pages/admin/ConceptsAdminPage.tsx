import { useState } from 'react';
import { CheckCircle2, ChevronDown, ChevronRight } from 'lucide-react';
import { useAllConcepts, useSetConceptStatus, useUpdateConcept } from '@/api/authoring';
import { Panel, Well } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { Field, ListEditor, SaveRow, StatusLabel } from '@/components/admin/Editor';
import { useDraft } from '@/components/admin/editorState';
import type { ConceptPresentation } from '@/types/database';

/**
 * Concept presentations, from the author's side.
 *
 * Two of the four are required and two are optional; the optional ones never
 * block completion, which is why that flag is editable here rather than buried
 * in the database.
 */
export function ConceptsAdminPage() {
  const { data: concepts, isLoading, error, refetch } = useAllConcepts();
  const [openId, setOpenId] = useState<string | null>(null);

  if (isLoading) return <LoadingState label="Loading the concept presentations…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load the concept presentations"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!concepts || concepts.length === 0) {
    return (
      <div className="space-y-6">
        <h1>Concepts</h1>
        <EmptyState
          title="No concept presentations loaded"
          description="Run bundle 03 from supabase/browser/ in the Supabase SQL Editor."
        />
      </div>
    );
  }

  const published = concepts.filter((concept) => concept.status === 'published').length;

  return (
    <div className="space-y-5">
      <div>
        <h1>Concepts</h1>
        <p className="mt-1 text-sm text-muted-foreground tabular">
          {published} of {concepts.length} published
        </p>
      </div>

      <Panel className="p-4">
        <p className="text-sm text-muted-foreground">
          Each presentation is a way of explaining an idea at a client's kitchen table. The
          diagrams are original artwork drawn for ATLAS — nothing here reproduces another
          organisation's training material.
        </p>
      </Panel>

      {concepts.map((concept) => (
        <ConceptRow
          key={concept.id}
          concept={concept}
          isOpen={openId === concept.id}
          onToggle={() => setOpenId((current) => (current === concept.id ? null : concept.id))}
        />
      ))}
    </div>
  );
}

function ConceptRow({
  concept,
  isOpen,
  onToggle,
}: {
  concept: ConceptPresentation;
  isOpen: boolean;
  onToggle: () => void;
}) {
  const update = useUpdateConcept();
  const setStatus = useSetConceptStatus();
  const { draft, set, dirty, saved, markSaved } = useDraft(concept);
  const isPublished = concept.status === 'published';

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
            <span className="block text-sm font-medium">{concept.name}</span>
            <span className="mt-0.5 flex flex-wrap items-center gap-2">
              <StatusLabel status={concept.status} />
              <span className="console-label">{concept.is_required ? 'Required' : 'Optional'}</span>
            </span>
          </span>
        </button>

        <Button
          size="sm"
          variant={isPublished ? 'ghost' : 'primary'}
          isLoading={setStatus.isPending}
          onClick={() =>
            void setStatus.mutateAsync({
              conceptId: concept.id,
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
            id={`concept-name-${concept.id}`}
            label="Name"
            singleLine
            value={draft.name}
            onChange={(next) => set('name', next)}
          />
          <Field
            id={`concept-purpose-${concept.id}`}
            label="Purpose"
            hint="(what this presentation is for)"
            value={draft.purpose}
            onChange={(next) => set('purpose', next)}
          />
          <Field
            id={`concept-suitable-${concept.id}`}
            label="Suitable situations"
            value={draft.suitable_situations ?? ''}
            onChange={(next) => set('suitable_situations', next || null)}
          />
          <Field
            id={`concept-not-${concept.id}`}
            label="When not to use it"
            hint="(as important as when to)"
            value={draft.when_not_to_use ?? ''}
            onChange={(next) => set('when_not_to_use', next || null)}
          />

          <ListEditor
            label="Steps"
            hint="(in the order an advisor works through them)"
            items={draft.steps}
            onChange={(next) => set('steps', next)}
            addLabel="Add a step"
          />
          <ListEditor
            label="Discovery questions"
            items={draft.discovery_questions}
            onChange={(next) => set('discovery_questions', next)}
            addLabel="Add a question"
          />
          <ListEditor
            label="Common mistakes"
            items={draft.common_mistakes}
            onChange={(next) => set('common_mistakes', next)}
            addLabel="Add a common mistake"
          />

          <Field
            id={`concept-transition-${concept.id}`}
            label="Transition"
            hint="(how the conversation moves on afterwards)"
            value={draft.transition ?? ''}
            onChange={(next) => set('transition', next || null)}
          />
          <Field
            id={`concept-compliance-${concept.id}`}
            label="Compliance note"
            value={draft.compliance_note ?? ''}
            onChange={(next) => set('compliance_note', next || null)}
          />

          <div className="flex items-start gap-3">
            <input
              id={`concept-required-${concept.id}`}
              type="checkbox"
              checked={draft.is_required}
              onChange={(event) => set('is_required', event.target.checked)}
              className="mt-1 h-5 w-5 shrink-0 rounded border-input"
            />
            <label htmlFor={`concept-required-${concept.id}`} className="text-sm">
              <span className="font-medium">Required</span>
              <span className="mt-0.5 block text-muted-foreground">
                A required presentation must be practised before an advisor's readiness review.
                An optional one is offered but never blocks completion.
              </span>
            </label>
          </div>

          {draft.diagram_svg && (
            <Well>
              <p className="console-label">Diagram</p>
              <div
                className="mt-2 max-w-md text-foreground [&_svg]:h-auto [&_svg]:w-full"
                // The artwork is authored in this repository and loaded by the seed
                // files as the database owner. It is not user-supplied content and
                // there is no path by which an advisor can write to this column.
                dangerouslySetInnerHTML={{ __html: draft.diagram_svg }}
              />
              <p className="mt-2 text-xs text-muted-foreground">
                Diagrams are edited in the repository rather than here — they are drawings, not
                prose, and a text box is the wrong tool for one.
              </p>
            </Well>
          )}

          <SaveRow
            dirty={dirty}
            saved={saved}
            pending={update.isPending}
            error={update.error}
            onSave={async () => {
              await update.mutateAsync({
                conceptId: concept.id,
                changes: {
                  name: draft.name.trim(),
                  purpose: draft.purpose.trim(),
                  suitable_situations: draft.suitable_situations?.trim() || null,
                  when_not_to_use: draft.when_not_to_use?.trim() || null,
                  steps: draft.steps.filter((item) => item.trim()),
                  discovery_questions: draft.discovery_questions.filter((item) => item.trim()),
                  common_mistakes: draft.common_mistakes.filter((item) => item.trim()),
                  transition: draft.transition?.trim() || null,
                  compliance_note: draft.compliance_note?.trim() || null,
                  is_required: draft.is_required,
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
