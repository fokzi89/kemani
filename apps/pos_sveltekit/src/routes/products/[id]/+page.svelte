<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Edit, Package, ShoppingBag, AlertTriangle, ToggleLeft, ToggleRight } from 'lucide-svelte';

	const productId = $page.params.id;
	let product = $state<any>(null);
	let salesHistory = $state<any[]>([]);
	let branchInventory = $state<any>(null);
	let loading = $state(true);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		let currentBranchId = null;
		if (session) {
			const { data: user } = await supabase.from('users').select('branch_id').eq('id', session.user.id).single();
			currentBranchId = user?.branch_id;
		}

		const { data } = await supabase.from('products').select('*').eq('id', productId).single();
		product = data;

		if (data) {
			if (currentBranchId) {
				const { data: invData } = await supabase
					.from('branch_inventory')
					.select('stock_quantity, selling_price')
					.eq('product_id', productId)
					.eq('branch_id', currentBranchId)
					.limit(1)
					.maybeSingle();
				branchInventory = invData;
			}

			const { data: items } = await supabase
				.from('sale_items')
				.select('*, sales(created_at, payment_method, status)')
				.eq('product_id', productId)
				.order('created_at', { ascending: false })
				.limit(10);
			salesHistory = items || [];
		}
		loading = false;
	});

	async function toggleActive() {
		if (!product) return;
		await supabase.from('products').update({ is_active: !product.is_active }).eq('id', productId);
		product = { ...product, is_active: !product.is_active };
	}
</script>

<svelte:head><title>{product?.name || 'Product'} – Kemani POS</title></svelte:head>

<div class="p-6 max-w-4xl mx-auto space-y-5">
	<div class="flex items-center justify-between">
		<div class="flex items-center gap-3">
			<a href="/products" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
			<h1 class="text-xl font-bold text-gray-900">{product?.name || 'Product Detail'}</h1>
		</div>
		{#if product}
			<a href="/products/{productId}/edit" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2 rounded-xl text-sm transition-colors">
				<Edit class="h-4 w-4" /> Edit Product
			</a>
		{/if}
	</div>

	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else if product}
		<div class="grid grid-cols-1 md:grid-cols-3 gap-5">
			<!-- Left: Product Info -->
			<div class="md:col-span-2 space-y-4">
				<div class="bg-white rounded-xl border p-5">
					<div class="flex items-start gap-4">
						<div class="w-20 h-20 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-xl flex items-center justify-center flex-shrink-0">
							{#if product.image_url}
								<img src={product.image_url} alt={product.name} class="w-20 h-20 object-cover rounded-xl" />
							{:else}
								<Package class="h-10 w-10 text-indigo-300" />
							{/if}
						</div>
						<div class="flex-1">
							<h2 class="text-xl font-bold text-gray-900">{product.name}</h2>
							{#if product.description}
								<p class="text-sm text-gray-500 mt-1">{product.description}</p>
							{/if}
							{#if product.product_details}
								<p class="text-sm text-gray-600 mt-2 p-3 bg-gray-50 rounded-lg border border-gray-100">{product.product_details}</p>
							{/if}
							<div class="flex flex-wrap gap-2 mt-3">
								{#if product.category}
									<span class="px-2.5 py-1 bg-indigo-50 text-indigo-700 text-xs font-medium rounded-full">{product.category}</span>
								{/if}
								{#if product.barcode}
									<span class="px-2.5 py-1 bg-gray-100 text-gray-600 text-xs font-mono rounded-full">Barcode: {product.barcode}</span>
								{/if}
							</div>
						</div>
					</div>
				</div>

				{#if branchInventory}
					<div class="bg-indigo-50 rounded-xl border border-indigo-100 p-5">
						<h3 class="font-semibold text-indigo-900 mb-2 flex items-center gap-2">
							<Package class="h-4 w-4 text-indigo-500" /> Branch Inventory
						</h3>
						<div class="grid grid-cols-2 gap-4">
							<div class="bg-white p-3 rounded-lg border border-indigo-50">
								<p class="text-xs text-indigo-400 font-medium uppercase tracking-wider mb-1">Stock Balance</p>
								<p class="text-xl font-bold text-indigo-900">{branchInventory.stock_quantity}</p>
							</div>
							<div class="bg-white p-3 rounded-lg border border-indigo-50">
								<p class="text-xs text-indigo-400 font-medium uppercase tracking-wider mb-1">Product Price</p>
								<p class="text-xl font-bold text-indigo-900">₦{(branchInventory.selling_price || 0).toLocaleString()}</p>
							</div>
						</div>
					</div>
				{/if}

				<!-- Sales History -->
				<div class="bg-white rounded-xl border p-5">
					<h3 class="font-semibold text-gray-900 mb-4 flex items-center gap-2">
						<ShoppingBag class="h-4 w-4 text-indigo-500" /> Recent Sales
					</h3>
					{#if salesHistory.length === 0}
						<p class="text-sm text-gray-400 text-center py-4">No sales recorded yet</p>
					{:else}
						<div class="space-y-2">
							{#each salesHistory as item}
								<div class="flex items-center justify-between py-2 border-b last:border-0">
									<div>
										<p class="text-sm font-medium text-gray-800">{item.quantity} × ₦{parseFloat(item.unit_price).toLocaleString()}</p>
										<p class="text-xs text-gray-400">{new Date(item.sales?.created_at).toLocaleDateString()}</p>
									</div>
									<span class="text-sm font-semibold text-emerald-600">₦{parseFloat(item.total_price).toLocaleString()}</span>
								</div>
							{/each}
						</div>
					{/if}
				</div>
			</div>

			<!-- Right: Stats -->
			<div class="space-y-4">
				<div class="bg-white rounded-xl border p-5 space-y-4">
					<h3 class="font-semibold text-gray-900 text-sm uppercase tracking-wider text-gray-500">Additional Info</h3>
					<div class="space-y-3 text-sm">
						{#if product.product_type}
							<div class="flex justify-between"><span class="text-gray-500">Product Type</span><span class="font-medium text-right">{product.product_type}</span></div>
						{/if}
						{#if product.product_type === 'Drug'}
							{#if product.generic_name}
								<div class="flex justify-between"><span class="text-gray-500">Generic Name</span><span class="font-medium text-right">{product.generic_name}</span></div>
							{/if}
							{#if product.strength}
								<div class="flex justify-between"><span class="text-gray-500">Strength</span><span class="font-medium text-right">{product.strength}</span></div>
							{/if}
							{#if product.dosage_form}
								<div class="flex justify-between"><span class="text-gray-500">Dosage Form</span><span class="font-medium text-right">{product.dosage_form}</span></div>
							{/if}
						{/if}
						{#if product.sample_type}
							<div class="flex justify-between"><span class="text-gray-500">Sample Type</span><span class="font-medium text-right">{product.sample_type}</span></div>
						{/if}
						{#if product.product_type === 'Drug'}
							{#if product['product side effect'] || product.product_side_effect}
								<div class="flex justify-between flex-col gap-1"><span class="text-gray-500">Side Effects</span><span class="font-medium">{product['product side effect'] || product.product_side_effect}</span></div>
							{/if}
							{#if product.interactions}
								<div class="flex justify-between flex-col gap-1"><span class="text-gray-500">Interactions</span><span class="font-medium">{product.interactions}</span></div>
							{/if}
						{/if}
						{#if product.manufacturer}
							<div class="flex justify-between"><span class="text-gray-500">Manufacturer</span><span class="font-medium text-right">{product.manufacturer}</span></div>
						{/if}
					</div>
				</div>

				<div class="bg-white rounded-xl border p-5">
					<div class="flex items-center justify-between">
						<div>
							<p class="font-medium text-gray-900 text-sm">Product Status</p>
							<p class="text-xs text-gray-400 mt-0.5">{product.is_active ? 'Visible in POS' : 'Hidden from POS'}</p>
						</div>
						<button onclick={toggleActive} class="text-indigo-600 hover:text-indigo-700">
							{#if product.is_active}<ToggleRight class="h-8 w-8" />{:else}<ToggleLeft class="h-8 w-8 text-gray-400" />{/if}
						</button>
					</div>
				</div>
			</div>
		</div>
	{/if}
</div>
