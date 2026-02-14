<script lang="ts">
    import { onMount, tick } from "svelte";
    import { user } from "$lib/stores/user";
    import MessageCircle from "lucide-svelte/icons/message-circle";
    import X from "lucide-svelte/icons/x";
    import Send from "lucide-svelte/icons/send";
    import Paperclip from "lucide-svelte/icons/paperclip";
    import Mic from "lucide-svelte/icons/mic";

    let isOpen = $state(false);
    let message = $state("");
    let messages = $state<
        {
            id: string;
            text: string;
            sender: "user" | "agent";
            timestamp: number;
        }[]
    >([]);
    let chatWindow: HTMLDivElement;

    function toggleChat() {
        isOpen = !isOpen;
        if (isOpen) scrollToBottom();
    }

    function scrollToBottom() {
        tick().then(() => {
            if (chatWindow) chatWindow.scrollTop = chatWindow.scrollHeight;
        });
    }

    async function sendMessage() {
        if (!message.trim()) return;

        // Add user message
        const userMsg = {
            id: Date.now().toString(),
            text: message,
            sender: "user" as const,
            timestamp: Date.now(),
        };
        messages = [...messages, userMsg];
        message = "";
        scrollToBottom();

        // Simulate AI response
        setTimeout(() => {
            const aiMsg = {
                id: (Date.now() + 1).toString(),
                text: "Thanks for reaching out! How can I help you today?",
                sender: "agent" as const,
                timestamp: Date.now(),
            };
            messages = [...messages, aiMsg];
            scrollToBottom();
        }, 1000);
    }
</script>

<div class="fixed bottom-6 right-6 z-50 flex flex-col items-end">
    {#if isOpen}
        <div
            class="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl border dark:border-gray-700 w-80 sm:w-96 h-[500px] flex flex-col mb-4 transition-all overflow-hidden"
        >
            <!-- Header -->
            <div
                class="bg-emerald-600 p-4 flex justify-between items-center text-white"
            >
                <div>
                    <h3 class="font-bold">Kemani Support</h3>
                    <p class="text-xs opacity-90">Avg. response time: 2 mins</p>
                </div>
                <button
                    onclick={toggleChat}
                    class="hover:bg-white/20 p-1 rounded-full transition"
                >
                    <X class="h-5 w-5" />
                </button>
            </div>

            <!-- Messages -->
            <div
                bind:this={chatWindow}
                class="flex-1 p-4 overflow-y-auto space-y-4 bg-gray-50 dark:bg-gray-900/50"
            >
                {#if messages.length === 0}
                    <div class="text-center text-gray-500 text-sm mt-10">
                        <p>👋 Hi there! How can we help you?</p>
                    </div>
                {/if}

                {#each messages as msg}
                    <div
                        class="flex {msg.sender === 'user'
                            ? 'justify-end'
                            : 'justify-start'}"
                    >
                        <div
                            class="max-w-[80%] p-3 rounded-xl text-sm {msg.sender ===
                            'user'
                                ? 'bg-emerald-600 text-white rounded-br-none'
                                : 'bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 shadow-sm rounded-bl-none'}"
                        >
                            {msg.text}
                        </div>
                    </div>
                {/each}
            </div>

            <!-- Input -->
            <div
                class="p-3 bg-white dark:bg-gray-800 border-t dark:border-gray-700"
            >
                <div
                    class="flex items-center gap-2 bg-gray-100 dark:bg-gray-900 rounded-full px-4 py-2"
                >
                    <input
                        type="text"
                        bind:value={message}
                        onkeydown={(e) => e.key === "Enter" && sendMessage()}
                        placeholder="Type a message..."
                        class="flex-1 bg-transparent border-none focus:ring-0 text-sm"
                    />
                    <button
                        class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                    >
                        <Paperclip class="h-4 w-4" />
                    </button>
                    {#if message.trim()}
                        <button
                            onclick={sendMessage}
                            class="text-emerald-600 hover:text-emerald-700"
                        >
                            <Send class="h-4 w-4" />
                        </button>
                    {:else}
                        <button
                            class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                        >
                            <Mic class="h-4 w-4" />
                        </button>
                    {/if}
                </div>
            </div>
        </div>
    {/if}

    <button
        onclick={toggleChat}
        class="bg-emerald-600 hover:bg-emerald-700 text-white p-4 rounded-full shadow-lg transition-transform hover:scale-105 active:scale-95 flex items-center justify-center"
    >
        <MessageCircle class="h-6 w-6" />
    </button>
</div>
