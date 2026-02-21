<script lang="ts">
    import ProductSearch from '$lib/components/ProductSearch.svelte';
    import type { PlanTier } from '$lib/types/supabase.js';

    // Example configuration - in a real app, these would come from stores or props
    let branchId = 'branch-123';
    let tenantId = 'tenant-123';
    let planTier: PlanTier = 'pro';
    let branches = [
        { id: 'branch-1', name: 'Main Store' },
        { id: 'branch-2', name: 'Mall Branch' },
        { id: 'branch-3', name: 'Online Store' }
    ];

    function handleProductClick(event: CustomEvent) {
        const { product } = event.detail;
        console.log('Product clicked:', product);
        // In a real app: goto(`/products/${product.id}`)
    }

    function handleAddToCart(event: CustomEvent) {
        const { product, quantity, variantId } = event.detail;
        console.log('Add to cart:', { product: product.name, quantity, variantId });
        // In a real app: cartStore.addItem(product, quantity, variantId)
        // Show success toast
    }

    function handleQuickView(event: CustomEvent) {
        const { product } = event.detail;
        console.log('Quick view:', product);
        // In a real app: quickViewModal.show(product)
    }

    function handleUpgradePrompt(event: CustomEvent) {
        const { feature } = event.detail;
        console.log('Upgrade needed for:', feature);
        // In a real app: upgradeModal.show(feature)
    }

    function handleError(event: CustomEvent) {
        console.error('Search error:', event.detail.message);
        // In a real app: toast.error(event.detail.message)
    }
</script>

<svelte:head>
    <title>Storefront - Product Search</title>
    <meta name="description" content="Browse and search products in our online store" />
</svelte:head>

<div class="min-h-screen bg-background">
    <!-- Header -->
    <header class="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div class="container mx-auto px-4 py-4">
            <div class="flex items-center justify-between">
                <h1 class="text-2xl font-bold text-foreground">
                    Storefront Demo
                </h1>
                <div class="flex items-center gap-4">
                    <span class="text-sm text-muted-foreground">
                        Plan: <span class="font-medium capitalize">{planTier}</span>
                    </span>
                    <div class="h-8 w-8 rounded-full bg-primary flex items-center justify-center">
                        <svg class="w-4 h-4 text-primary-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                        </svg>
                    </div>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="container mx-auto px-4 py-6">
        <div class="mb-6">
            <h2 class="text-xl font-semibold text-foreground mb-2">
                Product Search & Browse
            </h2>
            <p class="text-muted-foreground">
                Search and filter products with advanced features based on your plan tier.
            </p>
        </div>

        <!-- Product Search Component -->
        <div class="bg-card border rounded-lg overflow-hidden shadow-sm">
            <ProductSearch
                {branchId}
                {tenantId}
                {planTier}
                {branches}
                initialQuery=""
                showAddToCart={true}
                on:product-click={handleProductClick}
                on:add-to-cart={handleAddToCart}
                on:quick-view={handleQuickView}
                on:upgrade-prompt={handleUpgradePrompt}
                on:error={handleError}
            />
        </div>
    </main>

    <!-- Footer -->
    <footer class="border-t bg-muted/50 mt-12">
        <div class="container mx-auto px-4 py-6">
            <div class="text-center text-sm text-muted-foreground">
                <p>Storefront Demo - Product Search & Filtering</p>
                <p class="mt-1">
                    Features: Search, Filters, Plan-based Access, Mobile Responsive
                </p>
            </div>
        </div>
    </footer>
</div>

<style>
    :global(html) {
        scroll-behavior: smooth;
    }
</style>