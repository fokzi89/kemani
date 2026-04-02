<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { currentUser } from '$lib/stores/auth';
	import { TransactionGroupService, type CartItem } from '$lib/services/transactionGroup';
	import { CommissionCalculator } from '$lib/services/commissionCalculator';
	import CommissionPreview from '$lib/components/referral/CommissionPreview.svelte';

	/**
	 * Enhanced Checkout Page
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Integrates:
	 * - TransactionGroupService for multi-service checkout
	 * - CommissionCalculator for price preview
	 * - CommissionPreview component for transparency
	 */

	interface CheckoutItem {
		id: string;
		name: string;
		type: 'consultation' | 'product_sale' | 'diagnostic_test';
		base_price: number;
		provider_tenant_id: string;
		provider_name?: string;
		metadata?: Record<string, any>;
	}

	interface CheckoutData {
		items: CheckoutItem[];
		subtotal: number;
		tax: number;
		delivery_fee: number;
		total: number;
	}

	let checkoutData: CheckoutData | null = null;
	let referringTenantId: string | null = null;
	let referrerName: string | null = null;
	let isLoading = false;
	let error = '';
	let success = '';

	// Commission calculation results
	let commissionBreakdown: any = null;
	let calculatingCommission = false;

	$: referringTenantId = $page.data.referringTenantId || null;
	$: hasReferrer = !!referringTenantId;

	onMount(async () => {
		// Load checkout data from localStorage
		const savedData = localStorage.getItem('checkout_data');
		if (!savedData) {
			goto('/');
			return;
		}

		checkoutData = JSON.parse(savedData);

		// Calculate commission breakdown
		if (checkoutData) {
			await calculateCommissions();
		}
	});

	async function calculateCommissions() {
		if (!checkoutData) return;

		calculatingCommission = true;
		try {
			const cartItems = checkoutData.items.map((item) => ({
				type: item.type,
				price: item.base_price
			}));

			commissionBreakdown = await CommissionCalculator.calculateCart(cartItems, hasReferrer);
		} catch (err) {
			console.error('Error calculating commissions:', err);
		} finally {
			calculatingCommission = false;
		}
	}

	async function completeOrder() {
		if (!checkoutData || !$currentUser) {
			error = 'Please log in to complete your order';
			return;
		}

		isLoading = true;
		error = '';

		try {
			// Prepare cart items for TransactionGroupService
			const cartItems: CartItem[] = checkoutData.items.map((item) => ({
				type: item.type,
				base_price: item.base_price,
				provider_tenant_id: item.provider_tenant_id,
				metadata: {
					...item.metadata,
					item_name: item.name,
					provider_name: item.provider_name
				}
			}));

			// Create transaction group
			const result = await TransactionGroupService.createTransactionGroup(
				$currentUser.id,
				referringTenantId,
				cartItems
			);

			if (!result) {
				throw new Error('Failed to create transaction group');
			}

			const { group_id, transactions } = result;

			// Calculate total amount to charge
			let totalAmount = checkoutData.total;

			// Initialize payment gateway (Paystack example)
			await initializePayment({
				amount: totalAmount,
				email: $currentUser.email || '',
				metadata: {
					group_id: group_id, // IMPORTANT: Include group_id for webhook
					customer_id: $currentUser.id
				}
			});

			// Clear cart after payment initialization
			localStorage.removeItem('cart');
			localStorage.removeItem('checkout_data');

			success = 'Redirecting to payment...';
		} catch (err: any) {
			error = err.message || 'Failed to place order. Please try again.';
		} finally {
			isLoading = false;
		}
	}

	async function initializePayment(config: {
		amount: number;
		email: string;
		metadata: any;
	}) {
		// TODO: Implement actual payment gateway integration
		// Example with Paystack:
		/*
    const response = await fetch('/api/payment/initialize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount: config.amount * 100, // Convert to kobo
        email: config.email,
        metadata: config.metadata
      })
    });

    const data = await response.json();

    if (data.status && data.data?.authorization_url) {
      // Redirect to payment page
      window.location.href = data.data.authorization_url;
    }
    */

		console.log('Payment initialization:', config);

		// Simulate payment for now
		await new Promise((resolve) => setTimeout(resolve, 1500));
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
				<a href="/" class="text-blue-600 dark:text-blue-400 hover:underline"> ← Back to Shop </a>
				<h1 class="text-2xl font-bold text-gray-900 dark:text-white">Checkout</h1>
				<div class="w-24"></div>
			</div>
		</div>
	</header>

	<div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if error}
			<div
				class="mb-6 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 px-4 py-3 rounded-lg"
			>
				{error}
			</div>
		{/if}

		{#if success}
			<div
				class="mb-6 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 text-green-600 dark:text-green-400 px-4 py-3 rounded-lg"
			>
				{success}
			</div>
		{/if}

		{#if checkoutData}
			<div class="grid lg:grid-cols-3 gap-8">
				<!-- Left Column: Items & Customer Info -->
				<div class="lg:col-span-2 space-y-6">
					<!-- Cart Items -->
					<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
						<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">Order Items</h2>

						<div class="space-y-4">
							{#each checkoutData.items as item}
								<div class="flex justify-between items-start p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
									<div class="flex-1">
										<h3 class="font-semibold text-gray-900 dark:text-white">{item.name}</h3>
										<p class="text-sm text-gray-600 dark:text-gray-400 capitalize">
											{item.type.replace('_', ' ')}
										</p>
										{#if item.provider_name}
											<p class="text-sm text-gray-500 dark:text-gray-500 mt-1">
												Provider: {item.provider_name}
											</p>
										{/if}
									</div>
									<div class="text-right">
										<p class="font-semibold text-gray-900 dark:text-white">
											₦{item.base_price.toLocaleString()}
										</p>
									</div>
								</div>
							{/each}
						</div>
					</div>

					<!-- Commission Preview (if has referrer) -->
					{#if hasReferrer && !calculatingCommission}
						<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
							<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">
								Commission Breakdown
							</h2>

							{#if commissionBreakdown}
								<div class="space-y-3 text-sm">
									<div class="flex justify-between">
										<span class="text-gray-600 dark:text-gray-400">Base Total:</span>
										<span class="font-semibold">₦{commissionBreakdown.base_total.toLocaleString()}</span>
									</div>
									<div class="flex justify-between">
										<span class="text-gray-600 dark:text-gray-400">Customer Pays:</span>
										<span class="font-semibold text-blue-600">₦{commissionBreakdown.customer_total.toLocaleString()}</span>
									</div>
									<div class="flex justify-between">
										<span class="text-gray-600 dark:text-gray-400">Provider Earns:</span>
										<span class="font-semibold text-green-600">₦{commissionBreakdown.provider_total.toLocaleString()}</span>
									</div>
									{#if hasReferrer}
										<div class="flex justify-between">
											<span class="text-gray-600 dark:text-gray-400">Referrer Earns:</span>
											<span class="font-semibold text-purple-600">₦{commissionBreakdown.referrer_total.toLocaleString()}</span>
										</div>
									{/if}
									<div class="flex justify-between">
										<span class="text-gray-600 dark:text-gray-400">Platform Fee:</span>
										<span class="font-semibold">₦{commissionBreakdown.platform_total.toLocaleString()}</span>
									</div>
								</div>
							{/if}
						</div>
					{/if}

					<!-- Customer Info -->
					<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
						<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">
							Customer Information
						</h2>

						<div class="space-y-3">
							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
									Email
								</label>
								<p class="text-gray-900 dark:text-white">{$currentUser?.email || 'N/A'}</p>
							</div>

							{#if hasReferrer}
								<div class="mt-4 p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
									<p class="text-sm text-purple-800 dark:text-purple-200">
										<strong>Referred by:</strong>
										{referrerName || 'Partner'}
									</p>
								</div>
							{/if}
						</div>
					</div>
				</div>

				<!-- Right Column: Order Summary -->
				<div class="lg:col-span-1">
					<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 sticky top-4">
						<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">Order Summary</h2>

						<div class="space-y-3 mb-6 pb-6 border-b border-gray-200 dark:border-gray-700">
							<div class="flex justify-between text-gray-700 dark:text-gray-300">
								<span>Items ({checkoutData.items.length})</span>
								<span>₦{checkoutData.subtotal.toLocaleString()}</span>
							</div>

							<div class="flex justify-between text-gray-700 dark:text-gray-300">
								<span>Tax (7.5% VAT)</span>
								<span
									>₦{checkoutData.tax.toLocaleString(undefined, { maximumFractionDigits: 2 })}</span
								>
							</div>

							{#if checkoutData.delivery_fee > 0}
								<div class="flex justify-between text-gray-700 dark:text-gray-300">
									<span>Delivery Fee</span>
									<span>₦{checkoutData.delivery_fee.toLocaleString()}</span>
								</div>
							{/if}
						</div>

						<div class="flex justify-between items-center mb-6">
							<span class="text-lg font-bold text-gray-900 dark:text-white">Total</span>
							<span class="text-2xl font-bold text-blue-600 dark:text-blue-400">
								₦{checkoutData.total.toLocaleString(undefined, { maximumFractionDigits: 2 })}
							</span>
						</div>

						<button
							on:click={completeOrder}
							disabled={isLoading || success !== ''}
							class="w-full px-6 py-4 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
						>
							{#if isLoading}
								<svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
									<circle
										class="opacity-25"
										cx="12"
										cy="12"
										r="10"
										stroke="currentColor"
										stroke-width="4"
										fill="none"
									></circle>
									<path
										class="opacity-75"
										fill="currentColor"
										d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
									></path>
								</svg>
								Processing Order...
							{:else if success}
								✓ Order Placed!
							{:else}
								Proceed to Payment
							{/if}
						</button>

						<div
							class="mt-4 flex items-center justify-center gap-2 text-sm text-gray-600 dark:text-gray-400"
						>
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
			</div>
		{:else}
			<div class="text-center py-16">
				<p class="text-gray-600 dark:text-gray-400">Loading checkout...</p>
			</div>
		{/if}
	</div>
</div>
