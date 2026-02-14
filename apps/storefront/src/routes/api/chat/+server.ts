import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';
import { nanoid } from 'nanoid';

// POST - Send chat message
export const POST: RequestHandler = async ({ request }) => {
    try {
        const { session_id, message, sender_type, customer_id, branch_id } = await request.json();

        if (!message || !sender_type) {
            return json({ error: 'Message and sender type are required' }, { status: 400 });
        }

        const supabase = createClient();

        let sessionId = session_id;

        // If no session, create one
        if (!sessionId) {
            if (!branch_id) {
                return json({ error: 'Branch ID required for new session' }, { status: 400 });
            }

            const { data: newSession, error: sessionError } = await supabase
                .from('chat_sessions')
                .insert({
                    branch_id,
                    customer_id,
                    status: 'active'
                })
                .select()
                .single();

            if (sessionError) {
                console.error('Session creation error:', sessionError);
                return json({ error: 'Failed to create chat session' }, { status: 500 });
            }

            sessionId = newSession.id;
        }

        // Insert message
        const { data, error } = await supabase
            .from('chat_messages')
            .insert({
                session_id: sessionId,
                message,
                sender_type,
                sender_id: customer_id
            })
            .select()
            .single();

        if (error) {
            console.error('Message insert error:', error);
            return json({ error: error.message }, { status: 500 });
        }

        return json({ message: data, session_id: sessionId }, { status: 201 });
    } catch (error: any) {
        console.error('Chat API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
