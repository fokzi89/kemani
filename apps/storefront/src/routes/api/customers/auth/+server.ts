import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

// POST - Customer OAuth login (Google/Apple)
export const POST: RequestHandler = async ({ request }) => {
    try {
        const { provider } = await request.json();

        if (!provider || !['google', 'apple'].includes(provider)) {
            return json({ error: 'Invalid OAuth provider' }, { status: 400 });
        }

        const supabase = createClient();

        const { data, error } = await supabase.auth.signInWithOAuth({
            provider: provider as 'google' | 'apple',
            options: {
                redirectTo: `${import.meta.env.VITE_APP_URL}/auth/callback`
            }
        });

        if (error) {
            console.error('OAuth error:', error);
            return json({ error: error.message }, { status: 500 });
        }

        return json({ url: data.url });
    } catch (error: any) {
        console.error('Customer auth API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
