<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Search, RotateCcw, Building, FileText, ChevronRight, Ban } from 'lucide-svelte';

	let sales = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let currentTenantId = $state('');
	let branchId = $state('');
	
	let filtered = $derived(
		sales.filter(s => 
			s.sale_number?.toLowerCase().includes(searchQuery.toLowerCase()) || 
			s.customer_name?.toLowerCase().includes(searchQuery.toLowerCase())
		)
	);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: user } = await supabase.from('users')
			.select('tenant_id, branch_id')
			.eq('id', session.user.id)
			.single();
			
		if (user) {
			currentTenantId = user.tenant_id;
			branchId = user.branch_id || '';
			await loadSales();
		}
	});

	async function loadSales() {
		loading = true;
		try {
			const { data, error } = await supabase.from('sales')
				.select('*, users:cashier_id(full_name)')
				.eq('tenant_id', currentTenantId)
				.eq('branch_id', branchId)
				.order('created_at', { ascending: false })
				.limit(100);
				
			if (error) throw error;
			sales = data || [];
		} catch (err) {
			console.error('Failed to load sales:', err);
		} finally {
			loading = false;
		}
	}

	function formatCurrency(val: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}
</script>

<svelte:head>
	<title>Process Returns</title>
</svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-black text-gray-900 flex items-center gap-2">
				<RotateCcw class="h-6 w-6 text-indigo-600" />
				Returns Processing
			</h1>
			<p class="text-sm text-gray-500 font-medium mt-1">Locate a transaction receipt to modify or completely return</p>
		</div>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm flex items-center gap-4">
		<div class="relative flex-1">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input 
				type="text" 
				bind:value={searchQuery}
				placeholder="Search by receipt code (e.g. ORD-12345) or customer name..."
				class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all outline-none font-medium text-sm"
			/>
		</div>
	</div>

	<!-- Sales History Table -->
	<div class="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
		{#if loading}
			<div class="flex flex-col items-center justify-center p-20 text-gray-400">
				<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mb-4"></div>
				<p class="font-medium italic">Loading transaction history...</p>
			</div>
		{:else if filtered.length === 0}
			<div class="flex flex-col items-center justify-center p-20 text-gray-500 text-center">
				<div class="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
					<FileText class="h-8 w-8 text-gray-300" />
				</div>
				<p class="text-lg font-black text-gray-900">No Transactions Found</p>
				<p class="text-sm max-w-sm mt-1">Adjust your search or check if transactions exist for this branch.</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left whitespace-nowrap">
					<thead class="bg-gray-50">
						<tr>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Sale Information</th>
							<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Date & Time</th>
							<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Operator</th>
							<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Total Amount</th>
							<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-right">Status</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-50">
						{#each filtered as sale}
							<tr class="hover:bg-indigo-50/30 transition-colors group">
								<td class="px-6 py-4">
									<div class="flex items-center gap-3">
										<div class="h-10 w-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-600 font-black">
											<FileText class="h-4 w-4" />
										</div>
										<div>
											<a href="/returns/{sale.id}" class="font-bold text-indigo-600 hover:text-indigo-800 hover:underline">{sale.sale_number}</a>
											<p class="text-[10px] text-gray-500 font-bold uppercase mt-0.5">{sale.customer_name || 'Walk-In Customer'}</p>
										</div>
									</div>
								</td>
								<td class="px-4 py-4">
									<p class="text-sm font-bold text-gray-900">{new Date(sale.created_at).toLocaleDateString()}</p>
									<p class="text-[10px] text-gray-400 font-medium uppercase mt-0.5">{new Date(sale.created_at).toLocaleTimeString()}</p>
								</td>
								<td class="px-4 py-4 text-sm font-black text-gray-700">
									{sale.users?.full_name || 'System'}
								</td>
								<td class="px-4 py-4 text-sm font-black text-gray-900">
									{formatCurrency(sale.total_amount)}
								</td>
								<td class="px-6 py-4 text-right">
									{#if sale.sale_status === 'refunded'}
										<span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-black bg-rose-50 text-rose-600 uppercase">
											<Ban class="h-3 w-3" /> Refunded
										</span>
									{:else if sale.sale_status === 'voided'}
										<span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-black bg-gray-100 text-gray-600 uppercase">
											<Ban class="h-3 w-3" /> Voided
										</span>
									{:else}
										<div class="flex flex-col items-end gap-1">
											<span class="inline-flex px-2.5 py-1 rounded-md text-xs font-black bg-emerald-50 text-emerald-600 uppercase">
												Completed
											</span>
											<a href="/returns/{sale.id}" class="text-[10px] font-black text-indigo-500 hover:text-indigo-700 uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1">
												View Items <ChevronRight class="h-3 w-3" />
											</a>
										</div>
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</div>
</div>
