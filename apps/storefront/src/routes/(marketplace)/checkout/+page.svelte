<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { currentUser } from '$lib/stores/auth';

	// The tenant is identified by the host (Approach 2)
	export let data: { referringTenantId: string | null; user: any };
	let tenantId = data.referringTenantId;
	let orderData: any = null;
	let isLoading = false;
	let error = '';
	let success = '';

	onMount(() => {
		// Load checkout data from localStorage
		const savedData = localStorage.getItem('checkout_data');
		if (!savedData) {
			goto('/');
			return;
		}

		orderData = JSON.parse(savedData);
	});

	async function completeOrder() {
		isLoading = true;
		error = '';

		try {
			// TODO: Integrate payment gateway and create order
			// For now, we'll simulate the order creation

			// Simulate API call
			await new Promise(resolve => setTimeout(resolve, 1500));

			// Clear cart and checkout data
			localStorage.removeItem('cart');
			localStorage.removeItem('checkout_data');

			success = 'Order placed successfully!';

			// Redirect to profile after 2 seconds
			setTimeout(() => {
				goto(`/profile`);
			}, 2000);
		} catch (err: any) {
			error = err.message || 'Failed to place order. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Checkout - Complete Your Order</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<a href="/" class="text-blue-600 dark:text-blue-400 hover:underline">
					← Back to Shop
				</a>
				<h1 class="text-2xl font-bold text-gray-900 dark:text-white">Checkout</h1>
				<div class="w-24"></div>
			</div>
		</div>
	</header>

	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if error}
			<div class="mb-6 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 px-4 py-3 rounded-lg">
				{error}
			</div>
		{/if}

		{#if success}
			<div class="mb-6 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 text-green-600 dark:text-green-400 px-4 py-3 rounded-lg">
				{success}
			</div>
		{/if}

		{#if orderData}
			<div class="grid md:grid-cols-2 gap-8">
				<!-- Customer Info -->
				<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
					<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">Customer Information</h2>

					<div class="space-y-3">
						<div>
							<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
								Email
							</label>
							<p class="text-gray-900 dark:text-white">{$currentUser?.email || 'N/A'}</p>
						</div>

						<div>
							<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
								Order Type
							</label>
							<p class="text-gray-900 dark:text-white capitalize">{orderData.order_type}</p>
						</div>
					</div>

					<div class="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
						<p class="text-sm text-blue-800 dark:text-blue-200">
							<strong>Note:</strong> Payment gateway integration coming soon! This is a demo checkout.
						</p>
					</div>
				</div>

				<!-- Order Summary -->
				<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
					<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">Order Summary</h2>

					<div class="space-y-3 mb-6 pb-6 border-b border-gray-200 dark:border-gray-700">
						<div class="flex justify-between text-gray-700 dark:text-gray-300">
							<span>Items ({orderData.items.length})</span>
							<span>₦{orderData.subtotal.toLocaleString()}</span>
						</div>

						<div class="flex justify-between text-gray-700 dark:text-gray-300">
							<span>Tax (7.5% VAT)</span>
							<span>₦{orderData.tax.toLocaleString(undefined, { maximumFractionDigits: 2 })}</span>
						</div>

						{#if orderData.delivery_fee > 0}
							<div class="flex justify-between text-gray-700 dark:text-gray-300">
								<span>Delivery Fee</span>
								<span>₦{orderData.delivery_fee.toLocaleString()}</span>
							</div>
						{/if}

						{#if orderData.loyalty_points_to_redeem > 0}
							<div class="flex justify-between text-green-600 dark:text-green-400">
								<span>Loyalty Discount ({orderData.loyalty_points_to_redeem} points)</span>
								<span>-₦{(orderData.loyalty_points_to_redeem * 100).toLocaleString()}</span>
							</div>
						{/if}
					</div>

					<div class="flex justify-between items-center mb-6">
						<span class="text-lg font-bold text-gray-900 dark:text-white">Total</span>
						<span class="text-2xl font-bold text-blue-600 dark:text-blue-400">
							₦{orderData.total.toLocaleString(undefined, { maximumFractionDigits: 2 })}
						</span>
					</div>

					<button
						on:click={completeOrder}
						disabled={isLoading || success !== ''}
						class="w-full px-6 py-4 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
					>
						{#if isLoading}
							<svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
								<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
								<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
							</svg>
							Processing Order...
						{:else if success}
							✓ Order Placed!
						{:else}
							Place Order
						{/if}
					</button>

					<div class="mt-4 flex items-center justify-center gap-2 text-sm text-gray-600 dark:text-gray-400">
						<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
							/>
						</svg>
						<span>Secure Checkout</span>
					</div>
				</div>
			</div>
		{:else}
			<div class="text-center py-16">
				<p class="text-gray-600 dark:text-gray-400">Loading checkout...</p>
			</div>
		{/if}
	</div>
</div>
