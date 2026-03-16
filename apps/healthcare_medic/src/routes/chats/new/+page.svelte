<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { ArrowLeft, Search, Building2, Activity } from 'lucide-svelte';

	let provider = $state(null);
	let loading = $state(false);
	let error = $state('');
	let searchQuery = $state('');
	let selectedType = $state('pharmacy'); // pharmacy or lab
	let availableEntities = $state([]);

	let filteredEntities = $derived(
		availableEntities.filter((e) =>
			e.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
			e.location?.toLowerCase().includes(searchQuery.toLowerCase())
		)
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
		}

		loadEntities();
	});

	async function loadEntities() {
		// Mock data - you'll need to fetch from tenants table filtered by tenant_type
		if (selectedType === 'pharmacy') {
			availableEntities = [
				{ id: '1', name: 'MedPlus Pharmacy', location: 'Lagos, Nigeria', type: 'pharmacy' },
				{ id: '2', name: 'HealthCare Pharmacy', location: 'Abuja, Nigeria', type: 'pharmacy' },
				{ id: '3', name: 'WellLife Pharmacy', location: 'Port Harcourt, Nigeria', type: 'pharmacy' }
			];
		} else {
			availableEntities = [
				{ id: '1', name: 'City Diagnostics Lab', location: 'Lagos, Nigeria', type: 'lab' },
				{ id: '2', name: 'Premier Medical Lab', location: 'Abuja, Nigeria', type: 'lab' },
				{ id: '3', name: 'Advanced Lab Services', location: 'Kano, Nigeria', type: 'lab' }
			];
		}
	}

	async function startChat(entityId: string) {
		loading = true;
		error = '';

		try {
			// Create a new conversation (you'll need to implement chat_conversations table)
			// For now, just navigate to a new chat
			goto(`/chats/${entityId}`);
		} catch (err: any) {
			error = err.message || 'Failed to start chat';
			loading = false;
		}
	}

	function handleTypeChange() {
		searchQuery = '';
		loadEntities();
	}
</script>

<div class="max-w-4xl mx-auto space-y-6">
	<!-- Header -->
	<div class="bg-white rounded-lg shadow p-6">
		<div class="flex items-center gap-4">
			<a
				href="/chats"
				class="p-2 hover:bg-gray-100 rounded-md transition-colors"
			>
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</a>
			<div>
				<h2 class="text-2xl font-bold text-gray-900">Start New Conversation</h2>
				<p class="text-gray-600 mt-1">Chat with pharmacies and labs</p>
			</div>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md text-sm">
			{error}
		</div>
	{/if}

	<!-- Type Selection -->
	<div class="bg-white rounded-lg shadow p-4">
		<h3 class="font-semibold text-gray-900 mb-3">Select Type</h3>
		<div class="flex gap-4">
			<button
				onclick={() => { selectedType = 'pharmacy'; handleTypeChange(); }}
				class="flex-1 px-4 py-3 rounded-md transition-colors flex items-center justify-center gap-2 {selectedType === 'pharmacy' ? 'bg-green-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				<Building2 class="h-5 w-5" />
				Pharmacy
			</button>
			<button
				onclick={() => { selectedType = 'lab'; handleTypeChange(); }}
				class="flex-1 px-4 py-3 rounded-md transition-colors flex items-center justify-center gap-2 {selectedType === 'lab' ? 'bg-purple-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				<Activity class="h-5 w-5" />
				Laboratory
			</button>
		</div>
	</div>

	<!-- Search -->
	<div class="bg-white rounded-lg shadow p-4">
		<div class="relative">
			<Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
			<input
				type="text"
				bind:value={searchQuery}
				placeholder="Search by name or location..."
				class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
			/>
		</div>
	</div>

	<!-- Entities List -->
	<div class="bg-white rounded-lg shadow">
		<div class="p-6 border-b border-gray-200">
			<h3 class="text-lg font-semibold text-gray-900">
				Available {selectedType === 'pharmacy' ? 'Pharmacies' : 'Laboratories'}
			</h3>
		</div>

		{#if filteredEntities.length === 0}
			<div class="p-12 text-center">
				<div class="{selectedType === 'pharmacy' ? 'bg-green-100 text-green-600' : 'bg-purple-100 text-purple-600'} p-4 rounded-full inline-block mb-4">
					<svelte:component this={selectedType === 'pharmacy' ? Building2 : Activity} class="h-8 w-8" />
				</div>
				<h3 class="text-lg font-medium text-gray-900 mb-2">
					No {selectedType === 'pharmacy' ? 'pharmacies' : 'laboratories'} found
				</h3>
				<p class="text-gray-600">Try adjusting your search terms</p>
			</div>
		{:else}
			<div class="divide-y divide-gray-200">
				{#each filteredEntities as entity}
					<button
						onclick={() => startChat(entity.id)}
						disabled={loading}
						class="w-full p-6 hover:bg-gray-50 transition-colors text-left flex items-center justify-between disabled:opacity-50"
					>
						<div class="flex items-center gap-4">
							<div class="{selectedType === 'pharmacy' ? 'bg-green-100 text-green-600' : 'bg-purple-100 text-purple-600'} p-3 rounded-full">
								<svelte:component this={selectedType === 'pharmacy' ? Building2 : Activity} class="h-6 w-6" />
							</div>
							<div>
								<h4 class="font-semibold text-gray-900">{entity.name}</h4>
								<p class="text-sm text-gray-600">{entity.location}</p>
							</div>
						</div>

						<div class="text-primary-600 font-medium">
							Start Chat →
						</div>
					</button>
				{/each}
			</div>
		{/if}
	</div>
</div>
