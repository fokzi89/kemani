<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Package, Users, ShoppingCart, DollarSign, TrendingUp, AlertCircle } from 'lucide-svelte';

	let tenant = $state(null);
	let stats = $state({
		totalProducts: 0,
		totalCustomers: 0,
		todaySales: 0,
		monthlyRevenue: 0,
		lowStock: 0,
		pendingOrders: 0
	});
	let loading = $state(true);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();

		if (!session) {
			goto('/auth/login');
			return;
		}

		// Get user and tenant info
		const { data: userData } = await supabase
			.from('users')
			.select('*, tenants(*)')
			.eq('id', session.user.id)
			.single();

		if (userData?.tenants) {
			tenant = userData.tenants;
			await loadStats(tenant.id);
		}

		loading = false;
	});

	async function loadStats(tenantId: string) {
		// Get product count
		const { count: productsCount } = await supabase
			.from('products')
			.select('*', { count: 'exact', head: true })
			.eq('tenant_id', tenantId);

		// Get customer count
		const { count: customersCount } = await supabase
			.from('customers')
			.select('*', { count: 'exact', head: true })
			.eq('tenant_id', tenantId);

		// Get today's sales
		const today = new Date().toISOString().split('T')[0];
		const { data: todaySalesData } = await supabase
			.from('sales')
			.select('total_amount')
			.eq('tenant_id', tenantId)
			.gte('created_at', `${today}T00:00:00`)
			.lt('created_at', `${today}T23:59:59`);

		const todaySalesTotal = todaySalesData?.reduce((sum, sale) => sum + parseFloat(sale.total_amount), 0) || 0;

		// Get monthly revenue
		const firstDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();
		const { data: monthlySalesData } = await supabase
			.from('sales')
			.select('total_amount')
			.eq('tenant_id', tenantId)
			.gte('created_at', firstDayOfMonth);

		const monthlyTotal = monthlySalesData?.reduce((sum, sale) => sum + parseFloat(sale.total_amount), 0) || 0;

		// Get low stock products
		const { count: lowStockCount } = await supabase
			.from('products')
			.select('*', { count: 'exact', head: true })
			.eq('tenant_id', tenantId)
			.lt('stock_quantity', 10);

		// Get pending orders
		const { count: pendingCount } = await supabase
			.from('orders')
			.select('*', { count: 'exact', head: true })
			.eq('tenant_id', tenantId)
			.in('status', ['pending', 'processing']);

		stats = {
			totalProducts: productsCount || 0,
			totalCustomers: customersCount || 0,
			todaySales: todaySalesTotal,
			monthlyRevenue: monthlyTotal,
			lowStock: lowStockCount || 0,
			pendingOrders: pendingCount || 0
		};
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-lg shadow p-6">
			<h2 class="text-2xl font-bold text-gray-900">Dashboard</h2>
			<p class="text-gray-600 mt-1">Welcome back! Here's your business overview.</p>
		</div>

		{#if loading}
			<div class="bg-white rounded-lg shadow p-12 text-center">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
				<p class="mt-4 text-gray-600">Loading dashboard...</p>
			</div>
		{:else}
			<!-- Stats Grid -->
			<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				<!-- Total Products -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between">
						<div>
							<p class="text-sm font-medium text-gray-600">Total Products</p>
							<p class="text-3xl font-bold text-gray-900 mt-2">{stats.totalProducts}</p>
						</div>
						<div class="bg-blue-100 p-3 rounded-full">
							<Package class="h-6 w-6 text-blue-600" />
						</div>
					</div>
				</div>

				<!-- Total Customers -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between">
						<div>
							<p class="text-sm font-medium text-gray-600">Total Customers</p>
							<p class="text-3xl font-bold text-gray-900 mt-2">{stats.totalCustomers}</p>
						</div>
						<div class="bg-green-100 p-3 rounded-full">
							<Users class="h-6 w-6 text-green-600" />
						</div>
					</div>
				</div>

				<!-- Today's Sales -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between">
						<div>
							<p class="text-sm font-medium text-gray-600">Today's Sales</p>
							<p class="text-3xl font-bold text-gray-900 mt-2">₦{stats.todaySales.toLocaleString()}</p>
						</div>
						<div class="bg-purple-100 p-3 rounded-full">
							<ShoppingCart class="h-6 w-6 text-purple-600" />
						</div>
					</div>
				</div>

				<!-- Monthly Revenue -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between">
						<div>
							<p class="text-sm font-medium text-gray-600">Monthly Revenue</p>
							<p class="text-3xl font-bold text-gray-900 mt-2">₦{stats.monthlyRevenue.toLocaleString()}</p>
						</div>
						<div class="bg-emerald-100 p-3 rounded-full">
							<DollarSign class="h-6 w-6 text-emerald-600" />
						</div>
					</div>
				</div>

				<!-- Low Stock -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between">
						<div>
							<p class="text-sm font-medium text-gray-600">Low Stock Items</p>
							<p class="text-3xl font-bold text-gray-900 mt-2">{stats.lowStock}</p>
						</div>
						<div class="bg-orange-100 p-3 rounded-full">
							<AlertCircle class="h-6 w-6 text-orange-600" />
						</div>
					</div>
				</div>

				<!-- Pending Orders -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between">
						<div>
							<p class="text-sm font-medium text-gray-600">Pending Orders</p>
							<p class="text-3xl font-bold text-gray-900 mt-2">{stats.pendingOrders}</p>
						</div>
						<div class="bg-yellow-100 p-3 rounded-full">
							<TrendingUp class="h-6 w-6 text-yellow-600" />
						</div>
					</div>
				</div>
			</div>

			<!-- Quick Actions -->
			<div class="bg-white rounded-lg shadow p-6">
				<h3 class="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
				<div class="grid grid-cols-2 md:grid-cols-4 gap-4">
					<a
						href="/pos"
						class="flex flex-col items-center justify-center p-4 bg-primary-50 hover:bg-primary-100 rounded-lg transition-colors"
					>
						<ShoppingCart class="h-8 w-8 text-primary-600 mb-2" />
						<span class="text-sm font-medium text-primary-900">New Sale</span>
					</a>
					<a
						href="/products"
						class="flex flex-col items-center justify-center p-4 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors"
					>
						<Package class="h-8 w-8 text-blue-600 mb-2" />
						<span class="text-sm font-medium text-blue-900">Manage Products</span>
					</a>
					<a
						href="/customers"
						class="flex flex-col items-center justify-center p-4 bg-green-50 hover:bg-green-100 rounded-lg transition-colors"
					>
						<Users class="h-8 w-8 text-green-600 mb-2" />
						<span class="text-sm font-medium text-green-900">View Customers</span>
					</a>
					<a
						href="/orders"
						class="flex flex-col items-center justify-center p-4 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors"
					>
						<TrendingUp class="h-8 w-8 text-purple-600 mb-2" />
						<span class="text-sm font-medium text-purple-900">View Orders</span>
					</a>
				</div>
			</div>
		{/if}
	</div>
</div>
