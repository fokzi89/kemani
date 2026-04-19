<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { 
		ArrowLeft, Building2, Users, Package, ShoppingCart, 
		TrendingUp, AlertTriangle, Clock, Search, ChevronRight, 
		Download, DollarSign, Calendar, MapPin, Mail
	} from 'lucide-svelte';

	const branchId = $page.params.id;
	let branch = $state<any>(null);
	let stats = $state({
		totalSales: 0,
		salesCount: 0,
		staffCount: 0,
		productCount: 0,
		stockValue: 0,
		potentialProfit: 0,
		lowStockCount: 0,
		expiringSoonCount: 0
	});

	let activeTab = $state('overview');
	let loading = $state(true);

	// Multi-category data
	let sales = $state<any[]>([]);
	let staff = $state<any[]>([]);
	let products = $state<any[]>([]);
	let lowStockItems = $state<any[]>([]);
	let expiringItems = $state<any[]>([]);

	async function fetchData() {
		try {
			// 1. Fetch Branch info
			const { data: bData, error: bError } = await supabase
				.from('branches')
				.select('*')
				.eq('id', branchId)
				.single();
			if (bError) console.error('Branch fetch error:', bError);
			branch = bData;

			// 2. Fetch Staff
			const { data: sData, error: sError } = await supabase
				.from('users')
				.select('*')
				.eq('branch_id', branchId)
				.is('deleted_at', null);
			if (sError) console.error('Staff fetch error:', sError);
			staff = sData || [];
			stats.staffCount = staff.length;

			// 3. Fetch Products / Stock from branch_inventory
			const { data: biData, error: pError } = await supabase
				.from('branch_inventory')
				.select('*, products(*)')
				.eq('branch_id', branchId);
				
			if (pError) console.error('Products fetch error:', pError);
			
			// Map values for the remaining calculation logic
			products = (biData || []).map(bi => ({
				...bi.products,
				stock_quantity: bi.stock_quantity,
				selling_price: bi.selling_price,
				cost_price: bi.cost_price,
				low_stock_threshold: bi.low_stock_threshold,
				expiry_date: bi.expiry_date,
				expiry_alert_days: bi.expiry_alert_days
			}));
			stats.productCount = products.length;

			// Calculate stock value and profit
			let totalValue = 0;
			let totalProfit = 0;
			let lowStock: any[] = [];
			let expiring: any[] = [];
			const now = new Date();
			const thirtyDaysFromNow = new Date();
			thirtyDaysFromNow.setDate(now.getDate() + 30);

			for (const p of products) {
				const cost = p.cost_price || 0;
				const price = p.selling_price || 0;
				const qty = p.stock_quantity || 0;
				
				totalValue += cost * qty;
				totalProfit += (price - cost) * qty;

				if (qty <= (p.low_stock_threshold || 10)) {
					lowStock.push(p);
				}

				if (p.expiry_date) {
					const expiry = new Date(p.expiry_date);
					if (expiry <= thirtyDaysFromNow) {
						expiring.push(p);
					}
				}
			}
			stats.stockValue = totalValue;
			stats.potentialProfit = totalProfit;
			stats.lowStockCount = lowStock.length;
			stats.expiringSoonCount = expiring.length;
			lowStockItems = lowStock;
			expiringItems = expiring;

			// 4. Fetch Recent Sales — use explicit FK name to avoid ambiguous join
			const { data: slData, error: slError } = await supabase
				.from('sales')
				.select('id, sale_number, total_amount, created_at, cashier_id, users!cashier_id(full_name)')
				.eq('branch_id', branchId)
				.order('created_at', { ascending: false })
				.limit(10);
			if (slError) console.error('Sales fetch error:', slError);
			sales = (slData || []).map((s: any) => ({
				...s,
				cashier: s.users
			}));

			// 5. Sales totals
			const { data: salesAgg, error: aggError } = await supabase
				.from('sales')
				.select('total_amount')
				.eq('branch_id', branchId);
			if (aggError) console.error('Sales agg error:', aggError);
			stats.totalSales = (salesAgg || []).reduce((acc: number, s: any) => acc + (s.total_amount || 0), 0);
			stats.salesCount = (salesAgg || []).length;

		} catch (err) {
			console.error('Error fetching branch details:', err);
		} finally {
			loading = false;
		}
	}

	onMount(() => {
		fetchData();
	});

	function formatCurrency(val: number) {
		return new Intl.NumberFormat('en-NG', {
			style: 'currency',
			currency: branch?.currency || 'NGN',
			maximumFractionDigits: 0
		}).format(val);
	}
</script>

<div class="p-6 md:p-10 max-w-7xl mx-auto w-full">
	<!-- Header -->
	<div class="flex items-center gap-4 mb-8">
		<a href="/branches" class="p-2 hover:bg-white rounded-full transition-all border border-transparent hover:border-gray-200 text-gray-500">
			<ArrowLeft class="h-6 w-6" />
		</a>
		<div>
			<div class="flex items-center gap-2 text-sm text-gray-500 mb-1">
				<a href="/branches" class="hover:text-blue-600">Branch Management</a>
				<ChevronRight class="h-4 w-4" />
				<span class="font-medium text-gray-900">{branch?.name || 'Loading...'}</span>
			</div>
			<div class="flex items-center gap-3">
				<h1 class="text-3xl font-extrabold text-gray-900 tracking-tight">{branch?.name}</h1>
				<span class="px-3 py-1 bg-blue-50 text-blue-700 text-xs font-bold rounded-full border border-blue-100">
					{branch?.business_type?.replace('_', ' ').toUpperCase()}
				</span>
			</div>
		</div>
	</div>

	{#if loading}
		<div class="flex justify-center items-center py-20">
			<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600"></div>
		</div>
	{:else if !branch}
		<div class="p-10 text-center bg-white rounded-3xl border border-gray-100 shadow-sm">
			<p class="text-gray-500 font-medium">Branch not found.</p>
		</div>
	{:else}
		<!-- Stats Grid -->
		<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
			<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm transition-all hover:shadow-md group">
				<div class="flex items-center justify-between mb-4">
					<div class="h-12 w-12 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform">
						<DollarSign class="h-6 w-6" />
					</div>
					<span class="text-[10px] font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full uppercase">All Time</span>
				</div>
				<p class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Total Sales</p>
				<h3 class="text-2xl font-black text-gray-900">{formatCurrency(stats.totalSales)}</h3>
			</div>

			<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm transition-all hover:shadow-md group">
				<div class="flex items-center justify-between mb-4">
					<div class="h-12 w-12 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform">
						<TrendingUp class="h-6 w-6" />
					</div>
					<span class="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full uppercase">Profit</span>
				</div>
				<p class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Stock Margin</p>
				<h3 class="text-2xl font-black text-gray-900">{formatCurrency(stats.potentialProfit)}</h3>
			</div>

			<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm transition-all hover:shadow-md group">
				<div class="flex items-center justify-between mb-4">
					<div class="h-12 w-12 bg-amber-50 text-amber-600 rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform">
						<AlertTriangle class="h-6 w-6" />
					</div>
					<span class="text-[10px] font-bold text-amber-600 bg-amber-50 px-2 py-0.5 rounded-full uppercase">Alert</span>
				</div>
				<p class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Low Stock</p>
				<h3 class="text-2xl font-black text-gray-900">{stats.lowStockCount} <span class="text-xs text-gray-400 font-medium">Items</span></h3>
			</div>

			<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm transition-all hover:shadow-md group">
				<div class="flex items-center justify-between mb-4">
					<div class="h-12 w-12 bg-rose-50 text-rose-600 rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform">
						<Clock class="h-6 w-6" />
					</div>
					<span class="text-[10px] font-bold text-rose-600 bg-rose-50 px-2 py-0.5 rounded-full uppercase">Risk</span>
				</div>
				<p class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Expiring Soon</p>
				<h3 class="text-2xl font-black text-gray-900">{stats.expiringSoonCount} <span class="text-xs text-gray-400 font-medium">Items</span></h3>
			</div>
		</div>

		<!-- Navigation Tabs -->
		<div class="flex gap-1 bg-white p-1 rounded-2xl border border-gray-100 mb-8 self-start w-fit">
			{#each ['overview', 'sales', 'inventory', 'staff'] as tab}
				<button 
					onclick={() => activeTab = tab}
					class="px-6 py-2.5 rounded-xl text-sm font-bold transition-all {activeTab === tab ? 'bg-blue-600 text-white shadow-lg shadow-blue-200' : 'text-gray-500 hover:bg-gray-50'}"
				>
					{tab.charAt(0).toUpperCase() + tab.slice(1)}
				</button>
			{/each}
		</div>

		<!-- Tab Content -->
		<div class="animate-in fade-in slide-in-from-bottom-4 duration-500">
			{#if activeTab === 'overview'}
				<div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
					<!-- Recent Sales -->
					<div class="bg-white rounded-3xl border border-gray-100 shadow-sm overflow-hidden">
						<div class="p-6 border-b border-gray-50 flex justify-between items-center">
							<h3 class="font-black text-gray-900 flex items-center gap-2">
								<ShoppingCart class="h-5 w-5 text-blue-600" />
								Recent Sales
							</h3>
							<button class="text-xs font-bold text-blue-600 hover:underline">View All Sales</button>
						</div>
						<div class="overflow-x-auto">
							<table class="w-full text-left">
								<thead class="bg-gray-50/50">
									<tr>
										<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Sale ID</th>
										<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Date</th>
										<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Cashier</th>
										<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase text-right">Amount</th>
									</tr>
								</thead>
								<tbody class="divide-y divide-gray-50">
									{#each sales as sale}
										<tr class="hover:bg-gray-50/50">
											<td class="px-6 py-4 text-sm font-bold text-blue-600">{sale.sale_number}</td>
											<td class="px-6 py-4 text-xs text-gray-500">{new Date(sale.created_at).toLocaleDateString()}</td>
											<td class="px-6 py-4 text-xs font-medium text-gray-700">{sale.cashier?.full_name}</td>
											<td class="px-6 py-4 text-sm font-black text-gray-900 text-right">{formatCurrency(sale.total_amount)}</td>
										</tr>
									{:else}
										<tr>
											<td colspan="4" class="px-6 py-12 text-center text-gray-400 text-sm">No recent transactions</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					</div>

					<!-- Location Details & Quick Actions -->
					<div class="space-y-6">
						<div class="bg-white p-8 rounded-3xl border border-gray-100 shadow-sm">
							<h3 class="font-black text-gray-900 mb-6 flex items-center gap-2">
								<MapPin class="h-5 w-5 text-rose-500" />
								Branch Location
							</h3>
							<div class="space-y-4">
								<div class="flex items-start gap-4">
									<div class="h-10 w-10 shrink-0 bg-rose-50 text-rose-600 rounded-xl flex items-center justify-center">
										<MapPin class="h-5 w-5" />
									</div>
									<div>
										<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-0.5">Address</p>
										<p class="text-sm font-bold text-gray-900 leading-relaxed">{branch.address || 'No address provided'}</p>
										<p class="text-xs text-gray-500 mt-1">{branch.city ? `${branch.city}, ` : ''}{branch.state ? `${branch.state}, ` : ''}{branch.country || ''}</p>
									</div>
								</div>
								
								<div class="pt-4 border-t border-gray-50 flex gap-4">
									<div class="flex-1">
										<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-0.5">Latitude</p>
										<p class="text-sm font-bold text-gray-900">{branch.latitude || 'N/A'}</p>
									</div>
									<div class="flex-1">
										<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-0.5">Longitude</p>
										<p class="text-sm font-bold text-gray-900">{branch.longitude || 'N/A'}</p>
									</div>
								</div>
							</div>
						</div>

						<div class="bg-gradient-to-br from-blue-600 to-indigo-700 p-8 rounded-3xl text-white shadow-xl shadow-blue-200">
							<h3 class="font-black text-white/90 mb-2">Inventory Value</h3>
							<p class="text-xs text-white/60 mb-6">Estimated cost value of current active stock in this branch.</p>
							<div class="flex items-end justify-between">
								<h2 class="text-4xl font-black">{formatCurrency(stats.stockValue)}</h2>
								<Package class="h-12 w-12 text-white/20" />
							</div>
						</div>
					</div>
				</div>

			{:else if activeTab === 'sales'}
				<div class="bg-white rounded-3xl border border-gray-100 shadow-sm p-8 text-center py-20">
					<ShoppingCart class="h-12 w-12 text-gray-200 mx-auto mb-4" />
					<h3 class="text-lg font-bold text-gray-900">Detailed Sales Report</h3>
					<p class="text-gray-500 text-sm max-w-sm mx-auto mt-2 italic">Comprehensive sales dashboard for this branch is coming soon with date range filtering and performance charts.</p>
				</div>

			{:else if activeTab === 'inventory'}
				<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
					<div class="lg:col-span-2 space-y-8">
						<!-- Low Stock -->
						<div class="bg-white rounded-3xl border border-amber-100 shadow-sm overflow-hidden">
							<div class="p-6 border-b border-amber-50 flex justify-between items-center bg-amber-50/30">
								<h3 class="font-black text-amber-900 flex items-center gap-2">
									<AlertTriangle class="h-5 w-5 text-amber-600" />
									Low Stock Report
								</h3>
								<span class="px-3 py-1 bg-amber-100 text-amber-700 text-[10px] font-black rounded-full uppercase">Action Required</span>
							</div>
							<div class="overflow-x-auto">
								<table class="w-full text-left">
									<thead class="bg-gray-50/50">
										<tr>
											<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Product</th>
											<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Current Qty</th>
											<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Threshold</th>
											<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase text-right">Status</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each lowStockItems as item}
											<tr class="hover:bg-amber-50/30 transition-colors">
												<td class="px-6 py-4">
													<p class="text-sm font-bold text-gray-900">{item.name}</p>
													<p class="text-[10px] text-gray-400 font-medium">Barcode: {item.barcode || 'N/A'}</p>
												</td>
												<td class="px-6 py-4 text-sm font-black text-amber-700">{item.stock_quantity}</td>
												<td class="px-6 py-4 text-sm text-gray-400">{item.low_stock_threshold || 10}</td>
												<td class="px-6 py-4 text-right">
													<span class="inline-flex px-2 py-0.5 rounded-full text-[10px] font-black uppercase text-amber-600 bg-amber-50 border border-amber-100">Low</span>
												</td>
											</tr>
										{:else}
											<tr>
												<td colspan="4" class="px-6 py-12 text-center text-gray-400 text-sm italic">Inventory levels healthy! No low stock detected.</td>
											</tr>
										{/each}
									</tbody>
								</table>
							</div>
						</div>

						<!-- Expiry Report -->
						<div class="bg-white rounded-3xl border border-rose-100 shadow-sm overflow-hidden">
							<div class="p-6 border-b border-rose-50 flex justify-between items-center bg-rose-50/30">
								<h3 class="font-black text-rose-900 flex items-center gap-2">
									<Clock class="h-5 w-5 text-rose-600" />
									Expiration Report
								</h3>
								<span class="px-3 py-1 bg-rose-100 text-rose-700 text-[10px] font-black rounded-full uppercase">30 Day Alert</span>
							</div>
							<div class="overflow-x-auto">
								<table class="w-full text-left">
									<thead class="bg-gray-50/50">
										<tr>
											<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Product</th>
											<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase">Expiry Date</th>
											<th class="px-6 py-3 text-[10px] font-black text-gray-400 uppercase text-right">Risk</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each expiringItems as item}
											<tr class="hover:bg-rose-50/30 transition-colors">
												<td class="px-6 py-4">
													<p class="text-sm font-bold text-gray-900">{item.name}</p>
													<p class="text-[10px] text-gray-400 font-medium">Barcode: {item.barcode || 'N/A'}</p>
												</td>
												<td class="px-6 py-4">
													<span class="text-sm font-black text-rose-600">{new Date(item.expiry_date).toLocaleDateString()}</span>
												</td>
												<td class="px-6 py-4 text-right">
													<span class="inline-flex px-2 py-0.5 rounded-full text-[10px] font-black uppercase text-rose-600 bg-rose-50 border border-rose-100">Critical</span>
												</td>
											</tr>
										{:else}
											<tr>
												<td colspan="3" class="px-6 py-12 text-center text-gray-400 text-sm italic">No products expiring in the next 30 days.</td>
											</tr>
										{/each}
									</tbody>
								</table>
							</div>
						</div>
					</div>

					<div class="space-y-6">
						<div class="bg-white p-8 rounded-3xl border border-gray-100 shadow-sm">
							<h3 class="font-black text-gray-900 mb-6 flex items-center gap-2">
								<DollarSign class="h-5 w-5 text-emerald-500" />
								Stock Value Breakdown
							</h3>
							<div class="space-y-5">
								<div class="flex justify-between items-end">
									<span class="text-xs font-bold text-gray-400 uppercase tracking-widest">Total Products</span>
									<span class="text-lg font-black text-gray-900">{stats.productCount}</span>
								</div>
								<div class="flex justify-between items-end">
									<span class="text-xs font-bold text-gray-400 uppercase tracking-widest">Cost Value</span>
									<span class="text-lg font-black text-gray-900">{formatCurrency(stats.stockValue)}</span>
								</div>
								<div class="flex justify-between items-end pt-4 border-t border-gray-50">
									<span class="text-xs font-bold text-emerald-600 uppercase tracking-widest">Potential Profit</span>
									<span class="text-xl font-black text-emerald-600">{formatCurrency(stats.potentialProfit)}</span>
								</div>
							</div>
						</div>
					</div>
				</div>

			{:else if activeTab === 'staff'}
				<div class="bg-white rounded-3xl border border-gray-100 shadow-sm overflow-hidden">
					<div class="p-8 border-b border-gray-50 flex justify-between items-center">
						<h3 class="font-black text-gray-900 text-xl flex items-center gap-2">
							<Users class="h-6 w-6 text-blue-600" />
							Branch Staff ({staff.length})
						</h3>
						<button class="bg-blue-600 text-white px-5 py-2.5 rounded-xl text-sm font-bold hover:bg-blue-700 transition shadow-lg shadow-blue-100">
							Assign New Staff
						</button>
					</div>
					<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-8">
						{#each staff as person}
							<div class="p-6 rounded-2xl border border-gray-100 bg-gray-50/50 hover:bg-white hover:shadow-xl hover:border-blue-100 transition-all group">
								<div class="flex items-center gap-4 mb-4">
									<div class="h-14 w-14 rounded-full bg-blue-100 border-2 border-white shadow-sm flex items-center justify-center font-black text-blue-600 overflow-hidden">
										{#if person.avatar_url}
											<img src={person.avatar_url} alt="" class="h-full w-full object-cover" />
										{:else}
											{person.full_name?.charAt(0)}
										{/if}
									</div>
									<div>
										<h4 class="font-black text-gray-900">{person.full_name}</h4>
										<p class="text-xs font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full inline-block mt-1 uppercase tracking-tighter">
											{person.role?.replace('_', ' ')}
										</p>
									</div>
								</div>
								<div class="space-y-2 mb-6">
									<div class="flex items-center gap-2 text-xs text-gray-500 font-medium lowercase">
										<ShoppingCart class="h-3.5 w-3.5 text-gray-400 group-hover:text-blue-500" />
										{person.email || 'No email provided'}
									</div>
									<div class="flex items-center gap-2 text-xs text-gray-500 font-medium">
										<Calendar class="h-3.5 w-3.5 text-gray-400 group-hover:text-blue-500" />
										Joined {new Date(person.created_at).toLocaleDateString()}
									</div>
								</div>
								<button class="w-full py-2.5 rounded-xl text-xs font-bold text-gray-600 border border-gray-200 hover:bg-white hover:text-blue-600 hover:border-blue-200 transition-all flex items-center justify-center gap-2">
									Manage Profile
									<ChevronRight class="h-3 w-3" />
								</button>
							</div>
						{:else}
							<div class="col-span-full py-20 text-center text-gray-500 font-medium">
								No staff members assigned to this branch yet.
							</div>
						{/each}
					</div>
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	:global(.scrollbar-thin::-webkit-scrollbar) {
		width: 6px;
	}
	:global(.scrollbar-thin::-webkit-scrollbar-track) {
		background: transparent;
	}
	:global(.scrollbar-thin::-webkit-scrollbar-thumb) {
		background: #e2e8f0;
		border-radius: 10px;
	}
</style>
