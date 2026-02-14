<script lang="ts">
  import { ShoppingCart } from 'lucide-svelte';
  import type { Product } from '$lib/types';

  interface Props {
    product: Product;
    tenantId: string;
    formatPrice: (amount: number) => string;
  }

  let { product, tenantId, formatPrice }: Props = $props();

  const imageUrl = product.image_url || 'https://via.placeholder.com/300x300?text=No+Image';
  const isInStock = (product.stock_quantity ?? 0) > 0;
</script>

<a
  href="/shop/{tenantId}/products/{product.id}"
  class="group bg-white dark:bg-slate-800 rounded-lg shadow-sm hover:shadow-md transition overflow-hidden border border-slate-200 dark:border-slate-700"
>
  <!-- Image -->
  <div class="aspect-square overflow-hidden bg-slate-100 dark:bg-slate-700">
    <img
      src={imageUrl}
      alt={product.name}
      class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
    />
  </div>

  <!-- Content -->
  <div class="p-4">
    <h3 class="font-semibold theme-heading text-sm mb-1 line-clamp-2 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition">
      {product.name}
    </h3>

    {#if product.description}
      <p class="text-xs theme-text-muted mb-2 line-clamp-1">
        {product.description}
      </p>
    {/if}

    <div class="flex items-center justify-between mt-3">
      <div>
        <div class="text-lg font-bold theme-heading">
          {formatPrice(product.price)}
        </div>
        {#if !isInStock}
          <div class="text-xs text-red-500 font-medium">Out of stock</div>
        {:else if product.stock_quantity && product.stock_quantity < 10}
          <div class="text-xs text-orange-500">Only {product.stock_quantity} left</div>
        {/if}
      </div>

      <button
        class="p-2 bg-emerald-500 text-white rounded-lg hover:bg-emerald-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
        disabled={!isInStock}
        onclick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          // TODO: Add to cart functionality
          alert('Add to cart functionality coming soon!');
        }}
      >
        <ShoppingCart class="h-4 w-4" />
      </button>
    </div>
  </div>
</a>

<style>
  .line-clamp-1 {
    display: -webkit-box;
    -webkit-line-clamp: 1;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style>
