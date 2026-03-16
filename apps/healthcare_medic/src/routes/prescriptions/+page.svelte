<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { FileText, Plus, Calendar, User } from 'lucide-svelte';

	let provider = $state(null);
	let prescriptions = $state([]);
	let loading = $state(true);

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
				await loadPrescriptions(provider.id);
			}
		}

		loading = false;
	});

	async function loadPrescriptions(providerId: string) {
		const { data } = await supabase
			.from('prescriptions')
			.select('*')
			.eq('provider_id', providerId)
			.order('created_at', { ascending: false });

		prescriptions = data || [];
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'N/A';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}

	function getStatusColor(status: string) {
		switch (status) {
			case 'active': return 'bg-green-100 text-green-800';
			case 'expired': return 'bg-red-100 text-red-800';
			case 'fulfilled': return 'bg-blue-100 text-blue-800';
			case 'cancelled': return 'bg-gray-100 text-gray-800';
			default: return 'bg-gray-100 text-gray-800';
		}
	}
</script>

<div class="space-y-6">
	<!-- Header -->
	<div class="bg-white rounded-lg shadow p-6">
		<div class="flex justify-between items-center">
			<div>
				<h2 class="text-2xl font-bold text-gray-900">Prescriptions</h2>
				<p class="text-gray-600 mt-1">View and manage patient prescriptions</p>
			</div>
			<a
				href="/prescriptions/create"
				class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors flex items-center gap-2"
			>
				<Plus class="h-5 w-5" />
				New Prescription
			</a>
		</div>
	</div>

	<!-- Prescriptions List -->
	{#if loading}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading prescriptions...</p>
		</div>
	{:else if prescriptions.length === 0}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<FileText class="h-16 w-16 text-gray-300 mx-auto mb-4" />
			<h3 class="text-lg font-medium text-gray-900 mb-2">No prescriptions yet</h3>
			<p class="text-gray-600">Create your first prescription to get started.</p>
		</div>
	{:else}
		<div class="space-y-4">
			{#each prescriptions as prescription}
				<div class="bg-white rounded-lg shadow hover:shadow-md transition-shadow p-6">
					<div class="flex items-start justify-between mb-4">
						<div class="flex items-start gap-4 flex-1">
							<div class="bg-primary-100 p-3 rounded-full flex-shrink-0">
								<FileText class="h-6 w-6 text-primary-600" />
							</div>

							<div class="flex-1">
								<div class="flex items-center gap-3 mb-2">
									<h3 class="text-lg font-semibold text-gray-900">
										Prescription #{prescription.id.slice(0, 8)}
									</h3>
									<span class="px-2 py-1 text-xs font-semibold rounded-full {getStatusColor(prescription.status)}">
										{prescription.status}
									</span>
								</div>

								<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600 mb-4">
									<div class="flex items-center gap-2">
										<User class="h-4 w-4" />
										<span>Patient ID: {prescription.patient_id.slice(0, 8)}</span>
									</div>
									<div class="flex items-center gap-2">
										<Calendar class="h-4 w-4" />
										<span>Issued: {formatDate(prescription.issue_date)}</span>
									</div>
									<div class="flex items-center gap-2">
										<Calendar class="h-4 w-4" />
										<span>Expires: {formatDate(prescription.expiration_date)}</span>
									</div>
								</div>

								{#if prescription.diagnosis}
									<div class="mb-3">
										<span class="font-medium text-gray-700">Diagnosis:</span>
										<p class="text-gray-600 mt-1">{prescription.diagnosis}</p>
									</div>
								{/if}

								<div>
									<span class="font-medium text-gray-700">Medications:</span>
									<div class="mt-2 space-y-2">
										{#each prescription.medications as medication}
											<div class="bg-gray-50 p-3 rounded-md">
												<div class="font-medium text-gray-900">{medication.name}</div>
												<div class="text-sm text-gray-600 mt-1">
													<span class="font-medium">Dosage:</span> {medication.dosage}
												</div>
												<div class="text-sm text-gray-600">
													<span class="font-medium">Frequency:</span> {medication.frequency}
												</div>
												{#if medication.duration}
													<div class="text-sm text-gray-600">
														<span class="font-medium">Duration:</span> {medication.duration}
													</div>
												{/if}
											</div>
										{/each}
									</div>
								</div>

								{#if prescription.notes}
									<div class="mt-3 p-3 bg-blue-50 rounded-md">
										<span class="font-medium text-blue-900">Notes:</span>
										<p class="text-blue-700 text-sm mt-1">{prescription.notes}</p>
									</div>
								{/if}
							</div>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>
