import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, locals: { supabase } }) => {
    try {
        const { sessionId, sessionToken, messageType, content, productId, attachmentId, senderType } = await request.json();

        if (!sessionId || !sessionToken || !messageType || !content || !senderType) {
            return json({ error: 'Missing required parameters' }, { status: 400 });
        }

        // Validate session ownership before inserting
        // For security, check if sender owns the session via sessionToken or auth
        // RLS might handle this, but explicit check is good
        // Here we assume sessionToken matches if guest

        const { data: session, error: sessionError } = await supabase
            .from('chat_sessions')
            .select('customer_id, session_token')
            .eq('id', sessionId)
            .single();

        if (sessionError || !session) {
            return json({ error: 'Invalid session' }, { status: 404 });
        }

        if (session.session_token !== sessionToken && !session.customer_id) { // Guest must match token
            return json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Insert message
        const { data: message, error: insertError } = await supabase
            .from('chat_messages')
            .insert({
                session_id: sessionId,
                sender_type: senderType,
                sender_id: session.customer_id || null, // If authenticated customer
                sender_name: 'You', // Or customer name
                message_type: messageType,
                content: content,
                product_id: productId || null,
                read_at: null
            })
            .select()
            .single();

        if (insertError) {
            throw insertError;
        }

        // Link Attachment if present
        if (attachmentId) {
            const { error: linkError } = await supabase
                .from('chat_attachments')
                .update({ message_id: message.id })
                .eq('id', attachmentId)
                .eq('session_id', sessionId); // Ensure attachment belongs to this session

            if (linkError) {
                console.error('Failed to link attachment:', linkError);
            }
        }

        // Trigger AI Agent (Fire and await to ensure execution)
        if (senderType === 'customer') {
            try {
                // Determine the URL for the internal API call
                const aiUrl = new URL('/api/chat/ai', request.url).toString();

                // We await this ensuring the serverless function doesn't terminate early.
                // The AI endpoint performs the logic.
                await fetch(aiUrl, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ messageId: message.id })
                });
            } catch (aiError) {
                // Log but don't fail the user request
                console.error('Failed to trigger AI Agent:', aiError);
            }
        }

        return json(message);

    } catch (error: any) {
        console.error('Chat Message API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
