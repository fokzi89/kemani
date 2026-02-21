/**
 * Chat Store - Svelte store for managing chat state
 * Provides reactive state management for chat sessions and messages
 */

import { writable, derived, get } from 'svelte/store';
import type { Writable, Readable } from 'svelte/store';
import type { 
    ChatSession, 
    ChatMessage,
    PlanTier 
} from '$lib/types/supabase.js';
import { 
    createChatService, 
    type ChatService, 
    type ChatServiceConfig,
    type ChatEventHandlers 
} from '$lib/services/chat.js';

export interface ChatState {
    session: ChatSession | null;
    messages: ChatMessage[];
    isOpen: boolean;
    isConnected: boolean;
    isConnecting: boolean;
    isLoading: boolean;
    isTyping: boolean;
    typingAgentName: string | null;
    agentStatus: 'online' | 'offline' | 'busy';
    queuePosition: number | null;
    error: string | null;
    unreadCount: number;
}

const initialState: ChatState = {
    session: null,
    messages: [],
    isOpen: false,
    isConnected: false,
    isConnecting: false,
    isLoading: false,
    isTyping: false,
    typingAgentName: null,
    agentStatus: 'offline',
    queuePosition: null,
    error: null,
    unreadCount: 0
};

// Create the main chat store
function createChatStore() {
    const { subscribe, set, update }: Writable<ChatState> = writable(initialState);
    let chatService: ChatService | null = null;

    return {
        subscribe,

        /**
         * Initialize chat with configuration
         */
        async initialize(config: ChatServiceConfig): Promise<void> {
            update(state => ({ ...state, isConnecting: true, error: null }));

            try {
                // Create chat service
                chatService = createChatService(config);

                // Initialize session
                const initResponse = await chatService.initialize();

                // Setup event handlers
                const handlers: ChatEventHandlers = {
                    onMessage: (message) => {
                        update(state => {
                            const messageExists = state.messages.some(m => m.id === message.id);
                            if (messageExists) return state;

                            const newMessages = [...state.messages, message];
                            const unreadCount = message.sender_type !== 'customer' && !message.read_at
                                ? state.unreadCount + 1
                                : state.unreadCount;

                            return {
                                ...state,
                                messages: newMessages,
                                unreadCount
                            };
                        });
                    },

                    onTyping: (isTyping, agentName) => {
                        update(state => ({
                            ...state,
                            isTyping,
                            typingAgentName: agentName || null
                        }));
                    },

                    onAgentStatusChange: (status) => {
                        update(state => ({
                            ...state,
                            agentStatus: status
                        }));
                    },

                    onQueueUpdate: (position) => {
                        update(state => ({
                            ...state,
                            queuePosition: position
                        }));
                    },

                    onSessionUpdate: (session) => {
                        update(state => ({
                            ...state,
                            session
                        }));
                    },

                    onError: (error) => {
                        update(state => ({
                            ...state,
                            error: error.message,
                            isConnecting: false
                        }));
                    },

                    onConnect: () => {
                        update(state => ({
                            ...state,
                            isConnected: true,
                            isConnecting: false,
                            error: null
                        }));
                    },

                    onDisconnect: () => {
                        update(state => ({
                            ...state,
                            isConnected: false
                        }));
                    },

                    onReconnect: () => {
                        update(state => ({
                            ...state,
                            isConnecting: true
                        }));
                    }
                };

                // Connect WebSocket
                chatService.connect(initResponse.session.id, handlers);

                // Update state
                update(state => ({
                    ...state,
                    session: initResponse.session,
                    messages: initResponse.messages,
                    agentStatus: initResponse.agentStatus,
                    queuePosition: initResponse.queuePosition || null,
                    isConnecting: false,
                    unreadCount: initResponse.messages.filter(
                        m => m.sender_type !== 'customer' && !m.read_at
                    ).length
                }));

            } catch (error) {
                console.error('Failed to initialize chat:', error);
                update(state => ({
                    ...state,
                    error: error instanceof Error ? error.message : 'Failed to initialize chat',
                    isConnecting: false
                }));
                throw error;
            }
        },

        /**
         * Send a text message
         */
        async sendMessage(content: string): Promise<void> {
            const state = get({ subscribe });
            
            if (!chatService || !state.session) {
                throw new Error('Chat not initialized');
            }

            if (!content.trim()) {
                return;
            }

            update(s => ({ ...s, isLoading: true, error: null }));

            try {
                // Create optimistic message
                const tempMessage: ChatMessage = {
                    id: `temp-${Date.now()}`,
                    session_id: state.session.id,
                    sender_type: 'customer',
                    sender_id: null,
                    sender_name: 'You',
                    message_type: 'text',
                    content: content.trim(),
                    product_id: null,
                    created_at: new Date().toISOString(),
                    read_at: null
                };

                // Add optimistic message
                update(s => ({
                    ...s,
                    messages: [...s.messages, tempMessage]
                }));

                // Send message
                const message = await chatService.sendMessage({
                    sessionId: state.session.id,
                    messageType: 'text',
                    content: content.trim()
                });

                // Replace temp message with real one
                update(s => ({
                    ...s,
                    messages: s.messages.map(m => m.id === tempMessage.id ? message : m),
                    isLoading: false
                }));

            } catch (error) {
                console.error('Failed to send message:', error);
                
                // Remove temp message on error
                update(s => ({
                    ...s,
                    messages: s.messages.filter(m => !m.id.startsWith('temp-')),
                    error: error instanceof Error ? error.message : 'Failed to send message',
                    isLoading: false
                }));
                
                throw error;
            }
        },

        /**
         * Upload and send file
         */
        async sendFile(file: File, fileType: 'image' | 'pdf' | 'voice'): Promise<void> {
            const state = get({ subscribe });
            
            if (!chatService || !state.session) {
                throw new Error('Chat not initialized');
            }

            update(s => ({ ...s, isLoading: true, error: null }));

            try {
                // Upload file
                const { url, attachmentId } = await chatService.uploadFile(
                    state.session.id,
                    file,
                    fileType
                );

                // Send message with attachment
                const message = await chatService.sendMessage({
                    sessionId: state.session.id,
                    messageType: fileType,
                    content: url,
                    attachmentId
                });

                // Add message to state
                update(s => ({
                    ...s,
                    messages: [...s.messages, message],
                    isLoading: false
                }));

            } catch (error) {
                console.error('Failed to send file:', error);
                update(s => ({
                    ...s,
                    error: error instanceof Error ? error.message : 'Failed to send file',
                    isLoading: false
                }));
                throw error;
            }
        },

        /**
         * Share a product in chat
         */
        async shareProduct(productId: string, productName: string): Promise<void> {
            const state = get({ subscribe });
            
            if (!chatService || !state.session) {
                throw new Error('Chat not initialized');
            }

            update(s => ({ ...s, isLoading: true, error: null }));

            try {
                const message = await chatService.sendMessage({
                    sessionId: state.session.id,
                    messageType: 'product_card',
                    content: `Shared product: ${productName}`,
                    productId
                });

                update(s => ({
                    ...s,
                    messages: [...s.messages, message],
                    isLoading: false
                }));

            } catch (error) {
                console.error('Failed to share product:', error);
                update(s => ({
                    ...s,
                    error: error instanceof Error ? error.message : 'Failed to share product',
                    isLoading: false
                }));
                throw error;
            }
        },

        /**
         * Send typing indicator
         */
        sendTyping(isTyping: boolean): void {
            const state = get({ subscribe });
            
            if (chatService && state.session) {
                chatService.sendTypingIndicator(state.session.id, isTyping);
            }
        },

        /**
         * Mark messages as read
         */
        async markAsRead(messageIds: string[]): Promise<void> {
            const state = get({ subscribe });
            
            if (!chatService || !state.session) {
                return;
            }

            try {
                await chatService.markMessagesAsRead(state.session.id, messageIds);

                update(s => ({
                    ...s,
                    messages: s.messages.map(m =>
                        messageIds.includes(m.id) ? { ...m, read_at: new Date().toISOString() } : m
                    ),
                    unreadCount: Math.max(0, s.unreadCount - messageIds.length)
                }));

            } catch (error) {
                console.error('Failed to mark messages as read:', error);
            }
        },

        /**
         * Load more chat history
         */
        async loadHistory(limit = 50): Promise<void> {
            const state = get({ subscribe });
            
            if (!chatService || !state.session || state.messages.length === 0) {
                return;
            }

            update(s => ({ ...s, isLoading: true }));

            try {
                const oldestMessage = state.messages[0];
                const messages = await chatService.getChatHistory(
                    state.session.id,
                    limit,
                    oldestMessage.created_at
                );

                update(s => ({
                    ...s,
                    messages: [...messages, ...s.messages],
                    isLoading: false
                }));

            } catch (error) {
                console.error('Failed to load history:', error);
                update(s => ({
                    ...s,
                    error: error instanceof Error ? error.message : 'Failed to load history',
                    isLoading: false
                }));
            }
        },

        /**
         * Toggle chat window
         */
        toggle(): void {
            update(state => ({
                ...state,
                isOpen: !state.isOpen
            }));
        },

        /**
         * Open chat window
         */
        open(): void {
            update(state => ({
                ...state,
                isOpen: true
            }));
        },

        /**
         * Close chat window
         */
        close(): void {
            update(state => ({
                ...state,
                isOpen: false
            }));
        },

        /**
         * End chat session and disconnect
         */
        async endSession(): Promise<void> {
            const state = get({ subscribe });
            
            if (!chatService || !state.session) {
                return;
            }

            try {
                await chatService.endSession(state.session.id);
                set(initialState);
                chatService = null;

            } catch (error) {
                console.error('Failed to end session:', error);
                throw error;
            }
        },

        /**
         * Clear error
         */
        clearError(): void {
            update(state => ({
                ...state,
                error: null
            }));
        },

        /**
         * Reset store to initial state
         */
        reset(): void {
            if (chatService) {
                chatService.disconnect();
                chatService = null;
            }
            set(initialState);
        },

        /**
         * Get chat service instance
         */
        getService(): ChatService | null {
            return chatService;
        }
    };
}

// Export the chat store
export const chatStore = createChatStore();

// Derived stores for convenience
export const chatMessages: Readable<ChatMessage[]> = derived(
    chatStore,
    $chat => $chat.messages
);

export const chatSession: Readable<ChatSession | null> = derived(
    chatStore,
    $chat => $chat.session
);

export const isChatOpen: Readable<boolean> = derived(
    chatStore,
    $chat => $chat.isOpen
);

export const isChatConnected: Readable<boolean> = derived(
    chatStore,
    $chat => $chat.isConnected
);

export const chatUnreadCount: Readable<number> = derived(
    chatStore,
    $chat => $chat.unreadCount
);

export const chatAgentStatus: Readable<'online' | 'offline' | 'busy'> = derived(
    chatStore,
    $chat => $chat.agentStatus
);

export const chatError: Readable<string | null> = derived(
    chatStore,
    $chat => $chat.error
);
