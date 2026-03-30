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
	let productTypeFilter = $state('all');
	let categories = $state<string[]>([]);
	let tenantId = $state('');
	let userBranchId = $state('');
	let page = $state(1);
	let selectedIds = $state<string[]>([]);
	const PER_PAGE = 20;

	let paginated = $derived(filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE));
	let totalPages = $derived(Math.ceil(filtered.length / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: user } = await supabase.from('users')
			.select('tenant_id, branch_id')
			.eq('id', session.user.id)
			.single();
			
		if (user?.tenant_id) { 
			tenantId = user.tenant_id; 
			userBranchId = user.branch_id || '';
			await loadProducts(); 
		}
		loading = false;
	});

	async function loadProducts() {
		if (!tenantId) return;
		const { data, error: dbErr } = await supabase.from('products')
			.select('*')
			.order('created_at', { ascending: false });
		
		if (dbErr) {
			console.error('Failed to load products:', dbErr);
			return;
		}
		
		products = (data || []).map(p => ({
			...p,
			provisioning: { qty: 0, batch: '', cost: 0, selling: 0 }
		}));
		categories = [...new Set(products.map(p => p.category).filter(Boolean))];
		applyFilter();
	}

	function applyFilter() {
		let r = products;
		if (selectedCategory !== 'all') r = r.filter(p => p.category === selectedCategory);
		if (productTypeFilter !== 'all') {
			r = r.filter(p => {
				if (productTypeFilter === 'Test') return p.product_type === 'Laboratory test';
				return p.product_type === productTypeFilter;
			});
		}
		if (searchQuery) r = r.filter(p =>
			p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
			(p.barcode && p.barcode.toLowerCase().includes(searchQuery.toLowerCase()))
		);
		filtered = r;
		page = 1;
		selectedIds = [];
	}

	async function handleAddToStock() {
		if (!userBranchId) { alert('No branch assigned to your user account.'); return; }
		if (selectedIds.length === 0) return;
		
		loading = true;
		try {
			const inserts = selectedIds.map(id => {
				const product = products.find(p => p.id === id) || {};
				return {
					tenant_id: tenantId,
					branch_id: userBranchId,
					product_id: id,
					stock_quantity: product.provisioning?.qty || 0,
					sku: product.provisioning?.batch || null,
					cost_price: product.provisioning?.cost || 0,
					unit_cost: product.provisioning?.selling || 0,
					product_type: product.product_type || null,
					barcode: product.barcode || null
				};
			});
			
			const { error: err } = await supabase.from('branch_inventory')
				.upsert(inserts, { onConflict: 'branch_id, product_id' });
				
			if (err) throw err;
			alert(`Successfully added ${selectedIds.length} products to your branch inventory.`);
			selectedIds = [];
		} catch (err: any) {
			alert(err.message || 'Failed to add products to stock');
		} finally {
			loading = false;
		}
	}

	function toggleSelectAll() {
		if (selectedIds.length === paginated.length && paginated.length > 0) {
			selectedIds = [];
		} else {
			selectedIds = paginated.map(p => p.id);
		}
	}

	function toggleSelect(id: string) {
		if (selectedIds.includes(id)) {
			selectedIds = selectedIds.filter(i => i !== id);
		} else {
			selectedIds = [...selectedIds, id];
		}
	}

	$effect(() => { searchQuery; selectedCategory; productTypeFilter; applyFilter(); });

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
		<div class="flex items-center gap-3">
			{#if selectedIds.length > 0}
				<button 
					onclick={handleAddToStock}
					class="inline-flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm shadow-lg shadow-green-100"
				>
					<Package class="h-4 w-4" /> Add {selectedIds.length} to Stock
				</button>
			{/if}
			<a href="/products/new" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm">
				<Plus class="h-4 w-4" /> Add Product
			</a>
		</div>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-xl border p-4 flex flex-wrap gap-3">
		<div class="relative flex-1 min-w-48">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input type="text" bind:value={searchQuery} placeholder="Search by name or barcode..." 
				class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-shadow text-sm" />
		</div>
		<select bind:value={selectedCategory} class="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-white">
			<option value="all">All Categories</option>
			{#each categories as cat}<option value={cat}>{cat}</option>{/each}
		</select>
		<select bind:value={productTypeFilter} class="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-white">
			<option value="all">All Types</option>
			<option value="Grocery">Grocery</option>
			<option value="Drug">Drug</option>
			<option value="Test">Test</option>
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
							<th class="px-4 py-3 text-left">
								<input 
									type="checkbox" 
									checked={selectedIds.length === paginated.length && paginated.length > 0} 
									onchange={toggleSelectAll}
									class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 w-4 h-4 cursor-pointer" 
								/>
							</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Product</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Barcode</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Stock Qty</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Batch No</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Unit Cost</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Selling</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider uppercase tracking-wider">Type/Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each paginated as product}
							<tr class="hover:bg-gray-50 transition-colors {selectedIds.includes(product.id) ? 'bg-indigo-50/30' : ''}">
								<td class="px-4 py-3">
									<input 
										type="checkbox" 
										checked={selectedIds.includes(product.id)}
										onchange={() => toggleSelect(product.id)}
										class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 w-4 h-4 cursor-pointer" 
									/>
								</td>
								<td class="px-4 py-3">
									<div class="flex items-center gap-3">
										<div class="w-10 h-10 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-xl flex items-center justify-center flex-shrink-0 overflow-hidden border border-white shadow-sm">
											{#if product.image_url}
												<img src={product.image_url} alt={product.name} class="w-full h-full object-cover" />
											{:else}
												<Package class="h-5 w-5 text-indigo-400" />
											{/if}
										</div>
										<div>
											<p class="font-semibold text-gray-900 leading-tight">{product.name}</p>
											<p class="text-xs text-gray-400 mt-0.5">{product.category || 'No Category'}</p>
										</div>
									</div>
								</td>
								<td class="px-4 py-3 text-gray-500 font-mono text-xs">{product.barcode || '–'}</td>
								<td class="px-2 py-3">
									<input type="number" bind:value={product.provisioning.qty} disabled={!selectedIds.includes(product.id)} placeholder="Qty"
										class="w-20 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-2 py-3">
									<input type="text" bind:value={product.provisioning.batch} disabled={!selectedIds.includes(product.id)} placeholder="Batch"
										class="w-24 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-2 py-3">
									<input type="number" bind:value={product.provisioning.cost} disabled={!selectedIds.includes(product.id)} placeholder="Cost"
										class="w-24 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-2 py-3">
									<input type="number" bind:value={product.provisioning.selling} disabled={!selectedIds.includes(product.id)} placeholder="Price"
										class="w-24 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-4 py-3">
									<div class="flex items-center justify-end gap-2">
										<span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider {product.product_type === 'Drug' ? 'bg-blue-100 text-blue-700' : product.product_type === 'Laboratory test' ? 'bg-purple-100 text-purple-700' : 'bg-gray-100 text-gray-600'}">
											{product.product_type || 'Retail'}
										</span>
										<a href="/products/{product.id}" class="p-2 rounded-xl hover:bg-white hover:shadow-md text-gray-400 hover:text-indigo-600 transition-all border border-transparent hover:border-gray-100"><Eye class="h-4 w-4" /></a>
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
