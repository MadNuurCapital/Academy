import { useState } from 'react';
import { PauseCircle, PlayCircle, UserMinus } from 'lucide-react';
import {
  usePauseEnrolment,
  useResumeEnrolment,
  useWithdrawEnrolment,
} from '@/api/enrolments';
import { Panel, Well } from '@/components/ui/Panel';
import { Button } from '@/components/ui/Button';
import type { Enrolment } from '@/types/database';

/**
 * Pause, resume and withdraw.
 *
 * The schema has supported all three since the beginning and nothing could ever
 * reach them, so a manager whose advisor went on leave had no way to say so and
 * the programme kept counting working days against them.
 *
 * Every action asks for a reason before it will proceed, and withdrawal asks
 * twice. These change someone's training record, and the audit log keeps the
 * reason next to the change — an explanation written at the time is worth more
 * than one reconstructed afterwards.
 */
export function EnrolmentControls({ enrolment }: { enrolment: Enrolment }) {
  const [pending, setPending] = useState<'pause' | 'withdraw' | null>(null);
  const [reason, setReason] = useState('');
  const [failure, setFailure] = useState<string | null>(null);

  const pause = usePauseEnrolment();
  const resume = useResumeEnrolment();
  const withdraw = useWithdrawEnrolment();

  const isLive = enrolment.status === 'active' || enrolment.status === 'extended';
  const isPaused = enrolment.status === 'paused';
  const hasEnded = enrolment.status === 'completed' || enrolment.status === 'withdrawn';

  function cancel() {
    setPending(null);
    setReason('');
    setFailure(null);
  }

  async function confirm() {
    setFailure(null);
    if (!reason.trim()) {
      setFailure('A reason is required. It is recorded against the change.');
      return;
    }
    try {
      if (pending === 'pause') {
        await pause.mutateAsync({ enrolmentId: enrolment.id, reason });
      } else {
        await withdraw.mutateAsync({ enrolmentId: enrolment.id, reason });
      }
      cancel();
    } catch (e) {
      setFailure(e instanceof Error ? e.message : 'That did not work.');
    }
  }

  if (hasEnded) {
    return (
      <Panel className="p-5">
        <p className="console-label">Programme</p>
        <p className="mt-1 text-sm">
          This enrolment is <span className="font-medium capitalize">{enrolment.status}</span>.
          Nothing has been deleted — the days, attendance, scores and any readiness decision
          stay in the record.
        </p>
        {enrolment.status === 'withdrawn' && (
          <p className="mt-2 text-sm text-muted-foreground">
            To put them back on the programme, enrol them again from the Enrol screen. That
            starts a fresh 30 days rather than reopening this one.
          </p>
        )}
      </Panel>
    );
  }

  return (
    <Panel className="p-5">
      <p className="console-label">Programme</p>

      {isPaused && (
        <Well className="mt-3">
          <p className="text-sm text-warning">
            Paused. Days spent paused are not counted against their target, so their
            trajectory will not drift while they are away.
          </p>
        </Well>
      )}

      {pending ? (
        <div className="mt-4 space-y-3">
          <label htmlFor="enrolment-reason" className="block text-sm font-medium">
            {pending === 'pause'
              ? 'Why is this programme pausing?'
              : 'Why is this advisor being withdrawn?'}
          </label>
          <textarea
            id="enrolment-reason"
            value={reason}
            onChange={(event) => setReason(event.target.value)}
            rows={3}
            className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
            placeholder={
              pending === 'pause'
                ? 'On leave until the 20th'
                : 'Left the firm'
            }
          />

          {pending === 'withdraw' && (
            <p className="text-sm text-warning">
              This ends the programme without completing it. It cannot be undone from here —
              putting them back on means enrolling them again, which starts a fresh 30 days.
            </p>
          )}

          {failure && (
            <p role="alert" className="text-sm font-medium text-danger">
              {failure}
            </p>
          )}

          <div className="flex flex-wrap gap-2">
            <Button
              variant={pending === 'withdraw' ? 'danger' : 'primary'}
              onClick={() => void confirm()}
              isLoading={pause.isPending || withdraw.isPending}
            >
              {pending === 'pause' ? 'Pause programme' : 'Withdraw advisor'}
            </Button>
            <Button variant="ghost" onClick={cancel}>
              Cancel
            </Button>
          </div>
        </div>
      ) : (
        <div className="mt-4 flex flex-wrap gap-2">
          {isLive && (
            <Button variant="outline" onClick={() => setPending('pause')}>
              <PauseCircle className="h-4 w-4" aria-hidden="true" />
              Pause
            </Button>
          )}

          {isPaused && (
            <Button
              variant="primary"
              onClick={() => void resume.mutateAsync({ enrolmentId: enrolment.id })}
              isLoading={resume.isPending}
            >
              <PlayCircle className="h-4 w-4" aria-hidden="true" />
              Resume
            </Button>
          )}

          <Button variant="ghost" onClick={() => setPending('withdraw')}>
            <UserMinus className="h-4 w-4" aria-hidden="true" />
            Withdraw
          </Button>
        </div>
      )}

      {resume.isError && (
        <p role="alert" className="mt-3 text-sm font-medium text-danger">
          {resume.error instanceof Error ? resume.error.message : 'We could not resume that.'}
        </p>
      )}
    </Panel>
  );
}
