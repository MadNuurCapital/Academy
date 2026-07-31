import { useState } from 'react';
import { Briefcase } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { useFieldwork, useSubmitReflection } from '@/api/practical';
import { Button } from '@/components/ui/Button';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { formatLongDate } from '@/lib/formatDate';

const ROLE_LABELS: Record<string, string> = {
  observe: 'Observed',
  assist: 'Assisted',
  present_section: 'Presented a section',
  lead_supervised: 'Led with supervision',
};

/**
 * The advisor's joint fieldwork record.
 *
 * The reflection is the one field on this record the advisor writes. Their
 * manager's assessment of them is not editable from this side — RLS allows the
 * update but the manager's fields are not exposed here, and a fieldwork record
 * is meant to hold two independent accounts of the same appointment.
 */
export function FieldworkPage() {
  const { session } = useAuth();
  const { data: records, isLoading } = useFieldwork(session?.user.id);
  const submitReflection = useSubmitReflection();
  const [drafts, setDrafts] = useState<Record<string, string>>({});

  if (isLoading) return <LoadingState label="Loading your fieldwork…" />;

  if (!records || records.length === 0) {
    return (
      <div className="space-y-6">
        <h1>Joint fieldwork</h1>
        <EmptyState
          icon={Briefcase}
          title="No fieldwork recorded yet"
          description="Your manager records these after a joint appointment or an approved simulation."
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1>Joint fieldwork</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Appointments you attended with your manager.
        </p>
      </div>

      {records.map((record) => (
        <Card key={record.id}>
          <CardBody className="space-y-3">
            <div className="flex flex-wrap items-start justify-between gap-2">
              <div>
                <p className="font-medium">{record.appointment_category}</p>
                <p className="text-xs text-muted-foreground">
                  {formatLongDate(record.session_date)} ·{' '}
                  {ROLE_LABELS[record.advisor_role] ?? record.advisor_role}
                  {record.is_simulated && ' · simulated'}
                </p>
              </div>
              {record.rating && (
                <span className="text-sm font-semibold">{record.rating} / 5</span>
              )}
            </div>

            {record.strengths && (
              <div className="text-sm">
                <p className="font-medium text-success">Strengths</p>
                <p className="text-muted-foreground">{record.strengths}</p>
              </div>
            )}
            {record.improvement_areas && (
              <div className="text-sm">
                <p className="font-medium text-warning">To work on</p>
                <p className="text-muted-foreground">{record.improvement_areas}</p>
              </div>
            )}
            {record.manager_comments && (
              <div className="text-sm">
                <p className="font-medium">Manager's comments</p>
                <p className="text-muted-foreground">{record.manager_comments}</p>
              </div>
            )}

            <div className="space-y-2 border-t border-border pt-3">
              <label
                htmlFor={`reflection-${record.id}`}
                className="block text-sm font-medium"
              >
                Your reflection
              </label>
              {record.advisor_reflection ? (
                <p className="whitespace-pre-wrap text-sm text-muted-foreground">
                  {record.advisor_reflection}
                </p>
              ) : (
                <>
                  <textarea
                    id={`reflection-${record.id}`}
                    rows={3}
                    value={drafts[record.id] ?? ''}
                    onChange={(event) =>
                      setDrafts((prev) => ({ ...prev, [record.id]: event.target.value }))
                    }
                    placeholder="What did you notice? What would you do differently next time?"
                    className="w-full rounded-md border border-input bg-surface px-3 py-2 text-sm"
                  />
                  <Button
                    size="sm"
                    variant="outline"
                    isLoading={submitReflection.isPending}
                    disabled={!drafts[record.id]?.trim()}
                    onClick={() =>
                      submitReflection.mutate({
                        recordId: record.id,
                        reflection: drafts[record.id]!.trim(),
                      })
                    }
                  >
                    Save reflection
                  </Button>
                </>
              )}
            </div>
          </CardBody>
        </Card>
      ))}
    </div>
  );
}
