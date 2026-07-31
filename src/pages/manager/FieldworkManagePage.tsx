import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAllAdvisors, today } from '@/api/enrolments';
import { useRecordFieldwork } from '@/api/practical';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import type { AdvisorFieldworkRole } from '@/types/database';

const ROLES: { value: AdvisorFieldworkRole; label: string; description: string }[] = [
  { value: 'observe', label: 'Observed', description: 'Sat in and watched the appointment.' },
  { value: 'assist', label: 'Assisted', description: 'Took notes or supported during the meeting.' },
  { value: 'present_section', label: 'Presented a section', description: 'Delivered one part under supervision.' },
  { value: 'lead_supervised', label: 'Led with supervision', description: 'Ran the meeting with you present.' },
];

/**
 * Recording a joint fieldwork session.
 *
 * There is no field on this form for the client's name, and that is deliberate
 * rather than an omission — the table has no column for it. What is captured is
 * the category of appointment and how the advisor performed, which is all the
 * programme needs and considerably less than a training system might otherwise
 * accumulate.
 */
export function RecordFieldworkPage() {
  const navigate = useNavigate();
  const { data: advisors } = useAllAdvisors();
  const record = useRecordFieldwork();

  const [advisorId, setAdvisorId] = useState('');
  const [sessionDate, setSessionDate] = useState(today());
  const [category, setCategory] = useState('');
  const [isSimulated, setIsSimulated] = useState(false);
  const [advisorRole, setAdvisorRole] = useState<AdvisorFieldworkRole>('observe');
  const [strengths, setStrengths] = useState('');
  const [improvements, setImprovements] = useState('');
  const [comments, setComments] = useState('');
  const [rating, setRating] = useState<number | ''>('');
  const [submitError, setSubmitError] = useState<string | null>(null);

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    setSubmitError(null);
    try {
      await record.mutateAsync({
        advisor_id: advisorId,
        session_date: sessionDate,
        appointment_category: category,
        is_simulated: isSimulated,
        advisor_role: advisorRole,
        strengths: strengths.trim() || null,
        improvement_areas: improvements.trim() || null,
        manager_comments: comments.trim() || null,
        rating: rating === '' ? null : Number(rating),
      });
      navigate('/manage/advisors');
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'We could not save that record.');
    }
  }

  return (
    <div className="space-y-6">
      <h1>Record joint fieldwork</h1>

      <Card>
        <CardHeader>
          <CardTitle>Session</CardTitle>
        </CardHeader>
        <CardBody>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="advisor" className="block text-sm font-medium">Advisor</label>
              <select
                id="advisor" value={advisorId} required
                onChange={(event) => setAdvisorId(event.target.value)}
                className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              >
                <option value="">Select an advisor…</option>
                {(advisors ?? []).map(({ profile }) => (
                  <option key={profile.id} value={profile.id}>{profile.full_name}</option>
                ))}
              </select>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="date" className="block text-sm font-medium">Date</label>
              <input
                id="date" type="date" value={sessionDate} max={today()} required
                onChange={(event) => setSessionDate(event.target.value)}
                className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="category" className="block text-sm font-medium">
                Appointment category
              </label>
              <input
                id="category" type="text" value={category} required
                onChange={(event) => setCategory(event.target.value)}
                placeholder="For example: first appointment, review, protection discussion"
                className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
              <p className="text-sm text-muted-foreground">
                Category only. Do not record client names or details — there is no field for
                them, by design.
              </p>
            </div>

            <label className="flex min-h-[44px] items-center gap-3 text-sm">
              <input
                type="checkbox" checked={isSimulated}
                onChange={(event) => setIsSimulated(event.target.checked)}
                className="h-4 w-4"
              />
              This was an approved simulation rather than a real client appointment
            </label>

            <fieldset className="space-y-2">
              <legend className="text-sm font-medium">What the advisor did</legend>
              {ROLES.map((role) => (
                <label
                  key={role.value}
                  className="flex cursor-pointer items-start gap-3 rounded-md border border-border p-3 hover:bg-muted"
                >
                  <input
                    type="radio" name="role" value={role.value}
                    checked={advisorRole === role.value}
                    onChange={() => setAdvisorRole(role.value)}
                    className="mt-1 h-4 w-4 shrink-0"
                  />
                  <div>
                    <p className="text-sm font-medium">{role.label}</p>
                    <p className="text-xs text-muted-foreground">{role.description}</p>
                  </div>
                </label>
              ))}
            </fieldset>

            <div className="space-y-1.5">
              <label htmlFor="strengths" className="block text-sm font-medium">Strengths</label>
              <textarea
                id="strengths" rows={2} value={strengths}
                onChange={(event) => setStrengths(event.target.value)}
                className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="improvements" className="block text-sm font-medium">
                Areas to improve
              </label>
              <textarea
                id="improvements" rows={2} value={improvements}
                onChange={(event) => setImprovements(event.target.value)}
                className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="comments" className="block text-sm font-medium">Your comments</label>
              <textarea
                id="comments" rows={3} value={comments}
                onChange={(event) => setComments(event.target.value)}
                className="w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="rating" className="block text-sm font-medium">
                Overall rating <span className="font-normal text-muted-foreground">(optional)</span>
              </label>
              <select
                id="rating" value={rating}
                onChange={(event) => setRating(event.target.value === '' ? '' : Number(event.target.value))}
                className="min-h-[44px] w-full rounded-md border border-input bg-surface px-3 py-2 text-base"
              >
                <option value="">No rating</option>
                {[1, 2, 3, 4, 5].map((value) => (
                  <option key={value} value={value}>{value} of 5</option>
                ))}
              </select>
            </div>

            {submitError && (
              <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
                {submitError}
              </p>
            )}

            <Button type="submit" variant="accent" size="lg" isLoading={record.isPending} disabled={!advisorId}>
              Save fieldwork record
            </Button>
          </form>
        </CardBody>
      </Card>
    </div>
  );
}
