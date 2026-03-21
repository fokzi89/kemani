<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, AlertCircle } from 'lucide-svelte';

	let tenantId = $state('');
	let loading = $state(false);
	let error = $state('');
	let form = $state({
		name: '', sku: '', description: '', category: '', price: '',
		cost_price: '', stock_quantity: '0', low_stock_threshold: '10',
		unit: '', is_active: true
	});

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) tenantId = user.tenant_id;
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!form.name || !form.price) { error = 'Name and price are required'; return; }
		loading = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('products').insert({
				tenant_id: tenantId,
				name: form.name,
				sku: form.sku || null,
				description: form.description || null,
				category: form.category || null,
				price: parseFloat(form.price),
				cost_price: form.cost_price ? parseFloat(form.cost_price) : null,
				stock_quantity: parseInt(form.stock_quantity),
				low_stock_threshold: parseInt(form.low_stock_threshold),
				unit: form.unit || null,
				is_active: form.is_active
			});
			if (dbErr) throw dbErr;
			goto('/products');
		} catch (err: any) {
			error = err.message || 'Failed to create product';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>New Product – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/products" class="p-2 hover:bg-gray-100 rounded-lg transition-colors"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Add New Product</h1>
			<p class="text-sm text-gray-500">Fill in product details below</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-5">
		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-gray-900 text-sm uppercase tracking-wider text-gray-500">Basic Info</h2>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				<div class="sm:col-span-2">
					<label class="block text-sm font-medium text-gray-700 mb-1">Product Name <span class="text-red-500">*</span></label>
					<input type="text" bind:value={form.name} required placeholder="e.g. Bottle of Water" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">SKU / Barcode</label>
					<input type="text" bind:value={form.sku} placeholder="e.g. PRD-001" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
					<input type="text" bind:value={form.category} placeholder="e.g. Beverages" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div class="sm:col-span-2">
					<label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
					<textarea bind:value={form.description} rows="2" placeholder="Optional product description..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
				</div>
			</div>
		</div>

		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Pricing</h2>
			<div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Selling Price (₦) <span class="text-red-500">*</span></label>
					<input type="number" bind:value={form.price} required step="0.01" min="0" placeholder="0.00" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Cost Price (₦)</label>
					<input type="number" bind:value={form.cost_price} step="0.01" min="0" placeholder="0.00" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Unit</label>
					<input type="text" bind:value={form.unit} placeholder="e.g. piece, kg, pack" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
			</div>
		</div>

		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Inventory</h2>
			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Initial Stock Quantity</label>
					<input type="number" bind:value={form.stock_quantity} min="0" placeholder="0" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Low Stock Alert (below)</label>
					<input type="number" bind:value={form.low_stock_threshold} min="0" placeholder="10" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
			</div>
			<label class="flex items-center gap-3 cursor-pointer">
				<input type="checkbox" bind:checked={form.is_active} class="w-4 h-4 text-indigo-600 rounded border-gray-300 focus:ring-indigo-500" />
				<span class="text-sm font-medium text-gray-700">Product is active and visible in POS</span>
			</label>
		</div>

		<div class="flex gap-3">
			<a href="/products" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
				Cancel
			</a>
			<button type="submit" disabled={loading} class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
				<Save class="h-4 w-4" />{loading ? 'Saving...' : 'Save Product'}
			</button>
		</div>
	</form>
</div>
