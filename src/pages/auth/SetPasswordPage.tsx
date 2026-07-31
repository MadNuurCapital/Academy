import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/auth/useAuth';
import { AuthCard } from './AuthCard';
import { Button } from '@/components/ui/Button';
import { Field } from '@/components/ui/Field';
import { FullPageLoading } from '@/components/ui/States';

const schema = z
  .object({
    password: z
      .string()
      .min(10, 'Use at least 10 characters')
      .regex(/[a-z]/, 'Include a lower-case letter')
      .regex(/[A-Z]/, 'Include an upper-case letter')
      .regex(/[0-9]/, 'Include a number'),
    confirm: z.string(),
  })
  .refine((values) => values.password === values.confirm, {
    message: 'Both passwords must match',
    path: ['confirm'],
  });

type FormValues = z.infer<typeof schema>;

/**
 * Used for two journeys that are mechanically identical:
 *
 *   * accepting an invitation, where an advisor sets their password for the
 *     first time — nobody hands out passwords, so this is the only way an
 *     account gets one; and
 *   * completing a password reset.
 *
 * In both cases Supabase has already established a session from the link in the
 * email by the time this page renders.
 */
export function SetPasswordPage({ mode }: { mode: 'invite' | 'reset' }) {
  const navigate = useNavigate();
  const { session, isResolving, refresh } = useAuth();
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [hasCheckedLink, setHasCheckedLink] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  // Supabase parses the token from the URL fragment asynchronously; give it a
  // moment before deciding the link was invalid.
  useEffect(() => {
    if (!isResolving) setHasCheckedLink(true);
  }, [isResolving]);

  if (isResolving || !hasCheckedLink) return <FullPageLoading label="Checking your link…" />;

  if (!session) {
    return (
      <AuthCard title="This link is no longer valid">
        <p className="text-sm text-muted-foreground">
          Password links expire after one hour and can only be used once. Request a new one and try
          again.
        </p>
        <Button className="mt-6" size="full" variant="outline" onClick={() => navigate('/forgot-password')}>
          Request a new link
        </Button>
      </AuthCard>
    );
  }

  async function onSubmit(values: FormValues) {
    setSubmitError(null);
    const { error } = await supabase.auth.updateUser({ password: values.password });
    if (error) {
      setSubmitError(error.message);
      return;
    }
    await refresh();
    navigate('/', { replace: true });
  }

  return (
    <AuthCard
      title={mode === 'invite' ? 'Set your password' : 'Choose a new password'}
      subtitle={
        mode === 'invite'
          ? 'Welcome to ATLAS Academy. Set a password to finish setting up your account.'
          : undefined
      }
    >
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
        <Field
          label="New password"
          type="password"
          autoComplete="new-password"
          autoFocus
          hint="At least 10 characters, with an upper-case letter, a lower-case letter and a number."
          error={errors.password?.message}
          {...register('password')}
        />
        <Field
          label="Confirm password"
          type="password"
          autoComplete="new-password"
          error={errors.confirm?.message}
          {...register('confirm')}
        />

        {submitError && (
          <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
            {submitError}
          </p>
        )}

        <Button type="submit" size="full" isLoading={isSubmitting}>
          {mode === 'invite' ? 'Set password and continue' : 'Update password'}
        </Button>
      </form>
    </AuthCard>
  );
}
