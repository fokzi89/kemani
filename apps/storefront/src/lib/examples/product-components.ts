/**
 * Example usage of Product Card and Grid components
 * This file demonstrates how to use the product display components
 */

import type { StorefrontProductWithCatalog } from '$lib/types/supabase.js';

// Sample product data for examples
export const sampleProducts: StorefrontProductWithCatalog[] = [
    {
        id: '1',
        tenant_id: 'tenant-1',
        branch_id: 'branch-1',
        catalog_product_id: 'catalog-1',
        name: 'Samsung Galaxy S24',
        description: 'Latest flagship smartphone with advanced camera and AI features',
        images: ['https://via.placeholder.com/400x400?text=Galaxy+S24'],
        primary_image: 'https://via.placeholder.com/400x400?text=Galaxy+S24',
        category: 'Electronics',
        brand: 'Samsung',
        barcode: '123456789',
        business_type: 'electronics',
        specifications: { storage: '256GB', ram: '8GB', color: 'Phantom Black' },
        sku: 'SAM-S24-256-BLK',
        price: 450000, // ₦450,000
        compare_at_price: 500000, // ₦500,000
        cost_price: 400000,
        stock_quantity: 15,
        low_stock_threshold: 5,
        is_available: true,
        has_variants: true,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
        synced_at: '2024-01-01T00:00:00Z'
    },
    {
        id: '2',
        tenant_id: 'tenant-1',
        branch_id: 'branch-1',
        catalog_product_id: 'catalog-2',
        name: 'Nike Air Max 270',
        description: 'Comfortable running shoes with Air Max technology',
        images: ['https://via.placeholder.com/400x400?text=Air+Max+270'],
        primary_image: 'https://via.placeholder.com/400x400?text=Air+Max+270',
        category: 'Fashion',
        brand: 'Nike',
        barcode: '987654321',
        business_type: 'fashion',
        specifications: { size: '42', color: 'White/Black' },
        sku: 'NIKE-AM270-42-WB',
        price: 85000, // ₦85,000
        compare_at_price: null,
        cost_price: 70000,
        stock_quantity: 3, // Low stock
        low_stock_threshold: 5,
        is_available: true,
        has_variants: true,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
        synced_at: '2024-01-01T00:00:00Z'
    },
    {
        id: '3',
        tenant_id: 'tenant-1',
        branch_id: 'branch-1',
        catalog_product_id: 'catalog-3',
        name: 'MacBook Pro 14"',
        description: 'Professional laptop with M3 chip for creative professionals',
        images: ['https://via.placeholder.com/400x400?text=MacBook+Pro'],
        primary_image: 'https://via.placeholder.com/400x400?text=MacBook+Pro',
        category: 'Electronics',
        brand: 'Apple',
        barcode: '456789123',
        business_type: 'electronics',
        specifications: { processor: 'M3', ram: '16GB', storage: '512GB' },
        sku: 'APPLE-MBP14-M3-512',
        price: 1200000, // ₦1,200,000
        compare_at_price: null,
        cost_price: 1100000,
        stock_quantity: 0, // Out of stock
        low_stock_threshold: 2,
        is_available: false,
        has_variants: false,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
        synced_at: '2024-01-01T00:00:00Z'
    }
];

// Example 1: Basic ProductCard usage
export const exampleProductCard = `
<script>
    import ProductCard from '$lib/components/ProductCard.svelte';
    
    let product = {
        // ... product data
    };
    
    function handleProductClick(event) {
        const { product } = event.detail;
        console.log('Product clicked:', product);
        // Navigate to product detail page
    }
    
    function handleAddToCart(event) {
        const { product, quantity, variantId } = event.detail;
        console.log('Add to cart:', { product, quantity, variantId });
        // Add product to cart
    }
    
    function handleQuickView(event) {
        const { product } = event.detail;
        console.log('Quick view:', product);
        // Show quick view modal
    }
</script>

<ProductCard
    {product}
    size="md"
    showAddToCart={true}
    showStock={true}
    showBrand={true}
    showCategory={false}
    imageAspectRatio="square"
    on:click={handleProductClick}
    on:add-to-cart={handleAddToCart}
    on:quick-view={handleQuickView}
/>
`;

// Example 2: ProductGrid usage
export const exampleProductGrid = `
<script>
    import ProductGrid from '$lib/components/ProductGrid.svelte';
    
    let products = []; // Array of products
    let loading = false;
    
    function handleProductClick(event) {
        console.log('Product clicked:', event.detail);
    }
    
    function handleAddToCart(event) {
        console.log('Add to cart:', event.detail);
    }
</script>

<ProductGrid
    {products}
    {loading}
    columns={4}
    gap="md"
    cardSize="md"
    showAddToCart={true}
    showStock={false}
    showBrand={true}
    showCategory={true}
    imageAspectRatio="square"
    emptyMessage="No products found"
    emptyDescription="Try adjusting your search or filters"
    on:product-click={handleProductClick}
    on:add-to-cart={handleAddToCart}
    on:quick-view={handleQuickView}
>
    <div slot="empty-action">
        <button class="btn-primary">Browse All Products</button>
    </div>
</ProductGrid>
`;

// Example 3: ProductList with view toggle
export const exampleProductList = `
<script>
    import ProductList from '$lib/components/ProductList.svelte';
    
    let products = [];
    let loading = false;
    let viewMode = 'grid';
    
    function handleViewModeChange(event) {
        viewMode = event.detail.viewMode;
        console.log('View mode changed to:', viewMode);
    }
</script>

<ProductList
    {products}
    {loading}
    {viewMode}
    gridColumns={3}
    showViewToggle={true}
    showAddToCart={true}
    showStock={true}
    showBrand={true}
    showCategory={true}
    on:view-mode-change={handleViewModeChange}
    on:product-click={handleProductClick}
    on:add-to-cart={handleAddToCart}
    on:quick-view={handleQuickView}
/>
`;

// Example 4: Different card sizes and configurations
export const exampleCardVariations = `
<script>
    import ProductCard from '$lib/components/ProductCard.svelte';
    
    let product = { /* product data */ };
</script>

<!-- Small card for compact layouts -->
<ProductCard
    {product}
    size="sm"
    imageAspectRatio="square"
    showBrand={false}
    showCategory={false}
/>

<!-- Medium card (default) -->
<ProductCard
    {product}
    size="md"
    imageAspectRatio="square"
    showBrand={true}
    showCategory={true}
/>

<!-- Large card with more details -->
<ProductCard
    {product}
    size="lg"
    imageAspectRatio="portrait"
    showBrand={true}
    showCategory={true}
    showStock={true}
/>
`;

// Example 5: Responsive grid configurations
export const exampleResponsiveGrids = `
<script>
    import ProductGrid from '$lib/components/ProductGrid.svelte';
    
    let products = [];
</script>

<!-- Mobile-first: 1 column on mobile, 2 on tablet, 3 on desktop -->
<ProductGrid {products} columns={3} />

<!-- E-commerce standard: 1 on mobile, 2 on tablet, 4 on desktop -->
<ProductGrid {products} columns={4} />

<!-- Showcase layout: 1 on mobile, 2 on tablet, 6 on large screens -->
<ProductGrid {products} columns={6} />
`;

// Example 6: Integration with search and filters
export const exampleIntegratedSearch = `
<script>
    import ProductSearch from '$lib/components/ProductSearch.svelte';
    
    let branchId = 'branch-123';
    let tenantId = 'tenant-123';
    let planTier = 'pro';
    let branches = [
        { id: 'branch-1', name: 'Main Store' },
        { id: 'branch-2', name: 'Mall Branch' }
    ];
    
    function handleProductClick(event) {
        const { product } = event.detail;
        // Navigate to product detail page
        goto(\`/products/\${product.id}\`);
    }
    
    function handleAddToCart(event) {
        const { product, quantity, variantId } = event.detail;
        // Add to cart logic
        cartStore.addItem(product, quantity, variantId);
    }
    
    function handleQuickView(event) {
        const { product } = event.detail;
        // Show quick view modal
        quickViewModal.show(product);
    }
    
    function handleUpgradePrompt(event) {
        const { feature } = event.detail;
        // Show upgrade modal
        upgradeModal.show(feature);
    }
</script>

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
    on:error={(e) => console.error('Search error:', e.detail.message)}
/>
`;

// Example 7: Custom styling and theming
export const exampleCustomStyling = `
<script>
    import ProductCard from '$lib/components/ProductCard.svelte';
    
    let product = { /* product data */ };
</script>

<!-- Custom styling with Tailwind classes -->
<ProductCard
    {product}
    className="border-2 border-primary hover:border-primary/80 shadow-lg"
    size="lg"
/>

<!-- Grid with custom gap and styling -->
<ProductGrid
    {products}
    columns={3}
    gap="lg"
    className="bg-muted/50 p-6 rounded-xl"
/>
`;

// Example 8: Event handling patterns
export function exampleEventHandling() {
    console.log('=== PRODUCT COMPONENT EVENT HANDLING ===');
    
    // Product click handler
    function handleProductClick(product: StorefrontProductWithCatalog) {
        console.log('Product clicked:', product.name);
        // Navigate to product detail
        // router.push(`/products/${product.id}`);
    }
    
    // Add to cart handler
    function handleAddToCart(product: StorefrontProductWithCatalog, quantity = 1, variantId?: string) {
        console.log('Adding to cart:', {
            product: product.name,
            quantity,
            variantId,
            price: product.price
        });
        
        // Add to cart store
        // cartStore.addItem(product, quantity, variantId);
        
        // Show success message
        // toast.success(`${product.name} added to cart`);
    }
    
    // Quick view handler
    function handleQuickView(product: StorefrontProductWithCatalog) {
        console.log('Quick view:', product.name);
        // Show modal with product details
        // quickViewModal.show(product);
    }
    
    return {
        handleProductClick,
        handleAddToCart,
        handleQuickView
    };
}

// Example 9: Performance optimization tips
export const performanceOptimizationTips = `
Performance Tips for Product Components:

1. **Lazy Loading Images**
   - All product images use loading="lazy" by default
   - Consider using intersection observer for custom lazy loading

2. **Virtual Scrolling**
   - For large product lists (1000+ items), consider virtual scrolling
   - Use libraries like @tanstack/virtual or svelte-virtual-list

3. **Image Optimization**
   - Use optimized image formats (WebP, AVIF)
   - Implement responsive images with srcset
   - Consider using a CDN with automatic optimization

4. **Pagination vs Infinite Scroll**
   - Use pagination for better SEO and performance
   - Infinite scroll for better UX on mobile

5. **Caching**
   - Cache product data in stores
   - Use SWR pattern for data fetching
   - Implement proper cache invalidation

6. **Bundle Optimization**
   - Tree-shake unused component features
   - Use dynamic imports for heavy components
   - Optimize CSS with PurgeCSS
`;

// Run examples
export function runProductComponentExamples() {
    console.log('=== PRODUCT COMPONENT EXAMPLES ===');
    
    console.log('\n1. Sample Products:');
    console.log(sampleProducts);
    
    console.log('\n2. Event Handling:');
    const handlers = exampleEventHandling();
    
    // Simulate events
    handlers.handleProductClick(sampleProducts[0]);
    handlers.handleAddToCart(sampleProducts[0], 2);
    handlers.handleQuickView(sampleProducts[1]);
    
    console.log('\n3. Component Usage Examples:');
    console.log('ProductCard:', exampleProductCard);
    console.log('ProductGrid:', exampleProductGrid);
    console.log('ProductList:', exampleProductList);
    
    console.log('\n4. Performance Tips:');
    console.log(performanceOptimizationTips);
}