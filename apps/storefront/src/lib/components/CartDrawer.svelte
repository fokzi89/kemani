<script lang="ts">
	import { ShoppingBag, X, ArrowRight, Trash2, ShoppingCart, Plus, Minus } from 'lucide-svelte';
	import { fade, fly } from 'svelte/transition';
	import { cartStore, cartSubtotal, cartCount, cartServiceCharge, cartTotal } from '$lib/stores/cart.store';
	import { isCartOpen, toggleCart } from '$lib/stores/ui';
	import { goto } from '$app/navigation';

	function handleCheckout() {
		toggleCart();
		goto('/checkout');
	}
</script>

{#if $isCartOpen}
	<!-- Back-drop -->
	<div 
		class="fixed inset-0 z-[100] bg-gray-900/60 backdrop-blur-sm"
		on:click={toggleCart}
		on:keydown={(e) => e.key === 'Escape' && toggleCart()}
		transition:fade={{ duration: 200 }}
	></div>

	<!-- Drawer -->
	<div 
		class="fixed inset-y-0 right-0 z-[101] w-full max-w-md bg-white shadow-2xl flex flex-col"
		transition:fly={{ x: 400, duration: 400, opacity: 1 }}
	>
		<!-- Header -->
		<div class="px-6 py-8 border-b border-gray-100 flex items-center justify-between">
			<div class="flex items-center gap-4">
				<div class="h-12 w-12 bg-gray-900 text-white rounded-2xl flex items-center justify-center shadow-xl shadow-gray-200">
					<ShoppingBag class="h-6 w-6" />
				</div>
				<div>
					<h3 class="text-xl font-display tracking-tight text-gray-900">Your Shopping Bag</h3>
					<p class="text-[10px] text-gray-400 font-bold uppercase tracking-[0.2em]">{$cartCount} Items Selected</p>
				</div>
			</div>
			<button 
				on:click={toggleCart}
				class="p-2.5 hover:bg-gray-100 rounded-full transition-all duration-300 group"
			>
				<X class="h-6 w-6 text-gray-400 group-hover:rotate-90 group-hover:text-gray-900 transition-all" />
			</button>
		</div>

		<!-- Body -->
		<div class="flex-1 overflow-y-auto px-6 py-6 custom-scrollbar">
			{#if $cartStore.items.length === 0}
				<div class="h-full flex flex-col items-center justify-center text-gray-300 gap-6 py-12">
					<div class="relative">
						<div class="h-24 w-24 bg-gray-50 rounded-full flex items-center justify-center border border-dashed border-gray-200">
							<ShoppingCart class="h-10 w-10 text-gray-200" />
						</div>
						<div class="absolute -bottom-2 -right-2 h-10 w-10 bg-white rounded-full flex items-center justify-center shadow-sm border border-gray-100">
							<Plus class="h-5 w-5 text-gray-400" />
						</div>
					</div>
					<div class="text-center space-y-2">
						<p class="text-sm font-bold text-gray-900 uppercase tracking-widest">Your bag is empty</p>
						<p class="text-[10px] text-gray-400 uppercase tracking-widest leading-relaxed">Discover our collection and<br/>find something special.</p>
					</div>
					<button 
						on:click={toggleCart}
						class="mt-4 px-8 py-3 bg-gray-900 text-white text-[10px] font-bold uppercase tracking-widest rounded-full hover:bg-gray-800 transition-all"
					>
						Start Shopping
					</button>
				</div>
			{:else}
				<div class="space-y-6">
					{#each $cartStore.items as item}
						<div class="flex gap-5 group animate-in fade-in slide-in-from-right-4 duration-500">
							<!-- Product Image -->
							<div class="h-24 w-24 bg-gray-50 rounded-2xl overflow-hidden shadow-sm flex-shrink-0 border border-gray-100 group-hover:shadow-md transition-all">
								{#if item.image_url}
									<img src={item.image_url} alt={item.name} class="h-full w-full object-cover group-hover:scale-110 transition-transform duration-500" />
								{:else}
									<div class="h-full w-full flex items-center justify-center text-gray-200">
										<ShoppingBag class="h-8 w-8" />
									</div>
								{/if}
							</div>

							<!-- Details -->
							<div class="flex-1 flex flex-col py-1">
								<div class="flex justify-between items-start gap-2">
									<div>
										<h4 class="text-[11px] font-bold text-gray-900 uppercase tracking-tight leading-tight mb-1">{item.name || item.product_name}</h4>
										{#if item.sku}
											<p class="text-[9px] text-gray-400 font-medium uppercase tracking-widest">{item.sku}</p>
										{/if}
									</div>
									<button 
										on:click={() => cartStore.removeItem(item.product_id)}
										class="p-1 text-gray-300 hover:text-red-500 transition-colors"
									>
										<Trash2 class="h-4 w-4" />
									</button>
								</div>
								
								<div class="mt-auto flex items-center justify-between">
									<!-- Quantity Control -->
									<div class="flex items-center bg-gray-50 rounded-lg p-1 border border-gray-100">
										<button 
											on:click={() => cartStore.updateQuantity(item.product_id, item.quantity - 1)}
											class="w-7 h-7 rounded-md bg-white shadow-sm border border-gray-200 flex items-center justify-center text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
										>
											<Minus class="h-3 w-3" />
										</button>
										<span class="w-8 text-center text-[10px] font-bold text-gray-900">{item.quantity}</span>
										<button 
											on:click={() => cartStore.updateQuantity(item.product_id, item.quantity + 1)}
											class="w-7 h-7 rounded-md bg-white shadow-sm border border-gray-200 flex items-center justify-center text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
										>
											<Plus class="h-3 w-3" />
										</button>
									</div>
									<p class="text-[11px] font-bold text-gray-900">₦{((item.unit_price || item.price || 0) * item.quantity).toLocaleString()}</p>
								</div>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<!-- Footer -->
		<div class="p-8 bg-white border-t border-gray-100 space-y-6">
			<div class="space-y-3">
				<div class="flex items-center justify-between text-[10px] font-bold uppercase tracking-[0.2em] text-gray-400">
					<span>Subtotal</span>
					<span class="text-gray-900">₦{($cartSubtotal || 0).toLocaleString()}</span>
				</div>
				<div class="flex items-center justify-between text-[10px] font-bold uppercase tracking-[0.2em] text-gray-400">
					<span>Service Charge</span>
					<span class="text-gray-900">₦{($cartServiceCharge || 0).toLocaleString()}</span>
				</div>
				<div class="flex items-center justify-between text-[11px] font-bold uppercase tracking-[0.2em] text-gray-900 pt-3 border-t border-gray-50">
					<span>Total Amount</span>
					<span class="text-xl font-display tracking-tight">₦{($cartTotal || 0).toLocaleString()}</span>
				</div>
			</div>
			
			<div class="flex flex-col gap-3">
				<button 
					on:click={handleCheckout}
					class="w-full py-5 bg-gray-900 text-white text-[11px] font-bold uppercase tracking-[0.2em] rounded-2xl hover:bg-black transition-all flex items-center justify-center gap-3 shadow-xl shadow-gray-200 group active:scale-[0.98]"
				>
					Checkout Now <ArrowRight class="h-4 w-4 group-hover:translate-x-1 transition-transform" />
				</button>
				<button 
					on:click={toggleCart}
					class="w-full py-4 text-[10px] font-bold uppercase tracking-[0.2em] text-gray-400 hover:text-gray-900 transition-colors"
				>
					Continue Shopping
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	.custom-scrollbar::-webkit-scrollbar {
		width: 4px;
	}
	.custom-scrollbar::-webkit-scrollbar-track {
		background: transparent;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb {
		background: #f1f5f9;
		border-radius: 10px;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb:hover {
		background: #e2e8f0;
	}
</style>
