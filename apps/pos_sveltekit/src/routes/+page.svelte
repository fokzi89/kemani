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

		const cachedProfile = localStorage.getItem(`pos_user_profile_${session.user.id}`);
		const userData = cachedProfile ? JSON.parse(cachedProfile) : null;
		
		if (userData?.tenants) {
			tenant = Array.isArray(userData.tenants) ? userData.tenants[0] : userData.tenants;
			if (tenant?.id) {
				await loadStats(tenant.id);
			}
		}

		loading = false;
	});

	async function loadStats(tenantId: string) {
		try {
			// Run queries in parallel for better performance
			const [
				{ count: productsCount },
				{ count: customersCount },
				{ data: todaySalesData },
				{ data: monthlySalesData },
				{ count: lowStockCount },
				{ count: pendingCount }
			] = await Promise.all([
				// 1. Get product count
				supabase.from('products').select('*', { count: 'exact', head: true }).eq('tenant_id', tenantId),
				// 2. Get customer count
				supabase.from('customers').select('*', { count: 'exact', head: true }).eq('tenant_id', tenantId),
				// 3. Get today's sales
				supabase.from('sales').select('total_amount').eq('tenant_id', tenantId).gte('created_at', new Date().toISOString().split('T')[0]),
				// 4. Get monthly revenue
				supabase.from('sales').select('total_amount').eq('tenant_id', tenantId).gte('created_at', new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()),
				// 5. Get low stock products (Use product_stock_status view)
				supabase.from('product_stock_status').select('*', { count: 'exact', head: true }).eq('tenant_id', tenantId).eq('stock_status', 'low_stock'),
				// 6. Get pending orders
				supabase.from('orders').select('*', { count: 'exact', head: true }).eq('tenant_id', tenantId).in('status', ['pending', 'processing'])
			]);

			const todaySalesTotal = todaySalesData?.reduce((sum, sale) => sum + (parseFloat(sale.total_amount) || 0), 0) || 0;
			const monthlyTotal = monthlySalesData?.reduce((sum, sale) => sum + (parseFloat(sale.total_amount) || 0), 0) || 0;

			stats = {
				totalProducts: productsCount || 0,
				totalCustomers: customersCount || 0,
				todaySales: todaySalesTotal,
				monthlyRevenue: monthlyTotal,
				lowStock: lowStockCount || 0,
				pendingOrders: pendingCount || 0
			};
		} catch (err) {
			console.error('Error loading dashboard stats:', err);
		} finally {
			loading = false;
		}
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-lg shadow p-6">
			<h2 class="text-2xl font-bold text-gray-900">Dashboard</h2>
			<p class="text-gray-600 mt-1">Welcome back! Here's your business overview.</p>
		</div>

		<!-- Stats Grid -->
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
			<!-- Total Products -->
			<div class="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm relative overflow-hidden group hover:shadow-md transition-shadow">
				{#if loading}
					<div class="absolute inset-0 skeleton-shimmer"></div>
				{/if}
				<div class="flex items-center justify-between relative z-10">
					<div>
						<p class="text-xs font-black text-gray-400 uppercase tracking-widest">Total Products</p>
						{#if loading}
							<div class="h-9 w-20 bg-gray-100 rounded-lg mt-2"></div>
						{:else}
							<p class="text-3xl font-black text-gray-900 mt-1">{stats.totalProducts.toLocaleString()}</p>
						{/if}
					</div>
					<div class="bg-blue-50 p-4 rounded-2xl group-hover:scale-110 transition-transform">
						<Package class="h-6 w-6 text-blue-600" />
					</div>
				</div>
			</div>

			<!-- Total Customers -->
			<div class="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm relative overflow-hidden group hover:shadow-md transition-shadow">
				{#if loading}
					<div class="absolute inset-0 skeleton-shimmer"></div>
				{/if}
				<div class="flex items-center justify-between relative z-10">
					<div>
						<p class="text-xs font-black text-gray-400 uppercase tracking-widest">Total Customers</p>
						{#if loading}
							<div class="h-9 w-20 bg-gray-100 rounded-lg mt-2"></div>
						{:else}
							<p class="text-3xl font-black text-gray-900 mt-1">{stats.totalCustomers.toLocaleString()}</p>
						{/if}
					</div>
					<div class="bg-emerald-50 p-4 rounded-2xl group-hover:scale-110 transition-transform">
						<Users class="h-6 w-6 text-emerald-600" />
					</div>
				</div>
			</div>

			<!-- Today's Sales -->
			<div class="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm relative overflow-hidden group hover:shadow-md transition-shadow">
				{#if loading}
					<div class="absolute inset-0 skeleton-shimmer"></div>
				{/if}
				<div class="flex items-center justify-between relative z-10">
					<div>
						<p class="text-xs font-black text-gray-400 uppercase tracking-widest">Today's Sales</p>
						{#if loading}
							<div class="h-9 w-32 bg-gray-100 rounded-lg mt-2"></div>
						{:else}
							<p class="text-3xl font-black text-gray-900 mt-1">₦{stats.todaySales.toLocaleString()}</p>
						{/if}
					</div>
					<div class="bg-purple-50 p-4 rounded-2xl group-hover:scale-110 transition-transform">
						<ShoppingCart class="h-6 w-6 text-purple-600" />
					</div>
				</div>
			</div>

			<!-- Monthly Revenue -->
			<div class="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm relative overflow-hidden group hover:shadow-md transition-shadow">
				{#if loading}
					<div class="absolute inset-0 skeleton-shimmer"></div>
				{/if}
				<div class="flex items-center justify-between relative z-10">
					<div>
						<p class="text-xs font-black text-gray-400 uppercase tracking-widest">Monthly Revenue</p>
						{#if loading}
							<div class="h-9 w-32 bg-gray-100 rounded-lg mt-2"></div>
						{:else}
							<p class="text-3xl font-black text-gray-900 mt-1">₦{stats.monthlyRevenue.toLocaleString()}</p>
						{/if}
					</div>
					<div class="bg-blue-50 p-4 rounded-2xl group-hover:scale-110 transition-transform">
						<DollarSign class="h-6 w-6 text-blue-600" />
					</div>
				</div>
			</div>

			<!-- Low Stock -->
			<div class="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm relative overflow-hidden group hover:shadow-md transition-shadow">
				{#if loading}
					<div class="absolute inset-0 skeleton-shimmer"></div>
				{/if}
				<div class="flex items-center justify-between relative z-10">
					<div>
						<p class="text-xs font-black text-gray-400 uppercase tracking-widest">Low Stock Alert</p>
						{#if loading}
							<div class="h-9 w-20 bg-gray-100 rounded-lg mt-2"></div>
						{:else}
							<p class="text-3xl font-black {stats.lowStock > 0 ? 'text-red-600' : 'text-gray-900'} mt-1">{stats.lowStock}</p>
						{/if}
					</div>
					<div class="bg-red-50 p-4 rounded-2xl group-hover:scale-110 transition-transform">
						<AlertCircle class="h-6 w-6 text-red-600" />
					</div>
				</div>
			</div>

			<!-- Pending Orders -->
			<div class="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm relative overflow-hidden group hover:shadow-md transition-shadow">
				{#if loading}
					<div class="absolute inset-0 skeleton-shimmer"></div>
				{/if}
				<div class="flex items-center justify-between relative z-10">
					<div>
						<p class="text-xs font-black text-gray-400 uppercase tracking-widest">Pending Orders</p>
						{#if loading}
							<div class="h-9 w-20 bg-gray-100 rounded-lg mt-2"></div>
						{:else}
							<p class="text-3xl font-black text-gray-900 mt-1">{stats.pendingOrders}</p>
						{/if}
					</div>
					<div class="bg-orange-50 p-4 rounded-2xl group-hover:scale-110 transition-transform">
						<ShoppingCart class="h-6 w-6 text-orange-600" />
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
	</div>
</div>

<style>
	.skeleton-shimmer {
		background: linear-gradient(
			90deg,
			rgba(255, 255, 255, 0) 0%,
			rgba(255, 255, 255, 0.6) 50%,
			rgba(255, 255, 255, 0) 100%
		);
		background-size: 200% 100%;
		animation: shimmer 1.5s infinite;
		background-color: rgba(0, 0, 0, 0.03);
	}

	@keyframes shimmer {
		0% { background-position: -200% 0; }
		100% { background-position: 200% 0; }
	}
</style>
