<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { ArrowLeft, FileText, Plus, Trash2 } from 'lucide-svelte';

	const patientId = $derived($page.params.id);

	let provider = $state(null);
	let consultations = $state([]);
	let loading = $state(false);
	let error = $state('');

	let formData = $state({
		consultation_id: '',
		diagnosis: '',
		notes: '',
		medications: [
			{
				name: '',
				generic_name: '',
				nafdac_number: '',
				quantity: '',
				dosage: '',
				frequency: '',
				duration: '',
				special_instructions: ''
			}
		]
	});

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
				// Load patient's consultations
				const { data: consultsData } = await supabase
					.from('consultations')
					.select('*')
					.eq('provider_id', provider.id)
					.eq('patient_id', patientId)
					.order('created_at', { ascending: false });

				consultations = consultsData || [];
			}
		}
	});

	function addMedication() {
		formData.medications = [
			...formData.medications,
			{
				name: '',
				generic_name: '',
				nafdac_number: '',
				quantity: '',
				dosage: '',
				frequency: '',
				duration: '',
				special_instructions: ''
			}
		];
	}

	function removeMedication(index: number) {
		formData.medications = formData.medications.filter((_, i) => i !== index);
	}

	async function handleSubmit(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			if (!provider) throw new Error('Provider not found');

			const { data, error: prescError } = await supabase
				.from('prescriptions')
				.insert({
					consultation_id: formData.consultation_id || null,
					provider_id: provider.id,
					patient_id: patientId,
					diagnosis: formData.diagnosis,
					medications: formData.medications,
					notes: formData.notes,
					provider_name: provider.full_name,
					provider_credentials: provider.credentials,
					status: 'active'
				})
				.select()
				.single();

			if (prescError) throw prescError;

			goto('/prescriptions');
		} catch (err: any) {
			error = err.message || 'Failed to create prescription';
			loading = false;
		}
	}
</script>

<div class="max-w-5xl mx-auto space-y-6">
	<!-- Header -->
	<div class="bg-white rounded-lg shadow p-6">
		<div class="flex items-center gap-4">
			<a
				href="/patients"
				class="p-2 hover:bg-gray-100 rounded-md transition-colors"
			>
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</a>
			<div class="flex items-center gap-3">
				<div class="bg-green-100 p-3 rounded-full">
					<FileText class="h-6 w-6 text-green-600" />
				</div>
				<div>
					<h2 class="text-2xl font-bold text-gray-900">Create Prescription</h2>
					<p class="text-gray-600 mt-1">Write a prescription for patient</p>
				</div>
			</div>
		</div>
	</div>

	<!-- Form -->
	<form onsubmit={handleSubmit} class="bg-white rounded-lg shadow p-6 space-y-6">
		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md text-sm">
				{error}
			</div>
		{/if}

		<!-- Link to Consultation (Optional) -->
		<div>
			<label for="consultation_id" class="block text-sm font-medium text-gray-700 mb-2">
				Related Consultation (Optional)
			</label>
			<select
				id="consultation_id"
				bind:value={formData.consultation_id}
				class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
			>
				<option value="">No consultation selected</option>
				{#each consultations as consultation}
					<option value={consultation.id}>
						{new Date(consultation.created_at).toLocaleDateString()} - {consultation.type} - {consultation.status}
					</option>
				{/each}
			</select>
		</div>

		<!-- Diagnosis -->
		<div>
			<label for="diagnosis" class="block text-sm font-medium text-gray-700 mb-2">
				Diagnosis
			</label>
			<textarea
				id="diagnosis"
				bind:value={formData.diagnosis}
				rows="2"
				class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
				placeholder="Enter diagnosis..."
			></textarea>
		</div>

		<!-- Medications -->
		<div>
			<div class="flex justify-between items-center mb-4">
				<h3 class="text-lg font-semibold text-gray-900">Medications</h3>
				<button
					type="button"
					onclick={addMedication}
					class="px-3 py-2 bg-primary-600 text-white text-sm rounded-md hover:bg-primary-700 transition-colors flex items-center gap-2"
				>
					<Plus class="h-4 w-4" />
					Add Medication
				</button>
			</div>

			<div class="space-y-6">
				{#each formData.medications as medication, index}
					<div class="border border-gray-200 rounded-lg p-4 relative">
						{#if formData.medications.length > 1}
							<button
								type="button"
								onclick={() => removeMedication(index)}
								class="absolute top-4 right-4 p-2 text-red-600 hover:bg-red-50 rounded-md transition-colors"
								title="Remove medication"
							>
								<Trash2 class="h-4 w-4" />
							</button>
						{/if}

						<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
							<div>
								<label for="med_name_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Medication Name *
								</label>
								<input
									id="med_name_{index}"
									type="text"
									bind:value={medication.name}
									required
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="Paracetamol"
								/>
							</div>

							<div>
								<label for="generic_name_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Generic Name
								</label>
								<input
									id="generic_name_{index}"
									type="text"
									bind:value={medication.generic_name}
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="Acetaminophen"
								/>
							</div>

							<div>
								<label for="nafdac_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									NAFDAC Number
								</label>
								<input
									id="nafdac_{index}"
									type="text"
									bind:value={medication.nafdac_number}
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="A4-1234"
								/>
							</div>

							<div>
								<label for="quantity_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Quantity *
								</label>
								<input
									id="quantity_{index}"
									type="text"
									bind:value={medication.quantity}
									required
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="20 tablets"
								/>
							</div>

							<div>
								<label for="dosage_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Dosage *
								</label>
								<input
									id="dosage_{index}"
									type="text"
									bind:value={medication.dosage}
									required
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="500mg"
								/>
							</div>

							<div>
								<label for="frequency_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Frequency *
								</label>
								<input
									id="frequency_{index}"
									type="text"
									bind:value={medication.frequency}
									required
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="3 times daily"
								/>
							</div>

							<div>
								<label for="duration_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Duration *
								</label>
								<input
									id="duration_{index}"
									type="text"
									bind:value={medication.duration}
									required
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="7 days"
								/>
							</div>

							<div class="md:col-span-2">
								<label for="instructions_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Special Instructions
								</label>
								<input
									id="instructions_{index}"
									type="text"
									bind:value={medication.special_instructions}
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="Take after meals"
								/>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</div>

		<!-- Additional Notes -->
		<div>
			<label for="notes" class="block text-sm font-medium text-gray-700 mb-2">
				Additional Notes
			</label>
			<textarea
				id="notes"
				bind:value={formData.notes}
				rows="3"
				class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
				placeholder="Additional instructions or recommendations..."
			></textarea>
		</div>

		<!-- Actions -->
		<div class="flex gap-4 pt-4">
			<a
				href="/patients"
				class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors text-center"
			>
				Cancel
			</a>
			<button
				type="submit"
				disabled={loading}
				class="flex-1 px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
			>
				{loading ? 'Creating Prescription...' : 'Create Prescription'}
			</button>
		</div>
	</form>
</div>
