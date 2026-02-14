<script lang="ts">
    import { onMount } from "svelte";
    import { page } from "$app/stores";
    import { getProduct, type Product } from "$lib/services/products";
    import { cart } from "$lib/stores/cart";
    import { ui } from "$lib/stores/ui";
    import ShoppingBag from "lucide-svelte/icons/shopping-bag";
    import ArrowLeft from "lucide-svelte/icons/arrow-left";
    import Check from "lucide-svelte/icons/check";

    let product: Product | null = $state(null);
    let loading = $state(true);
    let selectedVariantId = $state("");
    let quantity = $state(1);

    const id = $page.params.slug;

    onMount(async () => {
        loading = true;
        try {
            product = await getProduct(id);
            if (product && product.variants && product.variants.length > 0) {
                selectedVariantId = product.variants[0].id;
            }
        } catch (e) {
            console.error(e);
        } finally {
            loading = false;
        }
    });

    function addToCart() {
        if (!product) return;

        // Check variant selection
        if (
            product.variants &&
            product.variants.length > 0 &&
            !selectedVariantId
        ) {
            ui.addToast("Please select a variant", "error");
            return;
        }

        const variant = product.variants?.find(
            (v) => v.id === selectedVariantId,
        );

        cart.addItem({
            id: product.id,
            name: product.name,
            price: variant ? variant.price : product.price,
            image: product.image_url,
            branchId: product.branch_id || "default", // Fallback
            variantId: selectedVariantId,
        });

        // If quantity > 1, update it (cart.addItem adds 1 by default)
        if (quantity > 1) {
            // We already added 1, so add the rest
            // Actually cart.addItem logic is simple increment, checking quantity logic in store
            // Let's use updateQuantity for precision if needed, but for now simple add is fine or we improve store
            // Improving store usage:
            cart.updateQuantity(
                product.id,
                (get(cart).items.find(
                    (i) =>
                        i.id === product.id &&
                        i.variantId === selectedVariantId,
                )?.quantity || 0) +
                    (quantity - 1),
                selectedVariantId,
            );
        }

        ui.addToast(`Added ${product.name} to cart`, "success");
    }

    function increment() {
        quantity += 1;
    }
    function decrement() {
        if (quantity > 1) quantity -= 1;
    }
</script>

<div class="container mx-auto px-4 py-8">
    <a
        href="/shop"
        class="inline-flex items-center text-gray-500 hover:text-emerald-600 mb-6 transition-colors"
    >
        <ArrowLeft class="h-4 w-4 mr-2" />
        Back to Shop
    </a>

    {#if loading}
        <div class="grid md:grid-cols-2 gap-12 animate-pulse">
            <div
                class="bg-gray-200 dark:bg-gray-800 rounded-2xl aspect-square"
            ></div>
            <div class="space-y-4 py-8">
                <div
                    class="h-8 bg-gray-200 dark:bg-gray-800 rounded w-3/4"
                ></div>
                <div
                    class="h-4 bg-gray-200 dark:bg-gray-800 rounded w-1/2"
                ></div>
                <div
                    class="h-10 bg-gray-200 dark:bg-gray-800 rounded w-1/4"
                ></div>
            </div>
        </div>
    {:else if !product}
        <div class="text-center py-20">
            <h2
                class="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-emerald-600 to-green-500"
            >
                Product not found
            </h2>
            <p class="text-gray-500 mt-2">
                The product you are looking for does not exist or has been
                removed.
            </p>
        </div>
    {:else}
        <div class="grid md:grid-cols-2 gap-12">
            <!-- Image Gallery -->
            <div
                class="bg-white dark:bg-gray-800 rounded-2xl overflow-hidden shadow-sm border dark:border-gray-700"
            >
                <img
                    src={product.image_url || "/placeholder.png"}
                    alt={product.name}
                    class="w-full h-full object-cover"
                />
            </div>

            <!-- Details -->
            <div class="flex flex-col justify-center">
                <div class="mb-6">
                    <span
                        class="text-sm font-medium text-emerald-600 bg-emerald-50 dark:bg-emerald-900/20 dark:text-emerald-400 px-3 py-1 rounded-full"
                        >{product.category}</span
                    >
                </div>

                <h1
                    class="text-4xl font-bold text-gray-900 dark:text-white mb-4"
                >
                    {product.name}
                </h1>

                <div
                    class="text-3xl font-bold text-emerald-600 dark:text-emerald-400 mb-6"
                >
                    ₦{(
                        product.variants?.find(
                            (v) => v.id === selectedVariantId,
                        )?.price || product.price
                    ).toLocaleString()}
                </div>

                <p
                    class="text-gray-600 dark:text-gray-300 mb-8 leading-relaxed text-lg"
                >
                    {product.description}
                </p>

                <!-- Variants -->
                {#if product.variants && product.variants.length > 0}
                    <div
                        class="mb-8 p-6 bg-gray-50 dark:bg-gray-900/50 rounded-xl border dark:border-gray-800"
                    >
                        <label
                            class="block text-sm font-semibold text-gray-900 dark:text-white mb-3"
                            >Options</label
                        >
                        <div class="flex flex-wrap gap-3">
                            {#each product.variants as variant}
                                <button
                                    class="px-4 py-2 rounded-lg border-2 transition-all font-medium {selectedVariantId ===
                                    variant.id
                                        ? 'border-emerald-600 bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400'
                                        : 'border-gray-200 hover:border-gray-300 dark:border-gray-700 dark:text-gray-300'}"
                                    onclick={() =>
                                        (selectedVariantId = variant.id)}
                                >
                                    {variant.name}
                                </button>
                            {/each}
                        </div>
                    </div>
                {/if}

                <div class="flex items-center gap-6 mb-8">
                    <!-- Quantity -->
                    <div
                        class="flex items-center border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800"
                    >
                        <button
                            onclick={decrement}
                            class="px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-l-lg transition"
                            >-</button
                        >
                        <span class="w-12 text-center font-medium"
                            >{quantity}</span
                        >
                        <button
                            onclick={increment}
                            class="px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-r-lg transition"
                            >+</button
                        >
                    </div>

                    <!-- Add to Cart -->
                    <button
                        onclick={addToCart}
                        class="flex-1 flex items-center justify-center gap-3 bg-gradient-to-r from-emerald-600 to-green-600 text-white font-bold py-3.5 px-8 rounded-xl hover:shadow-lg hover:from-emerald-500 hover:to-green-500 transition-all active:scale-[0.98]"
                    >
                        <ShoppingBag class="h-5 w-5" />
                        Add to Cart
                    </button>
                </div>

                <div
                    class="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                >
                    <Check class="h-4 w-4 text-emerald-500" />
                    <span>In stock and ready to ship</span>
                </div>
            </div>
        </div>
    {/if}
</div>
