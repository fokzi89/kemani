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
    .single();
  
  if (bySubdomain) return bySubdomain.id;

  // Fallback to slug if no explicit subdomain mapping exists
  const { data: bySlug } = await globalSupabase
    .from('tenants')
    .select('id')
    .eq('slug', subdomain)
    .single();
    
  return bySlug?.id || null;
}

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

export const handle: Handle = sequence(tenantHandle, supabaseHandle);

