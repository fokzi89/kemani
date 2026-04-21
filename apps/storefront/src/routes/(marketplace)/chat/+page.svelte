<script lang="ts">
	import { onMount, tick, onDestroy } from 'svelte';
	import { fade, fly, slide } from 'svelte/transition';
	import { 
		Send, MessageCircle, ShieldCheck, ArrowLeft, 
		Loader2, User, Phone, Video, Paperclip, Smile,
		Mic, X, Image as ImageIcon, FileText, ShoppingCart,
		Plus, CheckCircle2, ChevronRight, Package, Download, Play, Pause
	} from 'lucide-svelte';
	import { supabase } from '$lib/supabase';
	import { authStore, currentUser } from '$lib/stores/auth';
	import { page } from '$app/stores';
	import ProductSelectionModal from '$lib/components/ProductSelectionModal.svelte';
	import ChatCartFlyout from '$lib/components/ChatCartFlyout.svelte';
	import SuggestedProductCard from '$lib/components/SuggestedProductCard.svelte';

	// 1. Core State
	let conversation = $state<any>(null);
	let messages = $state<any[]>([]);
	let newMessage = $state('');
	let loading = $state(true);
	let sending = $state(false);
	let messagesContainer = $state<HTMLElement | null>(null);

	// 2. Navigation & Context
	const tenantId = $derived($page.data.storefront?.id);

	// 3. UI State
	let showProductModal = $state(false);
	let showCartFlyout = $state(false);
	let showMediaMenu = $state(false);
	
	// 4. Media Recording State
	let isRecording = $state(false);
	let mediaRecorder: MediaRecorder | null = null;
	let audioChunks: Blob[] = [];
	let recordingTime = $state(0);
	let recordingInterval: any = null;

	// 5. Activity Tracking
	async function logActivity(action: string) {
		if (!conversation) return;
		try {
			// This message is marked as pharmacist_only and is_activity
			// It will be hidden from the customer but visible to the pharmacist
			await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: $currentUser.id,
					sender_type: 'customer',
					message_text: `Activity: ${action}`,
					metadata: { 
						is_activity: true,
						pharmacist_only: true, // Only pharmacist sees this
						is_visible_to_customer: false 
					}
				});
		} catch (err) {
			console.error('Failed to log activity:', err);
		}
	}

	onMount(async () => {
		if (!$currentUser) return;
		await initChat();
	});

	onDestroy(() => {
		supabase.removeAllChannels();
		if (recordingInterval) clearInterval(recordingInterval);
	});

	async function initChat() {
		loading = true;
		try {
			const { data: existing } = await supabase
				.from('chat_conversations')
				.select('*')
				.eq('customer_id', $currentUser.id)
				.eq('tenant_id', tenantId)
				.is('consultation_id', null)
				.maybeSingle();

			if (existing) {
				conversation = existing;
			} else {
				const { data: created, error: createError } = await supabase
					.from('chat_conversations')
					.insert({
						customer_id: $currentUser.id,
						tenant_id: tenantId,
						status: 'active'
					})
					.select().single();
				
				if (createError) throw createError;
				conversation = created;
			}

			const { data: msgData, error: msgError } = await supabase
				.from('chat_messages')
				.select('*')
				.eq('conversation_id', conversation.id)
				.order('created_at', { ascending: true });

			if (msgError) throw msgError;
			messages = msgData || [];
			setupSubscription();
		} finally {
			loading = false;
			await tick();
			scrollToBottom();
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
				// Only display if it's not a pharmacist-only activity message
				if (!payload.new.metadata?.pharmacist_only) {
					messages = [...messages, payload.new];
					scrollToBottom();
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
					message_text: text
				})
				.select().single();

			if (error) throw error;
			if (sent) {
				messages = [...messages, sent];
				scrollToBottom();
			}
		} finally {
			sending = false;
		}
	}

	// 6. Media Handlers
	async function handleFileUpload(e: Event) {
		const target = e.target as HTMLInputElement;
		const file = target.files?.[0];
		if (!file) return;

		sending = true;
		showMediaMenu = false;

		try {
			const path = `chat/${conversation.id}/${Date.now()}_${file.name}`;
			const { error: uploadError } = await supabase.storage.from('chat-attachments').upload(path, file);
			if (uploadError) throw uploadError;

			const { data: { publicUrl } } = supabase.storage.from('chat-attachments').getPublicUrl(path);

			await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: $currentUser.id,
					sender_type: 'customer',
					message_text: `Sent an attachment: ${file.name}`,
					metadata: {
						attachments: [{ url: publicUrl, name: file.name, type: file.type }]
					}
				});
			// Subscription handles UI update
		} catch (err) {
			console.error('Upload failed:', err);
		} finally {
			sending = false;
		}
	}

	async function startRecording() {
		try {
			const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
			mediaRecorder = new MediaRecorder(stream);
			audioChunks = [];
			mediaRecorder.ondataavailable = e => audioChunks.push(e.data);
			mediaRecorder.onstop = async () => {
				const blob = new Blob(audioChunks, { type: 'audio/webm' });
				const file = new File([blob], `voice_${Date.now()}.webm`, { type: 'audio/webm' });
				
				sending = true;
				const path = `chat/${conversation.id}/${file.name}`;
				await supabase.storage.from('chat-attachments').upload(path, file);
				const { data: { publicUrl } } = supabase.storage.from('chat-attachments').getPublicUrl(path);

				await supabase.from('chat_messages').insert({
					conversation_id: conversation.id,
					sender_id: $currentUser.id,
					sender_type: 'customer',
					message_text: 'Sent a voice message',
					metadata: {
						attachments: [{ url: publicUrl, name: file.name, type: 'audio/webm' }]
					}
				});
				sending = false;
			};

			mediaRecorder.start();
			isRecording = true;
			recordingTime = 0;
			recordingInterval = setInterval(() => recordingTime++, 1000);
		} catch (err) {
			console.error('Mic access denied:', err);
		}
	}

	function stopRecording() {
		if (mediaRecorder) {
			mediaRecorder.stop();
			mediaRecorder.stream.getTracks().forEach(t => t.stop());
		}
		isRecording = false;
		clearInterval(recordingInterval);
	}

	// 7. Product / Cart Helpers
	function openProductModal() {
		showProductModal = true;
		logActivity('Opened Product Selection Modal');
	}

	function openCart() {
		showCartFlyout = true;
		logActivity('Opened Cart Flyout');
	}

	function handleProductSelect(product: any) {
		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
		cart.items.push({
			product_id: product.id,
			product_name: product.name,
			product_image: product.image_url,
			price: product.unit_price,
			quantity: 1
		});
		localStorage.setItem('cart', JSON.stringify(cart));
		window.dispatchEvent(new Event('cart-updated'));
		showProductModal = false;
		logActivity(`Added ${product.name} to bag`);
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
</script>

<svelte:head>
	<title>Pharmacy Hub — Live Consultation</title>
</svelte:head>

<div class="chat-viewport">
	{#if loading}
		<div class="loading-overlay" transition:fade>
			<div class="loader-wrap">
				<Loader2 class="h-8 w-8 animate-spin text-primary-600" />
				<div class="loader-pulse"></div>
			</div>
			<p class="mt-4 text-xs font-black uppercase tracking-[0.3em] text-gray-400">Securing Clinical Line</p>
		</div>
	{:else}
		<!-- HEADER: Focused & Clean -->
		<header class="header">
			<div class="header-content">
				<div class="flex items-center gap-4">
					<a href="/" class="icon-btn" title="Back to storefront">
						<ArrowLeft class="h-5 w-5" />
					</a>
					<div class="flex items-center gap-3">
						<div class="avatar-wrap">
							<div class="avatar-box">RX</div>
							<div class="status-dot"></div>
						</div>
						<div>
							<h1 class="text-sm font-black text-gray-900 uppercase tracking-tight leading-none">Pharmacy Support</h1>
							<p class="text-[10px] font-bold text-emerald-600 uppercase tracking-widest mt-1">Pharmacist is Online</p>
						</div>
					</div>
				</div>
				
				<div class="flex items-center gap-2">
					<button class="icon-btn text-gray-400 hover:text-primary-600"><Phone class="h-4 w-4" /></button>
					<button class="icon-btn text-gray-400 hover:text-primary-600"><Video class="h-4 w-4" /></button>
				</div>
			</div>
			<div class="encryption-bar">
				<ShieldCheck class="h-3 w-3" />
				<span>End-to-end encrypted medical consultation</span>
			</div>
		</header>

		<!-- MESSAGES AREA: Scrollable -->
		<main class="messages-wrap" bind:this={messagesContainer}>
			<div class="messages-inner">
				{#each messages as msg}
					{@const isMe = msg.sender_id === $currentUser?.id}
					<div class="msg-row {isMe ? 'me' : 'them'}" in:fly={{ y: 20 }}>
						<div class="msg-bubble shadow-sm">
							{#if msg.metadata?.attachments}
								<div class="msg-attachments">
									{#each msg.metadata.attachments as attr}
										{#if attr.type.startsWith('image/')}
											<div class="attachment-img">
												<img src={attr.url} alt="" />
												<a href={attr.url} target="_blank" class="download-link"><Download class="h-3 w-3" /></a>
											</div>
										{:else if attr.type.startsWith('audio/')}
											<div class="audio-msg">
												<audio src={attr.url} controls class="h-8"></audio>
											</div>
										{:else}
											<a href={attr.url} target="_blank" class="file-tag">
												<FileText class="h-4 w-4" />
												<span class="truncate">{attr.name}</span>
											</a>
										{/if}
									{/each}
								</div>
							{/if}
							{#if msg.metadata?.suggested_product}
								<SuggestedProductCard 
									productId={msg.metadata.suggested_product} 
									{tenantId} 
								/>
							{/if}
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
						<h3 class="text-xs font-black uppercase tracking-widest text-gray-900">Direct Consultation</h3>
						<p class="text-[10px] text-gray-400 max-w-[200px] mt-2 font-medium">Ask about dosages, side effects, or request a prescription refill.</p>
					</div>
				{/if}
			</div>
		</main>

		<!-- FIXED INTERACTION CENTER -->
		<footer class="interaction-center">
			<!-- Media Actions Flyout -->
			{#if showMediaMenu}
				<div class="media-menu shadow-2xl" transition:fly={{ y: 20 }}>
					<button class="media-option" onclick={() => document.getElementById('image-up')?.click()}>
						<div class="media-icon bg-blue-50 text-blue-600"><ImageIcon class="h-5 w-5" /></div>
						<span>Images</span>
					</button>
					<button class="media-option" onclick={() => document.getElementById('pdf-up')?.click()}>
						<div class="media-icon bg-amber-50 text-amber-600"><FileText class="h-5 w-5" /></div>
						<span>Medical PDF</span>
					</button>
					<input id="image-up" type="file" accept="image/*" class="hidden" onchange={handleFileUpload} />
					<input id="pdf-up" type="file" accept="application/pdf" class="hidden" onchange={handleFileUpload} />
				</div>
			{/if}

			<div class="input-strip shadow-2xl">
				<div class="flex items-center gap-1">
					<button 
						class="strip-btn {showMediaMenu ? 'rotate-45' : ''} transition-transform" 
						onclick={() => showMediaMenu = !showMediaMenu}
					>
						<Plus class="h-6 w-6" />
					</button>
					<button class="strip-btn" onclick={openProductModal} title="Product Discovery">
						<Package class="h-5 w-5" />
					</button>
				</div>

				<div class="input-well relative">
					{#if isRecording}
						<div class="recording-ui animate-in fade-in" in:fade>
							<div class="flex items-center gap-2">
								<div class="pulse-dot"></div>
								<span class="text-[10px] font-black uppercase tracking-widest text-red-600">Recording {recordingTime}s</span>
							</div>
							<button class="stop-btn" onclick={stopRecording}>SAVE</button>
						</div>
					{/if}
					<input 
						type="text" 
						bind:value={newMessage} 
						onkeydown={(e) => e.key === 'Enter' && sendMessage()}
						placeholder="Message your pharmacist..." 
						disabled={sending}
					/>
				</div>

				<div class="flex items-center gap-1">
					{#if !newMessage.trim()}
						<button 
							class="strip-btn {isRecording ? 'text-red-500 bg-red-50' : ''}" 
							onclick={isRecording ? stopRecording : startRecording}
						>
							<Mic class="h-5 w-5" />
						</button>
					{/if}
					<button class="strip-btn text-primary-600" onclick={openCart} title="View Bag">
						<ShoppingCart class="h-5 w-5" />
					</button>
					{#if newMessage.trim()}
						<button 
							class="send-btn" 
							onclick={sendMessage}
							disabled={sending}
						>
							{#if sending}<Loader2 class="h-4 w-4 animate-spin" />{:else}<Send class="h-4 w-4" />{/if}
						</button>
					{/if}
				</div>
			</div>
		</footer>
	{/if}
</div>

<ProductSelectionModal 
	show={showProductModal} 
	{tenantId}
	onClose={() => showProductModal = false}
	onSelect={handleProductSelect}
/>

<ChatCartFlyout 
	show={showCartFlyout}
	onClose={() => showCartFlyout = false}
/>

<style>
	:root {
		--primary: #4f46e5;
		--bg: #faf9f6;
	}

	.chat-viewport {
		height: 100vh;
		display: flex;
		flex-direction: column;
		background: var(--bg);
		overflow: hidden;
		font-family: 'Inter', sans-serif;
	}

	/* Loader */
	.loading-overlay { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; }
	.loader-wrap { position: relative; }
	.loader-pulse { 
		position: absolute; inset: -4px; border: 2px solid var(--primary); 
		border-radius: 50%; opacity: 0.2; animation: ping 2s cubic-bezier(0,0,0.2,1) infinite; 
	}

	/* Header */
	.header { background: white; border-bottom: 1px solid #f3f4f6; z-index: 50; }
	.header-content { height: 4rem; padding: 0 1.5rem; display: flex; align-items: center; justify-content: space-between; }
	.encryption-bar { 
		display: flex; align-items: center; justify-content: center; gap: 4px; text-transform: uppercase; letter-spacing: 0.05em;
	}

	/* Messages */
	.messages-wrap { flex: 1; overflow-y: auto; padding: 1.5rem; scroll-behavior: smooth; }
	.messages-inner { max-width: 800px; margin: 0 auto; display: flex; flex-direction: column; gap: 1.5rem; }
	
	.msg-row { display: flex; flex-direction: column; max-width: 85%; }
	.msg-row.me { align-self: flex-end; }
	.msg-row.them { align-self: flex-start; }

	.msg-bubble { 
		padding: 0.75rem 1rem; border-radius: 1.25rem; background: white; border: 1px solid #f3f4f6;
		position: relative;
	}
	.me .msg-bubble { background: black; color: white; border: none; border-bottom-right-radius: 0.25rem; }
	.them .msg-bubble { border-bottom-left-radius: 0.25rem; }

	.msg-time { display: block; font-size: 8px; font-weight: 700; opacity: 0.4; margin-top: 6px; text-transform: uppercase; }
	.me .msg-time { text-align: right; color: white; opacity: 0.6; }

	.empty-state { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding-top: 5rem; opacity: 0.5; }

	/* Attachments */
	.msg-attachments { margin-bottom: 0.5rem; display: flex; flex-direction: column; gap: 4px; }
	.attachment-img { position: relative; border-radius: 0.75rem; overflow: hidden; }
	.attachment-img img { max-height: 200px; width: 100%; object-fit: cover; }
	.download-link { position: absolute; bottom: 8px; right: 8px; padding: 4px; background: black/40; color: white; border-radius: 4px; }
	
	.file-tag { 
		display: flex; align-items: center; gap: 8px; padding: 8px; background: #f9fafb; border-radius: 8px;
		font-size: 11px; font-weight: 600; text-decoration: none; color: #1f2937;
	}
	.me .file-tag { background: white/10; color: white; }

	/* Interaction Center */
	.interaction-center { 
		padding: 1.5rem; background: linear-gradient(to top, var(--bg), transparent); 
		position: relative; z-index: 60;
	}
	.input-strip { 
		max-width: 800px; margin: 0 auto; background: white; height: 3.5rem; 
		border-radius: 1.5rem; display: flex; align-items: center; padding: 0 0.5rem; border: 1px solid #f3f4f6;
	}
	
	.input-well { flex: 1; height: 100%; }
	.input-well input { 
		width: 100%; height: 100%; border: none; outline: none; padding: 0 1rem; 
		font-size: 13px; font-weight: 500;
	}

	.strip-btn { 
		width: 2.75rem; height: 2.75rem; border-radius: 1rem; border: none; background: transparent; 
		color: #6b7280; display: flex; align-items: center; justify-content: center; cursor: pointer;
		transition: all 0.2s;
	}
	.strip-btn:hover { background: #f9fafb; color: black; }

	.send-btn { 
		width: 2.75rem; height: 2.75rem; background: black; color: white; border: none;
		border-radius: 1rem; display: flex; align-items: center; justify-content: center; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
	}

	/* Recording */
	.recording-ui { 
		position: absolute; inset: 0; background: white; z-index: 10; 
		display: flex; align-items: center; justify-content: space-between; padding: 0 1rem; border-radius: 1.5rem;
	}
	.pulse-dot { width: 8px; height: 8px; background: #ef4444; border-radius: 50%; animation: pulse 1s infinite; }
	.stop-btn { font-size: 10px; font-black: 900; color: #ef4444; padding: 4px 8px; background: #fef2f2; border: none; border-radius: 6px; }

	/* Media Menu */
	.media-menu { 
		position: absolute; bottom: 5.5rem; left: 1.5rem; background: white; 
		border-radius: 1.25rem; padding: 8px; display: flex; flex-direction: column; gap: 4px;
		width: 160px; border: 1px solid #f1f5f9;
	}
	.media-option { 
		display: flex; align-items: center; gap: 12px; padding: 8px; border: none; background: transparent; 
		cursor: pointer; border-radius: 0.75rem; transition: all 0.2s;
	}
	.media-option:hover { background: #f8fafc; }
	.media-option span { font-size: 11px; font-weight: 600; color: #475569; }
	.media-icon { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; }

	.icon-btn { 
		width: 2.25rem; height: 2.25rem; border-radius: 0.75rem; border: none; background: transparent; 
		display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s;
	}
	.icon-btn:hover { background: #f3f4f6; }

	.avatar-wrap { position: relative; }
	.avatar-box { 
		width: 2.25rem; height: 2.25rem; background: #f3f4f6; border-radius: 10px; 
		display: flex; align-items: center; justify-content: center; font-size: 10px; font-weight: 900; color: #9ca3af;
	}
	.status-dot { position: absolute; bottom: -2px; right: -2px; width: 10px; height: 10px; background: #10b981; border: 2px solid white; border-radius: 50%; }

	@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.4; } 100% { opacity: 1; } }
</style>
