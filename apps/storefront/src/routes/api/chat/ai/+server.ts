import { json } from '@sveltejs/kit';
import { StorefrontAIService } from '$lib/services/ai.service';
import { env } from '$env/dynamic/private';

/** @type {import('./$types').RequestHandler} */
export async function POST({ request, locals }) {
    try {
        const { messages, tenantId, customerId } = await request.json();
        
        if (!tenantId) {
            return json({ error: 'Tenant ID is required' }, { status: 400 });
        }

        const apiKey = env.GOOGLE_GENERATIVE_AI_API_KEY;
        if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY') {
            return json({ 
                error: 'AI API Key not configured. Please set GOOGLE_GENERATIVE_AI_API_KEY in your .env file.' 
            }, { status: 500 });
        }

        const aiService = new StorefrontAIService(apiKey);
        const result = await aiService.chat(messages, tenantId, customerId);

        return result.toDataStreamResponse();
    } catch (err: any) {
        console.error('AI Chat Error:', err);
        return json({ error: err.message }, { status: 500 });
    }
}
