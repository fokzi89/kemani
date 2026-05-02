<script lang="ts">
    import { Chat } from '@ai-sdk/svelte';
    import { HttpChatTransport } from 'ai';
    import { Sparkles, Send, Loader2, Package, ShoppingBag, History, User, Bot, ArrowLeft, ArrowRight, X } from 'lucide-svelte';
    import { fade, fly, slide } from 'svelte/transition';
    import { page } from '$app/stores';
    import { isAuthModalOpen } from '$lib/stores/ui';
    import { authStore, currentUser } from '$lib/stores/auth';

    let loading = $state(true);

    let input = $state('');

    const chat = new Chat({
        transport: new HttpChatTransport({
            api: '/api/chat/ai',
            body: {
                tenantId: $page.data.storefront?.id,
                customerId: $page.data.session?.user?.id
            }
        }),
        initialMessages: [
            { id: 'welcome', role: 'assistant', content: 'Hi there! I am your AI personal shopper. I can help you find products, check your orders, or recommend something based on your style. How can I help today?' }
        ]
    });

    let chatContainer: HTMLElement;
    
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
        "What's new in store?",
        "Check my order status",
        "Recommend some products",
        "Find medicine for headache"
    ];

    function applySuggestion(text: string) {
        input = text;
    }

    async function handleSubmit(e: Event) {
        e.preventDefault();
        if (!input.trim() || chat.status !== 'ready') return;
        
        const message = input;
        input = ''; 
        
        try {
            await chat.sendMessage({ text: message });
        } catch (err) {
            console.error('Failed to send message:', err);
        }
    }

    $effect(() => {
        if (!$authStore.initialized) {
            loading = true;
            return;
        }
        loading = false;
        if (!$currentUser) {
            isAuthModalOpen.set(true);
        } else {
            // User is authenticated — ensure modal is closed
            isAuthModalOpen.set(false);
        }
    });
</script>

<div class="flex flex-col h-screen bg-[#fafafa] overflow-hidden">
    {#if loading}
        <div class="flex-1 flex flex-col items-center justify-center p-8 text-center" transition:fade>
            <Loader2 class="h-8 w-8 animate-spin text-black" />
            <p class="mt-4 text-[10px] font-black uppercase tracking-[0.3em] text-slate-400">Initializing AI Shopper</p>
        </div>
    {:else if !$currentUser}
        <div class="flex-1 flex flex-col items-center justify-center p-8 text-center" transition:fade>
            <div class="h-20 w-20 bg-white rounded-2xl shadow-xl flex items-center justify-center mb-6 animate-pulse border border-slate-100">
                <Bot class="h-10 w-10 text-slate-200" />
            </div>
            <h2 class="text-sm font-black text-slate-900 uppercase tracking-[0.2em] mb-2">Authentication Required</h2>
            <p class="text-[10px] text-slate-400 font-bold uppercase tracking-widest max-w-[200px]">Please sign in to interact with your personal AI shopper.</p>
        </div>
    {:else}
        <!-- Header -->
        <header class="bg-white/80 backdrop-blur-md border-b px-4 py-3 flex items-center justify-between shrink-0 sticky top-0 z-50">
            <div class="flex items-center gap-3">
                <a href="/chat" class="p-2 hover:bg-slate-100 rounded-full transition-colors">
                    <ArrowLeft class="h-5 w-5 text-slate-600" />
                </a>
                <div class="flex items-center gap-2">
                    <div class="h-8 w-8 bg-black rounded-lg flex items-center justify-center text-white shadow-lg">
                        <Sparkles class="h-4 w-4" />
                    </div>
                    <div>
                        <h1 class="text-sm font-black uppercase tracking-tight text-slate-900">Personal AI Shopper</h1>
                        <div class="flex items-center gap-1">
                            <span class="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                            <span class="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Always Active</span>
                        </div>
                    </div>
                </div>
            </div>
            <button class="p-2 text-slate-400 hover:text-slate-900" onclick={() => window.history.back()}>
                <X class="h-5 w-5" />
            </button>
        </header>

        <!-- Chat Area -->
        <main 
            bind:this={chatContainer}
            class="flex-1 overflow-y-auto p-4 space-y-6 scroll-smooth"
        >
            {#each chat.messages as message}
                <div 
                    class="flex {message.role === 'user' ? 'justify-end' : 'justify-start'}"
                    in:fly={{ y: 10, duration: 300 }}
                >
                    <div class="flex gap-2.5 max-w-[85%] {message.role === 'user' ? 'flex-row-reverse' : ''}">
                        <div class="h-7 w-7 rounded-lg flex items-center justify-center shrink-0 mt-1
                            {message.role === 'user' ? 'bg-slate-200 text-slate-600' : 'bg-black text-white'}">
                            {#if message.role === 'user'}
                                <User class="h-3.5 w-3.5" />
                            {:else}
                                <Bot class="h-3.5 w-3.5" />
                            {/if}
                        </div>
                        
                        <div class="space-y-1">
                            <div class="p-3.5 rounded-2xl shadow-sm text-[13px] leading-relaxed
                                {message.role === 'user' 
                                    ? 'bg-black text-white rounded-tr-none font-medium' 
                                    : 'bg-white border border-slate-100 text-slate-700 rounded-tl-none font-medium'}">
                                {message.content}
                                
                                {#if message.toolInvocations}
                                    <div class="mt-2 space-y-2 pt-2 border-t border-slate-100">
                                        {#each message.toolInvocations as tool}
                                            <div class="flex items-center gap-2 text-[9px] font-bold uppercase tracking-wider text-slate-400">
                                                <Loader2 class="h-2.5 w-2.5 animate-spin" />
                                                {tool.toolName === 'search_products' ? 'Searching Inventory...' : 'Checking Data...'}
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
                    <div class="flex gap-2.5">
                        <div class="h-7 w-7 rounded-lg bg-black text-white flex items-center justify-center">
                            <Bot class="h-3.5 w-3.5 animate-pulse" />
                        </div>
                        <div class="bg-white border border-slate-100 p-3 rounded-2xl rounded-tl-none shadow-sm flex items-center gap-1.5">
                            <span class="w-1 h-1 bg-slate-300 rounded-full animate-bounce"></span>
                            <span class="w-1 h-1 bg-slate-300 rounded-full animate-bounce [animation-delay:0.2s]"></span>
                            <span class="w-1 h-1 bg-slate-300 rounded-full animate-bounce [animation-delay:0.4s]"></span>
                        </div>
                    </div>
                </div>
            {/if}
        </main>

        <!-- Footer -->
        <footer class="p-4 bg-white border-t shrink-0 pb-8">
            {#if chat.messages.length < 3}
                <div class="flex gap-2 overflow-x-auto pb-3 no-scrollbar" in:slide>
                    {#each suggestions as suggestion}
                        <button 
                            onclick={() => applySuggestion(suggestion)}
                            class="whitespace-nowrap px-3.5 py-2 bg-slate-50 border border-slate-100 rounded-full text-[11px] font-black uppercase tracking-tight text-slate-600 hover:bg-black hover:text-white hover:border-black transition-all flex items-center gap-2 group"
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
                    placeholder="Ask your AI shopper..."
                    class="flex-1 bg-slate-100 border-none rounded-2xl px-4 py-3 text-sm font-medium focus:ring-1 focus:ring-black transition-all"
                />
                <button 
                    type="submit"
                    disabled={chat.status !== 'ready' || !input.trim()}
                    class="bg-black text-white p-3 rounded-xl hover:opacity-90 disabled:opacity-30 disabled:cursor-not-allowed transition-all shadow-md"
                >
                    {#if chat.status !== 'ready'}
                        <Loader2 class="h-4 w-4 animate-spin" />
                    {:else}
                        <Send class="h-4 w-4" />
                    {/if}
                </button>
            </form>
        </footer>
    {/if}
</div>

<style>
    .no-scrollbar::-webkit-scrollbar {
        display: none;
    }
    .no-scrollbar {
        -ms-overflow-style: none;
        scrollbar-width: none;
    }
</style>
