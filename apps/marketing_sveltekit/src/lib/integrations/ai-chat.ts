import { createClient } from '@/lib/supabase/client';
import { ChatMessage, SenderType, ChatMessageType } from '@/lib/types/database';
import { Product } from '@/lib/types/pos';

// Mock AI response for MVP/Demo without incurring API costs immediately
// In production, this would use 'ai' SDK from Vercel or OpenAI directly.

export class AIChatService {

    /**
     * Finds relevant products based on query.
     * Simple ILIKE search for MVP. RAG would be used here in Prod.
     */
    static async searchProducts(tenantId: string, query: string): Promise<Product[]> {
        const supabase = await createClient();
        const { data } = await supabase
            .from('products')
            .select('*')
            .eq('tenant_id', tenantId)
            .ilike('name', `%${query}%`)
            .limit(3);
        return (data || []) as Product[];
    }

    /**
     * Generates a response from the AI Agent.
     */
    static async generateResponse(tenantId: string, conversationId: string, userMessage: string): Promise<Partial<ChatMessage>> {
        // 1. Analyze Intent (Mock)
        const lowerMsg = userMessage.toLowerCase();
        let intent = 'general_query';
        let responseText = "I'm not sure about that. Can you call the store?";
        let actionType: any = null;
        let actionData: any = null;

        if (lowerMsg.includes('price') || lowerMsg.includes('cost') || lowerMsg.includes('how much')) {
            intent = 'price_check';
            responseText = "Let me check the price for you.";
            // Extract product name roughly
            const productQuery = userMessage.replace(/price|cost|how much|is the|of/gi, '').trim();
            const products = await this.searchProducts(tenantId, productQuery);

            if (products.length > 0) {
                const p = products[0];
                responseText = `The ${p.name} is available for ₦${p.unit_price}.`;
                actionType = 'suggest_product';
                actionData = { productId: p.id, name: p.name, price: p.unit_price };
            } else {
                responseText = "I couldn't find that exact product, but we have many others in store!";
            }
        } else if (lowerMsg.includes('hello') || lowerMsg.includes('hi')) {
            intent = 'greeting';
            responseText = "Hello! Welcome to our store. How can I help you today?";
        } else if (lowerMsg.includes('open') || lowerMsg.includes('time')) {
            intent = 'store_hours';
            responseText = "We are open from 9 AM to 9 PM every day.";
        }

        // 2. Return the constructed message object (to be saved by caller)
        return {
            conversation_id: conversationId,
            sender_type: 'ai_agent',
            message_type: 'text',
            message_text: responseText,
            intent: intent,
            confidence_score: 0.95,
            action_type: actionType,
            action_data: actionData,
        };
    }
}
