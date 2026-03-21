<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Calendar, Video, MessageSquare, Phone, CheckCircle, Clock, XCircle } from 'lucide-svelte';

	let provider = $state(null);
	let consultations = $state([]);
	let loading = $state(true);
	let filter = $state('all'); // all, pending, in_progress, completed

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
				await loadConsultations(provider.id);
			}
		}

		loading = false;
	});

	async function loadConsultations(providerId: string) {
		let query = supabase
			.from('consultations')
			.select('*')
			.eq('provider_id', providerId)
			.order('created_at', { ascending: false }); // Order by time created to show referred patients chronologically

		if (filter !== 'all') {
			query = query.eq('status', filter);
		}

		const { data } = await query;
		consultations = data || [];
	}

	async function updateStatus(consultationId: string, newStatus: string) {
		const { error } = await supabase
			.from('consultations')
			.update({ status: newStatus })
			.eq('id', consultationId);

		if (!error && provider) {
			await loadConsultations(provider.id);
		}
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'Not scheduled';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function getTypeIcon(type: string) {
		switch (type) {
			case 'video': return Video;
			case 'chat': return MessageSquare;
			case 'audio': return Phone;
			default: return Calendar;
		}
	}

	function getStatusColor(status: string) {
		switch (status) {
			case 'completed': return 'bg-green-100 text-green-800';
			case 'in_progress': return 'bg-blue-100 text-blue-800';
			case 'pending': return 'bg-yellow-100 text-yellow-800';
			case 'cancelled': return 'bg-red-100 text-red-800';
			default: return 'bg-gray-100 text-gray-800';
		}
	}

	function getReferralBadge(referralSource: string) {
		switch (referralSource) {
			case 'storefront':
				return { text: 'Referred by Storefront', color: 'bg-blue-100 text-blue-800', icon: '🛒' };
			case 'medic_clinic':
				return { text: 'Referred by Clinic', color: 'bg-purple-100 text-purple-800', icon: '🏥' };
			case 'pharmacy':
				return { text: 'Referred by Pharmacy', color: 'bg-green-100 text-green-800', icon: '💊' };
			case 'lab':
				return { text: 'Referred by Lab', color: 'bg-orange-100 text-orange-800', icon: '🔬' };
			default:
				return { text: 'Direct Patient', color: 'bg-gray-100 text-gray-800', icon: '👤' };
		}
	}

	async function handleFilterChange(newFilter: string) {
		filter = newFilter;
		if (provider) {
			loading = true;
			await loadConsultations(provider.id);
			loading = false;
		}
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-lg shadow p-6">
			<h2 class="text-2xl font-bold text-gray-900">Consultations</h2>
			<p class="text-gray-600 mt-1">Manage your patient consultations</p>
		</div>

	<!-- Filters -->
	<div class="bg-white rounded-lg shadow p-4">
		<div class="flex flex-wrap gap-2">
			<button
				onclick={() => handleFilterChange('all')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'all' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				All
			</button>
			<button
				onclick={() => handleFilterChange('pending')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'pending' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				Pending
			</button>
			<button
				onclick={() => handleFilterChange('in_progress')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'in_progress' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				In Progress
			</button>
			<button
				onclick={() => handleFilterChange('completed')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'completed' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				Completed
			</button>
		</div>
	</div>

	<!-- Consultations List -->
	{#if loading}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading consultations...</p>
		</div>
	{:else if consultations.length === 0}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<Calendar class="h-16 w-16 text-gray-300 mx-auto mb-4" />
			<h3 class="text-lg font-medium text-gray-900 mb-2">No consultations found</h3>
			<p class="text-gray-600">
				{#if filter === 'all'}
					You don't have any consultations yet.
				{:else}
					No {filter} consultations at the moment.
				{/if}
			</p>
		</div>
	{:else}
		<div class="space-y-4">
			{#each consultations as consultation}
				{@const badge = getReferralBadge(consultation.referral_source || 'direct')}
				<div class="bg-white rounded-lg shadow hover:shadow-md transition-shadow">
					<div class="p-6">
						<div class="flex items-start justify-between">
							<div class="flex items-start gap-4 flex-1">
								<!-- Icon -->
								<div class="bg-primary-100 p-3 rounded-full flex-shrink-0">
									<svelte:component this={getTypeIcon(consultation.type)} class="h-6 w-6 text-primary-600" />
								</div>

								<!-- Details -->
								<div class="flex-1 min-w-0">
									<div class="flex items-center gap-3 mb-2 flex-wrap">
										<h3 class="text-lg font-semibold text-gray-900">
											{consultation.provider_name || 'Patient'}
										</h3>
										<span class="px-2 py-1 text-xs font-semibold rounded-full {getStatusColor(consultation.status)}">
											{consultation.status}
										</span>
										<span class="px-2 py-1 text-xs font-semibold rounded-full {badge.color}">
											{badge.icon} {badge.text}
										</span>
									</div>

									<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600">
										<div>
											<span class="font-medium">Type:</span> {consultation.type}
										</div>
										<div>
											<span class="font-medium">Fee:</span> ₦{consultation.consultation_fee?.toLocaleString() || '0'}
										</div>
										<div>
											<span class="font-medium">Scheduled:</span> {formatDate(consultation.scheduled_time)}
										</div>
										<div>
											<span class="font-medium">Payment:</span>
											<span class="capitalize">{consultation.payment_status}</span>
										</div>
									</div>

									{#if consultation.agora_channel_name}
										<div class="mt-3 p-3 bg-blue-50 rounded-md text-sm">
											<span class="font-medium text-blue-900">Channel:</span>
											<span class="text-blue-700 font-mono">{consultation.agora_channel_name}</span>
										</div>
									{/if}
								</div>
							</div>

							<!-- Actions -->
							<div class="flex flex-col gap-2 ml-4">
								{#if consultation.status === 'pending'}
									<button
										onclick={() => updateStatus(consultation.id, 'in_progress')}
										class="px-4 py-2 bg-blue-600 text-white text-sm rounded-md hover:bg-blue-700 transition-colors flex items-center gap-2"
									>
										<Clock class="h-4 w-4" />
										Start
									</button>
								{/if}

								{#if consultation.status === 'in_progress'}
									<button
										onclick={() => updateStatus(consultation.id, 'completed')}
										class="px-4 py-2 bg-green-600 text-white text-sm rounded-md hover:bg-green-700 transition-colors flex items-center gap-2"
									>
										<CheckCircle class="h-4 w-4" />
										Complete
									</button>
								{/if}

								{#if consultation.status !== 'cancelled' && consultation.status !== 'completed'}
									<button
										onclick={() => updateStatus(consultation.id, 'cancelled')}
										class="px-4 py-2 bg-red-600 text-white text-sm rounded-md hover:bg-red-700 transition-colors flex items-center gap-2"
									>
										<XCircle class="h-4 w-4" />
										Cancel
									</button>
								{/if}

								{#if consultation.type === 'chat' || (consultation.type === 'video' && consultation.agora_channel_name)}
									<a
										href="/consultations/{consultation.id}"
										class="px-4 py-2 bg-primary-600 text-white text-sm rounded-md hover:bg-primary-700 transition-colors text-center"
									>
										View Details
									</a>
								{/if}
							</div>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
	</div>
</div>
