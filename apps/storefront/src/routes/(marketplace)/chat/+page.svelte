<script lang="ts">
	import { onMount, tick, onDestroy } from 'svelte';
	import { fade, fly, slide } from 'svelte/transition';
	import { 
		Send, MessageCircle, ShieldCheck, ArrowLeft, 
		Loader2, User, Phone, Video, Paperclip, Smile,
		Mic, X, Image as ImageIcon, FileText, ShoppingCart,
		Plus, CheckCircle2, ChevronRight, Package, Download, Play, Pause,
		Stethoscope, Sparkles
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
		// Wait for auth store to initialize
		const checkAuth = () => {
			if ($authStore.initialized) {
				if (!$currentUser) {
					loading = false; // Show login required state
					isAuthModalOpen.set(true); // Automatically open the standard login modal
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
			// 1. Check for ID in URL
			let targetId = $page.url.searchParams.get('id');

			// 2. Fallback to global store
			if (!targetId) {
				targetId = get(activeConversationId);
			}

			if (targetId) {
				const { data: existing, error } = await supabase
					.from('chat_conversations')
					.select('*')
					.eq('id', targetId)
					.maybeSingle();
				
				if (existing) {
					conversation = existing;
					setActiveConversation(existing.id); // Sync store if URL had it
				}
			}

			// 3. Fallback to existing search logic if still no conversation
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
					// Create new if none found at all
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
							metadata: { 
								origin: 'storefront_fallback',
								productId: urlProductId 
							}
						})
						.select().single();
					
					if (createError) throw createError;
					conversation = created;
					setActiveConversation(created.id);
				}
			}

			// 4. Handle Product Inquiry Context
			const urlProductId = $page.url.searchParams.get('productId');
			const metaProductId = conversation?.metadata?.productId;
			const productId = urlProductId || metaProductId;

			if (productId) {
				const marketplaceService = new MarketplaceService(supabase);
				const { product, error: pError } = await marketplaceService.getMarketplaceProductById(productId, tenantId);
				if (!pError) {
					productInquiry = product;
				}
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

	async function endSession() {
		if (confirm('Are you sure you want to end this chat session? This will clear your active chat history on this device.')) {
			clearActiveConversation();
			goto('/');
		}
	}

	function setupSubscription() {
		// 1. Messages Subscription
		supabase.channel(`chat:${conversation.id}`)
			.on('postgres_changes', {
				event: 'INSERT',
				schema: 'public',
				table: 'chat_messages',
				filter: `conversation_id=eq.${conversation.id}`
			}, (payload) => {
				// Only display if it's not a pharmacist-only activity message
				if (payload.eventType === 'INSERT' && !payload.new.metadata?.pharmacist_only) {
					if (!messages.find(m => m.id === payload.new.id)) {
						messages = [...messages, payload.new];
						scrollToBottom();
					}
				}
			})
			.subscribe();

		// 2. Typing Indicators Subscription
		supabase.channel(`typing:${conversation.id}`)
			.on('postgres_changes', {
				event: '*',
				schema: 'public',
				table: 'chat_typing_indicators',
				filter: `conversation_id=eq.${conversation.id}`
			}, (payload: any) => {
				if (payload.new?.user_id === $currentUser?.id || payload.old?.user_id === $currentUser?.id) return;
				
				const userId = payload.new?.user_id || payload.old?.user_id;
				const typing = payload.new?.is_typing;
				
				if (typing) {
					if (!othersTyping.includes(userId)) {
						othersTyping = [...othersTyping, userId];
						scrollToBottom();
					}
				} else {
					othersTyping = othersTyping.filter(id => id !== userId);
				}
			})
			.subscribe();
	}

	async function handleTyping() {
		if (!conversation || !$currentUser) return;
		
		if (!isTyping) {
			isTyping = true;
			updateTypingStatus(true);
		}

		if (typingTimeout) clearTimeout(typingTimeout);
		typingTimeout = setTimeout(() => {
			isTyping = false;
			updateTypingStatus(false);
		}, 3000);
	}

	async function updateTypingStatus(typing: boolean) {
		try {
			await supabase
				.from('chat_typing_indicators')
				.upsert({
					conversation_id: conversation.id,
					user_id: $currentUser.id,
					user_type: 'customer',
					is_typing: typing
				}, { onConflict: 'conversation_id,user_id' });
		} catch (err) {
			console.error('Failed to update typing status:', err);
		}
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
					message_text: file.name,
					message_type: file.type.startsWith('image/') ? 'image' : (file.type === 'application/pdf' ? 'file' : 'file'),
					media_url: publicUrl,
					metadata: {
						attachments: [{ url: publicUrl, name: file.name, type: file.type, size: file.size }]
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
					message_text: 'Voice Message',
					message_type: 'audio',
					media_url: publicUrl,
					metadata: {
						attachments: [{ url: publicUrl, name: file.name, type: 'audio/webm', duration: recordingTime }]
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
	{:else if !$currentUser}
		<div class="auth-required" transition:fade>
			<div class="auth-card shadow-2xl">
				<div class="auth-icon-wrap">
					<ShieldCheck class="h-10 w-10 text-primary-600" />
				</div>
				<h2 class="auth-title">Authentication Required</h2>
				<p class="auth-sub">Please sign in to your health profile to begin a secure consultation with our pharmacist.</p>
				<button onclick={() => isAuthModalOpen.set(true)} class="login-btn w-full">
					Sign in to Continue
				</button>
				<div class="flex items-center gap-2 mt-6 opacity-40">
					<div class="h-[1px] flex-1 bg-gray-300"></div>
					<span class="text-[9px] font-black uppercase tracking-widest">Medical Privacy</span>
					<div class="h-[1px] flex-1 bg-gray-300"></div>
				</div>
			</div>
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
							<h1 class="text-sm font-black text-gray-900 uppercase tracking-tight leading-none">
								{conversation?.chatType === 'Customer Support' ? 'Customer Support' : 'Pharmacy Support'}
							</h1>
							<p class="text-[10px] font-bold text-emerald-600 uppercase tracking-widest mt-1">
								{conversation?.chatType === 'Customer Support' ? 'Support is Online' : 'Pharmacist is Online'}
							</p>
						</div>
					</div>
				</div>
				
				<div class="flex items-center gap-2">
					<a href="/chat/ai" class="icon-btn text-primary-600 bg-primary-50 hover:bg-primary-100" title="Switch to AI Shopper">
						<Sparkles class="h-4 w-4" />
					</a>
					<button class="icon-btn text-gray-400 hover:text-primary-600"><Phone class="h-4 w-4" /></button>
					<button class="icon-btn text-gray-400 hover:text-primary-600"><Video class="h-4 w-4" /></button>
					<button 
						onclick={endSession}
						class="px-3 py-1.5 bg-rose-50 text-rose-600 text-[10px] font-black uppercase tracking-widest rounded-lg hover:bg-rose-100 transition-colors ml-2"
					>
						End Session
					</button>
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
				{#if productInquiry}
					<div class="inquiry-banner" in:slide>
						<div class="flex items-center gap-4">
							<div class="inquiry-img">
								{#if productInquiry.image_url}
									<img src={productInquiry.image_url} alt="" />
								{:else}
									<Package class="h-6 w-6 text-gray-300" />
								{/if}
							</div>
							<div class="flex-1 min-w-0">
								<p class="text-[10px] font-black text-emerald-600 uppercase tracking-widest">Inquiry Context</p>
								<h3 class="text-sm font-black text-gray-900 truncate uppercase tracking-tight">{productInquiry.name}</h3>
								<p class="text-[10px] text-gray-500 font-medium">₦{productInquiry.price?.toLocaleString()}</p>
							</div>
							<button class="icon-btn text-gray-400" onclick={() => productInquiry = null}><X class="h-4 w-4" /></button>
						</div>
					</div>
				{/if}

				{#each messages as msg}
					{@const isMe = msg.sender_id === $currentUser?.id}
					<div class="msg-row {isMe ? 'me' : 'them'}" in:fly={{ y: 20 }}>
						<div class="msg-bubble shadow-sm">
							{#if msg.media_url || msg.metadata?.attachments}
								<div class="msg-attachments">
									{#if msg.message_type === 'image' || (!msg.message_type && msg.media_url && !msg.media_url.endsWith('.pdf'))}
										<div class="attachment-img">
											<img src={msg.media_url || msg.metadata?.attachments?.[0]?.url} alt="" />
											<a href={msg.media_url || msg.metadata?.attachments?.[0]?.url} target="_blank" class="download-link"><Download class="h-3 w-3" /></a>
										</div>
									{:else if msg.message_type === 'audio' || msg.metadata?.attachments?.[0]?.type?.startsWith('audio/')}
										<div class="audio-msg">
											<audio src={msg.media_url || msg.metadata?.attachments?.[0]?.url} controls class="h-8"></audio>
										</div>
									{:else if msg.message_type === 'file' || msg.metadata?.attachments?.[0]?.type === 'application/pdf'}
										<a href={msg.media_url || msg.metadata?.attachments?.[0]?.url} target="_blank" class="file-tag">
											<FileText class="h-4 w-4" />
											<span class="truncate">{msg.message_text || msg.metadata?.attachments?.[0]?.name || 'Document'}</span>
										</a>
									{:else if msg.metadata?.attachments}
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
									{/if}
								</div>
							{/if}
							{#if msg.metadata?.suggested_product}
								<SuggestedProductCard 
									productId={msg.metadata.suggested_product} 
									{tenantId} 
								/>
							{/if}

							{#if msg.metadata?.product}
								<div class="product-msg-card bg-gray-50 rounded-2xl p-3 border border-gray-100 mb-2">
									<div class="flex items-center gap-3">
										<div class="h-12 w-12 bg-white rounded-lg flex items-center justify-center border border-gray-200">
											{#if msg.metadata.product.image_url}
												<img src={msg.metadata.product.image_url} alt="" class="h-full w-full object-cover" />
											{:else}
												<Package class="h-6 w-6 text-gray-300" />
											{/if}
										</div>
										<div class="flex-1 min-w-0">
											<h4 class="text-xs font-black truncate uppercase tracking-tight">{msg.metadata.product.name}</h4>
											<p class="text-xs font-black text-primary-600">₦{msg.metadata.product.sharedPrice?.toLocaleString() || msg.metadata.product.unit_price?.toLocaleString()}</p>
										</div>
									</div>
									<button 
										onclick={() => handleProductSelect(msg.metadata.product)}
										class="w-full mt-2 bg-black text-white text-[10px] font-black py-2 rounded-lg uppercase tracking-widest flex items-center justify-center gap-2"
									>
										Add to Bag <Plus class="h-3 w-3" />
									</button>
								</div>
							{/if}

							{#if msg.metadata?.doctor}
								<div class="referral-card bg-indigo-50/50 rounded-2xl p-4 border border-indigo-100 mb-2">
									<div class="flex items-center gap-2 mb-3">
										<div class="p-1.5 bg-indigo-100 rounded-lg"><Stethoscope class="h-3 w-3 text-indigo-600" /></div>
										<span class="text-[9px] font-black uppercase tracking-[0.2em] text-indigo-600">Medical Referral</span>
									</div>
									<div class="flex items-center gap-3">
										<div class="h-12 w-12 bg-indigo-100 rounded-full flex items-center justify-center border-2 border-white shadow-sm overflow-hidden">
											{#if msg.metadata.doctor.avatar}
												<img src={msg.metadata.doctor.avatar} alt="" class="h-full w-full object-cover" />
											{:else}
												<User class="h-6 w-6 text-indigo-300" />
											{/if}
										</div>
										<div class="flex-1 min-w-0">
											<h4 class="text-sm font-black text-indigo-900 truncate uppercase tracking-tight">{msg.metadata.doctor.name}</h4>
											<p class="text-[10px] text-indigo-500 font-bold uppercase tracking-widest">{msg.metadata.doctor.specialization}</p>
										</div>
									</div>
									<a 
										href="/medics/{msg.metadata.doctor.id}"
										class="w-full mt-4 bg-indigo-600 text-white text-[10px] font-black py-2.5 rounded-xl uppercase tracking-widest flex items-center justify-center gap-2 shadow-lg shadow-indigo-200"
									>
										View Profile <ChevronRight class="h-3 w-3" />
									</a>
								</div>
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

				{#if othersTyping.length > 0}
					<div class="msg-row them" in:fade>
						<div class="msg-bubble shadow-sm bg-gray-50 flex items-center gap-1 py-3 px-4 rounded-2xl">
							<div class="typing-dot"></div>
							<div class="typing-dot"></div>
							<div class="typing-dot"></div>
							<span class="text-[10px] font-bold text-gray-400 ml-2 uppercase tracking-widest">Pharmacist is typing</span>
						</div>
					</div>
				{/if}
			</div>
		</main>

		<!-- FIXED INTERACTION CENTER -->
		<footer class="interaction-center">


			<div class="input-strip shadow-2xl">
				<div class="flex items-center gap-1 relative">
					<button 
						class="strip-btn {showMediaMenu ? 'rotate-45' : ''} transition-transform" 
						onclick={() => showMediaMenu = !showMediaMenu}
					>
						<Plus class="h-6 w-6" />
					</button>

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
						oninput={handleTyping}
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
	.me .msg-bubble p { color: white !important; }
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
		position: absolute; bottom: calc(100% + 1rem); left: 0; background: white; 
		border-radius: 1.25rem; padding: 8px; display: flex; flex-direction: column; gap: 4px;
		width: 160px; border: 1px solid #f1f5f9; z-index: 70;
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

	/* Auth Required */
	.auth-required {
		flex: 1; display: flex; align-items: center; justify-content: center; padding: 2rem;
		background: radial-gradient(circle at center, #f8fafc 0%, #f1f5f9 100%);
	}
	.auth-card {
		background: white; border-radius: 2.5rem; padding: 3rem; max-width: 400px; width: 100%;
		text-align: center; border: 1px solid rgba(255,255,255,0.8);
	}
	.auth-icon-wrap {
		width: 80px; height: 80px; background: #f5f3ff; border-radius: 2rem;
		display: flex; align-items: center; justify-content: center; margin: 0 auto 2rem;
		box-shadow: 0 10px 20px -5px rgba(79,70,229,0.1);
	}
	.auth-title { font-size: 1.5rem; font-weight: 900; color: #1e1b4b; letter-spacing: -0.02em; margin-bottom: 1rem; }
	.auth-sub { font-size: 0.875rem; color: #64748b; line-height: 1.6; margin-bottom: 2.5rem; }
	.login-btn {
		display: block; width: 100%; padding: 1.25rem; background: black; color: white;
		border-radius: 1.25rem; font-size: 0.875rem; font-weight: 800; text-transform: uppercase;
		letter-spacing: 0.1em; text-decoration: none; transition: transform 0.2s, box-shadow 0.2s;
	}
	.login-btn:hover { transform: translateY(-2px); box-shadow: 0 15px 30px -5px rgba(0,0,0,0.15); }

	@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.4; } 100% { opacity: 1; } }

	.typing-dot {
		width: 4px;
		height: 4px;
		background: #cbd5e1;
		border-radius: 50%;
		animation: typingPulse 1.4s infinite ease-in-out both;
	}
	.typing-dot:nth-child(1) { animation-delay: -0.32s; }
	.typing-dot:nth-child(2) { animation-delay: -0.16s; }

	.inquiry-banner {
		background: white;
		border: 1px solid #f3f4f6;
		border-radius: 1.5rem;
		padding: 1rem;
		margin-bottom: 2rem;
		box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
	}
	.inquiry-img {
		width: 3.5rem;
		height: 3.5rem;
		background: #f9fafb;
		border-radius: 1rem;
		display: flex;
		align-items: center;
		justify-content: center;
		overflow: hidden;
	}
	.inquiry-img img { width: 100%; height: 100%; object-fit: cover; }

	@keyframes typingPulse {
		0%, 80%, 100% { transform: scale(0); }
		40% { transform: scale(1); }
	}
</style>
