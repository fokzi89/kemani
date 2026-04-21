<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ShoppingCart, Heart, Share2, Plus, Minus, ArrowLeft, 
		ShieldCheck, Clock, Truck, Star, CheckCircle2, ChevronRight, Tag, ArrowRight, Stethoscope
	} from 'lucide-svelte';
	import { isAuthenticated } from '$lib/stores/auth';
	import { isAuthModalOpen } from '$lib/stores/ui';

	export let data;

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
		window.dispatchEvent(new Event('cart-updated'));
		goto(`/cart`);
	}

	function handleRxChat() {
		if (!$isAuthenticated) {
			localStorage.setItem('pending_chat_redirect', '/chat');
			isAuthModalOpen.set(true);
			return;
		}
		goto('/chat');
	}
</script>

<svelte:head>
	<title>{product?.name} | {storefront?.name}</title>
	<meta name="description" content={product?.description} />
</svelte:head>

<div class="product-page">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-16">
		
		<!-- Breadcrumbs (Minimalist) -->
		<nav class="breadcrumb">
			<a href="/">Catalog</a>
			<span class="sep">/</span>
			<span class="current">{product?.category}</span>
		</nav>

		{#if product}
			<div class="product-main">
				
				<!-- Product Media (Editorial focus) -->
				<div class="media-column">
					<div class="main-image-wrap">
						{#if product.image_url}
							<img 
								src={product.image_url} 
								alt={product.name} 
								class="main-image" 
							/>
						{:else}
							<div class="image-placeholder">
								<ShoppingCart class="h-16 w-16" />
								<span>Image Coming Soon</span>
							</div>
						{/if}
						
						{#if product.percentage_discount}
							<span class="discount-badge">{product.percentage_discount}% OFF</span>
						{/if}
					</div>
					
					<div class="thumbnail-grid">
						{#each Array(4) as _}
							<div class="thumbnail-wrap">
								{#if product.image_url}
									<img src={product.image_url} alt="Thumbnail" class="thumbnail-img" />
								{:else}
									<div class="thumbnail-placeholder"><ShoppingCart class="w-4 h-4" /></div>
								{/if}
							</div>
						{/each}
					</div>
				</div>

				<!-- Product Content -->
				<div class="content-column">
					<header class="product-header">
						<div class="product-meta">
							<span class="category-tag">{product.category}</span>
							<div class="rating">
								<Star class="star-filled" />
								<span class="rating-text">4.8</span>
							</div>
						</div>
						
						<h1 class="product-title">{product.name}</h1>
						<div class="product-sku">REF: {product.sku || 'KMN-992-UX'}</div>
					</header>

					<div class="price-section">
						<div class="price-row">
							<span class="current-price">₦{product.sale_price ? product.sale_price.toLocaleString() : product.price.toLocaleString()}</span>
							{#if product.sale_price}
								<span class="old-price">₦{product.selling_price?.toLocaleString()}</span>
							{/if}
						</div>
						<div class="stock-status {product.stock_quantity > 0 ? 'in-stock' : 'out-of-stock'}">
							<div class="status-dot"></div>
							{product.stock_quantity > 0 ? 'Verified In Stock & Ready' : 'Out of Stock'}
						</div>
					</div>

					<div class="description-section">
						<h3 class="section-label">The Details</h3>
						{#if product.description}
							<p class="description-text">{product.description}</p>
						{/if}
						
						{#if product.product_details}
							<div class="technical-details">
								<p>{product.product_details}</p>
							</div>
						{/if}

						{#if product.category?.toLowerCase() === 'drug'}
							<div class="drug-specs">
								{#if product.generic_name}
									<div class="spec-item">
										<span class="spec-label">Generic Name</span>
										<span class="spec-val">{product.generic_name}</span>
									</div>
								{/if}
								{#if product.strength}
									<div class="spec-item">
										<span class="spec-label">Strength</span>
										<span class="spec-val">{product.strength}</span>
									</div>
								{/if}
							</div>
						{/if}
					</div>

					<!-- Selection & Actions -->
					<div class="action-box">
						{#if product.is_available && product.stock_quantity > 0}
							<div class="quantity-selector">
								<span class="label">Quantity</span>
								<select bind:value={quantity} class="qty-select">
									{#each Array(Math.min(30, product.stock_quantity)) as _, i}
										<option value={i+1}>{i+1}</option>
									{/each}
								</select>
							</div>

							<div class="action-buttons">
								<button onclick={addToCart} class="btn-primary">
									Add to Bag <ArrowRight class="btn-icon" />
								</button>
								<button onclick={handleRxChat} class="btn-consult">
									<Stethoscope class="btn-icon" />
									Consult with Pharmacist
								</button>
								<button onclick={addToCart} class="btn-secondary">
									Buy It Now
								</button>
							</div>
						{:else}
							<div class="unavailable-status">Currently Unavailable</div>
						{/if}
					</div>

					<!-- Trust Icons -->
					<div class="trust-grid">
						<div class="trust-item">
							<Truck class="trust-icon" />
							<div>
								<p class="trust-title">Logistics</p>
								<p class="trust-sub">Express Dispatch</p>
							</div>
						</div>
						<div class="trust-item">
							<ShieldCheck class="trust-icon" />
							<div>
								<p class="trust-title">Verified</p>
								<p class="trust-sub">Certified Quality</p>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Related Products (Luxury Grid) -->
			<div class="related-section">
				<div class="section-header">
					<h2 class="section-title">The Collection</h2>
					<a href="/" class="view-all">See All Collections</a>
				</div>

				{#if relatedProducts.length > 0}
					<div class="related-grid">
						{#each relatedProducts as rel}
							<a href={`/products/${rel.id}`} class="related-card">
								<div class="related-img-wrap">
									{#if rel.image_url}
										<img src={rel.image_url} alt={rel.name} class="related-img" />
									{:else}
										<div class="related-placeholder"><ShoppingCart class="w-8 h-8" /></div>
									{/if}
								</div>
								<div class="related-info">
									<h3 class="related-name">{rel.name}</h3>
									<div class="related-price">₦{rel.price.toLocaleString()}</div>
								</div>
							</a>
						{/each}
					</div>
				{:else}
					<div class="empty-related">
						<p>No other items available in this series.</p>
					</div>
				{/if}
			</div>
		{/if}
	</div>
</div>

<style>
	/* ─── TOKENS ─── */
	:root {
		--font-display: 'Playfair Display', Georgia, serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #faf9f6;
		--on-surface: #1a1c1a;
		--on-surface-muted: #6b7280;
		--border: #e5e5e0;
		--accent: #785a1a; /* Gold/Brown Luxury Accent */
		--radius: 8px;
	}

	.product-page {
		background: var(--surface);
		color: var(--on-surface);
		font-family: var(--font-body);
		min-height: 100vh;
	}

	/* ─── BREADCRUMB ─── */
	.breadcrumb {
		display: flex; align-items: center; gap: 8px;
		font-size: 10px; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase;
		color: var(--on-surface-muted);
		margin-bottom: 2rem;
	}
	.breadcrumb a:hover { color: var(--on-surface); }
	.breadcrumb .sep { opacity: 0.4; }
	.breadcrumb .current { color: var(--on-surface); }

	/* ─── LAYOUT ─── */
	.product-main {
		display: grid;
		grid-template-columns: 1fr;
		gap: 3rem;
		align-items: start;
	}
	@media (min-width: 1024px) {
		.product-main { grid-template-columns: 1.2fr 1fr; gap: 5rem; }
	}

	/* ─── MEDIA COLUMN ─── */
	.media-column { position: sticky; top: 120px; }
	.main-image-wrap {
		position: relative;
		aspect-ratio: 1;
		background: #fff;
		border-radius: var(--radius);
		border: 1px solid var(--border);
		overflow: hidden;
		display: flex; align-items: center; justify-content: center;
		padding: 2rem;
	}
	.main-image { width: 100%; height: 100%; object-fit: contain; transition: transform 0.6s ease; }
	.main-image-wrap:hover .main-image { transform: scale(1.05); }

	.discount-badge {
		position: absolute; top: 1rem; left: 1rem;
		background: #059669; color: #fff;
		padding: 4px 12px; border-radius: 4px;
		font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
	}

	.image-placeholder { display: flex; flex-direction: column; align-items: center; color: #d1d5db; font-size: 10px; font-weight: 600; text-transform: uppercase; gap: 1rem; }

	.thumbnail-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin-top: 1rem; }
	.thumbnail-wrap { aspect-ratio: 1; border: 1px solid var(--border); border-radius: 4px; background: #fff; overflow: hidden; cursor: pointer; transition: border-color 0.2s; }
	.thumbnail-wrap:hover { border-color: var(--on-surface); }
	.thumbnail-img { width: 100%; height: 100%; object-fit: contain; opacity: 0.6; }
	.thumbnail-wrap:hover .thumbnail-img { opacity: 1; }
	.thumbnail-placeholder { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; color: #f3f4f6; }

	/* ─── CONTENT COLUMN ─── */
	.content-column { display: flex; flex-direction: column; gap: 2rem; }

	.product-meta { display: flex; align-items: center; gap: 12px; margin-bottom: 0.5rem; }
	.category-tag { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--accent); }
	.rating { display: flex; align-items: center; gap: 4px; }
	.star-filled { width: 12px; height: 12px; color: #f59e0b; fill: #f59e0b; }
	.rating-text { font-size: 11px; font-weight: 600; }

	.product-title {
		font-family: var(--font-display);
		font-size: 2.25rem; font-weight: 500;
		line-height: 1.1; margin-bottom: 0.5rem;
	}
	.product-sku { font-size: 10px; color: var(--on-surface-muted); letter-spacing: 0.05em; }

	.price-row { display: flex; align-items: baseline; gap: 12px; }
	.current-price { font-size: 1.75rem; font-weight: 600; }
	.old-price { font-size: 1rem; color: var(--on-surface-muted); text-decoration: line-through; }

	.stock-status { display: flex; align-items: center; gap: 8px; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
	.status-dot { width: 6px; height: 6px; border-radius: 50%; }
	.in-stock { color: #059669; }
	.in-stock .status-dot { background: #059669; box-shadow: 0 0 0 4px rgba(5, 150, 105, 0.1); }
	.out-of-stock { color: #ef4444; }
	.out-of-stock .status-dot { background: #ef4444; }

	.section-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 1rem; color: var(--on-surface-muted); }
	.description-text { font-size: 14px; line-height: 1.7; color: var(--on-surface-muted); }
	.technical-details { margin-top: 1rem; padding: 1rem; background: rgba(0,0,0,0.02); border-radius: 8px; font-size: 13px; color: var(--on-surface); line-height: 1.6; }

	.drug-specs { margin-top: 1.5rem; display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
	.spec-item { display: flex; flex-direction: column; gap: 2px; }
	.spec-label { font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: var(--on-surface-muted); }
	.spec-val { font-size: 13px; font-weight: 600; }

	/* ─── ACTION BOX ─── */
	.action-box { 
		padding: 2rem; background: #fff; 
		border: 1px solid var(--border); border-radius: var(--radius);
		display: flex; flex-direction: column; gap: 1.5rem;
	}
	.quantity-selector { display: flex; items-center: center; justify-content: space-between; padding-bottom: 1rem; border-bottom: 1px solid var(--border); }
	.quantity-selector .label { font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
	.qty-select { border: none; background: none; font-size: 14px; font-weight: 600; outline: none; cursor: pointer; }

	.action-buttons { display: flex; flex-direction: column; gap: 0.75rem; }
	.btn-primary {
		width: 100%; padding: 16px; border: none; border-radius: 6px;
		background: var(--on-surface); color: #fff;
		font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.15em;
		display: flex; align-items: center; justify-content: center; gap: 8px;
		cursor: pointer; transition: transform 0.2s, background 0.2s;
	}
	.btn-primary:hover { background: #000; transform: translateY(-1px); }
	.btn-icon { width: 14px; height: 14px; }
	
	.btn-secondary:hover { border-color: var(--on-surface); }

	.btn-consult {
		width: 100%; padding: 16px; border: 1px solid #059669; border-radius: 6px;
		background: #ecfdf5; color: #059669;
		font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.15em;
		display: flex; align-items: center; justify-content: center; gap: 8px;
		cursor: pointer; transition: background 0.2s;
	}
	.btn-consult:hover { background: #d1fae5; }

	.unavailable-status { text-align: center; font-size: 12px; font-weight: 600; color: #ef4444; text-transform: uppercase; padding: 1rem; border: 1px dashed #ef4444; border-radius: 8px; }

	/* Trust Grid */
	.trust-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
	.trust-item { display: flex; align-items: center; gap: 12px; padding: 1rem; background: #fff; border: 1px solid var(--border); border-radius: 8px; }
	.trust-icon { width: 20px; height: 20px; color: var(--accent); }
	.trust-title { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; }
	.trust-sub { font-size: 10px; color: var(--on-surface-muted); }

	/* ─── RELATED SECTION ─── */
	.related-section { margin-top: 5rem; padding-top: 3rem; border-top: 1px solid var(--border); }
	.section-header { display: flex; align-items: baseline; justify-content: space-between; margin-bottom: 2rem; }
	.section-title { font-family: var(--font-display); font-size: 1.75rem; font-weight: 500; }
	.view-all { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--accent); border-bottom: 1px solid var(--accent); padding-bottom: 2px; }

	.related-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; }
	@media (min-width: 768px) { .related-grid { grid-template-columns: repeat(4, 1fr); } }

	.related-card { display: block; group-decoration: none; }
	.related-img-wrap { aspect-ratio: 3/4; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden; display: flex; align-items: center; justify-content: center; margin-bottom: 1rem; }
	.related-img { width: 100%; height: 100%; object-fit: contain; transition: transform 0.4s ease; }
	.related-card:hover .related-img { transform: scale(1.05); }
	.related-info { display: flex; flex-direction: column; gap: 4px; }
	.related-name { font-family: var(--font-display); font-size: 15px; font-weight: 500; color: var(--on-surface); }
	.related-price { font-size: 14px; font-weight: 600; color: var(--on-surface-muted); }
</style>
