<script lang="ts">
    import { formatCurrency } from "$lib/storefront/pricing";
    import type { PageData } from "./$types";

    export let data: PageData;

    $: orders = data.orders;

    const STATUS_MAP: Record<string, { label: string; color: string }> = {
        pending_payment: {
            label: "Pending",
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
            label: "On the way",
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
        payment_failed: {
            label: "Failed",
            color: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
        },
    };

    function getStatus(s: string) {
        return (
            STATUS_MAP[s] ?? {
                label: s,
                color: "bg-muted text-muted-foreground",
            }
        );
    }

    function formatDate(d: string) {
        return new Date(d).toLocaleDateString("en-NG", {
            year: "numeric",
            month: "short",
            day: "numeric",
        });
    }
</script>

<svelte:head>
    <title>My Orders | Kemani Store</title>
</svelte:head>

<div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold tracking-tight text-foreground mb-8">
        My Orders
    </h1>

    {#if orders.length === 0}
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
                ><path d="M16 16h6" /><path
                    d="M21 10V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l2-1.14"
                /><path d="m7.5 4.27 9 5.15" /><polyline
                    points="3.29 7 12 12 20.71 7"
                /><line x1="12" x2="12" y1="22" y2="12" /></svg
            >
            <h3 class="text-lg font-semibold text-foreground">No orders yet</h3>
            <p class="mt-2 text-sm text-muted-foreground mb-4">
                Start shopping to see your order history here.
            </p>
            <a
                href="/"
                class="inline-flex h-10 items-center justify-center rounded-md bg-primary px-6 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90"
            >
                Browse Products
            </a>
        </div>
    {:else}
        <div class="space-y-4">
            {#each orders as order}
                {@const status = getStatus(order.status)}
                {@const itemCount = (order.items as any[])?.length ?? 0}
                <a
                    href="/order/{order.id}"
                    class="block rounded-lg border bg-card p-4 shadow-sm transition-colors hover:bg-accent/50"
                >
                    <div
                        class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
                    >
                        <div class="flex flex-col gap-1">
                            <!-- Business Name Header -->
                            {#if order.business_name}
                                <p
                                    class="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1"
                                >
                                    {order.business_name}
                                </p>
                            {/if}

                            <div class="flex items-center gap-3">
                                <span
                                    class="font-mono text-sm font-semibold text-foreground"
                                    >#{order.id.slice(0, 8)}</span
                                >
                                <span
                                    class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {status.color}"
                                >
                                    {status.label}
                                </span>
                            </div>
                            <p class="text-sm text-muted-foreground">
                                {itemCount} item{itemCount !== 1 ? "s" : ""} · {formatDate(
                                    order.created_at,
                                )}
                            </p>
                        </div>
                        <div class="text-right mt-2 sm:mt-0">
                            <p class="text-lg font-bold text-primary">
                                {formatCurrency(order.total_amount)}
                            </p>
                            <p class="text-xs text-muted-foreground capitalize">
                                {order.delivery_method?.replace(/_/g, " ")}
                            </p>
                        </div>
                    </div>
                </a>
            {/each}
        </div>
    {/if}
</div>
