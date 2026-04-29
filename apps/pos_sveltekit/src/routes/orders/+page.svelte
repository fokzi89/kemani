<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		ShoppingBag, Search, ChevronLeft, ChevronRight, Eye, 
		Calendar, Clock, Monitor, Smartphone, Store,
		Filter, Download, ArrowUpRight
	} from 'lucide-svelte';
	import { goto } from '$app/navigation';

	let orders = $state<any[]>([]);
	let filtered = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let statusFilter = $state('all');
	let page = $state(1);
	const PER_PAGE = 15;

	let paginated = $derived(filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE));
	let totalPages = $derived(Math.ceil(filtered.length / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: userProfile } = await supabase
			.from('users')
			.select('tenant_id')
			.eq('id', session.user.id)
			.single();
			
		if (userProfile?.tenant_id) {
			const { data, error } = await supabase.from('sales')
				.select(`
					*,
					customer:customers(full_name),
					cashier:users!sales_cashier_id_fkey(full_name)
				`)
				.eq('tenant_id', userProfile.tenant_id)
				.order('created_at', { ascending: false });
				
			if (error) console.error('Error fetching sales:', error);
			orders = data || [];
			filtered = orders;
		}
		loading = false;
	});

	function applyFilter() {
		let r = orders;
		if (statusFilter !== 'all') r = r.filter(o => o.sale_status === statusFilter);
		if (searchQuery) {
			const q = searchQuery.toLowerCase();
			r = r.filter(o =>
				o.sale_number?.toLowerCase().includes(q) ||
				o.customer_name?.toLowerCase().includes(q) ||
				o.customer?.full_name?.toLowerCase().includes(q)
			);
		}
		filtered = r;
		page = 1;
	}

	$effect(() => { searchQuery; statusFilter; applyFilter(); });

	function statusBadge(status: string) {
		switch (status) {
			case 'completed': return 'bg-emerald-50 text-emerald-700 ring-emerald-600/20';
			case 'pending': return 'bg-amber-50 text-amber-700 ring-amber-600/20';
			case 'cancelled': return 'bg-rose-50 text-rose-700 ring-rose-600/20';
			case 'refunded': return 'bg-indigo-50 text-indigo-700 ring-indigo-600/20';
			default: return 'bg-slate-50 text-slate-700 ring-slate-600/20';
		}
	}

	function channelIcon(channel: string) {
		switch (channel?.toLowerCase()) {
			case 'storefront':
			case 'online': return Monitor;
			case 'mobile': return Smartphone;
			default: return Store;
		}
	}

	function fmtDate(d: string) {
		return new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
	}
	
	function fmtTime(d: string) {
		return new Date(d).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
	}

	function fmtCurrency(n: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(n);
	}
</script>

<svelte:head><title>Orders & Sales – Kemani POS</title></svelte:head>

<div class="p-4 md:p-8 space-y-8 max-w-[1600px] mx-auto min-h-screen bg-slate-50/50">
	<!-- Header -->
	<div class="flex flex-col md:flex-row md:items-end justify-between gap-4">
		<div class="space-y-1">
			<div class="flex items-center gap-2 text-slate-500 text-sm font-medium">
				<ShoppingBag class="h-4 w-4" />
				<span>Sales Management</span>
			</div>
			<h1 class="text-2xl font-bold text-slate-900 tracking-tight">Orders & Transactions</h1>
			<p class="text-slate-500 font-medium">{filtered.length} total records found</p>
		</div>
		<div class="flex items-center gap-3">
			<button class="inline-flex items-center gap-2 bg-white border border-slate-200 px-4 py-2.5 rounded-xl text-sm font-bold text-slate-700 hover:bg-slate-50 transition-all shadow-sm">
				<Download class="h-4 w-4" /> Export CSV
			</button>
			<a href="/pos" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-6 py-2.5 rounded-xl transition-all shadow-lg shadow-indigo-200 hover:-translate-y-0.5 active:translate-y-0">
				New Sale <ArrowUpRight class="h-4 w-4" />
			</a>
		</div>
	</div>

	<!-- Filters -->
	<div class="grid grid-cols-1 md:grid-cols-4 gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
		<div class="md:col-span-2 relative">
			<Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
			<input 
				type="text" 
				bind:value={searchQuery} 
				placeholder="Search by sale number, customer name..."
				class="w-full pl-10 pr-4 py-3 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-indigo-500 text-sm font-medium" 
			/>
		</div>
		<div class="relative">
			<Filter class="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
			<select 
				bind:value={statusFilter} 
				class="w-full pl-10 pr-4 py-3 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-indigo-500 text-sm font-medium appearance-none cursor-pointer"
			>
				<option value="all">All Statuses</option>
				<option value="completed">Completed</option>
				<option value="pending">Pending</option>
				<option value="cancelled">Cancelled</option>
				<option value="refunded">Refunded</option>
			</select>
		</div>
		<div class="flex items-center justify-end">
			<button onclick={() => { searchQuery = ''; statusFilter = 'all'; }} class="text-sm font-bold text-indigo-600 hover:text-indigo-700 px-4">
				Reset Filters
			</button>
		</div>
	</div>

	<!-- Table Content -->
	<div class="bg-white rounded-3xl border border-slate-200 shadow-xl overflow-hidden">
		{#if loading}
			<div class="py-32 flex flex-col items-center justify-center gap-4">
				<div class="relative h-12 w-12">
					<div class="absolute inset-0 rounded-full border-4 border-slate-100"></div>
					<div class="absolute inset-0 rounded-full border-4 border-indigo-600 border-t-transparent animate-spin"></div>
				</div>
				<p class="text-slate-400 font-bold text-sm uppercase tracking-widest">Loading Transactions...</p>
			</div>
		{:else if paginated.length === 0}
			<div class="py-32 flex flex-col items-center justify-center text-center px-4">
				<div class="h-20 w-20 bg-slate-50 rounded-3xl flex items-center justify-center mb-6">
					<ShoppingBag class="h-10 w-10 text-slate-200" />
				</div>
				<h3 class="text-xl font-bold text-slate-900">No matching orders</h3>
				<p class="text-slate-500 mt-2 max-w-xs mx-auto font-medium">We couldn't find any transactions matching your current filters. Try adjusting your search.</p>
				<button onclick={() => { searchQuery = ''; statusFilter = 'all'; }} class="mt-8 text-indigo-600 font-bold text-sm uppercase tracking-widest hover:underline">
					Clear all filters
				</button>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full border-collapse">
					<thead>
						<tr class="bg-slate-50/50 border-b border-slate-100">
							<th class="px-6 py-5 text-left text-[11px] font-bold text-slate-400 uppercase tracking-[0.15em]">Transaction</th>
							<th class="px-6 py-5 text-left text-[11px] font-bold text-slate-400 uppercase tracking-[0.15em]">Customer</th>
							<th class="px-6 py-5 text-left text-[11px] font-bold text-slate-400 uppercase tracking-[0.15em]">Date & Time</th>
							<th class="px-6 py-5 text-center text-[11px] font-bold text-slate-400 uppercase tracking-[0.15em]">Channel</th>
							<th class="px-6 py-5 text-center text-[11px] font-bold text-slate-400 uppercase tracking-[0.15em]">Status</th>
							<th class="px-6 py-5 text-right text-[11px] font-bold text-slate-400 uppercase tracking-[0.15em]">Amount</th>
							<th class="px-6 py-5 text-right text-[11px] font-bold text-slate-400 uppercase tracking-[0.15em]"></th>
						</tr>
					</thead>
					<tbody class="divide-y divide-slate-50">
						{#each paginated as order}
							{@const Icon = channelIcon(order.channel)}
							<tr class="group hover:bg-slate-50/80 transition-all cursor-pointer" onclick={() => goto(`/orders/${order.id}`)}>
								<td class="px-6 py-5">
									<div class="flex flex-col">
										<span class="text-sm font-bold text-slate-900 group-hover:text-indigo-600 transition-colors">
											{order.sale_number || `#${order.id?.slice(-8).toUpperCase()}`}
										</span>
										<span class="text-[10px] font-bold text-slate-400 uppercase mt-0.5">
											{order.sale_type || 'Retail Sale'}
										</span>
									</div>
								</td>
								<td class="px-6 py-5">
									<div class="flex items-center gap-3">
										<div class="h-9 w-9 rounded-xl bg-slate-100 flex items-center justify-center text-slate-500 font-bold text-xs">
											{(order.customer_name || order.customer?.full_name || 'W')[0].toUpperCase()}
										</div>
										<div class="flex flex-col">
											<span class="text-sm font-bold text-slate-700">
												{order.customer_name || order.customer?.full_name || 'Walk-in Customer'}
											</span>
											<span class="text-[10px] font-bold text-slate-400 uppercase">
												{order.customer_type || 'Retail'}
											</span>
										</div>
									</div>
								</td>
								<td class="px-6 py-5">
									<div class="flex flex-col gap-1">
										<div class="flex items-center gap-1.5 text-slate-600 text-xs font-bold">
											<Calendar class="h-3 w-3 text-slate-300" />
											{fmtDate(order.created_at)}
										</div>
										<div class="flex items-center gap-1.5 text-slate-400 text-[11px] font-medium">
											<Clock class="h-3 w-3 text-slate-200" />
											{fmtTime(order.created_at)}
										</div>
									</div>
								</td>
								<td class="px-6 py-5 text-center">
									<div class="inline-flex items-center justify-center h-10 w-10 rounded-2xl bg-slate-50 text-slate-400 group-hover:bg-white group-hover:text-indigo-600 group-hover:shadow-sm transition-all">
										<Icon class="h-5 w-5" />
									</div>
								</td>
								<td class="px-6 py-5 text-center">
									<span class="inline-flex items-center px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest ring-1 ring-inset {statusBadge(order.sale_status)}">
										{order.sale_status}
									</span>
								</td>
								<td class="px-6 py-5 text-right">
									<span class="text-base font-bold text-slate-900 tabular-nums">
										{fmtCurrency(order.total_amount)}
									</span>
								</td>
								<td class="px-6 py-5 text-right">
									<div class="flex justify-end opacity-0 group-hover:opacity-100 transition-opacity">
										<div class="h-10 w-10 rounded-xl bg-white border border-slate-200 flex items-center justify-center text-slate-400 hover:text-indigo-600 hover:border-indigo-100 shadow-sm transition-all">
											<Eye class="h-5 w-5" />
										</div>
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Pagination -->
			{#if totalPages > 1}
				<div class="px-6 py-5 border-t border-slate-100 flex items-center justify-between bg-slate-50/30">
					<p class="text-xs font-bold text-slate-400 uppercase tracking-widest">
						Showing <span class="text-slate-900">{(page-1)*PER_PAGE+1}–{Math.min(page*PER_PAGE, filtered.length)}</span> of <span class="text-slate-900">{filtered.length}</span> transactions
					</p>
					<div class="flex items-center gap-2">
						<button 
							onclick={() => page--} 
							disabled={page === 1} 
							class="h-10 w-10 rounded-xl border border-slate-200 flex items-center justify-center text-slate-600 hover:bg-white hover:border-indigo-100 hover:text-indigo-600 disabled:opacity-30 disabled:hover:bg-transparent transition-all shadow-sm"
						>
							<ChevronLeft class="h-5 w-5" />
						</button>
						
						<div class="flex items-center gap-1 px-2">
							{#each Array.from({length: Math.min(5, totalPages)}, (_, i) => i + 1) as p}
								<button 
									onclick={() => page = p}
									class="h-10 w-10 rounded-xl text-sm font-bold transition-all {page === p ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-100' : 'text-slate-400 hover:text-slate-900 hover:bg-white hover:shadow-sm'}"
								>
									{p}
								</button>
							{/each}
						</div>

						<button 
							onclick={() => page++} 
							disabled={page === totalPages} 
							class="h-10 w-10 rounded-xl border border-slate-200 flex items-center justify-center text-slate-600 hover:bg-white hover:border-indigo-100 hover:text-indigo-600 disabled:opacity-30 disabled:hover:bg-transparent transition-all shadow-sm"
						>
							<ChevronRight class="h-5 w-5" />
						</button>
					</div>
				</div>
			{/if}
		{/if}
	</div>
</div>

<style>
	/* Subtle transition for table rows */
	tr { transition: background-color 0.2s ease; }
</style>
