// This service would handle Supabase Realtime connections
// and AI Agent interaction

export interface ChatMessage {
    id: string;
    text: string;
    sender: 'user' | 'agent';
    timestamp: number;
    attachments?: any[];
}

export class ChatService {
    private listeners: ((msg: ChatMessage) => void)[] = [];

    constructor() {
        // Initialize Supabase client here
    }

    subscribe(callback: (msg: ChatMessage) => void) {
        this.listeners.push(callback);
        return () => {
            this.listeners = this.listeners.filter(l => l !== callback);
        };
    }

    async sendMessage(text: string) {
        // 1. Save to Supabase
        // 2. Trigger AI Agent if no human available

        // Simulate echo/AI response for demo
        if (text.toLowerCase().includes('help')) {
            setTimeout(() => {
                this.notify({
                    id: Date.now().toString(),
                    text: "I can specificially help with orders, products, or general inquiries. What do you need?",
                    sender: 'agent',
                    timestamp: Date.now()
                });
            }, 1500);
        }
    }

    private notify(msg: ChatMessage) {
        this.listeners.forEach(l => l(msg));
    }
}

export const chatService = new ChatService();
