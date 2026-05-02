<script lang="ts">
	import { onMount, tick, onDestroy } from 'svelte';
	import { fade, fly, slide } from 'svelte/transition';
	import { 
		Send, MessageCircle, ShieldCheck, ArrowLeft, 
		Loader2, User, Phone, Video, Paperclip, Smile,
		Mic, X, Image as ImageIcon, FileText, ShoppingCart,
		Plus, CheckCircle2, ChevronRight, Package, Download, Play, Pause,
		Stethoscope, Sparkles, Headphones
	} from 'lucide-svelte';
	import { supabase } from '$lib/supabase';
	import { authStore, currentUser } from '$lib/stores/auth';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { activeConversationId, clearActiveConversation, setActiveConversation } from '$lib/stores/chat.store';
	import { get } from 'svelte/store';
	import { isAuthModalOpen } from '$lib/stores/ui';
	import ProductSelectionModal from '$lib/components/ProductSelectionModal.svelte';
	import ChatCartFlyout from '$lib/components/ChatCartFlyout.svelte';
	import SuggestedProductCard from '$lib/components/SuggestedProductCard.svelte';
	import { MarketplaceService } from '$lib/services/marketplace';
	import { cartStore } from '$lib/stores/cart.store';

	// 1. Core State
	let conversation = $state<any>(null);
	let messages = $state<any[]>([]);
	let newMessage = $state('');
	let loading = $state(true);
	let sending = $state(false);
	let messagesContainer = $state<HTMLElement | null>(null);
	let productInquiry = $state<any>(null);

	// 2. Navigation & Context
	const tenantId = $derived($page.data.storefront?.id);

	// 3. UI State
	let showProductModal = $state(false);
	let showCartFlyout = $state(false);
	let showMediaMenu = $state(false);
	let showAttachmentMenu = $state(false);
	let showEmojiMenu = $state(false);
	const popularEmojis = ['😊', '😂', '🥰', '👍', '🙏', '💊', '🏥', '👋', '💙', '✅'];
	
	// 4. Media Recording State
	let isRecording = $state(false);
	let mediaRecorder: MediaRecorder | null = null;
	let audioChunks: Blob[] = [];
	let recordingTime = $state(0);
	let recordingInterval: any = null;

	// 5. Typing Indicator State
	let isTyping = $state(false);
	let typingTimeout: any = null;
	let othersTyping = $state<string[]>([]);

	// 5. Activity Tracking
	async function logActivity(action: string) {
		if (!conversation) return;
		try {
			await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: $currentUser.id,
					sender_type: 'customer',
					message_text: `Activity: ${action}`,
					metadata: { 
						is_activity: true,
						pharmacist_only: true,
						is_visible_to_customer: false 
					}
				});
		} catch (err) {
			console.error('Failed to log activity:', err);
		}
	}

	onMount(async () => {
		const checkAuth = () => {
			if ($authStore.initialized) {
				if (!$currentUser) {
					loading = false;
					isAuthModalOpen.set(true);
				} else {
					initChat();
				}
			} else {
				setTimeout(checkAuth, 100);
			}
		};
		checkAuth();
	});

	onDestroy(() => {
		supabase.removeAllChannels();
		if (recordingInterval) clearInterval(recordingInterval);
	});

	async function initChat() {
		loading = true;
		try {
			let targetId = $page.url.searchParams.get('id') || get(activeConversationId);

			if (targetId) {
				const { data: existing } = await supabase
					.from('chat_conversations')
					.select('*')
					.eq('id', targetId)
					.maybeSingle();
				
				if (existing) {
					conversation = existing;
					setActiveConversation(existing.id);
				}
			}

			if (!conversation) {
				const { data: existing } = await supabase
					.from('chat_conversations')
					.select('*')
					.eq('customer_id', $currentUser.id)
					.eq('tenant_id', tenantId)
					.is('consultation_id', null)
					.order('started_at', { ascending: false })
					.limit(1)
					.maybeSingle();

				if (existing) {
					conversation = existing;
					setActiveConversation(existing.id);
				} else {
					const urlProductId = $page.url.searchParams.get('productId');
					const urlChatType = $page.url.searchParams.get('type') || (urlProductId ? 'Consultation' : 'Customer Support');
					const { data: created, error: createError } = await supabase
						.from('chat_conversations')
						.insert({
							customer_id: $currentUser.id,
							tenant_id: tenantId,
							status: 'active',
							chatType: urlChatType,
							customer_name: $currentUser?.user_metadata?.full_name || $currentUser?.email,
							customer_pic: $currentUser?.user_metadata?.avatar_url,
							isConsulatation: urlChatType === 'Consultation',
							metadata: { origin: 'storefront_fallback', productId: urlProductId }
						})
						.select().single();
					
					if (createError) throw createError;
					conversation = created;
					setActiveConversation(created.id);
				}
			}

			const urlProductId = $page.url.searchParams.get('productId') || conversation?.metadata?.productId;
			if (urlProductId) {
				const marketplaceService = new MarketplaceService(supabase);
				const { product, error: pError } = await marketplaceService.getMarketplaceProductById(urlProductId, tenantId);
				if (!pError) productInquiry = product;
			}

			const { data: msgData } = await supabase
				.from('chat_messages')
				.select('*')
				.eq('conversation_id', conversation.id)
				.order('created_at', { ascending: true });

			messages = msgData || [];
			setupSubscription();
		} finally {
			loading = false;
			await tick();
			scrollToBottom();
		}
	}

	async function endSession() {
		if (confirm('Are you sure you want to end this chat session?')) {
			clearActiveConversation();
			goto('/');
		}
	}

	function setupSubscription() {
		supabase.channel(`chat:${conversation.id}`)
			.on('postgres_changes', {
				event: 'INSERT',
				schema: 'public',
				table: 'chat_messages',
				filter: `conversation_id=eq.${conversation.id}`
			}, (payload) => {
				if (payload.eventType === 'INSERT' && !payload.new.metadata?.pharmacist_only) {
					if (!messages.find(m => m.id === payload.new.id)) {
						messages = [...messages, payload.new];
						scrollToBottom();
					}
				}
			})
			.subscribe();
	}

	async function sendMessage() {
		if (!newMessage.trim() || !conversation || sending) return;
		sending = true;
		const text = newMessage;
		newMessage = '';

		try {
			const { data: sent, error } = await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: $currentUser.id,
					sender_type: 'customer',
					message_text: text,
					message_type: 'text'
				})
				.select().single();

			if (sent) {
				messages = [...messages, sent];
				scrollToBottom();
			}
		} finally {
			sending = false;
		}
	}

	async function scrollToBottom() {
		await tick();
		if (messagesContainer) {
			messagesContainer.scrollTo({ top: messagesContainer.scrollHeight, behavior: 'smooth' });
		}
	}

	function formatTime(dateStr: string) {
		return new Date(dateStr).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
	}

	function openProductModal() { showProductModal = true; logActivity('Opened Product Selection Modal'); }
	function openCart() { showCartFlyout = true; logActivity('Opened Cart Flyout'); }
	function handleProductSelect(product: any) {
		cartStore.addItem({
			product_id: product.id,
			product_name: product.name,
			product_image: product.image_url,
			price: product.unit_price || product.price,
			quantity: 1,
			stock_available: product.stock_quantity
		}, tenantId);
		showProductModal = false;
		logActivity(`Added ${product.name} to bag`);
	}
</script>

<svelte:head>
	<title>Pharmacy Hub — Live Consultation</title>
</svelte:head>

<div class="chat-viewport">
	{#if loading}
		<div class="loading-overlay" transition:fade>
			<Loader2 class="h-8 w-8 animate-spin text-primary-600" />
			<p class="mt-4 text-xs font-black uppercase tracking-[0.3em] text-gray-400">Securing Clinical Line</p>
		</div>
	{:else if !$currentUser}
		<div class="flex-1 flex flex-col items-center justify-center p-8 text-center" transition:fade>
			<User class="h-10 w-10 text-gray-200 mb-6" />
			<h2 class="text-sm font-black text-gray-900 uppercase tracking-[0.2em] mb-2">Authentication Required</h2>
		</div>
	{:else}
		<header class="header">
			<div class="header-content">
				<div class="flex items-center gap-4">
					<a href="/" class="icon-btn"><ArrowLeft class="h-5 w-5" /></a>
					<div class="flex items-center gap-3">
						<div class="avatar-box bg-primary-50 text-primary-600"><Stethoscope class="h-5 w-5" /></div>
						<div>
							<h1 class="text-sm font-black text-gray-900 uppercase tracking-tight leading-none">Pharmacy Support</h1>
							<p class="text-[10px] font-bold text-emerald-600 uppercase tracking-widest mt-1">Online</p>
						</div>
					</div>
				</div>
				<button onclick={endSession} class="px-3 py-1.5 bg-rose-50 text-rose-600 text-[10px] font-black uppercase tracking-widest rounded-lg">End Session</button>
			</div>
			<div class="encryption-bar bg-gray-50 border-y py-1 flex items-center justify-center gap-2 text-[8px] font-bold text-gray-400 uppercase tracking-widest">
				<ShieldCheck class="h-3 w-3" /> End-to-end encrypted medical consultation
			</div>
		</header>

		<main class="messages-wrap" bind:this={messagesContainer}>
			<div class="messages-inner">
				{#each messages.filter(m => !m.metadata?.is_activity) as msg}
					{@const isMe = msg.sender_id === $currentUser?.id}
					<div class="msg-row {isMe ? 'me' : 'them'}" in:fly={{ y: 20 }}>
						<div class="msg-bubble shadow-sm">
							<p class="text-sm leading-relaxed">{msg.message_text}</p>
							<span class="msg-time">{formatTime(msg.created_at)}</span>
						</div>
					</div>
				{/each}
				
				{#if messages.length === 0}
					<div class="empty-state">
						<div class="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center text-gray-300 mb-4 border-2 border-gray-100 border-dashed">
							<MessageCircle class="h-8 w-8" />
						</div>
						<h3 class="text-xs font-black uppercase tracking-widest text-gray-900">Pharmacist Chat</h3>
						<p class="text-[10px] text-gray-400 max-w-[200px] mt-2 font-medium">Connect with our licensed pharmacists for clinical advice and prescription help.</p>
					</div>
				{/if}
			</div>
		</main>

		<footer class="interaction-center p-4">
			<div class="input-strip flex items-center gap-2 bg-white rounded-2xl p-2 border shadow-lg max-w-[800px] mx-auto relative">
				<div class="flex items-center gap-1">
					<button class="icon-btn" onclick={openProductModal} title="Share Product"><Package class="h-5 w-5" /></button>
					<div class="relative">
						<button class="icon-btn" onclick={() => showAttachmentMenu = !showAttachmentMenu} title="Add Attachment">
							<Plus class="h-5 w-5 {showAttachmentMenu ? 'rotate-45' : ''} transition-transform" />
						</button>

						{#if showAttachmentMenu}
							<div class="absolute bottom-full mb-4 left-0 bg-white border border-slate-100 rounded-2xl shadow-2xl p-2 min-w-[140px] flex flex-col gap-1 z-50" transition:fly={{ y: 10, duration: 200 }}>
								<button class="flex items-center gap-3 px-3 py-2.5 hover:bg-slate-50 rounded-xl transition-colors text-slate-700" onclick={() => { showAttachmentMenu = false; }}>
									<div class="w-8 h-8 bg-blue-50 text-blue-600 rounded-lg flex items-center justify-center"><ImageIcon class="h-4 w-4" /></div>
									<span class="text-[11px] font-black uppercase tracking-tight">Image</span>
								</button>
								<button class="flex items-center gap-3 px-3 py-2.5 hover:bg-slate-50 rounded-xl transition-colors text-slate-700" onclick={() => { showAttachmentMenu = false; }}>
									<div class="w-8 h-8 bg-rose-50 text-rose-600 rounded-lg flex items-center justify-center"><FileText class="h-4 w-4" /></div>
									<span class="text-[11px] font-black uppercase tracking-tight">PDF</span>
								</button>
							</div>
						{/if}
					</div>
				</div>
				<div class="flex-1 flex items-center px-4 gap-2">
					<input 
						type="text" 
						bind:value={newMessage} 
						onkeydown={(e) => e.key === 'Enter' && sendMessage()}
						placeholder="Message your pharmacist..." 
						class="flex-1 outline-none text-sm"
					/>
					<div class="relative">
						<button class="text-slate-400 hover:text-slate-600 transition-colors" onclick={() => showEmojiMenu = !showEmojiMenu}>
							<Smile class="h-5 w-5" />
						</button>
						{#if showEmojiMenu}
							<div class="absolute bottom-full mb-4 right-0 bg-white border border-slate-100 rounded-2xl shadow-2xl p-3 min-w-[200px] z-50" transition:fly={{ y: 10, duration: 200 }}>
								<div class="grid grid-cols-5 gap-2">
									{#each popularEmojis as emoji}
										<button class="text-xl hover:scale-125 transition-transform p-1" onclick={() => { newMessage += emoji; showEmojiMenu = false; }}>
											{emoji}
										</button>
									{/each}
								</div>
							</div>
						{/if}
					</div>
				</div>
				<button 
					class="send-btn {newMessage.trim() ? 'bg-black' : 'bg-black'} text-white p-3 rounded-xl transition-all" 
					onclick={newMessage.trim() ? sendMessage : () => {}}
					disabled={sending}
				>
					{#if newMessage.trim()}
						<Send class="h-4 w-4" />
					{:else}
						<Mic class="h-4 w-4" />
					{/if}
				</button>
			</div>
		</footer>
	{/if}
</div>

<ProductSelectionModal show={showProductModal} {tenantId} onClose={() => showProductModal = false} onSelect={handleProductSelect} />
<ChatCartFlyout show={showCartFlyout} onClose={() => showCartFlyout = false} />

<style>
	.chat-viewport { height: 100vh; display: flex; flex-direction: column; background: #fafafa; }
	.header { background: white; border-bottom: 1px solid #eee; }
	.header-content { height: 4rem; padding: 0 1rem; display: flex; align-items: center; justify-content: space-between; }
	.messages-wrap { flex: 1; overflow-y: auto; padding: 1.5rem; }
	.messages-inner { max-width: 800px; margin: 0 auto; display: flex; flex-direction: column; gap: 1rem; }
	.msg-row { display: flex; flex-direction: column; max-width: 80%; }
	.msg-row.me { align-self: flex-end; }
	.msg-row.them { align-self: flex-start; }
	.msg-bubble { padding: 0.75rem 1rem; border-radius: 1rem; background: white; border: 1px solid #f0f0f0; }
	.me .msg-bubble { background: black; color: white; border: none; border-bottom-right-radius: 0.25rem; }
	.msg-time { font-size: 8px; opacity: 0.4; margin-top: 4px; display: block; text-transform: uppercase; font-weight: 800; }
	.avatar-box { width: 2.25rem; height: 2.25rem; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
	.icon-btn { width: 2.5rem; height: 2.5rem; display: flex; align-items: center; justify-content: center; border-radius: 0.75rem; transition: background 0.2s; }
	.icon-btn:hover { background: #f3f4f6; }
	.loading-overlay { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
	.empty-state { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding-top: 5rem; opacity: 0.5; }
</style>
