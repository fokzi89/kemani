import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import OpenAI from 'openai';
import { PRIVATE_OPENAI_API_KEY } from '$env/static/private';

// Initialize OpenAI client
const openai = new OpenAI({
    apiKey: PRIVATE_OPENAI_API_KEY
});

// Configure constants
const HANDOVER_PHRASES = ["talk to human", "speak to agent", "real person", "human agent", "support person"];

export const POST: RequestHandler = async ({ request, locals: { supabase } }) => {
    try {
        const { messageId } = await request.json();

        if (!messageId) {
            return json({ error: 'Missing messageId' }, { status: 400 });
        }

        // 1. Fetch the user message and session context
        const { data: message, error: messageError } = await supabase
            .from('chat_messages')
            .select('*, session:chat_sessions(id, status, agent_type, tenant_id, branch_id)')
            .eq('id', messageId)
            .single();

        if (messageError || !message) {
            console.error('Message fetch error:', messageError);
            return json({ error: 'Message not found' }, { status: 404 });
        }

        const session = message.session;

        // 2. Validate prerequisites for AI response
        if (message.sender_type !== 'customer') {
            return json({ status: 'ignored', reason: 'Not a customer message' });
        }

        if (session.agent_type !== 'ai') {
            return json({ status: 'ignored', reason: 'Agent type is not AI' });
        }

        if (session.status !== 'active') {
            return json({ status: 'ignored', reason: 'Session is not active' });
        }

        // 3. Check for Handover Intent
        const lowerContent = message.content.toLowerCase();
        const isHandover = HANDOVER_PHRASES.some(phrase => lowerContent.includes(phrase));

        if (isHandover) {
            // Switch Agent Type to 'live'
            await supabase
                .from('chat_sessions')
                .update({ agent_type: 'live' })
                .eq('id', session.id);

            // Notify Customer
            await sendAIMessage(supabase, session.id, "I'm transferring you to a human agent. Please hold while I connect you.");
            return json({ status: 'handover_initiated' });
        }

        // 4. Generate AI Response
        const systemPrompt = `
            You are a helpful AI support assistant for an online store.
            Your goal is to assist customers with product questions, order status, and general inquiries.
            If you cannot answer a question, suggest talking to a human agent.
            Be concise, friendly, and professional.
            
            Store Context:
            - Tenant ID: ${session.tenant_id}
            - Branch ID: ${session.branch_id}
        `;

        let aiResponseContent = "";

        if (message.message_type === 'text') {
            const completion = await openai.chat.completions.create({
                messages: [
                    { role: "system", content: systemPrompt },
                    { role: "user", content: message.content },
                ],
                model: "gpt-4-turbo-preview", // Use a capable model
            });
            aiResponseContent = completion.choices[0].message.content || "I'm sorry, I couldn't generate a response.";

        } else if (message.message_type === 'image') {
            // Vision Capability
            const completion = await openai.chat.completions.create({
                messages: [
                    { role: "system", content: systemPrompt },
                    {
                        role: "user",
                        content: [
                            { type: "text", text: "What is in this image? Is it a product from our store?" },
                            {
                                type: "image_url",
                                image_url: {
                                    url: message.content, // Assuming public URL
                                },
                            },
                        ],
                    },
                ],
                model: "gpt-4-vision-preview",
                max_tokens: 300,
            });
            aiResponseContent = completion.choices[0].message.content || "I see an image, but I'm not sure what it is.";
        } else {
            aiResponseContent = "I received your file. A human agent can review it shortly.";
        }

        // 5. Send Response
        await sendAIMessage(supabase, session.id, aiResponseContent);

        return json({ status: 'responded' });

    } catch (error: any) {
        console.error('AI Agent API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};

async function sendAIMessage(supabase: any, sessionId: string, content: string) {
    const { error } = await supabase
        .from('chat_messages')
        .insert({
            session_id: sessionId,
            sender_type: 'ai',
            sender_name: 'AI Assistant',
            message_type: 'text',
            content: content,
        });

    if (error) {
        console.error('Failed to send AI message:', error);
        throw error;
    }
}
