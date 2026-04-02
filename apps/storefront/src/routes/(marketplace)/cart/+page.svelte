<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ShoppingCart, Trash2, Plus, Minus, ArrowLeft, 
		CreditCard, ShieldCheck, Truck, Tag, Ticket, ChevronRight 
	} from 'lucide-svelte';

	export let data;

	// Injected from layout context
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
	let loyaltyPointsAvailable = 450; 
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
			saveCart();
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

	$: subtotal = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
	$: tax = subtotal * 0.075; 
	$: actualDeliveryFee = orderType === 'delivery' ? deliveryFee : 0;
	$: loyaltyDiscount = loyaltyPointsToRedeem * 10; 
	$: total = subtotal + tax + actualDeliveryFee - loyaltyDiscount;

	$: maxRedeemablePoints = Math.min(
		loyaltyPointsAvailable,
		Math.floor(subtotal / 10) 
	);

	function handleLoyaltyPointsChange() {
		if (loyaltyPointsToRedeem > maxRedeemablePoints) loyaltyPointsToRedeem = maxRedeemablePoints;
		if (loyaltyPointsToRedeem < 0) loyaltyPointsToRedeem = 0;
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
			loyalty_points_to_redeem: loyaltyPointsToRedeem,
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

<div class="min-h-screen bg-[#F8FAFC]">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-20">
		
		{#if cart.items.length === 0}
			<div class="bg-white rounded-[40px] p-24 text-center border border-dashed border-gray-100 flex flex-col items-center">
				<div class="h-24 w-24 bg-gray-50 rounded-full flex items-center justify-center mb-8">
					<ShoppingCart class="h-10 w-10 text-gray-200" />
				</div>
				<h3 class="text-3xl font-black text-gray-900 tracking-tight uppercase">Your bag is empty</h3>
				<p class="text-gray-500 mt-3 max-w-sm font-medium leading-relaxed uppercase text-xs tracking-widest">Discover our premium healthcare collection and start your wellness journey.</p>
				<a 
					href="/"
					class="mt-10 px-12 py-5 text-white font-black rounded-3xl shadow-2xl transition-all active:scale-95 uppercase tracking-[0.2em] text-[11px]"
                    style="background: var(--brand); box-shadow: 0 20px 40px {brandColor}22;"
				>
					Start Shopping
				</a>
			</div>
		{:else}
			<div class="grid lg:grid-cols-3 gap-16">
				<!-- Cart Items -->
				<div class="lg:col-span-2 space-y-8">
					<div class="flex justify-between items-end border-b border-gray-100 pb-6">
						<div class="space-y-1">
                            <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Review your selection</p>
						    <h2 class="text-3xl font-black text-gray-900 uppercase tracking-tight">Shopping Bag ({cart.items.length})</h2>
                        </div>
						<button on:click={clearCart} class="text-[10px] font-black text-rose-500 hover:text-rose-600 uppercase tracking-[0.2em]">Clear All</button>
					</div>

					<div class="space-y-5">
						{#each cart.items as item, index}
							<div class="group bg-white rounded-[32px] p-6 border border-gray-100 flex flex-col md:flex-row gap-8 transition-all duration-500 hover:shadow-2xl hover:shadow-indigo-500/5">
								<!-- Product Image -->
								<div class="w-full md:w-36 h-36 bg-gray-50 rounded-2xl overflow-hidden flex-shrink-0 p-4">
									{#if item.product_image}
										<img src={item.product_image} alt={item.product_name} class="w-full h-full object-contain group-hover:scale-110 transition-transform duration-700" />
									{:else}
										<div class="w-full h-full flex items-center justify-center text-gray-200"><ShoppingCart class="h-10 w-10" /></div>
									{/if}
								</div>

								<!-- Product Details -->
								<div class="flex-1 flex flex-col">
									<div class="flex justify-between items-start gap-4">
										<div class="space-y-1">
                                            <p class="text-[9px] font-black uppercase tracking-[0.2em]" style="color:var(--brand);">Inventory Item</p>
											<h3 class="text-xl font-black text-gray-900 leading-tight transition-colors uppercase tracking-tight cursor-default">{item.product_name}</h3>
										</div>
										<button on:click={() => removeItem(index)} class="h-10 w-10 flex items-center justify-center text-gray-200 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all"><Trash2 class="h-5 w-5" /></button>
									</div>

									<div class="mt-auto pt-8 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
										<div class="flex items-center gap-2 p-1.5 bg-gray-50 rounded-2xl border border-gray-100">
											<button 
												on:click={() => updateQuantity(index, item.quantity - 1)}
												class="h-10 w-10 bg-white rounded-xl flex items-center justify-center text-gray-900 hover:bg-gray-950 hover:text-white transition-all shadow-sm active:scale-90"
											><Minus class="h-4 w-4" /></button>
											<span class="w-12 text-center text-lg font-black text-gray-900 tracking-tighter">{item.quantity}</span>
											<button 
												on:click={() => updateQuantity(index, item.quantity + 1)}
												class="h-10 w-10 bg-white rounded-xl flex items-center justify-center text-gray-900 hover:bg-gray-950 hover:text-white transition-all shadow-sm active:scale-90"
											><Plus class="h-4 w-4" /></button>
										</div>

										<div class="text-right">
											<p class="text-[10px] font-black text-gray-300 uppercase tracking-widest mb-1">Subtotal</p>
											<p class="text-2xl font-black text-gray-900 tracking-tighter">₦{(item.price * item.quantity).toLocaleString()}</p>
										</div>
									</div>
								</div>
							</div>
						{/each}
					</div>

					<!-- Trust Strip -->
					<div class="bg-white p-8 rounded-[40px] border border-gray-100 grid grid-cols-2 md:grid-cols-3 gap-8">
                        <div class="flex items-center gap-4">
                            <div class="h-12 w-12 rounded-2xl flex items-center justify-center" style="background:{brandColorLight};color:var(--brand);"><ShieldCheck class="w-6 h-6" /></div>
                            <div><p class="text-[11px] font-black uppercase tracking-widest">Secure</p><p class="text-[10px] font-medium text-gray-400">SSL Encrypted</p></div>
                        </div>
                        <div class="flex items-center gap-4">
                            <div class="h-12 w-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center"><Truck class="w-6 h-6" /></div>
                            <div><p class="text-[11px] font-black uppercase tracking-widest">Fast</p><p class="text-[10px] font-medium text-gray-400">Real-time Tracking</p></div>
                        </div>
                        <div class="flex items-center gap-4 hidden md:flex">
                            <div class="h-12 w-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center"><Tag class="w-6 h-6" /></div>
                            <div><p class="text-[11px] font-black uppercase tracking-widest">Quality</p><p class="text-[10px] font-medium text-gray-400">Verified Stocks</p></div>
                        </div>
                    </div>
				</div>

				<!-- Bag Summary -->
				<div class="lg:col-span-1">
					<div class="bg-white rounded-[44px] p-10 border border-gray-100 shadow-2xl shadow-gray-200/50 sticky top-32 space-y-10">
						<h3 class="text-[11px] font-black text-gray-400 uppercase tracking-[0.3em] border-b border-gray-50 pb-6">Payment Summary</h3>

						<!-- Order Type Selection -->
						<div class="flex p-1.5 bg-gray-50 rounded-[28px] border border-gray-100">
							<button 
								on:click={() => orderType = 'delivery'}
								class="flex-1 py-4 px-4 rounded-[22px] text-[10px] font-black uppercase tracking-widest transition-all duration-300 {orderType === 'delivery' ? 'bg-gray-950 text-white shadow-xl' : 'text-gray-400 hover:text-gray-900'}"
							>
								Home Delivery
							</button>
							<button 
								on:click={() => orderType = 'pickup'}
								class="flex-1 py-4 px-4 rounded-[22px] text-[10px] font-black uppercase tracking-widest transition-all duration-300 {orderType === 'pickup' ? 'bg-gray-950 text-white shadow-xl' : 'text-gray-400 hover:text-gray-900'}"
							>
								Pick up
							</button>
						</div>

						<!-- Costs Breakdown -->
						<div class="space-y-5">
							<div class="flex justify-between items-center text-[11px] font-black text-gray-400 uppercase tracking-widest">
								<span>Merchandise</span>
								<span class="text-gray-900 font-black">₦{subtotal.toLocaleString()}</span>
							</div>
							<div class="flex justify-between items-center text-[11px] font-black text-gray-400 uppercase tracking-widest">
								<span>VAT (7.5%)</span>
								<span class="text-gray-900 font-black">₦{tax.toLocaleString(undefined, { maximumFractionDigits: 1 })}</span>
							</div>
							<div class="flex justify-between items-center text-[11px] font-black text-gray-400 uppercase tracking-widest">
								<span>Shipping</span>
								<span class={orderType === 'delivery' ? 'text-gray-900' : 'text-emerald-500'}>
									{orderType === 'delivery' ? `₦${actualDeliveryFee.toLocaleString()}` : 'FREE'}
								</span>
							</div>
						</div>

						<!-- Grand Total -->
						<div class="pt-10 border-t border-gray-100 flex flex-col gap-3">
							<p class="text-[11px] font-black text-gray-400 uppercase tracking-[0.2em] leading-none">Estimated Total</p>
							<p class="text-5xl font-black text-gray-950 tracking-tighter">₦{total.toLocaleString(undefined, { maximumFractionDigits: 0 })}</p>
						</div>

						<!-- Checkout Button -->
						<button 
							on:click={proceedToCheckout}
							disabled={isLoading}
							class="w-full py-7 text-white text-[11px] font-black rounded-[32px] shadow-2xl transition-all flex items-center justify-center gap-4 uppercase tracking-[0.3em] active:scale-95 disabled:opacity-50"
                            style="background: var(--brand); box-shadow: 0 20px 40px {brandColor}33;"
						>
							{#if isLoading}
								<div class="animate-spin h-4 w-4 border-2 border-white/30 border-t-white rounded-full"></div>
								Processing...
							{:else}
								Secure Checkout <ChevronRight class="h-4 w-4" />
							{/if}
						</button>

						<!-- Payment Badges -->
						<div class="pt-4 flex items-center justify-center gap-6 opacity-30 grayscale hover:grayscale-0 transition-all duration-700">
							<CreditCard class="h-6 w-6" />
                            <div class="h-4 w-px bg-gray-200"></div>
							<span class="text-[10px] font-black uppercase tracking-widest">Paystack Secured</span>
						</div>
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) { font-family: 'Outfit', 'Inter', sans-serif; }
</style>
