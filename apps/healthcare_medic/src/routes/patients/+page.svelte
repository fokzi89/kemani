<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Plus, Search, User, Calendar, FileText, Activity } from 'lucide-svelte';

	let provider = $state(null);
	let patients = $state([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let filteredPatients = $derived(
		patients.filter((p) =>
			p.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
			p.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
			p.phone?.includes(searchQuery)
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

			if (provider) {
				await loadPatients(provider.id);
			}
		}

		loading = false;
	});

	async function loadPatients(providerId: string) {
		// Get unique patients from consultations
		const { data: consultationsData } = await supabase
			.from('consultations')
			.select('patient_id')
			.eq('provider_id', providerId);

		if (consultationsData) {
			const patientIds = [...new Set(consultationsData.map(c => c.patient_id))];

			// Get patient details from auth.users (we'll need to get via consultations with patient info)
			const { data: patientsData } = await supabase
				.from('consultations')
				.select(`
					patient_id,
					created_at
				`)
				.eq('provider_id', providerId)
				.order('created_at', { ascending: false });

			// Group by patient and get their stats
			const patientMap = new Map();

			for (const consultation of patientsData || []) {
				if (!patientMap.has(consultation.patient_id)) {
					// Get consultation count for this patient
					const { count } = await supabase
						.from('consultations')
						.select('*', { count: 'exact', head: true })
						.eq('provider_id', providerId)
						.eq('patient_id', consultation.patient_id);

					// Get last consultation with referral info
					const { data: lastConsult } = await supabase
						.from('consultations')
						.select('created_at, status, type, referral_source, referrer_entity_id')
						.eq('provider_id', providerId)
						.eq('patient_id', consultation.patient_id)
						.order('created_at', { ascending: false })
						.limit(1)
						.single();

					// Get first consultation to check if patient was initially referred
					const { data: firstConsult } = await supabase
						.from('consultations')
						.select('referral_source, referrer_entity_id')
						.eq('provider_id', providerId)
						.eq('patient_id', consultation.patient_id)
						.order('created_at', { ascending: true })
						.limit(1)
						.single();

					patientMap.set(consultation.patient_id, {
						id: consultation.patient_id,
						full_name: `Patient ${consultation.patient_id.slice(0, 8)}`,
						email: '',
						phone: '',
						total_consultations: count || 0,
						last_consultation: lastConsult?.created_at,
						last_consultation_type: lastConsult?.type,
						first_visit: consultation.created_at,
						referral_source: firstConsult?.referral_source || 'direct',
						referrer_entity_id: firstConsult?.referrer_entity_id
					});
				}
			}

			patients = Array.from(patientMap.values());
		}
	}

	function getReferralBadge(referralSource: string) {
		switch (referralSource) {
			case 'storefront':
				return { text: 'Referred by Storefront', color: 'bg-blue-100 text-blue-800' };
			case 'medic_clinic':
				return { text: 'Referred by Clinic', color: 'bg-purple-100 text-purple-800' };
			case 'pharmacy':
				return { text: 'Referred by Pharmacy', color: 'bg-green-100 text-green-800' };
			case 'lab':
				return { text: 'Referred by Lab', color: 'bg-orange-100 text-orange-800' };
			default:
				return { text: 'Direct Patient', color: 'bg-gray-100 text-gray-800' };
		}
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'Never';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}
</script>

<div class="space-y-6">
	<!-- Header -->
	<div class="bg-white rounded-lg shadow p-6">
		<div class="flex justify-between items-center">
			<div>
				<h2 class="text-2xl font-bold text-gray-900">Patients</h2>
				<p class="text-gray-600 mt-1">Manage your patient records and consultations</p>
			</div>
			<a
				href="/patients/add"
				class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors flex items-center gap-2"
			>
				<Plus class="h-5 w-5" />
				Add Patient
			</a>
		</div>
	</div>

	<!-- Search -->
	<div class="bg-white rounded-lg shadow p-4">
		<div class="relative">
			<Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
			<input
				type="text"
				bind:value={searchQuery}
				placeholder="Search patients by name, email, or phone..."
				class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
			/>
		</div>
	</div>

	<!-- Patients List -->
	{#if loading}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading patients...</p>
		</div>
	{:else if filteredPatients.length === 0}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<User class="h-16 w-16 text-gray-300 mx-auto mb-4" />
			<h3 class="text-lg font-medium text-gray-900 mb-2">
				{searchQuery ? 'No patients found' : 'No patients yet'}
			</h3>
			<p class="text-gray-600">
				{searchQuery
					? 'Try adjusting your search terms'
					: 'Add your first patient or wait for consultations to begin'}
			</p>
		</div>
	{:else}
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
			{#each filteredPatients as patient}
				<a href="/patients/{patient.id}" class="bg-white rounded-lg shadow hover:shadow-md transition-shadow p-6 block">
					<div class="flex items-start gap-4">
						<div class="bg-primary-100 p-3 rounded-full flex-shrink-0">
							<User class="h-6 w-6 text-primary-600" />
						</div>

						<div class="flex-1 min-w-0">
							<h3 class="text-lg font-semibold text-gray-900 truncate mb-1">
								{patient.full_name}
							</h3>

							{#if patient.email}
								<p class="text-sm text-gray-600 truncate">{patient.email}</p>
							{/if}
							{#if patient.phone}
								<p class="text-sm text-gray-600">{patient.phone}</p>
							{/if}

							<div class="mt-4 space-y-2">
								<div class="flex items-center gap-2 text-sm text-gray-600">
									<Activity class="h-4 w-4" />
									<span>{patient.total_consultations} consultation{patient.total_consultations !== 1 ? 's' : ''}</span>
								</div>

								<div class="flex items-center gap-2 text-sm text-gray-600">
									<Calendar class="h-4 w-4" />
									<span>Last visit: {formatDate(patient.last_consultation)}</span>
								</div>

								<div class="mt-2 flex flex-wrap gap-2">
									{#if patient.last_consultation_type}
										<span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full capitalize">
											{patient.last_consultation_type}
										</span>
									{/if}

									{@const badge = getReferralBadge(patient.referral_source)}
									<span class="px-2 py-1 {badge.color} text-xs rounded-full">
										{badge.text}
									</span>
								</div>
							</div>
						</div>
					</div>

					<div class="mt-4 pt-4 border-t border-gray-200 flex gap-2">
						<button
							onclick={(e) => { e.preventDefault(); window.location.href = `/patients/${patient.id}/schedule`; }}
							class="flex-1 px-3 py-2 bg-primary-600 text-white text-sm rounded-md hover:bg-primary-700 transition-colors"
						>
							Schedule
						</button>
						<button
							onclick={(e) => { e.preventDefault(); window.location.href = `/patients/${patient.id}/prescribe`; }}
							class="flex-1 px-3 py-2 bg-green-600 text-white text-sm rounded-md hover:bg-green-700 transition-colors"
						>
							Prescribe
						</button>
						<button
							onclick={(e) => { e.preventDefault(); window.location.href = `/patients/${patient.id}/lab-test`; }}
							class="flex-1 px-3 py-2 bg-purple-600 text-white text-sm rounded-md hover:bg-purple-700 transition-colors"
						>
							Lab Test
						</button>
					</div>
				</a>
			{/each}
		</div>
	{/if}
</div>
