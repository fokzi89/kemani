<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { MessageSquare, Plus, Search, User, Building2, Activity } from 'lucide-svelte';

	let provider = $state(null);
	let conversations = $state([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let filter = $state('all'); // all, patient, pharmacy, lab

	let filteredConversations = $derived(
		conversations.filter((c) => {
			const matchesSearch =
				c.participant_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
				c.last_message?.toLowerCase().includes(searchQuery.toLowerCase());
			const matchesFilter =
				filter === 'all' || c.participant_type === filter;
			return matchesSearch && matchesFilter;
		})
	);

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
				await loadConversations(provider.id);
			}
		}

		loading = false;
	});

	async function loadConversations(providerId: string) {
		// This is a mock implementation - you'll need to create proper chat tables
		conversations = [
			{
				id: '1',
				participant_id: 'patient-1',
				participant_name: 'John Doe',
				participant_type: 'patient',
				last_message: 'Thank you doctor, feeling much better!',
				last_message_time: new Date(Date.now() - 3600000).toISOString(),
				unread_count: 0,
				avatar_url: null
			},
			{
				id: '2',
				participant_id: 'pharmacy-1',
				participant_name: 'MedPlus Pharmacy',
				participant_type: 'pharmacy',
				last_message: 'Prescription ready for pickup',
				last_message_time: new Date(Date.now() - 7200000).toISOString(),
				unread_count: 2,
				avatar_url: null
			},
			{
				id: '3',
				participant_id: 'lab-1',
				participant_name: 'City Diagnostics Lab',
				participant_type: 'lab',
				last_message: 'Test results attached',
				last_message_time: new Date(Date.now() - 86400000).toISOString(),
				unread_count: 1,
				avatar_url: null
			}
		];
	}

	function formatTime(dateString: string) {
		const date = new Date(dateString);
		const now = new Date();
		const diff = now.getTime() - date.getTime();

		if (diff < 86400000) { // Less than 24 hours
			return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
		} else if (diff < 604800000) { // Less than 7 days
			return date.toLocaleDateString('en-US', { weekday: 'short' });
		} else {
			return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
		}
	}

	function getParticipantIcon(type: string) {
		switch (type) {
			case 'patient': return User;
			case 'pharmacy': return Building2;
			case 'lab': return Activity;
			default: return User;
		}
	}

	function getParticipantColor(type: string) {
		switch (type) {
			case 'patient': return 'bg-blue-100 text-blue-600';
			case 'pharmacy': return 'bg-green-100 text-green-600';
			case 'lab': return 'bg-purple-100 text-purple-600';
			default: return 'bg-gray-100 text-gray-600';
		}
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-lg shadow p-6">
		<div class="flex justify-between items-center">
			<div>
				<h2 class="text-2xl font-bold text-gray-900">Messages</h2>
				<p class="text-gray-600 mt-1">Chat with patients, pharmacies, and labs</p>
			</div>
			<a
				href="/chats/new"
				class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors flex items-center gap-2"
			>
				<Plus class="h-5 w-5" />
				New Chat
			</a>
		</div>
	</div>

	<!-- Search & Filters -->
	<div class="bg-white rounded-lg shadow p-4 space-y-4">
		<div class="relative">
			<Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
			<input
				type="text"
				bind:value={searchQuery}
				placeholder="Search conversations..."
				class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
			/>
		</div>

		<div class="flex flex-wrap gap-2">
			<button
				onclick={() => filter = 'all'}
				class="px-4 py-2 rounded-md transition-colors {filter === 'all' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				All
			</button>
			<button
				onclick={() => filter = 'patient'}
				class="px-4 py-2 rounded-md transition-colors {filter === 'patient' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				Patients
			</button>
			<button
				onclick={() => filter = 'pharmacy'}
				class="px-4 py-2 rounded-md transition-colors {filter === 'pharmacy' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				Pharmacies
			</button>
			<button
				onclick={() => filter = 'lab'}
				class="px-4 py-2 rounded-md transition-colors {filter === 'lab' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				Labs
			</button>
		</div>
	</div>

	<!-- Conversations List -->
	{#if loading}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading conversations...</p>
		</div>
	{:else if filteredConversations.length === 0}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<MessageSquare class="h-16 w-16 text-gray-300 mx-auto mb-4" />
			<h3 class="text-lg font-medium text-gray-900 mb-2">No conversations</h3>
			<p class="text-gray-600">
				{searchQuery || filter !== 'all'
					? 'No conversations match your search'
					: 'Start a new chat to begin messaging'}
			</p>
		</div>
	{:else}
		<div class="bg-white rounded-lg shadow divide-y divide-gray-200">
			{#each filteredConversations as conversation}
				<a
					href="/chats/{conversation.id}"
					class="block p-4 hover:bg-gray-50 transition-colors"
				>
					<div class="flex items-start gap-4">
						<!-- Avatar -->
						<div class="{getParticipantColor(conversation.participant_type)} p-3 rounded-full flex-shrink-0">
							<svelte:component this={getParticipantIcon(conversation.participant_type)} class="h-6 w-6" />
						</div>

						<!-- Content -->
						<div class="flex-1 min-w-0">
							<div class="flex justify-between items-start gap-2 mb-1">
								<div>
									<h3 class="font-semibold text-gray-900 truncate">
										{conversation.participant_name}
									</h3>
									<span class="text-xs text-gray-500 capitalize">
										{conversation.participant_type}
									</span>
								</div>
								<div class="text-right flex-shrink-0">
									<div class="text-xs text-gray-500">
										{formatTime(conversation.last_message_time)}
									</div>
									{#if conversation.unread_count > 0}
										<div class="mt-1 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-primary-600 rounded-full">
											{conversation.unread_count}
										</div>
									{/if}
								</div>
							</div>

							<p class="text-sm text-gray-600 truncate">
								{conversation.last_message}
							</p>
						</div>
					</div>
				</a>
			{/each}
		</div>
	{/if}
	</div>
</div>
