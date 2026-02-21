/**
 * Chat Service Usage Examples
 * Demonstrates how to use the chat service and store in SvelteKit
 */

import { chatStore } from '$lib/stores/chat.js';
import { createChatService, validateChatFile, formatFileSize } from '$lib/services/chat.js';
import type { ChatServiceConfig } from '$lib/services/chat.js';
import type { PlanTier } from '$lib/types/supabase.js';

// Example 1: Initialize chat in a Svelte component
export const exampleInitializeChat = `
<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { chatStore, chatMessages, isChatOpen, chatUnreadCount } from '$lib/stores/chat';
    import type { PlanTier } from '$lib/types/supabase';

    // Props from parent or page data
    export let branchId: string;
    export let tenantId: string;
    export let planTier: PlanTier;
    export let customerId: string | null = null;
    export let sessionToken: string;

    onMount(async () => {
        try {
            await chatStore.initialize({
                branchId,
                tenantId,
                customerId,
                sessionToken,
                planTier
            });
        } catch (error) {
            console.error('Failed to initialize chat:', error);
        }
    });

    onDestroy(() => {
        chatStore.reset();
    });

    function handleOpenChat() {
        chatStore.open();
    }
</script>

<!-- Chat button with unread count -->
<button on:click={handleOpenChat}>
    Chat
    {#if $chatUnreadCount > 0}
        <span class="badge">{$chatUnreadCount}</span>
    {/if}
</button>

<!-- Display messages -->
{#if $isChatOpen}
    <div class="chat-window">
        {#each $chatMessages as message}
            <div class="message">
                {message.content}
            </div>
        {/each}
    </div>
{/if}
`;

// Example 2: Send text messages
export const exampleSendMessage = `
<script lang="ts">
    import { chatStore } from '$lib/stores/chat';

    let messageInput = '';
    let isSending = false;

    async function sendMessage() {
        if (!messageInput.trim() || isSending) return;

        const message = messageInput.trim();
        messageInput = '';
        isSending = true;

        try {
            await chatStore.sendMessage(message);
        } catch (error) {
            console.error('Failed to send message:', error);
            // Show error to user
        } finally {
            isSending = false;
        }
    }

    function handleKeyPress(event: KeyboardEvent) {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            sendMessage();
        }
    }
</script>

<textarea
    bind:value={messageInput}
    on:keypress={handleKeyPress}
    placeholder="Type your message..."
    disabled={isSending}
/>

<button on:click={sendMessage} disabled={!messageInput.trim() || isSending}>
    {isSending ? 'Sending...' : 'Send'}
</button>
`;

// Example 3: Upload and send files
export const exampleSendFile = `
<script lang="ts">
    import { chatStore } from '$lib/stores/chat';
    import { validateChatFile, formatFileSize } from '$lib/services/chat';

    let fileInput: HTMLInputElement;
    let isUploading = false;

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

        isUploading = true;

        try {
            await chatStore.sendFile(file, fileType);
            input.value = ''; // Reset input
        } catch (error) {
            console.error('Failed to upload file:', error);
            alert('Failed to upload file. Please try again.');
        } finally {
            isUploading = false;
        }
    }
</script>

<input
    bind:this={fileInput}
    type="file"
    accept="image/*,.pdf,audio/*"
    on:change={handleFileUpload}
    class="hidden"
/>

<button on:click={() => fileInput.click()} disabled={isUploading}>
    {isUploading ? 'Uploading...' : 'Attach File'}
</button>
`;

// Example 4: Voice recording
export const exampleVoiceRecording = `
<script lang="ts">
    import { chatStore } from '$lib/stores/chat';

    let isRecording = false;
    let mediaRecorder: MediaRecorder | null = null;
    let recordingChunks: Blob[] = [];

    async function startRecording() {
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
                const file = new File([audioBlob], \`voice-\${Date.now()}.webm\`, { type: 'audio/webm' });

                try {
                    await chatStore.sendFile(file, 'voice');
                } catch (error) {
                    console.error('Failed to send voice note:', error);
                }

                // Stop all tracks
                stream.getTracks().forEach(track => track.stop());
            };

            mediaRecorder.start();
            isRecording = true;

        } catch (error) {
            console.error('Failed to start recording:', error);
            alert('Failed to access microphone. Please check permissions.');
        }
    }

    function stopRecording() {
        if (mediaRecorder && mediaRecorder.state !== 'inactive') {
            mediaRecorder.stop();
            isRecording = false;
        }
    }
</script>

<button on:click={isRecording ? stopRecording : startRecording}>
    {isRecording ? 'Stop Recording' : 'Record Voice Note'}
</button>
`;

// Example 5: Share product in chat
export const exampleShareProduct = `
<script lang="ts">
    import { chatStore } from '$lib/stores/chat';
    import type { StorefrontProductWithCatalog } from '$lib/types/supabase';

    export let product: StorefrontProductWithCatalog;

    async function shareProduct() {
        try {
            await chatStore.shareProduct(product.id, product.name || 'Product');
            alert('Product shared in chat!');
        } catch (error) {
            console.error('Failed to share product:', error);
            alert('Failed to share product. Please try again.');
        }
    }
</script>

<button on:click={shareProduct}>
    Share in Chat
</button>
`;

// Example 6: Typing indicator
export const exampleTypingIndicator = `
<script lang="ts">
    import { chatStore } from '$lib/stores/chat';

    let messageInput = '';
    let typingTimeout: ReturnType<typeof setTimeout> | null = null;

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

    function handleBlur() {
        chatStore.sendTyping(false);
        if (typingTimeout) {
            clearTimeout(typingTimeout);
        }
    }
</script>

<textarea
    bind:value={messageInput}
    on:input={handleInput}
    on:blur={handleBlur}
    placeholder="Type your message..."
/>
`;

// Example 7: Mark messages as read
export const exampleMarkAsRead = `
<script lang="ts">
    import { onMount } from 'svelte';
    import { chatStore, chatMessages, isChatOpen } from '$lib/stores/chat';

    $: if ($isChatOpen && $chatMessages.length > 0) {
        markUnreadMessages();
    }

    function markUnreadMessages() {
        const unreadMessages = $chatMessages.filter(
            m => m.sender_type !== 'customer' && !m.read_at
        );

        if (unreadMessages.length > 0) {
            const messageIds = unreadMessages.map(m => m.id);
            chatStore.markAsRead(messageIds);
        }
    }
</script>
`;

// Example 8: Load chat history
export const exampleLoadHistory = `
<script lang="ts">
    import { chatStore, chatMessages } from '$lib/stores/chat';

    let isLoadingHistory = false;

    async function loadMoreHistory() {
        if (isLoadingHistory) return;

        isLoadingHistory = true;

        try {
            await chatStore.loadHistory(50);
        } catch (error) {
            console.error('Failed to load history:', error);
        } finally {
            isLoadingHistory = false;
        }
    }
</script>

<button on:click={loadMoreHistory} disabled={isLoadingHistory}>
    {isLoadingHistory ? 'Loading...' : 'Load More Messages'}
</button>
`;

// Example 9: Handle connection status
export const exampleConnectionStatus = `
<script lang="ts">
    import { chatStore } from '$lib/stores/chat';

    $: connectionState = $chatStore.isConnected ? 'connected' : 
                        $chatStore.isConnecting ? 'connecting' : 'disconnected';
</script>

<div class="connection-status">
    {#if connectionState === 'connected'}
        <span class="status-dot online"></span>
        Connected
    {:else if connectionState === 'connecting'}
        <span class="status-dot connecting"></span>
        Connecting...
    {:else}
        <span class="status-dot offline"></span>
        Disconnected
    {/if}
</div>
`;

// Example 10: Complete chat component integration
export const exampleCompleteChatComponent = `
<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { 
        chatStore, 
        chatMessages, 
        isChatOpen, 
        chatUnreadCount,
        chatAgentStatus,
        chatError 
    } from '$lib/stores/chat';
    import ChatWidget from '$lib/components/ChatWidget.svelte';
    import type { PlanTier } from '$lib/types/supabase';

    export let branchId: string;
    export let tenantId: string;
    export let planTier: PlanTier;
    export let customerId: string | null = null;
    export let sessionToken: string;

    let initialized = false;

    onMount(async () => {
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
    });

    onDestroy(() => {
        chatStore.reset();
    });

    function handleProductClick(event: CustomEvent) {
        const { productId } = event.detail;
        // Navigate to product page
        console.log('Navigate to product:', productId);
    }

    function handleUpgradePrompt(event: CustomEvent) {
        const { feature } = event.detail;
        // Show upgrade modal
        console.log('Upgrade needed for:', feature);
    }

    function handleError(event: CustomEvent) {
        console.error('Chat error:', event.detail.message);
    }
</script>

{#if initialized}
    <ChatWidget
        {branchId}
        {tenantId}
        {planTier}
        {customerId}
        {sessionToken}
        isOpen={$isChatOpen}
        on:product-click={handleProductClick}
        on:upgrade-prompt={handleUpgradePrompt}
        on:error={handleError}
        on:toggle={(e) => {
            if (e.detail.isOpen) {
                chatStore.open();
            } else {
                chatStore.close();
            }
        }}
    />
{/if}

{#if $chatError}
    <div class="error-toast">
        {$chatError}
        <button on:click={() => chatStore.clearError()}>Dismiss</button>
    </div>
{/if}
`;

// Example 11: Using chat service directly (without store)
export function exampleDirectServiceUsage() {
    console.log('=== DIRECT CHAT SERVICE USAGE ===');

    const config: ChatServiceConfig = {
        branchId: 'branch-123',
        tenantId: 'tenant-123',
        customerId: 'customer-123',
        sessionToken: 'session-token-123',
        planTier: 'pro' as PlanTier
    };

    const chatService = createChatService(config);

    // Initialize
    chatService.initialize().then(response => {
        console.log('Chat initialized:', response);

        // Connect WebSocket
        chatService.connect(response.session.id, {
            onMessage: (message) => {
                console.log('New message:', message);
            },
            onConnect: () => {
                console.log('WebSocket connected');
            },
            onDisconnect: () => {
                console.log('WebSocket disconnected');
            },
            onError: (error) => {
                console.error('WebSocket error:', error);
            }
        });

        // Send message
        chatService.sendMessage({
            sessionId: response.session.id,
            messageType: 'text',
            content: 'Hello from chat service!'
        }).then(message => {
            console.log('Message sent:', message);
        });
    });

    return chatService;
}

// Example 12: File validation
export function exampleFileValidation() {
    console.log('=== FILE VALIDATION EXAMPLES ===');

    // Valid image
    const imageFile = new File([''], 'test.jpg', { type: 'image/jpeg' });
    console.log('Image validation:', validateChatFile(imageFile));

    // Valid PDF
    const pdfFile = new File([''], 'document.pdf', { type: 'application/pdf' });
    console.log('PDF validation:', validateChatFile(pdfFile));

    // Valid audio
    const audioFile = new File([''], 'voice.mp3', { type: 'audio/mp3' });
    console.log('Audio validation:', validateChatFile(audioFile));

    // Invalid file type
    const invalidFile = new File([''], 'document.doc', { type: 'application/msword' });
    console.log('Invalid file validation:', validateChatFile(invalidFile));

    // File size formatting
    console.log('1024 bytes:', formatFileSize(1024));
    console.log('1MB:', formatFileSize(1024 * 1024));
    console.log('5.5MB:', formatFileSize(5.5 * 1024 * 1024));
}

// Best practices and tips
export const chatBestPractices = `
CHAT SERVICE BEST PRACTICES:

1. **Initialization**
   - Always initialize chat in onMount() lifecycle
   - Clean up in onDestroy() to prevent memory leaks
   - Handle initialization errors gracefully

2. **WebSocket Connection**
   - The service handles reconnection automatically
   - Monitor connection state for UI feedback
   - Implement offline message queuing if needed

3. **Message Handling**
   - Use optimistic updates for better UX
   - Handle message failures gracefully
   - Implement message retry logic for critical messages

4. **File Uploads**
   - Always validate files before upload
   - Show upload progress to users
   - Handle upload failures with retry option
   - Compress images before upload when possible

5. **Performance**
   - Lazy load chat history (pagination)
   - Implement virtual scrolling for long conversations
   - Debounce typing indicators
   - Cache messages in local storage for offline access

6. **Security**
   - Validate session tokens on server
   - Sanitize message content to prevent XSS
   - Implement rate limiting for message sending
   - Validate file types and sizes on server

7. **Accessibility**
   - Provide keyboard navigation
   - Add ARIA labels for screen readers
   - Ensure proper focus management
   - Support high contrast mode

8. **Error Handling**
   - Show user-friendly error messages
   - Log errors for debugging
   - Implement retry mechanisms
   - Provide fallback options

9. **Plan-Based Features**
   - Check plan tier before enabling features
   - Show upgrade prompts for premium features
   - Gracefully degrade for lower plans
   - Handle plan changes during active sessions

10. **Testing**
    - Test with slow network conditions
    - Test reconnection scenarios
    - Test with different file types and sizes
    - Test concurrent chat sessions
`;

// Run examples
export function runChatExamples() {
    console.log('=== CHAT SERVICE EXAMPLES ===');
    
    console.log('\n1. File Validation:');
    exampleFileValidation();
    
    console.log('\n2. Component Examples:');
    console.log('Initialize Chat:', exampleInitializeChat);
    console.log('Send Message:', exampleSendMessage);
    console.log('Send File:', exampleSendFile);
    console.log('Voice Recording:', exampleVoiceRecording);
    console.log('Share Product:', exampleShareProduct);
    
    console.log('\n3. Best Practices:');
    console.log(chatBestPractices);
}
