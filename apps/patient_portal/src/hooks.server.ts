import { createServerClient } from '@supabase/ssr';
import { type Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { createClient } from '@supabase/supabase-js';

const globalSupabase = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

function extractSubdomain(hostname: string): string | null {
  const host = hostname.split(':')[0];
  const parts = host.split('.');
  if (host.includes('localhost')) {
    return parts.length > 1 ? parts[0] : null;
  }
  return parts.length >= 3 ? parts[0] : null;
}

async function resolveSubdomain(subdomain: string): Promise<{ tenantId: string | null; hcpId: string | null }> {
  if (!subdomain) return { tenantId: null, hcpId: null };

  // 1. Try to find a tenant by subdomain column
  const { data: bySubdomain } = await globalSupabase
    .from('tenants')
    .select('id')
    .eq('subdomain', subdomain)
    .is('deleted_at', null)
    .limit(1)
    .maybeSingle();
  if (bySubdomain) return { tenantId: bySubdomain.id, hcpId: null };

  // 2. Try to find a tenant by slug
  const { data: bySlug } = await globalSupabase
    .from('tenants')
    .select('id')
    .eq('slug', subdomain)
    .is('deleted_at', null)
    .limit(1)
    .maybeSingle();
  if (bySlug) return { tenantId: bySlug.id, hcpId: null };

  // 3. Fallback: try to find a healthcare_provider (medic) by slug
  const { data: byHcp } = await globalSupabase
    .from('healthcare_providers')
    .select('id')
    .eq('slug', subdomain)
    .limit(1)
    .maybeSingle();
  if (byHcp) return { tenantId: null, hcpId: byHcp.id };

  return { tenantId: null, hcpId: null };
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
  return resolve(event, { filterSerializedResponseHeaders: (name) => name === 'content-range' });
};

// Detects which tenant subdomain or HCP slug we're on
const tenantHandle: Handle = async ({ event, resolve }) => {
  event.locals.hostname = event.url.hostname;
  event.locals.referringTenantId = null;
  event.locals.referringHcpId = null;
  event.locals.subdomain = null;

  const subdomain = extractSubdomain(event.url.hostname);
  if (subdomain) {
    const { tenantId, hcpId } = await resolveSubdomain(subdomain);
    event.locals.subdomain = subdomain;
    event.locals.referringTenantId = tenantId;
    event.locals.referringHcpId = hcpId;
  }

  return resolve(event);
};

export const handle: Handle = sequence(tenantHandle, supabaseHandle);
