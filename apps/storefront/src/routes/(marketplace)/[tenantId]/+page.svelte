<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import type { MarketplaceProduct, MarketplaceFilters } from '$lib/types/ecommerce';

	let tenantId = $page.params.tenantId;
	let products: MarketplaceProduct[] = [];
	let categories: Array<{ name: string; count: number }> = [];
	let storefront: any = null;
	let isLoading = true;
	let error = '';

	// Filters
	let selectedCategory = '';
	let searchQuery = '';
	let minPrice = '';
	let maxPrice = '';
	let sortBy = 'newest';
	let inStockOnly = true;
	let currentPage = 1;
	let totalPages = 1;

	// Cart (stored in localStorage)
	let cartItemCount = 0;

	onMount(async () => {
		await loadStorefront();
		await loadCategories();
		await loadProducts();
		updateCartCount();
	});

	async function loadStorefront() {
		try {
			// TODO: Implement storefront info API call
			storefront = {
				business_name: 'Loading...',
				description: '',
				is_accepting_orders: true
			};
		} catch (err: any) {
			console.error('Failed to load storefront:', err);
		}
	}

	async function loadCategories() {
		try {
			// TODO: Implement categories API call
			categories = [];
		} catch (err: any) {
			console.error('Failed to load categories:', err);
		}
	}

	async function loadProducts() {
		isLoading = true;
		error = '';

		try {
			const params = new URLSearchParams();
			if (selectedCategory) params.set('category', selectedCategory);
			if (searchQuery) params.set('search', searchQuery);
			if (minPrice) params.set('min_price', minPrice);
			if (maxPrice) params.set('max_price', maxPrice);
			if (inStockOnly) params.set('in_stock_only', 'true');
			params.set('sort_by', sortBy);
			params.set('page', currentPage.toString());
			params.set('limit', '24');

			const response = await fetch(`/api/marketplace/${tenantId}/products?${params}`);
			const data = await response.json();

			if (response.ok) {
				products = data.products || [];
				totalPages = data.pagination?.pages || 1;
			} else {
				error = data.error || 'Failed to load products';
			}
		} catch (err: any) {
			error = err.message || 'Failed to load products';
		} finally {
			isLoading = false;
		}
	}

	function updateCartCount() {
		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
		cartItemCount = cart.items.reduce((sum: number, item: any) => sum + item.quantity, 0);
	}

	function addToCart(product: MarketplaceProduct) {
		const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');

		const existingItem = cart.items.find((item: any) => item.product_id === product.id);

		if (existingItem) {
			existingItem.quantity += 1;
		} else {
			cart.items.push({
				product_id: product.id,
				product_name: product.name,
				product_image: product.image_url,
				price: product.price,
				quantity: 1,
				stock_available: product.stock_quantity
			});
		}

		localStorage.setItem('cart', JSON.stringify(cart));
		updateCartCount();
		alert(`${product.name} added to cart!`);
	}

	function handleSearch() {
		currentPage = 1;
		loadProducts();
	}

	function handleCategoryClick(category: string) {
		selectedCategory = category;
		currentPage = 1;
		loadProducts();
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadProducts();
		window.scrollTo({ top: 0, behavior: 'smooth' });
	}
</script>

<svelte:head>
	<title>{storefront?.business_name || 'Shop'} - Online Store</title>
	<meta name="description" content="Browse products from {storefront?.business_name || 'our store'}" />
</svelte:head>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm sticky top-0 z-50">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<div>
					<h1 class="text-2xl font-bold text-gray-900 dark:text-white">
						{storefront?.business_name || 'Shop'}
					</h1>
					{#if storefront?.description}
						<p class="text-sm text-gray-600 dark:text-gray-400">{storefront.description}</p>
					{/if}
				</div>
				<a
					href="/{tenantId}/cart"
					class="relative inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					<svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
					</svg>
					Cart
					{#if cartItemCount > 0}
						<span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs font-bold rounded-full h-6 w-6 flex items-center justify-center">
							{cartItemCount}
						</span>
					{/if}
				</a>
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<!-- Search and Filters -->
		<div class="mb-8 space-y-4">
			<!-- Search Bar -->
			<div class="flex gap-4">
				<input
					type="search"
					bind:value={searchQuery}
					on:keydown={(e) => e.key === 'Enter' && handleSearch()}
					placeholder="Search products..."
					class="flex-1 px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-emerald-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
				/>
				<button
					on:click={handleSearch}
					class="px-6 py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition"
				>
					Search
				</button>
			</div>

			<!-- Filter Controls -->
			<div class="flex flex-wrap gap-4 items-center">
				<div class="flex gap-2 items-center">
					<label class="text-sm text-gray-700 dark:text-gray-300">Sort:</label>
					<select
						bind:value={sortBy}
						on:change={() => loadProducts()}
						class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm"
					>
						<option value="newest">Newest</option>
						<option value="price_asc">Price: Low to High</option>
						<option value="price_desc">Price: High to Low</option>
						<option value="name">Name A-Z</option>
					</select>
				</div>

				<div class="flex gap-2 items-center">
					<input
						type="number"
						bind:value={minPrice}
						placeholder="Min ₦"
						class="w-24 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm"
					/>
					<span class="text-gray-500">-</span>
					<input
						type="number"
						bind:value={maxPrice}
						placeholder="Max ₦"
						class="w-24 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm"
					/>
					<button
						on:click={() => loadProducts()}
						class="px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition text-sm"
					>
						Apply
					</button>
				</div>

				<label class="flex items-center gap-2 cursor-pointer">
					<input
						type="checkbox"
						bind:checked={inStockOnly}
						on:change={() => loadProducts()}
						class="w-4 h-4 text-emerald-600 rounded focus:ring-emerald-500"
					/>
					<span class="text-sm text-gray-700 dark:text-gray-300">In Stock Only</span>
				</label>
			</div>

			<!-- Categories -->
			{#if categories.length > 0}
				<div class="flex gap-2 flex-wrap">
					<button
						on:click={() => handleCategoryClick('')}
						class="px-4 py-2 rounded-full text-sm {selectedCategory === ''
							? 'bg-emerald-600 text-white'
							: 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'} transition"
					>
						All
					</button>
					{#each categories as category}
						<button
							on:click={() => handleCategoryClick(category.name)}
							class="px-4 py-2 rounded-full text-sm {selectedCategory === category.name
								? 'bg-emerald-600 text-white'
								: 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'} transition"
						>
							{category.name} ({category.count})
						</button>
					{/each}
				</div>
			{/if}
		</div>

		<!-- Loading State -->
		{#if isLoading}
			<div class="text-center py-12">
				<div class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-gray-200 border-t-emerald-600"></div>
				<p class="mt-4 text-gray-600 dark:text-gray-400">Loading products...</p>
			</div>
		{:else if error}
			<div class="text-center py-12">
				<p class="text-red-600 dark:text-red-400">{error}</p>
			</div>
		{:else if products.length === 0}
			<div class="text-center py-12">
				<p class="text-gray-600 dark:text-gray-400">No products found</p>
			</div>
		{:else}
			<!-- Products Grid -->
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
				{#each products as product}
					<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-lg transition overflow-hidden">
						<a href="/{tenantId}/products/{product.id}">
							<div class="aspect-square bg-gray-200 dark:bg-gray-700 relative">
								{#if product.image_url}
									<img
										src={product.image_url}
										alt={product.name}
										class="w-full h-full object-cover"
									/>
								{:else}
									<div class="w-full h-full flex items-center justify-center text-gray-400">
										No Image
									</div>
								{/if}
								{#if !product.is_available}
									<div class="absolute top-2 right-2 bg-red-500 text-white text-xs px-2 py-1 rounded">
										Out of Stock
									</div>
								{/if}
							</div>
						</a>
						<div class="p-4">
							<a href="/{tenantId}/products/{product.id}">
								<h3 class="font-semibold text-gray-900 dark:text-white mb-1 hover:text-emerald-600 dark:hover:text-emerald-400">
									{product.name}
								</h3>
							</a>
							{#if product.category}
								<p class="text-xs text-gray-500 dark:text-gray-400 mb-2">{product.category}</p>
							{/if}
							<div class="flex items-center justify-between">
								<p class="text-lg font-bold text-emerald-600 dark:text-emerald-400">
									₦{product.price.toLocaleString()}
								</p>
								{#if product.is_available}
									<button
										on:click={() => addToCart(product)}
										class="px-4 py-2 bg-emerald-600 text-white text-sm rounded-lg hover:bg-emerald-700 transition"
									>
										Add to Cart
									</button>
								{:else}
									<button
										disabled
										class="px-4 py-2 bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 text-sm rounded-lg cursor-not-allowed"
									>
										Out of Stock
									</button>
								{/if}
							</div>
						</div>
					</div>
				{/each}
			</div>

			<!-- Pagination -->
			{#if totalPages > 1}
				<div class="mt-8 flex justify-center gap-2">
					<button
						on:click={() => handlePageChange(currentPage - 1)}
						disabled={currentPage === 1}
						class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 dark:hover:bg-gray-700 transition text-gray-700 dark:text-gray-300"
					>
						Previous
					</button>

					{#each Array(totalPages) as _, i}
						{#if i + 1 === 1 || i + 1 === totalPages || Math.abs(i + 1 - currentPage) <= 2}
							<button
								on:click={() => handlePageChange(i + 1)}
								class="px-4 py-2 rounded-lg transition {currentPage === i + 1
									? 'bg-emerald-600 text-white'
									: 'border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'}"
							>
								{i + 1}
							</button>
						{:else if Math.abs(i + 1 - currentPage) === 3}
							<span class="px-2 py-2 text-gray-500">...</span>
						{/if}
					{/each}

					<button
						on:click={() => handlePageChange(currentPage + 1)}
						disabled={currentPage === totalPages}
						class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 dark:hover:bg-gray-700 transition text-gray-700 dark:text-gray-300"
					>
						Next
					</button>
				</div>
			{/if}
		{/if}
	</div>
</div>
