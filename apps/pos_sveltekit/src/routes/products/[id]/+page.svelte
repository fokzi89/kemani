<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ArrowLeft, Edit, Package, ShoppingBag, AlertTriangle, ToggleLeft, ToggleRight,
		Clock, TrendingUp, BarChart3, Truck, ClipboardList, Save, Loader2,
		Calendar, User, ShoppingCart, CheckCircle2, Info
	} from 'lucide-svelte';
	import Chart from 'chart.js/auto';

	const productId = $page.params.id;
	let loading = $state(true);
	let product = $state<any>(null);
	let batches = $state<any[]>([]);
	let salesHistory = $state<any[]>([]);
	let supplyHistory = $state<any[]>([]);
	let activeTab = $state<'overview' | 'batches' | 'supply' | 'sales' | 'analytics'>('overview');
	let chartPeriod = $state<'30d' | 'quarter' | 'year' | '5y'>('30d');
	let currentBranchId = $state<string | null>(null);
	let branchInventory = $state<any>(null);

	let chartCanvas = $state<HTMLCanvasElement | null>(null);
	let chart: Chart | null = null;

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (session) {
			const { data: user } = await supabase.from('users').select('branch_id').eq('id', session.user.id).single();
			currentBranchId = user?.branch_id;
		}
		await fetchData();
	});

	async function fetchData() {
		loading = true;
		try {
			// 1. Fetch Product Basic Info
			const { data: pData } = await supabase.from('products')
				.select('*')
				.eq('id', productId)
				.single();
			product = pData;

			if (currentBranchId) {
				// 2. Fetch Branch Specific Inventory (Batches)
				const { data: bData } = await supabase.from('branch_inventory')
					.select('*, suppliers(name)')
					.eq('product_id', productId)
					.eq('branch_id', currentBranchId)
					.order('created_at', { ascending: false });
				batches = bData || [];

				// Summary of current branch inventory
				if (batches.length > 0) {
					branchInventory = {
						stock_quantity: batches.reduce((acc, b) => acc + b.stock_quantity, 0),
						selling_price: batches[0].selling_price // Use latest batch price as representative
					};
				}
			}

			// 3. Fetch Sale History from sale_items (Tenant and Branch scoped via RLS or explicit filter)
			const { data: sData } = await supabase.from('sale_items')
				.select('*, sales!inner(created_at, payment_method, status, users:cashier_id(full_name))')
				.eq('product_id', productId)
				.order('created_at', { ascending: false });
			
			salesHistory = (sData || []).map((item: any) => ({
				...item,
				sale_date: item.sales.created_at,
				cashier_name: item.sales.users?.full_name || 'System',
				total: item.subtotal
			}));

			// 4. Fetch Supply History from inventory_transactions
			if (currentBranchId) {
				const { data: tData } = await supabase.from('inventory_transactions')
					.select('*, users:staff_id(full_name)')
					.eq('product_id', productId)
					.eq('branch_id', currentBranchId)
					.eq('transaction_type', 'restock')
					.order('created_at', { ascending: false });
				supplyHistory = tData || [];
			}

			if (activeTab === 'analytics' || activeTab === 'overview') {
				updateChart();
			}
		} catch (err) {
			console.error('Error fetching product data:', err);
		} finally {
			loading = false;
		}
	}

	async function toggleActive() {
		if (!product) return;
		const newStatus = !product.is_active;
		await supabase.from('products').update({ is_active: newStatus }).eq('id', productId);
		product = { ...product, is_active: newStatus };
	}

	function updateChart() {
		// Delay to ensure canvas is in DOM
		setTimeout(() => {
			if (!chartCanvas || !salesHistory.length) return;
			if (chart) chart.destroy();

			const ctx = chartCanvas.getContext('2d');
			if (!ctx) return;

			const data = getAggregatedData(chartPeriod);

			chart = new Chart(ctx, {
				type: 'line',
				data: {
					labels: data.labels,
					datasets: [{
						label: 'Units Sold',
						data: data.values,
						borderColor: 'rgb(79, 70, 229)',
						backgroundColor: 'rgba(79, 70, 229, 0.1)',
						fill: true,
						tension: 0.4
					}]
				},
				options: {
					responsive: true,
					maintainAspectRatio: false,
					plugins: { legend: { display: false } },
					scales: {
						y: { beginAtZero: true, ticks: { precision: 0 } },
						x: { grid: { display: false } }
					}
				}
			});
		}, 0);
	}

	function getAggregatedData(period: string) {
		const now = new Date();
		let filterDate = new Date();
		let grouping: 'day' | 'week' | 'month' | 'year' = 'day';

		if (period === '30d') filterDate.setDate(now.getDate() - 30);
		else if (period === 'quarter') { filterDate.setMonth(now.getMonth() - 3); grouping = 'week'; }
		else if (period === 'year') { filterDate.setFullYear(now.getFullYear() - 1); grouping = 'month'; }
		else if (period === '5y') { filterDate.setFullYear(now.getFullYear() - 5); grouping = 'year'; }

		const filteredSales = salesHistory.filter(s => new Date(s.sale_date) >= filterDate);
		const map = new Map<string, number>();

		filteredSales.forEach(s => {
			const d = new Date(s.sale_date);
			let key = d.toLocaleDateString();
			if (grouping === 'month') key = `${d.getFullYear()}-${d.getMonth() + 1}`;
			if (grouping === 'year') key = `${d.getFullYear()}`;
			if (grouping === 'week') {
				const startOfWeek = new Date(d);
				startOfWeek.setDate(d.getDate() - d.getDay());
				key = startOfWeek.toLocaleDateString();
			}
			map.set(key, (map.get(key) || 0) + s.quantity);
		});

		const sortedKeys = Array.from(map.keys()).sort((a,b) => new Date(a).getTime() - new Date(b).getTime());
		return {
			labels: sortedKeys,
			values: sortedKeys.map(k => map.get(k) || 0)
		};
	}

	$effect(() => {
		if (activeTab === 'analytics' || activeTab === 'overview') {
			updateChart();
		}
	});

	$effect(() => {
		if (chartPeriod) updateChart();
	});

	onDestroy(() => { if (chart) chart.destroy(); });

	function formatCurrency(val: number | undefined | null) {
		if (val == null) return '₦0.00';
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}

	// Stats derived from salesHistory
	const totalRevenue = $derived(salesHistory.reduce((acc, s) => acc + s.total, 0));
	const totalProfit = $derived(salesHistory.reduce((acc, s) => acc + (s.gross_profit || 0), 0));
	const lastSaleDate = $derived(salesHistory.length > 0 ? new Date(salesHistory[0].sale_date).toLocaleDateString() : 'Never');
</script>

<svelte:head><title>{product?.name || 'Product'} – Analytics & Inventory</title></svelte:head>

<div class="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8 space-y-6">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div class="flex items-center gap-4">
			<a href="/products" class="p-2 hover:bg-gray-100 rounded-lg transition-colors text-gray-500">
				<ArrowLeft class="h-6 w-6" />
			</a>
			<div class="h-14 w-14 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600 border border-indigo-100 shadow-sm">
				{#if product?.image_url}
					<img src={product.image_url} alt={product.name} class="h-14 w-14 object-cover rounded-2xl" />
				{:else}
					<Package class="h-7 w-7" />
				{/if}
			</div>
			<div>
				<h1 class="text-2xl font-black text-gray-900">{product?.name || 'Loading...'}</h1>
				<div class="flex items-center gap-2 mt-0.5">
					<span class="text-xs text-gray-500 font-bold uppercase tracking-widest">{product?.barcode || 'NO SKU'}</span>
					<span class="text-xs text-gray-300">•</span>
					<span class="text-xs font-bold {product?.is_active ? 'text-emerald-600' : 'text-rose-500'} uppercase tracking-widest">
						{product?.is_active ? 'Active' : 'Inactive'}
					</span>
				</div>
			</div>
		</div>
		<div class="flex items-center gap-2">
			{#if product}
				<a href="/products/{productId}/edit" class="inline-flex items-center gap-2 bg-white border hover:bg-gray-50 text-gray-700 font-bold px-4 py-2.5 rounded-xl text-sm transition-all shadow-sm">
					<Edit class="h-4 w-4 text-indigo-500" /> Edit Details
				</a>
			{/if}
		</div>
	</div>

	{#if loading}
		<div class="flex flex-col items-center justify-center py-32 text-gray-400 italic">
			<Loader2 class="h-10 w-10 animate-spin mb-4 text-indigo-600" />
			<p>Aggregating product analytics and stock data...</p>
		</div>
	{:else if product}
		<!-- Quick Stats Row -->
		<div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
			<div class="p-5 bg-white rounded-2xl border border-gray-100 shadow-sm transition-transform hover:scale-[1.02]">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Stock Balance</p>
				<p class="text-2xl font-black text-gray-900">{batches.reduce((acc, b) => acc + b.stock_quantity, 0)} <span class="text-xs text-gray-400 font-bold ml-1">Units</span></p>
			</div>
			<div class="p-5 bg-white rounded-2xl border border-gray-100 shadow-sm transition-transform hover:scale-[1.02]">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Total Revenue</p>
				<p class="text-2xl font-black text-emerald-600">{formatCurrency(totalRevenue)}</p>
			</div>
			<div class="p-5 bg-white rounded-2xl border border-gray-100 shadow-sm transition-transform hover:scale-[1.02]">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Total Profit</p>
				<p class="text-2xl font-black text-indigo-600">{formatCurrency(totalProfit)}</p>
			</div>
			<div class="p-5 bg-white rounded-2xl border border-gray-100 shadow-sm transition-transform hover:scale-[1.02]">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Last Sale</p>
				<p class="text-2xl font-black text-gray-900">{lastSaleDate}</p>
			</div>
		</div>

		<!-- Main Content Area with Tabs -->
		<div class="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
			<!-- Tab Navigation -->
			<div class="flex border-b px-8 bg-white overflow-x-auto no-scrollbar gap-8">
				{#each ['overview', 'batches', 'supply', 'sales', 'analytics'] as tab}
					<button 
						onclick={() => activeTab = tab as any}
						class="py-5 text-xs font-black uppercase tracking-widest transition-all relative whitespace-nowrap {activeTab === tab ? 'text-indigo-600' : 'text-gray-400 hover:text-gray-900'}"
					>
						{tab}
						{#if activeTab === tab}
							<div class="absolute bottom-0 left-0 right-0 h-1 bg-indigo-600 rounded-full"></div>
						{/if}
					</button>
				{/each}
			</div>

			<!-- Tab Panels -->
			<div class="p-8 bg-gray-50/20 min-h-[500px]">
				{#if activeTab === 'overview'}
					<div class="grid grid-cols-1 lg:grid-cols-3 gap-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
						<!-- Product Bio -->
						<div class="lg:col-span-2 space-y-6">
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
								<h3 class="font-black text-gray-900 flex items-center gap-2 mb-4">
									<Info class="h-5 w-5 text-indigo-500" /> Product Details
								</h3>
								<div class="grid grid-cols-2 gap-y-4 text-sm">
									<div class="flex flex-col"><span class="text-gray-400 font-bold uppercase text-[10px] tracking-wider">Type</span><span class="font-bold">{product.product_type || 'General'}</span></div>
									<div class="flex flex-col"><span class="text-gray-400 font-bold uppercase text-[10px] tracking-wider">Category</span><span class="font-bold">{product.category || 'Uncategorized'}</span></div>
									{#if product.generic_name}
										<div class="flex flex-col"><span class="text-gray-400 font-bold uppercase text-[10px] tracking-wider">Generic Name</span><span class="font-bold">{product.generic_name}</span></div>
									{/if}
									{#if product.manufacturer}
										<div class="flex flex-col"><span class="text-gray-400 font-bold uppercase text-[10px] tracking-wider">Manufacturer</span><span class="font-bold">{product.manufacturer}</span></div>
									{/if}
								</div>
								{#if product.description}
									<div class="mt-6 p-4 bg-gray-50 rounded-xl border border-gray-100">
										<p class="text-sm text-gray-600 leading-relaxed italic">"{product.description}"</p>
									</div>
								{/if}
							</div>

							<!-- 30 Day Trend Chart -->
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col h-[300px]">
								<h3 class="font-black text-gray-900 flex items-center gap-2 mb-4">
									<TrendingUp class="h-5 w-5 text-emerald-500" /> Sales Trend (30 Days)
								</h3>
								<div class="flex-1 relative min-h-0">
									<canvas bind:this={chartCanvas}></canvas>
								</div>
							</div>
						</div>

						<!-- Sidebar Stats -->
						<div class="space-y-6">
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm space-y-4">
								<div class="flex items-center justify-between">
									<h3 class="font-black text-gray-900 text-sm">Status Control</h3>
									<button onclick={toggleActive} class="transition-transform active:scale-95">
										{#if product.is_active}
											<ToggleRight class="h-10 w-10 text-indigo-600" />
										{:else}
											<ToggleLeft class="h-10 w-10 text-gray-300" />
										{/if}
									</button>
								</div>
								<p class="text-xs text-gray-500 font-medium">When inactive, this product is hidden from all point-of-sale interfaces and storefronts.</p>
							</div>

							<div class="bg-indigo-600 p-6 rounded-2xl shadow-lg shadow-indigo-200 text-white space-y-4">
								<h3 class="font-black text-sm uppercase tracking-widest opacity-80">Pricing Overview</h3>
								<div class="space-y-2">
									<div class="flex justify-between items-baseline"><span class="text-xs opacity-70">Current Selling</span><span class="text-xl font-black">{formatCurrency(branchInventory?.selling_price)}</span></div>
									<div class="flex justify-between items-baseline"><span class="text-xs opacity-70">Last Cost</span><span class="text-sm font-bold opacity-90">{formatCurrency(supplyHistory[0]?.unit_cost)}</span></div>
								</div>
								<div class="pt-4 border-t border-white/20">
									<div class="flex justify-between items-baseline"><span class="text-xs opacity-70">Gross Margin</span><span class="text-sm font-black">
										{branchInventory?.selling_price && supplyHistory[0]?.unit_cost 
											? (((branchInventory.selling_price - supplyHistory[0].unit_cost) / branchInventory.selling_price) * 100).toFixed(1)
											: '0.0'
										}%
									</span></div>
								</div>
							</div>
						</div>
					</div>

				{:else if activeTab === 'batches'}
					<div class="bg-white rounded-2xl border border-gray-100 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
						<div class="overflow-x-auto">
							<table class="w-full text-left whitespace-nowrap">
								<thead class="bg-gray-50">
									<tr>
										<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Batch Number</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Stock Level</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Pricing</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Supplier</th>
										<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-right">Expiry Date</th>
									</tr>
								</thead>
								<tbody class="divide-y divide-gray-50">
									{#each batches as batch}
										<tr class="hover:bg-gray-50/50 transition-colors">
											<td class="px-8 py-5">
												<p class="text-sm font-black text-gray-900">{batch.batch_no || 'MANUAL-BATCH'}</p>
												<p class="text-[10px] text-gray-400 font-bold uppercase">{batch.id.split('-')[0]}</p>
											</td>
											<td class="px-6 py-5">
												<div class="flex items-center gap-2">
													<div class="h-2 w-2 rounded-full {batch.stock_quantity > 10 ? 'bg-emerald-500' : 'bg-rose-500 animate-pulse'}"></div>
													<span class="text-sm font-black text-gray-900">{batch.stock_quantity}</span>
												</div>
											</td>
											<td class="px-6 py-5">
												<p class="text-sm font-black text-indigo-600">{formatCurrency(batch.selling_price)}</p>
												<p class="text-[10px] text-gray-400 font-medium italic">Cost: {formatCurrency(batch.cost_price)}</p>
											</td>
											<td class="px-6 py-5">
												<div class="flex items-center gap-2">
													<Truck class="h-3 w-3 text-gray-400" />
													<span class="text-xs font-bold text-gray-600">{batch.suppliers?.name || 'Local Stock'}</span>
												</div>
											</td>
											<td class="px-8 py-5 text-right">
												<span class="text-sm font-black {new Date(batch.expiry_date) < new Date() ? 'text-rose-600' : 'text-gray-700'}">
													{batch.expiry_date ? new Date(batch.expiry_date).toLocaleDateString() : 'NO EXPIRY'}
												</span>
											</td>
										</tr>
									{:else}
										<tr><td colspan="5" class="text-center py-20 text-gray-400 italic">No inventory batches found in this branch.</td></tr>
									{/each}
								</tbody>
							</table>
						</div>
					</div>

				{:else if activeTab === 'supply'}
					<div class="bg-white rounded-2xl border border-gray-100 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
						<div class="p-6 bg-indigo-50/50 border-b border-indigo-100 flex items-center gap-4">
							<ClipboardList class="h-6 w-6 text-indigo-600" />
							<div>
								<h4 class="font-black text-indigo-900 text-sm">Supply & Restock Ledger</h4>
								<p class="text-[10px] font-bold text-indigo-500 uppercase tracking-widest">Audit trail of all stock additions</p>
							</div>
						</div>
						<div class="overflow-x-auto">
							<table class="w-full text-left whitespace-nowrap">
								<thead class="bg-gray-50">
									<tr>
										<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Transaction Date</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Quantity Added</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Unit Cost</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Operator</th>
									</tr>
								</thead>
								<tbody class="divide-y divide-gray-50">
									{#each supplyHistory as log}
										<tr class="hover:bg-gray-50/50 transition-colors">
											<td class="px-8 py-5">
												<p class="text-sm font-black text-gray-900">{new Date(log.created_at).toLocaleDateString()}</p>
												<p class="text-[10px] text-gray-400 font-bold uppercase">{new Date(log.created_at).toLocaleTimeString()}</p>
											</td>
											<td class="px-6 py-5 text-sm font-black text-emerald-600">+{log.quantity_delta}</td>
											<td class="px-6 py-5 text-sm font-bold text-gray-700">{formatCurrency(log.unit_cost)}</td>
											<td class="px-6 py-5">
												<div class="flex items-center gap-2">
													<div class="h-6 w-6 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center text-[10px] font-black border border-indigo-100">
														{(log.users?.full_name || 'S').charAt(0)}
													</div>
													<span class="text-xs font-bold text-gray-600">{log.users?.full_name || 'System'}</span>
												</div>
											</td>
										</tr>
									{:else}
										<tr><td colspan="4" class="text-center py-20 text-gray-400 italic">No supply history records available.</td></tr>
									{/each}
								</tbody>
							</table>
						</div>
					</div>

				{:else if activeTab === 'sales'}
					<div class="bg-white rounded-2xl border border-gray-100 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
						<div class="overflow-x-auto">
							<table class="w-full text-left whitespace-nowrap">
								<thead class="bg-gray-50">
									<tr>
										<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Date & Time</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Sale Code</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Qty</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Subtotal</th>
										<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest">Profit</th>
										<th class="px-8 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-right">Cashier</th>
									</tr>
								</thead>
								<tbody class="divide-y divide-gray-50">
									{#each salesHistory as sale}
										<tr class="hover:bg-gray-50/50 transition-colors">
											<td class="px-8 py-5">
												<p class="text-sm font-black text-gray-900">{new Date(sale.sale_date).toLocaleDateString()}</p>
												<p class="text-[10px] text-gray-400 font-bold uppercase">{new Date(sale.sale_date).toLocaleTimeString()}</p>
											</td>
											<td class="px-6 py-5">
												<span class="text-[10px] font-black bg-gray-100 px-2 py-1 rounded border border-gray-200 font-mono">
													#{sale.id.split('-')[0]}
												</span>
											</td>
											<td class="px-6 py-5 text-sm font-black text-gray-900">{sale.quantity}</td>
											<td class="px-6 py-5 text-sm font-black text-emerald-600">{formatCurrency(sale.total)}</td>
											<td class="px-6 py-5 text-sm font-bold text-indigo-600">{formatCurrency(sale.gross_profit)}</td>
											<td class="px-8 py-5 text-right">
												<span class="text-xs font-bold text-gray-600">{sale.cashier_name}</span>
											</td>
										</tr>
									{:else}
										<tr><td colspan="6" class="text-center py-20 text-gray-400 italic">No sales recorded for this product yet.</td></tr>
									{/each}
								</tbody>
							</table>
						</div>
					</div>

				{:else if activeTab === 'analytics'}
					<div class="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
						<!-- Period Selector -->
						<div class="flex items-center justify-between">
							<div>
								<h3 class="font-black text-gray-900 text-xl">Sales Performance Analytics</h3>
								<p class="text-sm text-gray-400 font-medium">Detailed historical trajectory of inventory movement and revenue</p>
							</div>
							<div class="flex gap-1 p-1 bg-gray-100 rounded-xl border border-gray-200">
								{#each ['30d', 'quarter', 'year', '5y'] as period}
									<button 
										onclick={() => chartPeriod = period as any}
										class="px-5 py-2 text-[10px] font-black uppercase tracking-widest rounded-lg transition-all {chartPeriod === period ? 'bg-indigo-600 text-white shadow-md' : 'text-gray-400 hover:text-indigo-600'}"
									>
										{period}
									</button>
								{/each}
							</div>
						</div>

						<!-- KPI Grid -->
						<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
								<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Max Daily Sale</p>
								<p class="text-3xl font-black text-gray-900">{Math.max(0, ...getAggregatedData(chartPeriod).values)} <span class="text-xs text-gray-400 uppercase tracking-wider">Units</span></p>
							</div>
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
								<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Avg Order Value</p>
								<p class="text-3xl font-black text-gray-900">
									{salesHistory.length > 0 ? formatCurrency(totalRevenue / salesHistory.length) : '₦0'}
								</p>
							</div>
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
								<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Sales Velocity</p>
								<p class="text-3xl font-black text-gray-900">
									{(salesHistory.length / (chartPeriod === '30d' ? 30 : 90)).toFixed(1)} <span class="text-xs text-gray-400 uppercase tracking-wider">Daily</span>
								</p>
							</div>
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
								<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Profit Margin</p>
								<p class="text-3xl font-black text-indigo-600">
									{totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100).toFixed(1) : '0.0'}%
								</p>
							</div>
						</div>

						<!-- Large Chart Area -->
						<div class="bg-white p-8 rounded-3xl border border-gray-100 shadow-sm h-[500px]">
							<canvas bind:this={chartCanvas}></canvas>
						</div>
					</div>
				{/if}
			</div>
		</div>
	{/if}
</div>

<style>
	:global(.no-scrollbar::-webkit-scrollbar) { display: none; }
	:global(.no-scrollbar) { -ms-overflow-style: none; scrollbar-width: none; }
</style>

