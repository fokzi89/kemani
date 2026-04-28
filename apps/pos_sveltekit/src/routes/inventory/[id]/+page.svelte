<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { 
		ArrowLeft, Package, Clock, ShoppingCart, TrendingUp, 
		Calendar, User, AlertTriangle, Save, Loader2,
		Download, BarChart3, Truck, ClipboardList
	} from 'lucide-svelte';
	import Chart from 'chart.js/auto';

	let inventoryId = $derived($page.params.id);
	let branchId = $derived($page.url.searchParams.get('branchId') || '');

	let loading = $state(true);
	let product = $state<any>(null);
	let activeInventory = $state<any>(null);
	let batches = $state<any[]>([]);
	let sales = $state<any[]>([]);
	let supplyHistory = $state<any[]>([]);
	let activeTab = $state<'overview' | 'batches' | 'supply' | 'sales' | 'analytics'>('overview');
	let chartPeriod = $state<'30d' | 'quarter' | 'year' | '5y'>('30d');
	let lowStockThreshold = $state(0);
	let savingThreshold = $state(false);

	let chartCanvas = $state<HTMLCanvasElement | null>(null);
	let chart: Chart | null = null;

	async function fetchData() {
		if (!inventoryId) {
			console.log('[InventoryDetail] No ID found in params');
			return;
		}
		console.log('[InventoryDetail] Fetching data for ID:', inventoryId);
		loading = true;
		
		try {
			// 1. Fetch Active Inventory Batch Info
			console.log('[InventoryDetail] Fetching batch info...');
			const { data: invData, error: invErr } = await supabase.from('branch_inventory')
				.select('*, products(*)')
				.eq('id', inventoryId)
				.maybeSingle();
			
			if (invErr) {
				console.error('[InventoryDetail] Batch fetch error:', invErr);
				throw invErr;
			}
			
			if (!invData) {
				console.warn('[InventoryDetail] Inventory record not found for ID:', inventoryId);
				loading = false;
				return;
			}

			console.log('[InventoryDetail] Found inventory for product:', invData.products?.name);
			activeInventory = invData;
			product = invData.products;
			lowStockThreshold = invData?.low_stock_threshold || 0;
			batches = [invData];

			// 2. Fetch Sales and Transactions in parallel
			console.log('[InventoryDetail] Fetching history in parallel...');
			const [salesRes, transRes] = await Promise.all([
				supabase.from('sale_items')
					.select('*')
					.eq('inventory_id', inventoryId)
					.order('created_at', { ascending: false })
					.then(r => { console.log('[InventoryDetail] Sales fetch complete'); return r; }),
				supabase.from('inventory_transactions')
					.select('*, users:staff_id(full_name)')
					.eq('product_id', invData.product_id)
					.eq('branch_id', invData.branch_id)
					.eq('transaction_type', 'restock')
					.order('created_at', { ascending: false })
					.then(r => { console.log('[InventoryDetail] Transactions fetch complete'); return r; })
			]);

			if (salesRes.error) {
				console.error('[InventoryDetail] Sales error:', salesRes.error);
				throw salesRes.error;
			}
			if (transRes.error) {
				console.error('[InventoryDetail] Transactions error:', transRes.error);
			}

			sales = (salesRes.data || []).map((item: any) => ({
				...item,
				sale_date: item.sale_date || item.created_at,
				total: (item.quantity * item.unit_price) - (item.discount_amount || 0)
			}));

			supplyHistory = transRes.data || [];
			console.log(`[InventoryDetail] Loaded ${sales.length} sales and ${supplyHistory.length} transactions`);

			updateChart();
		} catch (err) {
			console.error('[InventoryDetail] Fatal fetch error:', err);
		} finally {
			console.log('[InventoryDetail] Fetch cycle complete');
			loading = false;
		}
	}

	async function updateThreshold() {
		savingThreshold = true;
		try {
			const { error } = await supabase.from('branch_inventory')
				.update({ low_stock_threshold: lowStockThreshold })
				.eq('product_id', activeInventory.product_id)
				.eq('branch_id', activeInventory.branch_id);
			
			if (error) throw error;
			if (activeInventory) activeInventory.low_stock_threshold = lowStockThreshold;
		} catch (err) {
			alert('Failed to update threshold');
		} finally {
			savingThreshold = false;
		}
	}

	function updateChart() {
		if (activeTab !== 'analytics' && activeTab !== 'overview') return;
		// Delay slightly to ensure canvas is rendered
		setTimeout(() => {
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

	$effect(() => { 
		if (inventoryId) fetchData(); 
	});
	
	$effect(() => { 
		if (chartPeriod || activeTab) updateChart(); 
	});

	onDestroy(() => { if (chart) chart.destroy(); });

	function formatCurrency(val: number | undefined | null) {
		if (val == null) return 'N/A';
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}

	// Last Supply Price calculation
	let lastSupplyPrice = $derived(supplyHistory.length > 0 ? supplyHistory[0].unit_cost : (product?.cost_price || null));
</script>

<svelte:head>
	<title>{product?.name || 'Product Detail'} Analytics</title>
</svelte:head>

<div class="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8 space-y-6">
	<!-- Header -->
	<div class="flex items-start justify-between">
		<div class="flex items-center gap-4">
			<a href="/inventory" class="p-2 hover:bg-gray-100 rounded-lg transition-colors text-gray-500 hover:text-gray-900">
				<ArrowLeft class="h-6 w-6" />
			</a>
			<div class="h-14 w-14 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm border border-indigo-100">
				<Package class="h-7 w-7" />
			</div>
			<div>
				<h1 class="text-2xl font-black text-gray-900">{product?.name || 'Loading...'}</h1>
				<p class="text-xs text-gray-500 font-bold uppercase tracking-widest mt-0.5">{product?.sku || 'No SKU'}</p>
			</div>
		</div>
	</div>

	{#if loading}
		<div class="flex flex-col items-center justify-center py-32 text-gray-400">
			<Loader2 class="h-10 w-10 animate-spin mb-4 text-indigo-600" />
			<p class="font-medium italic">Compiling audit and analytics data...</p>
		</div>
	{:else}
		<!-- Secondary Header with Stats -->
		<div class="grid grid-cols-2 lg:grid-cols-5 gap-4">
			<div class="p-4 bg-white rounded-2xl border border-gray-100 shadow-sm">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Total Stock</p>
				<p class="text-lg font-black text-gray-900">{batches.reduce((acc, b) => acc + b.stock_quantity, 0)} Units</p>
			</div>
			<div class="p-4 bg-white rounded-2xl border border-gray-100 shadow-sm font-black">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Selling Price</p>
				<p class="text-lg text-emerald-600">
					{activeInventory ? formatCurrency(activeInventory.selling_price) : 'N/A'}
				</p>
			</div>
			<div class="p-4 bg-white rounded-2xl border border-gray-100 shadow-sm">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Cost Price</p>
				<p class="text-lg font-black text-rose-600">{activeInventory ? formatCurrency(activeInventory.cost_price) : 'N/A'}</p>
			</div>
			<div class="p-4 bg-white rounded-2xl border border-gray-100 shadow-sm">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Last Sale</p>
				<p class="text-lg font-black text-gray-900">{sales[0] ? new Date(sales[0].sale_date).toLocaleDateString() : 'Never'}</p>
			</div>
			<div class="p-4 bg-indigo-50 rounded-2xl border border-indigo-100 shadow-sm">
				<p class="text-[10px] font-black text-indigo-400 uppercase tracking-widest mb-1">Low Stock Alert At</p>
				<div class="flex items-center gap-2">
					<input 
						type="number" 
						bind:value={lowStockThreshold} 
						class="w-16 text-lg font-black bg-transparent outline-none border-b border-indigo-200 focus:border-indigo-600 p-0 text-indigo-900"
					/>
					<button 
						onclick={updateThreshold} 
						disabled={savingThreshold}
						class="text-indigo-600 hover:text-indigo-800 transition-colors p-1"
						title="Save specific threshold"
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

		<!-- Page Content Container -->
		<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
			<!-- Tabs -->
			<div class="flex border-b px-6 bg-white overflow-x-auto no-scrollbar">
				{#each ['overview', 'batches', 'supply', 'sales', 'analytics'] as tab}
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

			<!-- Tab Panels -->
			<div class="p-6 bg-gray-50/30 min-h-[400px]">
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
												<p class="text-[10px] text-gray-400 font-bold uppercase">By: {sale.cashier_name}</p>
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
									Stock Expiry Summary
								</h3>
								<div class="space-y-4">
									{#each batches.filter(b => b.expiry_date).slice(0, 5) as batch}
										<div class="flex items-center justify-between border-b border-gray-50 pb-3 last:border-0 last:pb-0">
											<div>
												<p class="text-sm font-bold text-gray-900">Batch {batch.batch_no || 'N/A'}</p>
												<p class="text-[10px] text-gray-400 font-medium uppercase">{batch.stock_quantity} units remaining</p>
											</div>
											<div class="text-right">
												<p class="text-sm font-black {new Date(batch.expiry_date) < new Date(Date.now() + 90*24*60*60*1000) ? 'text-rose-600' : 'text-gray-700'}">
													{new Date(batch.expiry_date).toLocaleDateString()}
												</p>
												{#if new Date(batch.expiry_date) < new Date(Date.now() + 90*24*60*60*1000)}
													<span class="text-[8px] font-black bg-rose-50 text-rose-600 px-1.5 py-0.5 rounded uppercase">Urgent Alert</span>
												{/if}
											</div>
										</div>
									{:else}
										<p class="text-sm text-gray-500 italic py-4">No critical expiry data found</p>
									{/each}
								</div>
							</div>

							 <!-- Quick Sparkline Chart -->
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm md:col-span-2 flex flex-col h-[300px]">
								<h3 class="font-black text-gray-900 flex items-center gap-2 mb-4">
									<BarChart3 class="h-5 w-5 text-indigo-600" />
									30 Day Trend
								</h3>
								<div class="flex-1 relative min-h-0">
									<canvas bind:this={chartCanvas}></canvas>
								</div>
							</div>
						</div>

					{:else if activeTab === 'batches'}
						<div class="bg-white rounded-2xl border border-gray-100 overflow-hidden">
							<div class="overflow-x-auto">
								<table class="w-full text-left whitespace-nowrap min-w-[800px]">
									<thead class="bg-gray-50">
										<tr>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase">Batch Ref</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Pricing Settings</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Current Stock</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Supplier Mapping</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Supply Date</th>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase">Expiry Status</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each batches as batch}
											<tr class="hover:bg-gray-50/50 transition-colors">
												<td class="px-6 py-4">
													<p class="text-sm font-black text-gray-900">{batch.batch_no || 'Manual Entry'}</p>
													<p class="text-[10px] text-gray-400 font-bold uppercase" title="Inventory Block ID">{batch.id.split('-')[0]}</p>
												</td>
												<td class="px-4 py-4">
													<p class="text-sm font-black text-emerald-600">{formatCurrency(batch.selling_price)}</p>
													<p class="text-[10px] text-gray-400 font-medium italic">Unit Cost: {formatCurrency(batch.cost_price)}</p>
												</td>
												<td class="px-4 py-4">
													<div class="flex items-center gap-2">
														<div class="h-2 w-2 rounded-full {batch.stock_quantity > lowStockThreshold ? 'bg-green-500' : 'bg-red-500'}"></div>
														<p class="text-sm font-black text-gray-900">{batch.stock_quantity}</p>
													</div>
												</td>
												<td class="px-4 py-4">
													<div class="flex items-center gap-2">
														<div class="h-6 w-6 bg-gray-100 rounded-full flex justify-center items-center shrink-0">
															<Truck class="h-3 w-3 text-gray-500" />
														</div>
														<p class="text-xs font-bold text-gray-700 truncate max-w-[150px]">{batch.suppliers?.name || 'Unknown source'}</p>
													</div>
												</td>
												<td class="px-4 py-4 text-xs font-medium text-gray-500">
													{new Date(batch.created_at).toLocaleDateString()}
												</td>
												<td class="px-6 py-4">
													<p class="text-sm font-black {new Date(batch.expiry_date) < new Date() ? 'text-rose-600' : 'text-gray-700'}">
														{batch.expiry_date ? new Date(batch.expiry_date).toLocaleDateString() : 'Never'}
													</p>
												</td>
											</tr>
										{:else}
											<tr><td colspan="6" class="text-center py-10 text-gray-400 italic font-medium">No batch stock blocks are completely empty.</td></tr>
										{/each}
									</tbody>
								</table>
							</div>
						</div>

					{:else if activeTab === 'supply'}
						<div class="bg-white rounded-2xl border border-gray-100 overflow-hidden">
							<div class="p-5 bg-indigo-50 border-b border-indigo-100 flex items-center gap-3">
								<ClipboardList class="h-6 w-6 text-indigo-600" />
								<div>
									<h4 class="font-black text-indigo-900">Restock History</h4>
									<p class="text-xs font-medium text-indigo-700 tracking-wide">Detailed audit of every time this product's inventory was restocked</p>
								</div>
							</div>
							<div class="overflow-x-auto">
								<table class="w-full text-left whitespace-nowrap">
									<thead class="bg-gray-50">
										<tr>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase">Restock Date</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Quantity Added</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Unit Cost Logged</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Reference PO / Note</th>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase">Handled By</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each supplyHistory as log}
											<tr class="hover:bg-gray-50/50 transition-colors">
												<td class="px-6 py-4">
													<p class="text-sm font-bold text-gray-900">{new Date(log.created_at).toLocaleDateString()}</p>
													<p class="text-[10px] text-gray-400 font-medium">{new Date(log.created_at).toLocaleTimeString()}</p>
												</td>
												<td class="px-4 py-4 text-sm font-black text-emerald-600">+{log.quantity_delta} <span class="text-[10px] font-medium text-gray-400 ml-1">units</span></td>
												<td class="px-4 py-4 text-sm font-bold text-indigo-600">{formatCurrency(log.unit_cost)}</td>
												<td class="px-4 py-4 text-xs font-medium text-gray-500 max-w-xs truncate">{log.notes || log.reference_id || 'Direct Entry'}</td>
												<td class="px-6 py-4">
													<div class="flex items-center gap-2">
														<div class="h-6 w-6 bg-blue-50 text-blue-600 rounded-full flex justify-center items-center text-[10px] font-black">
															{(log.users?.full_name || 'Sys').charAt(0)}
														</div>
														<span class="text-xs font-bold text-gray-700">{log.users?.full_name || 'System Operator'}</span>
													</div>
												</td>
											</tr>
										{:else}
											<tr><td colspan="5" class="text-center py-10 text-gray-400 italic font-medium">No recorded restock history found involving supply orders.</td></tr>
										{/each}
									</tbody>
								</table>
							</div>
						</div>

					{:else if activeTab === 'sales'}
						<div class="bg-white rounded-2xl border border-gray-100 overflow-hidden">
							<div class="overflow-x-auto">
								<table class="w-full text-left whitespace-nowrap min-w-[800px]">
									<thead class="bg-gray-50">
										<tr>
											<th class="px-6 py-4 text-[10px] font-black text-gray-400 uppercase">Sale Date & Time</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Sale Code</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Qty Sold</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Unit Price</th>
											<th class="px-4 py-4 text-[10px] font-black text-gray-400 uppercase">Total Revenue</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each sales as sale}
											<tr class="hover:bg-gray-50/50 transition-colors">
												<td class="px-6 py-4">
													<p class="text-sm font-bold text-gray-900">{new Date(sale.sale_date).toLocaleDateString()}</p>
													<p class="text-[10px] text-gray-400 font-medium">{new Date(sale.sale_date).toLocaleTimeString()}</p>
												</td>
												<td class="px-4 py-4">
													<span class="text-xs bg-gray-100 text-gray-600 px-2.5 py-1 rounded-md font-bold font-mono">{sale.sales?.sale_number || 'UNKNOWN'}</span>
												</td>
												<td class="px-4 py-4 text-sm font-black text-gray-900 text-center bg-gray-50/50">{sale.quantity}</td>
												<td class="px-4 py-4 text-sm text-gray-500 font-medium border-l border-gray-50">{formatCurrency(sale.unit_price)}</td>
												<td class="px-4 py-4 text-sm font-black text-emerald-600">{formatCurrency(sale.total)}</td>
											</tr>
										{:else}
											<tr><td colspan="6" class="text-center py-10 text-gray-400 italic font-medium">This product has not been sold yet!</td></tr>
										{/each}
									</tbody>
								</table>
							</div>
						</div>

					{:else if activeTab === 'analytics'}
						<div class="space-y-6">
							<!-- Analytics KPI Cards -->
							<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 font-black">
								<div class="bg-emerald-50 p-6 rounded-2xl border border-emerald-100 text-center shadow-sm">
									<p class="text-[10px] text-emerald-600 uppercase tracking-widest mb-1">Max Daily Sale</p>
									<p class="text-3xl text-emerald-800">{Math.max(0, ...getAggregatedData(chartPeriod).values)} <span class="text-sm font-bold text-emerald-600">Units</span></p>
								</div>
								<div class="bg-indigo-50 p-6 rounded-2xl border border-indigo-100 text-center shadow-sm">
									<p class="text-[10px] text-indigo-600 uppercase tracking-widest mb-1">Total Period Revenue</p>
									<p class="text-3xl text-indigo-800 tracking-tight">{formatCurrency(sales.filter(s => new Date(s.sale_date) > new Date(Date.now() - (chartPeriod === '30d' ? 30 : chartPeriod === 'quarter' ? 90 : 365)*24*60*60*1000)).reduce((acc, s) => acc + s.total, 0))}</p>
								</div>
								<div class="bg-amber-50 p-6 rounded-2xl border border-amber-100 text-center shadow-sm">
									<p class="text-[10px] text-amber-600 uppercase tracking-widest mb-1">Velocity</p>
									<p class="text-3xl text-amber-800">{(sales.length / (chartPeriod === '30d' ? 30 : 90)).toFixed(1)} <span class="text-sm font-bold text-amber-600">Per Day</span></p>
								</div>
								<div class="bg-blue-50 p-6 rounded-2xl border border-blue-100 text-center shadow-sm">
									<p class="text-[10px] text-blue-600 uppercase tracking-widest mb-1">Total Sales Count</p>
									<p class="text-3xl text-blue-800">{sales.length} <span class="text-sm font-bold text-blue-600">Orders</span></p>
								</div>
							</div>

							<!-- Analytics Chart -->
							<div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col h-[500px]">
								<div class="flex items-center justify-between mb-6">
									<div>
										<h3 class="font-black text-gray-900 text-xl">Sales Performance Chart</h3>
										<p class="text-sm text-gray-400 font-medium">Historical trajectory of inventory movement</p>
									</div>
									<div class="flex gap-1 p-1 bg-gray-50 rounded-xl border border-gray-100">
										{#each ['30d', 'quarter', 'year', '5y'] as period}
											<button 
												onclick={() => chartPeriod = period as any}
												class="px-5 py-2 text-[10px] font-black uppercase tracking-widest rounded-lg transition-all {chartPeriod === period ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-100/50' : 'text-gray-400 hover:text-indigo-600'}"
											>
												{period}
											</button>
										{/each}
									</div>
								</div>
								<div class="flex-1 relative min-h-0 pt-4">
									<canvas bind:this={chartCanvas}></canvas>
								</div>
							</div>
						</div>
					{/if}
				</div>
			</div>
		</div>
	{/if}
</div>

<style>
	.no-scrollbar::-webkit-scrollbar { display: none; }
	.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
