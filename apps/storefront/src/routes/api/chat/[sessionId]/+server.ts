import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

// GET - Get chat history
export const GET: RequestHandler = async ({ params }) => {
    try {
        const { sessionId } = params;

        if (!sessionId) {
            return json({ error: 'Session ID required' }, { status: 400 });
        }

        const supabase = createClient();

        const { data, error } = await supabase
            .from('chat_messages')
            .select('*')
            .eq('session_id', sessionId)
            .order('created_at', { ascending: true });

        if (error) {
            console.error('Chat history fetch error:', error);
            return json({ error: error.message }, { status: 500 });
        }

        return json(data);
    } catch (error: any) {
        console.error('Chat history API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
