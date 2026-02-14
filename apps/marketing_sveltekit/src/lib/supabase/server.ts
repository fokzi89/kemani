import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { Database } from '@/types/database.types';
import type { User } from '@supabase/supabase-js';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: any) {
          try {
            cookieStore.set(name, value, options);
          } catch (error) {
            // Handle cookie setting errors
          }
        },
        remove(name: string, options: any) {
          try {
            cookieStore.set(name, '', options);
          } catch (error) {
            // Handle cookie removal errors
          }
        },
      },
    }
  );
}

export async function createAdminClient() {
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      cookies: {
        get() { return undefined; },
        set() { },
        remove() { },
      },
    }
  );
}

/**
 * Get the current user from the session.
 * Returns null if not authenticated.
 */
export async function getCurrentUser(): Promise<User | null> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

/**
 * Require authentication - redirects to login if not authenticated.
 * Use this in Server Components and layouts to protect routes.
 */
export async function requireAuth(): Promise<User> {
  const user = await getCurrentUser();
  if (!user) {
    redirect('/login');
  }
  return user;
}

/**
 * Get current user with their tenant and role information.
 * Returns null if not authenticated.
 */
export async function getUserWithTenant() {
  const user = await getCurrentUser();
  if (!user) return null;

  const supabase = await createClient();
  const { data: userProfile } = await supabase
    .from('users')
    .select(`
      *,
      tenant:tenants(*)
    `)
    .eq('id', user.id)
    .single();

  return userProfile;
}

/**
 * Require admin role - redirects to unauthorized page if not admin.
 */
export async function requireAdmin() {
  const user = await requireAuth();
  const userWithTenant = await getUserWithTenant();

  if (!userWithTenant || userWithTenant.role !== 'admin') {
    redirect('/unauthorized');
  }

  return userWithTenant;
}

/**
 * Check if user is already authenticated.
 * Useful for auth pages to redirect logged-in users.
 */
export async function redirectIfAuthenticated(to: string = '/dashboard') {
  const user = await getCurrentUser();
  if (user) {
    redirect(to);
  }
}
