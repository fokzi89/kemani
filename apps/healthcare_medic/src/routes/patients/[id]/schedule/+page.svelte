<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { ArrowLeft, Calendar } from 'lucide-svelte';

	const patientId = $derived($page.params.id);

	let provider = $state(null);
	let loading = $state(false);
	let error = $state('');

	let formData = $state({
		type: 'office_visit',
		scheduled_date: '',
		scheduled_time: '',
		duration: 30,
		consultation_fee: 15000,
		notes: '',
		location_address: {
			street: '',
			city: '',
			postal_code: '',
			country: 'Nigeria'
		}
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
				// Pre-fill clinic address
				if (provider.clinic_address) {
					formData.location_address = {
						...provider.clinic_address,
						country: provider.clinic_address.country || 'Nigeria'
					};
				}

				// Pre-fill fee based on type
				if (provider.fees?.office_visit) {
					formData.consultation_fee = provider.fees.office_visit;
				}
			}
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			if (!provider) throw new Error('Provider not found');

			const scheduledDateTime = `${formData.scheduled_date}T${formData.scheduled_time}:00`;

			const { data, error: consultError } = await supabase
				.from('consultations')
				.insert({
					provider_id: provider.id,
					patient_id: patientId,
					tenant_id: provider.id, // Using provider as tenant for now
					type: formData.type,
					status: 'pending',
					scheduled_time: scheduledDateTime,
					slot_duration: formData.duration,
					location_address: formData.location_address,
					provider_name: provider.full_name,
					provider_photo_url: provider.profile_photo_url,
					consultation_fee: formData.consultation_fee,
					payment_status: 'pending',
					referral_source: 'direct'
				})
				.select()
				.single();

			if (consultError) throw consultError;

			goto(`/consultations`);
		} catch (err: any) {
			error = err.message || 'Failed to schedule consultation';
			loading = false;
		}
	}

	function updateFee() {
		if (provider?.fees) {
			const typeMap = {
				'office_visit': provider.fees.office_visit,
				'video': provider.fees.video,
				'audio': provider.fees.audio,
				'chat': provider.fees.chat
			};
			formData.consultation_fee = typeMap[formData.type] || 15000;
		}
	}
</script>

<div class="max-w-3xl mx-auto space-y-6">
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
				<div class="bg-primary-100 p-3 rounded-full">
					<Calendar class="h-6 w-6 text-primary-600" />
				</div>
				<div>
					<h2 class="text-2xl font-bold text-gray-900">Schedule Consultation</h2>
					<p class="text-gray-600 mt-1">Book an office visit for patient</p>
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

		<!-- Consultation Details -->
		<div>
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Consultation Details</h3>
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
				<div>
					<label for="type" class="block text-sm font-medium text-gray-700 mb-2">
						Consultation Type *
					</label>
					<select
						id="type"
						bind:value={formData.type}
						onchange={updateFee}
						required
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					>
						<option value="office_visit">Office Visit</option>
						<option value="video">Video Consultation</option>
						<option value="audio">Audio Call</option>
						<option value="chat">Chat</option>
					</select>
				</div>

				<div>
					<label for="consultation_fee" class="block text-sm font-medium text-gray-700 mb-2">
						Consultation Fee (₦) *
					</label>
					<input
						id="consultation_fee"
						type="number"
						bind:value={formData.consultation_fee}
						required
						min="0"
						step="100"
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					/>
				</div>

				<div>
					<label for="scheduled_date" class="block text-sm font-medium text-gray-700 mb-2">
						Date *
					</label>
					<input
						id="scheduled_date"
						type="date"
						bind:value={formData.scheduled_date}
						required
						min={new Date().toISOString().split('T')[0]}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					/>
				</div>

				<div>
					<label for="scheduled_time" class="block text-sm font-medium text-gray-700 mb-2">
						Time *
					</label>
					<input
						id="scheduled_time"
						type="time"
						bind:value={formData.scheduled_time}
						required
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					/>
				</div>

				<div>
					<label for="duration" class="block text-sm font-medium text-gray-700 mb-2">
						Duration (minutes) *
					</label>
					<select
						id="duration"
						bind:value={formData.duration}
						required
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					>
						<option value={15}>15 minutes</option>
						<option value={30}>30 minutes</option>
						<option value={45}>45 minutes</option>
						<option value={60}>1 hour</option>
					</select>
				</div>
			</div>
		</div>

		<!-- Location (for office visits) -->
		{#if formData.type === 'office_visit'}
			<div>
				<h3 class="text-lg font-semibold text-gray-900 mb-4">Location</h3>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="md:col-span-2">
						<label for="street" class="block text-sm font-medium text-gray-700 mb-2">
							Street Address *
						</label>
						<input
							id="street"
							type="text"
							bind:value={formData.location_address.street}
							required={formData.type === 'office_visit'}
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
							placeholder="123 Clinic Street"
						/>
					</div>

					<div>
						<label for="city" class="block text-sm font-medium text-gray-700 mb-2">
							City *
						</label>
						<input
							id="city"
							type="text"
							bind:value={formData.location_address.city}
							required={formData.type === 'office_visit'}
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
							placeholder="Lagos"
						/>
					</div>

					<div>
						<label for="postal_code" class="block text-sm font-medium text-gray-700 mb-2">
							Postal Code
						</label>
						<input
							id="postal_code"
							type="text"
							bind:value={formData.location_address.postal_code}
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
							placeholder="100001"
						/>
					</div>
				</div>
			</div>
		{/if}

		<!-- Notes -->
		<div>
			<label for="notes" class="block text-sm font-medium text-gray-700 mb-2">
				Notes (Optional)
			</label>
			<textarea
				id="notes"
				bind:value={formData.notes}
				rows="3"
				class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
				placeholder="Add any notes or special instructions..."
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
				class="flex-1 px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
			>
				{loading ? 'Scheduling...' : 'Schedule Consultation'}
			</button>
		</div>
	</form>
</div>
