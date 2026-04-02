<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ShoppingCart, Trash2, Plus, Minus, ArrowLeft, 
		CreditCard, ShieldCheck, Truck, Tag, Ticket 
	} from 'lucide-svelte';

	// The tenant is identified by the host (Approach 2)
	$: tenantSlug = data.tenant.slug;
	export let data: { tenant: any; referringTenantId: string | null };

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
	let loyaltyPointsAvailable = 450; // Dummy points for visual demo
	let loyaltyPointsToRedeem = 0;
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
				const data = JSON.parse(cartData);
				// Map legacy keys if any (product_id vs id)
				cart = data;
			}
		} catch (err) {
			console.error('Failed to load cart:', err);
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
			saveCart();
		} else {
			alert(`Only ${item.stock_available} units available in stock`);
		}
	}

	function removeItem(index: number) {
		cart.items.splice(index, 1);
		cart = cart; 
		saveCart();
	}

	function clearCart() {
		if (confirm('Are you sure you want to clear your cart?')) {
			cart = { items: [] };
			saveCart();
		}
	}

	function continueShopping() {
		goto(`/`);
	}

	$: subtotal = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
	$: tax = subtotal * 0.075; // 7.5% VAT
	$: actualDeliveryFee = orderType === 'delivery' ? deliveryFee : 0;
	$: loyaltyDiscount = loyaltyPointsToRedeem * 10; // 1 point = ₦10 discount
	$: total = subtotal + tax + actualDeliveryFee - loyaltyDiscount;

	$: maxRedeemablePoints = Math.min(
		loyaltyPointsAvailable,
		Math.floor(subtotal / 10) 
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
		if (cart.items.length === 0) return;
		isLoading = true;
		
		const orderData = {
			items: cart.items,
			subtotal,
			tax,
			delivery_fee: actualDeliveryFee,
			loyalty_discount: loyaltyDiscount,
			total,
			order_type: orderType
		};

		localStorage.setItem('checkout_data', JSON.stringify(orderData));
		// Navigate to the host-relative checkout page
		goto(`/checkout`);
	}
</script>

<svelte:head>
	<title>Your Bag - Kemani Shop</title>
</svelte:head>

<div class="min-h-screen bg-[#F8FAFC]">
	<!-- Simple Navbar for Cart -->
	<nav class="bg-white border-b border-gray-100 sticky top-0 z-[60] shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex items-center justify-between h-20">
				<button 
					on:click={continueShopping}
					class="flex items-center gap-2 text-sm font-black text-gray-500 hover:text-indigo-600 transition-colors uppercase tracking-widest"
				>
					<ArrowLeft class="h-4 w-4" /> Keep Shopping
				</button>
				
				<div class="flex items-center gap-2">
					<div class="h-10 w-10 bg-indigo-50 rounded-xl flex items-center justify-center">
						<ShoppingCart class="h-6 w-6 text-indigo-600" />
					</div>
					<span class="text-xl font-black text-gray-900 tracking-tight">Your Shopping Bag</span>
				</div>
				
				<div class="w-32 hidden md:block"></div>
			</div>
		</div>
	</nav>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
		{#if cart.items.length === 0}
			<div class="bg-white rounded-3xl p-20 text-center border border-dashed border-gray-200">
				<div class="h-20 w-20 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-6">
					<ShoppingCart class="h-10 w-10 text-gray-300" />
				</div>
				<h3 class="text-2xl font-black text-gray-900">Your bag is empty</h3>
				<p class="text-gray-500 mt-2 max-w-sm mx-auto font-medium">Looks like you haven't added anything to your cart yet. Browse our marketplace to find premium healthcare essentials.</p>
				<button 
					on:click={continueShopping}
					class="mt-8 px-10 py-4 bg-indigo-600 text-white font-black rounded-2xl shadow-xl shadow-indigo-100 hover:scale-105 transition-all active:scale-95 uppercase tracking-widest text-xs"
				>
					Explore Marketplace
				</button>
			</div>
		{:else}
			<div class="grid lg:grid-cols-3 gap-12">
				<!-- Cart Items -->
				<div class="lg:col-span-2 space-y-6">
					<div class="flex justify-between items-center mb-2">
						<h2 class="text-sm font-black text-gray-400 uppercase tracking-widest">Bag Items ({cart.items.length})</h2>
						<button on:click={clearCart} class="text-xs font-bold text-rose-500 hover:text-rose-600 uppercase tracking-widest">Empty Bag</button>
					</div>

					{#each cart.items as item, index}
						<div class="group bg-white rounded-3xl p-6 border border-gray-100 flex flex-col md:flex-row gap-6 transition-all duration-300 hover:shadow-xl hover:shadow-indigo-500/5">
							<!-- Product Image -->
							<div class="w-full md:w-32 h-32 bg-[#F1F5F9] rounded-2xl overflow-hidden flex-shrink-0">
								{#if item.product_image}
									<img src={item.product_image} alt={item.product_name} class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
								{:else}
									<div class="w-full h-full flex items-center justify-center text-gray-400"><ShoppingCart class="h-8 w-8 opacity-20" /></div>
								{/if}
							</div>

							<!-- Product Details -->
							<div class="flex-1 flex flex-col">
								<div class="flex justify-between items-start">
									<div>
										<h3 class="text-lg font-black text-gray-900 leading-tight group-hover:text-indigo-600 transition-colors uppercase tracking-tight">{item.product_name}</h3>
										<p class="text-[10px] font-black text-indigo-400 uppercase tracking-widest mt-1">Authentic Product</p>
									</div>
									<button on:click={() => removeItem(index)} class="text-gray-300 hover:text-rose-500 p-1 transition-colors"><Trash2 class="h-5 w-5" /></button>
								</div>

								<div class="mt-auto pt-6 flex flex-col md:flex-row items-start md:items-center justify-between gap-4 border-t border-gray-50">
									<div class="flex items-center gap-1 p-1 bg-gray-50 rounded-xl border border-gray-100">
										<button 
											on:click={() => updateQuantity(index, item.quantity - 1)}
											class="h-8 w-8 bg-white rounded-lg flex items-center justify-center text-gray-500 hover:bg-indigo-600 hover:text-white transition-all shadow-sm"
										><Minus class="h-4 w-4" /></button>
										<span class="w-10 text-center text-sm font-black text-gray-900">{item.quantity}</span>
										<button 
											on:click={() => updateQuantity(index, item.quantity + 1)}
											class="h-8 w-8 bg-white rounded-lg flex items-center justify-center text-gray-500 hover:bg-indigo-600 hover:text-white transition-all shadow-sm"
										><Plus class="h-4 w-4" /></button>
									</div>

									<div class="text-right">
										<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest leading-none mb-1">Item Cost</p>
										<p class="text-xl font-black text-gray-900 tracking-tighter">₦{(item.price * item.quantity).toLocaleString()}</p>
									</div>
								</div>
							</div>
						</div>
					{/each}

					<!-- Promo Code Section -->
					<div class="bg-indigo-50/50 rounded-3xl p-6 border border-indigo-100 flex flex-col md:flex-row items-center justify-between gap-6">
						<div class="flex items-center gap-4 text-indigo-600">
							<Ticket class="h-6 w-6" />
							<div>
								<p class="text-sm font-black uppercase tracking-widest leading-none">Promo Code?</p>
								<p class="text-xs font-medium text-indigo-400 mt-1 uppercase tracking-widest">Apply to items for extra savings</p>
							</div>
						</div>
						<div class="flex gap-2 w-full md:w-auto">
							<input type="text" placeholder="CODE123" class="flex-1 md:w-40 bg-white border border-indigo-200 rounded-xl px-4 py-2 text-xs font-black uppercase tracking-widest outline-none focus:ring-2 focus:ring-indigo-500" />
							<button class="px-6 py-2 bg-indigo-600 text-white text-[10px] font-black rounded-xl uppercase tracking-widest">Apply</button>
						</div>
					</div>
				</div>

				<!-- Bag Summary -->
				<div class="lg:col-span-1">
					<div class="bg-white rounded-[32px] p-8 border border-gray-100 shadow-xl shadow-gray-200/50 sticky top-32 space-y-8">
						<h3 class="text-sm font-black text-gray-900 uppercase tracking-widest border-b border-gray-50 pb-4">Order Summary</h3>

						<!-- Order Type Selection -->
						<div class="flex p-1 bg-gray-50 rounded-2xl border border-gray-100">
							<button 
								on:click={() => orderType = 'delivery'}
								class="flex-1 py-3 px-4 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {orderType === 'delivery' ? 'bg-indigo-600 text-white shadow-lg' : 'text-gray-400 hover:text-gray-900'}"
							>
								Home Delivery
							</button>
							<button 
								on:click={() => orderType = 'pickup'}
								class="flex-1 py-3 px-4 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {orderType === 'pickup' ? 'bg-indigo-600 text-white shadow-lg' : 'text-gray-400 hover:text-gray-900'}"
							>
								Self Pickup
							</button>
						</div>

						<!-- Loyalty Section -->
						<div class="p-4 bg-indigo-50/50 rounded-2xl border border-indigo-100/50 space-y-3">
							<div class="flex items-center justify-between">
								<p class="text-[10px] font-black text-indigo-600 uppercase tracking-widest">Loyalty Balance</p>
								<div class="px-2 py-0.5 bg-indigo-600 rounded-lg text-[9px] font-black text-white">{loyaltyPointsAvailable} PTS</div>
							</div>
							<div class="flex items-center gap-2">
								<input 
									type="number" 
									bind:value={loyaltyPointsToRedeem}
									on:input={handleLoyaltyPointsChange}
									placeholder="Points to use" 
									class="flex-1 bg-white border border-indigo-200 rounded-xl px-4 py-2 text-xs font-black outline-none"
								/>
								<button on:click={() => (loyaltyPointsToRedeem = maxRedeemablePoints)} class="text-[9px] font-black text-indigo-600 uppercase tracking-widest bg-indigo-100 hover:bg-indigo-200 px-3 py-2 rounded-xl transition-colors">Max</button>
							</div>
						</div>

						<!-- Costs -->
						<div class="space-y-4 pt-4 border-t border-gray-50">
							<div class="flex justify-between items-center text-xs font-bold text-gray-500 uppercase tracking-widest">
								<span>Subtotal</span>
								<span class="text-gray-900 font-black">₦{subtotal.toLocaleString()}</span>
							</div>
							<div class="flex justify-between items-center text-xs font-bold text-gray-500 uppercase tracking-widest">
								<span>Tax (VAT 7.5%)</span>
								<span class="text-gray-900 font-black">₦{tax.toLocaleString(undefined, { maximumFractionDigits: 1 })}</span>
							</div>
							<div class="flex justify-between items-center text-xs font-bold text-gray-500 uppercase tracking-widest">
								<span>Delivery</span>
								<span class="text-indigo-600 font-black">
									{#if orderType === 'delivery'}
										₦{actualDeliveryFee.toLocaleString()}
									{:else}
										FREE
									{/if}
								</span>
							</div>
							{#if loyaltyDiscount > 0}
								<div class="flex justify-between items-center text-xs font-bold text-emerald-600 uppercase tracking-widest">
									<span>Loyalty Credit</span>
									<span class="font-black">-₦{loyaltyDiscount.toLocaleString()}</span>
								</div>
							{/if}
						</div>

						<!-- Grand Total -->
						<div class="pt-6 border-t border-gray-100 flex flex-col gap-2">
							<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest leading-none">Grand Total</p>
							<p class="text-4xl font-black text-gray-900 tracking-tighter">₦{total.toLocaleString(undefined, { maximumFractionDigits: 0 })}</p>
						</div>

						<!-- Checkout Button -->
						<button 
							on:click={proceedToCheckout}
							disabled={isLoading}
							class="w-full py-5 bg-indigo-600 text-white text-xs font-black rounded-2xl shadow-xl shadow-indigo-100 hover:bg-gray-900 transition-all flex items-center justify-center gap-3 uppercase tracking-[0.2em] active:scale-95 disabled:opacity-50"
						>
							{#if isLoading}
								<div class="animate-spin h-4 w-4 border-2 border-white/30 border-t-white rounded-full"></div>
								Securing Order...
							{:else}
								Checkout <ArrowLeft class="h-4 w-4 rotate-180" />
							{/if}
						</button>

						<!-- Badges -->
						<div class="flex flex-col gap-3">
							<div class="flex items-center gap-3 grayscale opacity-40">
								<CreditCard class="h-4 w-4" />
								<span class="text-[9px] font-bold uppercase tracking-widest">Secure Payments via Paystack</span>
							</div>
							<div class="flex items-center gap-3 grayscale opacity-40">
								<Truck class="h-4 w-4" />
								<span class="text-[9px] font-bold uppercase tracking-widest">Priority Delivery Guaranteed</span>
							</div>
						</div>
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) {
		font-family: 'Outfit', 'Inter', sans-serif;
	}
</style>
