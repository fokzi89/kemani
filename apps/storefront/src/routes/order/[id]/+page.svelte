<script lang="ts">
    import { formatCurrency } from "$lib/storefront/pricing";
    import type { PageData } from "./$types";

    export let data: PageData;
    $: order = data.order;

    const STATUS_MAP: Record<string, { label: string; color: string }> = {
        pending_payment: {
            label: "Pending Payment",
            color: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400",
        },
        paid: {
            label: "Paid",
            color: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
        },
        processing: {
            label: "Processing",
            color: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400",
        },
        out_for_delivery: {
            label: "Out for Delivery",
            color: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400",
        },
        delivered: {
            label: "Delivered",
            color: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
        },
        cancelled: {
            label: "Cancelled",
            color: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
        },
    };

    $: status = STATUS_MAP[order.status] ?? {
        label: order.status,
        color: "bg-muted text-muted-foreground",
    };
    $: items = (order.items ?? []) as Array<{
        title: string;
        price: number;
        quantity: number;
        line_total: number;
    }>;
    $: createdAt = new Date(order.created_at).toLocaleDateString("en-NG", {
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
    });
</script>

<svelte:head>
    <title>Order #{order.id?.slice(0, 8)} | Kemani Store</title>
</svelte:head>

<div class="container mx-auto px-4 py-8">
    <!-- Header -->
    <div
        class="mb-8 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"
    >
        <div>
            <h1 class="text-2xl font-bold tracking-tight text-foreground">
                Order <span class="font-mono text-lg"
                    >#{order.id?.slice(0, 8)}</span
                >
            </h1>
            <p class="text-sm text-muted-foreground">{createdAt}</p>
        </div>
        <span
            class="inline-flex w-fit items-center rounded-full px-3 py-1 text-xs font-semibold {status.color}"
        >
            {status.label}
        </span>
    </div>

    <div class="grid gap-8 lg:grid-cols-3">
        <!-- Order Items -->
        <div class="lg:col-span-2 space-y-4">
            <div class="rounded-lg border bg-card shadow-sm">
                <div class="border-b p-4">
                    <h2 class="text-sm font-semibold text-foreground">
                        Items ({items.length})
                    </h2>
                </div>
                <div class="divide-y">
                    {#each items as item}
                        <div class="flex items-center justify-between p-4">
                            <div>
                                <p class="text-sm font-medium text-foreground">
                                    {item.title}
                                </p>
                                <p class="text-xs text-muted-foreground">
                                    {formatCurrency(item.price)} × {item.quantity}
                                </p>
                            </div>
                            <p class="text-sm font-semibold">
                                {formatCurrency(item.line_total)}
                            </p>
                        </div>
                    {/each}
                </div>
            </div>

            <!-- Delivery Info -->
            <div class="rounded-lg border bg-card p-4 shadow-sm space-y-3">
                <h2 class="text-sm font-semibold text-foreground">
                    Delivery Details
                </h2>
                <div class="grid gap-2 text-sm sm:grid-cols-2">
                    <div>
                        <p class="text-xs text-muted-foreground">Name</p>
                        <p class="font-medium">{order.customer_name}</p>
                    </div>
                    <div>
                        <p class="text-xs text-muted-foreground">Phone</p>
                        <p class="font-medium">{order.customer_phone}</p>
                    </div>
                    <div class="sm:col-span-2">
                        <p class="text-xs text-muted-foreground">Address</p>
                        <p class="font-medium">{order.delivery_address}</p>
                    </div>
                    {#if order.delivery_instructions}
                        <div class="sm:col-span-2">
                            <p class="text-xs text-muted-foreground">
                                Instructions
                            </p>
                            <p class="font-medium">
                                {order.delivery_instructions}
                            </p>
                        </div>
                    {/if}
                    <div>
                        <p class="text-xs text-muted-foreground">Method</p>
                        <p class="font-medium capitalize">
                            {order.delivery_method?.replace(/_/g, " ")}
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Payment Summary -->
        <div class="lg:col-span-1">
            <div
                class="sticky top-20 rounded-lg border bg-card p-6 shadow-sm space-y-4"
            >
                <h2 class="text-lg font-semibold text-foreground">
                    Payment Summary
                </h2>
                <div class="space-y-2 text-sm">
                    <div class="flex justify-between">
                        <span class="text-muted-foreground">Subtotal</span>
                        <span>{formatCurrency(order.subtotal)}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-muted-foreground">Delivery Fee</span>
                        <span>{formatCurrency(order.delivery_fee)}</span>
                    </div>
                </div>
                <div class="border-t pt-4">
                    <div class="flex justify-between text-base font-semibold">
                        <span>Total</span>
                        <span class="text-primary"
                            >{formatCurrency(order.total_amount)}</span
                        >
                    </div>
                </div>

                {#if order.status === "pending_payment"}
                    <div
                        class="rounded-md border border-yellow-200 bg-yellow-50 p-3 text-sm text-yellow-800 dark:border-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400"
                    >
                        Payment is pending. If you closed the payment window,
                        please contact support with your order reference.
                    </div>
                {/if}

                <a
                    href="/"
                    class="mt-2 inline-flex w-full h-10 items-center justify-center rounded-md bg-primary px-8 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90"
                >
                    Continue Shopping
                </a>
            </div>
        </div>
    </div>
</div>
