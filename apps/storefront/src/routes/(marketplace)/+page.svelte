<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import type { MarketplaceProduct } from '$lib/types/ecommerce';
	import {
		Search, ShoppingCart, ChevronRight, Star,
		Clock, ShieldCheck, Tag, LayoutGrid, List, ArrowRight, UserCircle, Plus, ArrowLeft, Globe
	} from 'lucide-svelte';

	// Tenant data is loaded in (marketplace)/+layout.server.ts
	// we inherit branding from storefront
	$: storefront = data.storefront;
	$: brandColor      = storefront?.brand_color || '#4f46e5';
	$: brandColorLight = brandColor + '18';
	// Use the real origin so the URL shown is always correct (dev, staging, prod)
	// In subdomain mode, the origin is the store URL
	$: storeUrl = $page.url.origin;

	export let data;

	let products: MarketplaceProduct[] = [];
	let categories: Array<{ name: string; count: number }> = [];
	let isLoading = true;

	// Filter state
	let selectedCategory = '';
	let selectedBranch   = '';
	let searchQuery      = '';
	let minPrice         = '';
	let maxPrice         = '';
	let sortBy           = 'newest';
	let inStockOnly      = true;
	let currentPage      = 1;
	let totalPages       = 1;
	let viewMode         = 'grid';
	let cartItemCount    = 0;

	onMount(async () => {
		await Promise.all([loadCategories(), loadProducts()]);
		updateCartCount();
	});

	async function loadCategories() {
		try {
			const res  = await fetch('/api/marketplace/categories');
			const json = await res.json();
			if (json.categories) categories = json.categories;
		} catch (e) {
			console.error('Categories fetch failed', e);
		}
	}

	async function loadProducts() {
		isLoading = true;
		try {
			const p = new URLSearchParams();
			if (selectedCategory) p.set('category',     selectedCategory);
			if (selectedBranch)   p.set('branch_id',    selectedBranch);
			if (searchQuery)      p.set('search',        searchQuery);
			if (minPrice)         p.set('min_price',     minPrice);
			if (maxPrice)         p.set('max_price',     maxPrice);
			if (inStockOnly)      p.set('in_stock_only', 'true');
			p.set('sort_by', sortBy);
			p.set('page',    currentPage.toString());
			p.set('limit',   '24');

			const res  = await fetch(`/api/marketplace/products?${p}`);
			const json = await res.json();

			if (res.ok && json.products?.length > 0) {
				products   = json.products;
				totalPages = json.pagination?.pages || 1;
			} else {
				products   = [];
				totalPages = 1;
			}
		} catch {
			products = [];
		} finally {
			isLoading = false;
		}
	}

	function updateCartCount() {
		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
		cartItemCount = cart.items.reduce((s: number, i: any) => s + i.quantity, 0);
	}

	function addToCart(product: MarketplaceProduct) {
		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
		const found = cart.items.find((i: any) => i.product_id === product.id);
		if (found) {
			found.quantity += 1;
		} else {
			cart.items.push({
				product_id:     product.id,
				product_name:   product.name,
				product_image:  product.image_url,
				price:          product.price,
				quantity:       1,
				stock_available: product.stock_quantity
			});
		}
		localStorage.setItem('cart', JSON.stringify(cart));
		updateCartCount();
	}

	function handleSearch()                { currentPage = 1; loadProducts(); }
	function handleCategoryClick(c: string){ selectedCategory = c; currentPage = 1; loadProducts(); }
	function handleBranchClick(id: string) { selectedBranch = id; currentPage = 1; loadProducts(); }
	function handlePageChange(p: number)   { currentPage = p; loadProducts(); window.scrollTo({ top: 0, behavior: 'smooth' }); }
</script>

<svelte:head>
	<title>{storefront?.name || 'Store'} — Shop Online</title>
	<meta name="description" content="Shop {storefront?.name || 'our store'} online." />
</svelte:head>

<div class="bg-[#F8FAFC]">
	{#if storefront}
		<!-- Hero banner -->
		<section class="relative h-[280px] md:h-[360px] flex items-center overflow-hidden bg-gray-900">
			<img
				src={storefront.banner_url || 'https://images.unsplash.com/photo-1576091160550-217359f51f8c?q=80&w=2000&auto=format&fit=crop'}
				alt="Banner"
				class="absolute inset-0 w-full h-full object-cover opacity-50"
				style="animation: subtleZoom 14s ease-in-out infinite alternate;"
			/>
			<div class="absolute inset-0 bg-gradient-to-r from-gray-950 via-gray-900/70 to-transparent"></div>
			<div class="absolute inset-0 opacity-25" style="background: linear-gradient(135deg, {brandColor} 0%, transparent 60%);"></div>

			<div class="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full">
				<div class="max-w-xl space-y-4">
					<div class="flex items-center gap-2 flex-wrap">
						{#if storefront.logo_url}
							<img src={storefront.logo_url} alt="logo" class="h-7 w-7 rounded-lg object-cover" />
						{/if}
						<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest text-white/80 border border-white/20 bg-white/10 backdrop-blur-sm">
							<Tag class="h-3 w-3" /> {storefront.name}
						</span>
						{#each (storefront.services_offered || []) as svc}
							<span class="px-2.5 py-1 rounded-full text-[9px] font-black uppercase tracking-widest border border-white/10 text-white/60 capitalize">{svc}</span>
						{/each}
					</div>
					<h1 class="text-4xl md:text-5xl font-black text-white leading-[1.1] tracking-tight">
						Shop <span style="color:{brandColor};">{storefront.name}</span><br/>Online
					</h1>
					<p class="text-sm text-gray-300 font-medium max-w-md">
						{(storefront.ecommerce_settings as any)?.description || 'Browse our full catalog — available for delivery or pickup.'}
					</p>
				</div>
			</div>
		</section>

		<!-- Content Area -->
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
			<div class="grid lg:grid-cols-4 gap-8">

				<!-- Sidebar -->
				<aside class="hidden lg:block space-y-6">
					<!-- Store URL card -->
					<div class="p-4 rounded-2xl border border-dashed border-gray-200 bg-white text-center space-y-1.5">
						<p class="text-[9px] font-black uppercase tracking-widest text-gray-400">Share your store</p>
						<p class="text-xs font-black break-all" style="color:{brandColor};">{storeUrl}</p>
					</div>

					<!-- Categories -->
					<div>
						<h3 class="text-xs font-black text-gray-400 uppercase tracking-widest mb-3">Categories</h3>
						<div class="space-y-1">
							<button
								on:click={() => handleCategoryClick('')}
								class="w-full flex items-center justify-between p-3 rounded-xl transition-all font-bold text-sm"
								style={selectedCategory === '' ? `background:${brandColor};color:white;` : 'background:white;color:#6b7280;'}
							>
								<span>All Categories</span>
								<ChevronRight class="h-4 w-4 opacity-40" />
							</button>
							{#each categories as cat}
								<button
									on:click={() => handleCategoryClick(cat.name)}
									class="w-full flex items-center justify-between p-3 rounded-xl transition-all font-bold text-sm"
									style={selectedCategory === cat.name ? `background:${brandColor};color:white;` : 'background:white;color:#6b7280;'}
								>
									<span>{cat.name}</span>
									{#if cat.count > 0}<span class="text-[10px] px-2 py-0.5 bg-gray-100 rounded-full text-gray-400">{cat.count}</span>{/if}
								</button>
							{/each}
						</div>
					</div>

					<!-- Price & stock filters -->
					<div class="p-5 bg-white rounded-2xl border border-gray-100 shadow-sm space-y-5">
						<div>
							<h3 class="text-xs font-black text-gray-400 uppercase tracking-widest mb-3">Price Range</h3>
							<div class="flex gap-2">
								<div class="relative flex-1">
									<span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs">₦</span>
									<input type="number" bind:value={minPrice} placeholder="Min" class="w-full pl-7 pr-2 py-2 bg-gray-50 border border-gray-100 rounded-lg text-sm font-bold outline-none" />
								</div>
								<div class="relative flex-1">
									<span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs">₦</span>
									<input type="number" bind:value={maxPrice} placeholder="Max" class="w-full pl-7 pr-2 py-2 bg-gray-50 border border-gray-100 rounded-lg text-sm font-bold outline-none" />
								</div>
							</div>
							<button on:click={() => loadProducts()} class="w-full mt-3 py-2 text-white text-xs font-black rounded-lg uppercase tracking-widest brand-bg">Apply</button>
						</div>
						<label class="flex items-center gap-3 cursor-pointer">
							<input type="checkbox" bind:checked={inStockOnly} on:change={() => loadProducts()} class="w-5 h-5 rounded-lg border-gray-200" />
							<span class="text-sm font-bold text-gray-600">In-stock only</span>
						</label>
					</div>
				</aside>

				<!-- Main -->
				<main class="lg:col-span-3 space-y-6">
					<!-- Search + Sort -->
					<div class="flex flex-col md:flex-row gap-3">
						<div class="relative flex-1 group">
							<Search class="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
							<input
								type="search"
								bind:value={searchQuery}
								on:keydown={(e) => e.key === 'Enter' && handleSearch()}
								placeholder="Search products..."
								class="w-full pl-12 pr-4 py-4 bg-white border border-gray-100 rounded-2xl shadow-sm outline-none font-medium text-gray-900 transition-all"
							/>
						</div>
						<div class="flex gap-2">
							<select bind:value={sortBy} on:change={() => loadProducts()} class="h-14 px-4 bg-white border border-gray-100 rounded-2xl shadow-sm text-sm font-bold text-gray-700 outline-none cursor-pointer">
								<option value="newest">Featured</option>
								<option value="price_asc">Price ↑</option>
								<option value="price_desc">Price ↓</option>
								<option value="name">A–Z</option>
							</select>
							<div class="flex p-1 bg-white border border-gray-100 rounded-2xl shadow-sm">
								<button on:click={() => viewMode = 'grid'} class="p-3 rounded-xl transition-all" style={viewMode==='grid'?`background:${brandColorLight};color:${brandColor};`:'color:#9ca3af;'}><LayoutGrid class="h-5 w-5" /></button>
								<button on:click={() => viewMode = 'list'} class="p-3 rounded-xl transition-all" style={viewMode==='list'?`background:${brandColorLight};color:${brandColor};`:'color:#9ca3af;'}><List class="h-5 w-5" /></button>
							</div>
						</div>
					</div>

					<!-- Branch choice chips -->
					{#if storefront.branches?.length > 0}
						<div class="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
							<button
								on:click={() => handleBranchClick('')}
								class="flex-shrink-0 px-5 py-2 rounded-full text-sm font-bold border transition-all"
								style={selectedBranch===''?'background:#111827;color:white;border-color:#111827;':'background:white;color:#6b7280;border-color:#e5e7eb;'}
							>All Branches</button>
							{#each storefront.branches as branch}
								<button
									on:click={() => handleBranchClick(branch.id)}
									class="flex-shrink-0 px-5 py-2 rounded-full text-sm font-bold border transition-all"
									style={selectedBranch===branch.id?`background:${brandColor};color:white;border-color:${brandColor};`:'background:white;color:#6b7280;border-color:#e5e7eb;'}
								>{branch.name}</button>
							{/each}
						</div>
					{/if}

					<!-- Products -->
					{#if isLoading}
						<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
							{#each Array(6) as _}
								<div class="bg-white rounded-3xl p-4 border border-gray-100 animate-pulse space-y-4">
									<div class="aspect-square bg-gray-100 rounded-2xl"></div>
									<div class="h-4 bg-gray-100 rounded w-2/3"></div>
									<div class="h-4 bg-gray-100 rounded w-1/3"></div>
									<div class="h-10 bg-gray-100 rounded-xl"></div>
								</div>
							{/each}
						</div>
					{:else if products.length === 0}
						<div class="bg-white rounded-3xl p-16 text-center border border-dashed border-gray-200">
							<div class="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-5"><ShoppingCart class="h-8 w-8 text-gray-300" /></div>
							<h3 class="text-lg font-black text-gray-900">No products found</h3>
							<p class="text-gray-500 mt-1 text-sm">Try adjusting your filters or clear your search.</p>
							<button
								on:click={() => { searchQuery=''; selectedCategory=''; selectedBranch=''; loadProducts(); }}
								class="mt-6 px-8 py-3 text-white font-black rounded-2xl shadow-lg hover:scale-105 transition-all brand-bg"
							>Browse All</button>
						</div>
					{:else}
						<div class={viewMode==='grid'?'grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-6':'flex flex-col gap-5'}>
							{#each products as product}
								<div class="group bg-white rounded-3xl border border-gray-100 p-4 transition-all duration-300 hover:shadow-xl flex {viewMode==='list'?'flex-row gap-5':'flex-col'}">
									<!-- Image -->
									<div class="relative {viewMode==='list'?'w-36 h-36 flex-shrink-0':'aspect-square mb-4'} bg-gray-50 rounded-2xl overflow-hidden">
										{#if product.image_url}
											<img src={product.image_url} alt={product.name} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
										{:else}
											<div class="w-full h-full flex items-center justify-center"><ShoppingCart class="h-10 w-10 text-gray-200" /></div>
										{/if}
										{#if product.percentage_discount && product.percentage_discount > 0}
											<span class="absolute top-2 left-2 px-2 py-0.5 bg-emerald-500 text-white rounded-full text-[9px] font-black uppercase tracking-widest shadow-sm flex items-center gap-1">
												<Tag class="h-2.5 w-2.5" />
												{product.percentage_discount}% Off
											</span>
										{:else if product.category}
											<span class="absolute top-2 left-2 px-2 py-0.5 bg-white/90 backdrop-blur-sm rounded-full text-[9px] font-black uppercase tracking-widest shadow-sm" style="color:{brandColor};">{product.category}</span>
										{/if}

										{#if product.stock_quantity > 0 && product.stock_quantity < 10}
											<span class="absolute top-2 right-2 px-2 py-0.5 bg-rose-500 text-white text-[8px] font-black rounded-lg uppercase">Only {product.stock_quantity} left</span>
										{/if}
										{#if !product.is_available || product.stock_quantity === 0}
											<div class="absolute inset-0 bg-white/60 backdrop-blur-[2px] flex items-center justify-center">
												<span class="px-3 py-1.5 bg-gray-900 text-white text-[10px] font-black rounded-xl uppercase">Out of Stock</span>
											</div>
										{/if}
									</div>

									<!-- Info -->
									<div class="flex-1 flex flex-col">
										<div class="flex-1 mb-3">
											<div class="flex items-center gap-0.5 mb-1">
												{#each Array(5) as _, i}
													<Star class="h-3 w-3 {i < Math.floor((product as any).rating ?? 4.5) ? 'text-amber-400 fill-amber-400' : 'text-gray-200'}" />
												{/each}
												<span class="text-[10px] font-bold text-gray-400 ml-1">{((product as any).rating ?? 4.5).toFixed(1)}</span>
											</div>
											<h3 class="text-base font-black text-gray-900 tracking-tight leading-snug">{product.name}</h3>
											{#if product.description}
												<p class="text-xs text-gray-500 line-clamp-2 mt-1">{product.description}</p>
											{/if}
										</div>
										<div class="flex items-center justify-between">
											<div class="flex flex-col">
												{#if product.sale_price && product.sale_price > 0}
													<span class="text-[10px] font-black text-gray-400 line-through tracking-tighter decoration-rose-500/50">₦{product.selling_price?.toLocaleString()}</span>
													<span class="text-xl font-black tracking-tighter" style="color:{brandColor};">₦{product.sale_price.toLocaleString()}</span>
												{:else}
													<span class="text-xl font-black tracking-tighter" style="color:{brandColor};">₦{product.price.toLocaleString()}</span>
												{/if}
											</div>
											{#if product.is_available && product.stock_quantity > 0}
												<button on:click={() => addToCart(product)} class="h-11 w-11 brand-bg text-white rounded-2xl flex items-center justify-center shadow-lg hover:scale-105 active:scale-90 transition-all">
													<Plus class="h-5 w-5" />
												</button>
											{:else}
												<span class="h-11 px-3 bg-gray-100 text-gray-400 text-[10px] font-black rounded-2xl flex items-center uppercase tracking-widest">Restocking</span>
											{/if}
										</div>
									</div>
								</div>
							{/each}
						</div>

						<!-- Pagination -->
						{#if totalPages > 1}
							<div class="flex items-center justify-center gap-2 pt-4">
								<button on:click={() => handlePageChange(currentPage-1)} disabled={currentPage===1} class="p-3 rounded-xl bg-white border border-gray-100 disabled:opacity-30"><ArrowLeft class="h-5 w-5" /></button>
								{#each Array(totalPages) as _, i}
									<button on:click={() => handlePageChange(i+1)} class="h-11 w-11 rounded-xl text-sm font-bold transition-all" style={currentPage===i+1?`background:${brandColor};color:white;`:'background:white;color:#6b7280;'}>{i+1}</button>
								{/each}
								<button on:click={() => handlePageChange(currentPage+1)} disabled={currentPage===totalPages} class="p-3 rounded-xl bg-white border border-gray-100 disabled:opacity-30"><ChevronRight class="h-5 w-5" /></button>
							</div>
						{/if}
					{/if}

					<!-- Trust badges -->
					<div class="grid grid-cols-3 gap-4 pt-8 border-t border-gray-100">
						<div class="flex items-center gap-3">
							<div class="h-10 w-10 rounded-xl flex items-center justify-center" style="background:{brandColorLight};color:{brandColor};"><ShieldCheck class="h-5 w-5" /></div>
							<div><p class="text-xs font-black text-gray-900">Verified Quality</p><p class="text-[10px] text-gray-400">Certified products</p></div>
						</div>
						<div class="flex items-center gap-3">
							<div class="h-10 w-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center"><Clock class="h-5 w-5" /></div>
							<div><p class="text-xs font-black text-gray-900">Fast Delivery</p><p class="text-[10px] text-gray-400">Same-day available</p></div>
						</div>
						<div class="flex items-center gap-3">
							<div class="h-10 w-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center"><Tag class="h-5 w-5" /></div>
							<div><p class="text-xs font-black text-gray-900">Best Prices</p><p class="text-[10px] text-gray-400">Price match guarantee</p></div>
						</div>
					</div>
				</main>
			</div>
		</div>
	{:else}
		<div class="min-h-[60vh] flex items-center justify-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
		</div>
	{/if}
</div>

<style>
	.brand-bg   { background-color: var(--brand, #4f46e5); }
	.scrollbar-hide::-webkit-scrollbar { display: none; }
	.scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
	@keyframes subtleZoom { from { transform: scale(1.05); } to { transform: scale(1.12); } }
</style>
