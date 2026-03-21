<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Search, Plus, Package, Edit, Eye, AlertTriangle, ChevronLeft, ChevronRight } from 'lucide-svelte';

	let products = $state<any[]>([]);
	let filtered = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let selectedCategory = $state('all');
	let categories = $state<string[]>([]);
	let tenantId = $state('');
	let page = $state(1);
	const PER_PAGE = 20;

	let paginated = $derived(filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE));
	let totalPages = $derived(Math.ceil(filtered.length / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) { tenantId = user.tenant_id; await loadProducts(); }
		loading = false;
	});

	async function loadProducts() {
		const { data } = await supabase.from('products').select('*').eq('tenant_id', tenantId).order('name');
		products = data || [];
		categories = [...new Set(products.map(p => p.category).filter(Boolean))];
		applyFilter();
	}

	function applyFilter() {
		let r = products;
		if (selectedCategory !== 'all') r = r.filter(p => p.category === selectedCategory);
		if (searchQuery) r = r.filter(p =>
			p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
			(p.sku && p.sku.toLowerCase().includes(searchQuery.toLowerCase()))
		);
		filtered = r;
		page = 1;
	}

	$effect(() => { searchQuery; selectedCategory; applyFilter(); });

	function stockBadge(qty: number) {
		if (qty <= 0) return 'bg-red-100 text-red-700';
		if (qty < 10) return 'bg-orange-100 text-orange-700';
		return 'bg-green-100 text-green-700';
	}
</script>

<svelte:head><title>Products – Kemani POS</title></svelte:head>

<div class="p-6 space-y-5 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Products</h1>
			<p class="text-sm text-gray-500 mt-0.5">{filtered.length} product{filtered.length !== 1 ? 's' : ''}</p>
		</div>
		<a href="/products/new" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm">
			<Plus class="h-4 w-4" /> Add Product
		</a>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-xl border p-4 flex flex-wrap gap-3">
		<div class="relative flex-1 min-w-48">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input type="text" bind:value={searchQuery} placeholder="Search by name or SKU..."
				class="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
		</div>
		<select bind:value={selectedCategory} class="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-white">
			<option value="all">All Categories</option>
			{#each categories as cat}<option value={cat}>{cat}</option>{/each}
		</select>
	</div>

	<!-- Table -->
	<div class="bg-white rounded-xl border overflow-hidden">
		{#if loading}
			<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
		{:else if paginated.length === 0}
			<div class="p-12 text-center text-gray-400">
				<Package class="h-12 w-12 mx-auto mb-3 opacity-30" />
				<p class="font-medium">No products found</p>
				<a href="/products/new" class="mt-3 inline-block text-sm text-indigo-600 hover:underline">Add your first product</a>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-sm">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Product</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">SKU</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Category</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Price</th>
							<th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">Stock</th>
							<th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each paginated as product}
							<tr class="hover:bg-gray-50 transition-colors">
								<td class="px-4 py-3">
									<div class="flex items-center gap-3">
										<div class="w-9 h-9 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-lg flex items-center justify-center flex-shrink-0">
											{#if product.image_url}
												<img src={product.image_url} alt={product.name} class="w-9 h-9 object-cover rounded-lg" />
											{:else}
												<Package class="h-4 w-4 text-indigo-400" />
											{/if}
										</div>
										<div>
											<p class="font-medium text-gray-900">{product.name}</p>
											{#if product.description}
												<p class="text-xs text-gray-400 truncate max-w-32">{product.description}</p>
											{/if}
										</div>
									</div>
								</td>
								<td class="px-4 py-3 text-gray-500 font-mono text-xs">{product.sku || '–'}</td>
								<td class="px-4 py-3 text-gray-600">{product.category || '–'}</td>
								<td class="px-4 py-3 text-right font-semibold text-gray-900">₦{parseFloat(product.price).toLocaleString()}</td>
								<td class="px-4 py-3 text-center">
									<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium {stockBadge(product.stock_quantity)}">
										{#if product.stock_quantity < 10}<AlertTriangle class="h-3 w-3" />{/if}
										{product.stock_quantity}
									</span>
								</td>
								<td class="px-4 py-3 text-center">
									<span class="px-2 py-0.5 rounded-full text-xs font-medium {product.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}">
										{product.is_active ? 'Active' : 'Inactive'}
									</span>
								</td>
								<td class="px-4 py-3">
									<div class="flex items-center justify-end gap-1">
										<a href="/products/{product.id}" class="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"><Eye class="h-4 w-4" /></a>
										<a href="/products/{product.id}/edit" class="p-1.5 rounded-lg hover:bg-indigo-50 text-gray-400 hover:text-indigo-600 transition-colors"><Edit class="h-4 w-4" /></a>
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Pagination -->
			{#if totalPages > 1}
				<div class="px-4 py-3 border-t flex items-center justify-between text-sm text-gray-600">
					<span>Showing {(page-1)*PER_PAGE+1}–{Math.min(page*PER_PAGE, filtered.length)} of {filtered.length}</span>
					<div class="flex gap-1">
						<button onclick={() => page--} disabled={page === 1} class="p-1.5 rounded hover:bg-gray-100 disabled:opacity-40"><ChevronLeft class="h-4 w-4" /></button>
						<button onclick={() => page++} disabled={page === totalPages} class="p-1.5 rounded hover:bg-gray-100 disabled:opacity-40"><ChevronRight class="h-4 w-4" /></button>
					</div>
				</div>
			{/if}
		{/if}
	</div>
</div>
