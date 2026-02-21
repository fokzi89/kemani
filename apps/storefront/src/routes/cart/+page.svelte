<script lang="ts">
    import { cart, cartTotal, cartCount } from "$lib/stores/cart";
    import { formatCurrency } from "$lib/storefront/pricing";
    import { calculateOrderTotals } from "$lib/storefront/pricing";

    $: items = $cart.items;
    $: total = $cartTotal;
    $: count = $cartCount;
    $: breakdown = calculateOrderTotals(total);

    function increment(id: string) {
        const item = items.find((i) => i.id === id);
        if (item) cart.updateQuantity(id, item.quantity + 1);
    }

    function decrement(id: string) {
        const item = items.find((i) => i.id === id);
        if (item && item.quantity > 1)
            cart.updateQuantity(id, item.quantity - 1);
    }

    function remove(id: string) {
        cart.removeItem(id);
    }
</script>

<svelte:head>
    <title>Shopping Cart | Kemani Store</title>
</svelte:head>

<div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold tracking-tight text-foreground mb-8">
        Shopping Cart
    </h1>

    {#if items.length === 0}
        <!-- Empty State -->
        <div
            class="flex h-64 flex-col items-center justify-center rounded-lg border border-dashed bg-muted/50 p-8 text-center"
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="text-muted-foreground mb-4"
                ><circle cx="8" cy="21" r="1" /><circle
                    cx="19"
                    cy="21"
                    r="1"
                /><path
                    d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"
                /></svg
            >
            <h3 class="text-lg font-semibold text-foreground">
                Your cart is empty
            </h3>
            <p class="mt-2 text-sm text-muted-foreground mb-4">
                Browse our products and add items to get started.
            </p>
            <a
                href="/"
                class="inline-flex h-10 items-center justify-center rounded-md bg-primary px-6 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90"
            >
                Continue Shopping
            </a>
        </div>
    {:else}
        <div class="grid gap-8 lg:grid-cols-3">
            <!-- Cart Items -->
            <div class="lg:col-span-2 space-y-4">
                {#each items as item (item.id)}
                    <div
                        class="flex gap-4 rounded-lg border bg-card p-4 shadow-sm"
                    >
                        <!-- Image -->
                        <div
                            class="h-24 w-24 flex-shrink-0 overflow-hidden rounded-md bg-muted"
                        >
                            {#if item.image}
                                <img
                                    src={item.image}
                                    alt={item.title}
                                    class="h-full w-full object-cover"
                                />
                            {:else}
                                <div
                                    class="flex h-full w-full items-center justify-center text-muted-foreground"
                                >
                                    <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        width="24"
                                        height="24"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        stroke="currentColor"
                                        stroke-width="2"
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        ><rect
                                            width="18"
                                            height="18"
                                            x="3"
                                            y="3"
                                            rx="2"
                                            ry="2"
                                        /><circle cx="9" cy="9" r="2" /><path
                                            d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"
                                        /></svg
                                    >
                                </div>
                            {/if}
                        </div>

                        <!-- Details -->
                        <div class="flex flex-1 flex-col justify-between">
                            <div class="flex justify-between">
                                <div>
                                    <h3
                                        class="text-sm font-medium text-foreground"
                                    >
                                        {item.title}
                                    </h3>
                                    <p
                                        class="mt-1 text-sm text-muted-foreground"
                                    >
                                        {formatCurrency(item.price)} each
                                    </p>
                                </div>
                                <p
                                    class="text-sm font-semibold text-foreground"
                                >
                                    {formatCurrency(item.price * item.quantity)}
                                </p>
                            </div>

                            <div class="mt-2 flex items-center justify-between">
                                <!-- Quantity Controls -->
                                <div class="flex items-center gap-2">
                                    <button
                                        type="button"
                                        on:click={() => decrement(item.id)}
                                        disabled={item.quantity <= 1}
                                        class="inline-flex h-8 w-8 items-center justify-center rounded-md border text-sm transition-colors hover:bg-accent disabled:opacity-50"
                                        aria-label="Decrease quantity"
                                    >
                                        <svg
                                            xmlns="http://www.w3.org/2000/svg"
                                            width="14"
                                            height="14"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            stroke="currentColor"
                                            stroke-width="2"
                                            ><path d="M5 12h14" /></svg
                                        >
                                    </button>
                                    <span
                                        class="w-8 text-center text-sm font-medium"
                                        >{item.quantity}</span
                                    >
                                    <button
                                        type="button"
                                        on:click={() => increment(item.id)}
                                        disabled={item.quantity >=
                                            item.maxStock}
                                        class="inline-flex h-8 w-8 items-center justify-center rounded-md border text-sm transition-colors hover:bg-accent disabled:opacity-50"
                                        aria-label="Increase quantity"
                                    >
                                        <svg
                                            xmlns="http://www.w3.org/2000/svg"
                                            width="14"
                                            height="14"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            stroke="currentColor"
                                            stroke-width="2"
                                            ><path d="M5 12h14" /><path
                                                d="M12 5v14"
                                            /></svg
                                        >
                                    </button>
                                </div>

                                <!-- Remove -->
                                <button
                                    type="button"
                                    on:click={() => remove(item.id)}
                                    class="text-sm text-destructive hover:underline"
                                >
                                    Remove
                                </button>
                            </div>
                        </div>
                    </div>
                {/each}
            </div>

            <!-- Order Summary -->
            <div class="lg:col-span-1">
                <div
                    class="sticky top-20 rounded-lg border bg-card p-6 shadow-sm space-y-4"
                >
                    <h2 class="text-lg font-semibold text-foreground">
                        Order Summary
                    </h2>

                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between">
                            <span class="text-muted-foreground"
                                >Subtotal ({count} items)</span
                            >
                            <span>{formatCurrency(breakdown.subtotal)}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-muted-foreground"
                                >Delivery Fee</span
                            >
                            <span
                                >{formatCurrency(
                                    breakdown.deliveryFeeAddition,
                                )}</span
                            >
                        </div>
                        <div class="flex justify-between">
                            <span class="text-muted-foreground"
                                >Platform Fee</span
                            >
                            <span
                                >{formatCurrency(
                                    breakdown.platformCommission,
                                )}</span
                            >
                        </div>
                        <div class="flex justify-between">
                            <span class="text-muted-foreground"
                                >Transaction Fee</span
                            >
                            <span
                                >{formatCurrency(
                                    breakdown.transactionFee,
                                )}</span
                            >
                        </div>
                    </div>

                    <div class="border-t pt-4">
                        <div
                            class="flex justify-between text-base font-semibold"
                        >
                            <span>Total</span>
                            <span class="text-primary"
                                >{formatCurrency(breakdown.totalAmount)}</span
                            >
                        </div>
                    </div>

                    <a
                        href="/checkout"
                        class="mt-4 inline-flex w-full h-11 items-center justify-center rounded-md bg-primary px-8 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                    >
                        Proceed to Checkout
                    </a>

                    <a
                        href="/"
                        class="inline-flex w-full h-10 items-center justify-center rounded-md border border-input bg-background px-8 text-sm font-medium shadow-sm transition-colors hover:bg-accent hover:text-accent-foreground"
                    >
                        Continue Shopping
                    </a>
                </div>
            </div>
        </div>
    {/if}
</div>
