<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { onMount, tick, onDestroy } from 'svelte';
	import { fly, fade } from 'svelte/transition';
	import { 
		ArrowLeft, Send, Paperclip, Image, 
		FileText, Mic, X, MoreVertical, 
		CheckCheck, Smile, Phone, Video, 
		Camera, Play, Maximize2, Download,
		ChevronLeft, ChevronRight, AlertCircle,
		User
	} from 'lucide-svelte';

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

	// Typing State
	let isTyping = $state(false);
	let otherUserTyping = $state(false);
	let typingTimeout: ReturnType<typeof setTimeout> | null = null;
	let typingChannel: any = null;

	// Camera & Viewer State
	let showCamera = $state(false);
	let videoElement = $state<HTMLVideoElement | null>(null);
	let selectedMedia = $state<any>(null); 
	let activeStream: MediaStream | null = null;

	// Recording State
	let isRecording = $state(false);
	let mediaRecorder: MediaRecorder | null = null;
	let audioChunks: Blob[] = [];
	let recordingTime = $state(0);
	let recordingInterval: ReturnType<typeof setInterval> | null = null;

	onMount(async () => {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) return;

			// 1. Get Provider Details
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();
			provider = providerData;

			if (provider) {
				// 2. Load Consultation Info
				const { data: consult } = await supabase
					.from('consultations')
					.select('*, profiles:patient_id(full_name, avatar_url)')
					.eq('id', chatId)
					.single();
				consultation = consult;

				if (consultation) {
					// 3. Harmonize Conversation (Ensure it exists in chat_conversations)
					await ensureConversation();
					
					// 4. Load Real Messages from chat_messages
					if (conversation) {
						const { data: msgData } = await supabase
							.from('chat_messages')
							.select('*')
							.eq('conversation_id', conversation.id)
							.order('created_at', { ascending: true });
						messages = msgData || [];

						// 5. Setup Real-Time
						setupRealtime();
					}
				}
			}
		} catch (err) {
			console.error('Chat initialization error:', err);
		} finally {
			loading = false;
			scrollToBottom();
		}
	});

	async function ensureConversation() {
		// Try to find existing conversation linked to this consultation
		const { data: existing } = await supabase
			.from('chat_conversations')
			.select('*')
			.eq('consultation_id', chatId)
			.single();

		if (existing) {
			conversation = existing;
		} else {
			// Create new one using the harmonized schema
			const { data: created, error } = await supabase
				.from('chat_conversations')
				.insert({
					consultation_id: chatId,
					tenant_id: consultation.tenant_id,
					branch_id: provider.id, // Using provider as branch context
					customer_id: consultation.patient_id,
					status: 'active'
				})
				.select()
				.single();
			
			if (!error) conversation = created;
		}
	}

	onDestroy(() => {
		if (typingChannel) supabase.removeChannel(typingChannel);
		if (recordingInterval) clearInterval(recordingInterval);
		stopCamera();
	});

	function setupRealtime() {
		if (!conversation) return;

		// Listen for messages in the conversation
		const messageSubscription = supabase
			.channel('chat_messages_realtime')
			.on('postgres_changes', { 
				event: 'INSERT', 
				schema: 'public', 
				table: 'chat_messages',
				filter: `conversation_id=eq.${conversation.id}`
			}, (payload) => {
				messages = [...messages, payload.new];
				scrollToBottom();
			})
			.subscribe();

		// Typing States (Broadcast)
		typingChannel = supabase.channel(`typing:${conversation.id}`);
		typingChannel
			.on('broadcast', { event: 'typing' }, ({ payload }: any) => {
				if (payload.userId !== provider.user_id) {
					otherUserTyping = payload.isTyping;
				}
			})
			.subscribe();
	}

	function handleTyping() {
		if (!typingChannel) return;
		if (!isTyping) {
			isTyping = true;
			typingChannel.send({
				type: 'broadcast',
				event: 'typing',
				payload: { userId: provider.user_id, isTyping: true }
			});
		}

		if (typingTimeout) clearTimeout(typingTimeout);
		typingTimeout = setTimeout(() => {
			isTyping = false;
			typingChannel.send({
				type: 'broadcast',
				event: 'typing',
				payload: { userId: provider.user_id, isTyping: false }
			});
		}, 3000);
	}

	async function startRecording() {
		try {
			const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
			mediaRecorder = new MediaRecorder(stream);
			audioChunks = [];

			mediaRecorder.ondataavailable = (event) => {
				audioChunks.push(event.data);
			};

			mediaRecorder.onstop = async () => {
				const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
				const file = new File([audioBlob], `voice_${Date.now()}.webm`, { type: 'audio/webm' });
				await uploadAndSend(file);
			};

			mediaRecorder.start();
			isRecording = true;
			recordingTime = 0;
			recordingInterval = setInterval(() => recordingTime++, 1000);
		} catch (err) {
			console.error('Mic access denied:', err);
			alert('Microphone access denied.');
		}
	}

	function stopRecording() {
		if (mediaRecorder && isRecording) {
			mediaRecorder.stop();
			mediaRecorder.stream.getTracks().forEach(track => track.stop());
			isRecording = false;
			if (recordingInterval) clearInterval(recordingInterval);
		}
	}

	function formatDuration(seconds: number) {
		const mins = Math.floor(seconds / 60);
		const secs = seconds % 60;
		return `${mins}:${secs.toString().padStart(2, '0')}`;
	}

	async function startCamera() {
		try {
			showCamera = true;
			activeStream = await navigator.mediaDevices.getUserMedia({ video: true });
			if (videoElement) videoElement.srcObject = activeStream;
		} catch (err) {
			console.error('Camera access denied:', err);
			alert('Camera access denied.');
			showCamera = false;
		}
	}

	function stopCamera() {
		if (activeStream) {
			activeStream.getTracks().forEach(track => track.stop());
			activeStream = null;
		}
		showCamera = false;
	}

	async function takeSnapshot() {
		if (!videoElement) return;
		const canvas = document.createElement('canvas');
		canvas.width = videoElement.videoWidth;
		canvas.height = videoElement.videoHeight;
		const ctx = canvas.getContext('2d');
		ctx?.drawImage(videoElement, 0, 0);
		
		canvas.toBlob((blob) => {
			if (blob) {
				const file = new File([blob], `snap_${Date.now()}.jpg`, { type: 'image/jpeg' });
				attachments = [...attachments, { 
					file, 
					name: file.name, 
					type: 'image/jpeg', 
					preview: URL.createObjectURL(blob) 
				}];
				stopCamera();
			}
		}, 'image/jpeg');
	}

	async function uploadMedia() {
		const uploaded = [];
		for (const attr of attachments) {
			const path = `chat/${conversation.id}/${Date.now()}_${attr.name}`;
			const { error } = await supabase.storage.from('chat-attachments').upload(path, attr.file);
			if (error) continue;

			const { data: { publicUrl } } = supabase.storage.from('chat-attachments').getPublicUrl(path);
			uploaded.push({ url: publicUrl, type: attr.type, name: attr.name, size: attr.file.size });
		}
		return uploaded;
	}

	async function sendMessage() {
		if (!newMessage.trim() && attachments.length === 0) return;
		if (!conversation) return;
		sending = true;

		try {
			const mediaItems = await uploadMedia();
			
			// Map to the user's specific chat_messages schema
			const { error } = await supabase
				.from('chat_messages')
				.insert({
					conversation_id: conversation.id,
					sender_id: provider.user_id,
					sender_type: 'medic',
					message_text: newMessage,
					message_type: mediaItems.length > 0 ? (mediaItems[0].type.includes('image') ? 'image' : (mediaItems[0].type.includes('audio') ? 'audio' : 'media')) : 'text',
					media_url: mediaItems.length > 0 ? mediaItems[0].url : null,
					media_size_bytes: mediaItems.length > 0 ? mediaItems[0].size : null,
					metadata: { attachments: mediaItems }
				});

			if (error) throw error;
			
			newMessage = '';
			attachments = [];
			scrollToBottom();
		} catch (err) {
			console.error('Send error:', err);
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

	function formatTime(timestamp: string) {
		return new Date(timestamp).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
	}

	async function handleFileSelect(e: Event) {
		const input = e.target as HTMLInputElement;
		if (input.files) {
			for (const file of Array.from(input.files)) {
				if (file.type.startsWith('video/') && file.size > VIDEO_SIZE_LIMIT) {
					alert(`Video too large: ${file.name}`);
					continue;
				}
				if (file.type.startsWith('audio/') && file.size > 20 * 1024 * 1024) {
					alert(`Audio file too large: ${file.name}`);
					continue;
				}

				attachments = [...attachments, { 
					file, name: file.name, type: file.type, size: file.size,
					preview: file.type.startsWith('image/') ? URL.createObjectURL(file) : null
				}];
			}
		}
	}
</script>

<div class="fixed inset-0 lg:left-64 bg-gray-50 flex flex-col z-[45]" in:fly={{ x: 20, duration: 400 }} out:fade>
	<!-- Chat Header -->
	<header class="h-16 flex items-center justify-between px-4 lg:px-8 bg-white border-b border-gray-100 shadow-sm z-10">
		<div class="flex items-center gap-4">
			<a
				href="/consultations"
				class="p-2 hover:bg-gray-100 rounded-xl transition-all text-gray-500 hover:text-gray-900"
			>
				<ArrowLeft class="h-5 w-5" />
			</a>

			{#if consultation}
				<div class="flex items-center gap-3">
					<div class="relative">
						<div class="h-10 w-10 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden border border-gray-100">
							{#if consultation.profiles?.avatar_url}
								<img src={consultation.profiles.avatar_url} alt="" class="h-full w-full object-cover" />
							{:else}
								<div class="h-full w-full flex items-center justify-center bg-gray-200">
									<User class="h-6 w-6 text-gray-400" />
								</div>
							{/if}
						</div>
						<div class="absolute bottom-0 right-0 h-3 w-3 bg-emerald-500 border-2 border-white rounded-full"></div>
					</div>
					<div>
						<div class="flex items-center gap-2">
							<h3 class="text-sm font-bold text-gray-900">{consultation.profiles?.full_name || 'Patient'}</h3>
							{#if conversation?.consultation_code}
								<span class="px-1.5 py-0.5 bg-gray-100 text-[9px] font-black text-gray-500 rounded uppercase">
									{conversation.consultation_code}
								</span>
							{/if}
						</div>
						<div class="flex items-center gap-2">
							{#if otherUserTyping}
								<span class="text-[10px] font-black text-emerald-500 uppercase tracking-widest animate-pulse">Typing...</span>
							{:else}
								<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Secure Consultation</p>
							{/if}
						</div>
					</div>
				</div>
			{/if}
		</div>

		<div class="flex items-center gap-2">
			<button class="p-2.5 text-gray-400 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-all">
				<Phone class="h-5 w-5" />
			</button>
			<button class="p-2.5 text-gray-400 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-all">
				<Video class="h-5 w-5" />
			</button>
			<button class="p-2.5 text-gray-400 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-all">
				<MoreVertical class="h-5 w-5" />
			</button>
		</div>
	</header>

	<!-- Messages Area -->
	<div 
		bind:this={messagesContainer}
		class="flex-1 overflow-y-auto p-4 lg:p-6 space-y-6 scroll-smooth bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] bg-fixed"
	>
		{#if loading}
			<div class="flex items-center justify-center h-full">
				<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
			</div>
		{:else}
			{#each messages as message}
				{@const isMe = message.sender_id === provider?.user_id}
				<div class="flex {isMe ? 'justify-end' : 'justify-start items-end gap-3'}">
					{#if !isMe}
						<div class="h-8 w-8 rounded-full overflow-hidden bg-gray-100 flex-shrink-0 border border-gray-200 mb-6">
							{#if consultation?.profiles?.avatar_url}
								<img src={consultation.profiles.avatar_url} alt="" class="h-full w-full object-cover" />
							{:else}
								<div class="h-full w-full flex items-center justify-center bg-gray-200">
									<User class="h-4 w-4 text-gray-400" />
								</div>
							{/if}
						</div>
					{/if}

					<div class="max-w-[85%] md:max-w-[70%] space-y-1">
						<div class="flex items-center gap-2 px-1 mb-0.5">
							<span class="text-[10px] font-black uppercase tracking-tighter text-gray-400">
								{isMe ? 'You' : (consultation?.profiles?.full_name || 'Patient')}
							</span>
						</div>
						
						<div 
							class="relative p-3 rounded-2xl shadow-sm transition-all {isMe 
								? 'bg-gray-900 text-white rounded-tr-none' 
								: 'bg-white text-gray-900 border border-gray-100 rounded-tl-none'}"
						>
							<!-- Attachments Rendering -->
							{#if message.metadata?.attachments && message.metadata.attachments.length > 0}
								<div class="mb-3 space-y-2">
									{#each message.metadata.attachments as attr}
										{#if attr.type.startsWith('image/')}
											<button 
												onclick={() => selectedMedia = attr}
												class="w-full rounded-xl overflow-hidden border border-white/10 group relative"
											>
												<img src={attr.url} alt="" class="w-full h-auto max-h-64 object-cover" />
												<div class="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
													<Maximize2 class="h-8 w-8 text-white shadow-xl" />
												</div>
											</button>
										{:else if attr.type.startsWith('video/')}
											<button 
												onclick={() => selectedMedia = attr}
												class="w-full rounded-xl overflow-hidden border border-white/10 relative group bg-black/10 aspect-video flex items-center justify-center"
											>
												<Play class="h-12 w-12 text-white fill-white/20" />
												<span class="absolute bottom-2 right-2 px-2 py-0.5 bg-black/60 rounded text-[10px] text-white font-bold">VIDEO</span>
											</button>
										{:else if attr.type.includes('pdf')}
											<button 
												onclick={() => selectedMedia = attr}
												class="flex items-center gap-3 p-3 rounded-xl border {isMe ? 'bg-white/10 border-white/10 hover:bg-white/20' : 'bg-gray-50 border-gray-100 hover:bg-gray-100'} transition-all text-left w-full"
											>
												<div class="p-2 bg-red-500/10 rounded-lg">
													<FileText class="h-6 w-6 text-red-500" />
												</div>
												<div class="min-w-0">
													<p class="text-xs font-bold truncate">{attr.name}</p>
													<p class="text-[10px] opacity-60 font-medium">PDF Document • {(attr.size / 1024 / 1024).toFixed(1)}MB</p>
												</div>
											</button>
										{:else if attr.type.includes('audio')}
											<div class="flex items-center gap-3 p-3 rounded-xl border {isMe ? 'bg-white/10 border-white/10' : 'bg-gray-50 border-gray-100'} w-full">
												<button 
													class="h-10 w-10 flex-shrink-0 flex items-center justify-center rounded-full {isMe ? 'bg-white/20 hover:bg-white/30' : 'bg-gray-900 text-white hover:bg-black'} transition-all"
													onclick={(e) => {
														const audio = (e.currentTarget.nextElementSibling as HTMLAudioElement);
														if (audio.paused) audio.play();
														else audio.pause();
													}}
												>
													<Play class="h-5 w-5 fill-current" />
												</button>
												<audio src={attr.url} class="hidden"></audio>
												<div class="flex-1">
													<div class="h-1 bg-gray-200 rounded-full overflow-hidden">
														<div class="h-full bg-emerald-500 w-0"></div>
													</div>
													<div class="flex justify-between mt-1 text-[10px] font-bold opacity-60">
														<span>Voice Note</span>
														<span>{(attr.size / 1024).toFixed(0)} KB</span>
													</div>
												</div>
											</div>
										{:else}
											<div class="p-3 bg-white/10 rounded-xl flex items-center gap-2">
												<Paperclip class="h-4 w-4" />
												<span class="text-xs">{attr.name}</span>
											</div>
										{/if}
									{/each}
								</div>
							{/if}

							{#if message.message_text}
								<p class="text-sm leading-relaxed whitespace-pre-wrap">{message.message_text}</p>
							{/if}

							<div class="flex items-center justify-end gap-1.5 mt-2 opacity-60">
								<span class="text-[9px] font-bold tracking-tighter">{formatTime(message.created_at)}</span>
								{#if isMe}
									<CheckCheck class="h-3 w-3 text-emerald-400" />
								{/if}
							</div>
						</div>
					</div>
				</div>
			{/each}
		{/if}
	</div>

	<!-- Interaction Bar -->
	<div class="p-4 lg:p-6 bg-transparent">
		<div class="max-w-4xl mx-auto flex items-end gap-3 bg-white p-3 rounded-2xl shadow-xl border border-gray-100 backdrop-blur-md">
			<div class="flex items-center mb-1">
				<input type="file" id="media-upload" class="hidden" multiple onchange={handleFileSelect} />
				<button 
					onclick={() => document.getElementById('media-upload')?.click()}
					class="p-2 text-gray-400 hover:text-gray-900 transition-all"
				>
					<Paperclip class="h-6 w-6" />
				</button>
				<button 
					onclick={startCamera}
					class="p-2 text-gray-400 hover:text-gray-900 transition-colors"
				>
					<Camera class="h-6 w-6" />
				</button>
			</div>

			<!-- Input Container -->
			<div class="flex-1 relative">
				{#if isRecording}
					<div class="absolute inset-0 bg-white flex items-center justify-between px-4 z-10 transition-all" in:fade>
						<div class="flex items-center gap-3">
							<div class="h-3 w-3 bg-red-500 rounded-full animate-pulse"></div>
							<span class="text-sm font-black uppercase tracking-widest text-red-500">Recording</span>
							<span class="text-xs font-mono font-bold text-gray-400">{formatDuration(recordingTime)}</span>
						</div>
						<button 
							onclick={stopRecording}
							class="px-4 py-1.5 bg-gray-900 text-white text-[10px] font-black uppercase tracking-widest rounded-lg hover:bg-black transition-all"
						>
							Stop & Send
						</button>
					</div>
				{/if}

				<textarea
					rows="1"
					bind:value={newMessage}
					oninput={handleTyping}
					onkeydown={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), sendMessage())}
					placeholder="Type a clinical message..."
					class="w-full bg-gray-50 border-none rounded-2xl py-3 px-4 text-sm focus:ring-2 focus:ring-gray-900/5 transition-all resize-none max-h-32"
				></textarea>
			</div>

			<!-- Action Buttons (Mic & Send) -->
			<div class="flex items-center gap-1 mb-1">
				<button 
					onclick={startRecording}
					class="p-3 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-2xl transition-all"
				>
					<Mic class="h-6 w-6" />
				</button>
				
				<button
					onclick={sendMessage}
					disabled={(!newMessage.trim() && attachments.length === 0) || sending}
					class="p-3 bg-gray-900 text-white rounded-2xl hover:bg-black disabled:opacity-50 disabled:grayscale transition-all shadow-lg shadow-gray-200"
				>
					{#if sending}
						<div class="h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
					{:else}
						<Send class="h-5 w-5" />
					{/if}
				</button>
			</div>
		</div>

		{#if attachments.length > 0}
			<div class="max-w-4xl mx-auto mt-3 flex flex-wrap gap-2 px-1 pb-2">
				{#each attachments as attr, i}
					<div class="group relative h-16 w-16 bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm animate-in zoom-in-95">
						{#if attr.preview}
							<img src={attr.preview} alt="" class="h-full w-full object-cover" />
						{:else if attr.type.startsWith('audio/')}
							<div class="h-full w-full flex items-center justify-center bg-gray-50">
								<Mic class="h-6 w-6 text-gray-400" />
							</div>
						{:else}
							<div class="h-full w-full flex items-center justify-center bg-gray-50">
								<FileText class="h-6 w-6 text-gray-400" />
							</div>
						{/if}
						<button 
							onclick={() => attachments = attachments.filter((_, idx) => idx !== i)}
							class="absolute top-0.5 right-0.5 p-1 bg-gray-900/60 text-white rounded-full opacity-0 group-hover:opacity-100 transition-all hover:bg-gray-900"
						>
							<X class="h-3 w-3" />
						</button>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>

<!-- Camera Modal -->
{#if showCamera}
	<div class="fixed inset-0 bg-black/90 z-[100] flex flex-col items-center justify-center p-4" transition:fade>
		<div class="relative w-full max-w-2xl aspect-video rounded-3xl overflow-hidden bg-gray-900 border border-white/10 shadow-2xl">
			<video bind:this={videoElement} autoplay playsinline class="w-full h-full object-cover"></video>
			<div class="absolute bottom-6 left-1/2 -translate-x-1/2 flex items-center gap-6">
				<button 
					onclick={stopCamera}
					class="p-4 bg-white/10 hover:bg-white/20 text-white rounded-2xl backdrop-blur-md transition-all"
				>
					<X class="h-8 w-8" />
				</button>
				<button 
					onclick={takeSnapshot}
					class="p-1 border-4 border-white rounded-full transition-transform active:scale-90"
				>
					<div class="h-16 w-16 bg-white rounded-full"></div>
				</button>
			</div>
		</div>
	</div>
{/if}

<!-- Media Lightbox -->
{#if selectedMedia}
	<div class="fixed inset-0 bg-black/95 z-[100] flex flex-col" transition:fade>
		<header class="h-16 flex items-center justify-between px-6 border-b border-white/5 bg-black/40 backdrop-blur-xl">
			<div class="flex items-center gap-4">
				<button 
					onclick={() => selectedMedia = null}
					class="p-2 text-white/60 hover:text-white transition-all"
				>
					<ArrowLeft class="h-6 w-6" />
				</button>
				<div>
					<p class="text-sm font-bold text-white">{selectedMedia.name}</p>
					<p class="text-[10px] text-white/40 font-bold uppercase tracking-[0.2em]">Medical Media Archive</p>
				</div>
			</div>
			<div class="flex items-center gap-3">
				<a 
					href={selectedMedia.url} 
					download={selectedMedia.name}
					target="_blank"
					class="p-3 bg-white/10 hover:bg-white/20 text-white rounded-xl transition-all flex items-center gap-2"
				>
					<Download class="h-5 w-5" />
					<span class="text-xs font-bold">Download</span>
				</a>
			</div>
		</header>

		<div class="flex-1 flex items-center justify-center p-4 lg:p-12 overflow-hidden">
			{#if selectedMedia.type.startsWith('image/')}
				<img 
					src={selectedMedia.url} 
					alt="" 
					class="max-w-full max-h-full object-contain rounded-xl shadow-2xl animate-in zoom-in-95 duration-500" 
				/>
			{:else if selectedMedia.type.startsWith('video/')}
				<video 
					src={selectedMedia.url} 
					controls 
					autoplay 
					class="max-w-full max-h-full rounded-xl shadow-2xl animate-in zoom-in-95"
				></video>
			{:else if selectedMedia.type.includes('pdf')}
				<iframe 
					src={selectedMedia.url} 
					class="w-full h-full max-w-5xl bg-white rounded-xl shadow-2xl"
					title="PDF Viewer"
				></iframe>
			{/if}
		</div>
	</div>
{/if}

<style>
	:global(body) {
		overflow: hidden !important;
	}
	textarea {
		scrollbar-width: none;
	}
	textarea::-webkit-scrollbar {
		display: none;
	}
</style>
