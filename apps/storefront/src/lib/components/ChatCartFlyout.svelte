<script lang="ts">
	import { onMount } from 'svelte';
	import { ShoppingBag, X, ArrowRight, Trash2, ShoppingCart } from 'lucide-svelte';
	import { fade, fly } from 'svelte/transition';

	let { show = false, onClose } = $props();

	let cart = $state({ items: [] as any[] });
	let total = $derived(cart.items.reduce((sum: number, item: any) => sum + (item.price * item.quantity), 0));

	function loadCart() {
		try {
			const saved = localStorage.getItem('cart');
			if (saved) cart = JSON.parse(saved);
		} catch (e) {
			console.error('Failed to load cart:', e);
		}
	}

	$effect(() => {
		if (show) {
			loadCart();
		}
	});

	function removeFromCart(id: string) {
		cart.items = cart.items.filter((i: any) => i.product_id !== id);
		localStorage.setItem('cart', JSON.stringify(cart));
		window.dispatchEvent(new Event('cart-updated'));
	}

	function updateQuantity(id: string, delta: number) {
		const item = cart.items.find((i: any) => i.product_id === id);
		if (item) {
			item.quantity = Math.max(1, item.quantity + delta);
			localStorage.setItem('cart', JSON.stringify(cart));
			window.dispatchEvent(new Event('cart-updated'));
		}
	}
</script>

{#if show}
	<!-- Back-drop -->
	<div 
		class="fixed inset-0 z-[100] bg-gray-900/40 backdrop-blur-sm"
		onclick={onClose}
		transition:fade
	></div>

	<!-- Drawer -->
	<div 
		class="fixed inset-y-0 right-0 z-[101] w-full max-w-sm bg-white shadow-2xl flex flex-col"
		transition:fly={{ x: 300, duration: 400 }}
	>
		<!-- Header -->
		<div class="px-6 py-6 border-b border-gray-100 flex items-center justify-between">
			<div class="flex items-center gap-3">
				<div class="h-10 w-10 bg-gray-900 text-white rounded-xl flex items-center justify-center shadow-lg shadow-gray-200">
					<ShoppingBag class="h-5 w-5" />
				</div>
				<div>
					<h3 class="text-lg font-bold text-gray-900">Your Bag</h3>
					<p class="text-[10px] text-gray-400 font-bold uppercase tracking-widest">{cart.items.length} Items Selected</p>
				</div>
			</div>
			<button 
				onclick={onClose}
				class="p-2 hover:bg-gray-100 rounded-full transition-colors"
			>
				<X class="h-5 w-5 text-gray-400" />
			</button>
		</div>

		<!-- Body -->
		<div class="flex-1 overflow-y-auto px-6 py-4 space-y-6">
			{#if cart.items.length === 0}
				<div class="h-full flex flex-col items-center justify-center text-gray-300 gap-4">
					<div class="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center border border-dashed border-gray-200">
						<ShoppingCart class="h-8 w-8" />
					</div>
					<div class="text-center">
						<p class="text-sm font-bold text-gray-500 uppercase tracking-widest">Nothing Here Yet</p>
						<p class="text-[10px] text-gray-400 mt-1 uppercase">Browse items to add them to your bag</p>
					</div>
				</div>
			{:else}
				<div class="space-y-4">
					{#each cart.items as item}
						<div class="flex gap-4 p-3 bg-gray-50/50 rounded-2xl border border-gray-100/50 group animate-in fade-in slide-in-from-right-4">
							<div class="h-16 w-16 bg-white rounded-xl overflow-hidden shadow-sm flex-shrink-0">
								{#if item.product_image}
									<img src={item.product_image} alt={item.product_name} class="h-full w-full object-cover" />
								{:else}
									<div class="h-full w-full flex items-center justify-center text-gray-200">
										<ShoppingBag class="h-6 w-6" />
									</div>
								{/if}
							</div>
							<div class="flex-1 min-w-0">
								<h4 class="text-xs font-bold text-gray-900 truncate uppercase tracking-tight">{item.product_name}</h4>
								<p class="text-[10px] text-primary-700 font-black mt-1">₦{item.price?.toLocaleString()}</p>
								
								<!-- Quantity Control -->
								<div class="flex items-center gap-3 mt-2">
									<button 
										onclick={() => updateQuantity(item.product_id, -1)}
										class="w-6 h-6 rounded-md bg-white border border-gray-200 flex items-center justify-center text-xs font-bold hover:bg-gray-100"
									>-</button>
									<span class="text-[10px] font-bold text-gray-700">{item.quantity}</span>
									<button 
										onclick={() => updateQuantity(item.product_id, 1)}
										class="w-6 h-6 rounded-md bg-white border border-gray-200 flex items-center justify-center text-xs font-bold hover:bg-gray-100"
									>+</button>
								</div>
							</div>
							<button 
								onclick={() => removeFromCart(item.product_id)}
								class="p-2 h-fit text-gray-300 hover:text-red-500 transition-colors"
							>
								<Trash2 class="h-4 w-4" />
							</button>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<!-- Footer -->
		<div class="p-6 bg-white border-t border-gray-100 space-y-4">
			<div class="flex items-center justify-between text-sm font-bold uppercase tracking-widest text-gray-900">
				<span>Summary Total</span>
				<span class="text-lg">₦{total?.toLocaleString()}</span>
			</div>
			<div class="flex gap-2">
				<button 
					onclick={onClose}
					class="flex-1 py-4 text-[10px] font-bold uppercase tracking-widest text-gray-500 border border-gray-200 rounded-xl hover:bg-gray-50 transition-all"
				>
					Keep Browsing
				</button>
				<a 
					href="/checkout"
					class="flex-[1.5] py-4 bg-black text-white text-[10px] font-bold uppercase tracking-widest rounded-xl hover:bg-gray-800 transition-all flex items-center justify-center gap-2 shadow-xl shadow-gray-200"
				>
					Proceed To Pay <ArrowRight class="h-3 w-3" />
				</a>
			</div>
		</div>
	</div>
{/if}

<style>
	/* Custom scrollbar */
	div::-webkit-scrollbar {
		width: 4px;
	}
	div::-webkit-scrollbar-track {
		background: transparent;
	}
	div::-webkit-scrollbar-thumb {
		background: #f3f4f6;
		border-radius: 10px;
	}
</style>
