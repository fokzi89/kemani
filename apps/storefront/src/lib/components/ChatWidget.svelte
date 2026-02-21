<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { cn } from '$lib/utils.js';
    import { isFeatureEnabled } from '$lib/storefront/plans.js';
    import { chatStore, chatMessages, isChatOpen, chatUnreadCount, chatAgentStatus } from '$lib/stores/chat.js';
    import { validateChatFile } from '$lib/services/chat.js';
    import type { PlanTier, StorefrontProductWithCatalog } from '$lib/types/supabase.js';

    // Props
    export let branchId: string;
    export let tenantId: string;
    export let planTier: PlanTier = 'free';
    export let customerId: string | null = null;
    export let sessionToken: string;
    export let className: string | undefined = undefined;

    // Local state
    let messageInput = '';
    let fileInput: HTMLInputElement;
    let messagesContainer: HTMLDivElement;
    let isRecording = false;
    let mediaRecorder: MediaRecorder | null = null;
    let recordingChunks: Blob[] = [];
    let typingTimeout: ReturnType<typeof setTimeout> | null = null;
    let initialized = false;

    // Reactive statements
    $: canUseChat = isFeatureEnabled(planTier, 'liveChat');
    $: canUseAI = isFeatureEnabled(planTier, 'aiAgent');
    $: isOwnerOnlyChat = planTier === 'free';
    $: hasMultipleAgents = planTier === 'pro' || planTier === 'enterprise' || planTier === 'enterprise_custom';

    // Subscribe to store state
    $: state = $chatStore;
    $: messages = $chatMessages;
    $: isOpen = $isChatOpen;
    $: unreadCount = $chatUnreadCount;
    $: agentStatus = $chatAgentStatus;

    onMount(async () => {
        if (canUseChat) {
            await initializeChat();
        }
    });

    onDestroy(() => {
        chatStore.reset();
        if (typingTimeout) {
            clearTimeout(typingTimeout);
        }
    });

    async function initializeChat() {
        if (!canUseChat || initialized) return;

        try {
            await chatStore.initialize({
                branchId,
                tenantId,
                customerId,
                sessionToken,
                planTier
            });
            initialized = true;
        } catch (error) {
            console.error('Failed to initialize chat:', error);
        }
    }

    async function sendMessage() {
        if (!messageInput.trim() || state.isLoading) return;

        const message = messageInput.trim();
        messageInput = '';

        // Stop typing indicator
        chatStore.sendTyping(false);
        if (typingTimeout) {
            clearTimeout(typingTimeout);
        }

        try {
            await chatStore.sendMessage(message);
            scrollToBottom();
        } catch (error) {
            console.error('Failed to send message:', error);
        }
    }

    async function handleFileUpload(event: Event) {
        const input = event.target as HTMLInputElement;
        const file = input.files?.[0];
        if (!file) return;

        // Validate file
        const validation = validateChatFile(file);
        if (!validation.valid) {
            alert(validation.error);
            input.value = '';
            return;
        }

        // Determine file type
        let fileType: 'image' | 'pdf' | 'voice';
        if (file.type.startsWith('image/')) {
            fileType = 'image';
        } else if (file.type === 'application/pdf') {
            fileType = 'pdf';
        } else if (file.type.startsWith('audio/')) {
            fileType = 'voice';
        } else {
            alert('Unsupported file type');
            input.value = '';
            return;
        }

        try {
            await chatStore.sendFile(file, fileType);
            input.value = '';
            scrollToBottom();
        } catch (error) {
            console.error('Failed to upload file:', error);
            alert('Failed to upload file. Please try again.');
        }
    }

    async function startVoiceRecording() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            mediaRecorder = new MediaRecorder(stream);
            recordingChunks = [];

            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    recordingChunks.push(event.data);
                }
            };

            mediaRecorder.onstop = async () => {
                const audioBlob = new Blob(recordingChunks, { type: 'audio/webm' });
                
                if (audioBlob.size > 5 * 1024 * 1024) {
                    alert('Voice note too long. Maximum duration is 2 minutes.');
                    stream.getTracks().forEach(track => track.stop());
                    return;
                }

                const file = new File([audioBlob], `voice-${Date.now()}.webm`, { type: 'audio/webm' });
                
                try {
                    await chatStore.sendFile(file, 'voice');
                    scrollToBottom();
                } catch (error) {
                    console.error('Failed to send voice note:', error);
                    alert('Failed to send voice note. Please try again.');
                }

                stream.getTracks().forEach(track => track.stop());
            };

            mediaRecorder.start();
            isRecording = true;

        } catch (error) {
            console.error('Failed to start recording:', error);
            alert('Failed to access microphone. Please check permissions.');
        }
    }

    function stopVoiceRecording() {
        if (mediaRecorder && mediaRecorder.state !== 'inactive') {
            mediaRecorder.stop();
            isRecording = false;
        }
    }

    function scrollToBottom() {
        setTimeout(() => {
            if (messagesContainer) {
                messagesContainer.scrollTop = messagesContainer.scrollHeight;
            }
        }, 100);
    }

    function handleKeyPress(event: KeyboardEvent) {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            sendMessage();
        }
    }

    function handleInput() {
        // Send typing indicator
        chatStore.sendTyping(true);

        // Clear existing timeout
        if (typingTimeout) {
            clearTimeout(typingTimeout);
        }

        // Stop typing after 2 seconds of inactivity
        typingTimeout = setTimeout(() => {
            chatStore.sendTyping(false);
        }, 2000);
    }

    function toggleChat() {
        if (isOpen) {
            chatStore.close();
        } else {
            chatStore.open();
            if (!initialized) {
                initializeChat();
            }
            // Mark messages as read when opening
            setTimeout(() => {
                const unreadMessages = messages.filter(
                    m => m.sender_type !== 'customer' && !m.read_at
                );
                if (unreadMessages.length > 0) {
                    chatStore.markAsRead(unreadMessages.map(m => m.id));
                }
            }, 1000);
        }
    }

    function closeChat() {
        chatStore.close();
    }

    // Expose method for parent component to share products
    export async function shareProduct(product: StorefrontProductWithCatalog) {
        try {
            await chatStore.shareProduct(product.id, product.name || 'Product');
            chatStore.open();
            scrollToBottom();
        } catch (error) {
            console.error('Failed to share product:', error);
            alert('Failed to share product. Please try again.');
        }
    }

    // Auto-scroll on new messages
    $: if (messages.length > 0) {
        scrollToBottom();
    }
</script>

<!-- Chat Button (when closed) -->
{#if !isOpen}
    <button
        type="button"
        on:click={toggleChat}
        class={cn(
            "fixed bottom-4 right-4 z-50 flex h-14 w-14 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-lg transition-all hover:scale-105 hover:shadow-xl focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
            className
        )}
        aria-label="Open chat"
        title="Chat with us"
    >
        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 3.582-8 8-8s8 3.582 8 8z" />
        </svg>
        
        <!-- Notification dot for new messages -->
        {#if unreadCount > 0}
            <span class="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-xs text-white font-medium">
                {unreadCount > 9 ? '9+' : unreadCount}
            </span>
        {/if}
    </button>
{/if}

<!-- Chat Window (when open) -->
{#if isOpen}
    <div class={cn(
        "fixed bottom-4 right-4 z-50 flex h-96 w-80 flex-col overflow-hidden rounded-lg border bg-background shadow-xl",
        className
    )}>
        <!-- Header -->
        <div class="flex items-center justify-between border-b bg-primary px-4 py-3 text-primary-foreground">
            <div class="flex items-center gap-2">
                <div class={cn(
                    "h-2 w-2 rounded-full",
                    agentStatus === 'online' ? 'bg-green-400' :
                    agentStatus === 'busy' ? 'bg-yellow-400' : 'bg-gray-400'
                )}></div>
                <h3 class="font-medium">
                    {#if isOwnerOnlyChat}
                        Chat with Owner
                    {:else if agentStatus === 'online'}
                        Live Support
                    {:else if state.queuePosition}
                        Queue Position: {state.queuePosition}
                    {:else}
                        Support Chat
                    {/if}
                </h3>
            </div>
            <button
                type="button"
                on:click={closeChat}
                class="rounded p-1 hover:bg-primary-foreground/20 focus:outline-none focus:ring-2 focus:ring-primary-foreground"
                aria-label="Close chat"
            >
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
        </div>

        <!-- Messages -->
        <div
            bind:this={messagesContainer}
            class="flex-1 overflow-y-auto p-4 space-y-3"
        >
            {#if state.isConnecting}
                <div class="flex items-center justify-center py-8">
                    <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"></div>
                    <span class="ml-2 text-sm text-muted-foreground">Connecting...</span>
                </div>
            {:else if messages.length === 0}
                <div class="text-center py-8">
                    <div class="text-4xl mb-2">👋</div>
                    <p class="text-sm text-muted-foreground">
                        {#if isOwnerOnlyChat}
                            Start a conversation with the store owner
                        {:else}
                            How can we help you today?
                        {/if}
                    </p>
                </div>
            {:else}
                {#each messages as message (message.id)}
                    <div class={cn(
                        "flex",
                        message.sender_type === 'customer' ? 'justify-end' : 'justify-start'
                    )}>
                        <div class={cn(
                            "max-w-[80%] rounded-lg px-3 py-2 text-sm",
                            message.sender_type === 'customer'
                                ? 'bg-primary text-primary-foreground'
                                : 'bg-muted text-muted-foreground'
                        )}>
                            {#if message.message_type === 'text'}
                                <p class="whitespace-pre-wrap">{message.content}</p>
                            {:else if message.message_type === 'image'}
                                <img
                                    src={message.content}
                                    alt="Shared image"
                                    class="max-w-full rounded"
                                    loading="lazy"
                                />
                            {:else if message.message_type === 'voice'}
                                <audio controls class="max-w-full">
                                    <source src={message.content} type="audio/webm">
                                    <source src={message.content} type="audio/mp3">
                                    Your browser does not support audio playback.
                                </audio>
                            {:else if message.message_type === 'pdf'}
                                <a
                                    href={message.content}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="flex items-center gap-2 text-primary hover:underline"
                                >
                                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                    View PDF
                                </a>
                            {:else if message.message_type === 'product_card' && message.product_id}
                                <div class="border rounded p-2 bg-background">
                                    <p class="text-xs text-muted-foreground mb-1">Shared Product</p>
                                    <p class="font-medium">{message.content}</p>
                                    <a
                                        href="/products/{message.product_id}"
                                        class="text-xs text-primary hover:underline mt-1 inline-block"
                                    >
                                        View Product →
                                    </a>
                                </div>
                            {/if}
                            
                            <div class="flex items-center justify-between mt-1">
                                <span class="text-xs opacity-70">
                                    {new Date(message.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                </span>
                                {#if message.sender_type !== 'customer' && message.sender_name !== 'AI Assistant'}
                                    <span class="text-xs opacity-70">{message.sender_name}</span>
                                {/if}
                            </div>
                        </div>
                    </div>
                {/each}
            {/if}

            {#if state.isTyping}
                <div class="flex justify-start">
                    <div class="bg-muted text-muted-foreground rounded-lg px-3 py-2 text-sm">
                        <div class="flex items-center gap-1">
                            <div class="flex space-x-1">
                                <div class="h-2 w-2 bg-current rounded-full animate-bounce"></div>
                                <div class="h-2 w-2 bg-current rounded-full animate-bounce" style="animation-delay: 0.1s"></div>
                                <div class="h-2 w-2 bg-current rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                            </div>
                            <span class="ml-2">{state.typingAgentName || 'Agent'} is typing...</span>
                        </div>
                    </div>
                </div>
            {/if}
        </div>

        <!-- Input Area -->
        <div class="border-t p-3">
            {#if !canUseChat}
                <div class="text-center py-2">
                    <p class="text-xs text-muted-foreground mb-2">Chat is not available on your current plan</p>
                    <a
                        href="/pricing"
                        class="text-xs text-primary hover:underline"
                    >
                        Upgrade to enable chat
                    </a>
                </div>
            {:else if agentStatus === 'offline' && !canUseAI}
                <div class="text-center py-2">
                    <p class="text-xs text-muted-foreground">
                        {#if isOwnerOnlyChat}
                            Owner is currently offline
                        {:else}
                            All agents are currently offline
                        {/if}
                    </p>
                    <p class="text-xs text-muted-foreground mt-1">Please try again later</p>
                </div>
            {:else}
                <div class="flex items-end gap-2">
                    <div class="flex-1">
                        <textarea
                            bind:value={messageInput}
                            on:keypress={handleKeyPress}
                            on:input={handleInput}
                            placeholder="Type your message..."
                            rows="1"
                            class="w-full resize-none rounded border border-input bg-background px-3 py-2 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                            disabled={state.isLoading}
                        ></textarea>
                    </div>
                    
                    <!-- Attachment buttons -->
                    <div class="flex gap-1">
                        <!-- File upload -->
                        <button
                            type="button"
                            on:click={() => fileInput.click()}
                            disabled={state.isLoading}
                            class="rounded p-2 text-muted-foreground hover:text-foreground hover:bg-muted focus:outline-none focus:ring-2 focus:ring-primary disabled:opacity-50"
                            title="Attach file"
                        >
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                            </svg>
                        </button>

                        <!-- Voice recording -->
                        <button
                            type="button"
                            on:click={isRecording ? stopVoiceRecording : startVoiceRecording}
                            disabled={state.isLoading}
                            class={cn(
                                "rounded p-2 hover:bg-muted focus:outline-none focus:ring-2 focus:ring-primary disabled:opacity-50",
                                isRecording ? "text-red-500 bg-red-50" : "text-muted-foreground hover:text-foreground"
                            )}
                            title={isRecording ? "Stop recording" : "Record voice note"}
                        >
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                {#if isRecording}
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 10a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z" />
                                {:else}
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                                {/if}
                            </svg>
                        </button>

                        <!-- Send button -->
                        <button
                            type="button"
                            on:click={sendMessage}
                            disabled={!messageInput.trim() || state.isLoading}
                            class="rounded bg-primary p-2 text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary disabled:opacity-50"
                            title="Send message"
                        >
                            {#if state.isLoading}
                                <div class="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
                            {:else}
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                                </svg>
                            {/if}
                        </button>
                    </div>
                </div>

                <!-- Hidden file input -->
                <input
                    bind:this={fileInput}
                    type="file"
                    accept="image/*,.pdf,audio/*"
                    on:change={handleFileUpload}
                    class="hidden"
                />
            {/if}
        </div>
    </div>
{/if}