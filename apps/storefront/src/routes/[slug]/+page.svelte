<script lang="ts">
    import { formatCurrency } from "$lib/storefront/pricing";
    import { cn } from "$lib/utils";
    import type { PageData } from "./$types";

    export let data: PageData;

    $: ({ product } = data);

    // Derived Props
    $: catalog = product.global_product_catalog;
    $: name = product.custom_name || catalog.name;
    $: description = product.custom_description || catalog.description;
    $: images = [
        product.custom_images?.[0] || catalog.primary_image,
        ...(product.custom_images?.slice(1) || catalog.images || []),
    ].filter(Boolean);

    // State
    let selectedVariantId: string | null = null;
    let quantity = 1;
    let selectedImageIndex = 0;

    // Computed Price
    $: selectedVariant = product.product_variants?.find(
        (v) => v.id === selectedVariantId,
    );
    $: currentPrice = product.price + (selectedVariant?.price_adjustment || 0);
    $: isOutOfStock =
        (selectedVariant
            ? selectedVariant.stock_quantity
            : product.stock_quantity) <= 0;

    function addToCart() {
        if (product.has_variants && !selectedVariantId) {
            alert("Please select a variant");
            return;
        }
        // Dispatch add to cart event
        const item = {
            productId: product.id,
            variantId: selectedVariantId,
            quantity,
            price: currentPrice,
        };
        console.log("Adding to cart:", item);
        // TODO: Integrate with Cart Store (T014)
    }
</script>

<div class="container mx-auto px-4 py-8">
    <div class="grid gap-8 md:grid-cols-2">
        <!-- Gallery -->
        <div class="space-y-4">
            <div
                class="aspect-square overflow-hidden rounded-lg border bg-muted"
            >
                <img
                    src={images[selectedImageIndex]}
                    alt={name}
                    class="h-full w-full object-cover object-center"
                />
            </div>
            {#if images.length > 1}
                <div class="flex gap-4 overflow-x-auto pb-2">
                    {#each images as img, i}
                        <button
                            type="button"
                            class={cn(
                                "relative aspect-square w-20 flex-shrink-0 overflow-hidden rounded-md border-2",
                                selectedImageIndex === i
                                    ? "border-primary"
                                    : "border-transparent",
                            )}
                            on:click={() => (selectedImageIndex = i)}
                        >
                            <img
                                src={img}
                                alt=""
                                class="h-full w-full object-cover"
                            />
                        </button>
                    {/each}
                </div>
            {/if}
        </div>

        <!-- Details -->
        <div class="flex flex-col gap-6">
            <div>
                <h1 class="text-3xl font-bold tracking-tight text-foreground">
                    {name}
                </h1>
                <p class="text-2xl font-bold text-primary mt-2">
                    {formatCurrency(currentPrice)}
                    {#if product.compare_at_price && product.compare_at_price > currentPrice}
                        <span
                            class="ml-2 text-lg text-muted-foreground line-through"
                        >
                            {formatCurrency(product.compare_at_price)}
                        </span>
                    {/if}
                </p>
            </div>

            <div class="prose prose-sm text-muted-foreground">
                <p>{description}</p>
            </div>

            <!-- Options -->
            {#if product.has_variants && product.product_variants?.length > 0}
                <div class="flex flex-col gap-2">
                    <label for="variant" class="text-sm font-medium"
                        >Select Option</label
                    >
                    <select
                        id="variant"
                        bind:value={selectedVariantId}
                        class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        <option value={null} disabled selected
                            >Choose an option</option
                        >
                        {#each product.product_variants as variant}
                            <option
                                value={variant.id}
                                disabled={!variant.is_available ||
                                    variant.stock_quantity <= 0}
                            >
                                {variant.variant_name}
                                {variant.price_adjustment !== 0
                                    ? `(${variant.price_adjustment > 0 ? "+" : ""}${formatCurrency(variant.price_adjustment)})`
                                    : ""}
                                {variant.stock_quantity <= 0
                                    ? "(Out of Stock)"
                                    : ""}
                            </option>
                        {/each}
                    </select>
                </div>
            {/if}

            <!-- Actions -->
            <div class="flex flex-col gap-4 sm:flex-row sm:items-end">
                <div class="flex flex-col gap-2">
                    <label for="quantity" class="text-sm font-medium"
                        >Quantity</label
                    >
                    <input
                        id="quantity"
                        type="number"
                        min="1"
                        bind:value={quantity}
                        class="flex h-10 w-24 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                    />
                </div>

                <button
                    type="button"
                    on:click={addToCart}
                    disabled={isOutOfStock}
                    class="inline-flex h-10 flex-1 items-center justify-center rounded-md bg-primary px-8 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50"
                >
                    {isOutOfStock ? "Out of Stock" : "Add to Cart"}
                </button>
            </div>
        </div>
    </div>
</div>
