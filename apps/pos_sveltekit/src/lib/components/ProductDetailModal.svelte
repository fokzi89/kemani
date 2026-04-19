<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		X, Package, Clock, ShoppingCart, TrendingUp, 
		Calendar, User, AlertTriangle, Save, Loader2,
		Filter, Download, ArrowRight, BarChart3, Truck
	} from 'lucide-svelte';
	import Chart from 'chart.js/auto';

	let { productId, branchId, isOpen, onClose, productName = '' } = $props<{
		productId: string;
		branchId: string;
		isOpen: boolean;
		onClose: () => void;
		productName: string;
	}>();

	let loading = $state(true);
	let product = $state<any>(null);
	let batches = $state<any[]>([]);
	let sales = $state<any[]>([]);
	let activeTab = $state<'overview' | 'batches' | 'sales' | 'analytics'>('overview');
	let chartPeriod = $state<'30d' | 'quarter' | 'year' | '5y'>('30d');
	let lowStockThreshold = $state(0);
	let savingThreshold = $state(false);

	let chartCanvas = $state<HTMLCanvasElement | null>(null);
	let chart: Chart | null = null;

	async function fetchData() {
		if (!productId || !isOpen) return;
		loading = true;
		try {
			// 1. Fetch Product Basic Info
			const { data: pData } = await supabase.from('products')
				.select('*')
				.eq('id', productId)
				.single();
			product = pData;
			lowStockThreshold = pData?.low_stock_threshold || 0;

			// 2. Fetch all batches for this product in this branch
			const { data: bData } = await supabase.from('branch_inventory')
				.select('*, suppliers(name)')
				.eq('product_id', productId)
				.eq('branch_id', branchId)
				.order('created_at', { ascending: false });
			batches = bData || [];

			// 3. Fetch Sale History Joined with Sales and Users (Cashier)
			const { data: sData } = await supabase.from('sale_items')
				.select('*, sales!inner(*, users:cashier_id(full_name))')
				.eq('product_id', productId)
				.eq('sales.branch_id', branchId)
				.order('sales(created_at)', { ascending: false });
			
			sales = (sData || []).map(item => ({
				...item,
				sale_date: item.sales.created_at,
				cashier_name: item.sales.users?.full_name || 'System',
				total: (item.quantity * item.unit_price) - (item.discount_amount || 0)
			}));

			updateChart();
		} catch (err) {
			console.error('Error fetching product detail:', err);
		} finally {
			loading = false;
		}
	}

	async function updateThreshold() {
		savingThreshold = true;
		try {
			const { error } = await supabase.from('products')
				.update({ low_stock_threshold: lowStockThreshold })
				.eq('id', productId);
			
			if (error) throw error;
			if (product) product.low_stock_threshold = lowStockThreshold;
		} catch (err) {
			alert('Failed to update threshold');
		} finally {
			savingThreshold = false;
		}
	}

	function updateChart() {
		if (!chartCanvas || !sales.length) return;
		if (chart) chart.destroy();

		const ctx = chartCanvas.getContext('2d');
		if (!ctx) return;

		const data = getAggregatedData(chartPeriod);

		chart = new Chart(ctx, {
			type: 'line',
			data: {
				labels: data.labels,
				datasets: [{
					label: 'Quantity Sold',
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
				plugins: {
					legend: { display: false }
				},
				scales: {
					y: { beginAtZero: true, ticks: { precision: 0 } },
					x: { grid: { display: false } }
				}
			}
		});
	}

	function getAggregatedData(period: string) {
		const now = new Date();
		let filterDate = new Date();
		let grouping: 'day' | 'week' | 'month' | 'year' = 'day';

		if (period === '30d') filterDate.setDate(now.getDate() - 30);
		else if (period === 'quarter') { filterDate.setMonth(now.getMonth() - 3); grouping = 'week'; }
		else if (period === 'year') { filterDate.setFullYear(now.getFullYear() - 1); grouping = 'month'; }
		else if (period === '5y') { filterDate.setFullYear(now.getFullYear() - 5); grouping = 'year'; }

		const filteredSales = sales.filter(s => new Date(s.sale_date) >= filterDate);
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

	$effect(() => { if (isOpen) fetchData(); });
	$effect(() => { if (chartPeriod) updateChart(); });

	onDestroy(() => { if (chart) chart.destroy(); });

	function formatCurrency(val: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}
</script>

{#if isOpen}
	<div class="fixed inset-0 z-[110] flex items-center justify-center p-4">
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div class="absolute inset-0 bg-gray-900/60 backdrop-blur-sm" onclick={onClose}></div>
		
		<div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-5xl max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">
			<!-- Header -->
			<div class="p-6 border-b flex items-start justify-between bg-white sticky top-0 z-10">
				<div class="flex items-center gap-4">
					<div class="h-14 w-14 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm border border-indigo-100">
						<Package class="h-7 w-7" />
					</div>
					<div>
						<h2 class="text-2xl font-black text-gray-900">{productName || 'Product Detail'}</h2>
						<p class="text-xs text-gray-500 font-bold uppercase tracking-widest mt-0.5">{product?.sku || 'No SKU'}</p>
					</div>
				</div>
				<button onclick={onClose} class="p-2.5 hover:bg-gray-100 rounded-xl transition-colors text-gray-400">
					<X class="h-6 w-6" />
				</button>
			</div>

			<!-- Secondary Header with Stats -->
			<div class="px-6 py-4 bg-gray-50/50 border-b grid grid-cols-2 md:grid-cols-4 gap-4">
				<div class="p-3 bg-white rounded-xl border border-gray-100 shadow-sm">
					<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Total Stock</p>
					<p class="text-lg font-black text-gray-900">{batches.reduce((acc, b) => acc + b.stock_quantity, 0)} Units</p>
				</div>
				<div class="p-3 bg-white rounded-xl border border-gray-100 shadow-sm font-black">
					<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Price Range</p>
					<p class="text-lg text-indigo-600">
						{#if batches.length > 0}
							{formatCurrency(Math.min(...batches.map(b => b.selling_price)))} - {formatCurrency(Math.max(...batches.map(b => b.selling_price)))}
						{:else}
							N/A
						{/if}
					</p>
				</div>
				<div class="p-3 bg-white rounded-xl border border-gray-100 shadow-sm">
					<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Last Sale</p>
					<p class="text-lg font-black text-gray-900">{sales[0] ? new Date(sales[0].sale_date).toLocaleDateString() : 'Never'}</p>
				</div>
				<div class="p-3 bg-white rounded-xl border border-gray-100 shadow-sm">
					<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Set Low Stock</p>
					<div class="flex items-center gap-2">
						<input 
							type="number" 
							bind:value={lowStockThreshold} 
							class="w-full text-sm font-black outline-none border-none p-0 focus:ring-0"
						/>
						<button 
							onclick={updateThreshold} 
							disabled={savingThreshold}
							class="text-indigo-600 hover:text-indigo-800"
						>
							{#if savingThreshold}
								<Loader2 class="h-4 w-4 animate-spin" />
							{:else}
								<Save class="h-4 w-4" />
							{/if}
						</button>
					</div>
				</div>
			</div>

			<!-- Tabs -->
			<div class="flex border-b px-6 bg-white overflow-x-auto no-scrollbar">
				{#each ['overview', 'batches', 'sales', 'analytics'] as tab}
					<button 
						onclick={() => activeTab = tab as any}
						class="px-6 py-4 text-sm font-bold transition-all relative whitespace-nowrap {activeTab === tab ? 'text-indigo-600' : 'text-gray-500 hover:text-gray-900'}"
					>
						{tab.charAt(0).toUpperCase() + tab.slice(1)}
						{#if activeTab === tab}
							<div class="absolute bottom-0 left-6 right-6 h-0.5 bg-indigo-600 rounded-full"></div>
						{/if}
					</button>
				{/each}
			</div>

			<!-- Content -->
			<div class="flex-1 overflow-y-auto p-6 bg-gray-50/30">
				{#if loading}
					<div class="flex flex-col items-center justify-center py-20 text-gray-400">
						<Loader2 class="h-10 w-10 animate-spin mb-4" />
						<p class="font-medium italic">Compiling audit data...</p>
					</div>
				{:else}
					<div class="animate-in fade-in slide-in-from-bottom-2 duration-300">
						{#if activeTab === 'overview'}
							<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
								<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm space-y-4">
									<h3 class="font-black text-gray-900 flex items-center gap-2">
										<TrendingUp class="h-5 w-5 text-indigo-600" />
										Recent Activity
									</h3>
									<div class="space-y-4">
										{#each sales.slice(0, 5) as sale}
											<div class="flex items-center justify-between border-b border-gray-50 pb-3 last:border-0 last:pb-0">
												<div>
													<p class="text-sm font-bold text-gray-900">Sold {sale.quantity} units</p>
													<p class="text-[10px] text-gray-400 font-medium uppercase">{new Date(sale.sale_date).toLocaleString()}</p>
												</div>
												<div class="text-right">
													<p class="text-sm font-black text-emerald-600">{formatCurrency(sale.total)}</p>
													<p class="text-[10px] text-gray-400 font-bold uppercase">{sale.cashier_name}</p>
												</div>
											</div>
										{:else}
											<p class="text-sm text-gray-500 italic py-4">No recent sales data</p>
										{/each}
									</div>
								</div>

								<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm space-y-4">
									<h3 class="font-black text-gray-900 flex items-center gap-2">
										<Clock class="h-5 w-5 text-amber-500" />
										Stock Expiry
									</h3>
									<div class="space-y-4">
										{#each batches.filter(b => b.expiry_date).slice(0, 5) as batch}
											<div class="flex items-center justify-between border-b border-gray-50 pb-3 last:border-0 last:pb-0">
												<div>
													<p class="text-sm font-bold text-gray-900">Batch {batch.batch_no || 'N/A'}</p>
													<p class="text-[10px] text-gray-400 font-medium uppercase">{batch.stock_quantity} left</p>
												</div>
												<div class="text-right">
													<p class="text-sm font-black {new Date(batch.expiry_date) < new Date(Date.now() + 90*24*60*60*1000) ? 'text-rose-600' : 'text-gray-700'}">
														{new Date(batch.expiry_date).toLocaleDateString()}
													</p>
													{#if new Date(batch.expiry_date) < new Date(Date.now() + 90*24*60*60*1000)}
														<span class="text-[8px] font-black bg-rose-50 text-rose-600 px-1.5 py-0.5 rounded uppercase">Urgent</span>
													{/if}
												</div>
											</div>
										{:else}
											<p class="text-sm text-gray-500 italic py-4">No expiry data found</p>
										{/each}
									</div>
								</div>
							</div>

						{:else if activeTab === 'batches'}
							<div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
								<table class="w-full text-left">
									<thead class="bg-gray-50/50">
										<tr>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase whitespace-nowrap">Batch</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase whitespace-nowrap">Pricing</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase whitespace-nowrap">Stock</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase whitespace-nowrap">Supplier</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase whitespace-nowrap">Supply Date</th>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase whitespace-nowrap">Expiry</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each batches as batch}
											<tr class="hover:bg-gray-50/50 transition-colors">
												<td class="px-6 py-4">
													<p class="text-sm font-black text-gray-900">{batch.batch_no || 'NA'}</p>
													<p class="text-[10px] text-gray-400 font-bold uppercase">{batch.id.split('-')[0]}</p>
												</td>
												<td class="px-4 py-4">
													<p class="text-sm font-black text-indigo-600">{formatCurrency(batch.selling_price)}</p>
													<p class="text-[10px] text-gray-400 font-medium italic">Cost: {formatCurrency(batch.cost_price || 0)}</p>
												</td>
												<td class="px-4 py-4">
													<p class="text-sm font-black text-gray-900">{batch.stock_quantity}</p>
												</td>
												<td class="px-4 py-4">
													<div class="flex items-center gap-2">
														<Truck class="h-3.5 w-3.5 text-gray-400" />
														<p class="text-sm font-bold text-gray-700">{batch.suppliers?.name || 'Manual Stock'}</p>
													</div>
												</td>
												<td class="px-4 py-4 text-sm text-gray-500">
													{new Date(batch.created_at).toLocaleDateString()}
												</td>
												<td class="px-6 py-4">
													<p class="text-sm font-black {new Date(batch.expiry_date) < new Date() ? 'text-rose-600' : 'text-gray-700'}">
														{batch.expiry_date ? new Date(batch.expiry_date).toLocaleDateString() : '—'}
													</p>
												</td>
											</tr>
										{/each}
									</tbody>
								</table>
							</div>

						{:else if activeTab === 'sales'}
							<div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
								<table class="w-full text-left">
									<thead class="bg-gray-50/50">
										<tr>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase">Sale Date</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Qty</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Sold At</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Total Revenue</th>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase">Cashier</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each sales as sale}
											<tr class="hover:bg-gray-50/50 transition-colors">
												<td class="px-6 py-4">
													<p class="text-sm font-bold text-gray-900">{new Date(sale.sale_date).toLocaleDateString()}</p>
													<p class="text-[10px] text-gray-400 font-medium">{new Date(sale.sale_date).toLocaleTimeString()}</p>
												</td>
												<td class="px-4 py-4 text-sm font-black text-gray-900">{sale.quantity}</td>
												<td class="px-4 py-4 text-sm text-gray-500 font-medium">{formatCurrency(sale.unit_price)}</td>
												<td class="px-4 py-4 text-sm font-black text-emerald-600">{formatCurrency(sale.total)}</td>
												<td class="px-6 py-4">
													<div class="flex items-center gap-2">
														<User class="h-3.5 w-3.5 text-indigo-400" />
														<span class="text-sm font-bold text-gray-700">{sale.cashier_name}</span>
													</div>
												</td>
											</tr>
										{/each}
									</tbody>
								</table>
							</div>

						{:else if activeTab === 'analytics'}
							<div class="space-y-6">
								<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col h-[400px]">
									<div class="flex items-center justify-between mb-6">
										<div>
											<h3 class="font-black text-gray-900 text-lg">Sales Performance</h3>
											<p class="text-xs text-gray-400">Inventory movement trends over time</p>
										</div>
										<div class="flex gap-1 p-1 bg-gray-50 rounded-xl border border-gray-100">
											{#each ['30d', 'quarter', 'year', '5y'] as period}
												<button 
													onclick={() => chartPeriod = period as any}
													class="px-4 py-1.5 text-[10px] font-black uppercase tracking-widest rounded-lg transition-all {chartPeriod === period ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-100' : 'text-gray-400 hover:text-indigo-600'}"
												>
													{period}
												</button>
											{/each}
										</div>
									</div>
									<div class="flex-1 relative min-h-0">
										<canvas bind:this={chartCanvas}></canvas>
									</div>
								</div>
								
								<div class="grid grid-cols-1 md:grid-cols-3 gap-6 font-black">
									<div class="bg-emerald-50 p-6 rounded-2xl border border-emerald-100 text-center">
										<p class="text-[10px] text-emerald-600 uppercase tracking-widest mb-1">Max Daily Sale</p>
										<p class="text-3xl text-emerald-700">{Math.max(0, ...getAggregatedData('30d').values)} <span class="text-sm">Units</span></p>
									</div>
									<div class="bg-indigo-50 p-6 rounded-2xl border border-indigo-100 text-center">
										<p class="text-[10px] text-indigo-600 uppercase tracking-widest mb-1">Total Revenue (30d)</p>
										<p class="text-3xl text-indigo-700">{formatCurrency(sales.filter(s => new Date(s.sale_date) > new Date(Date.now() - 30*24*60*60*1000)).reduce((acc, s) => acc + s.total, 0))}</p>
									</div>
									<div class="bg-amber-50 p-6 rounded-2xl border border-amber-100 text-center font-black">
										<p class="text-[10px] text-amber-600 uppercase tracking-widest mb-1">Avg Movement Rate</p>
										<p class="text-3xl text-amber-700">{(sales.length / 30).toFixed(1)} <span class="text-sm">/ Day</span></p>
									</div>
								</div>
							</div>
						{/if}
					</div>
				{/if}
			</div>

			<!-- Footer -->
			<div class="p-6 border-t bg-gray-50 flex items-center justify-between">
				<div class="flex gap-4">
					<button class="flex items-center gap-2 text-xs font-bold text-gray-500 hover:text-indigo-600">
						<Download class="h-4 w-4" /> Export Audit Log
					</button>
					<button class="flex items-center gap-2 text-xs font-bold text-gray-500 hover:text-indigo-600">
						<BarChart3 class="h-4 w-4" /> General Analytics
					</button>
				</div>
				<button 
					onclick={onClose}
					class="px-8 py-3 bg-gray-900 text-white font-black rounded-xl hover:bg-gray-800 transition-all text-sm uppercase tracking-widest shadow-xl shadow-gray-200"
				>
					Close Viewer
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	.no-scrollbar::-webkit-scrollbar { display: none; }
	.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
