<script lang="ts">
	import { onMount, tick, onDestroy, untrack } from 'svelte';
	import { fade, fly, slide } from 'svelte/transition';
	import { 
		Send, MessageCircle, ShieldCheck, ArrowLeft, 
		Loader2, User, Phone, Video, Paperclip, Smile,
		Mic, X, Image as ImageIcon, FileText, ShoppingCart,
		Plus, CheckCircle2, ChevronRight, Package, Download, Play, Pause,
		Stethoscope, Sparkles, Headphones, ExternalLink
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
	let isProviderFreelance = $state(false);
	let queuePosition = $state<number | null>(null);

	// 2. Navigation & Context
	const tenantId = $derived($page.data.storefront?.id);

	// 3. UI State
	let showProductModal = $state(false);
	let showCartFlyout = $state(false);
	let showMediaMenu = $state(false);
	let showAttachmentMenu = $state(false);
	let showEmojiMenu = $state(false);
	let videoInput = $state<HTMLInputElement | null>(null);
	let uploadType = $state<'image' | 'file' | 'video'>('image');
	let isUploading = $state(false);
	let lightboxUrl = $state<string | null>(null);
	const popularEmojis = ['😊', '😂', '🥰', '👍', '🙏', '💊', '🏥', '👋', '💙', '✅'];

	let showToast = $state(false);
	let toastProduct = $state('');
	let toastTimeout: any = null;
	let chatInitialized = false;
	
	function triggerToast(productName: string) {
		toastProduct = productName;
		showToast = true;
		if (toastTimeout) clearTimeout(toastTimeout);
		toastTimeout = setTimeout(() => showToast = false, 2500);
	}
	
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

	onMount(() => {
		const unsub = authStore.subscribe($auth => {
			if ($auth.initialized && !chatInitialized) {
				if (!$auth.user) {
					loading = false;
					isAuthModalOpen.set(true);
				} else {
					chatInitialized = true;
					isAuthModalOpen.set(false);
					initChat();
				}
			}
		});
		return unsub;
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
				const preselectedProvider = $page.url.searchParams.get('serviceProvider');
				let query = supabase
					.from('chat_conversations')
					.select('*')
					.eq('customer_id', $currentUser.id)
					.eq('tenant_id', tenantId)
					.is('consultation_id', null);
				
				if (preselectedProvider) {
					query = query.eq('service_provider', preselectedProvider);
				}

				const { data: existing } = await query
					.order('started_at', { ascending: false })
					.limit(1)
					.maybeSingle();

				if (existing) {
					conversation = existing;
					setActiveConversation(existing.id);
				} else {
					const urlProductId = $page.url.searchParams.get('productId');
					const urlChatType = $page.url.searchParams.get('type') || (urlProductId ? 'Consultation' : 'Customer Support');
					
					console.log('Attempting chat creation on page...', { 
						urlChatType, 
						tenantId, 
						uid: $currentUser.id 
					});

					const { data: created, error: createError } = await supabase
						.from('chat_conversations')
						.insert({
							customer_id: $currentUser.id,
							tenant_id: tenantId,
							status: 'active',
							chatType: urlChatType,
							service_provider: preselectedProvider || null,
							customer_name: $currentUser?.user_metadata?.full_name || $currentUser?.email,
							customer_pic: $currentUser?.user_metadata?.avatar_url,
							metadata: { origin: 'storefront_direct', productId: urlProductId }
						})
						.select().single();
					
					if (createError) {
						console.error('Pharmacist Page Chat Create Error:', createError);
						throw createError;
					}

					console.log('Pharmacist chat created:', created.id);
					conversation = created;
					setActiveConversation(created.id);
				}
			}

			// If waiting, get position
			if (conversation?.status === 'waiting') {
				const { data: pos } = await supabase.rpc('get_chat_queue_position', { p_conversation_id: conversation.id });
				queuePosition = pos;
			}

			// Check if the service provider for this chat is freelance
			if (conversation?.service_provider) {
				const { data: pharmacist } = await supabase
					.from('available_pharmacists')
					.select('provider_type')
					.eq('user_id', conversation.service_provider)
					.maybeSingle();
				
				if (pharmacist?.provider_type === 'Freelance') {
					isProviderFreelance = true;
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
			.on('postgres_changes', {
				event: 'UPDATE',
				schema: 'public',
				table: 'chat_conversations',
				filter: `id=eq.${conversation.id}`
			}, (payload) => {
				if (payload.new.status === 'active' && conversation.status === 'waiting') {
					conversation.status = 'active';
					queuePosition = null;
					triggerToast('Pharmacist is ready!');
				} else {
					conversation = { ...conversation, ...payload.new };
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

			// Note: We don't manually push to 'messages' here because 
			// the setupSubscription listener will handle the INSERT event.
		} finally {
			sending = false;
		}
	}

	async function handleFileUpload(event: Event) {
		const target = event.target as HTMLInputElement;
		const file = target.files?.[0];
		if (!file || !conversation) return;

		isUploading = true;
		try {
			const fileExt = file.name.split('.').pop();
			const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
			const filePath = `chat/${conversation.id}/${fileName}`;

			const { error: uploadError } = await supabase.storage
				.from('chat-attachments')
				.upload(filePath, file);

			if (uploadError) throw uploadError;

			const { data: { publicUrl } } = supabase.storage
				.from('chat-attachments')
				.getPublicUrl(filePath);

			const { data: sent, error: msgError } = await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: $currentUser.id,
					sender_type: 'customer',
					message_text: file.name,
					message_type: uploadType === 'image' ? 'image' : 'image', // 'file' not in enum, using image as fallback for now
					media_url: publicUrl,
					metadata: { 
						file_url: publicUrl, // Keep for backward compat
						file_name: file.name,
						file_size: file.size,
						file_type: file.type,
						original_upload_type: uploadType
					}
				})
				.select().single();

			if (msgError) throw msgError;
			// Note: We don't manually push to 'messages' here because 
			// the setupSubscription listener will handle the INSERT event.
		} catch (err: any) {
			console.error('Upload failed:', err);
			alert(`Debug Error: ${err.message} | ${JSON.stringify(err)}`);
		} finally {
			isUploading = false;
			if (imageInput) imageInput.value = '';
			if (pdfInput) pdfInput.value = '';
		}
	}

	function triggerUpload(type: 'image' | 'file' | 'video') {
		uploadType = type === 'file' ? 'file' : type === 'video' ? 'video' : 'image';
		showAttachmentMenu = false;
		if (type === 'image' && imageInput) {
			imageInput.value = '';
			imageInput.click();
		} else if (type === 'file' && pdfInput) {
			pdfInput.value = '';
			pdfInput.click();
		} else if (type === 'video' && videoInput) {
			videoInput.value = '';
			videoInput.click();
		}
	}

	function formatRecordingTime(seconds: number) {
		const m = Math.floor(seconds / 60);
		const s = seconds % 60;
		return `${m}:${s.toString().padStart(2, '0')}`;
	}

	async function toggleRecording() {
		if (isRecording) {
			stopRecording();
		} else {
			await startRecording();
		}
	}

	async function startRecording() {
		try {
			const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
			mediaRecorder = new MediaRecorder(stream);
			audioChunks = [];
			
			mediaRecorder.ondataavailable = (e) => {
				if (e.data.size > 0) audioChunks.push(e.data);
			};
			
			mediaRecorder.onstop = async () => {
				if (audioChunks.length === 0) {
					console.error('No audio data captured');
					isUploading = false;
					return;
				}
				
				const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
				const audioFile = new File([audioBlob], `voice_note_${Date.now()}.webm`, { type: 'audio/webm' });
				
				isUploading = true;
				try {
					const filePath = `chat/${conversation.id}/${audioFile.name}`;
					const { error: uploadError } = await supabase.storage
						.from('chat-attachments')
						.upload(filePath, audioFile);

					if (uploadError) throw uploadError;

					const { data: { publicUrl } } = supabase.storage
						.from('chat-attachments')
						.getPublicUrl(filePath);

					const { error: msgError } = await supabase
						.from('chat_messages')
						.insert({
							conversation_id: conversation.id,
							sender_id: $currentUser.id,
							sender_type: 'customer',
							message_text: 'Voice Note',
							message_type: 'image', // using image as fallback to avoid enum error
							media_url: publicUrl,
							metadata: { 
								original_upload_type: 'audio',
								file_name: audioFile.name,
								file_size: audioFile.size,
								file_type: audioFile.type,
								duration: recordingTime
							}
						});
					if (msgError) throw msgError;
				} catch (err: any) {
					console.error('Audio upload failed:', err);
					alert(`Audio upload failed. Please try again.`);
				} finally {
					isUploading = false;
					// Stop tracks
					if (stream) {
						stream.getTracks().forEach(track => track.stop());
					}
				}
			};

			mediaRecorder.start(1000); // Collect data every second
			isRecording = true;
			recordingTime = 0;
			recordingInterval = setInterval(() => {
				recordingTime++;
				if (recordingTime >= 120) {
					stopRecording();
				}
			}, 1000);
		} catch (err) {
			console.error('Microphone access denied:', err);
			alert('Microphone access is required to record voice notes.');
		}
	}

	function stopRecording() {
		if (mediaRecorder && mediaRecorder.state !== 'inactive') {
			mediaRecorder.stop();
		}
		isRecording = false;
		if (recordingInterval) clearInterval(recordingInterval);
	}

	function cancelRecording() {
		if (mediaRecorder && mediaRecorder.state !== 'inactive') {
			mediaRecorder.onstop = null; // Prevent sending
			mediaRecorder.stop();
		}
		isRecording = false;
		if (recordingInterval) clearInterval(recordingInterval);
		audioChunks = [];
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
	async function handleProductSelect(product: any) {
		showProductModal = false;
		if (!conversation) return;
		try {
			const { error: msgError } = await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: $currentUser.id,
					sender_type: 'customer',
					message_text: `Shared product: ${product.name}`,
					message_type: 'text',
					metadata: { 
						original_upload_type: 'product',
						product_id: product.id,
						product_name: product.name,
						product_image: product.image_url,
						price: product.unit_price || product.price,
						stock_available: product.stock_quantity
					}
				});
			if (msgError) throw msgError;
		} catch (err) {
			console.error("Failed to share product", err);
		}
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
				<div class="flex items-center gap-3">
					<button class="relative icon-btn" onclick={() => showCartFlyout = true} aria-label="Open Cart">
						<ShoppingCart class="h-5 w-5 text-gray-600" />
						{#if $cartStore.items.length > 0}
							<div class="absolute -top-1 -right-1 h-4 w-4 bg-black rounded-full flex items-center justify-center">
								<span class="text-[9px] font-bold text-white leading-none" style="color: #ffffff;">{$cartStore.items.reduce((acc, item) => acc + item.quantity, 0)}</span>
							</div>
						{/if}
					</button>
					<button onclick={endSession} class="px-3 py-1.5 bg-rose-50 text-rose-600 text-[10px] font-black uppercase tracking-widest rounded-lg">End Session</button>
				</div>
			</div>
			<div class="encryption-bar bg-gray-50 border-y py-1 flex items-center justify-center gap-2 text-[8px] font-bold text-gray-400 uppercase tracking-widest">
				<ShieldCheck class="h-3 w-3" /> End-to-end encrypted medical consultation
			</div>
		</header>

		<main class="messages-wrap" bind:this={messagesContainer}>
			<div class="messages-inner">
				{#each messages.filter(m => !m.metadata?.is_activity) as msg}
					{@const isMe = msg.sender_id === $currentUser?.id}
					{@const mediaType = msg.attachment_type || msg.metadata?.original_upload_type || msg.metadata?.type || msg.message_type}
					{@const mediaUrl = msg.attachment_url || msg.media_url || msg.metadata?.file_url || msg.metadata?.url}
					{@const mediaName = msg.attachment_name || msg.metadata?.file_name || msg.metadata?.name || 'File'}

					<div class="msg-row {isMe ? 'me' : 'them'}" in:fly={{ y: 20 }}>
						<div class="msg-bubble shadow-sm">
							{#if mediaType === 'file' || mediaType === 'pdf'}
								<a href={mediaUrl} target="_blank" rel="noopener noreferrer" class="pdf-card">
									<div class="pdf-icon-wrap">
										<FileText class="h-6 w-6" />
									</div>
									<div class="pdf-info">
										<p class="pdf-name">{mediaName}</p>
										<p class="pdf-label">PDF Uploaded · Click to view</p>
									</div>
									<ExternalLink class="h-4 w-4 pdf-open-icon" />
								</a>
							{:else if mediaType === 'audio' || mediaType === 'voice'}
								<div class="audio-player mb-2">
									<audio controls src={mediaUrl} class="max-w-[350px] h-10 outline-none rounded-full"></audio>
								</div>
							{:else if mediaType === 'video'}
								<div class="msg-video-wrap mb-2">
									<video src={mediaUrl} controls class="w-full max-w-[240px] rounded-xl outline-none bg-black"></video>
								</div>
							{:else if mediaType === 'product' || msg.attachment_type === 'product'}
								{@const p = msg.metadata?.product || msg.metadata}
								<div class="product-card bg-white text-gray-900 rounded-xl p-3 border border-gray-100 min-w-[240px] max-w-[280px]">
									<div class="flex gap-3 items-center mb-2">
										<div class="w-12 h-12 bg-gray-50 rounded-lg overflow-hidden flex-shrink-0">
											{#if p.product_image || p.image_url}
												<img src={p.product_image || p.image_url} alt="Product" class="w-full h-full object-cover" />
											{:else}
												<div class="w-full h-full flex items-center justify-center text-gray-300"><Package class="h-6 w-6" /></div>
											{/if}
										</div>
										<div class="flex-1 min-w-0">
											<h4 class="text-xs font-bold truncate uppercase">{p.product_name || p.name}</h4>
											<p class="text-[10px] font-black text-primary-600 mt-0.5">₦{(p.price || p.unit_price || p.sharedPrice)?.toLocaleString()}</p>
										</div>
									</div>
									<button 
										class="w-full py-2 bg-black hover:bg-gray-800 text-white rounded-lg text-[10px] font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2"
										onclick={() => {
											cartStore.addItem({
												product_id: p.product_id || p.id,
												product_name: p.product_name || p.name,
												product_image: p.product_image || p.image_url,
												price: p.price || p.unit_price || p.sharedPrice,
												quantity: 1,
												stock_available: p.stock_available || p.stock_quantity,
												is_freelance_prescription: isProviderFreelance,
												prescription_id: msg.metadata?.prescription_id || null
											}, tenantId);
											triggerToast(p.product_name || p.name);
										}}
									>
										<ShoppingCart class="h-3 w-3" /> Add to Bag
									</button>
								</div>
							{:else if mediaType === 'image'}
								<div class="msg-image-wrap mb-2">
									<img src={mediaUrl} alt="Shared content" class="msg-img" onclick={() => lightboxUrl = mediaUrl} />
								</div>
							{/if}

							{#if msg.message_type === 'text' || (!mediaType && msg.message_text)}
								<p class="msg-text">{msg.message_text}</p>
							{/if}
							<span class="msg-time">{formatTime(msg.created_at)}</span>
						</div>
					</div>
				{/each}
				
				{#if messages.length === 0 && conversation?.status !== 'waiting'}
					<div class="empty-state">
						<div class="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center text-gray-300 mb-4 border-2 border-gray-100 border-dashed">
							<MessageCircle class="h-8 w-8" />
						</div>
						<h3 class="text-xs font-black uppercase tracking-widest text-gray-900">Pharmacist Chat</h3>
						<p class="text-[10px] text-gray-400 max-w-[200px] mt-2 font-medium">Connect with our licensed pharmacists for clinical advice and prescription help.</p>
					</div>
				{/if}

				{#if conversation?.status === 'waiting'}
					<div class="waiting-room" transition:fade>
						<div class="waiting-card shadow-2xl">
							<div class="waiting-icon-wrap">
								<Clock class="h-8 w-8 text-amber-500 animate-pulse" />
							</div>
							<h2 class="waiting-title">You're in the Queue</h2>
							<p class="waiting-desc">Our pharmacist is currently attending to another patient. Please stay on this page.</p>
							
							<div class="queue-status-box">
								<div class="queue-num-wrap">
									<span class="queue-label">Position</span>
									<span class="queue-val">{queuePosition || '...'}</span>
								</div>
								<div class="queue-sep"></div>
								<div class="queue-num-wrap">
									<span class="queue-label">Est. Wait</span>
									<span class="queue-val">~{(queuePosition || 1) * 3} min</span>
								</div>
							</div>

							<div class="waiting-footer">
								<Loader2 class="h-3 w-3 animate-spin text-gray-400" />
								<span>Matching you with a licensed pharmacist</span>
							</div>
						</div>
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
								<button class="flex items-center gap-3 px-3 py-2.5 hover:bg-slate-50 rounded-xl transition-colors text-slate-700" onclick={() => triggerUpload('image')}>
									<div class="w-8 h-8 bg-blue-50 text-blue-600 rounded-lg flex items-center justify-center"><ImageIcon class="h-4 w-4" /></div>
									<span class="text-[11px] font-black uppercase tracking-tight">Image</span>
								</button>
								<button class="flex items-center gap-3 px-3 py-2.5 hover:bg-slate-50 rounded-xl transition-colors text-slate-700" onclick={() => triggerUpload('video')}>
									<div class="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-lg flex items-center justify-center"><Video class="h-4 w-4" /></div>
									<span class="text-[11px] font-black uppercase tracking-tight">Video</span>
								</button>
								<button class="flex items-center gap-3 px-3 py-2.5 hover:bg-slate-50 rounded-xl transition-colors text-slate-700" onclick={() => triggerUpload('file')}>
									<div class="w-8 h-8 bg-rose-50 text-rose-600 rounded-lg flex items-center justify-center"><FileText class="h-4 w-4" /></div>
									<span class="text-[11px] font-black uppercase tracking-tight">PDF Document</span>
								</button>
							</div>
						{/if}
						<input 
							type="file" 
							bind:this={imageInput}
							class="hidden" 
							accept="image/*" 
							onchange={handleFileUpload}
						/>
						<input 
							type="file" 
							bind:this={pdfInput}
							class="hidden" 
							accept="application/pdf" 
							onchange={handleFileUpload}
						/>
						<input 
							type="file" 
							bind:this={videoInput}
							class="hidden" 
							accept="video/*" 
							onchange={handleFileUpload}
						/>
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
					class="send-btn {isRecording ? 'bg-red-500 hover:bg-red-600' : 'bg-black hover:bg-gray-800'} text-white p-3 rounded-xl transition-all flex items-center gap-2" 
					onclick={newMessage.trim() ? sendMessage : toggleRecording}
					disabled={sending || isUploading}
				>
					{#if isUploading}
						<Loader2 class="h-4 w-4 animate-spin" />
					{:else if isRecording}
						<span class="text-xs font-bold w-8 text-center">{formatRecordingTime(recordingTime)}</span>
						<div class="w-2 h-2 bg-white rounded-sm animate-pulse"></div>
					{:else if newMessage.trim()}
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

{#if lightboxUrl}
	<div class="lightbox-overlay" onclick={() => lightboxUrl = null} role="dialog" aria-modal="true">
		<button class="lightbox-close" onclick={() => lightboxUrl = null} aria-label="Close">×</button>
		<img src={lightboxUrl} alt="Full size" onclick={(e) => e.stopPropagation()} />
	</div>
{/if}

{#if showToast}
	<div class="toast" transition:fly={{ y: 20, duration: 200 }}>
		<CheckCircle2 class="w-4 h-4 text-emerald-500" />
		<span><strong>{toastProduct}</strong> added to bag</span>
		<button class="toast-link" onclick={() => showCartFlyout = true}>View Bag</button>
	</div>
{/if}

<style>
	.chat-viewport { height: 100vh; display: flex; flex-direction: column; background: #fafafa; }
	.header { background: white; border-bottom: 1px solid #eee; }
	.header-content { height: 4rem; padding: 0 1rem; display: flex; align-items: center; justify-content: space-between; }
	.messages-wrap { flex: 1; overflow-y: auto; padding: 1.5rem; }
	.messages-inner { max-width: 800px; margin: 0 auto; display: flex; flex-direction: column; gap: 1rem; }
	.msg-row { display: flex; flex-direction: column; max-width: 80%; }
	.msg-row.me { align-self: flex-end; }
	.msg-row.them { align-self: flex-start; }

	/* Bubble colours */
	.msg-bubble { padding: 0.75rem 1rem; border-radius: 1rem; background: #f1f5f9; border: none; color: #374151; }
	.me .msg-bubble { background: #000000; color: #ffffff; border: none; border-bottom-right-radius: 0.25rem; }
	.me .pdf-name { color: #ffffff; }
	.msg-bubble p, .msg-bubble .msg-text { color: inherit; font-size: 0.875rem; line-height: 1.625; }

	/* PDF Card */
	.pdf-card {
		display: flex; align-items: center; gap: 10px;
		padding: 10px 12px;
		background: rgba(255,255,255,0.12);
		border: 1px solid rgba(255,255,255,0.2);
		border-radius: 12px;
		cursor: pointer;
		text-decoration: none;
		color: inherit;
		margin-bottom: 4px;
		transition: background 0.15s;
		min-width: 220px;
	}
	.pdf-card:hover { background: rgba(255,255,255,0.22); }
	.them .pdf-card { background: rgba(0,0,0,0.06); border-color: rgba(0,0,0,0.1); }
	.them .pdf-card:hover { background: rgba(0,0,0,0.1); }
	.pdf-icon-wrap {
		width: 38px; height: 38px; flex-shrink: 0;
		background: rgba(239,68,68,0.15);
		border-radius: 8px;
		display: flex; align-items: center; justify-content: center;
		color: #ef4444;
	}
	.me .pdf-icon-wrap { background: rgba(255,255,255,0.15); color: #fff; }
	.pdf-info { flex: 1; min-width: 0; }
	.pdf-name { font-size: 12px; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: inherit; }
	.pdf-label { font-size: 10px; opacity: 0.65; margin-top: 2px; color: inherit; }
	.pdf-open-icon { flex-shrink: 0; opacity: 0.7; }

	/* Images */
	.msg-image-wrap { margin: -0.25rem -0.5rem 0.5rem -0.5rem; border-radius: 0.75rem; overflow: hidden; min-width: 200px; max-width: 100%; }
	.msg-img { display: block; width: 100%; height: auto; max-height: 280px; object-fit: cover; cursor: zoom-in; transition: opacity 0.15s; }
	.msg-img:hover { opacity: 0.92; }
	.msg-file-wrap { min-width: 220px; }
	.audio-player { width: 100%; max-width: 350px; margin-top: 0.25rem; }
	.audio-player audio { width: 100%; height: 40px; display: block; }

	/* Lightbox */
	.lightbox-overlay {
		position: fixed; inset: 0; z-index: 9999;
		background: rgba(0,0,0,0.88);
		display: flex; align-items: center; justify-content: center;
		cursor: zoom-out;
	}
	.lightbox-overlay img {
		max-width: 92vw; max-height: 92vh;
		object-fit: contain;
		border-radius: 0.75rem;
		box-shadow: 0 25px 80px rgba(0,0,0,0.6);
	}
	.lightbox-close {
		position: absolute; top: 1.25rem; right: 1.5rem;
		color: white; font-size: 2rem; cursor: pointer;
		background: rgba(255,255,255,0.15); border: none;
		width: 2.5rem; height: 2.5rem; border-radius: 50%;
		display: flex; align-items: center; justify-content: center;
		transition: background 0.15s;
	}
	.lightbox-close:hover { background: rgba(255,255,255,0.3); }

	.msg-time { font-size: 8px; opacity: 0.5; margin-top: 4px; display: block; text-transform: uppercase; font-weight: 800; }
	.me .msg-time { color: white; opacity: 0.7; }
	.avatar-box { width: 2.25rem; height: 2.25rem; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
	.icon-btn { width: 2.5rem; height: 2.5rem; display: flex; align-items: center; justify-content: center; border-radius: 0.75rem; transition: background 0.2s; }
	.icon-btn:hover { background: #f3f4f6; }
	.loading-overlay { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
	.empty-state { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding-top: 5rem; opacity: 0.5; }

	/* Waiting Room */
	.waiting-room {
		position: absolute; inset: 0; z-index: 100;
		background: rgba(250, 250, 250, 0.8);
		backdrop-filter: blur(8px);
		display: flex; align-items: center; justify-content: center;
		padding: 2rem;
	}
	.waiting-card {
		background: white; border-radius: 2rem; padding: 2.5rem;
		max-width: 400px; width: 100%; text-align: center;
		border: 1px solid #f1f5f9;
	}
	.waiting-icon-wrap {
		width: 4rem; height: 4rem; background: #fff7ed;
		border-radius: 1.25rem; display: flex; align-items: center; justify-content: center;
		margin: 0 auto 1.5rem;
	}
	.waiting-title { font-size: 1.25rem; font-weight: 900; text-transform: uppercase; letter-spacing: -0.02em; color: #0f172a; margin-bottom: 0.5rem; }
	.waiting-desc { font-size: 0.875rem; color: #64748b; line-height: 1.6; margin-bottom: 2rem; }
	
	.queue-status-box {
		background: #f8fafc; border-radius: 1.25rem; padding: 1.5rem;
		display: flex; align-items: center; justify-content: center;
		margin-bottom: 2rem; border: 1px solid #f1f5f9;
	}
	.queue-num-wrap { flex: 1; display: flex; flex-direction: column; gap: 4px; }
	.queue-label { font-size: 0.625rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; color: #94a3b8; }
	.queue-val { font-size: 1.5rem; font-weight: 900; color: #0f172a; }
	.queue-sep { width: 1px; height: 2.5rem; background: #e2e8f0; margin: 0 1.5rem; }
	
	.waiting-footer {
		display: flex; align-items: center; justify-content: center; gap: 8px;
		font-size: 0.625rem; font-weight: 800; text-transform: uppercase;
		letter-spacing: 0.05em; color: #94a3b8;
	}

	/* Toast */
	.toast {
		position: fixed; bottom: 6rem; right: 2rem; z-index: 200;
		background: #fff; border: 1px solid #f1f5f9; border-radius: 14px;
		padding: 12px 16px; display: flex; align-items: center; gap: 10px;
		box-shadow: 0 8px 30px rgba(0,0,0,0.12); font-size: 13px; color: #0f172a;
	}
	.toast-link { color: #4f46e5; font-weight: 700; background: none; border: none; cursor: pointer; margin-left: 4px; padding: 0; outline: none; text-decoration: underline; }
</style>
