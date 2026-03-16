<script lang="ts">
	import { goto } from '$app/navigation';
	import { Search, Filter, Star, Video, MessageSquare, Phone, MapPin } from 'lucide-svelte';
	import type { PageData } from './$types';

	export let data: PageData;

	let { providers, specializations, filters } = $derived(data);

	let searchTerm = $state(filters.search);
	let selectedSpecialization = $state(filters.specialization);
	let selectedType = $state(filters.type);

	function applyFilters() {
		const params = new URLSearchParams();
		if (searchTerm) params.set('search', searchTerm);
		if (selectedSpecialization) params.set('specialization', selectedSpecialization);
		if (selectedType) params.set('type', selectedType);
		goto(`/providers?${params.toString()}`);
	}

	function formatFee(fees: any, type: string): string {
		if (!fees || typeof fees !== 'object') return 'N/A';
		const amount = fees[type];
		if (!amount) return 'N/A';
		return `₦${amount.toLocaleString()}`;
	}

	function getConsultationTypes(types: string[]): string {
		if (!types || !Array.isArray(types)) return 'Not specified';
		const labels: Record<string, string> = {
			chat: 'Chat',
			video: 'Video',
			audio: 'Audio',
			office_visit: 'Office Visit'
		};
		return types.map(t => labels[t] || t).join(', ');
	}
</script>

<svelte:head>
	<title>Find Healthcare Providers | Kemani Health</title>
</svelte:head>

<div class="min-h-screen theme-bg">
	<!-- Header -->
	<header class="theme-nav border-b sticky top-0 z-10">
		<div class="max-w-7xl mx-auto px-4 py-4">
			<div class="flex items-center justify-between">
				<div>
					<h1 class="text-2xl font-bold theme-text">Find a Healthcare Provider</h1>
					<p class="theme-text-muted text-sm mt-1">Browse verified doctors, pharmacists, and specialists</p>
				</div>
				<a href="/" class="theme-btn-outline px-4 py-2 rounded-lg">
					Back to Home
				</a>
			</div>
		</div>
	</header>

	<main class="max-w-7xl mx-auto px-4 py-8">
		<!-- Filters -->
		<div class="theme-card rounded-lg p-6 mb-8">
			<div class="grid grid-cols-1 md:grid-cols-4 gap-4">
				<!-- Search -->
				<div class="md:col-span-2">
					<label for="search" class="block text-sm font-medium theme-text mb-2">
						<Search class="inline w-4 h-4 mr-1" />
						Search Providers
					</label>
					<input
						id="search"
						type="text"
						bind:value={searchTerm}
						placeholder="Name, specialization, or keyword..."
						class="w-full px-4 py-2 border theme-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
						onkeydown={(e) => e.key === 'Enter' && applyFilters()}
					/>
				</div>

				<!-- Specialization Filter -->
				<div>
					<label for="specialization" class="block text-sm font-medium theme-text mb-2">
						<Filter class="inline w-4 h-4 mr-1" />
						Specialization
					</label>
					<select
						id="specialization"
						bind:value={selectedSpecialization}
						class="w-full px-4 py-2 border theme-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
						onchange={applyFilters}
					>
						<option value="">All Specializations</option>
						{#each specializations as spec}
							<option value={spec}>{spec}</option>
						{/each}
					</select>
				</div>

				<!-- Type Filter -->
				<div>
					<label for="type" class="block text-sm font-medium theme-text mb-2">
						Provider Type
					</label>
					<select
						id="type"
						bind:value={selectedType}
						class="w-full px-4 py-2 border theme-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
						onchange={applyFilters}
					>
						<option value="">All Types</option>
						<option value="doctor">Doctor</option>
						<option value="pharmacist">Pharmacist</option>
						<option value="diagnostician">Diagnostician</option>
						<option value="specialist">Specialist</option>
					</select>
				</div>
			</div>

			<div class="mt-4 flex gap-2">
				<button
					onclick={applyFilters}
					class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
				>
					Apply Filters
				</button>
				<button
					onclick={() => {
						searchTerm = '';
						selectedSpecialization = '';
						selectedType = '';
						goto('/providers');
					}}
					class="px-6 py-2 theme-btn-outline rounded-lg"
				>
					Clear Filters
				</button>
			</div>
		</div>

		<!-- Results Count -->
		<div class="mb-6">
			<p class="theme-text-muted">
				Found <span class="font-semibold theme-text">{providers.length}</span> provider{providers.length !== 1 ? 's' : ''}
			</p>
		</div>

		<!-- Provider Grid -->
		{#if providers.length === 0}
			<div class="text-center py-12 theme-card rounded-lg">
				<p class="text-xl theme-text-muted">No providers found matching your criteria</p>
				<button
					onclick={() => goto('/providers')}
					class="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
				>
					View All Providers
				</button>
			</div>
		{:else}
			<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				{#each providers as provider}
					<div class="theme-card rounded-lg p-6 hover:shadow-lg transition cursor-pointer" onclick={() => goto(`/providers/${provider.slug}`)}>
						<!-- Provider Photo -->
						<div class="flex items-start gap-4 mb-4">
							{#if provider.profile_photo_url}
								<img
									src={provider.profile_photo_url}
									alt={provider.full_name}
									class="w-16 h-16 rounded-full object-cover"
								/>
							{:else}
								<div class="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center">
									<span class="text-2xl font-bold text-blue-600">
										{provider.full_name.charAt(0)}
									</span>
								</div>
							{/if}

							<div class="flex-1">
								<h3 class="font-bold theme-text text-lg">{provider.full_name}</h3>
								{#if provider.credentials}
									<p class="text-sm theme-text-muted">{provider.credentials}</p>
								{/if}
							</div>
						</div>

						<!-- Specialization & Type -->
						<div class="mb-4">
							<p class="font-medium theme-text">{provider.specialization}</p>
							<p class="text-sm theme-text-muted capitalize">{provider.type}</p>
						</div>

						<!-- Rating & Experience -->
						<div class="flex items-center gap-4 mb-4">
							<div class="flex items-center gap-1">
								<Star class="w-4 h-4 text-yellow-500 fill-yellow-500" />
								<span class="theme-text font-medium">{provider.average_rating.toFixed(1)}</span>
								<span class="theme-text-muted text-sm">({provider.total_reviews})</span>
							</div>
							<span class="theme-text-muted text-sm">
								{provider.years_of_experience} yrs exp
							</span>
						</div>

						<!-- Consultation Types Icons -->
						<div class="flex gap-2 mb-4">
							{#if provider.consultation_types.includes('video')}
								<div class="p-2 bg-blue-100 rounded-lg" title="Video Consultation">
									<Video class="w-4 h-4 text-blue-600" />
								</div>
							{/if}
							{#if provider.consultation_types.includes('chat')}
								<div class="p-2 bg-green-100 rounded-lg" title="Chat Consultation">
									<MessageSquare class="w-4 h-4 text-green-600" />
								</div>
							{/if}
							{#if provider.consultation_types.includes('audio')}
								<div class="p-2 bg-purple-100 rounded-lg" title="Audio Consultation">
									<Phone class="w-4 h-4 text-purple-600" />
								</div>
							{/if}
							{#if provider.consultation_types.includes('office_visit')}
								<div class="p-2 bg-orange-100 rounded-lg" title="Office Visit">
									<MapPin class="w-4 h-4 text-orange-600" />
								</div>
							{/if}
						</div>

						<!-- Pricing -->
						<div class="border-t theme-border pt-4">
							<p class="text-sm theme-text-muted mb-2">Starting from</p>
							<p class="text-xl font-bold text-blue-600">
								{formatFee(provider.fees, 'chat')}
							</p>
						</div>

						<!-- Book Button -->
						<button
							onclick={(e) => {
								e.stopPropagation();
								goto(`/book/${provider.slug}`);
							}}
							class="w-full mt-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
						>
							Book Consultation
						</button>
					</div>
				{/each}
			</div>
		{/if}
	</main>
</div>

<style>
	/* Add any custom styles here */
</style>
