<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { TrendingUp, ShoppingCart, Users, Package, ArrowUp, ArrowDown } from 'lucide-svelte';

	let loading = $state(true);
	let tenantId = $state('');
	let period = $state<'7d' | '30d' | '90d'>('30d');
	let stats = $state({ revenue: 0, orders: 0, avgOrder: 0, topProducts: [] as any[], recentSales: [] as any[], dailySales: [] as any[] });

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) { tenantId = user.tenant_id; await loadStats(); }
		loading = false;
	});

	async function loadStats() {
		const days = period === '7d' ? 7 : period === '30d' ? 30 : 90;
		const since = new Date(Date.now() - days * 86400000).toISOString();

		const { data: sales } = await supabase.from('sales')
			.select('*').eq('tenant_id', tenantId).gte('created_at', since).eq('status', 'completed');

		const revenue = (sales || []).reduce((s, o) => s + parseFloat(o.total_amount), 0);
		const orders = (sales || []).length;
		const avgOrder = orders > 0 ? revenue / orders : 0;

		// Daily sales for chart
		const dailyMap: Record<string, number> = {};
		(sales || []).forEach(s => {
			const d = s.created_at.split('T')[0];
			dailyMap[d] = (dailyMap[d] || 0) + parseFloat(s.total_amount);
		});
		const dailySales = Object.entries(dailyMap).sort().map(([date, amount]) => ({ date, amount }));

		// Top products — query sale_items directly using the tenant index
		const { data: topItems } = await supabase.from('sale_items')
			.select('product_name, quantity, subtotal')
			.eq('tenant_id', tenantId)
			.gte('created_at', since);

		const productMap: Record<string, { qty: number; revenue: number }> = {};
		(topItems || []).forEach(i => {
			if (!productMap[i.product_name]) productMap[i.product_name] = { qty: 0, revenue: 0 };
			productMap[i.product_name].qty += i.quantity;
			productMap[i.product_name].revenue += parseFloat(i.subtotal);
		});
		const topProducts = Object.entries(productMap)
			.map(([name, d]) => ({ name, ...d }))
			.sort((a, b) => b.revenue - a.revenue)
			.slice(0, 5);

		stats = { revenue, orders, avgOrder, topProducts, recentSales: (sales || []).slice(0, 5), dailySales };
	}

	$effect(() => { period; if (tenantId) loadStats(); });

	const maxDailyRevenue = $derived(Math.max(...stats.dailySales.map(d => d.amount), 1));
</script>

<svelte:head><title>Analytics – Kemani POS</title></svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Analytics</h1>
			<p class="text-sm text-gray-500 mt-0.5">Business performance overview</p>
		</div>
		<div class="flex bg-gray-100 rounded-xl p-1 gap-1">
			{#each [['7d', 'Last 7 days'], ['30d', 'Last 30 days'], ['90d', 'Last 90 days']] as [val, label]}
				<button onclick={() => period = val as any}
					class="px-3 py-1.5 text-sm rounded-lg font-medium transition-colors {period === val ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'}">
					{label}
				</button>
			{/each}
		</div>
	</div>

	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else}
		<!-- KPI Cards -->
		<div class="grid grid-cols-1 sm:grid-cols-3 gap-5">
			<div class="bg-white rounded-xl border p-5">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm text-gray-500 font-medium">Total Revenue</p>
						<p class="text-3xl font-bold text-gray-900 mt-1">₦{stats.revenue.toLocaleString('en-NG', { minimumFractionDigits: 0 })}</p>
					</div>
					<div class="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center">
						<TrendingUp class="h-6 w-6 text-indigo-600" />
					</div>
				</div>
			</div>
			<div class="bg-white rounded-xl border p-5">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm text-gray-500 font-medium">Total Orders</p>
						<p class="text-3xl font-bold text-gray-900 mt-1">{stats.orders}</p>
					</div>
					<div class="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
						<ShoppingCart class="h-6 w-6 text-emerald-600" />
					</div>
				</div>
			</div>
			<div class="bg-white rounded-xl border p-5">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm text-gray-500 font-medium">Avg. Order Value</p>
						<p class="text-3xl font-bold text-gray-900 mt-1">₦{stats.avgOrder.toLocaleString('en-NG', { minimumFractionDigits: 0 })}</p>
					</div>
					<div class="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
						<Package class="h-6 w-6 text-purple-600" />
					</div>
				</div>
			</div>
		</div>

		<!-- Revenue Chart -->
		{#if stats.dailySales.length > 0}
			<div class="bg-white rounded-xl border p-5">
				<h3 class="font-semibold text-gray-900 mb-4">Revenue Over Time</h3>
				<div class="h-48 flex items-end gap-1 overflow-x-auto">
					{#each stats.dailySales as day}
						<div class="flex flex-col items-center gap-1 flex-1 min-w-6">
							<div class="relative group flex flex-col items-center w-full">
								<div class="absolute bottom-full mb-1 bg-gray-900 text-white text-xs rounded px-1.5 py-0.5 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none">
									₦{day.amount.toLocaleString()}
								</div>
								<div
									class="w-full bg-indigo-500 hover:bg-indigo-600 rounded-t-md transition-colors cursor-pointer"
									style="height: {Math.max(4, (day.amount / maxDailyRevenue) * 160)}px"
								></div>
							</div>
							<p class="text-xs text-gray-400 whitespace-nowrap">{new Date(day.date).toLocaleDateString('en', { month: 'short', day: 'numeric' })}</p>
						</div>
					{/each}
				</div>
			</div>
		{:else}
			<div class="bg-white rounded-xl border p-8 text-center text-gray-400">
				<TrendingUp class="h-10 w-10 mx-auto mb-2 opacity-30" />
				<p>No sales data for this period</p>
			</div>
		{/if}

		<!-- Top Products + Recent Sales -->
		<div class="grid grid-cols-1 md:grid-cols-2 gap-5">
			<div class="bg-white rounded-xl border p-5">
				<h3 class="font-semibold text-gray-900 mb-4">Top Products</h3>
				{#if stats.topProducts.length === 0}
					<p class="text-sm text-gray-400 text-center py-4">No data available</p>
				{:else}
					<div class="space-y-3">
						{#each stats.topProducts as product, i}
							<div class="flex items-center gap-3">
								<span class="w-6 h-6 rounded-full bg-indigo-100 text-indigo-700 text-xs font-bold flex items-center justify-center flex-shrink-0">{i + 1}</span>
								<div class="flex-1 min-w-0">
									<p class="text-sm font-medium text-gray-800 truncate">{product.name}</p>
									<div class="w-full bg-gray-100 rounded-full h-1.5 mt-1">
										<div class="bg-indigo-500 h-1.5 rounded-full" style="width: {(product.revenue / stats.topProducts[0].revenue) * 100}%"></div>
									</div>
								</div>
								<div class="text-right flex-shrink-0">
									<p class="text-xs font-semibold text-gray-900">₦{product.revenue.toLocaleString()}</p>
									<p class="text-xs text-gray-400">{product.qty} sold</p>
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>

			<div class="bg-white rounded-xl border p-5">
				<h3 class="font-semibold text-gray-900 mb-4">Recent Sales</h3>
				{#if stats.recentSales.length === 0}
					<p class="text-sm text-gray-400 text-center py-4">No recent sales</p>
				{:else}
					<div class="space-y-2">
						{#each stats.recentSales as sale}
							<a href="/orders/{sale.id}" class="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-gray-50 transition-colors">
								<div>
									<p class="text-sm font-medium text-gray-800">{sale.customer_name || 'Walk-in'}</p>
									<p class="text-xs text-gray-400">{new Date(sale.created_at).toLocaleString()}</p>
								</div>
								<span class="text-sm font-bold text-emerald-600">₦{parseFloat(sale.total_amount).toLocaleString()}</span>
							</a>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	{/if}
</div>
