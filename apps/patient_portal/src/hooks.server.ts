import { createServerClient } from '@supabase/ssr';
import { type Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { createClient } from '@supabase/supabase-js';

const globalSupabase = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

function extractSubdomain(hostname: string): string | null {
  const host = hostname.split(':')[0]; // Remove port if any
  const parts = host.split('.');
  
  // Local development handling
  if (host.includes('localhost')) {
    if (parts.length > 1) return parts[0];
    return null;
  }
  
  // Production handling (assuming kemani.com or similar)
  if (parts.length >= 3) {
    return parts[0];
  }
  
  return null;
}

async function lookupTenantBySubdomain(subdomain: string): Promise<string | null> {
  if (!subdomain) return null;

  // Try subdomain column first
  const { data: bySubdomain } = await globalSupabase
    .from('tenants')
    .select('id')
    .eq('subdomain', subdomain)
    .is('deleted_at', null)
    .limit(1)
    .maybeSingle();
  
  if (bySubdomain) return bySubdomain.id;

  // Fallback to slug if no explicit subdomain mapping exists
  const { data: bySlug } = await globalSupabase
    .from('tenants')
    .select('id')
    .eq('slug', subdomain)
    .is('deleted_at', null)
    .limit(1)
    .maybeSingle();
    
  return bySlug?.id || null;
}

// Creates the per-request Supabase client and attaches it to locals
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

  return resolve(event, {
    filterSerializedResponseHeaders: (name) => name === 'content-range'
  });
};

// Detects which tenant subdomain we're on and attaches the tenant ID to locals
const tenantHandle: Handle = async ({ event, resolve }) => {
  event.locals.hostname = event.url.hostname;
  event.locals.referringTenantId = null;
  
  const subdomain = extractSubdomain(event.url.hostname);
  if (subdomain) {
    const tenantId = await lookupTenantBySubdomain(subdomain);
    if (tenantId) {
      event.locals.referringTenantId = tenantId;
      event.locals.subdomain = subdomain;
    }
  }
  
  return resolve(event);
};

// tenantHandle runs first, then supabaseHandle to ensure auth is available
export const handle: Handle = sequence(tenantHandle, supabaseHandle);
