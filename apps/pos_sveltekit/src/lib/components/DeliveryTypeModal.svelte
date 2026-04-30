<script lang="ts">
	import { Save, AlertCircle } from 'lucide-svelte';
	import Modal from './Modal.svelte';
	import { supabase } from '$lib/supabase';

	let { open = $bindable(false), tenantId, onSave, deliveryType = null } = $props<any>();

	let loading = $state(false);
	let error = $state('');

	let formData = $state({
		name: '',
		description: '',
		base_fee: 0,
		per_km_fee: 0,
		free_distance_km: 0,
		min_order_value: 0,
		max_distance_km: null as number | null,
		estimated_minutes: null as number | null,
		is_active: true,
		display_order: 0
	});

	$effect(() => {
		if (deliveryType) {
			formData = { 
				name: deliveryType.name || '',
				description: deliveryType.description || '',
				base_fee: deliveryType.base_fee || 0,
				per_km_fee: deliveryType.per_km_fee || 0,
				free_distance_km: deliveryType.free_distance_km || 0,
				min_order_value: deliveryType.min_order_value || 0,
				max_distance_km: deliveryType.max_distance_km || null,
				estimated_minutes: deliveryType.estimated_minutes || null,
				is_active: deliveryType.is_active ?? true,
				display_order: deliveryType.display_order || 0
			};
		} else {
			formData = {
				name: '',
				description: '',
				base_fee: 0,
				per_km_fee: 0,
				free_distance_km: 0,
				min_order_value: 0,
				max_distance_km: null,
				estimated_minutes: null,
				is_active: true,
				display_order: 0
			};
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			const payload = {
				...formData,
				tenant_id: tenantId
			};

			let result;
			if (deliveryType?.id) {
				result = await supabase
					.from('delivery_types')
					.update(payload)
					.eq('id', deliveryType.id);
			} else {
				result = await supabase
					.from('delivery_types')
					.insert(payload);
			}

			if (result.error) throw result.error;

			onSave();
			open = false;
		} catch (err: any) {
			error = err.message || 'Failed to save delivery type';
		} finally {
			loading = false;
		}
	}
</script>

<Modal bind:open title={deliveryType ? 'Edit Delivery Type' : 'Add Delivery Type'} onClose={() => (open = false)}>
	<form onsubmit={handleSubmit} class="space-y-6">
		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg flex items-start gap-2">
				<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" />
				<p class="text-sm font-medium">{error}</p>
			</div>
		{/if}

		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			<div class="md:col-span-2">
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Type Name</label>
				<input
					type="text"
					bind:value={formData.name}
					required
					placeholder="e.g. Motorbike, Van, Bicycle"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
				/>
			</div>

			<div class="md:col-span-2">
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Description</label>
				<textarea
					bind:value={formData.description}
					placeholder="Briefly describe this delivery option"
					rows="2"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm resize-none"
				></textarea>
			</div>

			<div>
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Base Fee (NGN)</label>
				<input
					type="number"
					bind:value={formData.base_fee}
					min="0"
					step="0.01"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
				/>
			</div>

			<div>
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Fee Per KM (NGN)</label>
				<input
					type="number"
					bind:value={formData.per_km_fee}
					min="0"
					step="0.01"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
				/>
			</div>

			<div>
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Free Distance (KM)</label>
				<input
					type="number"
					bind:value={formData.free_distance_km}
					min="0"
					step="0.1"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
				/>
			</div>

			<div>
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Max Distance (KM)</label>
				<input
					type="number"
					bind:value={formData.max_distance_km}
					min="0"
					step="0.1"
					placeholder="Unlimited"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
				/>
			</div>

			<div>
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Min Order Value (NGN)</label>
				<input
					type="number"
					bind:value={formData.min_order_value}
					min="0"
					step="0.01"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
				/>
			</div>

			<div>
				<label class="block text-[13px] font-medium text-gray-700 mb-1.5">Est. Delivery (Min)</label>
				<input
					type="number"
					bind:value={formData.estimated_minutes}
					min="0"
					placeholder="Unknown"
					class="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
				/>
			</div>
		</div>

		<div class="flex items-center gap-4 pt-4">
			<button
				type="button"
				onclick={() => (formData.is_active = !formData.is_active)}
				class="flex items-center gap-2 px-4 py-2 rounded-xl border border-gray-200 text-xs font-semibold transition-all {formData.is_active ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : 'bg-gray-50 text-gray-500'}"
			>
				<div class="h-2 w-2 rounded-full {formData.is_active ? 'bg-emerald-500' : 'bg-gray-400'}"></div>
				{formData.is_active ? 'Active' : 'Inactive'}
			</button>

			<div class="flex-1"></div>

			<button
				type="submit"
				disabled={loading}
				class="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-6 py-2 rounded-xl text-sm transition-all shadow-lg shadow-indigo-100 disabled:opacity-50"
			>
				<Save class="h-4 w-4" />
				{loading ? 'Saving...' : 'Save Type'}
			</button>
		</div>
	</form>
</Modal>
