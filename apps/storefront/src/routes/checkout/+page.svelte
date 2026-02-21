<script lang="ts">
    import CheckoutForm from "$lib/components/CheckoutForm.svelte";
    import DeliveryMethodSelector from "$lib/components/DeliveryMethodSelector.svelte";
    import { cart, cartTotal, cartCount } from "$lib/stores/cart";
    import {
        formatCurrency,
        calculateOrderTotals,
        DELIVERY_BASE_FEE,
    } from "$lib/storefront/pricing";
    import { goto } from "$app/navigation";
    import { onMount } from "svelte";
    import { page } from "$app/stores";

    // Form state
    let name = "";
    let phone = "";
    let address = "";
    let instructions = "";

    // Delivery state
    let deliveryMethod = "self_pickup";
    let deliveryBaseFee = 0;

    // Payment state
    let isSubmitting = false;
    let errorMessage = "";

    $: items = $cart.items;
    $: subtotal = $cartTotal;
    $: count = $cartCount;

    // Recalculate totals with selected delivery method fee
    $: breakdown = calculateOrderTotals(subtotal, deliveryBaseFee);

    $: canSubmit =
        name.trim().length > 0 &&
        phone.trim().length >= 10 &&
        address.trim().length > 0 &&
        items.length > 0 &&
        !isSubmitting;

    // Auth-aware auto-fill
    $: user = $page.data.user;
    $: userEmail = user?.email || "";

    function handleDeliveryChange(
        e: CustomEvent<{ method: string; baseFee: number }>,
    ) {
        deliveryMethod = e.detail.method;
        deliveryBaseFee = e.detail.baseFee;
    }

    // Redirect if cart empty + auto-fill from user profile
    onMount(async () => {
        if ($cart.items.length === 0) {
            goto("/cart");
            return;
        }
        // Auto-fill from authenticated user's metadata
        if (user) {
            const meta = user.user_metadata || {};
            if (!name && meta.full_name) name = meta.full_name;
            if (!phone && meta.phone) phone = meta.phone;
            if (!address && meta.delivery_address)
                address = meta.delivery_address;
        }
    });

    async function initializePayment() {
        if (!canSubmit) return;
        isSubmitting = true;
        errorMessage = "";

        try {
            // 1. Create order on server
            const res = await fetch("/api/checkout", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    items: items.map((i) => ({
                        productId: i.productId,
                        variantId: i.variantId,
                        title: i.title,
                        price: i.price,
                        quantity: i.quantity,
                    })),
                    deliveryMethod,
                    deliveryFee: deliveryBaseFee,
                    customerName: name,
                    customerPhone: phone,
                    customerAddress: address,
                    deliveryInstructions: instructions,
                    subtotal,
                    totalAmount: breakdown.totalAmount,
                }),
            });

            if (!res.ok) {
                const err = await res.json();
                throw new Error(err.message || "Failed to create order");
            }

            const { orderId, totalAmount } = await res.json();

            // 2. Initialize Paystack
            openPaystack(orderId, totalAmount);
        } catch (err: any) {
            errorMessage =
                err.message || "Something went wrong. Please try again.";
            isSubmitting = false;
        }
    }

    function openPaystack(orderId: string, amount: number) {
        // @ts-ignore - PaystackPop is loaded via script tag
        const handler = window.PaystackPop?.setup({
            key: import.meta.env.VITE_PAYSTACK_PUBLIC_KEY || "pk_test_xxxxx",
            email: userEmail || `${phone.replace(/\D/g, "")}@guest.kemani.com`,
            amount: Math.round(amount * 100), // Paystack expects kobo
            currency: "NGN",
            ref: orderId,
            metadata: {
                order_id: orderId,
                customer_name: name,
                customer_phone: phone,
                delivery_method: deliveryMethod,
            },
            callback: (response: { reference: string }) => {
                // Payment successful — clear cart and redirect
                cart.clear();
                goto(`/checkout/success?ref=${response.reference}`);
            },
            onClose: () => {
                isSubmitting = false;
                errorMessage =
                    "Payment window was closed. Your order is saved — you can retry payment.";
            },
        });

        if (handler) {
            handler.openIframe();
        } else {
            // Fallback: redirect-based payment
            errorMessage =
                "Payment gateway not loaded. Please refresh and try again.";
            isSubmitting = false;
        }
    }
</script>

<svelte:head>
    <title>Checkout | Kemani Store</title>
    <script src="https://js.paystack.co/v2/inline.js"></script>
</svelte:head>

<div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold tracking-tight text-foreground mb-8">
        Checkout
    </h1>

    {#if items.length === 0}
        <div
            class="flex h-48 flex-col items-center justify-center rounded-lg border border-dashed bg-muted/50 p-8 text-center"
        >
            <p class="text-muted-foreground">Your cart is empty.</p>
            <a
                href="/"
                class="mt-4 text-sm font-medium text-primary hover:underline"
                >Browse products</a
            >
        </div>
    {:else}
        <div class="grid gap-8 lg:grid-cols-3">
            <!-- Form Section -->
            <div class="lg:col-span-2 space-y-8">
                <!-- Step 1: Delivery Info -->
                <div class="rounded-lg border bg-card p-6 shadow-sm">
                    <h2 class="text-lg font-semibold text-foreground mb-4">
                        <span
                            class="mr-2 inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground"
                            >1</span
                        >
                        Delivery Information
                    </h2>
                    <CheckoutForm
                        bind:name
                        bind:phone
                        bind:address
                        bind:instructions
                        disabled={isSubmitting}
                    >
                        <div slot="actions"></div>
                    </CheckoutForm>
                </div>

                <!-- Step 2: Delivery Method -->
                <div class="rounded-lg border bg-card p-6 shadow-sm">
                    <h2 class="text-lg font-semibold text-foreground mb-4">
                        <span
                            class="mr-2 inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground"
                            >2</span
                        >
                        Delivery Method
                    </h2>
                    <DeliveryMethodSelector
                        bind:selected={deliveryMethod}
                        disabled={isSubmitting}
                        on:change={handleDeliveryChange}
                    />
                </div>

                <!-- Step 3: Payment -->
                <div class="rounded-lg border bg-card p-6 shadow-sm">
                    <h2 class="text-lg font-semibold text-foreground mb-4">
                        <span
                            class="mr-2 inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground"
                            >3</span
                        >
                        Payment
                    </h2>
                    <p class="text-sm text-muted-foreground mb-4">
                        Secure payment powered by Paystack. You'll be asked to
                        complete payment after reviewing your order.
                    </p>
                    <div
                        class="flex items-center gap-2 text-xs text-muted-foreground"
                    >
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="16"
                            height="16"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            ><rect
                                width="18"
                                height="11"
                                x="3"
                                y="11"
                                rx="2"
                                ry="2"
                            /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg
                        >
                        Cards, Bank Transfer, USSD, Mobile Money accepted
                    </div>
                </div>
            </div>

            <!-- Order Summary -->
            <div class="lg:col-span-1">
                <div
                    class="sticky top-20 rounded-lg border bg-card p-6 shadow-sm space-y-4"
                >
                    <h2 class="text-lg font-semibold text-foreground">
                        Order Summary
                    </h2>

                    <!-- Items Preview -->
                    <div
                        class="max-h-48 space-y-2 overflow-y-auto border-b pb-4"
                    >
                        {#each items as item}
                            <div class="flex justify-between text-sm">
                                <span class="truncate text-muted-foreground"
                                    >{item.title} × {item.quantity}</span
                                >
                                <span class="flex-shrink-0 font-medium"
                                    >{formatCurrency(
                                        item.price * item.quantity,
                                    )}</span
                                >
                            </div>
                        {/each}
                    </div>

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
                                >{deliveryBaseFee === 0
                                    ? "Free"
                                    : formatCurrency(
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

                    {#if errorMessage}
                        <div
                            class="rounded-md border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive"
                        >
                            {errorMessage}
                        </div>
                    {/if}

                    <button
                        type="button"
                        on:click={initializePayment}
                        disabled={!canSubmit}
                        class="mt-2 inline-flex w-full h-11 items-center justify-center rounded-md bg-primary px-8 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50"
                    >
                        {#if isSubmitting}
                            <svg
                                class="mr-2 h-4 w-4 animate-spin"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <circle
                                    class="opacity-25"
                                    cx="12"
                                    cy="12"
                                    r="10"
                                    stroke="currentColor"
                                    stroke-width="4"
                                ></circle>
                                <path
                                    class="opacity-75"
                                    fill="currentColor"
                                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                                ></path>
                            </svg>
                            Processing...
                        {:else}
                            Pay {formatCurrency(breakdown.totalAmount)}
                        {/if}
                    </button>

                    <a
                        href="/cart"
                        class="inline-flex w-full h-10 items-center justify-center rounded-md border border-input bg-background px-8 text-sm font-medium shadow-sm transition-colors hover:bg-accent hover:text-accent-foreground"
                    >
                        Back to Cart
                    </a>
                </div>
            </div>
        </div>
    {/if}
</div>
