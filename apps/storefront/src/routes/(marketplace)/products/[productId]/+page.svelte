<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ShoppingCart, Heart, Share2, Plus, Minus, ArrowLeft, 
		ShieldCheck, Clock, Truck, Star, CheckCircle2, ChevronRight, Tag
	} from 'lucide-svelte';

	export let data;

	// Injected from layout context and our server loader
	$: storefront = data.storefront;
    $: brandColor = storefront?.brand_color || '#4f46e5';
	$: product = data.product;
	$: relatedProducts = data.relatedProducts || [];

	let quantity = 1;

	function addToCart() {
		if (!product) return;

		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
		const existingItem = cart.items.find((item: any) => item.product_id === product!.id);

		if (existingItem) {
			existingItem.quantity += quantity;
		} else {
			cart.items.push({
				product_id: product.id,
				inventory_id: product.inventory_id,
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
	<title>{product?.name} | {storefront?.name}</title>
	<meta name="description" content={product?.description} />
</svelte:head>

<div class="bg-[#F8FAFC]">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-16">
		
		<!-- Breadcrumbs -->
		<div class="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-gray-400 mb-10 overflow-x-auto whitespace-nowrap pb-2">
			<a href="/" class="hover:text-indigo-600 transition-colors">Catalog</a>
			<ChevronRight class="h-3 w-3" />
			<span class="opacity-60">{product?.category}</span>
			<ChevronRight class="h-3 w-3" />
			<span class="text-gray-900">{product?.name}</span>
		</div>

		{#if product}
			<div class="grid lg:grid-cols-2 gap-16 items-start">
				
				<!-- Product Media -->
				<div class="space-y-6 sticky top-28">
					<div class="aspect-square bg-white rounded-[40px] overflow-hidden border border-gray-100 shadow-2xl shadow-gray-200/50 p-12 group transition-all duration-500 hover:p-8">
						{#if product.image_url}
							<img 
								src={product.image_url} 
								alt={product.name} 
								class="w-full h-full object-contain group-hover:scale-110 transition-transform duration-700" 
							/>
						{:else}
							<div class="w-full h-full flex flex-col items-center justify-center bg-gray-50 text-gray-200">
								<ShoppingCart class="h-20 w-20 mb-4" />
								<span class="text-xs font-black uppercase tracking-widest">Image Coming Soon</span>
							</div>
						{/if}
						
						<!-- Overlay Badges -->
						{#if product.percentage_discount}
							<div class="absolute top-8 left-8 bg-emerald-500 text-white px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-[0.2em] shadow-lg flex items-center gap-2">
								<Tag class="w-3.5 h-3.5" />
								{product.percentage_discount}% Off
							</div>
						{/if}
					</div>
					
					<div class="grid grid-cols-4 gap-4">
						{#each Array(4) as _}
							<div class="aspect-square bg-white rounded-2xl border border-gray-100 p-2 cursor-pointer hover:border-indigo-600 transition-all group overflow-hidden">
								{#if product.image_url}
									<img src={product.image_url} alt="Thumbnail" class="w-full h-full object-contain opacity-40 group-hover:opacity-100 group-hover:scale-110 transition-all" />
								{:else}
									<div class="w-full h-full bg-gray-50 flex items-center justify-center"><ShoppingCart class="w-4 h-4 text-gray-200" /></div>
								{/if}
							</div>
						{/each}
					</div>
				</div>

				<!-- Product Options -->
				<div class="space-y-10">
					<div class="space-y-4">
						<div class="flex items-center gap-4 flex-wrap">
							<span class="px-4 py-1.5 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-black uppercase tracking-widest">{product.category}</span>
							<div class="flex items-center gap-1">
								<Star class="h-4 w-4 text-amber-400 fill-amber-400" />
								<span class="text-sm font-black text-gray-900">4.8</span>
								<span class="text-xs text-gray-400 font-bold ml-1 tracking-tight">/ 5.0 (250+ Sold)</span>
							</div>
						</div>
						
						<h1 class="text-xl md:text-2xl font-black text-gray-900 leading-[1.1] tracking-tight uppercase">{product.name}</h1>
						<div class="flex items-center gap-5 pt-1">
							<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest leading-none">SKU: <span class="text-gray-900">{product.sku || 'KMN-992-UX'}</span></p>
							<div class="h-3 w-px bg-gray-200"></div>
							<div class="flex items-center gap-1.5 text-emerald-600 text-[10px] font-black uppercase tracking-widest leading-none">
								<div class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
								In Stock & Ready
							</div>
						</div>
					</div>

					<div class="flex items-baseline gap-5">
						<span class="text-2xl md:text-3xl font-black tracking-tighter" style="color:var(--brand);">₦{product.price.toLocaleString()}</span>
						{#if product.sale_price}
							<span class="text-lg font-bold text-gray-300 line-through">₦{product.selling_price?.toLocaleString()}</span>
						{/if}
					</div>

					<div class="space-y-4">
						<h3 class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Master Product Details</h3>
						{#if product.description}
							<p class="text-sm text-gray-600 font-medium leading-relaxed max-w-xl">{product.description}</p>
						{/if}
						
						{#if product.product_details}
							<div class="p-4 bg-indigo-50/50 rounded-2xl border border-indigo-100 mt-2">
								<p class="text-xs text-gray-700 leading-relaxed">{product.product_details}</p>
							</div>
						{/if}

						{#if product.category?.toLowerCase() === 'drug'}
							<div class="grid grid-cols-1 md:grid-cols-2 gap-y-3 gap-x-6 mt-4">
								{#if product.generic_name}
									<div class="flex flex-col">
										<span class="text-[10px] text-gray-400 font-black uppercase tracking-widest">Generic Name</span>
										<span class="text-sm font-semibold text-gray-800">{product.generic_name}</span>
									</div>
								{/if}
								{#if product.strength}
									<div class="flex flex-col">
										<span class="text-[10px] text-gray-400 font-black uppercase tracking-widest">Strength</span>
										<span class="text-sm font-semibold text-gray-800">{product.strength}</span>
									</div>
								{/if}
								{#if product.dosage_form}
									<div class="flex flex-col">
										<span class="text-[10px] text-gray-400 font-black uppercase tracking-widest">Dosage Form</span>
										<span class="text-sm font-semibold text-gray-800">{product.dosage_form}</span>
									</div>
								{/if}
							</div>
							
							{#if product.product_side_effect || product.interactions}
								<div class="mt-4 space-y-4">
									{#if product.product_side_effect}
										<div>
											<h4 class="text-[10px] text-red-400 font-black uppercase tracking-widest mb-1">Side Effects</h4>
											<p class="text-sm text-gray-600 font-medium bg-red-50/50 p-3 rounded-xl border border-red-100">{product.product_side_effect}</p>
										</div>
									{/if}
									{#if product.interactions}
										<div>
											<h4 class="text-[10px] text-amber-500 font-black uppercase tracking-widest mb-1">Interactions</h4>
											<p class="text-sm text-gray-600 font-medium bg-amber-50/50 p-3 rounded-xl border border-amber-100">{product.interactions}</p>
										</div>
									{/if}
								</div>
							{/if}
						{/if}
					</div>

					<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
						<div class="bg-white p-5 rounded-[32px] border border-gray-100 flex items-center gap-4 group hover:bg-indigo-50 transition-colors">
							<div class="h-12 w-12 bg-indigo-50/50 rounded-2xl flex items-center justify-center group-hover:bg-indigo-600 group-hover:text-white transition-all"><Truck class="h-6 w-6" /></div>
							<div>
								<p class="text-[11px] font-black uppercase tracking-widest">Logistics</p>
								<p class="text-xs font-bold text-gray-400 mt-0.5">Express Dispatch</p>
							</div>
						</div>
						<div class="bg-white p-5 rounded-[32px] border border-gray-100 flex items-center gap-4 group hover:bg-emerald-50 transition-colors">
							<div class="h-12 w-12 bg-emerald-50/50 rounded-2xl flex items-center justify-center group-hover:bg-emerald-600 group-hover:text-white transition-all"><ShieldCheck class="h-6 w-6" /></div>
							<div>
								<p class="text-[11px] font-black uppercase tracking-widest">Quality</p>
								<p class="text-xs font-bold text-gray-400 mt-0.5">ISO 13485 Certified</p>
							</div>
						</div>
					</div>

					<!-- Cart Action Controls -->
					<div class="space-y-6 pt-12 border-t border-gray-100">
						{#if product.is_available && product.stock_quantity > 0}
							<div class="flex flex-col md:flex-row gap-6 items-center">
								<div class="flex items-center gap-3 p-3 bg-white rounded-3xl border border-gray-100 shadow-sm w-full md:w-auto">
									<button 
										on:click={() => quantity = Math.max(1, quantity - 1)}
										class="h-12 w-12 bg-gray-50 rounded-2xl flex items-center justify-center hover:bg-gray-900 hover:text-white transition-all group"
									><Minus class="h-5 w-5 group-active:scale-75 transition-transform" /></button>
									<span class="w-16 text-center text-2xl font-black text-gray-900 tracking-tighter">{quantity}</span>
									<button 
										on:click={() => quantity = Math.min(product!.stock_quantity, quantity + 1)}
										class="h-12 w-12 bg-gray-50 rounded-2xl flex items-center justify-center hover:bg-gray-900 hover:text-white transition-all group"
									><Plus class="h-5 w-5 group-active:scale-75 transition-transform" /></button>
								</div>

								<div class="flex-1 w-full flex gap-4">
									<button 
										on:click={addToCart}
										class="flex-1 py-6 bg-gray-950 text-white text-[11px] font-black rounded-3xl hover:bg-gray-800 transition-all uppercase tracking-[0.2em] shadow-xl shadow-gray-200 active:scale-95"
									>Add to Cart</button>
									<button 
										on:click={addToCart}
										class="flex-1 py-6 text-white text-[11px] font-black rounded-3xl hover:opacity-90 transition-all uppercase tracking-[0.2em] shadow-xl shadow-indigo-100 active:scale-95"
										style="background: var(--brand);"
									>Order Direct</button>
								</div>
							</div>
							<div class="flex items-center gap-2.5">
								<div class="h-3 w-3 rounded-full bg-emerald-500 animate-pulse"></div>
								<span class="text-[11px] font-black uppercase tracking-widest text-emerald-600">Local Inventory ({product.stock_quantity} available)</span>
							</div>
						{:else}
							<div class="p-10 bg-rose-50 border border-rose-100 rounded-[40px] text-center space-y-2">
								<p class="text-rose-600 font-black uppercase tracking-widest text-sm">Item Out of Stock</p>
								<p class="text-rose-400 text-xs font-medium">Restocking from central warehouse. Available soon!</p>
							</div>
						{/if}
					</div>
				</div>
			</div>

			<!-- Related Products Horizontal -->
			<div class="mt-40 space-y-12">
				<div class="flex justify-between items-end border-b border-gray-100 pb-8">
					<div class="space-y-1">
						<p class="text-[11px] font-black uppercase tracking-widest opacity-40 shrink-0" style="color:var(--brand);">You might also need</p>
						<h2 class="text-xl md:text-2xl font-black text-gray-900 tracking-tight">Featured Essentials</h2>
					</div>
					<a href="/" class="flex items-center gap-2 text-sm font-black text-gray-900 hover:gap-4 transition-all uppercase tracking-widest h-12 px-6 bg-white border border-gray-100 rounded-2xl group">
						Explore More <ChevronRight class="h-4 w-4 group-hover:translate-x-1 transition-transform" />
					</a>
				</div>

				{#if relatedProducts.length > 0}
					<div class="grid grid-cols-2 md:grid-cols-4 gap-8">
						{#each relatedProducts as rel}
							<button 
								on:click={() => { goto(`/products/${rel.id}`); window.scrollTo({top: 0, behavior: 'smooth'}); }}
								class="group bg-white rounded-[32px] p-5 border border-gray-100 text-left transition-all hover:shadow-2xl hover:shadow-indigo-500/5 hover:-translate-y-2"
							>
								<div class="aspect-square bg-gray-50 rounded-2xl overflow-hidden mb-6 group-hover:p-1 transition-all">
									{#if rel.image_url}
										<img src={rel.image_url} alt={rel.name} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
									{:else}
										<div class="w-full h-full flex items-center justify-center text-gray-200"><ShoppingCart class="w-10 h-10" /></div>
									{/if}
								</div>
								<div class="space-y-1 pr-4">
									<h3 class="text-sm font-black text-gray-900 leading-tight uppercase group-hover:text-indigo-600 transition-colors line-clamp-1">{rel.name}</h3>
									<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">{rel.category}</p>
								</div>
								<div class="flex items-center justify-between mt-6">
									<p class="text-lg font-black tracking-tighter" style="color:var(--brand);">₦{rel.price.toLocaleString()}</p>
									<Plus class="w-4 h-4 text-gray-300 group-hover:text-gray-900 transition-colors" />
								</div>
							</button>
						{/each}
					</div>
				{:else}
					<div class="py-20 text-center bg-white rounded-[40px] border border-dashed border-gray-100">
						<p class="text-xs font-black uppercase tracking-widest text-gray-300">No other items in this category currently</p>
					</div>
				{/if}
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) { font-family: 'Outfit', 'Inter', sans-serif; }
</style>
