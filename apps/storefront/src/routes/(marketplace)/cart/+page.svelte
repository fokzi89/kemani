<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ShoppingCart, Trash2, Plus, Minus, ArrowLeft, 
		CreditCard, ShieldCheck, Truck, Tag, Ticket, ChevronRight, ArrowRight
	} from 'lucide-svelte';
	import { isAuthenticated } from '$lib/stores/auth';
	import { isAuthModalOpen } from '$lib/stores/ui';

	export let data;

	$: storefront = data.storefront;
    $: brandColor = storefront?.brand_color || '#4f46e5';
    $: brandColorLight = brandColor + '18';

	type CartItem = {
		product_id: string;
		inventory_id?: string;
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
	let deliveryFee = 1500;
	let orderType: 'delivery' | 'pickup' = 'delivery';
	let isLoading = false;

	onMount(() => {
		loadCart();
	});

	function loadCart() {
		try {
			const cartData = localStorage.getItem('cart');
			if (cartData) {
				cart = JSON.parse(cartData);
			}
		} catch (err) {
			cart = { items: [] };
		}
	}

	function saveCart() {
		localStorage.setItem('cart', JSON.stringify(cart));
	}

	function updateQuantity(index: number, newQuantity: number) {
		const item = cart.items[index];
		if (newQuantity <= 0) {
			removeItem(index);
		} else if (newQuantity <= (item.stock_available || 999)) {
			cart.items[index].quantity = newQuantity;
			cart = cart; 
			saveCart();
		}
	}

	function removeItem(index: number) {
		cart.items.splice(index, 1);
		cart = cart; 
		saveCart();
	}

	$: subtotal = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
	$: tax = subtotal * 0.075; 
	$: actualDeliveryFee = orderType === 'delivery' ? deliveryFee : 0;
	$: total = subtotal + tax + actualDeliveryFee;

	async function proceedToCheckout() {
		if (cart.items.length === 0) return;
		
		if (!$isAuthenticated) {
			isAuthModalOpen.set(true);
			return;
		}

		isLoading = true;
		
		const orderData = {
			items: cart.items,
			subtotal,
			tax,
			delivery_fee: actualDeliveryFee,
			total,
			order_type: orderType
		};

		localStorage.setItem('checkout_data', JSON.stringify(orderData));
		goto(`/checkout`);
	}
</script>

<svelte:head>
	<title>Your Bag | {storefront?.name || 'Shop'}</title>
</svelte:head>

<div class="cart-page">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-16">
		
		<header class="cart-header">
			<h1 class="cart-title">Your Bag</h1>
			<p class="cart-subtitle">Review your selection before proceeding to checkout.</p>
		</header>

		{#if cart.items.length === 0}
			<div class="empty-cart">
				<div class="empty-icon"><ShoppingCart class="w-12 h-12" /></div>
				<h3 class="empty-msg">Your bag is currently empty</h3>
				<p class="empty-sub">Discover our curated healthcare collection and start your medics journey.</p>
				<a href="/" class="btn-primary empty-cta">Start Shopping</a>
			</div>
		{:else}
			<div class="cart-layout">
				<!-- Items List -->
				<div class="cart-items">
					{#each cart.items as item, index}
						<div class="cart-row">
							<div class="item-img-wrap">
								{#if item.product_image}
									<img src={item.product_image} alt={item.product_name} class="item-img" />
								{:else}
									<div class="item-placeholder"><ShoppingCart class="w-8 h-8" /></div>
								{/if}
							</div>

							<div class="item-info">
								<div class="item-details">
									<h3 class="item-name">{item.product_name}</h3>
									<p class="item-price">₦{item.price.toLocaleString()}</p>
								</div>

								<div class="item-controls">
									<div class="qty-control">
										<button on:click={() => updateQuantity(index, item.quantity - 1)} class="qty-btn"><Minus class="w-2.5 h-2.5" /></button>
										<span class="qty-val">{item.quantity}</span>
										<button on:click={() => updateQuantity(index, item.quantity + 1)} class="qty-btn"><Plus class="w-2.5 h-2.5" /></button>
									</div>
									<button on:click={() => removeItem(index)} class="remove-btn">Remove</button>
								</div>
							</div>
						</div>
					{/each}
				</div>

				<!-- Summary Table -->
				<aside class="cart-summary">
					<div class="summary-box">
						<h2 class="summary-title">Summary</h2>
						
						<div class="order-type-tabs">
							<button 
								on:click={() => orderType = 'delivery'}
								class="type-tab {orderType === 'delivery' ? 'active' : ''}"
							>Delivery</button>
							<button 
								on:click={() => orderType = 'pickup'}
								class="type-tab {orderType === 'pickup' ? 'active' : ''}"
							>Pickup</button>
						</div>

						<div class="summary-details">
							<div class="summary-row">
								<span>Subtotal</span>
								<span>₦{subtotal.toLocaleString()}</span>
							</div>
							<div class="summary-row">
								<span>VAT (7.5%)</span>
								<span>₦{tax.toLocaleString()}</span>
							</div>
							{#if orderType === 'delivery'}
								<div class="summary-row">
									<span>Delivery Fee</span>
									<span>₦{deliveryFee.toLocaleString()}</span>
								</div>
							{:else}
								<div class="summary-row text-emerald-600">
									<span>Pickup</span>
									<span>Free</span>
								</div>
							{/if}
							<div class="summary-total">
								<span>Total</span>
								<span>₦{total.toLocaleString()}</span>
							</div>
						</div>

						<button 
							on:click={proceedToCheckout}
							disabled={isLoading}
							class="btn-primary checkout-btn"
						>
							{#if isLoading}
								<div class="loader-dot"></div> Processing...
							{:else}
								Proceed to Checkout <ArrowRight class="w-4 h-4" />
							{/if}
						</button>

						<div class="trust-points">
							<div class="trust-item">
								<ShieldCheck class="w-3.5 h-3.5" />
								<span>Industrial Grade Encryption</span>
							</div>
							<div class="trust-item">
								<Truck class="w-3.5 h-3.5" />
								<span>Express Priority Dispatch</span>
							</div>
						</div>
					</div>
				</aside>
			</div>
		{/if}

		<div class="mt-12">
			<a href="/" class="continue-shopping">
				<ArrowLeft class="w-3.5 h-3.5" /> Continue Shopping
			</a>
		</div>
	</div>
</div>

<style>
    /* Design Tokens */
    :root {
        --font-display: 'Playfair Display', serif;
        --font-body: 'Inter', sans-serif;
        --surface: #faf9f6;
        --border: #f0eeea;
        --on-surface: #1a1c1a;
        --on-surface-muted: #6b7280;
        --radius: 8px;
    }

    .cart-page { background: var(--surface); color: var(--on-surface); font-family: var(--font-body); min-height: 100vh; }
    
    .cart-header { margin-bottom: 3rem; }
    .cart-title { font-family: var(--font-display); font-size: 2.5rem; margin-bottom: 0.5rem; }
    .cart-subtitle { font-size: 0.875rem; color: var(--on-surface-muted); }

    /* Layout */
    .cart-layout { display: grid; grid-template-columns: 1fr; gap: 4rem; }
    @media (min-width: 1024px) { .cart-layout { grid-template-columns: 1fr 380px; } }

    /* Rows */
    .cart-row { display: flex; gap: 1.5rem; padding: 2rem 0; border-bottom: 1px solid var(--border); }
    .item-img-wrap { width: 100px; aspect-ratio: 3/4; border-radius: var(--radius); overflow: hidden; background: #fff; border: 1px solid var(--border); }
    .item-img { width: 100%; height: 100%; object-fit: cover; }
    .item-placeholder { display: flex; align-items: center; justify-content: center; height: 100%; color: #f3f4f6; }
    
    .item-info { flex: 1; display: flex; flex-direction: column; justify-content: space-between; }
    .item-name { font-family: var(--font-display); font-size: 1.25rem; margin-bottom: 0.25rem; }
    .item-price { font-weight: 600; font-size: 0.875rem; }

    .item-controls { display: flex; align-items: center; justify-content: space-between; margin-top: 1rem; }
    .qty-control { display: flex; align-items: center; gap: 1rem; background: #fff; border: 1px solid var(--border); padding: 4px 8px; border-radius: 4px; }
    .qty-btn { opacity: 0.4; transition: opacity 0.2s; }
    .qty-btn:hover { opacity: 1; }
    .qty-val { font-size: 0.75rem; font-weight: 700; min-width: 1rem; text-align: center; }
    
    .remove-btn { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); }
    .remove-btn:hover { color: #ef4444; }

    /* Summary */
    .summary-box { background: #fff; border: 1px solid var(--border); padding: 2.5rem; border-radius: var(--radius); position: sticky; top: 120px; }
    .summary-title { font-family: var(--font-display); font-size: 1.5rem; margin-bottom: 2rem; }

    .order-type-tabs { display: grid; grid-template-columns: 1fr 1fr; background: var(--surface); padding: 4px; border-radius: 6px; margin-bottom: 2rem; }
    .type-tab { padding: 8px; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; border-radius: 4px; transition: all 0.3s; }
    .type-tab.active { background: #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.05); color: var(--on-surface); }
    .type-tab:not(.active) { color: var(--on-surface-muted); }

    .summary-details { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem; }
    .summary-row { display: flex; justify-content: space-between; font-size: 0.875rem; color: var(--on-surface-muted); }
    .summary-total { display: flex; justify-content: space-between; font-weight: 700; font-size: 1.125rem; color: var(--on-surface); border-top: 1px solid var(--border); padding-top: 1.5rem; margin-top: 1rem; }

    .btn-primary { 
        width: 100%; padding: 1.25rem; background: var(--on-surface); color: #fff; 
        border-radius: var(--radius); font-size: 0.75rem; font-weight: 700; 
        text-transform: uppercase; letter-spacing: 0.15em; display: flex; 
        align-items: center; justify-content: center; gap: 0.75rem;
        transition: all 0.3s;
    }
    .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 10px 20px rgba(0,0,0,0.1); }
    .btn-primary:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }

    .trust-points { display: flex; flex-direction: column; gap: 0.75rem; margin-top: 2rem; border-top: 1px solid var(--border); padding-top: 1.5rem; }
    .trust-item { display: flex; align-items: center; gap: 0.75rem; color: var(--on-surface-muted); font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }

    .continue-shopping { display: inline-flex; align-items: center; gap: 0.5rem; font-size: 0.75rem; font-weight: 600; color: var(--on-surface-muted); transition: color 0.2s; }
    .continue-shopping:hover { color: var(--on-surface); }

    /* Empty State */
    .empty-cart { text-align: center; padding: 6rem 0; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); }
    .empty-icon { opacity: 0.1; display: flex; justify-content: center; margin-bottom: 2rem; }
    .empty-msg { font-family: var(--font-display); font-size: 1.75rem; margin-bottom: 0.5rem; }
    .empty-sub { font-size: 0.875rem; color: var(--on-surface-muted); margin-bottom: 2.5rem; }
    .empty-cta { max-width: 240px; margin: 0 auto; }

    /* Loader */
    .loader-dot { width: 4px; height: 4px; background: currentColor; border-radius: 50%; animation: pulse 0.6s infinite alternate; }
    @keyframes pulse { to { transform: scale(1.5); opacity: 0.5; } }
</style>
