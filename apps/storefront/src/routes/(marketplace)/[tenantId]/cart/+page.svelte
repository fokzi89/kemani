<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { isAuthenticated } from '$lib/stores/auth';

	let tenantId = $page.params.tenantId;

	type CartItem = {
		product_id: string;
		product_name: string;
		product_image?: string;
		price: number;
		quantity: number;
		stock_available: number;
	};

	type Cart = {
		items: CartItem[];
	};

	let cart: Cart = { items: [] };
	let loyaltyPointsAvailable = 0;
	let loyaltyPointsToRedeem = 0;
	let deliveryFee = 1500; // Default ₦1,500 delivery fee
	let orderType: 'delivery' | 'pickup' = 'delivery';
	let isLoading = false;

	onMount(() => {
		loadCart();
		loadLoyaltyPoints();
	});

	function loadCart() {
		try {
			const cartData = localStorage.getItem('cart');
			if (cartData) {
				cart = JSON.parse(cartData);
			}
		} catch (err) {
			console.error('Failed to load cart:', err);
			cart = { items: [] };
		}
	}

	function loadLoyaltyPoints() {
		// TODO: Fetch from API when customer is logged in
		// For now, we'll use a placeholder
		loyaltyPointsAvailable = 0;
	}

	function saveCart() {
		localStorage.setItem('cart', JSON.stringify(cart));
	}

	function updateQuantity(index: number, newQuantity: number) {
		const item = cart.items[index];
		if (newQuantity <= 0) {
			removeItem(index);
		} else if (newQuantity <= item.stock_available) {
			cart.items[index].quantity = newQuantity;
			saveCart();
		} else {
			alert(`Only ${item.stock_available} units available in stock`);
		}
	}

	function removeItem(index: number) {
		cart.items.splice(index, 1);
		cart = cart; // Trigger reactivity
		saveCart();
	}

	function clearCart() {
		if (confirm('Are you sure you want to clear your cart?')) {
			cart = { items: [] };
			saveCart();
		}
	}

	function continueShopping() {
		goto(`/${tenantId}`);
	}

	$: subtotal = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
	$: tax = subtotal * 0.075; // 7.5% VAT
	$: actualDeliveryFee = orderType === 'delivery' ? deliveryFee : 0;
	$: loyaltyDiscount = loyaltyPointsToRedeem * 100; // 1 point = ₦100 discount
	$: total = subtotal + tax + actualDeliveryFee - loyaltyDiscount;

	$: maxRedeemablePoints = Math.min(
		loyaltyPointsAvailable,
		Math.floor(subtotal / 100) // Can't redeem more than subtotal allows
	);

	function handleLoyaltyPointsChange() {
		if (loyaltyPointsToRedeem > maxRedeemablePoints) {
			loyaltyPointsToRedeem = maxRedeemablePoints;
		}
		if (loyaltyPointsToRedeem < 0) {
			loyaltyPointsToRedeem = 0;
		}
	}

	async function proceedToCheckout() {
		if (cart.items.length === 0) {
			alert('Your cart is empty!');
			return;
		}

		// Check if user is authenticated
		if (!$isAuthenticated) {
			const currentPath = `/${tenantId}/cart`;
			goto(`/auth/login?redirect=${encodeURIComponent(currentPath)}`);
			return;
		}

		isLoading = true;

		// Prepare order data and navigate to checkout page
		const orderData = {
			items: cart.items.map((item) => ({
				product_id: item.product_id,
				quantity: item.quantity,
				unit_price: item.price
			})),
			subtotal,
			tax,
			delivery_fee: actualDeliveryFee,
			loyalty_points_to_redeem: loyaltyPointsToRedeem,
			total,
			order_type: orderType
		};

		// Save order data to localStorage for checkout page
		localStorage.setItem('checkout_data', JSON.stringify(orderData));

		// Navigate to checkout page
		goto(`/checkout`);
	}
</script>

<svelte:head>
	<title>Shopping Cart - Shop</title>
	<meta name="description" content="Review your shopping cart and proceed to checkout" />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<a href="/{tenantId}" class="text-emerald-600 dark:text-emerald-400 hover:underline">
					← Back to Shop
				</a>
				<h1 class="text-2xl font-bold text-gray-900 dark:text-white">Shopping Cart</h1>
				<div class="w-24"></div>
				<!-- Spacer for centering -->
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if cart.items.length === 0}
			<!-- Empty Cart State -->
			<div class="text-center py-16">
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
						d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
					/>
				</svg>
				<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Your cart is empty</h2>
				<p class="text-gray-600 dark:text-gray-400 mb-8">
					Start shopping to add items to your cart
				</p>
				<button
					on:click={continueShopping}
					class="px-6 py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					Browse Products
				</button>
			</div>
		{:else}
			<!-- Cart Content -->
			<div class="grid lg:grid-cols-3 gap-8">
				<!-- Cart Items (Left Column) -->
				<div class="lg:col-span-2 space-y-4">
					<div class="flex justify-between items-center mb-4">
						<h2 class="text-xl font-bold text-gray-900 dark:text-white">
							Cart Items ({cart.items.length})
						</h2>
						<button
							on:click={clearCart}
							class="text-red-600 dark:text-red-400 hover:underline text-sm"
						>
							Clear Cart
						</button>
					</div>

					{#each cart.items as item, index}
						<div
							class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-4 flex gap-4 items-center"
						>
							<!-- Product Image -->
							<div class="w-24 h-24 flex-shrink-0">
								<div
									class="w-full h-full bg-gray-200 dark:bg-gray-700 rounded-lg overflow-hidden"
								>
									{#if item.product_image}
										<img
											src={item.product_image}
											alt={item.product_name}
											class="w-full h-full object-cover"
										/>
									{:else}
										<div
											class="w-full h-full flex items-center justify-center text-gray-400 text-xs"
										>
											No Image
										</div>
									{/if}
								</div>
							</div>

							<!-- Product Info -->
							<div class="flex-1">
								<h3 class="font-semibold text-gray-900 dark:text-white mb-1">
									{item.product_name}
								</h3>
								<p class="text-lg font-bold text-emerald-600 dark:text-emerald-400 mb-2">
									₦{item.price.toLocaleString()}
								</p>
								<p class="text-xs text-gray-500 dark:text-gray-400">
									{item.stock_available} available in stock
								</p>
							</div>

							<!-- Quantity Controls -->
							<div class="flex items-center gap-2">
								<button
									on:click={() => updateQuantity(index, item.quantity - 1)}
									class="w-8 h-8 rounded-lg border border-gray-300 dark:border-gray-600 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-700 transition"
								>
									-
								</button>
								<input
									type="number"
									value={item.quantity}
									on:change={(e) => updateQuantity(index, parseInt(e.currentTarget.value) || 0)}
									min="1"
									max={item.stock_available}
									class="w-16 px-2 py-1 border border-gray-300 dark:border-gray-600 rounded-lg text-center bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
								/>
								<button
									on:click={() => updateQuantity(index, item.quantity + 1)}
									class="w-8 h-8 rounded-lg border border-gray-300 dark:border-gray-600 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-700 transition"
								>
									+
								</button>
							</div>

							<!-- Item Total -->
							<div class="text-right">
								<p class="text-sm text-gray-500 dark:text-gray-400 mb-1">Item Total</p>
								<p class="text-lg font-bold text-gray-900 dark:text-white">
									₦{(item.price * item.quantity).toLocaleString()}
								</p>
							</div>

							<!-- Remove Button -->
							<button
								on:click={() => removeItem(index)}
								class="text-red-600 dark:text-red-400 hover:text-red-700 dark:hover:text-red-300 p-2"
								title="Remove from cart"
							>
								<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
									/>
								</svg>
							</button>
						</div>
					{/each}

					<!-- Continue Shopping Button -->
					<button
						on:click={continueShopping}
						class="w-full px-4 py-3 border-2 border-emerald-600 text-emerald-600 dark:text-emerald-400 font-semibold rounded-lg hover:bg-emerald-50 dark:hover:bg-emerald-900/20 transition"
					>
						Continue Shopping
					</button>
				</div>

				<!-- Order Summary (Right Column) -->
				<div class="lg:col-span-1">
					<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 sticky top-4">
						<h2 class="text-xl font-bold text-gray-900 dark:text-white mb-6">Order Summary</h2>

						<!-- Order Type -->
						<div class="mb-6">
							<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
								Order Type
							</label>
							<div class="flex gap-4">
								<label class="flex items-center cursor-pointer">
									<input
										type="radio"
										bind:group={orderType}
										value="delivery"
										class="mr-2 text-emerald-600 focus:ring-emerald-500"
									/>
									<span class="text-gray-900 dark:text-white">Delivery</span>
								</label>
								<label class="flex items-center cursor-pointer">
									<input
										type="radio"
										bind:group={orderType}
										value="pickup"
										class="mr-2 text-emerald-600 focus:ring-emerald-500"
									/>
									<span class="text-gray-900 dark:text-white">Pickup</span>
								</label>
							</div>
						</div>

						<!-- Loyalty Points -->
						{#if loyaltyPointsAvailable > 0}
							<div class="mb-6 p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
									Redeem Loyalty Points
								</label>
								<p class="text-xs text-gray-600 dark:text-gray-400 mb-2">
									Available: {loyaltyPointsAvailable} points (₦{(loyaltyPointsAvailable * 100).toLocaleString()})
								</p>
								<div class="flex items-center gap-2">
									<input
										type="number"
										bind:value={loyaltyPointsToRedeem}
										on:input={handleLoyaltyPointsChange}
										min="0"
										max={maxRedeemablePoints}
										placeholder="Points to redeem"
										class="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
									/>
									<button
										on:click={() => (loyaltyPointsToRedeem = maxRedeemablePoints)}
										class="px-3 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition text-sm"
									>
										Max
									</button>
								</div>
								{#if loyaltyPointsToRedeem > 0}
									<p class="text-xs text-emerald-600 dark:text-emerald-400 mt-2">
										Discount: -₦{loyaltyDiscount.toLocaleString()}
									</p>
								{/if}
							</div>
						{/if}

						<!-- Price Breakdown -->
						<div class="space-y-3 mb-6 pb-6 border-b border-gray-200 dark:border-gray-700">
							<div class="flex justify-between text-gray-700 dark:text-gray-300">
								<span>Subtotal</span>
								<span>₦{subtotal.toLocaleString()}</span>
							</div>
							<div class="flex justify-between text-gray-700 dark:text-gray-300">
								<span>Tax (7.5% VAT)</span>
								<span>₦{tax.toLocaleString(undefined, { maximumFractionDigits: 2 })}</span>
							</div>
							{#if orderType === 'delivery'}
								<div class="flex justify-between text-gray-700 dark:text-gray-300">
									<span>Delivery Fee</span>
									<span>₦{actualDeliveryFee.toLocaleString()}</span>
								</div>
							{/if}
							{#if loyaltyPointsToRedeem > 0}
								<div class="flex justify-between text-emerald-600 dark:text-emerald-400">
									<span>Loyalty Discount</span>
									<span>-₦{loyaltyDiscount.toLocaleString()}</span>
								</div>
							{/if}
						</div>

						<!-- Total -->
						<div class="flex justify-between items-center mb-6">
							<span class="text-lg font-bold text-gray-900 dark:text-white">Total</span>
							<span class="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
								₦{total.toLocaleString(undefined, { maximumFractionDigits: 2 })}
							</span>
						</div>

						<!-- Points to Earn -->
						<div class="mb-6 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
							<p class="text-sm text-blue-800 dark:text-blue-200">
								You'll earn <strong>{Math.floor(subtotal * 0.01)}</strong> loyalty points with this order!
							</p>
						</div>

						<!-- Checkout Button -->
						<button
							on:click={proceedToCheckout}
							disabled={isLoading}
							class="w-full px-6 py-4 bg-emerald-600 text-white font-bold rounded-lg hover:bg-emerald-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
						>
							{#if isLoading}
								Processing...
							{:else}
								Proceed to Checkout
							{/if}
						</button>

						<!-- Security Badge -->
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
			</div>
		{/if}
	</div>
</div>
