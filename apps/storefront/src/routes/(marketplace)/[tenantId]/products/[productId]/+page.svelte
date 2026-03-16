<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import type { MarketplaceProduct } from '$lib/types/ecommerce';

	let tenantId = $page.params.tenantId;
	let productId = $page.params.productId;

	let product: MarketplaceProduct | null = null;
	let relatedProducts: MarketplaceProduct[] = [];
	let quantity = 1;
	let isLoading = true;
	let error = '';

	onMount(async () => {
		await loadProduct();
		await loadRelatedProducts();
	});

	async function loadProduct() {
		isLoading = true;
		error = '';

		try {
			const response = await fetch(`/api/marketplace/${tenantId}/products/${productId}`);
			const data = await response.json();

			if (response.ok) {
				product = data.product;
			} else {
				error = data.error || 'Product not found';
			}
		} catch (err: any) {
			error = err.message || 'Failed to load product';
		} finally {
			isLoading = false;
		}
	}

	async function loadRelatedProducts() {
		try {
			// TODO: Implement related products API
			relatedProducts = [];
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
		alert(`${quantity} x ${product.name} added to cart!`);
		goto(`/${tenantId}/cart`);
	}

	function buyNow() {
		addToCart();
	}
</script>

<svelte:head>
	<title>{product?.name || 'Product'} - Shop</title>
	<meta name="description" content={product?.description || 'View product details'} />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<a href="/{tenantId}" class="text-emerald-600 dark:text-emerald-400 hover:underline">
					← Back to Shop
				</a>
				<a
					href="/{tenantId}/cart"
					class="inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					<svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
					</svg>
					View Cart
				</a>
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if isLoading}
			<div class="text-center py-12">
				<div class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-gray-200 border-t-emerald-600"></div>
				<p class="mt-4 text-gray-600 dark:text-gray-400">Loading product...</p>
			</div>
		{:else if error}
			<div class="text-center py-12">
				<p class="text-red-600 dark:text-red-400">{error}</p>
				<a href="/{tenantId}" class="mt-4 inline-block text-emerald-600 hover:underline">
					Return to shop
				</a>
			</div>
		{:else if product}
			<!-- Product Detail -->
			<div class="grid md:grid-cols-2 gap-8 mb-12">
				<!-- Product Image -->
				<div>
					<div class="aspect-square bg-gray-200 dark:bg-gray-700 rounded-lg overflow-hidden">
						{#if product.image_url}
							<img
								src={product.image_url}
								alt={product.name}
								class="w-full h-full object-cover"
							/>
						{:else}
							<div class="w-full h-full flex items-center justify-center text-gray-400">
								<div class="text-center">
									<svg class="w-24 h-24 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
									</svg>
									<p>No Image Available</p>
								</div>
							</div>
						{/if}
					</div>
				</div>

				<!-- Product Info -->
				<div>
					{#if product.category}
						<p class="text-sm text-gray-500 dark:text-gray-400 mb-2">{product.category}</p>
					{/if}

					<h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-4">
						{product.name}
					</h1>

					<div class="mb-6">
						<p class="text-4xl font-bold text-emerald-600 dark:text-emerald-400">
							₦{product.price.toLocaleString()}
						</p>
					</div>

					{#if product.description}
						<div class="mb-6">
							<h3 class="font-semibold text-gray-900 dark:text-white mb-2">Description</h3>
							<p class="text-gray-700 dark:text-gray-300 leading-relaxed">
								{product.description}
							</p>
						</div>
					{/if}

					<div class="mb-6">
						<p class="text-sm text-gray-600 dark:text-gray-400">
							SKU: <span class="font-mono">{product.sku}</span>
						</p>
						<p class="text-sm {product.is_available ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}">
							{#if product.is_available}
								In Stock ({product.stock_quantity} available)
							{:else}
								Out of Stock
							{/if}
						</p>
					</div>

					{#if product.is_available}
						<!-- Quantity Selector -->
						<div class="mb-6">
							<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
								Quantity
							</label>
							<div class="flex items-center gap-4">
								<button
									on:click={() => quantity = Math.max(1, quantity - 1)}
									class="w-10 h-10 rounded-lg border border-gray-300 dark:border-gray-600 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-700 transition"
								>
									-
								</button>
								<input
									type="number"
									bind:value={quantity}
									min="1"
									max={product.stock_quantity}
									class="w-20 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-center bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
								/>
								<button
									on:click={() => quantity = Math.min(product!.stock_quantity, quantity + 1)}
									class="w-10 h-10 rounded-lg border border-gray-300 dark:border-gray-600 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-700 transition"
								>
									+
								</button>
							</div>
						</div>

						<!-- Action Buttons -->
						<div class="flex gap-4">
							<button
								on:click={addToCart}
								class="flex-1 px-6 py-3 border-2 border-emerald-600 text-emerald-600 dark:text-emerald-400 font-semibold rounded-lg hover:bg-emerald-50 dark:hover:bg-emerald-900/20 transition"
							>
								Add to Cart
							</button>
							<button
								on:click={buyNow}
								class="flex-1 px-6 py-3 bg-emerald-600 text-white font-semibold rounded-lg hover:bg-emerald-700 transition"
							>
								Buy Now
							</button>
						</div>
					{:else}
						<div class="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
							<p class="text-red-800 dark:text-red-200 font-semibold">
								This product is currently out of stock
							</p>
						</div>
					{/if}
				</div>
			</div>

			<!-- Related Products -->
			{#if relatedProducts.length > 0}
				<div>
					<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">
						Related Products
					</h2>
					<div class="grid grid-cols-2 md:grid-cols-4 gap-4">
						{#each relatedProducts as relatedProduct}
							<a
								href="/{tenantId}/products/{relatedProduct.id}"
								class="bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-lg transition overflow-hidden"
							>
								<div class="aspect-square bg-gray-200 dark:bg-gray-700">
									{#if relatedProduct.image_url}
										<img
											src={relatedProduct.image_url}
											alt={relatedProduct.name}
											class="w-full h-full object-cover"
										/>
									{/if}
								</div>
								<div class="p-3">
									<h3 class="font-semibold text-sm text-gray-900 dark:text-white truncate">
										{relatedProduct.name}
									</h3>
									<p class="text-emerald-600 dark:text-emerald-400 font-bold mt-1">
										₦{relatedProduct.price.toLocaleString()}
									</p>
								</div>
							</a>
						{/each}
					</div>
				</div>
			{/if}
		{/if}
	</div>
</div>
