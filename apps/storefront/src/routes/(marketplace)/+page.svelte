<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import type { MarketplaceProduct } from '$lib/types/ecommerce';
	import {
		Search, ShoppingCart, ChevronRight, Star,
		Clock, ShieldCheck, Tag, ArrowRight, Plus, ArrowLeft
	} from 'lucide-svelte';

	$: storefront = data.storefront;
	$: brandColor      = storefront?.brand_color || '#4f46e5';
	$: brandColorLight = brandColor + '18';
	$: storeUrl = $page.url.origin;

	export let data;

	let products: MarketplaceProduct[] = [];
	let categories: Array<{ name: string; count: number }> = [];
	let isLoading = true;

	let selectedCategory = '';
	let selectedBranch   = '';
	let searchQuery      = '';
	let minPrice         = '';
	let maxPrice         = '';
	let sortBy           = 'newest';
	let inStockOnly      = true;
	let currentPage      = 1;
	let totalPages       = 1;
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
	<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
</svelte:head>

<div class="store-page">
	{#if storefront}

		<!-- ═══════════ HERO SECTION ═══════════ -->
		<section class="hero-section">
			<img
				src={storefront.banner_url || 'https://images.unsplash.com/photo-1576091160550-217359f51f8c?q=80&w=2000&auto=format&fit=crop'}
				alt="Banner"
				class="hero-bg"
			/>
			<div class="hero-overlay"></div>
			<div class="hero-gradient"></div>
			<div class="hero-content">
				<span class="hero-label">
					<Tag class="label-icon" /> {storefront.name}
				</span>
				<h2 class="hero-title">
					Discover Medics,<br/>Delivered to You
				</h2>
				<p class="hero-subtitle">
					{(storefront?.ecommerce_settings as any)?.description || 'Curated healthcare products — quality you can trust, prices you can afford.'}
				</p>
				<a href="#shop" class="hero-cta">
					Shop Now <ArrowRight class="cta-arrow" />
				</a>
			</div>
		</section>

		<!-- ═══════════ CONTENT AREA: SIDEBAR + MAIN ═══════════ -->
		<div class="content-area" id="shop">
			<!-- LEFT SIDEBAR -->
			<aside class="sidebar">
				<!-- Categories -->
				<div class="sidebar-block">
					<h3 class="sidebar-heading">Categories</h3>
					<div class="sidebar-list">
						<button
							on:click={() => handleCategoryClick('')}
							class="sidebar-item"
							class:sidebar-item-active={selectedCategory === ''}
						>
							<span>All Categories</span>
							<ChevronRight class="sidebar-chevron" />
						</button>
						{#each categories as cat}
							<button
								on:click={() => handleCategoryClick(cat.name)}
								class="sidebar-item"
								class:sidebar-item-active={selectedCategory === cat.name}
							>
								<span>{cat.name}</span>
								{#if cat.count > 0}<span class="sidebar-count">{cat.count}</span>{/if}
							</button>
						{/each}
					</div>
				</div>

				<!-- Price Filter -->
				<div class="sidebar-block">
					<h3 class="sidebar-heading">Price Range</h3>
					<div class="price-inputs">
						<div class="price-field">
							<span class="price-symbol">₦</span>
							<input type="number" bind:value={minPrice} placeholder="Min" class="price-input" />
						</div>
						<div class="price-field">
							<span class="price-symbol">₦</span>
							<input type="number" bind:value={maxPrice} placeholder="Max" class="price-input" />
						</div>
					</div>
					<button on:click={() => loadProducts()} class="apply-btn">Apply</button>
				</div>

				<!-- Stock Filter -->
				<div class="sidebar-block">
					<label class="stock-toggle">
						<input type="checkbox" bind:checked={inStockOnly} on:change={() => loadProducts()} class="stock-checkbox" />
						<span>In-stock only</span>
					</label>
				</div>
			</aside>

			<!-- MAIN CONTENT -->
			<main class="main-content">
				<!-- Search + Sort Row -->
				<div class="search-bar">
					<div class="search-input-wrap">
						<Search class="search-icon" />
						<input
							type="search"
							bind:value={searchQuery}
							on:keydown={(e) => e.key === 'Enter' && handleSearch()}
							placeholder="Search products..."
							class="search-input"
						/>
					</div>
					<select bind:value={sortBy} on:change={() => loadProducts()} class="sort-select">
						<option value="newest">Featured</option>
						<option value="price_asc">Price: Low → High</option>
						<option value="price_desc">Price: High → Low</option>
						<option value="name">A – Z</option>
					</select>
				</div>

				<!-- Branch Chips -->
				{#if storefront.branches?.length > 0}
					<div class="branch-chips">
						<button on:click={() => handleBranchClick('')} class="chip chip-sm" class:chip-active={selectedBranch === ''}>All Branches</button>
						{#each storefront.branches as branch}
							<button on:click={() => handleBranchClick(branch.id)} class="chip chip-sm" class:chip-active={selectedBranch === branch.id}>{branch.name}</button>
						{/each}
					</div>
				{/if}

				<!-- Products -->
				<section class="products-section">
			{#if isLoading}
				<div class="product-grid">
					{#each Array(8) as _}
						<div class="product-skeleton">
							<div class="skeleton-img"></div>
							<div class="skeleton-text w60"></div>
							<div class="skeleton-text w40"></div>
						</div>
					{/each}
				</div>
			{:else if products.length === 0}
				<div class="empty-state">
					<ShoppingCart class="empty-icon" />
					<h3 class="empty-title">No products found</h3>
					<p class="empty-sub">Try adjusting your filters or clear your search.</p>
					<button
						on:click={() => { searchQuery=''; selectedCategory=''; selectedBranch=''; loadProducts(); }}
						class="empty-cta"
					>Browse All</button>
				</div>
			{:else}
				<div class="product-grid">
					{#each products as product}
						<div class="product-card">
							<a href={`/products/${product.id}`} class="product-img-wrap">
								{#if product.image_url}
									<img src={product.image_url} alt={product.name} class="product-img" />
								{:else}
									<div class="product-img-placeholder"><ShoppingCart /></div>
								{/if}
								{#if product.percentage_discount && product.percentage_discount > 0}
									<span class="badge badge-discount">{product.percentage_discount}% Off</span>
								{/if}
								{#if product.stock_quantity > 0 && product.stock_quantity < 10}
									<span class="badge badge-low">Only {product.stock_quantity} left</span>
								{/if}
								{#if !product.is_available || product.stock_quantity === 0}
									<div class="product-sold-out">
										<span>Sold Out</span>
									</div>
								{/if}
							</a>
							<div class="product-info">
								<div class="product-rating">
									{#each Array(5) as _, i}
										<Star class="star {i < Math.floor((product as any).rating ?? 4.5) ? 'star-filled' : ''}" />
									{/each}
								</div>
								<a href={`/products/${product.id}`} class="product-name">{product.name}</a>
								{#if product.description}
									<p class="product-desc">{product.description}</p>
								{/if}
								<div class="product-price-row">
									<div class="product-price">
										{#if product.sale_price && product.sale_price > 0}
											<span class="price-old">₦{product.selling_price?.toLocaleString()}</span>
											<span class="price-current">₦{product.sale_price.toLocaleString()}</span>
										{:else}
											<span class="price-current">₦{product.price.toLocaleString()}</span>
										{/if}
									</div>
								</div>
							</div>
							{#if product.is_available && product.stock_quantity > 0}
								<button
									on:click|stopPropagation={() => addToCart(product)}
									class="add-to-bag"
								>
									Add to Bag
									<ArrowRight class="bag-arrow" />
								</button>
							{:else}
								<div class="unavailable-label">Currently Unavailable</div>
							{/if}
						</div>
					{/each}
				</div>

				<!-- Pagination -->
				{#if totalPages > 1}
					<div class="pagination">
						<button on:click={() => handlePageChange(currentPage-1)} disabled={currentPage===1} class="page-btn"><ArrowLeft class="page-arrow" /></button>
						{#each Array(totalPages) as _, i}
							<button on:click={() => handlePageChange(i+1)} class="page-btn" class:page-active={currentPage===i+1}>{i+1}</button>
						{/each}
						<button on:click={() => handlePageChange(currentPage+1)} disabled={currentPage===totalPages} class="page-btn"><ChevronRight class="page-arrow" /></button>
					</div>
				{/if}
			{/if}
			</section>
			</main>
		</div>

		<!-- ═══════════ TRUST BADGES ═══════════ -->
		<section class="trust-section">
			<div class="trust-badge">
				<div class="trust-icon" style="background:{brandColorLight};color:{brandColor};"><ShieldCheck /></div>
				<div><p class="trust-title">Verified Quality</p><p class="trust-sub">Certified products</p></div>
			</div>
			<div class="trust-badge">
				<div class="trust-icon trust-icon-green"><Clock /></div>
				<div><p class="trust-title">Fast Delivery</p><p class="trust-sub">Same-day available</p></div>
			</div>
			<div class="trust-badge">
				<div class="trust-icon trust-icon-amber"><Tag /></div>
				<div><p class="trust-title">Best Prices</p><p class="trust-sub">Price match guarantee</p></div>
			</div>
		</section>

		<!-- ═══════════ NEWSLETTER ═══════════ -->
		<section class="newsletter-section">
			<h4 class="newsletter-title">Stay in the Loop</h4>
			<p class="newsletter-sub">New arrivals, health tips, and exclusive deals — straight to your inbox.</p>
			<div class="newsletter-form">
				<input type="email" placeholder="Your email address" class="newsletter-input" />
				<button class="newsletter-btn">Subscribe</button>
			</div>
		</section>

	{:else}
		<div class="loading-state">
			<div class="loader"></div>
		</div>
	{/if}
</div>

<style>
	/* ─── TOKENS ─── */
	:root {
		--font-display: 'Playfair Display', Georgia, serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #faf9f6;
		--surface-dim: #f0eeea;
		--on-surface: #1a1c1a;
		--on-surface-muted: #6b7280;
		--border: #e5e5e0;
		--border-light: #f0eeea;
		--accent: var(--brand, #4f46e5);
	}

	.store-page {
		font-family: var(--font-body);
		background: var(--surface);
		color: var(--on-surface);
		min-height: 100vh;
	}

	/* ─── HERO ─── */
	.hero-section {
		position: relative;
		height: 420px;
		display: flex;
		flex-direction: column;
		justify-content: flex-end;
		padding: 2rem;
		overflow: hidden;
	}
	@media (min-width: 768px) { .hero-section { height: 520px; padding: 3rem; } }

	.hero-bg {
		position: absolute; inset: 0;
		width: 100%; height: 100%;
		object-fit: cover;
		animation: heroZoom 20s ease-in-out infinite alternate;
	}
	.hero-overlay { position: absolute; inset: 0; background: linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 60%); }
	.hero-gradient { position: absolute; inset: 0; background: linear-gradient(135deg, var(--accent) 0%, transparent 50%); opacity: 0.15; }

	.hero-content { position: relative; z-index: 2; max-width: 560px; }

	.hero-label {
		display: inline-flex; align-items: center; gap: 6px;
		font-size: 10px; font-weight: 600; letter-spacing: 0.15em; text-transform: uppercase;
		color: rgba(255,255,255,0.8);
		border: 1px solid rgba(255,255,255,0.2);
		background: rgba(255,255,255,0.08);
		backdrop-filter: blur(8px);
		padding: 6px 14px; border-radius: 99px;
		margin-bottom: 16px;
	}
	.hero-label :global(.label-icon) { width: 12px; height: 12px; }

	.hero-title {
		font-family: var(--font-display);
		font-size: 2.2rem; font-weight: 500;
		line-height: 1.15; color: #fff;
		margin-bottom: 12px;
	}
	@media (min-width: 768px) { .hero-title { font-size: 3rem; } }

	.hero-subtitle { font-size: 14px; color: rgba(255,255,255,0.75); line-height: 1.6; max-width: 420px; margin-bottom: 24px; }

	.hero-cta {
		display: inline-flex; align-items: center; gap: 8px;
		background: var(--accent); color: #fff;
		padding: 14px 32px; border-radius: 8px;
		font-size: 12px; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase;
		text-decoration: none;
		box-shadow: 0 4px 20px rgba(0,0,0,0.2);
		transition: transform 0.15s, box-shadow 0.15s;
	}
	.hero-cta:active { transform: scale(0.97); }
	.hero-cta :global(.cta-arrow) { width: 14px; height: 14px; }

	/* ─── CONTENT AREA (sidebar + main) ─── */
	.content-area {
		max-width: 1280px;
		margin: 0 auto;
		padding: 2rem;
		display: grid;
		grid-template-columns: 1fr;
		gap: 2rem;
	}
	@media (min-width: 1024px) {
		.content-area { grid-template-columns: 220px 1fr; }
	}

	/* ─── SIDEBAR ─── */
	.sidebar { display: none; }
	@media (min-width: 1024px) { .sidebar { display: block; } }

	.sidebar-block {
		padding: 20px;
		background: #fff;
		border: 1px solid var(--border);
		border-radius: 8px;
		margin-bottom: 12px;
	}
	.sidebar-heading {
		font-size: 11px; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase;
		color: var(--on-surface-muted);
		margin-bottom: 12px;
	}
	.sidebar-list { display: flex; flex-direction: column; gap: 2px; }

	.sidebar-item {
		display: flex; align-items: center; justify-content: space-between;
		width: 100%; padding: 9px 12px; border-radius: 8px;
		border: none; background: transparent;
		font-size: 13px; font-weight: 500; color: var(--on-surface-muted);
		cursor: pointer; transition: all 0.15s; text-align: left;
	}
	.sidebar-item:hover { background: var(--surface-dim); color: var(--on-surface); }
	.sidebar-item-active { background: var(--accent); color: #fff; }
	.sidebar-item-active:hover { background: var(--accent); color: #fff; }
	.sidebar-item :global(.sidebar-chevron) { width: 14px; height: 14px; opacity: 0.4; }
	.sidebar-item-active :global(.sidebar-chevron) { opacity: 0.7; }

	.sidebar-count {
		font-size: 10px; background: var(--surface-dim); padding: 1px 8px; border-radius: 99px;
		color: var(--on-surface-muted);
	}
	.sidebar-item-active .sidebar-count { background: rgba(255,255,255,0.2); color: #fff; }

	/* Price Filter */
	.price-inputs { display: flex; gap: 8px; margin-bottom: 10px; }
	.price-field { position: relative; flex: 1; }
	.price-symbol {
		position: absolute; left: 10px; top: 50%; transform: translateY(-50%);
		font-size: 12px; color: var(--on-surface-muted);
	}
	.price-input {
		width: 100%; padding: 8px 8px 8px 26px;
		border: 1px solid var(--border); border-radius: 8px;
		background: var(--surface-dim); font-size: 12px; font-weight: 500;
		color: var(--on-surface); outline: none;
	}
	.price-input:focus { border-color: var(--accent); }

	.apply-btn {
		width: 100%; padding: 8px;
		background: var(--accent); color: #fff; border: none; border-radius: 8px;
		font-size: 11px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase;
		cursor: pointer; transition: opacity 0.15s;
	}
	.apply-btn:hover { opacity: 0.9; }

	/* Stock Filter */
	.stock-toggle {
		display: flex; align-items: center; gap: 10px; cursor: pointer;
		font-size: 13px; font-weight: 500; color: var(--on-surface-muted);
	}
	.stock-checkbox {
		width: 18px; height: 18px; border-radius: 4px; border: 1px solid var(--border);
		accent-color: var(--accent);
	}

	/* ─── MAIN CONTENT ─── */
	.main-content { min-width: 0; }

	/* ─── CHIPS (branch, mobile categories) ─── */
	.branch-chips {
		display: flex; gap: 8px; overflow-x: auto; padding-bottom: 4px;
		margin-bottom: 16px;
		-ms-overflow-style: none; scrollbar-width: none;
	}
	.branch-chips::-webkit-scrollbar { display: none; }

	.chip {
		flex-shrink: 0;
		padding: 8px 20px; border-radius: 99px;
		border: 1px solid var(--border);
		background: #fff;
		font-size: 11px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase;
		color: var(--on-surface-muted);
		cursor: pointer; transition: all 0.15s;
	}
	.chip:hover { border-color: var(--on-surface-muted); }
	.chip-active { background: var(--accent); color: #fff; border-color: var(--accent); }
	.chip-sm { padding: 6px 16px; font-size: 10px; }

	/* ─── SEARCH BAR ─── */
	.search-bar {
		display: flex; gap: 10px;
		margin-bottom: 16px;
		flex-wrap: wrap;
	}
	.search-input-wrap { flex: 1; position: relative; min-width: 200px; }
	.search-input-wrap :global(.search-icon) {
		position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
		width: 16px; height: 16px; color: var(--on-surface-muted);
	}
	.search-input {
		width: 100%; padding: 10px 14px 10px 40px;
		border: 1px solid var(--border); border-radius: 8px;
		background: #fff; font-size: 13px; color: var(--on-surface);
		outline: none; transition: border-color 0.15s;
	}
	.search-input:focus { border-color: var(--accent); }

	.sort-select {
		padding: 10px 14px; border: 1px solid var(--border); border-radius: 8px;
		background: #fff; font-size: 13px; font-weight: 500; color: var(--on-surface);
		outline: none; cursor: pointer;
	}

	/* ─── PRODUCT GRID ─── */
	.products-section { padding: 0; }

	.product-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1.5rem 1rem;
	}
	@media (min-width: 768px) { .product-grid { grid-template-columns: repeat(2, 1fr); } }
	@media (min-width: 1024px) { .product-grid { grid-template-columns: repeat(3, 1fr); gap: 1.5rem; } }

	/* Product Card */
	.product-card {
		display: flex; flex-direction: column; gap: 0;
	}

	.product-img-wrap {
		position: relative;
		aspect-ratio: 3 / 4;
		overflow: hidden;
		background: var(--surface-dim);
		border-radius: 8px;
		display: block;
	}
	.product-img {
		width: 100%; height: 100%; object-fit: cover;
		transition: transform 0.5s ease;
	}
	.product-card:hover .product-img { transform: scale(1.04); }

	.product-img-placeholder {
		width: 100%; height: 100%;
		display: flex; align-items: center; justify-content: center;
		color: #d1d5db;
	}
	.product-img-placeholder :global(svg) { width: 40px; height: 40px; }

	.badge {
		position: absolute; top: 10px; left: 10px;
		padding: 3px 10px; border-radius: 4px;
		font-size: 9px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase;
	}
	.badge-discount { background: #059669; color: #fff; }
	.badge-low { position: absolute; top: 10px; right: 10px; left: auto; background: #ef4444; color: #fff; }

	.product-sold-out {
		position: absolute; inset: 0;
		background: rgba(255,255,255,0.7); backdrop-filter: blur(2px);
		display: flex; align-items: center; justify-content: center;
	}
	.product-sold-out span {
		background: var(--on-surface); color: #fff;
		padding: 6px 16px; border-radius: 8px;
		font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em;
	}

	/* Product Info */
	.product-info { padding: 12px 0 8px; flex: 1; }

	.product-rating {
		display: flex; align-items: center; gap: 1px; margin-bottom: 4px;
	}
	.product-rating :global(.star) { width: 12px; height: 12px; color: #d1d5db; }
	.product-rating :global(.star-filled) { color: #f59e0b; fill: #f59e0b; }

	.product-name {
		font-family: var(--font-display);
		font-size: 15px; font-weight: 500;
		color: var(--on-surface); line-height: 1.3;
		text-decoration: none;
		display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
	}
	.product-name:hover { text-decoration: underline; }

	.product-desc {
		font-size: 11px; color: var(--on-surface-muted);
		margin-top: 2px;
		display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden;
	}

	.product-price-row { margin-top: 6px; }
	.product-price { display: flex; align-items: baseline; gap: 6px; }
	.price-old { font-size: 11px; color: var(--on-surface-muted); text-decoration: line-through; }
	.price-current { font-size: 15px; font-weight: 600; color: var(--on-surface); }

	/* Add to Bag Button */
	.add-to-bag {
		width: 100%;
		border: none; border-top: 1px solid var(--border-light);
		background: none;
		padding: 10px 0;
		font-size: 10px; font-weight: 600; letter-spacing: 0.15em; text-transform: uppercase;
		color: var(--accent);
		cursor: pointer;
		display: flex; align-items: center; justify-content: space-between;
		transition: color 0.15s;
	}
	.add-to-bag:hover { color: var(--on-surface); }
	.add-to-bag :global(.bag-arrow) { width: 12px; height: 12px; transition: transform 0.2s; }
	.add-to-bag:hover :global(.bag-arrow) { transform: translateX(3px); }

	.unavailable-label {
		padding: 10px 0; border-top: 1px solid var(--border-light);
		font-size: 10px; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase;
		color: #ef4444;
	}

	/* ─── EMPTY / LOADING ─── */
	.empty-state {
		text-align: center; padding: 4rem 2rem;
		border: 1px dashed var(--border); border-radius: 8px; background: #fff;
	}
	.empty-state :global(.empty-icon) { width: 40px; height: 40px; color: #d1d5db; margin: 0 auto 16px; }
	.empty-title { font-family: var(--font-display); font-size: 18px; margin-bottom: 4px; }
	.empty-sub { font-size: 13px; color: var(--on-surface-muted); margin-bottom: 20px; }
	.empty-cta {
		padding: 10px 28px; border-radius: 8px;
		background: var(--accent); color: #fff;
		font-size: 12px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase;
		border: none; cursor: pointer;
	}

	.loading-state { min-height: 60vh; display: flex; align-items: center; justify-content: center; }
	.loader { width: 40px; height: 40px; border: 3px solid var(--border); border-top-color: var(--accent); border-radius: 50%; animation: spin 0.8s linear infinite; }

	.product-skeleton { display: flex; flex-direction: column; gap: 10px; }
	.skeleton-img { aspect-ratio: 3/4; background: var(--border-light); border-radius: 8px; animation: pulse 1.5s infinite; }
	.skeleton-text { height: 12px; background: var(--border-light); border-radius: 4px; animation: pulse 1.5s infinite; }
	.w60 { width: 60%; }
	.w40 { width: 40%; }

	/* ─── PAGINATION ─── */
	.pagination { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 2rem 0; }
	.page-btn {
		width: 38px; height: 38px; border-radius: 8px;
		border: 1px solid var(--border); background: #fff;
		display: flex; align-items: center; justify-content: center;
		font-size: 13px; font-weight: 500; cursor: pointer; transition: all 0.15s;
	}
	.page-btn:disabled { opacity: 0.3; cursor: not-allowed; }
	.page-active { background: var(--accent); color: #fff; border-color: var(--accent); }
	.page-btn :global(.page-arrow) { width: 16px; height: 16px; }

	/* ─── TRUST BADGES ─── */
	.trust-section {
		display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem;
		padding: 2rem;
		border-top: 1px solid var(--border);
	}
	.trust-badge { display: flex; align-items: center; gap: 12px; }
	.trust-icon {
		width: 40px; height: 40px; border-radius: 8px;
		display: flex; align-items: center; justify-content: center;
		flex-shrink: 0;
	}
	.trust-icon :global(svg) { width: 20px; height: 20px; }
	.trust-icon-green { background: #ecfdf5; color: #059669; }
	.trust-icon-amber { background: #fffbeb; color: #d97706; }
	.trust-title { font-size: 12px; font-weight: 600; color: var(--on-surface); }
	.trust-sub { font-size: 10px; color: var(--on-surface-muted); }

	/* ─── NEWSLETTER ─── */
	.newsletter-section {
		text-align: center; padding: 3.5rem 2rem;
		background: var(--surface-dim);
	}
	.newsletter-title { font-family: var(--font-display); font-size: 1.75rem; margin-bottom: 8px; }
	.newsletter-sub { font-size: 13px; color: var(--on-surface-muted); max-width: 320px; margin: 0 auto 24px; line-height: 1.7; }
	.newsletter-form { max-width: 320px; margin: 0 auto; }
	.newsletter-input {
		width: 100%;
		background: transparent; border: none; border-bottom: 1px solid var(--border);
		padding: 12px 0; font-size: 13px; color: var(--on-surface);
		outline: none;
	}
	.newsletter-input::placeholder { color: #b0b0a8; }
	.newsletter-input:focus { border-color: var(--accent); }
	.newsletter-btn {
		margin-top: 24px;
		padding: 0 0 4px; border: none; border-bottom: 1px solid var(--accent);
		background: none;
		font-size: 11px; font-weight: 600; letter-spacing: 0.15em; text-transform: uppercase;
		color: var(--accent); cursor: pointer;
	}

	/* ─── ANIMATIONS ─── */
	@keyframes heroZoom { from { transform: scale(1); } to { transform: scale(1.08); } }
	@keyframes spin { to { transform: rotate(360deg); } }
	@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }

	/* ─── RESPONSIVE ─── */
	@media (max-width: 640px) {
		.trust-section { grid-template-columns: 1fr; gap: 16px; }
		.hero-title { font-size: 1.75rem; }
	}
</style>
