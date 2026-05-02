<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { ShoppingCart, Trash2, Plus, Minus, ArrowLeft, ShieldCheck, Truck, ArrowRight } from 'lucide-svelte';
	import { isAuthenticated } from '$lib/stores/auth';
	import { isAuthModalOpen } from '$lib/stores/ui';
	import { cartStore, cartCount, cartSubtotal, cartServiceCharge } from '$lib/stores/cart.store';

	export let data;

	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#003f87';

	let isLoading = false;

	onMount(() => {
		// Store automatically syncs via localStorage and storage events
	});

	function updateQuantity(product_id: string, qty: number) {
		cartStore.updateQuantity(product_id, qty);
	}

	function removeItem(product_id: string) {
		cartStore.removeItem(product_id);
	}

	$: subtotal = $cartSubtotal;
	
	$: taxRate = storefront?.branches?.[0]?.tax_rate || 0;
	$: tax = Math.round(subtotal * (taxRate / 100));

	$: serviceCharge = $cartServiceCharge;
	$: estimatedTotal = subtotal + tax + serviceCharge;

	async function proceedToCheckout() {
		if ($cartStore.items.length === 0) return;
		if (!$isAuthenticated) {
			localStorage.setItem('auth_redirect', '/cart');
			localStorage.removeItem('pending_chat_redirect');
			isAuthModalOpen.set(true);
			return;
		}
		isLoading = true;
		const orderData = { 
			items: $cartStore.items, 
			subtotal, 
			tax, 
			service_charge: serviceCharge,
			delivery_fee: 0, 
			total: estimatedTotal, 
			order_type: 'delivery' 
		};
		localStorage.setItem('checkout_data', JSON.stringify(orderData));
		await goto('/checkout');
		isLoading = false;
	}
</script>

<svelte:head>
	<title>Your Cart | {storefront?.name || 'Shop'}</title>
	<meta name="description" content="Review your cart items before checkout." />
	<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet" />
</svelte:head>

<div class="cart-page">
	<div class="cart-container">

		<!-- Back link + Title -->
		<div class="page-header">
			<a href="/" class="back-link">
				<ArrowLeft class="back-icon" /> Back
			</a>
			<h1 class="page-title">Your Cart</h1>
		</div>

		{#if $cartStore.items.length === 0}
			<div class="empty-state">
				<div class="empty-icon-wrap">
					<ShoppingCart class="empty-icon" />
				</div>
				<h2 class="empty-title">Your cart is empty</h2>
				<p class="empty-sub">Discover our curated healthcare collection and add items to your bag.</p>
				<a href="/products" class="empty-cta">Start Shopping</a>
			</div>
		{:else}
			<div class="cart-layout">

				<!-- LEFT: Items -->
				<div class="items-panel">
					<div class="panel-header">
						<h2 class="panel-title">Items</h2>
					</div>

					<!-- Group label (fulfilling pharmacy if available) -->
					{#if storefront?.name}
						<p class="fulfillment-label">
							Fulfilling Pharmacy: <strong>{storefront.name}</strong>
						</p>
					{/if}

					<div class="items-list">
						{#each $cartStore.items as item}
							<div class="item-row">
								<!-- Product image -->
								<div class="item-img-wrap">
									{#if item.product_image}
										<img src={item.product_image} alt={item.product_name} class="item-img" />
									{:else}
										<div class="item-placeholder">
											<ShoppingCart class="placeholder-icon" />
										</div>
									{/if}
								</div>

								<!-- Item info -->
								<div class="item-body">
									<div class="item-top">
										<span class="item-name">{item.product_name}</span>
										<span class="item-price" style="color:{brandColor};">
											₦{(item.price * item.quantity).toLocaleString()}
										</span>
									</div>

									<div class="item-bottom">
										<!-- Qty control -->
										<div class="qty-wrap">
											<button
												class="qty-btn"
												onclick={() => updateQuantity(item.product_id, item.quantity - 1)}
												aria-label="Decrease quantity"
											>
												<Minus class="qty-icon" />
											</button>
											<span class="qty-val">{item.quantity}</span>
											<button
												class="qty-btn"
												onclick={() => updateQuantity(item.product_id, item.quantity + 1)}
												aria-label="Increase quantity"
											>
												<Plus class="qty-icon" />
											</button>
										</div>

										<!-- Remove -->
										<button class="remove-btn" onclick={() => removeItem(item.product_id)}>
											<Trash2 class="remove-icon" /> Remove
										</button>
									</div>
								</div>
							</div>
						{/each}
					</div>
				</div>

				<!-- RIGHT: Cart Summary -->
				<aside class="summary-panel">
					<div class="summary-box">
						<h2 class="summary-title">Cart Summary</h2>

						<div class="summary-rows">
							<div class="summary-row">
								<span class="row-label">Subtotal</span>
								<span class="row-val">₦{subtotal.toLocaleString()}</span>
							</div>
							{#if taxRate > 0}
								<div class="summary-row">
									<span class="row-label">Estimated Tax ({taxRate}%)</span>
									<span class="row-val">₦{tax.toLocaleString()}</span>
								</div>
							{/if}
							<div class="summary-row">
								<span class="row-label">Transaction Fee</span>
								<span class="row-val">₦{serviceCharge.toLocaleString()}</span>
							</div>
						</div>

						<div class="summary-divider"></div>

						<div class="summary-total">
							<span class="total-label">Estimated Total</span>
							<span class="total-val" style="color:{brandColor};">₦{estimatedTotal.toLocaleString()}</span>
						</div>

						<p class="delivery-note">Delivery fee will be calculated at checkout.</p>

						<button
							class="checkout-btn"
							onclick={proceedToCheckout}
							disabled={isLoading}
							id="proceed-to-checkout-btn"
						>
							{#if isLoading}
								Processing...
							{:else}
								Proceed to Checkout →
							{/if}
						</button>

						<div class="trust-items">
							<div class="trust-item">
								<ShieldCheck class="trust-icon" />
								<span>Secure & Encrypted Checkout</span>
							</div>
							<div class="trust-item">
								<Truck class="trust-icon" />
								<span>Express Priority Dispatch</span>
							</div>
						</div>
					</div>
				</aside>
			</div>

			<a href="/" class="continue-link">
				<ArrowLeft class="continue-icon" /> Continue Shopping
			</a>
		{/if}
	</div>
</div>

<style>
	.cart-page {
		background: #f3f4f6;
		min-height: 100vh;
		font-family: 'Inter', sans-serif;
		padding: 2rem 0 4rem;
	}

	.cart-container {
		max-width: 1100px;
		margin: 0 auto;
		padding: 0 1.5rem;
	}

	/* ── Header ── */
	.page-header {
		display: flex;
		align-items: center;
		gap: 1.25rem;
		margin-bottom: 2rem;
	}

	.back-link {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		font-size: 0.8125rem;
		font-weight: 500;
		color: #6b7280;
		text-decoration: none;
		transition: color 0.15s;
	}
	.back-link:hover { color: #111827; }
	.back-icon { width: 14px; height: 14px; }

	.page-title {
		font-size: 1.75rem;
		font-weight: 800;
		color: #111827;
		letter-spacing: -0.02em;
	}

	/* ── Layout ── */
	.cart-layout {
		display: grid;
		grid-template-columns: 1fr;
		gap: 1.5rem;
		align-items: flex-start;
	}
	@media (min-width: 900px) {
		.cart-layout { grid-template-columns: 1fr 360px; }
	}

	/* ── Items Panel ── */
	.items-panel {
		background: #fff;
		border: 1px solid #e5e7eb;
		border-radius: 14px;
		padding: 1.75rem;
		box-shadow: 0 1px 4px rgba(0,0,0,0.04);
	}

	.panel-header { margin-bottom: 1rem; }
	.panel-title {
		font-size: 1rem;
		font-weight: 700;
		color: #111827;
	}

	.fulfillment-label {
		font-size: 0.8125rem;
		color: #6b7280;
		margin-bottom: 1.25rem;
		padding-bottom: 1rem;
		border-bottom: 1px solid #f3f4f6;
	}
	.fulfillment-label strong { color: #111827; }

	.items-list { display: flex; flex-direction: column; }

	.item-row {
		display: flex;
		gap: 1rem;
		padding: 1.25rem 0;
		border-bottom: 1px solid #f3f4f6;
	}
	.item-row:last-child { border-bottom: none; }

	.item-img-wrap {
		width: 56px;
		height: 64px;
		border-radius: 8px;
		border: 1px solid #e5e7eb;
		background: #f9fafb;
		overflow: hidden;
		flex-shrink: 0;
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.item-img { width: 100%; height: 100%; object-fit: cover; }
	.item-placeholder { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; }
	.placeholder-icon { width: 20px; height: 20px; color: #d1d5db; }

	.item-body { flex: 1; display: flex; flex-direction: column; justify-content: space-between; min-width: 0; }

	.item-top {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 1rem;
		margin-bottom: 0.625rem;
	}

	.item-name {
		font-size: 0.9375rem;
		font-weight: 600;
		color: #111827;
		line-height: 1.3;
		flex: 1;
	}

	.item-price {
		font-size: 0.9375rem;
		font-weight: 700;
		white-space: nowrap;
	}

	.item-bottom {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	/* Qty */
	.qty-wrap {
		display: inline-flex;
		align-items: center;
		gap: 0.875rem;
	}
	.qty-btn {
		width: 24px;
		height: 24px;
		display: flex;
		align-items: center;
		justify-content: center;
		background: none;
		border: none;
		color: #374151;
		cursor: pointer;
		font-size: 1rem;
		font-weight: 700;
		transition: color 0.15s;
	}
	.qty-btn:hover { color: #111827; }
	.qty-icon { width: 14px; height: 14px; }
	.qty-val {
		font-size: 0.9375rem;
		font-weight: 700;
		color: #111827;
		min-width: 20px;
		text-align: center;
	}

	/* Remove */
	.remove-btn {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		font-size: 0.8125rem;
		font-weight: 600;
		color: #ef4444;
		background: none;
		border: none;
		cursor: pointer;
		transition: opacity 0.15s;
	}
	.remove-btn:hover { opacity: 0.75; }
	.remove-icon { width: 13px; height: 13px; }

	/* ── Summary Panel ── */
	.summary-panel { position: sticky; top: 5rem; }

	.summary-box {
		background: #fff;
		border: 1px solid #e5e7eb;
		border-radius: 14px;
		padding: 1.75rem;
		box-shadow: 0 1px 4px rgba(0,0,0,0.04);
	}

	.summary-title {
		font-size: 1rem;
		font-weight: 700;
		color: #111827;
		margin-bottom: 1.5rem;
	}

	.summary-rows { display: flex; flex-direction: column; gap: 0.875rem; margin-bottom: 1.25rem; }

	.summary-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}
	.row-label { font-size: 0.875rem; color: #6b7280; }
	.row-val { font-size: 0.875rem; font-weight: 500; color: #374151; }

	.summary-divider {
		height: 1px;
		background: #e5e7eb;
		margin-bottom: 1.25rem;
	}

	.summary-total {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 0.5rem;
	}
	.total-label { font-size: 1rem; font-weight: 800; color: #111827; }
	.total-val { font-size: 1rem; font-weight: 800; }

	.delivery-note {
		font-size: 0.75rem;
		color: #9ca3af;
		margin-bottom: 1.5rem;
	}

	.checkout-btn {
		width: 100%;
		padding: 1rem;
		border-radius: 10px;
		background: #111827;
		color: #fff;
		font-size: 0.9375rem;
		font-weight: 700;
		border: none;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		transition: opacity 0.15s, transform 0.15s;
		margin-bottom: 1.25rem;
	}
	.checkout-btn:hover { opacity: 0.9; transform: translateY(-1px); }
	.checkout-btn:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }

	/* Trust */
	.trust-items {
		display: flex;
		flex-direction: column;
		gap: 0.625rem;
		border-top: 1px solid #f3f4f6;
		padding-top: 1rem;
	}
	.trust-item {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.75rem;
		color: #9ca3af;
		font-weight: 500;
	}
	.trust-icon { width: 13px; height: 13px; color: #d1d5db; }

	/* ── Continue ── */
	.continue-link {
		display: inline-flex;
		align-items: center;
		gap: 0.375rem;
		margin-top: 1.5rem;
		font-size: 0.8125rem;
		font-weight: 600;
		color: #6b7280;
		text-decoration: none;
		transition: color 0.15s;
	}
	.continue-link:hover { color: #111827; }
	.continue-icon { width: 14px; height: 14px; }

	/* ── Empty State ── */
	.empty-state {
		text-align: center;
		padding: 5rem 2rem;
		background: #fff;
		border: 1px solid #e5e7eb;
		border-radius: 14px;
	}
	.empty-icon-wrap {
		width: 72px;
		height: 72px;
		background: #f3f4f6;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto 1.5rem;
	}
	.empty-icon { width: 32px; height: 32px; color: #d1d5db; }
	.empty-title { font-size: 1.25rem; font-weight: 700; color: #111827; margin-bottom: 0.5rem; }
	.empty-sub { font-size: 0.875rem; color: #6b7280; margin-bottom: 2rem; }
	.empty-cta {
		display: inline-flex;
		padding: 0.75rem 2rem;
		background: #111827;
		color: #fff;
		border-radius: 8px;
		font-size: 0.875rem;
		font-weight: 700;
		text-decoration: none;
		transition: opacity 0.15s;
	}
	.empty-cta:hover { opacity: 0.85; }

	@media (max-width: 640px) {
		.page-title { font-size: 1.375rem; }
		.items-panel, .summary-box { padding: 1.25rem; }
		.summary-panel { position: static; }
	}
</style>
