<script lang="ts">
	import { onMount } from 'svelte';

	type Customer = {
		id: string;
		full_name: string;
		email?: string;
		phone: string;
		loyalty_points_balance: number;
		total_orders: number;
		total_spent: number;
		last_order_date?: string;
		created_at: string;
	};

	let customers: Customer[] = [];
	let isLoading = true;
	let error = '';
	let searchQuery = '';
	let sortBy: 'name' | 'orders' | 'spent' | 'points' | 'recent' = 'recent';
	let showRegisterModal = false;

	// TODO: Get from auth session
	let tenantId = 'your-tenant-id';

	onMount(async () => {
		await loadCustomers();
	});

	async function loadCustomers() {
		isLoading = true;
		error = '';

		try {
			const params = new URLSearchParams();
			if (searchQuery) params.set('search', searchQuery);

			const response = await fetch(`/api/customers?${params}`);
			const data = await response.json();

			if (response.ok) {
				customers = data.customers || [];
				sortCustomers();
			} else {
				error = data.error || 'Failed to load customers';
			}
		} catch (err: any) {
			error = err.message || 'Failed to load customers';
		} finally {
			isLoading = false;
		}
	}

	function sortCustomers() {
		switch (sortBy) {
			case 'name':
				customers.sort((a, b) => a.full_name.localeCompare(b.full_name));
				break;
			case 'orders':
				customers.sort((a, b) => b.total_orders - a.total_orders);
				break;
			case 'spent':
				customers.sort((a, b) => b.total_spent - a.total_spent);
				break;
			case 'points':
				customers.sort((a, b) => b.loyalty_points_balance - a.loyalty_points_balance);
				break;
			case 'recent':
				customers.sort(
					(a, b) =>
						new Date(b.last_order_date || b.created_at).getTime() -
						new Date(a.last_order_date || a.created_at).getTime()
				);
				break;
		}
		customers = customers; // Trigger reactivity
	}

	function handleSearch() {
		loadCustomers();
	}

	function handleSortChange() {
		sortCustomers();
	}

	function formatDate(dateString?: string): string {
		if (!dateString) return 'Never';
		const date = new Date(dateString);
		return date.toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}

	function handleRegisterCustomer() {
		showRegisterModal = true;
	}

	function closeRegisterModal() {
		showRegisterModal = false;
	}

	// Stats
	$: totalCustomers = customers.length;
	$: totalRevenue = customers.reduce((sum, c) => sum + c.total_spent, 0);
	$: averageOrderValue = totalRevenue / customers.reduce((sum, c) => sum + c.total_orders, 0) || 0;
	$: totalLoyaltyPoints = customers.reduce((sum, c) => sum + c.loyalty_points_balance, 0);
</script>

<svelte:head>
	<title>Customer Management - Admin</title>
	<meta name="description" content="Manage your customers and view their statistics" />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<h1 class="text-2xl font-bold text-gray-900 dark:text-white">Customer Management</h1>
				<button
					on:click={handleRegisterCustomer}
					class="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					+ Add Customer
				</button>
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<!-- Stats Cards -->
		<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Customers</p>
				<p class="text-3xl font-bold text-gray-900 dark:text-white">{totalCustomers}</p>
			</div>
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Revenue</p>
				<p class="text-3xl font-bold text-emerald-600 dark:text-emerald-400">
					₦{totalRevenue.toLocaleString()}
				</p>
			</div>
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Avg Order Value</p>
				<p class="text-3xl font-bold text-blue-600 dark:text-blue-400">
					₦{averageOrderValue.toLocaleString(undefined, { maximumFractionDigits: 0 })}
				</p>
			</div>
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Loyalty Points</p>
				<p class="text-3xl font-bold text-purple-600 dark:text-purple-400">
					{totalLoyaltyPoints.toLocaleString()}
				</p>
			</div>
		</div>

		<!-- Search and Filters -->
		<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 mb-6">
			<div class="flex flex-wrap gap-4 items-center">
				<div class="flex-1 min-w-[300px]">
					<input
						type="search"
						bind:value={searchQuery}
						on:keydown={(e) => e.key === 'Enter' && handleSearch()}
						placeholder="Search by name, phone, or email..."
						class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-emerald-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
					/>
				</div>
				<button
					on:click={handleSearch}
					class="px-6 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					Search
				</button>
				<div class="flex items-center gap-2">
					<label class="text-sm text-gray-700 dark:text-gray-300">Sort by:</label>
					<select
						bind:value={sortBy}
						on:change={handleSortChange}
						class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
					>
						<option value="recent">Most Recent</option>
						<option value="name">Name A-Z</option>
						<option value="orders">Most Orders</option>
						<option value="spent">Highest Spender</option>
						<option value="points">Most Points</option>
					</select>
				</div>
			</div>
		</div>

		<!-- Customers Table -->
		<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm overflow-hidden">
			{#if isLoading}
				<div class="text-center py-12">
					<div
						class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-gray-200 border-t-emerald-600"
					></div>
					<p class="mt-4 text-gray-600 dark:text-gray-400">Loading customers...</p>
				</div>
			{:else if error}
				<div class="text-center py-12">
					<p class="text-red-600 dark:text-red-400">{error}</p>
					<button
						on:click={loadCustomers}
						class="mt-4 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
					>
						Try Again
					</button>
				</div>
			{:else if customers.length === 0}
				<div class="text-center py-12">
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
							d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
						/>
					</svg>
					<h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">No customers yet</h3>
					<p class="text-gray-600 dark:text-gray-400 mb-6">
						Start by adding your first customer
					</p>
					<button
						on:click={handleRegisterCustomer}
						class="px-6 py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
					>
						Add First Customer
					</button>
				</div>
			{:else}
				<div class="overflow-x-auto">
					<table class="w-full">
						<thead class="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
							<tr>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Customer
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Contact
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Orders
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Total Spent
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Loyalty Points
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Last Order
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Actions
								</th>
							</tr>
						</thead>
						<tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
							{#each customers as customer}
								<tr class="hover:bg-gray-50 dark:hover:bg-gray-700/50">
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="flex items-center">
											<div
												class="flex-shrink-0 h-10 w-10 bg-emerald-100 dark:bg-emerald-900/20 rounded-full flex items-center justify-center"
											>
												<span class="text-emerald-600 dark:text-emerald-400 font-semibold">
													{customer.full_name.charAt(0).toUpperCase()}
												</span>
											</div>
											<div class="ml-4">
												<div class="text-sm font-medium text-gray-900 dark:text-white">
													{customer.full_name}
												</div>
												<div class="text-xs text-gray-500 dark:text-gray-400">
													Joined {formatDate(customer.created_at)}
												</div>
											</div>
										</div>
									</td>
									<td class="px-6 py-4">
										<div class="text-sm text-gray-900 dark:text-white">{customer.phone}</div>
										{#if customer.email}
											<div class="text-xs text-gray-500 dark:text-gray-400">{customer.email}</div>
										{/if}
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-sm font-semibold text-gray-900 dark:text-white">
											{customer.total_orders}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-sm font-semibold text-emerald-600 dark:text-emerald-400">
											₦{customer.total_spent.toLocaleString()}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-sm font-semibold text-purple-600 dark:text-purple-400">
											{customer.loyalty_points_balance}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-sm text-gray-900 dark:text-white">
											{formatDate(customer.last_order_date)}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap text-sm">
										<button
											class="text-emerald-600 dark:text-emerald-400 hover:underline mr-3"
											on:click={() => alert(`View customer details: ${customer.id}`)}
										>
											View
										</button>
										<button
											class="text-blue-600 dark:text-blue-400 hover:underline"
											on:click={() => alert(`View orders for: ${customer.full_name}`)}
										>
											Orders
										</button>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</div>
	</div>
</div>

<!-- Register Customer Modal -->
{#if showRegisterModal}
	<div
		class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
		on:click={closeRegisterModal}
	>
		<div
			class="bg-white dark:bg-gray-800 rounded-lg p-8 max-w-md w-full mx-4"
			on:click|stopPropagation
		>
			<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Add New Customer</h2>

			<div class="space-y-4">
				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
						Full Name *
					</label>
					<input
						type="text"
						placeholder="John Doe"
						class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
					/>
				</div>

				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
						Phone Number *
					</label>
					<input
						type="tel"
						placeholder="+234 800 000 0000"
						class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
					/>
				</div>

				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
						Email Address
					</label>
					<input
						type="email"
						placeholder="john@example.com"
						class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
					/>
				</div>

				<div class="flex gap-4 pt-4">
					<button
						on:click={closeRegisterModal}
						class="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition"
					>
						Cancel
					</button>
					<button
						on:click={() => {
							alert('Customer registration will be implemented');
							closeRegisterModal();
						}}
						class="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
					>
						Add Customer
					</button>
				</div>
			</div>
		</div>
	</div>
{/if}
