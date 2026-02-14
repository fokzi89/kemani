<script lang="ts">
    import { cart } from "$lib/stores/cart";
    import { user } from "$lib/stores/user";
    import Trash from "lucide-svelte/icons/trash";
    import Plus from "lucide-svelte/icons/plus";
    import Minus from "lucide-svelte/icons/minus";
    import ArrowRight from "lucide-svelte/icons/arrow-right";
    import ArrowLeft from "lucide-svelte/icons/arrow-left";

    // Calculate total
    let subtotal = $derived(
        $cart.items.reduce((acc, item) => acc + item.price * item.quantity, 0),
    );
</script>

<div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold mb-8 text-gray-900 dark:text-white">
        Shopping Cart
    </h1>

    {#if $cart.items.length === 0}
        <div
            class="text-center py-20 bg-gray-50 dark:bg-gray-800 rounded-2xl border dark:border-gray-700"
        >
            <p class="text-xl text-gray-500 mb-6">Your cart is empty</p>
            <a
                href="/shop"
                class="inline-flex items-center text-emerald-600 font-medium hover:underline"
            >
                <ArrowLeft class="h-4 w-4 mr-2" />
                Continue Shopping
            </a>
        </div>
    {:else}
        <div class="grid lg:grid-cols-3 gap-8">
            <!-- Cart Items -->
            <div class="lg:col-span-2 space-y-4">
                {#each $cart.items as item}
                    <div
                        class="flex gap-4 p-4 bg-white dark:bg-gray-800 rounded-xl shadow-sm border dark:border-gray-700"
                    >
                        <div
                            class="h-24 w-24 bg-gray-100 dark:bg-gray-900 rounded-lg overflow-hidden flex-shrink-0"
                        >
                            <img
                                src={item.image || "/placeholder.png"}
                                alt={item.name}
                                class="w-full h-full object-cover"
                            />
                        </div>

                        <div class="flex-1 flex flex-col justify-between">
                            <div class="flex justify-between">
                                <div>
                                    <h3
                                        class="font-medium text-gray-900 dark:text-white"
                                    >
                                        {item.name}
                                    </h3>
                                    {#if item.variantId}
                                        <p class="text-sm text-gray-500">
                                            Variant: {item.variantId}
                                        </p>
                                    {/if}
                                </div>
                                <button
                                    onclick={() =>
                                        cart.removeItem(
                                            item.id,
                                            item.variantId,
                                        )}
                                    class="text-gray-400 hover:text-red-500 transition"
                                >
                                    <Trash class="h-5 w-5" />
                                </button>
                            </div>

                            <div class="flex justify-between items-center mt-2">
                                <div
                                    class="flex items-center border border-gray-200 dark:border-gray-700 rounded-lg"
                                >
                                    <button
                                        onclick={() =>
                                            cart.updateQuantity(
                                                item.id,
                                                item.quantity - 1,
                                                item.variantId,
                                            )}
                                        class="p-1 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-l-lg"
                                        ><Minus class="h-4 w-4" /></button
                                    >
                                    <span class="w-8 text-center text-sm"
                                        >{item.quantity}</span
                                    >
                                    <button
                                        onclick={() =>
                                            cart.updateQuantity(
                                                item.id,
                                                item.quantity + 1,
                                                item.variantId,
                                            )}
                                        class="p-1 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-r-lg"
                                        ><Plus class="h-4 w-4" /></button
                                    >
                                </div>
                                <span
                                    class="font-bold text-gray-900 dark:text-white"
                                    >₦{(
                                        item.price * item.quantity
                                    ).toLocaleString()}</span
                                >
                            </div>
                        </div>
                    </div>
                {/each}
            </div>

            <!-- Summary -->
            <div class="lg:col-span-1">
                <div
                    class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border dark:border-gray-700 p-6 sticky top-24"
                >
                    <h2
                        class="text-lg font-bold mb-4 text-gray-900 dark:text-white"
                    >
                        Order Summary
                    </h2>

                    <div class="space-y-3 mb-6">
                        <div
                            class="flex justify-between text-gray-600 dark:text-gray-400"
                        >
                            <span>Subtotal</span>
                            <span>₦{subtotal.toLocaleString()}</span>
                        </div>
                        <div
                            class="flex justify-between text-gray-600 dark:text-gray-400"
                        >
                            <span>Taxes & Fees</span>
                            <span class="text-xs">Calculated at checkout</span>
                        </div>
                    </div>

                    <div class="border-t dark:border-gray-700 pt-4 mb-6">
                        <div
                            class="flex justify-between font-bold text-lg text-gray-900 dark:text-white"
                        >
                            <span>Total</span>
                            <span>₦{subtotal.toLocaleString()}</span>
                        </div>
                    </div>

                    <a
                        href={$user ? "/checkout" : "/login?redirect=/checkout"}
                        class="block w-full text-center bg-emerald-600 text-white font-bold py-3 rounded-xl hover:bg-emerald-700 transition shadow-lg hover:shadow-xl"
                    >
                        Proceed to Checkout
                    </a>
                </div>
            </div>
        </div>
    {/if}
</div>
