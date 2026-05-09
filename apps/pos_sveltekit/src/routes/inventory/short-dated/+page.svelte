<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Calendar, ArrowLeft, Building, 
		Loader2, ChevronLeft, 
		ChevronRight, Search, Package,
		Clock, AlertCircle
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
			await loadShortDated();
		}
	});

	async function loadBranches() {
		const { data } = await supabase.from('branches')
			.select('id, name')
			.eq('tenant_id', currentTenantId);
		branches = data || [];
	}

	async function loadShortDated() {
		if (!currentTenantId) return;
		loading = true;
		try {
			const nineMonthsFromNow = new Date();
			nineMonthsFromNow.setMonth(nineMonthsFromNow.getMonth() + 9);
			const today = new Date().toISOString().split('T')[0];
			const limitDate = nineMonthsFromNow.toISOString().split('T')[0];

			let query = supabase
				.from('branch_inventory')
				.select('*', { count: 'exact' })
				.eq('tenant_id', currentTenantId)
				.gte('expiry_date', today)
				.lte('expiry_date', limitDate);

			if (selectedBranchId !== 'all') {
				query = query.eq('branch_id', selectedBranchId);
			}

			if (searchQuery) {
				query = query.ilike('product_name', `%${searchQuery}%`);
			}

			const { data, count, error } = await query
				.order('expiry_date', { ascending: true })
				.range((page - 1) * PER_PAGE, page * PER_PAGE - 1);

			if (error) throw error;
			
			inventory = (data || []).map(item => {
				const expiryDate = new Date(item.expiry_date);
				const now = new Date();
				const diffMs = expiryDate.getTime() - now.getTime();
				const diffMonths = diffMs / (1000 * 60 * 60 * 24 * 30.44);

				let status = { label: '', color: '', bg: '', border: '' };
				if (diffMonths < 3) {
					status = { label: 'CRITICAL (<3M)', color: 'text-rose-700', bg: 'bg-rose-100', border: 'border-rose-200' };
				} else if (diffMonths < 6) {
					status = { label: 'URGENT (3-6M)', color: 'text-orange-700', bg: 'bg-orange-100', border: 'border-orange-200' };
				} else {
					status = { label: 'SHORT DATED (6-9M)', color: 'text-amber-700', bg: 'bg-amber-100', border: 'border-amber-200' };
				}

				return { ...item, expiryStatus: status };
			});
			
			totalCount = count || 0;
		} catch (err) {
			console.error('Short dated fetch error:', err);
		} finally {
			loading = false;
		}
	}

	$effect(() => {
		if (currentTenantId && (selectedBranchId || page || searchQuery)) {
			loadShortDated();
		}
	});

</script>

<svelte:head><title>Short Dated Stock – Kemani POS</title></svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div class="flex items-center gap-4">
			<a href="/inventory" class="p-2 hover:bg-gray-100 rounded-xl transition-colors text-gray-500">
				<ArrowLeft class="h-6 w-6" />
			</a>
			<div>
				<h1 class="text-xl font-bold text-gray-900 flex items-center gap-2">
					<Clock class="h-5 w-5 text-amber-500" />
					Short Dated Stock
				</h1>
				<p class="text-sm text-gray-500 mt-0.5">{totalCount} items expiring within 9 months</p>
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
				placeholder="Search by product or batch..."
				class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-all outline-none text-sm"
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
				<Loader2 class="h-10 w-10 animate-spin mb-4 text-amber-600" />
				<p>Scanning for upcoming expirations...</p>
			</div>
		{:else if inventory.length > 0}
			<div class="overflow-x-auto">
				<table class="w-full text-left whitespace-nowrap">
					<thead class="bg-gray-50/50">
						<tr>
							<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Product & Batch</th>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Branch</th>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-center">Stock</th>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-center">Expiry Date</th>
							<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-right">Risk Level</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-50">
						{#each inventory as item}
							<tr class="hover:bg-amber-50/20 transition-colors group">
								<td class="px-8 py-5">
									<div class="flex items-center gap-4">
										<div class="h-12 w-12 bg-gray-50 rounded-xl flex items-center justify-center text-gray-400 border border-gray-100 overflow-hidden">
											{#if item.image_url}
												<img src={item.image_url} alt={item.product_name} class="h-full w-full object-cover" />
											{:else}
												<Package class="h-5 w-5" />
											{/if}
										</div>
										<div>
											<p class="text-sm font-black text-gray-900 leading-none">{item.product_name}</p>
											<div class="flex items-center gap-2 mt-1.5">
												<span class="text-[9px] font-black bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded border border-gray-200 uppercase tracking-tight">
													Batch: {item.batch_no || 'NA'}
												</span>
												<span class="text-[9px] text-gray-300">•</span>
												<span class="text-[9px] text-gray-400 font-bold uppercase">{item.sku || 'NO SKU'}</span>
											</div>
										</div>
									</div>
								</td>
								<td class="px-6 py-5">
									<span class="text-xs font-bold text-gray-600">
										{branches.find(b => b.id === item.branch_id)?.name || 'Branch'}
									</span>
								</td>
								<td class="px-6 py-5 text-center">
									<span class="text-sm font-black text-gray-900">{item.stock_quantity}</span>
									<span class="text-[10px] text-gray-400 font-bold ml-0.5 uppercase">{item.unit_of_measure || 'Units'}</span>
								</td>
								<td class="px-6 py-5 text-center">
									<div class="flex flex-col items-center">
										<span class="text-sm font-black {item.expiryStatus.color}">
											{new Date(item.expiry_date).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}
										</span>
										<span class="text-[9px] font-bold text-gray-400 uppercase tracking-tighter mt-0.5">
											({Math.floor((new Date(item.expiry_date).getTime() - Date.now()) / (1000 * 60 * 60 * 24))} days left)
										</span>
									</div>
								</td>
								<td class="px-8 py-5 text-right">
									<span class="{item.expiryStatus.bg} {item.expiryStatus.color} border {item.expiryStatus.border} text-[10px] font-black px-3 py-1.5 rounded-full uppercase tracking-widest shadow-sm">
										{item.expiryStatus.label}
									</span>
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
					<Package class="h-10 w-10" />
				</div>
				<h3 class="text-xl font-black text-gray-900">All Stock Fresh</h3>
				<p class="text-gray-500 text-sm mt-2 max-w-xs">No products found expiring within the next 9 months in the selected locations.</p>
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) { background-color: #f8fafc; }
</style>
