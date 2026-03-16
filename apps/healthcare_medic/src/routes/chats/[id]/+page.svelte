<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { onMount } from 'svelte';
	import { ArrowLeft, Send, Paperclip, Image, FileText, Mic, X } from 'lucide-svelte';

	const chatId = $derived($page.params.id);

	let provider = $state(null);
	let conversation = $state(null);
	let messages = $state([]);
	let newMessage = $state('');
	let loading = $state(true);
	let sending = $state(false);
	let attachments = $state([]);
	let recording = $state(false);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();

		if (session) {
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();

			provider = providerData;

			if (provider) {
				await loadConversation();
			}
		}

		loading = false;
	});

	async function loadConversation() {
		// Mock data - you'll need to implement proper chat tables
		conversation = {
			id: chatId,
			participant_name: 'John Doe',
			participant_type: 'patient',
			participant_avatar: null
		};

		messages = [
			{
				id: '1',
				sender: 'patient',
				sender_name: 'John Doe',
				content: 'Hello doctor, I need to discuss my prescription',
				timestamp: new Date(Date.now() - 3600000).toISOString(),
				attachments: []
			},
			{
				id: '2',
				sender: 'provider',
				sender_name: provider?.full_name || 'You',
				content: 'Hi John, of course. What would you like to know?',
				timestamp: new Date(Date.now() - 3500000).toISOString(),
				attachments: []
			},
			{
				id: '3',
				sender: 'patient',
				sender_name: 'John Doe',
				content: 'Can I take it with food?',
				timestamp: new Date(Date.now() - 3400000).toISOString(),
				attachments: []
			}
		];
	}

	async function handleFileSelect(e: Event) {
		const input = e.target as HTMLInputElement;
		if (input.files && input.files.length > 0) {
			for (const file of Array.from(input.files)) {
				attachments = [
					...attachments,
					{
						file,
						name: file.name,
						type: file.type,
						size: file.size,
						preview: file.type.startsWith('image/') ? URL.createObjectURL(file) : null
					}
				];
			}
		}
	}

	function removeAttachment(index: number) {
		attachments = attachments.filter((_, i) => i !== index);
	}

	async function startRecording() {
		recording = true;
		// Implement voice recording logic here
		alert('Voice recording feature requires MediaRecorder API implementation');
	}

	async function stopRecording() {
		recording = false;
		// Stop recording and add to attachments
	}

	async function sendMessage() {
		if (!newMessage.trim() && attachments.length === 0) return;

		sending = true;

		try {
			// Upload attachments if any
			const uploadedAttachments = [];
			for (const attachment of attachments) {
				// Upload to Supabase storage
				const fileName = `${Date.now()}_${attachment.file.name}`;
				const { data, error } = await supabase.storage
					.from('chat-attachments')
					.upload(fileName, attachment.file);

				if (!error && data) {
					const { data: { publicUrl } } = supabase.storage
						.from('chat-attachments')
						.getPublicUrl(fileName);

					uploadedAttachments.push({
						url: publicUrl,
						type: attachment.type,
						name: attachment.name
					});
				}
			}

			// Add message to list (in real app, save to database)
			const message = {
				id: Date.now().toString(),
				sender: 'provider',
				sender_name: provider?.full_name || 'You',
				content: newMessage,
				timestamp: new Date().toISOString(),
				attachments: uploadedAttachments
			};

			messages = [...messages, message];
			newMessage = '';
			attachments = [];

			// Scroll to bottom
			setTimeout(() => {
				const messagesContainer = document.getElementById('messages-container');
				if (messagesContainer) {
					messagesContainer.scrollTop = messagesContainer.scrollHeight;
				}
			}, 100);
		} catch (error) {
			console.error('Error sending message:', error);
		} finally {
			sending = false;
		}
	}

	function formatTime(timestamp: string) {
		return new Date(timestamp).toLocaleTimeString('en-US', {
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function formatFileSize(bytes: number) {
		if (bytes < 1024) return bytes + ' B';
		if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
		return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
	}

	function getFileIcon(type: string) {
		if (type.startsWith('image/')) return Image;
		if (type.includes('pdf')) return FileText;
		return Paperclip;
	}
</script>

<div class="h-[calc(100vh-12rem)] flex flex-col bg-white rounded-lg shadow">
	<!-- Chat Header -->
	<div class="flex items-center gap-4 p-4 border-b border-gray-200">
		<a
			href="/chats"
			class="p-2 hover:bg-gray-100 rounded-md transition-colors"
		>
			<ArrowLeft class="h-5 w-5 text-gray-600" />
		</a>

		{#if conversation}
			<div class="flex items-center gap-3 flex-1">
				<div class="bg-primary-100 p-3 rounded-full">
					<span class="text-primary-600 font-semibold">
						{conversation.participant_name.charAt(0)}
					</span>
				</div>
				<div>
					<h3 class="font-semibold text-gray-900">{conversation.participant_name}</h3>
					<p class="text-sm text-gray-500 capitalize">{conversation.participant_type}</p>
				</div>
			</div>
		{/if}
	</div>

	<!-- Messages -->
	<div id="messages-container" class="flex-1 overflow-y-auto p-4 space-y-4">
		{#if loading}
			<div class="flex items-center justify-center h-full">
				<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
			</div>
		{:else}
			{#each messages as message}
				<div class="flex {message.sender === 'provider' ? 'justify-end' : 'justify-start'}">
					<div class="max-w-md {message.sender === 'provider' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-900'} rounded-lg p-3">
						{#if message.sender !== 'provider'}
							<p class="text-xs font-semibold mb-1 opacity-75">{message.sender_name}</p>
						{/if}

						{#if message.content}
							<p class="text-sm whitespace-pre-wrap">{message.content}</p>
						{/if}

						{#if message.attachments && message.attachments.length > 0}
							<div class="mt-2 space-y-2">
								{#each message.attachments as attachment}
									<a
										href={attachment.url}
										target="_blank"
										class="flex items-center gap-2 p-2 bg-white bg-opacity-20 rounded hover:bg-opacity-30 transition-colors"
									>
										<svelte:component this={getFileIcon(attachment.type)} class="h-4 w-4" />
										<span class="text-sm truncate">{attachment.name}</span>
									</a>
								{/each}
							</div>
						{/if}

						<p class="text-xs mt-2 opacity-75">{formatTime(message.timestamp)}</p>
					</div>
				</div>
			{/each}
		{/if}
	</div>

	<!-- Attachments Preview -->
	{#if attachments.length > 0}
		<div class="border-t border-gray-200 p-3 bg-gray-50">
			<div class="flex flex-wrap gap-2">
				{#each attachments as attachment, index}
					<div class="relative bg-white border border-gray-200 rounded-lg p-2 flex items-center gap-2 pr-8">
						{#if attachment.preview}
							<img src={attachment.preview} alt={attachment.name} class="h-12 w-12 object-cover rounded" />
						{:else}
							<div class="h-12 w-12 bg-gray-100 rounded flex items-center justify-center">
								<svelte:component this={getFileIcon(attachment.type)} class="h-6 w-6 text-gray-400" />
							</div>
						{/if}
						<div class="flex-1 min-w-0">
							<p class="text-sm font-medium text-gray-900 truncate">{attachment.name}</p>
							<p class="text-xs text-gray-500">{formatFileSize(attachment.size)}</p>
						</div>
						<button
							onclick={() => removeAttachment(index)}
							class="absolute top-1 right-1 p-1 bg-red-100 text-red-600 rounded-full hover:bg-red-200 transition-colors"
						>
							<X class="h-3 w-3" />
						</button>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Message Input -->
	<div class="border-t border-gray-200 p-4">
		<div class="flex items-end gap-2">
			<!-- Attachment Button -->
			<div class="relative">
				<input
					type="file"
					id="file-input"
					multiple
					accept="image/*,.pdf,.doc,.docx"
					onchange={handleFileSelect}
					class="hidden"
				/>
				<button
					onclick={() => document.getElementById('file-input')?.click()}
					class="p-2 text-gray-600 hover:bg-gray-100 rounded-md transition-colors"
					title="Attach file"
				>
					<Paperclip class="h-5 w-5" />
				</button>
			</div>

			<!-- Image Button -->
			<div class="relative">
				<input
					type="file"
					id="image-input"
					multiple
					accept="image/*"
					onchange={handleFileSelect}
					class="hidden"
				/>
				<button
					onclick={() => document.getElementById('image-input')?.click()}
					class="p-2 text-gray-600 hover:bg-gray-100 rounded-md transition-colors"
					title="Attach image"
				>
					<Image class="h-5 w-5" />
				</button>
			</div>

			<!-- Voice Note Button -->
			<button
				onclick={recording ? stopRecording : startRecording}
				class="p-2 {recording ? 'text-red-600 bg-red-50' : 'text-gray-600 hover:bg-gray-100'} rounded-md transition-colors"
				title={recording ? 'Stop recording' : 'Record voice note'}
			>
				<Mic class="h-5 w-5 {recording ? 'animate-pulse' : ''}" />
			</button>

			<!-- Message Input -->
			<textarea
				bind:value={newMessage}
				onkeydown={(e) => {
					if (e.key === 'Enter' && !e.shiftKey) {
						e.preventDefault();
						sendMessage();
					}
				}}
				placeholder="Type a message..."
				class="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent resize-none"
				rows="1"
			></textarea>

			<!-- Send Button -->
			<button
				onclick={sendMessage}
				disabled={sending || (!newMessage.trim() && attachments.length === 0)}
				class="p-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				title="Send message"
			>
				<Send class="h-5 w-5" />
			</button>
		</div>
	</div>
</div>
