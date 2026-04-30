<script lang="ts">
    import { Chat } from '@ai-sdk/svelte';
    import { HttpChatTransport } from 'ai';
    import { Sparkles, Send, Loader2, BarChart3, TrendingUp, AlertCircle, Bot, User, ArrowRight } from 'lucide-svelte';
    import { fade, fly } from 'svelte/transition';
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';

    let input = $state('');
    let tenantId = $state('');
    let branchId = $state('');
    let staffId = $state('');
    
    const chat = new Chat({
        transport: new HttpChatTransport({
            api: '/api/chat/ai',
            body: () => ({
                tenantId,
                branchId,
                staffId
            })
        }),
        initialMessages: [
            { id: 'welcome', role: 'assistant', content: 'Hello! I am your Kemani POS Assistant. How can I help you analyze your business today? I can provide sales summaries, stock alerts, and growth tips.' }
        ]
    });

    onMount(async () => {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) return;
        
        staffId = session.user.id;
        const { data: profile } = await supabase
            .from('users')
            .select('tenant_id, branch_id')
            .eq('id', staffId)
            .single();
            
        if (profile) {
            tenantId = profile.tenant_id;
            branchId = profile.branch_id;
        }
    });

    let chatContainer: HTMLElement;
    
    // Auto-scroll to bottom
    $effect(() => {
        if (chat.messages.length > 0) {
            setTimeout(() => {
                if (chatContainer) {
                    chatContainer.scrollTop = chatContainer.scrollHeight;
                }
            }, 50);
        }
    });

    const suggestions = [
        "What are today's total sales?",
        "Show me low stock alerts",
        "Which products are best sellers?",
        "How can I grow my business?"
    ];

    function applySuggestion(text: string) {
        input = text;
    }

    async function handleSubmit(e: Event) {
        e.preventDefault();
        if (!input.trim() || chat.status !== 'ready') return;
        
        const message = input;
        input = ''; // Clear input immediately for better UX
        
        try {
            await chat.sendMessage({ text: message });
        } catch (err) {
            console.error('Failed to send message:', err);
            // Input is already cleared, but we could restore it on error if desired
        }
    }
</script>

<div class="flex flex-col h-full bg-slate-50 overflow-hidden">
    <!-- Header -->
    <header class="bg-white border-b px-6 py-4 flex items-center justify-between shrink-0 shadow-sm">
        <div class="flex items-center gap-3">
            <div class="p-2 bg-indigo-600 rounded-xl text-white shadow-lg shadow-indigo-100">
                <Sparkles class="h-5 w-5" />
            </div>
            <div>
                <h1 class="text-lg font-bold text-slate-900">AI Business Assistant</h1>
                <p class="text-xs text-slate-500 font-medium flex items-center gap-1">
                    <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
                    Ready for analytics
                </p>
            </div>
        </div>
        <div class="flex items-center gap-4 text-xs font-semibold text-slate-400">
            <span class="px-2 py-1 bg-slate-100 rounded-md">Gemini 1.5 Flash</span>
        </div>
    </header>

    <!-- Chat Area -->
    <main 
        bind:this={chatContainer}
        class="flex-1 overflow-y-auto p-6 space-y-6 scroll-smooth"
    >
        {#each chat.messages as message}
            <div 
                class="flex {message.role === 'user' ? 'justify-end' : 'justify-start'}"
                in:fly={{ y: 10, duration: 300 }}
            >
                <div class="flex gap-3 max-w-[80%] {message.role === 'user' ? 'flex-row-reverse' : ''}">
                    <div class="h-8 w-8 rounded-full flex items-center justify-center shrink-0 shadow-sm
                        {message.role === 'user' ? 'bg-indigo-100 text-indigo-600' : 'bg-slate-900 text-white'}">
                        {#if message.role === 'user'}
                            <User class="h-4 w-4" />
                        {:else}
                            <Bot class="h-4 w-4" />
                        {/if}
                    </div>
                    
                    <div class="space-y-2">
                        <div class="p-4 rounded-2xl shadow-sm text-sm leading-relaxed
                            {message.role === 'user' 
                                ? 'bg-indigo-600 text-white rounded-tr-none' 
                                : 'bg-white border border-slate-100 text-slate-700 rounded-tl-none'}">
                            {message.content}
                            
                            {#if message.toolInvocations}
                                <div class="mt-3 space-y-2 pt-3 border-t border-slate-100/10">
                                    {#each message.toolInvocations as tool}
                                        <div class="flex items-center gap-2 text-[10px] font-bold uppercase tracking-wider opacity-60">
                                            <Loader2 class="h-3 w-3 animate-spin" />
                                            Running {tool.toolName}...
                                        </div>
                                    {/each}
                                </div>
                            {/if}
                        </div>
                    </div>
                </div>
            </div>
        {/each}

        {#if chat.status !== 'ready' && chat.messages[chat.messages.length - 1]?.role === 'user'}
            <div class="flex justify-start" in:fade>
                <div class="flex gap-3">
                    <div class="h-8 w-8 rounded-full bg-slate-900 text-white flex items-center justify-center">
                        <Bot class="h-4 w-4 animate-pulse" />
                    </div>
                    <div class="bg-white border border-slate-100 p-4 rounded-2xl rounded-tl-none shadow-sm flex items-center gap-2">
                        <div class="flex gap-1">
                            <span class="w-1.5 h-1.5 bg-slate-300 rounded-full animate-bounce"></span>
                            <span class="w-1.5 h-1.5 bg-slate-300 rounded-full animate-bounce [animation-delay:0.2s]"></span>
                            <span class="w-1.5 h-1.5 bg-slate-300 rounded-full animate-bounce [animation-delay:0.4s]"></span>
                        </div>
                    </div>
                </div>
            </div>
        {/if}
    </main>

    <!-- Footer -->
    <footer class="p-6 bg-white border-t shrink-0">
        {#if chat.messages.length < 3}
            <div class="flex flex-wrap gap-2 mb-4" in:fade>
                {#each suggestions as suggestion}
                    <button 
                        onclick={() => applySuggestion(suggestion)}
                        class="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-full text-xs font-medium text-slate-600 hover:bg-indigo-50 hover:border-indigo-200 hover:text-indigo-600 transition-all flex items-center gap-2 group"
                    >
                        {suggestion}
                        <ArrowRight class="h-3 w-3 opacity-0 group-hover:opacity-100 transition-all" />
                    </button>
                {/each}
            </div>
        {/if}

        <form 
            onsubmit={handleSubmit}
            class="relative flex items-center gap-2"
        >
            <input 
                bind:value={input}
                placeholder="Ask me anything about your business..."
                class="flex-1 bg-slate-100 border-none rounded-2xl px-5 py-3.5 text-sm focus:ring-2 focus:ring-indigo-500 transition-all"
            />
            <button 
                type="submit"
                disabled={chat.status !== 'ready' || !input.trim()}
                class="bg-slate-900 text-white p-3.5 rounded-2xl hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg"
            >
                {#if chat.status !== 'ready'}
                    <Loader2 class="h-5 w-5 animate-spin" />
                {:else}
                    <Send class="h-5 w-5" />
                {/if}
            </button>
        </form>
        <p class="mt-3 text-[10px] text-center text-slate-400 font-medium uppercase tracking-widest">
            Powered by Kemani Intelligence • AI can make mistakes
        </p>
    </footer>
</div>

<style>
    /* Custom scrollbar */
    main::-webkit-scrollbar {
        width: 4px;
    }
    main::-webkit-scrollbar-track {
        background: transparent;
    }
    main::-webkit-scrollbar-thumb {
        background: #e2e8f0;
        border-radius: 10px;
    }
    main::-webkit-scrollbar-thumb:hover {
        background: #cbd5e1;
    }
</style>
