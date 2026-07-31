import { Link, useParams } from 'react-router-dom';
import { AlertCircle, ArrowLeft, FileText } from 'lucide-react';
import { useScript, useScripts } from '@/api/practical';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';

/**
 * The script library.
 *
 * Advisors learn the structure and purpose of a conversation, not a set of
 * words to recite. The reading view leads with the situation and objective for
 * that reason — an advisor who understands what a call is for can improvise
 * around the wording; one who has only memorised the wording cannot.
 */
export function ScriptsPage() {
  const { data: scripts, isLoading, error, refetch } = useScripts();

  if (isLoading) return <LoadingState label="Loading the script library…" />;

  if (error) {
    return (
      <ErrorState
        title="We could not load the scripts"
        description={error instanceof Error ? error.message : undefined}
        onRetry={() => void refetch()}
      />
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1>Script library</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Approved wording for the conversations you will have most often.
        </p>
      </div>

      {!scripts || scripts.length === 0 ? (
        <EmptyState
          icon={FileText}
          title="No scripts published yet"
          description="Your administrator has not published any scripts. They will appear here once approved."
        />
      ) : (
        <div className="space-y-2">
          {scripts.map((script) => (
            <Link key={script.id} to={`/scripts/${script.id}`} className="block">
              <Card className="transition-colors hover:border-accent/40">
                <CardBody className="py-3">
                  <p className="font-medium">{script.title}</p>
                  <p className="mt-0.5 text-sm text-muted-foreground">{script.situation}</p>
                </CardBody>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

export function ScriptDetailPage() {
  const { scriptId } = useParams<{ scriptId: string }>();
  const { data: script, isLoading, error } = useScript(scriptId);

  if (isLoading) return <LoadingState label="Loading the script…" />;

  if (error || !script) {
    return (
      <EmptyState
        title="Script not available"
        description="This script is either not published yet, or does not exist."
        action={
          <Link to="/scripts" className="text-sm font-medium text-accent hover:underline">
            Back to the script library
          </Link>
        }
      />
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <Link
          to="/scripts"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-accent hover:underline"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Script library
        </Link>
        <h1 className="mt-2">{script.title}</h1>
      </div>

      <Card>
        <CardBody className="space-y-3">
          <div>
            <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
              When to use it
            </p>
            <p className="mt-1 text-sm">{script.situation}</p>
          </div>
          <div>
            <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
              What you are trying to achieve
            </p>
            <p className="mt-1 text-sm">{script.objective}</p>
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Approved wording</CardTitle>
        </CardHeader>
        <CardBody>
          <div className="whitespace-pre-wrap text-base leading-relaxed">{script.wording}</div>
          <p className="mt-4 border-t border-border pt-3 text-sm text-muted-foreground">
            Learn the shape of this, not the sentences. Reading it aloud word for word sounds
            exactly like what it is.
          </p>
        </CardBody>
      </Card>

      {script.talking_points.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Key points to cover</CardTitle>
          </CardHeader>
          <CardBody>
            <ul className="space-y-1.5 text-sm">
              {script.talking_points.map((point, index) => (
                <li key={index} className="flex gap-2">
                  <span className="text-accent" aria-hidden="true">•</span>
                  {point}
                </li>
              ))}
            </ul>
          </CardBody>
        </Card>
      )}

      {script.common_mistakes.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Common mistakes</CardTitle>
          </CardHeader>
          <CardBody>
            <ul className="space-y-1.5 text-sm">
              {script.common_mistakes.map((mistake, index) => (
                <li key={index} className="flex gap-2">
                  <span className="text-warning" aria-hidden="true">•</span>
                  {mistake}
                </li>
              ))}
            </ul>
          </CardBody>
        </Card>
      )}

      {script.compliance_note && (
        <div className="flex items-start gap-3 rounded-md border border-warning/30 bg-warning/5 px-4 py-3">
          <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-warning" aria-hidden="true" />
          <div>
            <p className="text-sm font-medium">Compliance</p>
            <p className="mt-0.5 text-sm text-muted-foreground">{script.compliance_note}</p>
          </div>
        </div>
      )}
    </div>
  );
}
