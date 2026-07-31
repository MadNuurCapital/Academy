import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useAuth } from '@/auth/useAuth';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/Button';
import { Card, CardBody, CardHeader, CardTitle } from '@/components/ui/Card';
import { Field } from '@/components/ui/Field';

const schema = z.object({
  full_name: z.string().min(1, 'Enter your name'),
  phone: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

/**
 * The advisor's own details.
 *
 * Name and phone are the only fields an advisor may change. Their role, status
 * and email are administrative, and the RLS policy on profiles rejects an
 * attempt to alter status even if this form were bypassed.
 */
export function ProfilePage() {
  const { profile, roles, refresh } = useAuth();
  const [saved, setSaved] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      full_name: profile?.full_name ?? '',
      phone: profile?.phone ?? '',
    },
  });

  async function onSubmit(values: FormValues) {
    setSaved(false);
    setSaveError(null);
    const { error } = await supabase
      .from('profiles')
      .update({ full_name: values.full_name, phone: values.phone || null })
      .eq('id', profile!.id);

    if (error) {
      setSaveError(error.message);
      return;
    }
    await refresh();
    setSaved(true);
  }

  return (
    <div className="space-y-6">
      <h1>My profile</h1>

      <Card>
        <CardHeader>
          <CardTitle>Your details</CardTitle>
        </CardHeader>
        <CardBody>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
            <Field label="Full name" error={errors.full_name?.message} {...register('full_name')} />
            <Field
              label="Phone number"
              type="tel"
              hint="Optional. Used by your manager to reach you."
              error={errors.phone?.message}
              {...register('phone')}
            />

            {saveError && (
              <p role="alert" className="rounded-md bg-danger/10 px-3 py-2 text-sm font-medium text-danger">
                {saveError}
              </p>
            )}
            {saved && (
              <p role="status" className="rounded-md bg-success/10 px-3 py-2 text-sm font-medium text-success">
                Your details have been saved.
              </p>
            )}

            <Button type="submit" isLoading={isSubmitting}>
              Save changes
            </Button>
          </form>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Account</CardTitle>
        </CardHeader>
        <CardBody>
          <dl className="space-y-3 text-sm">
            <div>
              <dt className="text-muted-foreground">Email address</dt>
              <dd className="font-medium">{profile?.email}</dd>
            </div>
            <div>
              <dt className="text-muted-foreground">Role</dt>
              <dd className="font-medium capitalize">{roles.join(', ') || 'None assigned'}</dd>
            </div>
          </dl>
          <p className="mt-4 text-sm text-muted-foreground">
            Your email address and role are managed by your administrator.
          </p>
        </CardBody>
      </Card>
    </div>
  );
}
