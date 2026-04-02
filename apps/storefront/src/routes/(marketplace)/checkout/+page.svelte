<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { currentUser } from '$lib/stores/auth';
	import { 
		ShieldCheck, CreditCard, Truck, ArrowLeft, 
		CheckCircle2, Package, Mail, MapPin, ChevronRight, ShoppingBag
	} from 'lucide-svelte';

	export let data;

	// Inherited from layout and server load
	$: storefront = data.storefront;
    $: brandColor = storefront?.brand_color || '#4f46e5';
    $: brandColorLight = brandColor + '18';

	let orderData: any = null;
	let isLoading = false;
	let error = '';
	let success = '';
    let step = 1; // 1: Details, 2: Payment, 3: Confirmation

	onMount(() => {
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
			// Simulate order processing for demonstration
			await new Promise(resolve => setTimeout(resolve, 2000));

			// In reality, here we would call /api/orders/create with Supabase
			localStorage.removeItem('cart');
			localStorage.removeItem('checkout_data');

			success = 'Order placed successfully!';
            step = 3; // Success state

			// Redirect after a delay
			setTimeout(() => {
				goto(`/profile`);
			}, 3000);
		} catch (err: any) {
			error = err.message || 'Failed to place order. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Checkout | {storefront?.name || 'Secure Checkout'}</title>
</svelte:head>

<div class="min-h-screen bg-[#F8FAFC]">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 md:py-16">
		
		<div class="flex flex-col md:flex-row gap-16">
			<!-- Main Checkout Flow -->
			<div class="flex-1 space-y-10">
				{#if success}
					<div class="bg-white rounded-[44px] p-20 text-center border border-gray-100 flex flex-col items-center animate-in fade-in zoom-in duration-700">
						<div class="h-24 w-24 bg-emerald-50 text-emerald-500 rounded-full flex items-center justify-center mb-8">
							<CheckCircle2 class="h-12 w-12" />
						</div>
						<h2 class="text-4xl font-black text-gray-900 tracking-tight uppercase mb-4">You're all set!</h2>
						<p class="text-gray-500 max-w-sm mx-auto font-medium leading-relaxed uppercase text-xs tracking-widest">Your order has been secured. We've sent a confirmed receipt to your email address.</p>
						
                        <div class="mt-12 p-6 bg-gray-50 rounded-[32px] w-full max-w-sm space-y-3">
                            <p class="text-[10px] font-black uppercase tracking-widest text-gray-400">Next Steps</p>
                            <div class="flex items-center gap-3 text-left">
                                <Package class="h-5 w-5 text-indigo-600" />
                                <span class="text-xs font-bold text-gray-600">Preparing your inventory items</span>
                            </div>
                            <div class="flex items-center gap-3 text-left">
                                <Truck class="h-5 w-5 text-emerald-600" />
                                <span class="text-xs font-bold text-gray-600">Dispatch via priority courier</span>
                            </div>
                        </div>

						<button 
							on:click={() => goto('/profile')}
							class="mt-10 px-12 py-5 bg-gray-950 text-white font-black rounded-3xl transition-all active:scale-95 uppercase tracking-[0.2em] text-[11px] shadow-2xl"
						>
							View Order Status
						</button>
					</div>
				{:else}
                    <!-- Steps Indicator -->
                    <div class="flex items-center gap-4 mb-12">
                        <div class="flex items-center gap-2">
                            <div class="h-8 w-8 rounded-full bg-gray-950 text-white flex items-center justify-center text-[10px] font-black">1</div>
                            <span class="text-[10px] font-black uppercase tracking-widest text-gray-900">Details</span>
                        </div>
                        <div class="h-px w-8 bg-gray-200"></div>
                        <div class="flex items-center gap-2 opacity-30">
                            <div class="h-8 w-8 rounded-full bg-gray-200 text-gray-600 flex items-center justify-center text-[10px] font-black">2</div>
                            <span class="text-[10px] font-black uppercase tracking-widest">Payment</span>
                        </div>
                    </div>

					<div class="space-y-8">
						<header class="space-y-2">
							<p class="text-[10px] font-black uppercase tracking-widest opacity-40 leading-none" style="color:var(--brand);">Secure Transaction</p>
							<h1 class="text-4xl md:text-5xl font-black text-gray-900 uppercase tracking-tight leading-none">Confirm order</h1>
						</header>

						{#if error}
							<div class="p-6 bg-rose-50 border border-rose-100 rounded-3xl text-rose-600 flex items-center gap-4 animate-in slide-in-from-top duration-300">
								<ShieldCheck class="h-6 w-6 flex-shrink-0" />
								<p class="text-xs font-black uppercase tracking-widest">{error}</p>
							</div>
						{/if}

						<div class="grid gap-8">
							<!-- Identity Card -->
							<div class="bg-white rounded-[32px] p-8 border border-gray-100 shadow-sm space-y-8">
								<div class="flex items-center justify-between border-b border-gray-50 pb-6">
                                    <div class="flex items-center gap-4">
                                        <div class="h-12 w-12 rounded-2xl flex items-center justify-center bg-gray-50 text-gray-900"><Mail class="h-6 w-6" /></div>
                                        <div><p class="text-[10px] font-black uppercase tracking-widest text-gray-400">Order Contact</p><p class="text-sm font-black text-gray-900">{$currentUser?.email || 'Guest Session'}</p></div>
                                    </div>
                                    <button class="text-[10px] font-black uppercase tracking-widest opacity-30 hover:opacity-100 transition-all">Edit</button>
                                </div>

                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-4">
                                        <div class="h-12 w-12 rounded-2xl flex items-center justify-center bg-gray-50 text-gray-900"><MapPin class="h-6 w-6" /></div>
                                        <div>
                                            <p class="text-[10px] font-black uppercase tracking-widest text-gray-400">Delivery Method</p>
                                            <p class="text-sm font-black text-gray-900 uppercase tracking-tight">
                                                {orderData?.order_type === 'delivery' ? 'Home Delivery (Standard)' : 'Self Collection (Store Front)'}
                                            </p>
                                        </div>
                                    </div>
                                    <span class="px-4 py-1.5 bg-emerald-50 text-emerald-600 rounded-full text-[9px] font-black uppercase tracking-widest">Active</span>
                                </div>
							</div>

                            <!-- Payment Method Card -->
                            <div class="bg-white rounded-[32px] p-8 border border-gray-100 shadow-sm space-y-6">
                                <h3 class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Available Methods</h3>
                                <div class="p-5 rounded-2xl border-2 border-indigo-600 bg-indigo-50/30 flex items-center justify-between group cursor-pointer transition-all">
                                    <div class="flex items-center gap-5">
                                        <div class="h-12 w-12 bg-white rounded-xl shadow-sm flex items-center justify-center text-indigo-600"><CreditCard class="h-6 w-6" /></div>
                                        <div><p class="text-sm font-black text-indigo-900 uppercase tracking-widest">Paystack Integrated</p><p class="text-[10px] font-medium text-indigo-400 leading-none">Cards, Transfers, Bank, USSD</p></div>
                                    </div>
                                    <CheckCircle2 class="h-5 w-5 text-indigo-600" />
                                </div>
                            </div>

                            <!-- Notice -->
                            <div class="p-8 bg-gray-900 rounded-[32px] flex items-center gap-6 group hover:translate-x-1 transition-transform">
                                <div class="h-14 w-14 rounded-2xl flex items-center justify-center bg-white/10 text-white/40 group-hover:text-amber-400 transition-colors"><ShieldCheck class="h-8 w-8" /></div>
                                <div class="space-y-1">
                                    <p class="text-[10px] font-black uppercase tracking-[0.2em] text-white/40">Secure Settlement</p>
                                    <p class="text-xs text-white/80 font-medium max-w-sm">This store uses industrial-grade encryption for all financial settlements. Your data is never stored locally.</p>
                                </div>
                            </div>
						</div>
					</div>
				{/if}
			</div>

			<!-- Sidebar Summary -->
			{#if orderData && !success}
				<div class="w-full md:w-[420px]">
					<div class="bg-white rounded-[44px] p-10 border border-gray-100 shadow-2xl shadow-gray-200/50 space-y-10 sticky top-28">
						<header class="flex items-baseline justify-between border-b border-gray-50 pb-6">
                            <h3 class="text-[11px] font-black text-gray-900 uppercase tracking-[0.3em]">Final Summary</h3>
                            <ShoppingBag class="h-4 w-4 opacity-20" />
                        </header>

						<div class="space-y-6 max-h-48 overflow-y-auto pr-4 scrollbar-hide">
							{#each orderData.items as item}
								<div class="flex items-center gap-5 group">
									<div class="h-14 w-14 bg-gray-50 rounded-2xl overflow-hidden flex-shrink-0 p-2">
										<img src={item.product_image} alt={item.product_name} class="w-full h-full object-contain group-hover:scale-110 transition-all duration-500" />
									</div>
									<div class="flex-1 min-w-0">
										<h4 class="text-[11px] font-black text-gray-900 uppercase tracking-tight truncate">{item.product_name}</h4>
										<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">{item.quantity} x Item</p>
									</div>
									<p class="text-xs font-black text-gray-900">₦{(item.price * item.quantity).toLocaleString()}</p>
								</div>
							{/each}
						</div>

						<div class="space-y-4 pt-4 border-t border-gray-50">
							<div class="flex justify-between items-center text-[11px] font-black text-gray-400 uppercase tracking-widest">
								<span>Merchandise</span>
								<span class="text-gray-900">₦{orderData.subtotal.toLocaleString()}</span>
							</div>
							<div class="flex justify-between items-center text-[11px] font-black text-gray-400 uppercase tracking-widest">
								<span>Processing (VAT)</span>
								<span class="text-gray-900">₦{orderData.tax.toLocaleString(undefined, { maximumFractionDigits: 0 })}</span>
							</div>
							{#if orderData.delivery_fee > 0}
								<div class="flex justify-between items-center text-[11px] font-black text-gray-400 uppercase tracking-widest">
									<span>Logistic Fee</span>
									<span class="text-gray-900">₦{orderData.delivery_fee.toLocaleString()}</span>
								</div>
							{/if}
							{#if orderData.loyalty_discount > 0}
								<div class="flex justify-between items-center text-[11px] font-black text-emerald-600 uppercase tracking-widest">
									<span>Loyalty credit</span>
									<span class="font-black">-₦{orderData.loyalty_discount.toLocaleString()}</span>
								</div>
							{/if}
						</div>

						<div class="pt-8 border-t border-gray-100 flex flex-col gap-3">
							<p class="text-[11px] font-black text-gray-400 uppercase tracking-[0.2em] leading-none">Total Settlement</p>
							<p class="text-5xl font-black text-gray-950 tracking-tighter">₦{orderData.total.toLocaleString(undefined, { maximumFractionDigits: 0 })}</p>
						</div>

						<button
							on:click={completeOrder}
							disabled={isLoading}
							class="w-full py-7 text-white text-[11px] font-black rounded-[32px] shadow-2xl transition-all flex items-center justify-center gap-4 uppercase tracking-[0.3em] active:scale-95 disabled:opacity-50"
                            style="background: var(--brand); box-shadow: 0 20px 40px {brandColor}33;"
						>
							{#if isLoading}
								<div class="animate-spin h-5 w-5 border-2 border-white/20 border-t-white rounded-full"></div>
								Securing Order...
							{:else}
								Authorize & Pay <ChevronRight class="h-4 w-4" />
							{/if}
						</button>
                        
                        <a href="/cart" class="w-full h-14 flex items-center justify-center text-[10px] font-black uppercase tracking-widest text-gray-400 hover:text-gray-900 transition-all">
                            Modify selection
                        </a>
					</div>
				</div>
			{/if}
		</div>
	</div>
</div>

<style>
	:global(body) { font-family: 'Outfit', 'Inter', sans-serif; }
    .scrollbar-hide::-webkit-scrollbar { display: none; }
	.scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
</style>
