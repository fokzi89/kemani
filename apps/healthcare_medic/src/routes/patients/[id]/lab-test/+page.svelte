<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { ArrowLeft, Activity, Plus, Trash2 } from 'lucide-svelte';

	const patientId = $derived($page.params.id);

	let provider = $state(null);
	let consultations = $state([]);
	let loading = $state(false);
	let error = $state('');

	let formData = $state({
		consultation_id: '',
		test_type: 'blood_test',
		priority: 'routine',
		clinical_indication: '',
		notes: '',
		tests: [
			{
				name: '',
				code: '',
				sample_type: 'blood',
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

	function addTest() {
		formData.tests = [
			...formData.tests,
			{
				name: '',
				code: '',
				sample_type: 'blood',
				special_instructions: ''
			}
		];
	}

	function removeTest(index: number) {
		formData.tests = formData.tests.filter((_, i) => i !== index);
	}

	async function handleSubmit(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			if (!provider) throw new Error('Provider not found');

			// Note: You would need to create a lab_tests table for this
			// For now, we'll save it as a consultation note or custom table
			alert('Lab test request feature requires lab_tests table setup. This will be created in the database schema.');

			goto('/patients');
		} catch (err: any) {
			error = err.message || 'Failed to request lab test';
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
				<div class="bg-purple-100 p-3 rounded-full">
					<Activity class="h-6 w-6 text-purple-600" />
				</div>
				<div>
					<h2 class="text-2xl font-bold text-gray-900">Request Lab Test</h2>
					<p class="text-gray-600 mt-1">Order laboratory tests for patient</p>
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

		<!-- Request Details -->
		<div>
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Request Details</h3>
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
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
								{new Date(consultation.created_at).toLocaleDateString()} - {consultation.type}
							</option>
						{/each}
					</select>
				</div>

				<div>
					<label for="test_type" class="block text-sm font-medium text-gray-700 mb-2">
						Test Category *
					</label>
					<select
						id="test_type"
						bind:value={formData.test_type}
						required
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					>
						<option value="blood_test">Blood Test</option>
						<option value="urine_test">Urine Test</option>
						<option value="imaging">Imaging (X-Ray, CT, MRI)</option>
						<option value="biopsy">Biopsy</option>
						<option value="culture">Culture & Sensitivity</option>
						<option value="other">Other</option>
					</select>
				</div>

				<div>
					<label for="priority" class="block text-sm font-medium text-gray-700 mb-2">
						Priority *
					</label>
					<select
						id="priority"
						bind:value={formData.priority}
						required
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					>
						<option value="routine">Routine</option>
						<option value="urgent">Urgent</option>
						<option value="stat">STAT (Immediate)</option>
					</select>
				</div>

				<div class="md:col-span-2">
					<label for="clinical_indication" class="block text-sm font-medium text-gray-700 mb-2">
						Clinical Indication *
					</label>
					<textarea
						id="clinical_indication"
						bind:value={formData.clinical_indication}
						required
						rows="2"
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="Reason for test request..."
					></textarea>
				</div>
			</div>
		</div>

		<!-- Tests -->
		<div>
			<div class="flex justify-between items-center mb-4">
				<h3 class="text-lg font-semibold text-gray-900">Tests Requested</h3>
				<button
					type="button"
					onclick={addTest}
					class="px-3 py-2 bg-purple-600 text-white text-sm rounded-md hover:bg-purple-700 transition-colors flex items-center gap-2"
				>
					<Plus class="h-4 w-4" />
					Add Test
				</button>
			</div>

			<div class="space-y-4">
				{#each formData.tests as test, index}
					<div class="border border-gray-200 rounded-lg p-4 relative">
						{#if formData.tests.length > 1}
							<button
								type="button"
								onclick={() => removeTest(index)}
								class="absolute top-4 right-4 p-2 text-red-600 hover:bg-red-50 rounded-md transition-colors"
								title="Remove test"
							>
								<Trash2 class="h-4 w-4" />
							</button>
						{/if}

						<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
							<div>
								<label for="test_name_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Test Name *
								</label>
								<input
									id="test_name_{index}"
									type="text"
									bind:value={test.name}
									required
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="Complete Blood Count (CBC)"
								/>
							</div>

							<div>
								<label for="test_code_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Test Code
								</label>
								<input
									id="test_code_{index}"
									type="text"
									bind:value={test.code}
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="CBC-001"
								/>
							</div>

							<div>
								<label for="sample_type_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Sample Type *
								</label>
								<select
									id="sample_type_{index}"
									bind:value={test.sample_type}
									required
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
								>
									<option value="blood">Blood</option>
									<option value="urine">Urine</option>
									<option value="stool">Stool</option>
									<option value="swab">Swab</option>
									<option value="tissue">Tissue</option>
									<option value="other">Other</option>
								</select>
							</div>

							<div>
								<label for="special_instructions_{index}" class="block text-sm font-medium text-gray-700 mb-2">
									Special Instructions
								</label>
								<input
									id="special_instructions_{index}"
									type="text"
									bind:value={test.special_instructions}
									class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
									placeholder="Fasting required, etc."
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
				placeholder="Any additional information for the lab..."
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
				class="flex-1 px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
			>
				{loading ? 'Submitting Request...' : 'Submit Lab Request'}
			</button>
		</div>
	</form>
</div>
