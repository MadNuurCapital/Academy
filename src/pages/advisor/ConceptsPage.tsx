import { BookOpen } from 'lucide-react';
import { useConceptPresentations } from '@/api/practical';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';

/**
 * Concept presentations.
 *
 * Every diagram here is original artwork authored for ATLAS. Nothing
 * reproduces a copyrighted diagram from another organisation's training
 * material, which is why the SVG is stored as content rather than linked from
 * elsewhere.
 */
export function ConceptsPage() {
  const { data: concepts, isLoading } = useConceptPresentations();

  if (isLoading) return <LoadingState label="Loading concept presentations…" />;

  if (!concepts || concepts.length === 0) {
    return (
      <div className="space-y-6">
        <h1>Concept presentations</h1>
        <EmptyState
          icon={BookOpen}
          title="No concepts published yet"
          description="Concept presentations appear here once your administrator publishes them."
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1>Concept presentations</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Structured ways to explain financial planning to a client.
        </p>
      </div>

      {concepts.map((concept) => (
        <Card key={concept.id}>
          <CardHeader>
            <CardTitle>
              {concept.name}
              {!concept.is_required && (
                <span className="ml-2 rounded-full border border-border bg-muted px-2 py-0.5 text-xs font-normal text-muted-foreground">
                  Optional
                </span>
              )}
            </CardTitle>
          </CardHeader>
          <CardBody className="space-y-4">
            <p className="text-sm">{concept.purpose}</p>

            {concept.diagram_svg && (
              <div
                className="overflow-x-auto rounded-md border border-border bg-surface p-4"
                /*
                  The SVG is authored by an administrator inside ATLAS, not
                  supplied by an advisor, and the content tables are writable
                  only by managers and admins.
                */
                dangerouslySetInnerHTML={{ __html: concept.diagram_svg }}
              />
            )}

            {concept.steps.length > 0 && (
              <div>
                <p className="text-sm font-medium">How to present it</p>
                <ol className="mt-1 space-y-1 text-sm text-muted-foreground">
                  {concept.steps.map((step, index) => (
                    <li key={index}>
                      {index + 1}. {step}
                    </li>
                  ))}
                </ol>
              </div>
            )}

            {concept.discovery_questions.length > 0 && (
              <div>
                <p className="text-sm font-medium">Questions to ask</p>
                <ul className="mt-1 space-y-1 text-sm text-muted-foreground">
                  {concept.discovery_questions.map((question, index) => (
                    <li key={index}>• {question}</li>
                  ))}
                </ul>
              </div>
            )}

            {concept.when_not_to_use && (
              <div>
                <p className="text-sm font-medium text-warning">When not to use it</p>
                <p className="mt-1 text-sm text-muted-foreground">{concept.when_not_to_use}</p>
              </div>
            )}
          </CardBody>
        </Card>
      ))}
    </div>
  );
}
