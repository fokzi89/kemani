import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/**
 * OAuth callback handler.
 * Supabase redirects here after Google/Apple sign-in.
 * The auth code is exchanged for a session via the URL hash/query.
 */
export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
    const code = url.searchParams.get('code');

    if (code) {
        await supabase.auth.exchangeCodeForSession(code);
    }

    // Redirect to the page they were trying to access, or home
    const next = url.searchParams.get('next') || '/';
    throw redirect(303, next);
};
