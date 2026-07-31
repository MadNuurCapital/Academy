import { createClient } from '@supabase/supabase-js';

/**
 * The browser Supabase client.
 *
 * Only the anon key ever reaches this file. Every permission is enforced by Row
 * Level Security in the database, so the anon key grants nothing on its own —
 * it identifies the project, not the user.
 *
 * The service-role key must never appear in any file under src/. Operations
 * needing it (creating a user, sending an invite) run in a Netlify Function
 * where the key stays server-side.
 */

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Missing Supabase configuration. Copy .env.example to .env and set ' +
      'VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY. See README.md for where to find them.',
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    // Persisting the session is what allows a hard refresh on a protected page
    // to restore the user rather than bouncing them to the login screen.
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
