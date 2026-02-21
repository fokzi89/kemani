<script lang="ts">
	import favicon from "$lib/assets/favicon.svg";
	import "../app.css";
	import { cart } from "$lib/stores/cart";
	import type { PageData } from "./$types";
	import type { Snippet } from "svelte";

	let { children, data }: { children: Snippet; data: PageData } = $props();

	// Function to handle add-to-cart events
	function handleAddToCart(event: CustomEvent<any>) {
		const product = event.detail;
		cart.addItem({
			id: product.id,
			productId: product.id,
			variantId: product.variantId || null,
			title:
				product.name ||
				product.custom_name ||
				product.global_product_catalog?.name,
			price: product.price,
			quantity: 1, // Default quantity when added from grid
			maxStock: product.stock_quantity || 10,
			image:
				product.custom_images?.[0] ||
				product.global_product_catalog?.primary_image,
		});
	}
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<div
	class="flex min-h-screen flex-col font-sans"
	role="application"
	on:add-to-cart={handleAddToCart}
>
	<!-- Navbar (Will be implemented fully later) -->
	<header
		class="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60"
	>
		<div class="container flex h-14 items-center">
			<a class="flex items-center space-x-2 font-bold" href="/">
				<span class="inline-block h-6 w-6 bg-primary rounded-full"
				></span>
				<span>Kemani Store</span>
			</a>
			<div class="ml-auto flex items-center gap-2">
				{#if data.user}
					<a
						href="/orders"
						class="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-9 px-3"
					>
						Orders
					</a>
					<form method="POST" action="/auth/signout">
						<button
							type="submit"
							class="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-9 px-3"
						>
							Sign Out
						</button>
					</form>
				{:else}
					<a
						href="/auth/signin"
						class="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-9 px-3"
					>
						Sign In
					</a>
				{/if}
				<a
					href="/cart"
					class="relative inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
				>
					<svg
						xmlns="http://www.w3.org/2000/svg"
						width="20"
						height="20"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
						class="lucide lucide-shopping-cart"
						><circle cx="8" cy="21" r="1" /><circle
							cx="19"
							cy="21"
							r="1"
						/><path
							d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"
						/></svg
					>
					<span class="ml-1">Cart</span>
				</a>
			</div>
		</div>
	</header>

	<main class="flex-1">
		{@render children()}
	</main>

	<!-- Minimal Footer -->
	<footer class="border-t py-6 md:py-0">
		<div
			class="container flex flex-col items-center justify-between gap-4 md:h-24 md:flex-row"
		>
			<p
				class="text-center text-sm leading-loose text-muted-foreground md:text-left"
			>
				Built by Kemani.
			</p>
		</div>
	</footer>
</div>
