<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Package, ArrowLeft, Building, 
		AlertCircle, Loader2, ChevronLeft, 
		ChevronRight, Search
	} from 'lucide-svelte';

	let inventory = $state<any[]>([]);
	let branches = $state<any[]>([]);
	let totalCount = $state(0);
	let loading = $state(true);
	let selectedBranchId = $state('all');
	let searchQuery = $state('');
	let currentTenantId = $state('');

	// Pagination
	let page = $state(1);
	const PER_PAGE = 20;
	let totalPages = $derived(Math.ceil(totalCount / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: user } = await supabase.from('users')
			.select('tenant_id, branch_id')
			.eq('id', session.user.id)
			.single();
			
		if (user) {
			currentTenantId = user.tenant_id;
			selectedBranchId = user.branch_id || 'all';
			await loadBranches();
			await loadLowStock();
		}
	});

	async function loadBranches() {
		const { data } = await supabase.from('branches')
			.select('id, name')
			.eq('tenant_id', currentTenantId);
		branches = data || [];
	}

	async function loadLowStock() {
		if (!currentTenantId) return;
		loading = true;
		try {
			let query = supabase
				.from('branch_inventory')
				.select('*', { count: 'exact' })
				.eq('tenant_id', currentTenantId)
				.filter('stock_quantity', 'lte', 'low_stock_threshold');

			if (selectedBranchId !== 'all') {
				query = query.eq('branch_id', selectedBranchId);
			}

			if (searchQuery) {
				query = query.ilike('product_name', `%${searchQuery}%`);
			}

			const { data, count, error } = await query
				.order('stock_quantity', { ascending: true })
				.range((page - 1) * PER_PAGE, page * PER_PAGE - 1);

			if (error) throw error;
			inventory = data || [];
			totalCount = count || 0;
		} catch (err) {
			console.error('Low stock fetch error:', err);
		} finally {
			loading = false;
		}
	}

	$effect(() => {
		if (currentTenantId && (selectedBranchId || page || searchQuery)) {
			loadLowStock();
		}
	});

	function formatCurrency(val: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}
</script>

<svelte:head><title>Low Stock Alerts – Kemani POS</title></svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div class="flex items-center gap-4">
			<a href="/inventory" class="p-2 hover:bg-gray-100 rounded-xl transition-colors text-gray-500">
				<ArrowLeft class="h-6 w-6" />
			</a>
			<div>
				<h1 class="text-xl font-bold text-gray-900 flex items-center gap-2">
					<AlertCircle class="h-5 w-5 text-rose-500" />
					Low Stock Alerts
				</h1>
				<p class="text-sm text-gray-500 mt-0.5">{totalCount} items requiring replenishment</p>
			</div>
		</div>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-2xl border border-gray-100 p-4 flex flex-wrap gap-4 shadow-sm">
		<div class="relative flex-1 min-w-[300px]">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input 
				type="text" 
				bind:value={searchQuery}
				placeholder="Search low stock items..."
				class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition-all outline-none text-sm"
			/>
		</div>

		<div class="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-xl px-3 py-1">
			<Building class="h-4 w-4 text-gray-400" />
			<select 
				bind:value={selectedBranchId}
				class="bg-transparent border-none focus:ring-0 text-sm font-bold text-gray-700 outline-none cursor-pointer py-1.5"
			>
				<option value="all">All Branches</option>
				{#each branches as branch}
					<option value={branch.id}>{branch.name}</option>
				{/each}
			</select>
		</div>
	</div>

	<!-- Table Content -->
	<div class="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
		{#if loading}
			<div class="flex flex-col items-center justify-center py-32 text-gray-400 italic">
				<Loader2 class="h-10 w-10 animate-spin mb-4 text-rose-600" />
				<p>Analyzing inventory levels...</p>
			</div>
		{:else if inventory.length > 0}
			<div class="overflow-x-auto">
				<table class="w-full text-left whitespace-nowrap">
					<thead class="bg-gray-50/50">
						<tr>
							<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Product</th>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Branch</th>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-center">Current Stock</th>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-center">Threshold</th>
							<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-right">Status</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-50">
						{#each inventory as item}
							<tr class="hover:bg-rose-50/30 transition-colors group">
								<td class="px-8 py-5">
									<div class="flex items-center gap-4">
										<div class="h-12 w-12 bg-gray-50 rounded-xl flex items-center justify-center text-gray-400 border border-gray-100 overflow-hidden group-hover:border-rose-200 transition-colors">
											{#if item.image_url}
												<img src={item.image_url} alt={item.product_name} class="h-full w-full object-cover" />
											{:else}
												<Package class="h-5 w-5" />
											{/if}
										</div>
										<div>
											<p class="text-sm font-black text-gray-900 leading-none">{item.product_name}</p>
											<p class="text-[10px] text-gray-400 font-bold uppercase mt-1.5">{item.sku || 'NO SKU'}</p>
										</div>
									</div>
								</td>
								<td class="px-6 py-5">
									<span class="text-xs font-bold text-gray-600 bg-gray-100 px-2 py-1 rounded-lg">
										{branches.find(b => b.id === item.branch_id)?.name || 'Branch'}
									</span>
								</td>
								<td class="px-6 py-5 text-center">
									<span class="text-lg font-black text-rose-600">{item.stock_quantity}</span>
									<span class="text-[10px] text-gray-400 font-bold ml-1 uppercase">{item.unit_of_measure || 'Units'}</span>
								</td>
								<td class="px-6 py-5 text-center">
									<span class="text-sm font-bold text-gray-400">{item.low_stock_threshold}</span>
								</td>
								<td class="px-8 py-5 text-right">
									{#if item.stock_quantity === 0}
										<span class="bg-rose-600 text-white text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-widest shadow-lg shadow-rose-200">Out of Stock</span>
									{:else}
										<span class="bg-rose-100 text-rose-700 text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-widest">Critical Low</span>
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Pagination -->
			{#if totalPages > 1}
				<div class="px-8 py-5 border-t border-gray-50 flex items-center justify-between bg-gray-50/30">
					<p class="text-xs font-bold text-gray-500 uppercase tracking-widest">Page {page} of {totalPages}</p>
					<div class="flex items-center gap-2">
						<button 
							disabled={page === 1}
							onclick={() => page--}
							class="p-2 rounded-xl border border-gray-200 bg-white text-gray-600 disabled:opacity-30 hover:bg-gray-50 transition-all"
						>
							<ChevronLeft class="h-4 w-4" />
						</button>
						<button 
							disabled={page === totalPages}
							onclick={() => page++}
							class="p-2 rounded-xl border border-gray-200 bg-white text-gray-600 disabled:opacity-30 hover:bg-gray-50 transition-all"
						>
							<ChevronRight class="h-4 w-4" />
						</button>
					</div>
				</div>
			{/if}
		{:else}
			<div class="flex flex-col items-center justify-center py-32 text-center">
				<div class="h-20 w-20 bg-emerald-50 rounded-full flex items-center justify-center text-emerald-600 mb-6 border-4 border-emerald-100">
					<Check class="h-10 w-10" />
				</div>
				<h3 class="text-xl font-black text-gray-900">Inventory Healthy</h3>
				<p class="text-gray-500 text-sm mt-2 max-w-xs">All products in this branch are currently above their minimum stock thresholds.</p>
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) { background-color: #f8fafc; }
</style>
