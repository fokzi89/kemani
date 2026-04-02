<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import type { MarketplaceProduct } from '$lib/types/ecommerce';
	import { 
		ShoppingCart, Heart, Share2, Plus, Minus, ArrowLeft, 
		ShieldCheck, Clock, Truck, Star, CheckCircle2, ChevronRight 
	} from 'lucide-svelte';

	// The tenant is identified by the host (Approach 2)
	export let data: { tenant: any };
	$: tenantSlug = data.tenant.slug;
	let productId = $page.params.productId;

	let product: MarketplaceProduct | null = null;
	let relatedProducts: MarketplaceProduct[] = [];
	let quantity = 1;
	let isLoading = true;
	let error = '';

	const dummyProducts: MarketplaceProduct[] = [
		{ id: 'p1', name: 'Premium Multi-Vitamin Complex', description: 'Advanced formula with 24 essential vitamins and minerals for daily wellness. Supports immune system, energy metabolism, and overall vitality.', price: 12500, image_url: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=800&auto=format&fit=crop', category: 'Supplements', stock_quantity: 45, is_available: true, rating: 4.8, sku: 'KMN-VIT-001' },
		{ id: 'p2', name: 'Digital Blood Pressure Monitor', description: 'High-precision upper arm monitor with large backlit display and memory storage. Clinically validated for accuracy and ease of use.', price: 35000, image_url: 'https://images.unsplash.com/photo-1631815589968-fdb09a223b1e?q=80&w=800&auto=format&fit=crop', category: 'Equipment', stock_quantity: 12, is_available: true, rating: 4.9, sku: 'KMN-BPM-092' },
		{ id: 'p3', name: 'N95 Respirator Mask (Pack of 10)', description: 'Certified high-filtration masks for maximum respiratory protection. Adjustable nose clip and elastic ear loops for a secure fit.', price: 8500, image_url: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=800&auto=format&fit=crop', category: 'Protection', stock_quantity: 150, is_available: true, rating: 4.7, sku: 'KMN-MSK-005' },
		{ id: 'p4', name: 'Organic Herbal Tea Assortment', description: 'Curated selection of calming and revitalizing herbal blends. 100% organic ingredients with no artificial flavors.', price: 4200, image_url: 'https://images.unsplash.com/photo-1594631252845-29fc45865157?q=80&w=800&auto=format&fit=crop', category: 'Wellness', stock_quantity: 0, is_available: false, rating: 4.5, sku: 'KMN-TEA-021' },
	];

	onMount(async () => {
		await loadProduct();
		await loadRelatedProducts();
	});

	async function loadProduct() {
		isLoading = true;
		error = '';

		try {
			await new Promise(resolve => setTimeout(resolve, 600)); // Smooth transition

			const response = await fetch(`/api/marketplace/products/${productId}`);
			const data = await response.json();

			if (response.ok && data.product) {
				product = data.product;
			} else {
				// Fallback to dummy data
				product = dummyProducts.find(p => p.id === productId) || dummyProducts[0];
			}
		} catch (err: any) {
			product = dummyProducts.find(p => p.id === productId) || dummyProducts[0];
		} finally {
			isLoading = false;
		}
	}

	async function loadRelatedProducts() {
		try {
			relatedProducts = dummyProducts.filter(p => p.id !== productId).slice(0, 4);
		} catch (err: any) {
			console.error('Failed to load related products:', err);
		}
	}

	function addToCart() {
		if (!product) return;

		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
		const existingItem = cart.items.find((item: any) => item.product_id === product!.id);

		if (existingItem) {
			existingItem.quantity += quantity;
		} else {
			cart.items.push({
				product_id: product.id,
				product_name: product.name,
				product_image: product.image_url,
				price: product.price,
				quantity,
				stock_available: product.stock_quantity
			});
		}

		localStorage.setItem('cart', JSON.stringify(cart));
		goto(`/cart`);
	}
</script>

<svelte:head>
	<title>{product?.name || 'Product'} - Kemani Shop</title>
</svelte:head>

<div class="min-h-screen bg-[#F8FAFC]">
	<!-- Secondary Navbar -->
	<nav class="bg-white border-b border-gray-100 sticky top-0 z-[60] shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex items-center justify-between h-20">
				<button 
					on:click={() => goto(`/`)}
					class="flex items-center gap-2 text-sm font-black text-gray-500 hover:text-indigo-600 transition-colors uppercase tracking-widest"
				>
					<ArrowLeft class="h-4 w-4" /> Marketplace
				</button>
				
				<div class="flex items-center gap-4">
					<button class="h-10 w-10 bg-gray-50 text-gray-400 rounded-xl flex items-center justify-center hover:bg-rose-50 hover:text-rose-500 transition-all"><Heart class="h-5 w-5" /></button>
					<button class="h-10 w-10 bg-gray-50 text-gray-400 rounded-xl flex items-center justify-center hover:bg-indigo-50 hover:text-indigo-600 transition-all"><Share2 class="h-5 w-5" /></button>
				</div>
			</div>
		</div>
	</nav>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
		{#if isLoading}
			<div class="flex flex-col items-center justify-center py-32 space-y-4">
				<div class="animate-spin h-12 w-12 border-4 border-indigo-100 border-t-indigo-600 rounded-full"></div>
				<p class="text-sm font-black text-gray-400 uppercase tracking-widest">Detailing Product...</p>
			</div>
		{:else if product}
			<div class="grid lg:grid-cols-2 gap-16 items-start">
				
				<!-- Product Media -->
				<div class="space-y-6">
					<div class="aspect-square bg-white rounded-[40px] overflow-hidden border border-gray-100 shadow-2xl shadow-gray-200/50 p-8 group">
						<img 
							src={product.image_url} 
							alt={product.name} 
							class="w-full h-full object-contain group-hover:scale-110 transition-transform duration-700" 
						/>
					</div>
					
					<div class="grid grid-cols-4 gap-4">
						{#each Array(4) as _}
							<div class="aspect-square bg-white rounded-2xl border border-gray-100 p-2 cursor-pointer hover:border-indigo-600 transition-all group">
								<img src={product?.image_url} alt="Thumbnail" class="w-full h-full object-contain opacity-40 group-hover:opacity-100 transition-opacity" />
							</div>
						{/each}
					</div>
				</div>

				<!-- Product Selection Info -->
				<div class="space-y-10">
					<div class="space-y-4">
						<div class="flex items-center gap-4">
							<span class="px-4 py-1.5 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase tracking-widest">{product.category}</span>
							<div class="flex items-center gap-1">
								<Star class="h-4 w-4 text-amber-400 fill-amber-400" />
								<span class="text-sm font-black text-gray-900">{(product.rating || 4.5).toFixed(1)}</span>
								<span class="text-xs text-gray-400 font-bold ml-1 tracking-tight">/ 5.0 (120+ Reviews)</span>
							</div>
						</div>
						
						<h1 class="text-4xl md:text-5xl font-black text-gray-900 leading-tight tracking-tight uppercase">{product.name}</h1>
						<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">SKU: <span class="text-gray-900 font-black">{product.sku || 'KMN-992-UX'}</span></p>
					</div>

					<div class="flex items-baseline gap-4">
						<span class="text-5xl font-black text-indigo-600 tracking-tighter">₦{product.price.toLocaleString()}</span>
						<span class="text-lg font-bold text-gray-300 line-through">₦{(product.price * 1.2).toLocaleString()}</span>
					</div>

					<div class="space-y-4">
						<h3 class="text-xs font-black text-gray-400 uppercase tracking-widest">About this item</h3>
						<p class="text-lg text-gray-600 font-medium leading-relaxed">{product.description}</p>
					</div>

					<div class="grid grid-cols-2 gap-4">
						<div class="bg-white p-4 rounded-3xl border border-gray-50 flex items-center gap-4 group hover:bg-indigo-50 transition-colors">
							<div class="h-10 w-10 bg-indigo-50 rounded-xl flex items-center justify-center group-hover:bg-indigo-600 group-hover:text-white transition-all"><Truck class="h-5 w-5" /></div>
							<div>
								<p class="text-[10px] font-black uppercase tracking-widest leading-none">Shipping</p>
								<p class="text-xs font-bold text-gray-400 mt-1 uppercase">Same-day delivery</p>
							</div>
						</div>
						<div class="bg-white p-4 rounded-3xl border border-gray-50 flex items-center gap-4 group hover:bg-emerald-50 transition-colors">
							<div class="h-10 w-10 bg-emerald-50 rounded-xl flex items-center justify-center group-hover:bg-emerald-600 group-hover:text-white transition-all"><ShieldCheck class="h-5 w-5" /></div>
							<div>
								<p class="text-[10px] font-black uppercase tracking-widest leading-none">Quality</p>
								<p class="text-xs font-bold text-gray-400 mt-1 uppercase">ISO Certified</p>
							</div>
						</div>
					</div>

					<!-- Selection Controls -->
					<div class="space-y-6 pt-10 border-t border-gray-100">
						{#if product.is_available && product.stock_quantity > 0}
							<div class="flex flex-col md:flex-row gap-6 items-center">
								<div class="flex items-center gap-2 p-2 bg-white rounded-2xl border border-gray-100 shadow-sm w-full md:w-auto">
									<button 
										on:click={() => quantity = Math.max(1, quantity - 1)}
										class="h-12 w-12 bg-gray-50 rounded-xl flex items-center justify-center hover:bg-indigo-600 hover:text-white transition-all"
									><Minus class="h-5 w-5" /></button>
									<span class="w-16 text-center text-xl font-black text-gray-900">{quantity}</span>
									<button 
										on:click={() => quantity = Math.min(product!.stock_quantity, quantity + 1)}
										class="h-12 w-12 bg-gray-50 rounded-xl flex items-center justify-center hover:bg-indigo-600 hover:text-white transition-all"
									><Plus class="h-5 w-5" /></button>
								</div>

								<div class="flex-1 w-full flex gap-4">
									<button 
										on:click={addToCart}
										class="flex-1 py-5 bg-gray-900 text-white text-xs font-black rounded-2xl hover:bg-indigo-600 transition-all uppercase tracking-[0.2em] shadow-xl shadow-gray-200"
									>Add to Bag</button>
									<button 
										on:click={addToCart}
										class="flex-1 py-5 bg-indigo-600 text-white text-xs font-black rounded-2xl hover:bg-gray-900 transition-all uppercase tracking-[0.2em] shadow-xl shadow-indigo-100"
									>Buy Now</button>
								</div>
							</div>
							<div class="flex items-center gap-2 text-emerald-600">
								<CheckCircle2 class="h-4 w-4" />
								<span class="text-[10px] font-black uppercase tracking-widest">In Stock Ready to dispatch ({product.stock_quantity} Left)</span>
							</div>
						{:else}
							<div class="p-8 bg-rose-50 border border-rose-100 rounded-[32px] text-center">
								<p class="text-rose-600 font-black uppercase tracking-widest text-sm">Product Out of Stock</p>
								<p class="text-rose-400 text-xs mt-1 font-medium italic">We're restocking this item currently. Check back soon!</p>
							</div>
							<button class="w-full py-5 bg-gray-100 text-gray-400 text-xs font-black rounded-2xl cursor-not-allowed uppercase tracking-widest">Notify Me</button>
						{/if}
					</div>
				</div>
			</div>

			<!-- Related Products Horizontal -->
			<div class="mt-32 space-y-12">
				<div class="flex justify-between items-end">
					<div class="space-y-1">
						<p class="text-[10px] font-black text-indigo-400 uppercase tracking-widest">Recommended for you</p>
						<h2 class="text-3xl font-black text-gray-900 uppercase tracking-tight">Complete your health kit</h2>
					</div>
					<button class="flex items-center gap-2 text-sm font-black text-indigo-600 hover:gap-4 transition-all uppercase tracking-widest">View More <ChevronRight class="h-4 w-4" /></button>
				</div>

				<div class="grid grid-cols-2 md:grid-cols-4 gap-8">
					{#each relatedProducts as rel}
						<button 
							on:click={() => { productId = rel.id; loadProduct(); window.scrollTo({top: 0, behavior: 'smooth'}); }}
							class="group bg-white rounded-3xl p-4 border border-gray-100 text-left transition-all hover:shadow-2xl hover:shadow-indigo-500/5 hover:-translate-y-1"
						>
							<div class="aspect-square bg-gray-50 rounded-2xl overflow-hidden mb-4">
								<img src={rel.image_url} alt={rel.name} class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
							</div>
							<h3 class="text-sm font-black text-gray-900 leading-tight uppercase group-hover:text-indigo-600 transition-colors">{rel.name}</h3>
							<p class="text-lg font-black text-indigo-600 mt-2">₦{rel.price.toLocaleString()}</p>
						</button>
					{/each}
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
