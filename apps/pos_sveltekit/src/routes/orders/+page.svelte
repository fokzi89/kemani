<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { ShoppingBag, Search, ChevronLeft, ChevronRight, Eye } from 'lucide-svelte';

	let orders = $state<any[]>([]);
	let filtered = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let statusFilter = $state('all');
	let page = $state(1);
	const PER_PAGE = 20;

	let paginated = $derived(filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE));
	let totalPages = $derived(Math.ceil(filtered.length / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) {
			const { data } = await supabase.from('sales')
				.select('*')
				.eq('tenant_id', user.tenant_id)
				.order('created_at', { ascending: false });
			orders = data || [];
			filtered = orders;
		}
		loading = false;
	});

	function applyFilter() {
		let r = orders;
		if (statusFilter !== 'all') r = r.filter(o => o.status === statusFilter);
		if (searchQuery) r = r.filter(o =>
			o.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
			(o.customer_name && o.customer_name.toLowerCase().includes(searchQuery.toLowerCase()))
		);
		filtered = r;
		page = 1;
	}

	$effect(() => { searchQuery; statusFilter; applyFilter(); });

	function statusColor(status: string) {
		switch (status) {
			case 'completed': return 'bg-green-100 text-green-700';
			case 'pending': return 'bg-yellow-100 text-yellow-700';
			case 'cancelled': return 'bg-red-100 text-red-700';
			default: return 'bg-gray-100 text-gray-600';
		}
	}

	function paymentBadge(method: string) {
		switch (method) {
			case 'cash': return 'bg-emerald-50 text-emerald-700';
			case 'card': return 'bg-blue-50 text-blue-700';
			case 'transfer': return 'bg-purple-50 text-purple-700';
			default: return 'bg-gray-50 text-gray-600';
		}
	}
</script>

<svelte:head><title>Orders – Kemani POS</title></svelte:head>

<div class="p-6 space-y-5 max-w-7xl mx-auto">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Sales & Orders</h1>
			<p class="text-sm text-gray-500 mt-0.5">{filtered.length} transaction{filtered.length !== 1 ? 's' : ''}</p>
		</div>
		<a href="/pos" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm">
			New Sale
		</a>
	</div>

	<div class="bg-white rounded-xl border p-4 flex flex-wrap gap-3">
		<div class="relative flex-1 min-w-48">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input type="text" bind:value={searchQuery} placeholder="Search by ID or customer..."
				class="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
		</div>
		<select bind:value={statusFilter} class="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-white">
			<option value="all">All Status</option>
			<option value="completed">Completed</option>
			<option value="pending">Pending</option>
			<option value="cancelled">Cancelled</option>
		</select>
	</div>

	<div class="bg-white rounded-xl border overflow-hidden">
		{#if loading}
			<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
		{:else if paginated.length === 0}
			<div class="p-12 text-center text-gray-400">
				<ShoppingBag class="h-12 w-12 mx-auto mb-3 opacity-30" />
				<p class="font-medium">No orders found</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-sm">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Order ID</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Customer</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Date</th>
							<th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">Payment</th>
							<th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Total</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Action</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each paginated as order}
							<tr class="hover:bg-gray-50 transition-colors">
								<td class="px-4 py-3 font-mono text-xs text-gray-600">#{order.id?.slice(-8).toUpperCase()}</td>
								<td class="px-4 py-3 font-medium text-gray-800">{order.customer_name || 'Walk-in'}</td>
								<td class="px-4 py-3 text-gray-500">{new Date(order.created_at).toLocaleDateString()} <span class="text-xs">{new Date(order.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span></td>
								<td class="px-4 py-3 text-center">
									<span class="px-2 py-0.5 rounded-full text-xs font-medium capitalize {paymentBadge(order.payment_method)}">{order.payment_method}</span>
								</td>
								<td class="px-4 py-3 text-center">
									<span class="px-2 py-0.5 rounded-full text-xs font-medium capitalize {statusColor(order.status)}">{order.status}</span>
								</td>
								<td class="px-4 py-3 text-right font-bold text-gray-900">₦{parseFloat(order.total_amount).toLocaleString()}</td>
								<td class="px-4 py-3 text-right">
									<a href="/orders/{order.id}" class="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors inline-flex"><Eye class="h-4 w-4" /></a>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

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
