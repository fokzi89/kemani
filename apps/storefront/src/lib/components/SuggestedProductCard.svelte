<script lang="ts">
	import { onMount } from 'svelte';
	import { ShoppingBag, ChevronRight, Plus, Package, Loader2 } from 'lucide-svelte';
	import { MarketplaceService } from '$lib/services/marketplace';
	import { supabase } from '$lib/supabase';
	import { fade, slide } from 'svelte/transition';

	let { productId, tenantId } = $props();

	let product = $state<any>(null);
	let loading = $state(true);
	let error = $state<string | null>(null);

	onMount(async () => {
		const service = new MarketplaceService(supabase);
		const { product: data, error: err } = await service.getMarketplaceProductById(productId, tenantId);
		if (err) {
			error = err;
		} else {
			product = data;
		}
		loading = false;
	});

	function addToBag() {
		if (!product) return;
		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
		const existing = cart.items.find((i: any) => i.product_id === product.id);
		
		if (existing) {
			existing.quantity += 1;
		} else {
			cart.items.push({
				product_id: product.id,
				product_name: product.name,
				product_image: product.image_url,
				price: product.price,
				quantity: 1,
				isPOM: product.isPOM
			});
		}
		
		localStorage.setItem('cart', JSON.stringify(cart));
		window.dispatchEvent(new Event('cart-updated'));
	}
</script>

{#if loading}
	<div class="bg-white/50 backdrop-blur-sm rounded-2xl p-4 border border-gray-100 flex items-center justify-center gap-3">
		<Loader2 class="h-4 w-4 animate-spin text-gray-400" />
		<span class="text-[10px] font-bold uppercase tracking-widest text-gray-400">Loading Recommendation...</span>
	</div>
{:else if error}
	<div class="bg-red-50 rounded-2xl p-4 border border-red-100 flex items-center gap-3">
		<Package class="h-4 w-4 text-red-400" />
		<span class="text-[10px] font-bold uppercase tracking-widest text-red-400">Suggestion unavailable</span>
	</div>
{:else if product}
	<div 
		class="suggested-card bg-white rounded-2xl overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-all animate-in fade-in slide-in-from-bottom-2 duration-300"
		in:slide
	>
		<div class="flex items-center p-3 gap-4">
			<div class="h-16 w-16 bg-gray-50 rounded-xl overflow-hidden flex-shrink-0">
				{#if product.image_url}
					<img src={product.image_url} alt={product.name} class="h-full w-full object-cover" />
				{:else}
					<div class="h-full w-full flex items-center justify-center text-gray-300">
						<Package class="h-8 w-8" />
					</div>
				{/if}
			</div>
			
			<div class="flex-1 min-w-0">
				<div class="flex items-center gap-2 mb-1">
					<span class="px-1.5 py-0.5 bg-primary-50 text-[8px] font-black uppercase tracking-tighter text-primary-700 rounded-sm">Recommended</span>
					{#if product.isPOM}
						<span class="px-1.5 py-0.5 bg-amber-50 text-[8px] font-black uppercase tracking-tighter text-amber-700 rounded-sm">Verification Required</span>
					{/if}
				</div>
				<h4 class="text-sm font-black text-gray-900 truncate uppercase tracking-tight leading-none">{product.name}</h4>
				<p class="text-[10px] text-gray-400 font-bold mt-1 uppercase tracking-widest truncate">{product.category}</p>
			</div>
		</div>

		<div class="bg-gray-50 p-3 flex items-center justify-between border-t border-gray-100">
			<div>
				<p class="text-[8px] font-bold text-gray-400 uppercase tracking-widest mb-0.5">Unit Price</p>
				<p class="text-sm font-black text-gray-900">₦{product.price?.toLocaleString()}</p>
			</div>
			<button 
				onclick={addToBag}
				class="bg-black text-white px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest flex items-center gap-2 hover:bg-gray-800 transition-all active:scale-95"
			>
				Add to Bag <Plus class="h-3 w-3" />
			</button>
		</div>
	</div>
{/if}

<style>
	.suggested-card {
		max-width: 320px;
		margin: 8px 0;
	}
</style>
