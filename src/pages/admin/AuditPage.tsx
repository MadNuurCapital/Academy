import { useState } from 'react';
import { useAuditLog, type AuditEntry } from '@/api/audit';
import { useUsers } from '@/api/users';
import { Panel } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import { EmptyState, ErrorState, LoadingState } from '@/components/ui/States';
import { inputClass } from '@/components/admin/editorState';
import { cn } from '@/lib/cn';

/**
 * The audit log.
 *
 * Read-only, because the table is append-only: managers may insert, admins may
 * read, nobody may update or delete. There is deliberately no export button and
 * no way to clear it — a record that can be tidied up is not a record.
 */
export function AuditPage() {
  const [actorId, setActorId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [limit, setLimit] = useState(100);

  const { data: users } = useUsers();
  const { data: entries, isLoading, error, refetch } = useAuditLog({
    actorId: actorId || undefined,
    from: from || undefined,
    to: to || undefined,
    limit,
  });

  const hasFilters = Boolean(actorId || from || to);
  const namesById = new Map((users ?? []).map(({ profile }) => [profile.id, profile.full_name]));

  return (
    <div className="space-y-5">
      <div>
        <h1>Audit log</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Attendance corrections, manager overrides, quiz resets, publishing and readiness
          decisions.
        </p>
      </div>

      <Panel className="space-y-3 p-4">
        <div className="grid gap-3 sm:grid-cols-3">
          <div className="space-y-1.5">
            <label htmlFor="audit-actor" className="block text-sm font-medium">
              Person
            </label>
            <select
              id="audit-actor"
              value={actorId}
              onChange={(event) => setActorId(event.target.value)}
              className={inputClass}
            >
              <option value="">Anyone</option>
              {(users ?? []).map(({ profile }) => (
                <option key={profile.id} value={profile.id}>
                  {profile.full_name}
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-1.5">
            <label htmlFor="audit-from" className="block text-sm font-medium">
              From
            </label>
            <input
              id="audit-from"
              type="date"
              value={from}
              onChange={(event) => setFrom(event.target.value)}
              className={cn(inputClass, 'tabular')}
            />
          </div>

          <div className="space-y-1.5">
            <label htmlFor="audit-to" className="block text-sm font-medium">
              To
            </label>
            <input
              id="audit-to"
              type="date"
              value={to}
              onChange={(event) => setTo(event.target.value)}
              className={cn(inputClass, 'tabular')}
            />
          </div>
        </div>

        {hasFilters && (
          <Button
            size="sm"
            variant="ghost"
            onClick={() => {
              setActorId('');
              setFrom('');
              setTo('');
            }}
          >
            Clear the filters
          </Button>
        )}
      </Panel>

      {isLoading && <LoadingState label="Loading the audit log…" />}

      {error && (
        <ErrorState
          title="We could not load the audit log"
          description={error instanceof Error ? error.message : undefined}
          onRetry={() => void refetch()}
        />
      )}

      {entries && entries.length === 0 && (
        <EmptyState
          title={hasFilters ? 'Nothing matches those filters' : 'Nothing recorded yet'}
          description={
            hasFilters
              ? 'Widen the dates, or clear the filters to see everything.'
              : 'Entries appear here as corrections, overrides and publishing decisions are made.'
          }
        />
      )}

      {entries && entries.length > 0 && (
        <>
          <ul className="space-y-2">
            {entries.map((entry) => (
              <AuditRow
                key={entry.id}
                entry={entry}
                actorName={entry.actor_id ? namesById.get(entry.actor_id) : undefined}
              />
            ))}
          </ul>

          {entries.length === limit && (
            <Button variant="outline" onClick={() => setLimit((current) => current + 100)}>
              Show older entries
            </Button>
          )}
        </>
      )}
    </div>
  );
}

/**
 * Plain English for the actions the application writes.
 *
 * An action not listed here falls back to its own name with the underscores
 * removed, which stays readable rather than blank — a new action added by a
 * later migration should not make this screen look broken.
 */
const ACTION_LABELS: Record<string, string> = {
  enrol_advisor: 'Enrolled an advisor',
  pause_enrolment: 'Paused an enrolment',
  resume_enrolment: 'Resumed an enrolment',
  withdraw_enrolment: 'Withdrew an enrolment',
  manager_unlock_day: 'Unlocked a day early',
  reset_quiz_attempts: 'Reset an advisor’s quiz attempts',
  resolve_makeup_task: 'Resolved a make-up task',
  record_readiness_decision: 'Recorded a readiness decision',
  set_module_status: 'Changed a module’s status',
  set_script_status: 'Changed a script’s status',
  set_concept_status: 'Changed a concept presentation’s status',
  create_quiz_question: 'Added a quiz question',
  update_quiz_question: 'Edited a quiz question',
  delete_quiz_question: 'Deleted a quiz question',
};

/**
 * An action added by a later migration and not listed above still reads as a
 * sentence rather than as a column name, so this screen ages without looking
 * broken.
 */
function describe(action: string): string {
  const known = ACTION_LABELS[action];
  if (known) return known;
  const words = action.replace(/_/g, ' ');
  return words.charAt(0).toUpperCase() + words.slice(1);
}

function formatTimestamp(value: string): string {
  const date = new Date(value);
  return date.toLocaleString('en-SG', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
}

function AuditRow({ entry, actorName }: { entry: AuditEntry; actorName?: string }) {
  const [showDetail, setShowDetail] = useState(false);
  const hasDetail = Boolean(entry.before || entry.after);

  return (
    <li>
      <Panel className="p-3">
        <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
          <p className="text-sm font-medium">{describe(entry.action)}</p>
          <p className="tabular text-xs text-muted-foreground">
            {formatTimestamp(entry.created_at)}
          </p>
          <span className="console-label text-[10px]">{entry.entity_type}</span>
        </div>

        <p className="mt-1 text-sm text-muted-foreground">
          {actorName ?? (entry.actor_id ? 'Someone whose account has since been removed' : 'The system')}
        </p>

        {entry.reason && (
          <p className="mt-2 text-sm">
            <span className="console-label">Reason</span>{' '}
            <span className="text-foreground">{entry.reason}</span>
          </p>
        )}

        {hasDetail && (
          <>
            <button
              type="button"
              onClick={() => setShowDetail((open) => !open)}
              aria-expanded={showDetail}
              className="mt-2 text-xs font-medium text-accent hover:underline"
            >
              {showDetail ? 'Hide what changed' : 'Show what changed'}
            </button>

            {showDetail && (
              <div className="mt-2 grid gap-2 sm:grid-cols-2">
                <DetailBlock label="Before" value={entry.before} />
                <DetailBlock label="After" value={entry.after} />
              </div>
            )}
          </>
        )}
      </Panel>
    </li>
  );
}

function DetailBlock({ label, value }: { label: string; value: unknown }) {
  if (value === null || value === undefined) return null;
  return (
    <div className="rounded-md border border-white/[0.06] bg-panel/60 p-2.5">
      <p className="console-label">{label}</p>
      <dl className="mt-1 space-y-1">
        {Object.entries(value as Record<string, unknown>).map(([key, item]) => (
          <div key={key} className="flex flex-wrap gap-x-2 text-sm">
            <dt className="text-muted-foreground">{key.replace(/_/g, ' ')}</dt>
            <dd className="min-w-0 break-words">{String(item)}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}
