import { redirect } from '@sveltejs/kit';

export const GET = async ({ url, locals: { supabase } }) => {
  const code = url.searchParams.get('code');
  const next = url.searchParams.get('next') ?? '/';

  if (code) {
    await supabase.auth.exchangeCodeForSession(code);
  }

  // If `next` is a full URL (contains http/https), redirect to it directly.
  // This handles the case where the user was on a subdomain (e.g. medic.localhost:5143)
  // and we need to bounce them back there after auth.
  if (next.startsWith('http://') || next.startsWith('https://')) {
    throw redirect(303, next);
  }

  throw redirect(303, next);
};

