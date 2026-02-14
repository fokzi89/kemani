<script lang="ts">
    import { onMount } from "svelte";
    import { page } from "$app/stores";
    import { getProducts, type Product } from "$lib/services/products";
    import Search from "lucide-svelte/icons/search";
    import Filter from "lucide-svelte/icons/filter";

    let products: Product[] = $state([]);
    let loading = $state(true);
    let searchQuery = $state("");
    let selectedCategory = $state("");

    // These would typically come from API or config
    const categories = ["All", "Electronics", "Fashion", "Home", "Beauty"];

    async function loadProducts() {
        loading = true;
        try {
            // In real implementation, tenant/branch ID would come from $page.data or context
            const tenantId = "demo-tenant";
            products = await getProducts(
                tenantId,
                undefined,
                searchQuery,
                selectedCategory !== "All" ? selectedCategory : undefined,
            );
        } catch (e) {
            console.error(e);
        } finally {
            loading = false;
        }
    }

    onMount(() => {
        loadProducts();
    });

    function handleSearch() {
        loadProducts();
    }
</script>

<div class="container mx-auto px-4 py-8">
    <div
        class="flex flex-col md:flex-row justify-between items-center mb-8 gap-4"
    >
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Shop</h1>

        <div class="flex flex-col sm:flex-row gap-4 w-full md:w-auto">
            <!-- Search -->
            <div class="relative">
                <input
                    type="text"
                    bind:value={searchQuery}
                    onkeydown={(e) => e.key === "Enter" && handleSearch()}
                    placeholder="Search products..."
                    class="pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 w-full sm:w-64 bg-white dark:bg-gray-800 dark:border-gray-700"
                />
                <button
                    onclick={handleSearch}
                    class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
                >
                    <Search class="h-4 w-4" />
                </button>
            </div>

            <!-- Filter -->
            <select
                bind:value={selectedCategory}
                onchange={loadProducts}
                class="px-4 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 bg-white dark:bg-gray-800 dark:border-gray-700"
            >
                {#each categories as category}
                    <option value={category}>{category}</option>
                {/each}
            </select>
        </div>
    </div>

    {#if loading}
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {#each Array(8) as _}
                <div
                    class="bg-gray-200 dark:bg-gray-800 rounded-xl h-80 animate-pulse"
                ></div>
            {/each}
        </div>
    {:else if products.length === 0}
        <div class="text-center py-20 text-gray-500">
            <p class="text-xl">No products found.</p>
            <button
                onclick={() => {
                    searchQuery = "";
                    selectedCategory = "All";
                    loadProducts();
                }}
                class="mt-4 text-emerald-600 hover:underline"
                >Clear filters</button
            >
        </div>
    {:else}
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {#each products as product}
                <a
                    href="/shop/product/{product.id}"
                    class="group bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-md transition overflow-hidden border dark:border-gray-700"
                >
                    <div
                        class="aspect-square bg-gray-100 dark:bg-gray-900 overflow-hidden relative"
                    >
                        <img
                            src={product.image_url || "/placeholder.png"}
                            alt={product.name}
                            class="w-full h-full object-cover group-hover:scale-105 transition duration-300"
                        />
                    </div>
                    <div class="p-4">
                        <h3
                            class="font-medium text-gray-900 dark:text-white truncate"
                        >
                            {product.name}
                        </h3>
                        <p
                            class="text-sm text-gray-500 dark:text-gray-400 mb-2 truncate"
                        >
                            {product.category}
                        </p>
                        <div class="flex justify-between items-center">
                            <span
                                class="font-bold text-emerald-600 dark:text-emerald-400"
                                >₦{product.price.toLocaleString()}</span
                            >
                            <span
                                class="text-xs px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded-full text-gray-600 dark:text-gray-300"
                                >View</span
                            >
                        </div>
                    </div>
                </a>
            {/each}
        </div>
    {/if}
</div>
