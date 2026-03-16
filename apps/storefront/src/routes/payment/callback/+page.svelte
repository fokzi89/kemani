<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	/**
	 * Payment Callback Page
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Handles return from Paystack after payment
	 */

	let verifying = true;
	let success = false;
	let error = '';
	let paymentDetails: any = null;

	onMount(async () => {
		const reference = $page.url.searchParams.get('reference');

		if (!reference) {
			error = 'No payment reference found';
			verifying = false;
			return;
		}

		// Verify payment
		await verifyPayment(reference);
	});

	async function verifyPayment(reference: string) {
		try {
			const response = await fetch(`/api/payment/verify?reference=${reference}`);
			const data = await response.json();

			if (data.status && data.data) {
				success = true;
				paymentDetails = data.data;

				// Redirect to success page after 3 seconds
				setTimeout(() => {
					goto('/orders');
				}, 3000);
			} else {
				error = data.message || 'Payment verification failed';
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to verify payment';
		} finally {
			verifying = false;
		}
	}
</script>

<svelte:head>
	<title>Payment Processing</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center p-4">
	<div class="max-w-md w-full bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
		{#if verifying}
			<!-- Verifying -->
			<div class="text-center">
				<div class="mb-4 flex justify-center">
					<svg
						class="animate-spin h-16 w-16 text-blue-600"
						xmlns="http://www.w3.org/2000/svg"
						fill="none"
						viewBox="0 0 24 24"
					>
						<circle
							class="opacity-25"
							cx="12"
							cy="12"
							r="10"
							stroke="currentColor"
							stroke-width="4"
						></circle>
						<path
							class="opacity-75"
							fill="currentColor"
							d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
						></path>
					</svg>
				</div>
				<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
					Verifying Payment...
				</h2>
				<p class="text-gray-600 dark:text-gray-400">Please wait while we confirm your payment</p>
			</div>
		{:else if success && paymentDetails}
			<!-- Success -->
			<div class="text-center">
				<div class="mb-4 flex justify-center">
					<svg
						class="h-16 w-16 text-green-600"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
						></path>
					</svg>
				</div>
				<h2 class="text-2xl font-bold text-green-600 mb-2">Payment Successful!</h2>
				<p class="text-gray-600 dark:text-gray-400 mb-6">
					Your payment has been confirmed and your order is being processed.
				</p>

				<div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 mb-6">
					<div class="space-y-2 text-sm">
						<div class="flex justify-between">
							<span class="text-gray-600 dark:text-gray-400">Reference:</span>
							<span class="font-mono text-gray-900 dark:text-white"
								>{paymentDetails.reference}</span
							>
						</div>
						<div class="flex justify-between">
							<span class="text-gray-600 dark:text-gray-400">Amount:</span>
							<span class="font-semibold text-gray-900 dark:text-white"
								>₦{(paymentDetails.amount / 100).toLocaleString()}</span
							>
						</div>
						{#if paymentDetails.metadata?.group_id}
							<div class="flex justify-between">
								<span class="text-gray-600 dark:text-gray-400">Type:</span>
								<span class="text-gray-900 dark:text-white">Multi-Service Checkout</span>
							</div>
						{/if}
					</div>
				</div>

				<p class="text-sm text-gray-500 dark:text-gray-400">
					Redirecting to your orders in 3 seconds...
				</p>
			</div>
		{:else if error}
			<!-- Error -->
			<div class="text-center">
				<div class="mb-4 flex justify-center">
					<svg
						class="h-16 w-16 text-red-600"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
						></path>
					</svg>
				</div>
				<h2 class="text-2xl font-bold text-red-600 mb-2">Payment Failed</h2>
				<p class="text-gray-600 dark:text-gray-400 mb-6">{error}</p>

				<div class="space-y-3">
					<a
						href="/checkout"
						class="block w-full px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition"
					>
						Try Again
					</a>
					<a
						href="/"
						class="block w-full px-6 py-3 bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-white font-semibold rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition"
					>
						Back to Shop
					</a>
				</div>
			</div>
		{/if}
	</div>
</div>
