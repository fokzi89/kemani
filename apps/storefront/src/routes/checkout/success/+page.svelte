<script lang="ts">
    import { page } from "$app/stores";

    $: ref = $page.url.searchParams.get("ref") || "";
</script>

<svelte:head>
    <title>Order Confirmed | Kemani Store</title>
</svelte:head>

<div
    class="container mx-auto flex min-h-[60vh] flex-col items-center justify-center px-4 py-16 text-center"
>
    <div class="rounded-full bg-green-100 p-4 dark:bg-green-900/30 mb-6">
        <svg
            xmlns="http://www.w3.org/2000/svg"
            width="48"
            height="48"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="text-green-600 dark:text-green-400"
        >
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
            <path d="m9 11 3 3L22 4" />
        </svg>
    </div>

    <h1 class="text-3xl font-bold tracking-tight text-foreground">
        Order Confirmed!
    </h1>
    <p class="mt-2 max-w-md text-muted-foreground">
        Thank you for your purchase. Your order has been placed successfully and
        is being processed.
    </p>

    {#if ref}
        <div class="mt-4 rounded-md border bg-muted/50 px-4 py-2">
            <p class="text-xs text-muted-foreground">Order Reference</p>
            <p class="font-mono text-sm font-semibold">{ref}</p>
        </div>
    {/if}

    <div class="mt-8 flex gap-4">
        <a
            href="/"
            class="inline-flex h-10 items-center justify-center rounded-md bg-primary px-6 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90"
        >
            Continue Shopping
        </a>
    </div>
</div>
