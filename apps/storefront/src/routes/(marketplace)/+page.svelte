<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import type { MarketplaceProduct } from '$lib/types/ecommerce';
	import { fade, scale } from 'svelte/transition';
	import {
		Search, ShoppingCart, ChevronRight, Star,
		Clock, ShieldCheck, Tag, ArrowRight, Plus, ArrowLeft, MessageSquare, Stethoscope, CheckCircle2, Minus, X
	} from 'lucide-svelte';
	import { isAuthenticated, currentUser } from '$lib/stores/auth';
	import { isAuthModalOpen, isChatOpen, chatProduct, authRedirect } from '$lib/stores/ui';
	import { supabase } from '$lib/supabase';
	import { activeConversationId, setActiveConversation } from '$lib/stores/chat.store';
	import { get } from 'svelte/store';
	import { PUBLIC_APP_URL } from '$env/static/public';
	import { cartStore } from '$lib/stores/cart.store';

	$: storefront = data.storefront;
	$: brandColor      = storefront?.brand_color || '#4f46e5';
	$: brandColorLight = brandColor + '18';
	$: storeUrl = $page.url.origin;

	export let data;

	let featuredProducts: MarketplaceProduct[] = [];
	let onSaleProducts: MarketplaceProduct[] = [];
	let newArrivals: MarketplaceProduct[] = [];
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

	let showToast        = false;
	let toastProduct     = '';
	let toastTimeout: ReturnType<typeof setTimeout> | null = null;
    
	let itemQuantity = 1;

	onMount(async () => {
		await Promise.all([loadCategories(), loadProducts()]);
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
			// Fetch Featured Products
			const featuredParams = new URLSearchParams({ is_featured: 'true', limit: '8', in_stock_only: 'true' });
			const featuredRes = await fetch(`/api/marketplace/products?${featuredParams}`);
			const featuredJson = await featuredRes.json();
			featuredProducts = featuredJson.products || [];

			// Fetch On Sale Products
			const saleParams = new URLSearchParams({ is_on_sale: 'true', limit: '8', in_stock_only: 'true' });
			const saleRes = await fetch(`/api/marketplace/products?${saleParams}`);
			const saleJson = await saleRes.json();
			onSaleProducts = saleJson.products || [];

			// Fetch New Arrivals
			const newParams = new URLSearchParams({ is_new_arrival: 'true', limit: '8', in_stock_only: 'true' });
			const newRes = await fetch(`/api/marketplace/products?${newParams}`);
			const newJson = await newRes.json();
			newArrivals = newJson.products || [];

			// If no specific products found, fill with general products as fallback
			if (featuredProducts.length === 0) {
				const fallbackParams = new URLSearchParams({ limit: '8', in_stock_only: 'true' });
				const fallbackRes = await fetch(`/api/marketplace/products?${fallbackParams}`);
				const fallbackJson = await fallbackRes.json();
				featuredProducts = fallbackJson.products || [];
			}
		} catch (err) {
			console.error('Failed to load home page products', err);
		} finally {
			isLoading = false;
		}
	}

	function addToCart(product: MarketplaceProduct, qty: number = 1) {
		cartStore.addItem({
			product_id:     product.id,
			product_name:   product.name,
			product_image:  product.image_url,
			price:          product.price,
			quantity:       qty,
			stock_available: product.stock_quantity
		}, storefront.id);

		// Show toast feedback
		toastProduct = product.name;
		showToast = true;
		if (toastTimeout) clearTimeout(toastTimeout);
		toastTimeout = setTimeout(() => { showToast = false; }, 2500);
	}

	async function handleRxChat(e?: Event, onBeforeOpen?: () => void, productId?: string) {
		e?.stopPropagation();
		if (!$isAuthenticated) {
			// Run any pre-action (e.g. close product modal) before opening auth modal
			if (onBeforeOpen) onBeforeOpen();
			const redirectUrl = productId ? `/chat?productId=${productId}&type=Consultation` : '/chat?type=Consultation';
			localStorage.setItem('pending_chat_redirect', redirectUrl);
			isAuthModalOpen.set(true);
			return;
		}

		const chatUrl = productId ? `/chat?productId=${productId}&type=Consultation` : '/chat?type=Consultation';

		// Check for existing active conversation
		const existingId = get(activeConversationId);
		if (existingId) {
			goto(`${chatUrl}${chatUrl.includes('?') ? '&' : '?'}id=${existingId}`);
			return;
		}

		// Create new "Consultation" chat
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
						origin: 'storefront_rx',
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

	function handleSearch()                { currentPage = 1; loadProducts(); }
	function handleCategoryClick(c: string){ selectedCategory = c; currentPage = 1; loadProducts(); }
	function handleBranchClick(id: string) { selectedBranch = id; currentPage = 1; loadProducts(); }
	function handlePageChange(p: number)   { currentPage = p; loadProducts(); window.scrollTo({ top: 0, behavior: 'smooth' }); }

	function handleProductChat(product: any, e?: Event) {
		e?.stopPropagation();
		e?.preventDefault();
		if (!$isAuthenticated) {
			localStorage.setItem('pending_chat_redirect', '/chat');
			isAuthModalOpen.set(true);
			return;
		}
		chatProduct.set(product);
		isChatOpen.set(true);
	}
</script>

<svelte:head>
	<title>{storefront?.name || 'Store'} — Shop Online</title>
	<meta name="description" content="Shop {storefront?.name || 'our store'} online." />
	<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
</svelte:head>

<div class="store-page">
	{#if storefront}

		<!-- ═══════════ HERO SECTION ═══════════ -->
		<section class="hero-section" style="background-color: #0b1a30;">
			<div class="hero-content">
				<span class="hero-label">
					<Tag class="label-icon" /> {storefront.slogan || storefront.name}
				</span>
				<h2 class="hero-title">
					{#if storefront?.hero_title}
						{storefront.hero_title}
					{:else if storefront?.allowDoctorPartnerShip ?? true}
						Discover Medics,<br/>Delivered to You
					{:else}
						Premium Health,<br/>Delivered to You
					{/if}
				</h2>
				<p class="hero-subtitle">
					{storefront?.hero_subtitle || 'Curated healthcare products — quality you can trust, prices you can afford.'}
				</p>
				<div class="hero-cta-row">
					<a href="/products" class="hero-cta">
						Shop Now <ArrowRight class="cta-arrow" />
					</a>
					<button class="hero-cta hero-cta-ghost" onclick={() => handleRxChat()}>
						<MessageSquare class="cta-arrow" /> Chat Pharmacist
					</button>
				</div>
			</div>
		</section>

		<!-- ═══════════ FEATURED PRODUCTS ═══════════ -->
		<section class="home-section" id="shop">
			<div class="section-header">
				<div>
					<p class="section-label">Handpicked for you</p>
					<h2 class="section-title">Featured Products</h2>
				</div>
				<a href="/featured" class="see-all">See All <ArrowRight class="w-3.5 h-3.5" /></a>
			</div>
			{#if isLoading}
				<div class="home-grid">{#each Array(4) as _}<div class="product-skeleton"><div class="skeleton-img"></div><div class="skeleton-text w60"></div><div class="skeleton-text w40"></div></div>{/each}</div>
			{:else if featuredProducts.length === 0}
				<div class="empty-state"><ShoppingCart class="empty-icon" /><p class="empty-title">No featured products yet</p></div>
			{:else}
				<div class="home-grid">
					{#each featuredProducts as product}
						<div class="product-card">
							<a href={`/products/${product.id}`} class="product-img-wrap border-none outline-none text-left w-full cursor-pointer p-0 bg-transparent block">
								{#if product.image_url}<img src={product.image_url} alt={product.name} class="product-img" />{:else}<div class="product-img-placeholder"><ShoppingCart /></div>{/if}
								{#if product.percentage_discount > 0}<span class="badge badge-discount">{product.percentage_discount}% Off</span>{/if}
								{#if !product.is_available}<div class="product-sold-out"><span>Sold Out</span></div>{/if}
							</a>
							<div class="product-info">
								<div class="product-category">{product.category?.name || (product as any).category_name || 'PRODUCT'}</div>
								<a href={`/products/${product.id}`} class="product-name border-none bg-transparent outline-none p-0 text-left w-full cursor-pointer">{product.name}</a>
								<div class="product-bottom-row">
									<span class="price-current font-black text-lg">₦{(product.sale_price > 0 ? product.sale_price : product.price)?.toLocaleString()}</span>
									<div class="product-actions-flex">
										<button class="action-icon-btn action-rx" onclick={(e) => { e.preventDefault(); handleRxChat(e, undefined, product.id); }} title="RX Chat"><MessageSquare class="w-4 h-4" /></button>
										{#if product.is_available && product.stock_quantity > 0}<button class="action-icon-btn action-bag" onclick={(e) => { e.preventDefault(); e.stopPropagation(); addToCart(product); }} title="Add to Bag"><ShoppingCart class="w-4 h-4" /></button>{/if}
									</div>
								</div>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</section>

		<!-- ═══════════ PRODUCTS ON SALE ═══════════ -->
		{#if onSaleProducts.length > 0}
		<section class="home-section">
			<div class="section-header">
				<div>
					<p class="section-label">Flash Deals</p>
					<h2 class="section-title">On Sale Now</h2>
				</div>
				<a href="/on-sale" class="see-all">View All <ArrowRight class="w-3.5 h-3.5" /></a>
			</div>
			<div class="home-grid">
				{#each onSaleProducts as product}
					<div class="product-card">
						<a href={`/products/${product.id}`} class="product-img-wrap border-none outline-none text-left w-full cursor-pointer p-0 bg-transparent block">
							{#if product.image_url}<img src={product.image_url} alt={product.name} class="product-img" />{:else}<div class="product-img-placeholder"><ShoppingCart /></div>{/if}
							<span class="badge badge-discount">{product.percentage_discount || 10}% Off</span>
							{#if !product.is_available}<div class="product-sold-out"><span>Sold Out</span></div>{/if}
						</a>
						<div class="product-info">
							<div class="product-category">{product.category?.name || (product as any).category_name || 'SALE'}</div>
							<a href={`/products/${product.id}`} class="product-name border-none bg-transparent outline-none p-0 text-left w-full cursor-pointer">{product.name}</a>
							<div class="product-bottom-row">
								<div class="price-stack">
									<span class="price-current font-black text-lg text-emerald-600">₦{(product.sale_price > 0 ? product.sale_price : product.price)?.toLocaleString()}</span>
									{#if product.selling_price && product.selling_price > (product.sale_price || product.price)}
										<span class="price-old text-xs text-gray-400 line-through">₦{product.selling_price.toLocaleString()}</span>
									{/if}
								</div>
								<div class="product-actions-flex">
									<button class="action-icon-btn action-rx" onclick={(e) => { e.preventDefault(); handleRxChat(e, undefined, product.id); }} title="RX Chat"><MessageSquare class="w-4 h-4" /></button>
									{#if product.is_available && product.stock_quantity > 0}<button class="action-icon-btn action-bag" onclick={(e) => { e.preventDefault(); e.stopPropagation(); addToCart(product); }} title="Add to Bag"><ShoppingCart class="w-4 h-4" /></button>{/if}
								</div>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>
		{/if}

		<!-- ═══════════ PHARMACIST CTA BANNER ═══════════ -->
		<section class="rx-banner">
			<div class="rx-banner-inner">
				<div class="rx-icon-wrap">
					<Stethoscope class="rx-icon" />
				</div>
				<div class="rx-copy">
					<h3 class="rx-title">Not sure what you need?</h3>
					<p class="rx-sub">Our licensed pharmacists are online and ready to help. Get free, personalised advice in under a minute.</p>
				</div>
				<button class="rx-cta" onclick={() => handleRxChat()}>
					<MessageSquare class="w-4 h-4" /> Chat with a Pharmacist
				</button>
			</div>
		</section>

		<!-- ═══════════ NEW ARRIVALS ═══════════ -->
		{#if newArrivals.length > 0}
		<section class="home-section">
			<div class="section-header">
				<div>
					<p class="section-label">Just landed</p>
					<h2 class="section-title">New Arrivals</h2>
				</div>
				<a href="/products?sort=newest" class="see-all">View All <ArrowRight class="w-3.5 h-3.5" /></a>
			</div>
			<div class="home-grid">
				{#each newArrivals as product}
					<div class="product-card">
						<a href={`/products/${product.id}`} class="product-img-wrap border-none outline-none text-left w-full cursor-pointer p-0 bg-transparent block">
							{#if product.image_url}<img src={product.image_url} alt={product.name} class="product-img" />{:else}<div class="product-img-placeholder"><ShoppingCart /></div>{/if}
							<span class="badge badge-new">New</span>
							{#if !product.is_available}<div class="product-sold-out"><span>Sold Out</span></div>{/if}
						</a>
						<div class="product-info">
							<div class="product-category">{product.category?.name || (product as any).category_name || 'PRODUCT'}</div>
							<a href={`/products/${product.id}`} class="product-name border-none bg-transparent outline-none p-0 text-left w-full cursor-pointer">{product.name}</a>
								<div class="product-bottom-row">
									<span class="price-current font-black text-lg">₦{(product.sale_price > 0 ? product.sale_price : product.price)?.toLocaleString()}</span>
									<div class="product-actions-flex">
										<button class="action-icon-btn action-rx" onclick={(e) => { e.preventDefault(); handleRxChat(e, undefined, product.id); }} title="RX Chat"><MessageSquare class="w-4 h-4" /></button>
										{#if product.is_available && product.stock_quantity > 0}<button class="action-icon-btn action-bag" onclick={(e) => { e.preventDefault(); e.stopPropagation(); addToCart(product); }} title="Add to Bag"><ShoppingCart class="w-4 h-4" /></button>{/if}
									</div>
								</div>
						</div>
					</div>
				{/each}
			</div>
		</section>
		{/if}

		<!-- ═══════════ SHOP ALL CTA ═══════════ -->
		<div class="shop-all-wrap">
			<a href="/products" class="shop-all-btn">Browse All Products <ArrowRight class="w-4 h-4" /></a>
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

<!-- Toast Notification -->
{#if showToast}
	<div class="cart-toast">
		<CheckCircle2 class="toast-check" />
		<div class="toast-text">
			<span class="toast-title">Added to Bag</span>
			<span class="toast-product">{toastProduct}</span>
		</div>
		<a href="/cart" class="toast-link">View Bag</a>
	</div>
{/if}

<style>
	/* ─── NEW HOMEPAGE SECTIONS ─── */
	.hero-cta-row { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }
	.hero-cta {
		display: inline-flex; align-items: center; gap: 8px;
		background: var(--accent, #4f46e5); color: #fff;
		padding: 14px 32px; border-radius: 8px; border: none; cursor: pointer;
		font-size: 12px; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase;
		text-decoration: none; box-shadow: 0 4px 20px rgba(0,0,0,0.2);
		transition: transform 0.15s, box-shadow 0.15s;
	}
	.hero-cta:active { transform: scale(0.97); }
	.hero-cta :global(.cta-arrow) { width: 14px; height: 14px; }
	.hero-cta-ghost { background: rgba(255,255,255,0.12); border: 1px solid rgba(255,255,255,0.3); backdrop-filter: blur(8px); }

	.home-section { max-width: 1280px; margin: 0 auto; padding: 3rem 1.5rem 1rem; }
	.section-header { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 1.75rem; }
	.section-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.15em; color: var(--accent, #4f46e5); margin-bottom: 4px; }
	.section-title { font-size: 1.5rem; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; line-height: 1; }
	.see-all { display: inline-flex; align-items: center; gap: 4px; font-size: 12px; font-weight: 700; color: #64748b; text-decoration: none; white-space: nowrap; transition: color 0.15s; }
	.see-all:hover { color: #0f172a; }

	.home-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
	@media (min-width: 640px) { .home-grid { grid-template-columns: repeat(3, 1fr); } }
	@media (min-width: 1024px) { .home-grid { grid-template-columns: repeat(4, 1fr); gap: 1.25rem; } }

	/* Pharmacist CTA Banner */
	.rx-banner { background: linear-gradient(135deg, #0b1a30 0%, #1a2f5a 100%); margin: 2rem 0; }
	.rx-banner-inner {
		max-width: 1280px; margin: 0 auto; padding: 2.5rem 1.5rem;
		display: flex; flex-wrap: wrap; align-items: center; gap: 1.5rem;
	}
	.rx-icon-wrap { width: 56px; height: 56px; background: rgba(255,255,255,0.1); border-radius: 16px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
	.rx-icon { width: 28px; height: 28px; color: #fff; }
	.rx-copy { flex: 1; min-width: 200px; }
	.rx-title { font-size: 1.125rem; font-weight: 800; color: #fff; margin-bottom: 4px; }
	.rx-sub { font-size: 13px; color: rgba(255,255,255,0.65); line-height: 1.5; }
	.rx-cta {
		display: inline-flex; align-items: center; gap: 8px; flex-shrink: 0;
		background: #fff; color: #0b1a30;
		padding: 12px 24px; border-radius: 10px; border: none; cursor: pointer;
		font-size: 13px; font-weight: 800; transition: opacity 0.15s;
	}
	.rx-cta:hover { opacity: 0.92; }

	/* Shop All */
	.shop-all-wrap { display: flex; justify-content: center; padding: 1rem 1.5rem 3rem; }
	.shop-all-btn {
		display: inline-flex; align-items: center; gap: 10px;
		padding: 14px 36px; border-radius: 12px;
		border: 2px solid #0f172a; color: #0f172a; background: transparent;
		font-size: 13px; font-weight: 800; text-decoration: none; text-transform: uppercase; letter-spacing: 0.06em;
		transition: all 0.2s;
	}
	.shop-all-btn:hover { background: #0f172a; color: #fff; }

	/* New badge */
	.badge-new { top: 10px; left: 10px; background: #10b981; color: #fff; }

	.empty-title { font-size: 14px; font-weight: 700; color: #0f172a; }

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
		height: 400px;
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding: 2rem;
		overflow: hidden;
	}
	@media (min-width: 768px) { .hero-section { height: 400px; padding: 4rem; } }

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
		display: flex; flex-direction: column; 
		border: 1px solid #f1f5f9; border-radius: 16px;
		background: #fff; overflow: hidden;
		transition: transform 0.2s, box-shadow 0.2s;
	}
	.product-card:hover { transform: translateY(-4px); box-shadow: 0 12px 24px rgba(0,0,0,0.06); }

	.product-img-wrap {
		position: relative; height: 200px; width: 100%;
		background: #f8fafc;
		display: block;
	}
	.product-img {
		width: 100%; height: 100%; object-fit: cover;
		transition: transform 0.5s ease;
	}
	.product-card:hover .product-img { transform: scale(1.02); }

	.product-img-placeholder {
		width: 100%; height: 100%;
		display: flex; align-items: center; justify-content: center;
		color: #cbd5e1;
	}
	.product-img-placeholder :global(svg) { width: 40px; height: 40px; }

	.badge { 
		position: absolute;
		padding: 3px 10px; border-radius: 4px;
		font-size: 9px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase;
		z-index: 5;
	}
	.badge-discount { top: 1rem; left: 1rem; background: var(--brand); color: #fff; }

	.product-sold-out { 
		position: absolute; inset: 0; background: rgba(255,255,255,0.8); 
		display: flex; align-items: center; justify-content: center; z-index: 20;
	}
	.product-sold-out span {
		background: #0f172a; color: #fff;
		padding: 6px 16px; border-radius: 8px;
		font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em;
	}

	/* Product Info */
	.product-info { padding: 16px; flex: 1; display: flex; flex-direction: column; }

	.product-category { 
		font-size: 10px; font-weight: 800; color: #1d4ed8; text-transform: uppercase; 
		letter-spacing: 0.05em; margin-bottom: 4px; display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden;
	}

	.product-name {
		font-size: 16px; font-weight: 700; color: #0f172a; text-decoration: none; 
		display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
		margin-bottom: 2px;
	}
	.product-name:hover { text-decoration: underline; }

	.product-generic { 
		font-size: 12px; font-weight: 600; color: #475569; margin-bottom: 6px; 
		display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden;
	}

	.product-desc {
		font-size: 11px; color: #64748b; margin-bottom: 16px; line-height: 1.4; 
		display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
	}

	.product-bottom-row { display: flex; align-items: center; justify-content: space-between; margin-top: auto; }
	.product-price { color: #0f172a; }
	
	.product-actions-flex { display: flex; gap: 8px; }
	.action-icon-btn { 
		width: 36px; height: 36px; border-radius: 8px; border: none; cursor: pointer; 
		display: flex; align-items: center; justify-content: center; transition: all 0.2s;
	}
	.action-rx { background: #eff6ff; color: #1d4ed8; }
	.action-rx:hover { background: #dbeafe; }
	.action-bag { background: #0b2559; color: #ffffff; }
	.action-bag:hover { background: #0f357f; }

	/* Toast */
	.cart-toast {
		position: fixed;
		bottom: 2rem; left: 50%; transform: translateX(-50%);
		z-index: 200;
		display: flex; align-items: center; gap: 12px;
		background: var(--on-surface); color: #fff;
		padding: 14px 24px; border-radius: 12px;
		box-shadow: 0 20px 60px rgba(0,0,0,0.25);
		animation: toastIn 0.35s cubic-bezier(0.16, 1, 0.3, 1);
		font-size: 12px;
	}
	.cart-toast :global(.toast-check) { width: 18px; height: 18px; color: #34d399; flex-shrink: 0; }
	.toast-text { display: flex; flex-direction: column; gap: 1px; }
	.toast-title { font-weight: 700; font-size: 11px; letter-spacing: 0.05em; text-transform: uppercase; }
	.toast-product { font-size: 10px; opacity: 0.7; max-width: 160px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
	.toast-link {
		margin-left: 8px; padding: 6px 14px; border-radius: 6px;
		background: rgba(255,255,255,0.15); color: #fff;
		font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em;
		text-decoration: none; white-space: nowrap;
		transition: background 0.15s;
	}
	.toast-link:hover { background: rgba(255,255,255,0.25); }

	@keyframes toastIn {
		from { opacity: 0; transform: translateX(-50%) translateY(20px); }
		to { opacity: 1; transform: translateX(-50%) translateY(0); }
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

	/* ─── MODAL STYLES ─── */
	.modal-backdrop {
		position: fixed; inset: 0; background: rgba(0,0,0,0.6); backdrop-filter: blur(4px);
		display: flex; align-items: center; justify-content: center; z-index: 1100; padding: 1rem;
	}
	.modal-content {
		background: white; width: 100%; max-width: 760px; height: 90vh; border-radius: 1.5rem;
		position: relative; overflow: hidden; display: flex; flex-direction: column; text-align: left;
	}
	.modal-close {
		position: absolute; top: 0.75rem; right: 0.75rem; width: 32px; height: 32px;
		border-radius: 50%; background: white; display: flex; align-items: center; justify-content: center;
		box-shadow: 0 4px 10px rgba(0,0,0,0.12); z-index: 10; flex-shrink: 0; border: none; cursor: pointer; color: var(--on-surface);
	}
	.modal-body { display: grid; grid-template-columns: 1fr; flex: 1; overflow: hidden; height: 100%; }
	@media (min-width: 640px) { .modal-body { grid-template-columns: 1fr 1.2fr; } }
	
	.modal-img { background: #f8fafc; display: flex; align-items: center; justify-content: center; padding: 1.25rem; min-height: 160px; max-height: 220px; }
	@media (min-width: 640px) { .modal-img { max-height: 100%; } }
	.modal-img img { width: 100%; max-height: 300px; object-fit: contain; }
	.m-ph { color: #cbd5e1; opacity: 0.5; }
	
	.modal-info { padding: 1.25rem 1.75rem; display: flex; flex-direction: column; overflow-y: auto; }
	.m-header { margin-bottom: 0.875rem; }
	.m-cat { font-size: 0.65rem; font-weight: 800; color: #1d4ed8; text-transform: uppercase; letter-spacing: 0.1em; display: block; margin-bottom: 0.25rem; }
	.m-header h2 { font-family: var(--font-display); font-size: 1.35rem; font-weight: 800; color: #0f172a; line-height: 1.2; margin-bottom: 0.25rem; }
	.m-generic { font-size: 0.75rem; color: #475569; }

	.m-details { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; margin-bottom: 0.875rem; padding: 0.875rem; background: #f8fafc; border-radius: 0.875rem; }
	.m-detail { display: flex; flex-direction: column; gap: 0.15rem; }
	.m-detail .label { font-size: 0.6rem; font-weight: 700; color: #64748b; text-transform: uppercase; }
	.m-detail .val { font-size: 0.8rem; font-weight: 700; color: #0f172a; }

	.m-desc { font-size: 0.8125rem; color: #475569; line-height: 1.55; margin-bottom: 1rem; flex: 1; }

	.m-footer { display: flex; align-items: center; justify-content: space-between; gap: 0.875rem; padding-top: 0.875rem; border-top: 1px solid var(--border); flex-wrap: wrap; }
	.m-price-section { display: flex; flex-direction: column; min-width: 80px; }
	.m-price { font-size: 1.25rem; font-weight: 900; color: #0f172a; }
	.m-stock { font-size: 0.6rem; font-weight: 600; color: #64748b; }
	
	.m-qty-selector { display: flex; align-items: center; gap: 0.625rem; background: #f8fafc; padding: 0.375rem; border-radius: 0.625rem; border: 1px solid var(--border); }
	.m-qty-selector button { width: 28px; height: 28px; border-radius: 0.4rem; background: white; border: 1px solid var(--border); display: flex; align-items: center; justify-content: center; color: #0f172a; transition: all 0.2s; cursor: pointer; }
	.m-qty-selector button:hover { background: #0b1a30; color: white; }
	.m-qty-selector span { font-weight: 800; font-size: 0.9rem; min-width: 18px; text-align: center; }

	.m-add-btn { flex: 1; min-width: 120px; padding: 0.7rem 1rem; border-radius: 0.75rem; color: white; font-weight: 700; font-size: 0.875rem; border: none; cursor: pointer; box-shadow: 0 6px 15px -3px rgba(0,0,0,0.1); transition: opacity 0.2s; }
	.m-add-btn:hover { opacity: 0.9; }

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
