<script lang="ts">
	/**
	 * TELEMEDICINE INTERACTION HUB
	 * Final Stabilized Version (Post-Diagnostic)
	 */
	import { onMount, tick, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { fly, fade } from 'svelte/transition';
	import { 
		ArrowLeft, Send, Paperclip, Mic, X, MoreVertical, 
		CheckCheck, Smile, Phone, Video, Loader2, Camera,
		Play, Maximize2, Download, FileText, User, ChevronRight,
		AlertCircle
	} from 'lucide-svelte';

	// 1. Reactive Core
	const chatId = $derived($page.params.id);
	const VIDEO_SIZE_LIMIT = 100 * 1024 * 1024;

	let provider = $state<any>(null);
	let consultation = $state<any>(null);
	let conversation = $state<any>(null);
	let messages = $state<any[]>([]);
	let newMessage = $state('');
	let loading = $state(true);
	let sending = $state(false);
	let messagesContainer = $state<HTMLElement | null>(null);

	// 2. Feature State
	let isTyping = $state(false);
	let otherUserTyping = $state(false);
	let typingTimeout: ReturnType<typeof setTimeout> | null = null;
	let typingChannel: any = null;
	let attachments = $state<any[]>([]);

	// 3. Media State
	let showCamera = $state(false);
	let videoElement = $state<HTMLVideoElement | null>(null);
	let selectedMedia = $state<any>(null); 
	let activeStream: MediaStream | null = null;
	let isRecording = $state(false);
	let mediaRecorder: MediaRecorder | null = null;
	let audioChunks: Blob[] = [];
	let recordingTime = $state(0);
	let recordingInterval: ReturnType<typeof setInterval> | null = null;

	// 4. Lifecycle & Init
	let initialized = false;

	$effect(() => {
		if (!initialized && chatId) {
			initialized = true;
			initChat();
		}
	});

	onDestroy(() => {
		if (typingChannel) supabase.removeChannel(typingChannel);
		if (recordingInterval) clearInterval(recordingInterval);
		if (activeStream) activeStream.getTracks().forEach(t => t.stop());
		supabase.removeAllChannels();
	});

	async function initChat() {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) return;

			// Fetch Clinical Identity
			const { data: pData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();
			provider = pData;

			// Fetch Consultation Context
			const { data: cData } = await supabase
				.from('consultations')
				.select(`
					*,
					profiles:patient_id (full_name, avatar_url)
				`)
				.eq('id', chatId)
				.single();
			consultation = cData;

			if (consultation) {
				await ensureConversation();
				if (conversation) {
					await loadMessages();
					setupRealtime();
				}
			}
		} catch (err) {
			console.error('Chat Init Error:', err);
		} finally {
			loading = false;
			await tick();
			scrollToBottom();
		}
	}

	async function ensureConversation() {
		const { data: existing } = await supabase
			.from('chat_conversations')
			.select('*')
			.eq('consultation_id', chatId)
			.maybeSingle();

		if (existing) {
			conversation = existing;
		} else {
			const { data: created, error } = await supabase
				.from('chat_conversations')
				.insert({ 
					consultation_id: chatId, 
					status: 'active'
				})
				.select()
				.single();
			if (!error) conversation = created;
		}
	}

	async function loadMessages() {
		const { data } = await supabase
			.from('chat_messages')
			.select('*')
			.eq('conversation_id', conversation.id)
			.order('created_at', { ascending: true });
		messages = data || [];
	}

	function setupRealtime() {
		supabase.channel(`chat:${conversation.id}`)
			.on('postgres_changes', { 
				event: 'INSERT', 
				schema: 'public', 
				table: 'chat_messages',
				filter: `conversation_id=eq.${conversation.id}`
			}, (payload) => {
				if (payload.new.sender_id !== provider?.user_id) {
					messages = [...messages, payload.new];
					scrollToBottom();
				}
			})
			.subscribe();

		typingChannel = supabase.channel(`typing:${conversation.id}`);
		typingChannel
			.on('broadcast', { event: 'typing' }, ({ payload }: any) => {
				if (payload.userId !== provider?.user_id) {
					otherUserTyping = payload.isTyping;
				}
			})
			.subscribe();
	}

	// 5. User Actions
	async function sendMessage() {
		if ((!newMessage.trim() && attachments.length === 0) || !conversation || sending) return;
		sending = true;
		try {
			const mediaItems = await uploadAttachments();
			
			const { data: sent, error } = await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: provider.user_id,
					sender_type: 'medic',
					message_text: newMessage,
					metadata: { attachments: mediaItems }
				})
				.select()
				.single();

			if (!error && sent) {
				messages = [...messages, sent];
				newMessage = '';
				attachments = [];
				scrollToBottom();
			}
		} finally {
			sending = false;
		}
	}

	async function uploadAttachments() {
		const uploaded = [];
		for (const attr of attachments) {
			const path = `chat/${conversation.id}/${Date.now()}_${attr.name}`;
			const { error } = await supabase.storage.from('chat-attachments').upload(path, attr.file);
			if (error) continue;
			const { data: { publicUrl } } = supabase.storage.from('chat-attachments').getPublicUrl(path);
			uploaded.push({ url: publicUrl, type: attr.type, name: attr.name, size: attr.size });
		}
		return uploaded;
	}

	function handleTyping() {
		if (!typingChannel || isTyping) return;
		isTyping = true;
		typingChannel.send({ type: 'broadcast', event: 'typing', payload: { userId: provider.user_id, isTyping: true }});
		if (typingTimeout) clearTimeout(typingTimeout);
		typingTimeout = setTimeout(() => {
			isTyping = false;
			typingChannel.send({ type: 'broadcast', event: 'typing', payload: { userId: provider.user_id, isTyping: false }});
		}, 3000);
	}

	async function scrollToBottom() {
		await tick();
		if (messagesContainer) {
			messagesContainer.scrollTo({ top: messagesContainer.scrollHeight, behavior: 'smooth' });
		}
	}

	// 6. Media Handlers
	async function startRecording() {
		const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
		mediaRecorder = new MediaRecorder(stream);
		audioChunks = [];
		mediaRecorder.ondataavailable = e => audioChunks.push(e.data);
		mediaRecorder.onstop = async () => {
			const blob = new Blob(audioChunks, { type: 'audio/webm' });
			const file = new File([blob], `voice_${Date.now()}.webm`, { type: 'audio/webm' });
			attachments = [...attachments, { file, name: file.name, type: file.type, size: file.size, preview: null }];
		};
		mediaRecorder.start();
		isRecording = true;
		recordingTime = 0;
		recordingInterval = setInterval(() => recordingTime++, 1000);
	}

	function stopRecording() {
		if (mediaRecorder) {
			mediaRecorder.stop();
			mediaRecorder.stream.getTracks().forEach(t => t.stop());
		}
		isRecording = false;
		if (recordingInterval) clearInterval(recordingInterval);
	}

	async function startCamera() {
		showCamera = true;
		activeStream = await navigator.mediaDevices.getUserMedia({ video: true });
		if (videoElement) videoElement.srcObject = activeStream;
	}

	function stopCamera() {
		if (activeStream) activeStream.getTracks().forEach(t => t.stop());
		showCamera = false;
	}

	function takeSnapshot() {
		const canvas = document.createElement('canvas');
		canvas.width = videoElement!.videoWidth;
		canvas.height = videoElement!.videoHeight;
		canvas.getContext('2d')?.drawImage(videoElement!, 0, 0);
		canvas.toBlob(blob => {
			if (blob) {
				const file = new File([blob], `snap_${Date.now()}.jpg`, { type: 'image/jpeg' });
				attachments = [...attachments, { file, name: file.name, type: 'image/jpeg', size: blob.size, preview: URL.createObjectURL(blob) }];
				stopCamera();
			}
		}, 'image/jpeg');
	}

	function handleFileSelect(e: Event) {
		const files = (e.target as HTMLInputElement).files;
		if (files) {
			for (const f of Array.from(files)) {
				attachments = [...attachments, { file: f, name: f.name, type: f.type, size: f.size, preview: f.type.startsWith('image/') ? URL.createObjectURL(f) : null }];
			}
		}
	}
</script>

<div class="fixed inset-0 lg:left-64 bg-slate-50 flex flex-col z-[45]" in:fly={{ x: 20, duration: 400 }}>
	{#if loading}
		<div class="flex-1 flex flex-col items-center justify-center space-y-4 text-slate-400">
			<Loader2 class="h-10 w-10 animate-spin text-blue-600" />
			<p class="text-xs font-black uppercase tracking-widest animate-pulse">Establishing Secure Clinical Line</p>
		</div>
	{:else}
		<!-- Header -->
		<header class="h-16 flex items-center justify-between px-4 lg:px-8 bg-white border-b border-slate-100 shadow-sm z-10">
			<div class="flex items-center gap-4">
				<a href="/consultations" class="p-2 hover:bg-slate-100 rounded-xl transition-all text-slate-500">
					<ArrowLeft class="h-5 w-5" />
				</a>

				{#if consultation}
					<div class="flex items-center gap-3">
						<div class="relative">
							<div class="h-10 w-10 bg-slate-100 rounded-full flex items-center justify-center overflow-hidden border border-slate-100">
								{#if consultation.profiles?.avatar_url}
									<img src={consultation.profiles.avatar_url} alt="" class="h-full w-full object-cover" />
								{:else}
									<User class="h-6 w-6 text-slate-300" />
								{/if}
							</div>
							<div class="absolute bottom-0 right-0 h-3 w-3 bg-emerald-500 border-2 border-white rounded-full"></div>
						</div>
						<div>
							<h3 class="text-sm font-bold text-slate-900">{consultation.profiles?.full_name || 'Patient'}</h3>
							<p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
								{otherUserTyping ? 'Typing...' : 'Secure Connection'}
							</p>
						</div>
					</div>
				{/if}
			</div>
			
			<div class="flex items-center gap-2">
				<button class="p-2.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all"><Phone class="h-5 w-5" /></button>
				<button class="p-2.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all"><Video class="h-5 w-5" /></button>
			</div>
		</header>

		<!-- Messages -->
		<div bind:this={messagesContainer} class="flex-1 overflow-y-auto p-4 lg:p-6 space-y-6 scroll-smooth">
			{#each messages as msg}
				{@const isMe = msg.sender_id === provider?.user_id}
				<div class="flex {isMe ? 'justify-end' : 'justify-start items-end gap-3'}">
					<div class="max-w-[85%] md:max-w-[70%] space-y-1">
						<div class="p-3 rounded-2xl shadow-sm {isMe ? 'bg-slate-900 text-white rounded-tr-none' : 'bg-white text-slate-900 border border-slate-100 rounded-tl-none'}">
							{#if msg.metadata?.attachments}
								<div class="mb-2 space-y-1">
									{#each msg.metadata.attachments as attr}
										{#if attr.type.startsWith('image/')}
											<img src={attr.url} alt="" class="rounded-lg max-h-64 w-full object-cover cursor-pointer" onclick={() => selectedMedia = attr} />
										{:else}
											<div class="p-2 bg-slate-100/10 rounded-lg flex items-center gap-2 text-xs">
												<Paperclip class="h-3 w-3" /> {attr.name}
											</div>
										{/if}
									{/each}
								</div>
							{/if}
							<p class="text-sm whitespace-pre-wrap">{msg.message_text}</p>
							<div class="flex justify-end mt-1 opacity-40 text-[9px] font-bold">
								{new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
							</div>
						</div>
					</div>
				</div>
			{/each}
			{#if messages.length === 0}
				<div class="flex flex-col items-center justify-center py-20 text-slate-300">
					<MessageSquare class="h-12 w-12 mb-4 opacity-20" />
					<p class="text-xs font-bold uppercase tracking-[0.3em]">No Session History</p>
				</div>
			{/if}
		</div>

		<!-- Interaction Bar -->
		<div class="p-4 lg:p-6 pb-8">
			<div class="max-w-4xl mx-auto flex flex-col gap-3">
				{#if attachments.length > 0}
					<div class="flex flex-wrap gap-2 px-1">
						{#each attachments as attr, i}
							<div class="relative h-12 w-12 rounded-lg overflow-hidden border border-slate-200">
								{#if attr.preview}<img src={attr.preview} alt="" class="h-full w-full object-cover" />{/if}
								<button class="absolute top-0 right-0 p-1 bg-black/60 text-white" onclick={() => attachments = attachments.filter((_, idx) => idx !== i)}><X class="h-3 w-3" /></button>
							</div>
						{/each}
					</div>
				{/if}

				<div class="flex items-end gap-3 bg-white p-2 rounded-2xl shadow-xl border border-slate-100">
					<div class="flex gap-1 mb-1">
						<input type="file" id="files" class="hidden" multiple onchange={handleFileSelect} />
						<button onclick={() => document.getElementById('files')?.click()} class="p-2 text-slate-400 hover:text-slate-900"><Paperclip class="h-6 w-6" /></button>
						<button onclick={startCamera} class="p-2 text-slate-400 hover:text-slate-900"><Camera class="h-6 w-6" /></button>
					</div>

					<div class="flex-1 relative">
						{#if isRecording}
							<div class="absolute inset-0 bg-white flex items-center justify-between px-4 z-10 rounded-xl" in:fade>
								<div class="flex items-center gap-3"><div class="h-2 w-2 bg-red-500 rounded-full animate-ping"></div><span class="text-xs font-bold text-red-500 tracking-widest">{recordingTime}s</span></div>
								<button class="text-[10px] font-black uppercase text-slate-900" onclick={stopRecording}>Stop & Attach</button>
							</div>
						{/if}
						<textarea bind:value={newMessage} oninput={handleTyping} placeholder="Enter clinical notes..." class="w-full bg-slate-50 border-none rounded-xl py-3 px-4 text-sm resize-none" rows="1"></textarea>
					</div>

					<div class="flex gap-1 mb-1">
						<button onclick={startRecording} class="p-2 text-slate-400 hover:text-slate-900"><Mic class="h-6 w-6" /></button>
						<button onclick={sendMessage} disabled={sending} class="p-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 shadow-lg shadow-blue-100 disabled:opacity-50">
							{#if sending}<Loader2 class="h-5 w-5 animate-spin" />{:else}<Send class="h-5 w-5" />{/if}
						</button>
					</div>
				</div>
			</div>
		</div>
	{/if}
</div>

{#if showCamera}
	<div class="fixed inset-0 bg-black/95 z-[100] flex flex-col items-center justify-center" transition:fade>
		<video bind:this={videoElement} autoplay playsinline class="max-w-full max-h-[70vh] rounded-3xl"></video>
		<div class="mt-8 flex gap-6">
			<button onclick={stopCamera} class="p-4 bg-white/10 text-white rounded-2xl"><X class="h-8 w-8" /></button>
			<button onclick={takeSnapshot} class="h-20 w-20 bg-white rounded-full border-4 border-white/20 active:scale-90 transition-all"></button>
		</div>
	</div>
{/if}

{#if selectedMedia}
	<div class="fixed inset-0 bg-black z-[100] flex flex-col" transition:fade>
		<header class="h-16 flex items-center px-6 justify-between text-white border-b border-white/10">
			<button onclick={() => selectedMedia = null}><ArrowLeft /></button>
			<span class="text-xs font-bold uppercase tracking-widest">Media Inspection</span>
			<a href={selectedMedia.url} download class="p-2 bg-white/10 rounded-lg"><Download class="h-5 w-5" /></a>
		</header>
		<div class="flex-1 flex items-center justify-center p-4">
			<img src={selectedMedia.url} alt="" class="max-w-full max-h-full object-contain shadow-2xl" />
		</div>
	</div>
{/if}

<style>
	:global(body) { overflow: hidden !important; }
	textarea { scrollbar-width: none; }
</style>
