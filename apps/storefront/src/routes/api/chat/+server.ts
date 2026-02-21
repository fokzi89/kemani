import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, locals: { supabase } }) => {
    try {
        const { branchId, tenantId, customerId, sessionToken } = await request.json();

        if (!branchId || !tenantId) {
            return json({ error: 'Missing branch or tenant ID' }, { status: 400 });
        }

        // Check for existing active session
        let query = supabase
            .from('chat_sessions')
            .select('*')
            .eq('branch_id', branchId)
            .eq('status', 'active')
            .order('last_message_at', { ascending: false, nullsFirst: false }) // Prioritize recent activity
            .limit(1);

        if (customerId) {
            query = query.eq('customer_id', customerId);
        } else if (sessionToken) {
            query = query.eq('session_token', sessionToken);
        } else {
            return json({ error: 'Missing customer context' }, { status: 400 });
        }

        const { data: existingSession, error: fetchError } = await query.maybeSingle();

        if (fetchError) {
            throw fetchError;
        }

        let session = existingSession;

        // If no active session, create one
        if (!session) {
            const { data: newSession, error: createError } = await supabase
                .from('chat_sessions')
                .insert({
                    branch_id: branchId,
                    tenant_id: tenantId,
                    customer_id: customerId || null,
                    session_token: sessionToken || 'guest',
                    status: 'active',
                    agent_type: 'live' // Default to live, can be updated by logic later
                })
                .select()
                .single();

            if (createError) {
                throw createError;
            }
            session = newSession;
        }

        // Fetch recent messages
        const { data: messages, error: messagesError } = await supabase
            .from('chat_messages')
            .select('*')
            .eq('session_id', session.id)
            .order('created_at', { ascending: true }) // Send in chronological order
            .limit(50); // Initial load limit

        if (messagesError) {
            throw messagesError;
        }

        return json({
            session,
            messages: messages || [],
            agentStatus: 'online', // Placeholder, implement real status later using presence
            queuePosition: null
        });

    } catch (error: any) {
        console.error('Chat API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
