<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';

	// The tenant is identified by the host (Approach 2)
	export let data: { tenant: any };
	$: tenantSlug = data.tenant.slug;

	type Customer = {
		id: string;
		tenant_id: string;
		full_name: string;
		email?: string;
		phone: string;
		loyalty_points_balance: number;
		total_orders: number;
		total_spent: number;
		last_order_date?: string;
		created_at: string;
	};

	type Address = {
		id: string;
		address_line1: string;
		address_line2?: string;
		city: string;
		state: string;
		postal_code?: string;
		country: string;
		is_default: boolean;
	};

	type Order = {
		id: string;
		order_number: string;
		status: string;
		total_amount: number;
		created_at: string;
	};

	let customer: Customer | null = null;
	let addresses: Address[] = [];
	let orders: Order[] = [];
	let isLoading = true;
	let activeTab: 'profile' | 'orders' | 'addresses' | 'loyalty' = 'profile';
	let error = '';

	// TODO: Replace with actual authentication
	let isAuthenticated = false;
	let customerId = ''; // Will be set from auth session

	onMount(async () => {
		// TODO: Check authentication
		// For now, we'll simulate being logged out
		isAuthenticated = false;

		if (!isAuthenticated) {
			// Show login prompt
			isLoading = false;
			return;
		}

		await loadCustomerData();
	});

	async function loadCustomerData() {
		isLoading = true;
		error = '';

		try {
			await Promise.all([loadCustomer(), loadAddresses(), loadOrders()]);
		} catch (err: any) {
			error = err.message || 'Failed to load profile';
		} finally {
			isLoading = false;
		}
	}

	async function loadCustomer() {
		const response = await fetch(`/api/customers/${customerId}`);
		const data = await response.json();

		if (response.ok) {
			customer = data.customer;
		} else {
			throw new Error(data.error || 'Failed to load customer');
		}
	}

	async function loadAddresses() {
		const response = await fetch(`/api/customers/${customerId}/addresses`);
		const data = await response.json();

		if (response.ok) {
			addresses = data.addresses || [];
		}
	}

	async function loadOrders() {
		const response = await fetch(`/api/orders?customer_id=${customerId}`);
		const data = await response.json();

		if (response.ok) {
			orders = data.orders || [];
		}
	}

	function formatDate(dateString: string): string {
		const date = new Date(dateString);
		return date.toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}

	function getStatusColor(status: string): string {
		const colors: Record<string, string> = {
			pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400',
			confirmed: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400',
			processing: 'bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-400',
			ready_for_pickup:
				'bg-indigo-100 text-indigo-800 dark:bg-indigo-900/20 dark:text-indigo-400',
			out_for_delivery: 'bg-cyan-100 text-cyan-800 dark:bg-cyan-900/20 dark:text-cyan-400',
			delivered: 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400',
			cancelled: 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400',
			refunded: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
		};
		return colors[status] || colors.pending;
	}

	function handleLogin() {
		// TODO: Implement actual login
		alert('Login functionality will be implemented with OTP authentication');
	}
</script>

<svelte:head>
	<title>My Profile - {customer?.full_name || 'Customer'}</title>
	<meta name="description" content="Manage your profile, orders, and loyalty points" />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<a href="/" class="text-emerald-600 dark:text-emerald-400 hover:underline">
					← Back to Shop
				</a>
				<h1 class="text-2xl font-bold text-gray-900 dark:text-white">My Profile</h1>
				<div class="w-24"></div>
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if !isAuthenticated}
			<!-- Login Required State -->
			<div class="max-w-md mx-auto text-center py-16">
				<svg
					class="w-24 h-24 mx-auto mb-6 text-gray-400"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
					/>
				</svg>
				<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Login Required</h2>
				<p class="text-gray-600 dark:text-gray-400 mb-8">
					Please log in to view your profile and manage your orders
				</p>
				<button
					on:click={handleLogin}
					class="px-6 py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					Log In with Phone Number
				</button>
			</div>
		{:else if isLoading}
			<!-- Loading State -->
			<div class="text-center py-12">
				<div
					class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-gray-200 border-t-emerald-600"
				></div>
				<p class="mt-4 text-gray-600 dark:text-gray-400">Loading profile...</p>
			</div>
		{:else if error}
			<!-- Error State -->
			<div class="text-center py-12">
				<p class="text-red-600 dark:text-red-400">{error}</p>
				<button
					on:click={loadCustomerData}
					class="mt-4 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					Try Again
				</button>
			</div>
		{:else if customer}
			<!-- Profile Content -->
			<div class="grid lg:grid-cols-4 gap-8">
				<!-- Sidebar -->
				<div class="lg:col-span-1">
					<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
						<div class="text-center mb-6">
							<div
								class="w-20 h-20 mx-auto mb-4 bg-emerald-100 dark:bg-emerald-900/20 rounded-full flex items-center justify-center"
							>
								<span class="text-3xl font-bold text-emerald-600 dark:text-emerald-400">
									{customer.full_name.charAt(0).toUpperCase()}
								</span>
							</div>
							<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-1">
								{customer.full_name}
							</h2>
							<p class="text-sm text-gray-600 dark:text-gray-400">{customer.phone}</p>
							{#if customer.email}
								<p class="text-sm text-gray-600 dark:text-gray-400">{customer.email}</p>
							{/if}
						</div>

						<!-- Quick Stats -->
						<div class="space-y-3 pt-6 border-t border-gray-200 dark:border-gray-700">
							<div class="flex justify-between">
								<span class="text-sm text-gray-600 dark:text-gray-400">Total Orders</span>
								<span class="font-semibold text-gray-900 dark:text-white"
									>{customer.total_orders}</span
								>
							</div>
							<div class="flex justify-between">
								<span class="text-sm text-gray-600 dark:text-gray-400">Total Spent</span>
								<span class="font-semibold text-gray-900 dark:text-white"
									>₦{customer.total_spent.toLocaleString()}</span
								>
							</div>
							<div class="flex justify-between">
								<span class="text-sm text-gray-600 dark:text-gray-400">Loyalty Points</span>
								<span class="font-bold text-emerald-600 dark:text-emerald-400"
									>{customer.loyalty_points_balance}</span
								>
							</div>
						</div>

						<!-- Navigation -->
						<nav class="mt-6 space-y-2">
							<button
								on:click={() => (activeTab = 'profile')}
								class="w-full text-left px-4 py-2 rounded-lg transition {activeTab === 'profile'
									? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-semibold'
									: 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'}"
							>
								Profile Info
							</button>
							<button
								on:click={() => (activeTab = 'orders')}
								class="w-full text-left px-4 py-2 rounded-lg transition {activeTab === 'orders'
									? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-semibold'
									: 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'}"
							>
								Order History
							</button>
							<button
								on:click={() => (activeTab = 'addresses')}
								class="w-full text-left px-4 py-2 rounded-lg transition {activeTab === 'addresses'
									? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-semibold'
									: 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'}"
							>
								Saved Addresses
							</button>
							<button
								on:click={() => (activeTab = 'loyalty')}
								class="w-full text-left px-4 py-2 rounded-lg transition {activeTab === 'loyalty'
									? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-semibold'
									: 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'}"
							>
								Loyalty Points
							</button>
						</nav>
					</div>
				</div>

				<!-- Main Content -->
				<div class="lg:col-span-3">
					{#if activeTab === 'profile'}
						<!-- Profile Info Tab -->
						<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
							<h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">
								Profile Information
							</h3>

							<div class="space-y-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
										Full Name
									</label>
									<input
										type="text"
										value={customer.full_name}
										disabled
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white"
									/>
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
										Phone Number
									</label>
									<input
										type="tel"
										value={customer.phone}
										disabled
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white"
									/>
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
										Email Address
									</label>
									<input
										type="email"
										value={customer.email || ''}
										placeholder="Not provided"
										disabled
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white"
									/>
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
										Member Since
									</label>
									<input
										type="text"
										value={formatDate(customer.created_at)}
										disabled
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white"
									/>
								</div>

								<!-- Edit functionality placeholder -->
								<div class="pt-4">
									<button
										disabled
										class="px-6 py-2 bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 rounded-lg cursor-not-allowed"
									>
										Edit Profile (Coming Soon)
									</button>
								</div>
							</div>
						</div>
					{:else if activeTab === 'orders'}
						<!-- Order History Tab -->
						<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
							<h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">Order History</h3>

							{#if orders.length === 0}
								<div class="text-center py-12">
									<p class="text-gray-600 dark:text-gray-400 mb-4">No orders yet</p>
									<a
										href="/"
										class="inline-block px-6 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
									>
										Start Shopping
									</a>
								</div>
							{:else}
								<div class="space-y-4">
									{#each orders as order}
										<div
											class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition"
										>
											<div class="flex justify-between items-start mb-2">
												<div>
													<h4 class="font-semibold text-gray-900 dark:text-white">
														{order.order_number}
													</h4>
													<p class="text-sm text-gray-600 dark:text-gray-400">
														{formatDate(order.created_at)}
													</p>
												</div>
												<span class="px-3 py-1 rounded-full text-xs font-semibold {getStatusColor(order.status)}">
													{order.status.replace('_', ' ').toUpperCase()}
												</span>
											</div>

											<div class="flex justify-between items-center pt-3 border-t border-gray-200 dark:border-gray-700">
												<p class="text-lg font-bold text-emerald-600 dark:text-emerald-400">
													₦{order.total_amount.toLocaleString()}
												</p>
												<a
													href="/track/{order.id}"
													class="px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition text-sm"
												>
													Track Order
												</a>
											</div>
										</div>
									{/each}
								</div>
							{/if}
						</div>
					{:else if activeTab === 'addresses'}
						<!-- Saved Addresses Tab -->
						<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
							<div class="flex justify-between items-center mb-6">
								<h3 class="text-xl font-bold text-gray-900 dark:text-white">Saved Addresses</h3>
								<button
									disabled
									class="px-4 py-2 bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 rounded-lg cursor-not-allowed text-sm"
								>
									Add New Address
								</button>
							</div>

							{#if addresses.length === 0}
								<div class="text-center py-12">
									<p class="text-gray-600 dark:text-gray-400">No saved addresses</p>
								</div>
							{:else}
								<div class="grid md:grid-cols-2 gap-4">
									{#each addresses as address}
										<div
											class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 relative"
										>
											{#if address.is_default}
												<span
													class="absolute top-2 right-2 px-2 py-1 bg-emerald-100 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 text-xs rounded"
												>
													Default
												</span>
											{/if}
											<p class="font-medium text-gray-900 dark:text-white mb-2">
												{address.address_line1}
											</p>
											{#if address.address_line2}
												<p class="text-sm text-gray-600 dark:text-gray-400">{address.address_line2}</p>
											{/if}
											<p class="text-sm text-gray-600 dark:text-gray-400">
												{address.city}, {address.state}
												{#if address.postal_code}{address.postal_code}{/if}
											</p>
											<p class="text-sm text-gray-600 dark:text-gray-400">{address.country}</p>
										</div>
									{/each}
								</div>
							{/if}
						</div>
					{:else if activeTab === 'loyalty'}
						<!-- Loyalty Points Tab -->
						<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
							<h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">Loyalty Points</h3>

							<!-- Points Balance Card -->
							<div
								class="bg-gradient-to-r from-emerald-500 to-emerald-600 rounded-lg p-6 mb-6 text-white"
							>
								<p class="text-sm opacity-90 mb-2">Current Balance</p>
								<p class="text-5xl font-bold mb-4">{customer.loyalty_points_balance}</p>
								<p class="text-sm opacity-90">
									= ₦{(customer.loyalty_points_balance * 100).toLocaleString()} in rewards
								</p>
							</div>

							<!-- How It Works -->
							<div class="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
								<h4 class="font-semibold text-blue-900 dark:text-blue-200 mb-2">
									How Loyalty Points Work
								</h4>
								<ul class="text-sm text-blue-800 dark:text-blue-300 space-y-1">
									<li>• Earn 1 point for every ₦100 spent</li>
									<li>• Redeem points for discounts (1 point = ₦100 off)</li>
									<li>• Points are awarded when your order is delivered</li>
									<li>• Use points at checkout to save on your next purchase</li>
								</ul>
							</div>

							<!-- Transaction History Placeholder -->
							<div>
								<h4 class="font-semibold text-gray-900 dark:text-white mb-4">
									Recent Transactions
								</h4>
								<p class="text-center text-gray-600 dark:text-gray-400 py-8">
									Transaction history coming soon
								</p>
							</div>
						</div>
					{/if}
				</div>
			</div>
		{/if}
	</div>
</div>
