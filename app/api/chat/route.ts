import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';
import { AIChatService } from '@/lib/integrations/ai-chat';
import { SubscriptionService } from '@/lib/pos/subscription';

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const body = await req.json();
        const { conversationId, message, customerId, tenantId, branchId } = body;

        if (!conversationId && (!customerId || !tenantId || !branchId)) {
            return NextResponse.json({ error: 'Missing required fields to start chat' }, { status: 400 });
        }

        // Check Access
        const canUseAi = await SubscriptionService.checkFeatureAccess(tenantId, 'canUseAi');
        if (!canUseAi) {
            return NextResponse.json({
                error: 'AI Chat is not enabled for your subscription. Please upgrade or enable the add-on.'
            }, { status: 403 });
        }

        let convId = conversationId;

        // 1. Create Conversation if new
        if (!convId) {
            const { data: conv, error: convError } = await supabase
                .from('chat_conversations')
                .insert({
                    tenant_id: tenantId,
                    branch_id: branchId,
                    customer_id: customerId,
                    status: 'active'
                })
                .select()
                .single();

            if (convError) throw convError;
            convId = conv.id;
        }

        // 2. Save Customer Message
        const { error: msgError } = await supabase
            .from('chat_messages')
            .insert({
                conversation_id: convId,
                sender_type: 'customer',
                message_type: 'text',
                message_text: message
            });

        if (msgError) throw msgError;

        // 3. Generate AI Response
        const aiResponse = await AIChatService.generateResponse(tenantId, convId, message);

        // 4. Save AI Response
        const { data: aiMsg, error: aiError } = await supabase
            .from('chat_messages')
            .insert(aiResponse as any) // Type casting as Partial<ChatMessage> vs InsertSchema match might need strictness
            .select()
            .single();

        if (aiError) throw aiError;

        return NextResponse.json({
            conversationId: convId,
            userMessage: message,
            aiMessage: aiMsg
        });

    } catch (error: any) {
        console.error('Chat API Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
