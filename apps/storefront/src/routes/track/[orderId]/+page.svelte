<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';

	let orderId = $page.params.orderId;

	type OrderStatus =
		| 'pending'
		| 'confirmed'
		| 'processing'
		| 'ready_for_pickup'
		| 'out_for_delivery'
		| 'delivered'
		| 'cancelled'
		| 'refunded';

	type OrderItem = {
		product_name: string;
		quantity: number;
		unit_price: number;
		total_price: number;
	};

	type Order = {
		id: string;
		order_number: string;
		status: OrderStatus;
		order_type: 'delivery' | 'pickup';
		created_at: string;
		updated_at: string;
		items: OrderItem[];
		subtotal: number;
		tax_amount: number;
		delivery_fee: number;
		loyalty_points_discount: number;
		total_amount: number;
		payment_method: string;
		payment_status: string;
		customer_name?: string;
		customer_phone?: string;
		delivery_address?: string;
		estimated_delivery?: string;
		tracking_notes?: string;
	};

	let order: Order | null = null;
	let isLoading = true;
	let error = '';

	onMount(async () => {
		await loadOrder();
	});

	async function loadOrder() {
		isLoading = true;
		error = '';

		try {
			const response = await fetch(`/api/track/${orderId}`);
			const data = await response.json();

			if (response.ok) {
				order = data.order;
			} else {
				error = data.error || 'Order not found';
			}
		} catch (err: any) {
			error = err.message || 'Failed to load order';
		} finally {
			isLoading = false;
		}
	}

	const statusConfig: Record<
		OrderStatus,
		{ label: string; color: string; icon: string; description: string }
	> = {
		pending: {
			label: 'Pending',
			color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400',
			icon: '⏳',
			description: 'Your order is awaiting confirmation'
		},
		confirmed: {
			label: 'Confirmed',
			color: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400',
			icon: '✓',
			description: 'Your order has been confirmed and is being prepared'
		},
		processing: {
			label: 'Processing',
			color: 'bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-400',
			icon: '⚙️',
			description: 'Your order is being prepared'
		},
		ready_for_pickup: {
			label: 'Ready for Pickup',
			color: 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900/20 dark:text-indigo-400',
			icon: '📦',
			description: 'Your order is ready to be picked up'
		},
		out_for_delivery: {
			label: 'Out for Delivery',
			color: 'bg-cyan-100 text-cyan-800 dark:bg-cyan-900/20 dark:text-cyan-400',
			icon: '🚚',
			description: 'Your order is on its way to you'
		},
		delivered: {
			label: 'Delivered',
			color: 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400',
			icon: '✅',
			description: 'Your order has been delivered'
		},
		cancelled: {
			label: 'Cancelled',
			color: 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400',
			icon: '✕',
			description: 'This order has been cancelled'
		},
		refunded: {
			label: 'Refunded',
			color: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
			icon: '↩',
			description: 'This order has been refunded'
		}
	};

	function getStatusInfo(status: OrderStatus) {
		return statusConfig[status] || statusConfig.pending;
	}

	function formatDate(dateString: string): string {
		const date = new Date(dateString);
		return date.toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'long',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function getProgressPercentage(status: OrderStatus): number {
		const statusOrder: OrderStatus[] = [
			'pending',
			'confirmed',
			'processing',
			'ready_for_pickup',
			'out_for_delivery',
			'delivered'
		];
		const index = statusOrder.indexOf(status);
		if (index === -1) return 0;
		return ((index + 1) / statusOrder.length) * 100;
	}
</script>

<svelte:head>
	<title>Track Order - {order?.order_number || orderId}</title>
	<meta name="description" content="Track your order status and delivery information" />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-center items-center h-16">
				<h1 class="text-2xl font-bold text-gray-900 dark:text-white">Order Tracking</h1>
			</div>
		</div>
	</header>

	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if isLoading}
			<!-- Loading State -->
			<div class="text-center py-12">
				<div
					class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-gray-200 border-t-emerald-600"
				></div>
				<p class="mt-4 text-gray-600 dark:text-gray-400">Loading order details...</p>
			</div>
		{:else if error}
			<!-- Error State -->
			<div class="text-center py-12">
				<svg
					class="w-24 h-24 mx-auto mb-6 text-red-400"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
					/>
				</svg>
				<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Order Not Found</h2>
				<p class="text-gray-600 dark:text-gray-400 mb-8">{error}</p>
			</div>
		{:else if order}
			<!-- Order Details -->
			<div class="space-y-6">
				<!-- Order Header -->
				<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
					<div class="flex items-start justify-between mb-4">
						<div>
							<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
								{order.order_number}
							</h2>
							<p class="text-sm text-gray-600 dark:text-gray-400">
								Placed on {formatDate(order.created_at)}
							</p>
						</div>
						<div>
							{@const statusInfo = getStatusInfo(order.status)}
							<span class="px-4 py-2 rounded-full text-sm font-semibold {statusInfo.color}">
								{statusInfo.icon} {statusInfo.label}
							</span>
						</div>
					</div>

					<!-- Status Description -->
					{@const statusInfo = getStatusInfo(order.status)}
					<div
						class="p-4 bg-gray-50 dark:bg-gray-900/50 rounded-lg border-l-4 border-emerald-600 mb-4"
					>
						<p class="text-gray-700 dark:text-gray-300">{statusInfo.description}</p>
					</div>

					<!-- Progress Bar (for non-cancelled/refunded orders) -->
					{#if !['cancelled', 'refunded'].includes(order.status)}
						<div class="mt-6">
							<div class="relative">
								<div class="overflow-hidden h-2 mb-4 text-xs flex rounded-full bg-gray-200 dark:bg-gray-700">
									<div
										style="width: {getProgressPercentage(order.status)}%"
										class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-emerald-600 transition-all duration-500"
									></div>
								</div>
							</div>
						</div>
					{/if}
				</div>

				<!-- Order Type & Delivery Info -->
				<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
					<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4">
						{order.order_type === 'delivery' ? 'Delivery' : 'Pickup'} Information
					</h3>

					<div class="space-y-3">
						{#if order.customer_name}
							<div>
								<p class="text-sm text-gray-500 dark:text-gray-400">Customer Name</p>
								<p class="text-gray-900 dark:text-white font-medium">{order.customer_name}</p>
							</div>
						{/if}

						{#if order.customer_phone}
							<div>
								<p class="text-sm text-gray-500 dark:text-gray-400">Contact Phone</p>
								<p class="text-gray-900 dark:text-white font-medium">{order.customer_phone}</p>
							</div>
						{/if}

						{#if order.order_type === 'delivery' && order.delivery_address}
							<div>
								<p class="text-sm text-gray-500 dark:text-gray-400">Delivery Address</p>
								<p class="text-gray-900 dark:text-white">{order.delivery_address}</p>
							</div>
						{/if}

						{#if order.estimated_delivery}
							<div>
								<p class="text-sm text-gray-500 dark:text-gray-400">Estimated Delivery</p>
								<p class="text-gray-900 dark:text-white font-medium">{order.estimated_delivery}</p>
							</div>
						{/if}
					</div>

					{#if order.tracking_notes}
						<div class="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
							<p class="text-sm text-blue-800 dark:text-blue-200">{order.tracking_notes}</p>
						</div>
					{/if}
				</div>

				<!-- Order Items -->
				<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
					<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4">Order Items</h3>

					<div class="space-y-3">
						{#each order.items as item}
							<div class="flex justify-between items-center py-3 border-b border-gray-200 dark:border-gray-700 last:border-0">
								<div class="flex-1">
									<p class="font-medium text-gray-900 dark:text-white">{item.product_name}</p>
									<p class="text-sm text-gray-500 dark:text-gray-400">
										Quantity: {item.quantity} × ₦{item.unit_price.toLocaleString()}
									</p>
								</div>
								<p class="font-semibold text-gray-900 dark:text-white">
									₦{item.total_price.toLocaleString()}
								</p>
							</div>
						{/each}
					</div>
				</div>

				<!-- Payment Summary -->
				<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
					<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4">Payment Summary</h3>

					<div class="space-y-3">
						<div class="flex justify-between text-gray-700 dark:text-gray-300">
							<span>Subtotal</span>
							<span>₦{order.subtotal.toLocaleString()}</span>
						</div>

						<div class="flex justify-between text-gray-700 dark:text-gray-300">
							<span>Tax (7.5% VAT)</span>
							<span>₦{order.tax_amount.toLocaleString(undefined, { maximumFractionDigits: 2 })}</span>
						</div>

						{#if order.delivery_fee > 0}
							<div class="flex justify-between text-gray-700 dark:text-gray-300">
								<span>Delivery Fee</span>
								<span>₦{order.delivery_fee.toLocaleString()}</span>
							</div>
						{/if}

						{#if order.loyalty_points_discount > 0}
							<div class="flex justify-between text-emerald-600 dark:text-emerald-400">
								<span>Loyalty Discount</span>
								<span>-₦{order.loyalty_points_discount.toLocaleString()}</span>
							</div>
						{/if}

						<div
							class="flex justify-between items-center pt-3 border-t border-gray-200 dark:border-gray-700"
						>
							<span class="text-lg font-bold text-gray-900 dark:text-white">Total</span>
							<span class="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
								₦{order.total_amount.toLocaleString(undefined, { maximumFractionDigits: 2 })}
							</span>
						</div>

						<div class="pt-3 border-t border-gray-200 dark:border-gray-700">
							<div class="flex justify-between text-sm">
								<span class="text-gray-600 dark:text-gray-400">Payment Method</span>
								<span class="text-gray-900 dark:text-white font-medium capitalize">
									{order.payment_method.replace('_', ' ')}
								</span>
							</div>
							<div class="flex justify-between text-sm mt-2">
								<span class="text-gray-600 dark:text-gray-400">Payment Status</span>
								<span
									class="font-medium capitalize {order.payment_status === 'paid'
										? 'text-green-600 dark:text-green-400'
										: 'text-yellow-600 dark:text-yellow-400'}"
								>
									{order.payment_status}
								</span>
							</div>
						</div>
					</div>
				</div>

				<!-- Help Section -->
				<div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6 text-center">
					<h3 class="text-lg font-semibold text-blue-900 dark:text-blue-200 mb-2">
						Need Help?
					</h3>
					<p class="text-blue-800 dark:text-blue-300 text-sm mb-4">
						If you have any questions about your order, please contact our support team.
					</p>
					<div class="flex justify-center gap-4">
						{#if order.customer_phone}
							<a
								href="tel:{order.customer_phone}"
								class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition text-sm"
							>
								Call Support
							</a>
						{/if}
						<button
							on:click={() => window.location.reload()}
							class="px-4 py-2 bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition text-sm"
						>
							Refresh Status
						</button>
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>
