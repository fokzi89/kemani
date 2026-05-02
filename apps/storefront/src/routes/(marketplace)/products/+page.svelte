<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { Search, ShoppingCart, ChevronRight, SlidersHorizontal, X, ArrowLeft, MessageSquare, CheckCircle2, Package, LayoutGrid, List, ChevronLeft } from 'lucide-svelte';
	import { cartStore } from '$lib/stores/cart.store';
	import { isAuthModalOpen, chatProduct, isChatOpen } from '$lib/stores/ui';
	import { isAuthenticated, currentUser } from '$lib/stores/auth';
	import { supabase } from '$lib/supabase';
	import { activeConversationId, setActiveConversation } from '$lib/stores/chat.store';
	import { get } from 'svelte/store';

	export let data;

	$: storefront = data.storefront;

	let products = data.products || [];
	let categories = data.categories || [];
	let isLoading = false;
	let showMobileFilters = false;

	// Filters
	let selectedCategory = data.filters?.category || '';
	let searchQuery = data.filters?.search || '';
	let minPrice = data.filters?.minPrice?.toString() || '';
	let maxPrice = data.filters?.maxPrice?.toString() || '';
	let sortBy = data.filters?.sortBy || 'newest';
	let inStockOnly = data.filters?.inStockOnly ?? true;

	// Toast
	let showToast = false;
	let toastProduct = '';
	let toastTimeout: any;

	// Pagination + view
	let currentPage = 1;
	let totalPages = data.pagination?.pages || 1;
	let totalCount = data.pagination?.total || 0;
	let viewMode: 'grid' | 'list' = 'grid';

	async function loadProducts(resetPage = true) {
		if (resetPage) currentPage = 1;
		isLoading = true;
		try {
			const p = new URLSearchParams();
			if (selectedCategory) p.set('category', selectedCategory);
			if (searchQuery) p.set('search', searchQuery);
			if (minPrice) p.set('min_price', minPrice);
			if (maxPrice) p.set('max_price', maxPrice);
			if (inStockOnly) p.set('in_stock_only', 'true');
			p.set('sort_by', sortBy);
			p.set('page', currentPage.toString());
			p.set('limit', '24');

			const res = await fetch(`/api/marketplace/products?${p}`);
			const json = await res.json();
			products = json.products || [];
			totalPages = json.pagination?.pages || 1;
			totalCount = json.pagination?.total || 0;
		} catch { products = []; }
		finally { isLoading = false; }
	}

	async function goToPage(p: number) {
		if (p < 1 || p > totalPages) return;
		currentPage = p;
		await loadProducts(false);
		window.scrollTo({ top: 0, behavior: 'smooth' });
	}

	function addToCart(product: any) {
		cartStore.addItem({
			product_id: product.id,
			product_name: product.name,
			product_image: product.image_url,
			price: product.price,
			quantity: 1,
			stock_available: product.stock_quantity
		}, storefront.id);
		toastProduct = product.name;
		showToast = true;
		if (toastTimeout) clearTimeout(toastTimeout);
		toastTimeout = setTimeout(() => showToast = false, 2500);
	}

	function selectCategory(cat: string) {
		selectedCategory = cat;
		loadProducts();
	}

	function applyFilters() {
		showMobileFilters = false;
		loadProducts();
	}

	function clearFilters() {
		selectedCategory = '';
		searchQuery = '';
		minPrice = '';
		maxPrice = '';
		sortBy = 'newest';
		inStockOnly = true;
		loadProducts();
	}

	$: activeFilterCount = [
		selectedCategory,
		searchQuery,
		minPrice,
		maxPrice,
		!inStockOnly ? 'stock' : ''
	].filter(Boolean).length;

	async function handleRxChat(e?: Event, onBeforeOpen?: () => void, productId?: string) {
		e?.stopPropagation();
		if (!$isAuthenticated) {
			if (onBeforeOpen) onBeforeOpen();
			const redirectUrl = productId ? `/chat?productId=${productId}&type=Consultation` : '/chat?type=Consultation';
			localStorage.setItem('pending_chat_redirect', redirectUrl);
			isAuthModalOpen.set(true);
			return;
		}

		const chatUrl = productId ? `/chat?productId=${productId}&type=Consultation` : '/chat?type=Consultation';
		const existingId = get(activeConversationId);
		if (existingId) {
			goto(`${chatUrl}${chatUrl.includes('?') ? '&' : '?'}id=${existingId}`);
			return;
		}

		try {
			const { data: created, error } = await supabase
				.from('chat_conversations')
				.insert({
					customer_id: $currentUser.id,
					tenant_id: storefront?.id,
					chatType: 'Consultation',
					customer_name: $currentUser?.user_metadata?.full_name || $currentUser?.email,
					customer_pic: $currentUser?.user_metadata?.avatar_url,
					isConsulatation: true,
					status: 'active',
					metadata: { 
						origin: 'storefront_products_list',
						productId: productId
					}
				})
				.select().single();

			if (error) throw error;
			if (created) {
				setActiveConversation(created.id);
				goto(`${chatUrl}${chatUrl.includes('?') ? '&' : '?'}id=${created.id}`);
			}
		} catch (err) {
			console.error('Failed to initiate consultation chat:', err);
			goto(chatUrl);
		}
	}
</script>

<svelte:head>
	<title>{storefront?.name || 'Store'} — All Products</title>
	<meta name="description" content="Browse all products at {storefront?.name || 'our store'}." />
</svelte:head>

<div class="products-page">

	<!-- ── PAGE HEADER ── -->
	<div class="page-header">
		<div class="page-header-inner">
			<div class="breadcrumb">
				<a href="/">Home</a>
				<ChevronRight class="w-3 h-3" />
				<span>Products</span>
			</div>
			<h1 class="page-title">All Products</h1>
			{#if selectedCategory}
				<p class="page-subtitle">Browsing <strong>{selectedCategory}</strong></p>
			{:else}
				<p class="page-subtitle">{products.length} products available</p>
			{/if}
		</div>
	</div>

	<!-- ── CATEGORY CHIPS (top horizontal) ── -->
	<div class="category-strip">
		<div class="category-strip-inner">
			<button class="cat-chip" class:active={!selectedCategory} onclick={() => selectCategory('')}>
				All
			</button>
			{#each categories as cat}
				<button class="cat-chip" class:active={selectedCategory === cat.name} onclick={() => selectCategory(cat.name)}>
					{cat.name}
					{#if cat.count}<span class="cat-count">{cat.count}</span>{/if}
				</button>
			{/each}
		</div>
	</div>

	<!-- ── MAIN LAYOUT ── -->
	<div class="layout">

		<!-- LEFT SIDEBAR -->
		<aside class="sidebar" class:mobile-open={showMobileFilters}>
			<div class="sidebar-header">
				<h2 class="sidebar-title">Filters</h2>
				{#if activeFilterCount > 0}
					<button class="clear-btn" onclick={clearFilters}>Clear all ({activeFilterCount})</button>
				{/if}
				<button class="sidebar-close md:hidden" onclick={() => showMobileFilters = false}><X class="w-4 h-4" /></button>
			</div>

			<!-- Sort -->
			<div class="filter-block">
				<h3 class="filter-label">Sort By</h3>
				<select bind:value={sortBy} onchange={loadProducts} class="filter-select">
					<option value="newest">Newest First</option>
					<option value="price_asc">Price: Low → High</option>
					<option value="price_desc">Price: High → Low</option>
					<option value="name">Name A–Z</option>
				</select>
			</div>

			<!-- Price -->
			<div class="filter-block">
				<h3 class="filter-label">Price Range (₦)</h3>
				<div class="price-row">
					<input type="number" bind:value={minPrice} placeholder="Min" class="price-input" />
					<span class="price-dash">—</span>
					<input type="number" bind:value={maxPrice} placeholder="Max" class="price-input" />
				</div>
				<button class="apply-btn" onclick={applyFilters}>Apply</button>
			</div>

			<!-- Stock -->
			<div class="filter-block">
				<label class="stock-label">
					<input type="checkbox" bind:checked={inStockOnly} onchange={loadProducts} class="stock-check" />
					In stock only
				</label>
			</div>
		</aside>

		<!-- MAIN CONTENT -->
		<main class="main">
			<!-- Search + mobile filter trigger -->
			<div class="toolbar">
				<div class="search-wrap">
					<Search class="search-icon" />
					<input
						type="search"
						bind:value={searchQuery}
						onkeydown={(e) => e.key === 'Enter' && loadProducts()}
						placeholder="Search products..."
						class="search-input"
					/>
				</div>
				<button class="filter-toggle" onclick={() => showMobileFilters = true}>
					<SlidersHorizontal class="w-4 h-4" />
					Filters {#if activeFilterCount > 0}<span class="filter-badge">{activeFilterCount}</span>{/if}
				</button>
				<!-- View toggle -->
				<div class="view-toggle">
					<button class="view-btn" class:view-active={viewMode === 'grid'} onclick={() => viewMode = 'grid'} title="Grid view">
						<LayoutGrid class="w-4 h-4" />
					</button>
					<button class="view-btn" class:view-active={viewMode === 'list'} onclick={() => viewMode = 'list'} title="List view">
						<List class="w-4 h-4" />
					</button>
				</div>
			</div>

			<!-- Products -->
			{#if isLoading}
				<div class="grid">
					{#each Array(8) as _}
						<div class="skeleton">
							<div class="skel-img"></div>
							<div class="skel-line w70"></div>
							<div class="skel-line w50"></div>
						</div>
					{/each}
				</div>
			{:else if products.length === 0}
				<div class="empty">
					<Package class="empty-icon" />
					<h3>No products found</h3>
					<p>Try adjusting your filters.</p>
					<button class="empty-btn" onclick={clearFilters}>Clear Filters</button>
				</div>
			{:else}
				<!-- Results info -->
				<p class="results-info">{totalCount} products · Page {currentPage} of {totalPages}</p>

				<!-- GRID VIEW -->
				{#if viewMode === 'grid'}
					<div class="grid">
						{#each products as product}
							<div class="card">
								<a href="/products/{product.id}" class="card-img-wrap">
									{#if product.image_url}<img src={product.image_url} alt={product.name} class="card-img" />{:else}<div class="card-img-ph"><Package class="w-10 h-10 text-gray-300" /></div>{/if}
									{#if product.percentage_discount > 0}<span class="discount-badge">{product.percentage_discount}% Off</span>{/if}
									{#if !product.is_available}<div class="sold-out-overlay"><span>Sold Out</span></div>{/if}
								</a>
								<div class="card-body">
									<p class="card-cat">{product.category || 'Product'}</p>
									<a href="/products/{product.id}" class="card-name">{product.name}</a>
									<div class="card-footer">
										<span class="card-price">₦{(product.sale_price > 0 ? product.sale_price : product.price)?.toLocaleString()}</span>
										<div class="card-actions">
											<button class="rx-btn" onclick={(e) => handleRxChat(e, undefined, product.id)} title="Rx Chat"><MessageSquare class="w-4 h-4" /></button>
											{#if product.is_available && product.stock_quantity > 0}
												<button class="add-btn" onclick={() => addToCart(product)} title="Add to cart"><ShoppingCart class="w-4 h-4" /></button>
											{/if}
										</div>
									</div>
								</div>
							</div>
						{/each}
					</div>
				{:else}
					<!-- LIST VIEW -->
					<div class="list">
						{#each products as product}
							<div class="list-card">
								<a href="/products/{product.id}" class="list-img-wrap">
									{#if product.image_url}<img src={product.image_url} alt={product.name} class="list-img" />{:else}<div class="list-img-ph"><Package class="w-8 h-8 text-gray-300" /></div>{/if}
									{#if !product.is_available}<div class="list-sold-out">Sold Out</div>{/if}
								</a>
								<div class="list-body">
									<p class="card-cat">{product.category || 'Product'}</p>
									<a href="/products/{product.id}" class="list-name">{product.name}</a>
									{#if product.description}<p class="list-desc">{product.description}</p>{/if}
								</div>
								<div class="list-right">
									{#if product.percentage_discount > 0}<span class="discount-badge" style="position:static;margin-bottom:6px">{product.percentage_discount}% Off</span>{/if}
									<span class="card-price">₦{(product.sale_price > 0 ? product.sale_price : product.price)?.toLocaleString()}</span>
									<div class="list-actions-row">
										<button class="rx-btn list-rx" onclick={(e) => handleRxChat(e, undefined, product.id)} title="Rx Chat">
											<MessageSquare class="w-4 h-4" />
										</button>
										{#if product.is_available && product.stock_quantity > 0}
											<button class="add-btn" style="width:auto;padding:0 14px;gap:6px;" onclick={() => addToCart(product)}>
												<ShoppingCart class="w-4 h-4" /> Add
											</button>
										{:else}
											<span class="list-out">Out of stock</span>
										{/if}
									</div>
								</div>
							</div>
						{/each}
					</div>
				{/if}

				<!-- PAGINATION -->
				{#if totalPages > 1}
					<div class="pagination">
						<button class="page-btn" disabled={currentPage === 1} onclick={() => goToPage(currentPage - 1)}>
							<ChevronLeft class="w-4 h-4" />
						</button>
						{#each Array(totalPages) as _, i}
							{@const p = i + 1}
							{#if p === 1 || p === totalPages || Math.abs(p - currentPage) <= 1}
								<button class="page-btn" class:page-active={currentPage === p} onclick={() => goToPage(p)}>{p}</button>
							{:else if Math.abs(p - currentPage) === 2}
								<span class="page-ellipsis">…</span>
							{/if}
						{/each}
						<button class="page-btn" disabled={currentPage === totalPages} onclick={() => goToPage(currentPage + 1)}>
							<ChevronRight class="w-4 h-4" />
						</button>
					</div>
				{/if}
			{/if}
		</main>
	</div>
</div>

<!-- Mobile filter overlay backdrop -->
{#if showMobileFilters}
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div class="backdrop" onclick={() => showMobileFilters = false}></div>
{/if}

<!-- Toast -->
{#if showToast}
	<div class="toast">
		<CheckCircle2 class="w-4 h-4 text-emerald-500" />
		<span><strong>{toastProduct}</strong> added to bag</span>
		<a href="/cart" class="toast-link">View Bag</a>
	</div>
{/if}

<style>
	.products-page { background: #faf9f6; min-height: 100vh; }

	/* Page header */
	.page-header { background: #fff; border-bottom: 1px solid #f1f5f9; padding: 1.5rem 0; }
	.page-header-inner { max-width: 1280px; margin: 0 auto; padding: 0 1.5rem; }
	.breadcrumb { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #94a3b8; margin-bottom: 8px; }
	.breadcrumb a { color: #94a3b8; text-decoration: none; } .breadcrumb a:hover { color: #0f172a; }
	.page-title { font-size: 1.75rem; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; }
	.page-subtitle { font-size: 13px; color: #64748b; margin-top: 4px; }

	/* Category strip */
	.category-strip { background: #fff; border-bottom: 1px solid #f1f5f9; position: sticky; top: 0; z-index: 40; }
	.category-strip-inner {
		max-width: 1280px; margin: 0 auto; padding: 0.75rem 1.5rem;
		display: flex; gap: 8px; overflow-x: auto; -ms-overflow-style: none; scrollbar-width: none;
	}
	.category-strip-inner::-webkit-scrollbar { display: none; }
	.cat-chip {
		flex-shrink: 0; padding: 6px 16px; border-radius: 99px;
		border: 1px solid #e2e8f0; background: #fff;
		font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em;
		color: #64748b; cursor: pointer; transition: all 0.15s; display: flex; align-items: center; gap: 6px;
	}
	.cat-chip:hover { border-color: #0f172a; color: #0f172a; }
	.cat-chip.active { background: #0f172a; color: #fff; border-color: #0f172a; }
	.cat-count { font-size: 9px; background: rgba(255,255,255,0.2); padding: 1px 6px; border-radius: 99px; }
	.cat-chip:not(.active) .cat-count { background: #f1f5f9; color: #94a3b8; }

	/* Layout */
	.layout { max-width: 1280px; margin: 0 auto; padding: 2rem 1.5rem; display: grid; grid-template-columns: 1fr; gap: 2rem; }
	@media (min-width: 1024px) { .layout { grid-template-columns: 240px 1fr; } }

	/* Sidebar */
	.sidebar {
		background: #fff; border: 1px solid #f1f5f9; border-radius: 16px;
		padding: 1.25rem; height: fit-content; position: sticky; top: 80px;
		display: none;
	}
	@media (min-width: 1024px) { .sidebar { display: block; } }
	.sidebar.mobile-open {
		display: block; position: fixed; top: 0; left: 0; bottom: 0; z-index: 100;
		width: 280px; border-radius: 0; overflow-y: auto; box-shadow: 4px 0 30px rgba(0,0,0,0.12);
	}
	.sidebar-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.25rem; }
	.sidebar-title { font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.08em; color: #0f172a; }
	.clear-btn { font-size: 11px; color: #ef4444; font-weight: 600; border: none; background: none; cursor: pointer; }
	.sidebar-close { border: none; background: none; cursor: pointer; padding: 4px; }

	.filter-block { margin-bottom: 1.25rem; padding-bottom: 1.25rem; border-bottom: 1px solid #f1f5f9; }
	.filter-block:last-child { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
	.filter-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; color: #94a3b8; margin-bottom: 10px; }
	.filter-select { width: 100%; padding: 8px 12px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 13px; background: #faf9f6; }
	.price-row { display: flex; gap: 8px; align-items: center; margin-bottom: 10px; }
	.price-input { flex: 1; padding: 8px 10px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 12px; min-width: 0; }
	.price-dash { color: #94a3b8; font-size: 12px; }
	.apply-btn { width: 100%; padding: 8px; background: #0f172a; color: #fff; border: none; border-radius: 8px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; cursor: pointer; }
	.stock-label { display: flex; align-items: center; gap: 10px; font-size: 13px; color: #475569; cursor: pointer; font-weight: 500; }
	.stock-check { accent-color: #0f172a; width: 16px; height: 16px; }

	/* Toolbar */
	.toolbar { display: flex; gap: 10px; margin-bottom: 1.5rem; }
	.search-wrap { flex: 1; position: relative; }
	.search-input { width: 100%; padding: 10px 14px 10px 40px; border: 1px solid #e2e8f0; border-radius: 12px; background: #fff; font-size: 13px; outline: none; }
	.search-input:focus { border-color: #0f172a; }
	.search-wrap :global(.search-icon) { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); width: 16px; height: 16px; color: #94a3b8; }
	.filter-toggle {
		display: flex; align-items: center; gap: 8px; padding: 10px 16px;
		border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
		font-size: 12px; font-weight: 600; cursor: pointer; white-space: nowrap;
	}
	@media (min-width: 1024px) { .filter-toggle { display: none; } }
	.filter-badge { background: #0f172a; color: #fff; font-size: 10px; padding: 1px 6px; border-radius: 99px; }

	/* Grid */
	.grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
	@media (min-width: 640px) { .grid { grid-template-columns: repeat(2, 1fr); } }
	@media (min-width: 1024px) { .grid { grid-template-columns: repeat(3, 1fr); gap: 1.25rem; } }

	/* Card */
	.card { background: #fff; border: 1px solid #f1f5f9; border-radius: 16px; overflow: hidden; transition: transform 0.2s, box-shadow 0.2s; }
	.card:hover { transform: translateY(-3px); box-shadow: 0 12px 24px rgba(0,0,0,0.06); }
	.card-img-wrap { display: block; position: relative; height: 180px; background: #f8fafc; }
	.card-img { width: 100%; height: 100%; object-fit: cover; }
	.card-img-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; }
	.discount-badge { position: absolute; top: 10px; left: 10px; background: #0f172a; color: #fff; font-size: 9px; font-weight: 700; padding: 3px 8px; border-radius: 4px; text-transform: uppercase; }
	.sold-out-overlay { position: absolute; inset: 0; background: rgba(255,255,255,0.8); display: flex; align-items: center; justify-content: center; }
	.sold-out-overlay span { background: #0f172a; color: #fff; font-size: 10px; font-weight: 700; padding: 5px 12px; border-radius: 6px; text-transform: uppercase; }
	.card-body { padding: 0.875rem; }
	.card-cat { font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: #94a3b8; margin-bottom: 4px; }
	.card-name { font-size: 13px; font-weight: 700; color: #0f172a; text-decoration: none; display: block; margin-bottom: 10px; line-height: 1.3; }
	.card-name:hover { color: #4f46e5; }
	.card-footer { display: flex; align-items: center; justify-content: space-between; }
	.card-price { font-size: 15px; font-weight: 900; color: #0f172a; }
	.card-actions { display: flex; gap: 8px; align-items: center; }
	.rx-btn { width: 34px; height: 34px; background: #eff6ff; color: #1d4ed8; border: none; border-radius: 10px; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s; }
	.rx-btn:hover { background: #dbeafe; }
	.list-rx { background: #f1f5f9; color: #64748b; }
	.list-actions-row { display: flex; gap: 8px; align-items: center; }
	.add-btn { width: 34px; height: 34px; background: #0f172a; color: #fff; border: none; border-radius: 10px; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: opacity 0.15s; flex-shrink: 0; }
	.add-btn:hover { opacity: 0.8; }

	/* Skeleton */
	.skeleton { background: #fff; border: 1px solid #f1f5f9; border-radius: 16px; overflow: hidden; }
	.skel-img { height: 180px; background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%); background-size: 200%; animation: shimmer 1.5s infinite; }
	.skel-line { height: 12px; background: #f1f5f9; border-radius: 6px; margin: 12px; }
	.w70 { width: 70%; } .w50 { width: 50%; }
	@keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }

	/* Empty */
	.empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 5rem 2rem; text-align: center; }
	.empty :global(.empty-icon) { width: 48px; height: 48px; color: #cbd5e1; margin-bottom: 1rem; }
	.empty h3 { font-size: 16px; font-weight: 800; color: #0f172a; margin-bottom: 6px; }
	.empty p { font-size: 13px; color: #64748b; margin-bottom: 1.25rem; }
	.empty-btn { padding: 10px 24px; background: #0f172a; color: #fff; border: none; border-radius: 10px; font-size: 12px; font-weight: 700; cursor: pointer; text-transform: uppercase; letter-spacing: 0.06em; }

	/* Backdrop */
	.backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 99; backdrop-filter: blur(4px); }

	/* Toast */
	.toast {
		position: fixed; bottom: 6rem; right: 2rem; z-index: 200;
		background: #fff; border: 1px solid #f1f5f9; border-radius: 14px;
		padding: 12px 16px; display: flex; align-items: center; gap: 10px;
		box-shadow: 0 8px 30px rgba(0,0,0,0.12); font-size: 13px;
		animation: slideUp 0.3s ease;
	}
	.toast-link { color: #4f46e5; font-weight: 700; text-decoration: none; margin-left: 4px; }
	/* View toggle */
	.view-toggle { display: flex; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; background: #fff; flex-shrink: 0; }
	.view-btn { width: 38px; height: 38px; display: flex; align-items: center; justify-content: center; border: none; background: transparent; color: #94a3b8; cursor: pointer; transition: all 0.15s; }
	.view-btn:hover { color: #0f172a; }
	.view-btn.view-active { background: #0f172a; color: #fff; }

	/* Results info */
	.results-info { font-size: 12px; color: #94a3b8; margin-bottom: 1rem; }

	/* List view */
	.list { display: flex; flex-direction: column; gap: 12px; }
	.list-card { display: flex; gap: 1rem; align-items: center; background: #fff; border: 1px solid #f1f5f9; border-radius: 16px; overflow: hidden; padding: 0.75rem; transition: box-shadow 0.2s; }
	.list-card:hover { box-shadow: 0 6px 20px rgba(0,0,0,0.06); }
	.list-img-wrap { position: relative; width: 80px; height: 80px; flex-shrink: 0; border-radius: 10px; overflow: hidden; background: #f8fafc; display: block; }
	.list-img { width: 100%; height: 100%; object-fit: cover; }
	.list-img-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; }
	.list-sold-out { position: absolute; inset: 0; background: rgba(255,255,255,0.8); display: flex; align-items: center; justify-content: center; font-size: 9px; font-weight: 700; color: #0f172a; text-transform: uppercase; }
	.list-body { flex: 1; min-width: 0; }
	.list-name { font-size: 14px; font-weight: 700; color: #0f172a; text-decoration: none; display: block; margin-bottom: 4px; }
	.list-name:hover { color: #4f46e5; }
	.list-desc { font-size: 12px; color: #64748b; margin-top: 2px; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
	.list-right { display: flex; flex-direction: column; align-items: flex-end; gap: 8px; flex-shrink: 0; }
	.list-out { font-size: 11px; color: #94a3b8; font-weight: 600; }

	/* Pagination */
	.pagination { display: flex; align-items: center; justify-content: center; gap: 6px; margin-top: 2rem; padding-top: 1.5rem; border-top: 1px solid #f1f5f9; }
	.page-btn { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; border: 1px solid #e2e8f0; border-radius: 10px; background: #fff; font-size: 13px; font-weight: 600; color: #475569; cursor: pointer; transition: all 0.15s; }
	.page-btn:hover:not(:disabled) { border-color: #0f172a; color: #0f172a; }
	.page-btn:disabled { opacity: 0.35; cursor: not-allowed; }
	.page-btn.page-active { background: #0f172a; color: #fff; border-color: #0f172a; }
	.page-ellipsis { font-size: 13px; color: #94a3b8; padding: 0 4px; }
</style>
