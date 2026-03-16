<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Plus, Calendar, Clock, Trash2, Edit } from 'lucide-svelte';

	let provider = $state(null);
	let availabilityTemplates = $state([]);
	let loading = $state(true);
	let showAddForm = $state(false);

	let formData = $state({
		day_of_week: 1,
		start_time: '09:00',
		end_time: '17:00',
		slot_duration: 30,
		buffer_minutes: 0,
		consultation_types: ['chat', 'video', 'audio']
	});

	const daysOfWeek = [
		{ value: 0, label: 'Sunday' },
		{ value: 1, label: 'Monday' },
		{ value: 2, label: 'Tuesday' },
		{ value: 3, label: 'Wednesday' },
		{ value: 4, label: 'Thursday' },
		{ value: 5, label: 'Friday' },
		{ value: 6, label: 'Saturday' }
	];

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
				await loadAvailability(provider.id);
			}
		}

		loading = false;
	});

	async function loadAvailability(providerId: string) {
		const { data } = await supabase
			.from('provider_availability_templates')
			.select('*')
			.eq('provider_id', providerId)
			.order('day_of_week', { ascending: true });

		availabilityTemplates = data || [];
	}

	async function handleAddAvailability(e: Event) {
		e.preventDefault();

		if (!provider) return;

		const { error } = await supabase
			.from('provider_availability_templates')
			.insert({
				provider_id: provider.id,
				...formData
			});

		if (!error) {
			await loadAvailability(provider.id);
			showAddForm = false;
			resetForm();
		}
	}

	async function deleteTemplate(id: string) {
		if (!confirm('Are you sure you want to delete this availability template?')) return;

		const { error } = await supabase
			.from('provider_availability_templates')
			.delete()
			.eq('id', id);

		if (!error && provider) {
			await loadAvailability(provider.id);
		}
	}

	function resetForm() {
		formData = {
			day_of_week: 1,
			start_time: '09:00',
			end_time: '17:00',
			slot_duration: 30,
			buffer_minutes: 0,
			consultation_types: ['chat', 'video', 'audio']
		};
	}

	function getDayName(dayNumber: number) {
		return daysOfWeek.find(d => d.value === dayNumber)?.label || 'Unknown';
	}

	function toggleConsultationType(type: string) {
		if (formData.consultation_types.includes(type)) {
			formData.consultation_types = formData.consultation_types.filter(t => t !== type);
		} else {
			formData.consultation_types = [...formData.consultation_types, type];
		}
	}
</script>

<div class="space-y-6">
	<!-- Header -->
	<div class="bg-white rounded-lg shadow p-6">
		<div class="flex justify-between items-center">
			<div>
				<h2 class="text-2xl font-bold text-gray-900">Availability Management</h2>
				<p class="text-gray-600 mt-1">Set your weekly availability schedule</p>
			</div>
			<button
				onclick={() => showAddForm = !showAddForm}
				class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors flex items-center gap-2"
			>
				<Plus class="h-5 w-5" />
				Add Availability
			</button>
		</div>
	</div>

	<!-- Add Form -->
	{#if showAddForm}
		<div class="bg-white rounded-lg shadow p-6">
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Add Availability Template</h3>
			<form onsubmit={handleAddAvailability} class="space-y-4">
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div>
						<label for="day" class="block text-sm font-medium text-gray-700 mb-2">
							Day of Week
						</label>
						<select
							id="day"
							bind:value={formData.day_of_week}
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500"
						>
							{#each daysOfWeek as day}
								<option value={day.value}>{day.label}</option>
							{/each}
						</select>
					</div>

					<div>
						<label for="slot_duration" class="block text-sm font-medium text-gray-700 mb-2">
							Slot Duration (minutes)
						</label>
						<select
							id="slot_duration"
							bind:value={formData.slot_duration}
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500"
						>
							<option value={15}>15 minutes</option>
							<option value={30}>30 minutes</option>
							<option value={45}>45 minutes</option>
							<option value={60}>60 minutes</option>
						</select>
					</div>

					<div>
						<label for="start_time" class="block text-sm font-medium text-gray-700 mb-2">
							Start Time
						</label>
						<input
							id="start_time"
							type="time"
							bind:value={formData.start_time}
							required
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500"
						/>
					</div>

					<div>
						<label for="end_time" class="block text-sm font-medium text-gray-700 mb-2">
							End Time
						</label>
						<input
							id="end_time"
							type="time"
							bind:value={formData.end_time}
							required
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500"
						/>
					</div>

					<div>
						<label for="buffer" class="block text-sm font-medium text-gray-700 mb-2">
							Buffer Between Slots (minutes)
						</label>
						<input
							id="buffer"
							type="number"
							bind:value={formData.buffer_minutes}
							min="0"
							max="60"
							class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500"
						/>
					</div>
				</div>

				<div>
					<label class="block text-sm font-medium text-gray-700 mb-2">
						Consultation Types
					</label>
					<div class="flex flex-wrap gap-2">
						{#each ['chat', 'video', 'audio', 'office_visit'] as type}
							<button
								type="button"
								onclick={() => toggleConsultationType(type)}
								class="px-4 py-2 rounded-md transition-colors {formData.consultation_types.includes(type) ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
							>
								{type.replace('_', ' ')}
							</button>
						{/each}
					</div>
				</div>

				<div class="flex gap-4">
					<button
						type="button"
						onclick={() => { showAddForm = false; resetForm(); }}
						class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors"
					>
						Cancel
					</button>
					<button
						type="submit"
						class="flex-1 px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors"
					>
						Add Template
					</button>
				</div>
			</form>
		</div>
	{/if}

	<!-- Templates List -->
	{#if loading}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading availability...</p>
		</div>
	{:else if availabilityTemplates.length === 0}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<Calendar class="h-16 w-16 text-gray-300 mx-auto mb-4" />
			<h3 class="text-lg font-medium text-gray-900 mb-2">No availability set</h3>
			<p class="text-gray-600">Add your first availability template to start accepting bookings.</p>
		</div>
	{:else}
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
			{#each availabilityTemplates as template}
				<div class="bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow">
					<div class="flex items-start justify-between mb-4">
						<div class="bg-primary-100 p-3 rounded-full">
							<Calendar class="h-6 w-6 text-primary-600" />
						</div>
						<button
							onclick={() => deleteTemplate(template.id)}
							class="p-2 text-red-600 hover:bg-red-50 rounded-md transition-colors"
							title="Delete"
						>
							<Trash2 class="h-5 w-5" />
						</button>
					</div>

					<h3 class="text-lg font-semibold text-gray-900 mb-2">
						{getDayName(template.day_of_week)}
					</h3>

					<div class="space-y-2 text-sm text-gray-600">
						<div class="flex items-center gap-2">
							<Clock class="h-4 w-4" />
							<span>{template.start_time} - {template.end_time}</span>
						</div>

						<div>
							<span class="font-medium">Slot Duration:</span> {template.slot_duration} min
						</div>

						{#if template.buffer_minutes > 0}
							<div>
								<span class="font-medium">Buffer:</span> {template.buffer_minutes} min
							</div>
						{/if}

						<div>
							<span class="font-medium">Types:</span>
							<div class="flex flex-wrap gap-1 mt-1">
								{#each template.consultation_types as type}
									<span class="px-2 py-1 bg-primary-100 text-primary-700 text-xs rounded-full">
										{type}
									</span>
								{/each}
							</div>
						</div>

						<div class="pt-2">
							<span class="px-2 py-1 rounded-full text-xs {template.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}">
								{template.is_active ? 'Active' : 'Inactive'}
							</span>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>
