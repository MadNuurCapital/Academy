import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { supabase } from '@/lib/supabase';
import { AuthCard } from './AuthCard';
import { Button } from '@/components/ui/Button';
import { Field } from '@/components/ui/Field';

const schema = z.object({
  email: z.string().min(1, 'Enter your email address').email('Enter a valid email address'),
});

type FormValues = z.infer<typeof schema>;

export function ForgotPasswordPage() {
  const [isSent, setIsSent] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  async function onSubmit(values: FormValues) {
    await supabase.auth.resetPasswordForEmail(values.email.trim(), {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    // Always report success. Revealing that an address is unknown would let
    // anyone test which staff emails are registered.
    setIsSent(true);
  }

  if (isSent) {
    return (
      <AuthCard title="Check your email">
        <p className="text-sm text-muted-foreground">
          If that address belongs to an ATLAS Academy account, a password reset link is on its way.
          The link expires after one hour.
        </p>
        <Link to="/login" className="mt-6 block text-center text-sm font-medium text-accent hover:underline">
          Back to sign in
        </Link>
      </AuthCard>
    );
  }

  return (
    <AuthCard title="Reset your password" subtitle="We will email you a link to set a new one.">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
        <Field
          label="Email address"
          type="email"
          autoComplete="email"
          autoFocus
          error={errors.email?.message}
          {...register('email')}
        />
        <Button type="submit" size="full" isLoading={isSubmitting}>
          Send reset link
        </Button>
      </form>

      <Link to="/login" className="mt-4 block text-center text-sm font-medium text-accent hover:underline">
        Back to sign in
      </Link>
    </AuthCard>
  );
}
