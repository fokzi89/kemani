import { createServerClient } from '@supabase/ssr';
import { type Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { createClient } from '@supabase/supabase-js';

const globalSupabase = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

function extractSubdomain(hostname: string): string | null {
  const host = hostname.split(':')[0];
  const parts = host.split('.');
  if (host === 'localhost') return null;
  if (host.endsWith('.localhost') && parts.length === 2) return parts[0];
  if (parts.length >= 3) return parts[0];
  return null;
}

async function lookupTenantBySubdomain(subdomain: string): Promise<string | null> {
  const { data: bySubdomain } = await globalSupabase
    .from('tenants').select('id').eq('subdomain', subdomain).single();
  if (bySubdomain) return bySubdomain.id;
  const { data: bySlug } = await globalSupabase
    .from('tenants').select('id').eq('slug', subdomain).single();
  return bySlug?.id || null;
}

const supabaseHandle: Handle = async ({ event, resolve }) => {
  event.locals.supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
    cookies: {
      get: (key) => event.cookies.get(key),
      set: (key, value, options) => event.cookies.set(key, value, { ...options, path: '/' }),
      remove: (key, options) => event.cookies.delete(key, { ...options, path: '/' })
    }
  });
  const { data: { session } } = await event.locals.supabase.auth.getSession();
  event.locals.session = session;
  return resolve(event, { filterSerializedResponseHeaders: (n) => n === 'content-range' });
};

const tenantHandle: Handle = async ({ event, resolve }) => {
  event.locals.hostname = event.url.hostname;
  event.locals.referringTenantId = null;
  const subdomain = extractSubdomain(event.url.hostname);
  if (subdomain) {
    const tenantId = await lookupTenantBySubdomain(subdomain);
    if (tenantId) event.locals.referringTenantId = tenantId;
  }
  return resolve(event);
};

export const handle: Handle = sequence(tenantHandle, supabaseHandle);
