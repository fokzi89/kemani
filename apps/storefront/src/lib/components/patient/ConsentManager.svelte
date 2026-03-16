<script lang="ts">
	import { onMount } from 'svelte';
	import { PatientIdentityService } from '$lib/services/patientIdentity';
	import type { CrossTenantConsent } from '$lib/services/patientIdentity';

	export let customerId: string;

	let consent: CrossTenantConsent | null = null;
	let loading = true;
	let saving = false;
	let error = '';
	let success = '';

	// Local state for consent toggles
	let shareMedicalHistory = false;
	let sharePrescriptions = false;
	let shareConsultationNotes = false;
	let sharePurchaseHistory = false;
	let shareWithPharmacies = false;
	let shareWithLabs = false;
	let shareWithDoctors = true;

	onMount(async () => {
		await loadConsent();
	});

	async function loadConsent() {
		loading = true;
		error = '';

		const result = await PatientIdentityService.getConsent(customerId);

		if (result) {
			consent = result;
			// Update local state
			shareMedicalHistory = result.share_medical_history;
			sharePrescriptions = result.share_prescriptions;
			shareConsultationNotes = result.share_consultation_notes;
			sharePurchaseHistory = result.share_purchase_history;
			shareWithPharmacies = result.share_with_pharmacies;
			shareWithLabs = result.share_with_labs;
			shareWithDoctors = result.share_with_doctors;
		} else {
			error = 'Unable to load consent settings';
		}

		loading = false;
	}

	async function handleSave() {
		saving = true;
		error = '';
		success = '';

		const result = await PatientIdentityService.updateConsent(customerId, {
			share_medical_history: shareMedicalHistory,
			share_prescriptions: sharePrescriptions,
			share_consultation_notes: shareConsultationNotes,
			share_purchase_history: sharePurchaseHistory,
			share_with_pharmacies: shareWithPharmacies,
			share_with_labs: shareWithLabs,
			share_with_doctors: shareWithDoctors
		});

		saving = false;

		if (result.success) {
			success = 'Privacy preferences saved successfully!';
			setTimeout(() => {
				success = '';
			}, 3000);
		} else {
			error = 'Failed to save preferences. Please try again.';
		}
	}
</script>

<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 space-y-6">
	<div class="border-b dark:border-gray-700 pb-4">
		<h2 class="text-2xl font-bold text-gray-900 dark:text-white">Privacy & Data Sharing</h2>
		<p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
			Control how your medical information is shared across different healthcare providers
		</p>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<svg class="animate-spin h-8 w-8 text-blue-600" viewBox="0 0 24 24">
				<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
				<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
			</svg>
		</div>
	{:else}
		{#if error}
			<div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 px-4 py-3 rounded-lg">
				{error}
			</div>
		{/if}

		{#if success}
			<div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 text-green-600 dark:text-green-400 px-4 py-3 rounded-lg">
				{success}
			</div>
		{/if}

		<div class="space-y-4">
			<!-- Medical History -->
			<label class="flex items-start gap-3 cursor-pointer group">
				<input
					type="checkbox"
					bind:checked={shareMedicalHistory}
					class="mt-1 w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
				/>
				<div class="flex-1">
					<div class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
						Share Medical History
					</div>
					<div class="text-sm text-gray-600 dark:text-gray-400">
						Allow healthcare providers to see your complete medical history across all clinics
					</div>
				</div>
			</label>

			<!-- Prescriptions -->
			<label class="flex items-start gap-3 cursor-pointer group">
				<input
					type="checkbox"
					bind:checked={sharePrescriptions}
					class="mt-1 w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
				/>
				<div class="flex-1">
					<div class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
						Share Prescriptions
					</div>
					<div class="text-sm text-gray-600 dark:text-gray-400">
						Allow doctors and pharmacists to see prescriptions from other providers
					</div>
				</div>
			</label>

			<!-- Consultation Notes -->
			<label class="flex items-start gap-3 cursor-pointer group">
				<input
					type="checkbox"
					bind:checked={shareConsultationNotes}
					class="mt-1 w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
				/>
				<div class="flex-1">
					<div class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
						Share Consultation Notes
					</div>
					<div class="text-sm text-gray-600 dark:text-gray-400">
						Allow doctors to view detailed notes from previous consultations
					</div>
				</div>
			</label>

			<!-- Purchase History -->
			<label class="flex items-start gap-3 cursor-pointer group">
				<input
					type="checkbox"
					bind:checked={sharePurchaseHistory}
					class="mt-1 w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
				/>
				<div class="flex-1">
					<div class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
						Share Purchase History
					</div>
					<div class="text-sm text-gray-600 dark:text-gray-400">
						Allow providers to see your medication and product purchase history
					</div>
				</div>
			</label>

			<div class="border-t dark:border-gray-700 pt-4 mt-6">
				<h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">Share With Specific Providers</h3>

				<!-- Share with Pharmacies -->
				<label class="flex items-start gap-3 cursor-pointer group mb-3">
					<input
						type="checkbox"
						bind:checked={shareWithPharmacies}
						class="mt-1 w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
					/>
					<div class="flex-1">
						<div class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
							Pharmacies
						</div>
						<div class="text-sm text-gray-600 dark:text-gray-400">
							Share relevant data with pharmacies when filling prescriptions
						</div>
					</div>
				</label>

				<!-- Share with Labs -->
				<label class="flex items-start gap-3 cursor-pointer group mb-3">
					<input
						type="checkbox"
						bind:checked={shareWithLabs}
						class="mt-1 w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
					/>
					<div class="flex-1">
						<div class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
							Diagnostic Labs
						</div>
						<div class="text-sm text-gray-600 dark:text-gray-400">
							Share test results and medical history with diagnostic centers
						</div>
					</div>
				</label>

				<!-- Share with Doctors -->
				<label class="flex items-start gap-3 cursor-pointer group">
					<input
						type="checkbox"
						bind:checked={shareWithDoctors}
						class="mt-1 w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
					/>
					<div class="flex-1">
						<div class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
							Doctors & Medical Professionals
						</div>
						<div class="text-sm text-gray-600 dark:text-gray-400">
							Share complete medical history with doctors for better care (Recommended)
						</div>
					</div>
				</label>
			</div>
		</div>

		<div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
			<div class="flex items-start gap-3">
				<svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
				</svg>
				<div class="flex-1 text-sm text-blue-800 dark:text-blue-300">
					<strong>Your privacy matters.</strong> You can change these settings at any time.
					Sharing your medical history helps healthcare providers give you better, safer care.
				</div>
			</div>
		</div>

		<div class="flex gap-3 pt-4">
			<button
				on:click={handleSave}
				disabled={saving}
				class="flex-1 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-semibold py-3 px-4 rounded-lg transition duration-200 flex items-center justify-center"
			>
				{#if saving}
					<svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
						<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
						<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
					</svg>
					Saving...
				{:else}
					Save Preferences
				{/if}
			</button>
		</div>
	{/if}
</div>
