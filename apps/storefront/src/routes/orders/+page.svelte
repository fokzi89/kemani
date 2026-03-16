<script lang="ts">
	import { onMount } from 'svelte';

	type OrderStatus =
		| 'pending'
		| 'confirmed'
		| 'processing'
		| 'ready_for_pickup'
		| 'out_for_delivery'
		| 'delivered'
		| 'cancelled'
		| 'refunded';

	type Order = {
		id: string;
		order_number: string;
		status: OrderStatus;
		order_type: 'delivery' | 'pickup';
		customer_name: string;
		customer_phone: string;
		total_amount: number;
		payment_status: string;
		payment_method: string;
		created_at: string;
		updated_at: string;
		items_count?: number;
	};

	let orders: Order[] = [];
	let isLoading = true;
	let error = '';
	let searchQuery = '';
	let filterStatus: OrderStatus | 'all' = 'all';
	let sortBy: 'newest' | 'oldest' | 'amount_high' | 'amount_low' = 'newest';
	let selectedOrder: Order | null = null;
	let showStatusModal = false;
	let newStatus: OrderStatus = 'confirmed';

	// TODO: Get from auth session
	let tenantId = 'your-tenant-id';

	onMount(async () => {
		await loadOrders();
	});

	async function loadOrders() {
		isLoading = true;
		error = '';

		try {
			const params = new URLSearchParams({ tenant_id: tenantId });
			if (searchQuery) params.set('search', searchQuery);
			if (filterStatus !== 'all') params.set('status', filterStatus);

			const response = await fetch(`/api/orders?${params}`);
			const data = await response.json();

			if (response.ok) {
				orders = data.orders || [];
				sortOrders();
			} else {
				error = data.error || 'Failed to load orders';
			}
		} catch (err: any) {
			error = err.message || 'Failed to load orders';
		} finally {
			isLoading = false;
		}
	}

	function sortOrders() {
		switch (sortBy) {
			case 'newest':
				orders.sort(
					(a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
				);
				break;
			case 'oldest':
				orders.sort(
					(a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
				);
				break;
			case 'amount_high':
				orders.sort((a, b) => b.total_amount - a.total_amount);
				break;
			case 'amount_low':
				orders.sort((a, b) => a.total_amount - b.total_amount);
				break;
		}
		orders = orders; // Trigger reactivity
	}

	function handleSearch() {
		loadOrders();
	}

	function handleFilterChange() {
		loadOrders();
	}

	function handleSortChange() {
		sortOrders();
	}

	function formatDate(dateString: string): string {
		const date = new Date(dateString);
		return date.toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'short',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function getStatusColor(status: OrderStatus): string {
		const colors: Record<OrderStatus, string> = {
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
		return colors[status];
	}

	function openStatusModal(order: Order) {
		selectedOrder = order;
		newStatus = order.status;
		showStatusModal = true;
	}

	function closeStatusModal() {
		selectedOrder = null;
		showStatusModal = false;
	}

	async function updateOrderStatus() {
		if (!selectedOrder) return;

		try {
			const response = await fetch(`/api/orders/${selectedOrder.id}/status`, {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ status: newStatus })
			});

			const data = await response.json();

			if (response.ok) {
				alert('Order status updated successfully!');
				closeStatusModal();
				await loadOrders();
			} else {
				alert(data.error || 'Failed to update order status');
			}
		} catch (err: any) {
			alert(err.message || 'Failed to update order status');
		}
	}

	// Stats
	$: totalOrders = orders.length;
	$: totalRevenue = orders.reduce((sum, o) => sum + o.total_amount, 0);
	$: pendingOrders = orders.filter((o) => o.status === 'pending').length;
	$: deliveredOrders = orders.filter((o) => o.status === 'delivered').length;

	const statusOptions: { value: OrderStatus | 'all'; label: string }[] = [
		{ value: 'all', label: 'All Orders' },
		{ value: 'pending', label: 'Pending' },
		{ value: 'confirmed', label: 'Confirmed' },
		{ value: 'processing', label: 'Processing' },
		{ value: 'ready_for_pickup', label: 'Ready for Pickup' },
		{ value: 'out_for_delivery', label: 'Out for Delivery' },
		{ value: 'delivered', label: 'Delivered' },
		{ value: 'cancelled', label: 'Cancelled' }
	];

	const nextStatusOptions: Record<OrderStatus, { value: OrderStatus; label: string }[]> = {
		pending: [
			{ value: 'confirmed', label: 'Confirm Order' },
			{ value: 'cancelled', label: 'Cancel Order' }
		],
		confirmed: [
			{ value: 'processing', label: 'Start Processing' },
			{ value: 'cancelled', label: 'Cancel Order' }
		],
		processing: [
			{ value: 'ready_for_pickup', label: 'Ready for Pickup' },
			{ value: 'out_for_delivery', label: 'Send for Delivery' }
		],
		ready_for_pickup: [
			{ value: 'delivered', label: 'Mark as Picked Up' },
			{ value: 'processing', label: 'Back to Processing' }
		],
		out_for_delivery: [
			{ value: 'delivered', label: 'Mark as Delivered' },
			{ value: 'processing', label: 'Back to Processing' }
		],
		delivered: [{ value: 'refunded', label: 'Refund Order' }],
		cancelled: [],
		refunded: []
	};
</script>

<svelte:head>
	<title>Order Management - Admin</title>
	<meta name="description" content="Manage your orders and track fulfillment" />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<h1 class="text-2xl font-bold text-gray-900 dark:text-white">Order Management</h1>
				<button
					on:click={loadOrders}
					class="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					<svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
						/>
					</svg>
					Refresh
				</button>
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<!-- Stats Cards -->
		<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Orders</p>
				<p class="text-3xl font-bold text-gray-900 dark:text-white">{totalOrders}</p>
			</div>
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Revenue</p>
				<p class="text-3xl font-bold text-emerald-600 dark:text-emerald-400">
					₦{totalRevenue.toLocaleString()}
				</p>
			</div>
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Pending Orders</p>
				<p class="text-3xl font-bold text-yellow-600 dark:text-yellow-400">{pendingOrders}</p>
			</div>
			<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Delivered</p>
				<p class="text-3xl font-bold text-green-600 dark:text-green-400">{deliveredOrders}</p>
			</div>
		</div>

		<!-- Filters -->
		<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 mb-6">
			<div class="grid md:grid-cols-3 gap-4">
				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						Search Orders
					</label>
					<div class="flex gap-2">
						<input
							type="search"
							bind:value={searchQuery}
							on:keydown={(e) => e.key === 'Enter' && handleSearch()}
							placeholder="Order number or customer name..."
							class="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-emerald-500 bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
						/>
						<button
							on:click={handleSearch}
							class="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
						>
							Search
						</button>
					</div>
				</div>

				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						Status Filter
					</label>
					<select
						bind:value={filterStatus}
						on:change={handleFilterChange}
						class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
					>
						{#each statusOptions as option}
							<option value={option.value}>{option.label}</option>
						{/each}
					</select>
				</div>

				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						Sort By
					</label>
					<select
						bind:value={sortBy}
						on:change={handleSortChange}
						class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
					>
						<option value="newest">Newest First</option>
						<option value="oldest">Oldest First</option>
						<option value="amount_high">Highest Amount</option>
						<option value="amount_low">Lowest Amount</option>
					</select>
				</div>
			</div>
		</div>

		<!-- Orders Table -->
		<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm overflow-hidden">
			{#if isLoading}
				<div class="text-center py-12">
					<div
						class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-gray-200 border-t-emerald-600"
					></div>
					<p class="mt-4 text-gray-600 dark:text-gray-400">Loading orders...</p>
				</div>
			{:else if error}
				<div class="text-center py-12">
					<p class="text-red-600 dark:text-red-400">{error}</p>
					<button
						on:click={loadOrders}
						class="mt-4 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
					>
						Try Again
					</button>
				</div>
			{:else if orders.length === 0}
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
							d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
						/>
					</svg>
					<h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">No orders found</h3>
					<p class="text-gray-600 dark:text-gray-400">
						{filterStatus !== 'all'
							? 'No orders match your current filter'
							: 'Orders will appear here once customers start placing them'}
					</p>
				</div>
			{:else}
				<div class="overflow-x-auto">
					<table class="w-full">
						<thead class="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
							<tr>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Order
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Customer
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Type
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Status
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Amount
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Payment
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Date
								</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
									Actions
								</th>
							</tr>
						</thead>
						<tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
							{#each orders as order}
								<tr class="hover:bg-gray-50 dark:hover:bg-gray-700/50">
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-sm font-medium text-gray-900 dark:text-white">
											{order.order_number}
										</div>
										{#if order.items_count}
											<div class="text-xs text-gray-500 dark:text-gray-400">
												{order.items_count} item(s)
											</div>
										{/if}
									</td>
									<td class="px-6 py-4">
										<div class="text-sm font-medium text-gray-900 dark:text-white">
											{order.customer_name}
										</div>
										<div class="text-xs text-gray-500 dark:text-gray-400">
											{order.customer_phone}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<span
											class="px-2 py-1 text-xs font-semibold rounded-full {order.order_type ===
											'delivery'
												? 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400'
												: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'}"
										>
											{order.order_type === 'delivery' ? '🚚 Delivery' : '📦 Pickup'}
										</span>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<span class="px-3 py-1 text-xs font-semibold rounded-full {getStatusColor(order.status)}">
											{order.status.replace('_', ' ').toUpperCase()}
										</span>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-sm font-bold text-emerald-600 dark:text-emerald-400">
											₦{order.total_amount.toLocaleString()}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-xs text-gray-900 dark:text-white capitalize">
											{order.payment_method.replace('_', ' ')}
										</div>
										<div
											class="text-xs {order.payment_status === 'paid'
												? 'text-green-600 dark:text-green-400'
												: 'text-yellow-600 dark:text-yellow-400'} capitalize"
										>
											{order.payment_status}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap">
										<div class="text-xs text-gray-900 dark:text-white">
											{formatDate(order.created_at)}
										</div>
									</td>
									<td class="px-6 py-4 whitespace-nowrap text-sm">
										<button
											on:click={() => window.open(`/track/${order.id}`, '_blank')}
											class="text-blue-600 dark:text-blue-400 hover:underline mr-3"
										>
											View
										</button>
										{#if nextStatusOptions[order.status].length > 0}
											<button
												on:click={() => openStatusModal(order)}
												class="text-emerald-600 dark:text-emerald-400 hover:underline"
											>
												Update
											</button>
										{/if}
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

<!-- Update Status Modal -->
{#if showStatusModal && selectedOrder}
	<div
		class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
		on:click={closeStatusModal}
	>
		<div
			class="bg-white dark:bg-gray-800 rounded-lg p-8 max-w-md w-full mx-4"
			on:click|stopPropagation
		>
			<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Update Order Status</h2>

			<div class="mb-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-2">Order Number</p>
				<p class="text-lg font-semibold text-gray-900 dark:text-white">
					{selectedOrder.order_number}
				</p>
			</div>

			<div class="mb-6">
				<p class="text-sm text-gray-600 dark:text-gray-400 mb-2">Current Status</p>
				<span class="px-3 py-1 text-sm font-semibold rounded-full {getStatusColor(selectedOrder.status)}">
					{selectedOrder.status.replace('_', ' ').toUpperCase()}
				</span>
			</div>

			<div class="mb-6">
				<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
					New Status
				</label>
				<select
					bind:value={newStatus}
					class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white"
				>
					<option value={selectedOrder.status} disabled>Select new status...</option>
					{#each nextStatusOptions[selectedOrder.status] as option}
						<option value={option.value}>{option.label}</option>
					{/each}
				</select>
			</div>

			<div class="flex gap-4">
				<button
					on:click={closeStatusModal}
					class="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition"
				>
					Cancel
				</button>
				<button
					on:click={updateOrderStatus}
					disabled={newStatus === selectedOrder.status}
					class="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
				>
					Update Status
				</button>
			</div>
		</div>
	</div>
{/if}
