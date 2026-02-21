import { createClient } from '$lib/services/supabase';
import type { RealtimeChannel, SupabaseClient } from '@supabase/supabase-js';
import type {
    ChatSession,
    ChatMessage,
    Database
} from '$lib/types/supabase.js';

export interface ChatServiceConfig {
    branchId: string;
    tenantId: string;
    customerId: string | null;
    sessionToken: string;
    planTier: string;
}

export interface ChatEventHandlers {
    onMessage: (message: ChatMessage) => void;
    onTyping: (isTyping: boolean, agentName?: string) => void;
    onAgentStatusChange: (status: 'online' | 'offline' | 'busy') => void;
    onQueueUpdate: (position: number) => void;
    onSessionUpdate: (session: ChatSession) => void;
    onError: (error: Error) => void;
    onConnect: () => void;
    onDisconnect: () => void;
    onReconnect: () => void;
}

export class ChatServiceImpl {
    private supabase: SupabaseClient<Database>;
    private channel: RealtimeChannel | null = null;
    private config: ChatServiceConfig;
    private handlers: ChatEventHandlers | null = null;

    constructor(config: ChatServiceConfig) {
        this.config = config;
        this.supabase = createClient();
    }

    async initialize() {
        try {
            // Call API to create or retrieve session
            const response = await fetch('/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    branchId: this.config.branchId,
                    tenantId: this.config.tenantId,
                    customerId: this.config.customerId,
                    sessionToken: this.config.sessionToken
                })
            });

            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.message || 'Failed to initialize chat session');
            }

            const data = await response.json();
            return {
                session: data.session,
                messages: data.messages || [],
                agentStatus: data.agentStatus || 'offline',
                queuePosition: data.queuePosition
            };

        } catch (error) {
            console.error('Chat initialization error:', error);
            throw error;
        }
    }

    connect(sessionId: string, handlers: ChatEventHandlers) {
        this.handlers = handlers;

        if (this.channel) {
            this.disconnect();
        }

        this.channel = this.supabase.channel(`chat:${sessionId}`)
            .on('postgres_changes', {
                event: 'INSERT',
                schema: 'public',
                table: 'chat_messages',
                filter: `session_id=eq.${sessionId}`
            }, (payload) => {
                const newMessage = payload.new as ChatMessage;
                // Only notify if it's not our own message (or if we want to confirm receipt)
                // Assuming optimistic updates handle own messages, we might strictly filter incoming
                // But typically good to receive confirmation.
                // For simplicity, we pass all and let store handle dedup logic (which it does).
                handlers.onMessage(newMessage);
            })
            .on('broadcast', { event: 'typing' }, (payload) => {
                handlers.onTyping(payload.payload.isTyping, payload.payload.agentName);
            })
            .on('broadcast', { event: 'agent_status' }, (payload) => {
                handlers.onAgentStatusChange(payload.payload.status);
            })
            .subscribe((status) => {
                if (status === 'SUBSCRIBED') {
                    handlers.onConnect();
                } else if (status === 'CLOSED') {
                    handlers.onDisconnect();
                } else if (status === 'CHANNEL_ERROR') {
                    handlers.onError(new Error('Channel subscription error'));
                }
            });
    }

    disconnect() {
        if (this.channel) {
            this.channel.unsubscribe();
            this.channel = null;
        }
    }

    async sendMessage(payload: {
        sessionId: string;
        messageType: 'text' | 'image' | 'voice' | 'pdf' | 'product_card';
        content: string;
        productId?: string;
        attachmentId?: string;
    }): Promise<ChatMessage> {
        // We use the API to send messages to ensure proper server-side validation and processing (e.g. AI auto-reply trigger)
        // Alternatively we could insert directly if RLS allows, but API is safer for logic.

        // However, RLS usually allows INSERT for session owners.
        // Let's stick to API for consistency and triggering side effects (like AI agent).

        // Wait, for low latency, direct DB insert is better, but then we need a Database Trigger to handle AI.
        // The schema has triggers for timestamps.
        // Let's use the API approach to abstract complexity and handle AI.

        const response = await fetch('/api/chat/message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                sessionId: payload.sessionId,
                messageType: payload.messageType,
                content: payload.content,
                productId: payload.productId,
                attachmentId: payload.attachmentId,
                senderType: 'customer', // Or 'guest' based on auth
                sessionToken: this.config.sessionToken
            })
        });

        if (!response.ok) {
            throw new Error('Failed to send message');
        }

        return await response.json();
    }

    sendTypingIndicator(sessionId: string, isTyping: boolean) {
        if (this.channel) {
            this.channel.send({
                type: 'broadcast',
                event: 'typing',
                payload: { isTyping, from: 'customer' }
            });
        }
    }

    async uploadFile(sessionId: string, file: File, type: 'image' | 'voice' | 'pdf') {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('sessionId', sessionId);
        formData.append('type', type);
        formData.append('sessionToken', this.config.sessionToken);

        const response = await fetch('/api/chat/upload', {
            method: 'POST',
            body: formData
        });

        if (!response.ok) {
            throw new Error('File upload failed');
        }

        return await response.json();
    }

    async markMessagesAsRead(sessionId: string, messageIds: string[]) {
        await this.supabase.rpc('mark_chat_messages_read', {
            p_session_id: sessionId,
            p_message_ids: messageIds
        });
    }

    async getChatHistory(sessionId: string, limit: number, before?: string) {
        let query = this.supabase
            .from('chat_messages')
            .select('*')
            .eq('session_id', sessionId)
            .order('created_at', { ascending: false })
            .limit(limit);

        if (before) {
            query = query.lt('created_at', before);
        }

        const { data, error } = await query;

        if (error) throw error;
        return data?.reverse() || [];
    }

    async endSession(sessionId: string) {
        await this.supabase
            .from('chat_sessions')
            .update({ status: 'resolved', resolved_at: new Date().toISOString() })
            .eq('id', sessionId);
    }
}

export function createChatService(config: ChatServiceConfig) {
    return new ChatServiceImpl(config);
}

export function validateChatFile(file: File): { valid: boolean; error?: string } {
    const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
    const MAX_PDF_SIZE = 10 * 1024 * 1024; // 10MB
    const MAX_AUDIO_SIZE = 5 * 1024 * 1024; // 5MB

    if (file.type.startsWith('image/')) {
        if (file.size > MAX_IMAGE_SIZE) {
            return { valid: false, error: 'Image must be less than 5MB' };
        }
    } else if (file.type === 'application/pdf') {
        if (file.size > MAX_PDF_SIZE) {
            return { valid: false, error: 'PDF must be less than 10MB' };
        }
    } else if (file.type.startsWith('audio/')) {
        if (file.size > MAX_AUDIO_SIZE) {
            return { valid: false, error: 'Audio must be less than 5MB' };
        }
    } else {
        return { valid: false, error: 'Unsupported file type' };
    }

    return { valid: true };
}
