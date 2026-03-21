<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, Trash2, AlertCircle } from 'lucide-svelte';

	const productId = $page.params.id;
	let loading = $state(true);
	let saving = $state(false);
	let deleting = $state(false);
	let error = $state('');
	let form = $state({
		name: '', sku: '', description: '', category: '', price: '',
		cost_price: '', stock_quantity: '0', low_stock_threshold: '10', unit: '', is_active: true
	});

	onMount(async () => {
		const { data } = await supabase.from('products').select('*').eq('id', productId).single();
		if (data) {
			form = {
				name: data.name || '',
				sku: data.sku || '',
				description: data.description || '',
				category: data.category || '',
				price: data.price?.toString() || '',
				cost_price: data.cost_price?.toString() || '',
				stock_quantity: data.stock_quantity?.toString() || '0',
				low_stock_threshold: data.low_stock_threshold?.toString() || '10',
				unit: data.unit || '',
				is_active: data.is_active ?? true
			};
		}
		loading = false;
	});

	async function handleSave(e: Event) {
		e.preventDefault();
		saving = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('products').update({
				name: form.name, sku: form.sku || null, description: form.description || null,
				category: form.category || null, price: parseFloat(form.price),
				cost_price: form.cost_price ? parseFloat(form.cost_price) : null,
				stock_quantity: parseInt(form.stock_quantity),
				low_stock_threshold: parseInt(form.low_stock_threshold),
				unit: form.unit || null, is_active: form.is_active
			}).eq('id', productId);
			if (dbErr) throw dbErr;
			goto(`/products/${productId}`);
		} catch (err: any) {
			error = err.message || 'Failed to save';
		} finally { saving = false; }
	}

	async function handleDelete() {
		if (!confirm('Are you sure you want to delete this product? This cannot be undone.')) return;
		deleting = true;
		await supabase.from('products').delete().eq('id', productId);
		goto('/products');
	}
</script>

<svelte:head><title>Edit Product – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/products/{productId}" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Edit Product</h1>
			<p class="text-sm text-gray-500">Update product details</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else}
		<form onsubmit={handleSave} class="space-y-5">
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Basic Info</h2>
				<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
					<div class="sm:col-span-2">
						<label class="block text-sm font-medium text-gray-700 mb-1">Product Name *</label>
						<input type="text" bind:value={form.name} required class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">SKU</label>
						<input type="text" bind:value={form.sku} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
						<input type="text" bind:value={form.category} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="sm:col-span-2">
						<label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
						<textarea bind:value={form.description} rows="2" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
					</div>
				</div>
			</div>

			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Pricing</h2>
				<div class="grid grid-cols-3 gap-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Selling Price (₦) *</label>
						<input type="number" bind:value={form.price} required step="0.01" min="0" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Cost Price (₦)</label>
						<input type="number" bind:value={form.cost_price} step="0.01" min="0" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Unit</label>
						<input type="text" bind:value={form.unit} placeholder="piece, kg..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
			</div>

			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Inventory</h2>
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Stock Quantity</label>
						<input type="number" bind:value={form.stock_quantity} min="0" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Low Stock Threshold</label>
						<input type="number" bind:value={form.low_stock_threshold} min="0" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
				<label class="flex items-center gap-3 cursor-pointer">
					<input type="checkbox" bind:checked={form.is_active} class="w-4 h-4 text-indigo-600 rounded border-gray-300" />
					<span class="text-sm font-medium text-gray-700">Product is active</span>
				</label>
			</div>

			<div class="flex gap-3">
				<button type="button" onclick={handleDelete} disabled={deleting} class="flex items-center gap-2 px-4 py-2.5 border border-red-300 text-red-600 font-medium rounded-xl hover:bg-red-50 transition-colors text-sm disabled:opacity-50">
					<Trash2 class="h-4 w-4" />{deleting ? 'Deleting...' : 'Delete'}
				</button>
				<a href="/products/{productId}" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
					Cancel
				</a>
				<button type="submit" disabled={saving} class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
					<Save class="h-4 w-4" />{saving ? 'Saving...' : 'Save Changes'}
				</button>
			</div>
		</form>
	{/if}
</div>
