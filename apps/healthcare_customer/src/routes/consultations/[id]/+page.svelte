<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import {
		Video,
		VideoOff,
		Mic,
		MicOff,
		Phone,
		MessageSquare,
		Send,
		FileText,
		ArrowLeft,
		Clock
	} from 'lucide-svelte';
	import { AgoraService } from '$lib/agora';
	import { supabase } from '$lib/supabase';
	import { authStore } from '$lib/stores/auth.svelte';
	import type { PageData } from './$types';

	export let data: PageData;

	let { consultation } = $derived(data);

	// Agora state
	let agoraService: AgoraService | null = null;
	let isVideoEnabled = $state(true);
	let isAudioEnabled = $state(true);
	let isConnected = $state(false);
	let isConnecting = $state(false);
	let remoteUsers = $state<any[]>([]);

	// Chat state
	let messages = $state<any[]>([]);
	let newMessage = $state('');
	let showChat = $state(false);

	// Timer
	let consultationDuration = $state(0);
	let durationInterval: any = null;

	onMount(async () => {
		if (consultation.type === 'video' || consultation.type === 'audio') {
			await initializeAgora();
		}

		// Load chat messages
		await loadMessages();

		// Subscribe to new messages
		const messageSubscription = supabase
			.channel(`consultation:${consultation.id}`)
			.on(
				'postgres_changes',
				{
					event: 'INSERT',
					schema: 'public',
					table: 'consultation_messages',
					filter: `consultation_id=eq.${consultation.id}`
				},
				(payload) => {
					messages = [...messages, payload.new];
				}
			)
			.subscribe();

		// Start duration timer if consultation is in progress
		if (consultation.status === 'in_progress' && consultation.started_at) {
			startDurationTimer();
		}

		return () => {
			messageSubscription.unsubscribe();
		};
	});

	onDestroy(async () => {
		if (agoraService) {
			await agoraService.leave();
		}
		if (durationInterval) {
			clearInterval(durationInterval);
		}
	});

	async function initializeAgora() {
		try {
			isConnecting = true;

			// Get Agora token from edge function
			const { data: tokenData, error: tokenError } = await supabase.functions.invoke(
				'generate-agora-token',
				{
					body: {
						consultation_id: consultation.id,
						channel_name: consultation.agora_channel_name || `consultation_${consultation.id}`,
						role: 'publisher'
					}
				}
			);

			if (tokenError) throw tokenError;

			// Initialize Agora
			agoraService = new AgoraService();

			agoraService.onUserJoined((user) => {
				remoteUsers = [...agoraService!.getRemoteUsers()];

				// Play remote video
				setTimeout(() => {
					if (consultation.type === 'video') {
						const remoteVideoContainer = document.getElementById(`remote-video-${user.uid}`);
						if (remoteVideoContainer && user.videoTrack) {
							user.videoTrack.play(remoteVideoContainer);
						}
					}
				}, 100);
			});

			agoraService.onUserLeft((user) => {
				remoteUsers = [...agoraService!.getRemoteUsers()];
			});

			await agoraService.join({
				appId: tokenData.app_id,
				channel: tokenData.channel,
				token: tokenData.token,
				uid: tokenData.uid
			});

			// Play local video
			if (consultation.type === 'video') {
				setTimeout(() => {
					agoraService!.playLocalVideo('local-video');
				}, 100);
			}

			isConnected = true;
			isConnecting = false;

			// Update consultation status to in_progress
			if (consultation.status === 'scheduled') {
				await supabase
					.from('consultations')
					.update({
						status: 'in_progress',
						started_at: new Date().toISOString()
					})
					.eq('id', consultation.id);

				startDurationTimer();
			}
		} catch (error) {
			console.error('Error initializing Agora:', error);
			isConnecting = false;
			alert('Failed to connect to video call. Please try again.');
		}
	}

	async function toggleVideo() {
		if (!agoraService) return;
		isVideoEnabled = await agoraService.toggleCamera();
	}

	async function toggleAudio() {
		if (!agoraService) return;
		isAudioEnabled = await agoraService.toggleMicrophone();
	}

	async function endCall() {
		if (confirm('Are you sure you want to end this consultation?')) {
			// Update consultation status
			await supabase
				.from('consultations')
				.update({
					status: 'completed',
					ended_at: new Date().toISOString()
				})
				.eq('id', consultation.id);

			// Leave Agora channel
			if (agoraService) {
				await agoraService.leave();
			}

			// Redirect to consultations page
			goto('/consultations');
		}
	}

	async function loadMessages() {
		const { data, error } = await supabase
			.from('consultation_messages')
			.select('*')
			.eq('consultation_id', consultation.id)
			.order('created_at', { ascending: true });

		if (!error && data) {
			messages = data;
		}
	}

	async function sendMessage() {
		if (!newMessage.trim()) return;

		const { error } = await supabase.from('consultation_messages').insert({
			consultation_id: consultation.id,
			sender_id: authStore.user?.id,
			sender_type: 'patient', // TODO: Detect if provider
			content: newMessage.trim()
		});

		if (!error) {
			newMessage = '';
		}
	}

	function startDurationTimer() {
		const startedAt = new Date(consultation.started_at).getTime();

		durationInterval = setInterval(() => {
			const now = Date.now();
			consultationDuration = Math.floor((now - startedAt) / 1000);
		}, 1000);
	}

	function formatDuration(seconds: number): string {
		const mins = Math.floor(seconds / 60);
		const secs = seconds % 60;
		return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
	}
</script>

<svelte:head>
	<title>Consultation Room | Kemani Health</title>
</svelte:head>

<div class="fixed inset-0 bg-gray-900 flex flex-col">
	<!-- Header -->
	<header class="bg-gray-800 px-6 py-4 flex items-center justify-between">
		<div class="flex items-center gap-4">
			<button
				onclick={() => goto('/consultations')}
				class="p-2 hover:bg-gray-700 rounded-lg transition text-white"
			>
				<ArrowLeft class="w-5 h-5" />
			</button>
			<div>
				<h1 class="text-white font-semibold">{consultation.provider_name}</h1>
				<p class="text-sm text-gray-400 capitalize">{consultation.type} Consultation</p>
			</div>
		</div>

		<div class="flex items-center gap-4">
			{#if consultation.status === 'in_progress'}
				<div class="flex items-center gap-2 text-white bg-red-600 px-4 py-2 rounded-lg">
					<Clock class="w-4 h-4" />
					<span class="font-mono">{formatDuration(consultationDuration)}</span>
				</div>
			{/if}

			<button
				onclick={() => showChat = !showChat}
				class="p-2 hover:bg-gray-700 rounded-lg transition text-white relative"
			>
				<MessageSquare class="w-5 h-5" />
				{#if messages.length > 0}
					<span class="absolute top-1 right-1 w-2 h-2 bg-blue-500 rounded-full"></span>
				{/if}
			</button>
		</div>
	</header>

	<!-- Main Content -->
	<div class="flex-1 flex overflow-hidden">
		<!-- Video Area -->
		<div class="flex-1 relative bg-black">
			{#if isConnecting}
				<div class="absolute inset-0 flex items-center justify-center">
					<div class="text-white text-center">
						<div class="w-16 h-16 border-4 border-white border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
						<p>Connecting to call...</p>
					</div>
				</div>
			{:else if !isConnected && (consultation.type === 'video' || consultation.type === 'audio')}
				<div class="absolute inset-0 flex items-center justify-center">
					<div class="text-white text-center">
						<Video class="w-16 h-16 mx-auto mb-4" />
						<p>Waiting to start consultation...</p>
						<button
							onclick={initializeAgora}
							class="mt-4 px-6 py-3 bg-blue-600 rounded-lg hover:bg-blue-700 transition"
						>
							Join Call
						</button>
					</div>
				</div>
			{:else if consultation.type === 'chat'}
				<div class="absolute inset-0 flex items-center justify-center">
					<div class="text-white text-center">
						<MessageSquare class="w-16 h-16 mx-auto mb-4" />
						<p>Chat Consultation</p>
						<p class="text-sm text-gray-400 mt-2">Use the chat panel to communicate</p>
					</div>
				</div>
			{:else}
				<!-- Remote Video (main) -->
				{#if remoteUsers.length > 0}
					<div class="absolute inset-0">
						{#each remoteUsers as user}
							<div id="remote-video-{user.uid}" class="w-full h-full"></div>
						{/each}
					</div>
				{:else}
					<div class="absolute inset-0 flex items-center justify-center text-white">
						<div class="text-center">
							<Video class="w-16 h-16 mx-auto mb-4" />
							<p>Waiting for {consultation.provider_name} to join...</p>
						</div>
					</div>
				{/if}

				<!-- Local Video (PiP) -->
				{#if consultation.type === 'video'}
					<div class="absolute bottom-6 right-6 w-48 h-36 bg-gray-800 rounded-lg overflow-hidden shadow-xl">
						<div id="local-video" class="w-full h-full"></div>
					</div>
				{/if}
			{/if}

			<!-- Controls -->
			<div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-6">
				<div class="flex justify-center gap-4">
					{#if consultation.type === 'video'}
						<button
							onclick={toggleVideo}
							class="p-4 rounded-full transition {isVideoEnabled ? 'bg-gray-700 hover:bg-gray-600' : 'bg-red-600 hover:bg-red-700'}"
						>
							{#if isVideoEnabled}
								<Video class="w-6 h-6 text-white" />
							{:else}
								<VideoOff class="w-6 h-6 text-white" />
							{/if}
						</button>
					{/if}

					<button
						onclick={toggleAudio}
						class="p-4 rounded-full transition {isAudioEnabled ? 'bg-gray-700 hover:bg-gray-600' : 'bg-red-600 hover:bg-red-700'}"
					>
						{#if isAudioEnabled}
							<Mic class="w-6 h-6 text-white" />
						{:else}
							<MicOff class="w-6 h-6 text-white" />
						{/if}
					</button>

					<button
						onclick={endCall}
						class="p-4 rounded-full bg-red-600 hover:bg-red-700 transition"
					>
						<Phone class="w-6 h-6 text-white" />
					</button>
				</div>
			</div>
		</div>

		<!-- Chat Sidebar -->
		{#if showChat}
			<div class="w-96 bg-white flex flex-col">
				<div class="p-4 border-b">
					<h2 class="font-semibold text-gray-900">Chat Messages</h2>
				</div>

				<!-- Messages -->
				<div class="flex-1 overflow-y-auto p-4 space-y-4">
					{#each messages as message}
						<div class={message.sender_type === 'patient' ? 'flex justify-end' : 'flex justify-start'}>
							<div class={`max-w-[70%] rounded-lg p-3 ${message.sender_type === 'patient' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-900'}`}>
								<p class="text-sm">{message.content}</p>
								<p class="text-xs mt-1 opacity-70">
									{new Date(message.created_at).toLocaleTimeString()}
								</p>
							</div>
						</div>
					{/each}

					{#if messages.length === 0}
						<div class="text-center text-gray-500 py-8">
							<MessageSquare class="w-12 h-12 mx-auto mb-2 text-gray-400" />
							<p class="text-sm">No messages yet</p>
						</div>
					{/if}
				</div>

				<!-- Input -->
				<div class="p-4 border-t">
					<form onsubmit={(e) => { e.preventDefault(); sendMessage(); }} class="flex gap-2">
						<input
							type="text"
							bind:value={newMessage}
							placeholder="Type a message..."
							class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
						/>
						<button
							type="submit"
							class="p-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
						>
							<Send class="w-5 h-5" />
						</button>
					</form>
				</div>
			</div>
		{/if}
	</div>
</div>
