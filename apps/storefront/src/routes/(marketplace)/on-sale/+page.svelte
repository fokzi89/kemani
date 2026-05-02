<script lang="ts">
	import { ArrowLeft, ShoppingCart, Package, Tag, MessageSquare, CheckCircle2 } from 'lucide-svelte';
	import { cartStore } from '$lib/stores/cart.store';
	import { isChatOpen, chatProduct } from '$lib/stores/ui';

	export let data;

	$: products = data.products || [];
	$: storefront = data.storefront;

	// Toast
	let showToast = false;
	let toastProduct = '';
	let toastTimeout: any;

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

	function handleRxChat(e: MouseEvent, p?: any) {
		e.preventDefault();
		e.stopPropagation();
		if (p) {
			chatProduct.set({
				id: p.id,
				name: p.name,
				image: p.image_url,
				price: p.price
			});
		}
		isChatOpen.set(true);
	}
</script>

<svelte:head>
	<title>{data.title} — {storefront?.name || 'Store'}</title>
	<meta name="description" content={data.description} />
</svelte:head>

<div class="promotional-page">
	<header class="promo-header">
		<div class="container">
			<a href="/" class="back-link">
				<ArrowLeft class="w-4 h-4" /> Back to Home
			</a>
			<div class="title-wrap">
				<div class="icon-badge">
					<Tag class="w-6 h-6 text-rose-500" />
				</div>
				<div>
					<h1 class="page-title">{data.title}</h1>
					<p class="page-subtitle">{data.description}</p>
				</div>
			</div>
		</div>
	</header>

	<main class="container py-12">
		{#if products.length === 0}
			<div class="empty-state">
				<Package class="w-16 h-16 text-gray-200 mb-4" />
				<h3>No products on sale found</h3>
				<p>Stay tuned for our upcoming flash sales and discounts.</p>
				<a href="/products" class="btn-primary mt-6">Browse All Products</a>
			</div>
		{:else}
			<div class="product-grid">
				{#each products as product}
					<div class="product-card">
						<a href="/products/{product.id}" class="img-wrap">
							{#if product.image_url}
								<img src={product.image_url} alt={product.name} class="img" />
							{:else}
								<div class="img-ph"><Package class="w-10 h-10 text-gray-300" /></div>
							{/if}
							<span class="badge-sale">Limited Time</span>
							{#if !product.is_available}
								<div class="sold-out-overlay"><span>Sold Out</span></div>
							{/if}
						</a>
						<div class="card-body">
							<p class="card-cat">{product.category || 'Sale'}</p>
							<a href="/products/{product.id}" class="card-name">{product.name}</a>
							<div class="card-footer">
								<div class="price-stack">
									<span class="price-current text-rose-600">₦{product.price.toLocaleString()}</span>
									{#if product.selling_price && product.selling_price > product.price}
										<span class="price-old">₦{product.selling_price.toLocaleString()}</span>
									{/if}
								</div>
								<div class="actions">
									<button class="action-btn chat-btn" onclick={(e) => handleRxChat(e, product)} title="Ask Pharmacist">
										<MessageSquare class="w-4 h-4" />
									</button>
									{#if product.is_available && product.stock_quantity > 0}
										<button class="action-btn add-btn" onclick={() => addToCart(product)} title="Add to Bag">
											<ShoppingCart class="w-4 h-4" />
										</button>
									{/if}
								</div>
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</main>
</div>

{#if showToast}
	<div class="toast">
		<CheckCircle2 class="w-4 h-4 text-emerald-500" />
		<span><strong>{toastProduct}</strong> added to bag</span>
		<a href="/cart" class="toast-link">View Bag</a>
	</div>
{/if}

<style>
	.promotional-page { background: #faf9f6; min-height: 100vh; }
	.container { max-width: 1280px; margin: 0 auto; padding: 0 1.5rem; }
	
	.promo-header { background: #fff; border-bottom: 1px solid #f1f5f9; padding: 3rem 0; }
	.back-link { display: flex; align-items: center; gap: 8px; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; text-decoration: none; margin-bottom: 2rem; }
	.back-link:hover { color: #0f172a; }
	
	.title-wrap { display: flex; align-items: center; gap: 1.5rem; }
	.icon-badge { width: 64px; height: 64px; background: #fff1f2; border: 1px solid #fecdd3; border-radius: 20px; display: flex; align-items: center; justify-content: center; }
	.page-title { font-size: 2.5rem; font-weight: 900; color: #0f172a; letter-spacing: -0.03em; line-height: 1; }
	.page-subtitle { font-size: 1.125rem; color: #64748b; margin-top: 0.5rem; }
	
	.product-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; }
	@media (min-width: 768px) { .product-grid { grid-template-columns: repeat(3, 1fr); } }
	@media (min-width: 1024px) { .product-grid { grid-template-columns: repeat(4, 1fr); } }
	
	.product-card { background: #fff; border: 1px solid #f1f5f9; border-radius: 24px; overflow: hidden; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
	.product-card:hover { transform: translateY(-8px); box-shadow: 0 20px 40px rgba(0,0,0,0.08); border-color: #e2e8f0; }
	
	.img-wrap { display: block; position: relative; height: 240px; background: #f8fafc; overflow: hidden; }
	.img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s; }
	.product-card:hover .img { transform: scale(1.05); }
	.img-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; }
	
	.badge-sale { position: absolute; top: 1rem; left: 1rem; background: #ef4444; color: #fff; font-size: 11px; font-weight: 800; padding: 4px 10px; border-radius: 8px; text-transform: uppercase; }
	.sold-out-overlay { position: absolute; inset: 0; background: rgba(255,255,255,0.8); display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
	.sold-out-overlay span { background: #0f172a; color: #fff; font-size: 11px; font-weight: 800; padding: 6px 16px; border-radius: 10px; text-transform: uppercase; }
	
	.card-body { padding: 1.5rem; }
	.card-cat { font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; color: #94a3b8; margin-bottom: 6px; }
	.card-name { font-size: 15px; font-weight: 800; color: #0f172a; text-decoration: none; display: block; margin-bottom: 1.25rem; line-height: 1.4; height: 2.8em; overflow: hidden; }
	.card-name:hover { color: #4f46e5; }
	
	.card-footer { display: flex; align-items: flex-end; justify-content: space-between; gap: 1rem; }
	.price-stack { display: flex; flex-direction: column; }
	.price-current { font-size: 18px; font-weight: 900; }
	.price-old { font-size: 12px; color: #94a3b8; text-decoration: line-through; }
	
	.actions { display: flex; gap: 8px; }
	.action-btn { width: 42px; height: 42px; border-radius: 14px; border: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s; }
	.chat-btn { background: #f8fafc; color: #64748b; }
	.chat-btn:hover { background: #fff; border-color: #4f46e5; color: #4f46e5; }
	.add-btn { background: #ef4444; color: #fff; border: none; }
	.add-btn:hover { background: #dc2626; transform: scale(1.05); }
	
	.empty-state { padding: 8rem 0; text-align: center; }
	.empty-state h3 { font-size: 1.5rem; font-weight: 800; color: #0f172a; margin-bottom: 8px; }
	.empty-state p { color: #64748b; font-size: 1.125rem; }
	.btn-primary { display: inline-block; padding: 12px 32px; background: #0f172a; color: #fff; border-radius: 14px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; text-decoration: none; transition: all 0.2s; }
	.btn-primary:hover { background: #4f46e5; transform: translateY(-2px); box-shadow: 0 10px 20px rgba(79, 70, 229, 0.2); }

	.toast { position: fixed; bottom: 2rem; right: 2rem; z-index: 1000; background: #fff; border: 1px solid #f1f5f9; border-radius: 16px; padding: 16px 20px; display: flex; align-items: center; gap: 12px; box-shadow: 0 10px 40px rgba(0,0,0,0.12); font-size: 14px; animation: slideUp 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
	.toast-link { color: #4f46e5; font-weight: 800; text-decoration: none; border-bottom: 2px solid #e0e7ff; }
	@keyframes slideUp { from { transform: translateY(100%); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
</style>
