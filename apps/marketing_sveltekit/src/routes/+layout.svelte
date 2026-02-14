<script lang="ts">
	import "../app.css";
	import { cart } from "$lib/stores/cart";
	import { user } from "$lib/stores/user";
	import ShoppingBag from "lucide-svelte/icons/shopping-bag";
	import Menu from "lucide-svelte/icons/menu";
	import UserIcon from "lucide-svelte/icons/user";
	import ChatWidget from "$lib/components/ChatWidget.svelte";
	import { onMount } from "svelte";
	import { browser } from "$app/environment";

	let { children } = $props();
	let isMenuOpen = $state(false);
	let isStorefront = $state(false);

	// Check if we are on a storefront page (not marketing)
	// Use browser check to avoid SSR issues
	onMount(() => {
		if (browser) {
			const pathname = window.location.pathname;
			isStorefront =
				pathname.startsWith("/shop") ||
				pathname.startsWith("/cart") ||
				pathname.startsWith("/checkout") ||
				pathname.startsWith("/account");
		}
	});
</script>

<div
	class="min-h-screen flex flex-col bg-gray-50 dark:bg-gray-900 transition-colors duration-300"
>
	<!-- Header -->
	<header
		class="sticky top-0 z-50 w-full border-b bg-white/80 dark:bg-gray-950/80 backdrop-blur supports-[backdrop-filter]:bg-white/60"
	>
		<div
			class="container flex h-16 items-center justify-between px-4 md:px-6"
		>
			<div class="flex gap-6 md:gap-10">
				<a href="/" class="flex items-center space-x-2">
					<span
						class="inline-block font-bold text-xl text-emerald-600 dark:text-emerald-400"
						>Kemani</span
					>
				</a>
				{#if !isStorefront}
					<nav class="hidden md:flex gap-6">
						<a
							href="/#features"
							class="text-sm font-medium transition-colors hover:text-primary"
							>Features</a
						>
						<a
							href="/pricing"
							class="text-sm font-medium transition-colors hover:text-primary"
							>Pricing</a
						>
						<a
							href="/about"
							class="text-sm font-medium transition-colors hover:text-primary"
							>About</a
						>
					</nav>
				{/if}
			</div>

			<div class="flex items-center gap-4">
				{#if isStorefront}
					<a
						href="/shop"
						class="text-sm font-medium transition-colors hover:text-primary hidden md:block"
						>Shop</a
					>

					<!-- Cart Indicator -->
					<a
						href="/cart"
						class="relative p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
					>
						<ShoppingBag class="h-5 w-5" />
						{#if $cart.items.length > 0}
							<span
								class="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-emerald-600 text-[10px] font-bold text-white"
							>
								{$cart.items.reduce(
									(acc, item) => acc + item.quantity,
									0,
								)}
							</span>
						{/if}
					</a>

					<!-- User Menu -->
					<a
						href={$user ? "/account" : "/login"}
						class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
					>
						<UserIcon class="h-5 w-5" />
					</a>
				{:else}
					<a
						href="/login"
						class="text-sm font-medium transition-colors hover:text-primary"
						>Log in</a
					>
					<a
						href="/register?plan=free"
						class="hidden md:inline-flex h-9 items-center justify-center rounded-md bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow transition-colors hover:bg-emerald-700 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-emerald-700 disabled:pointer-events-none disabled:opacity-50"
					>
						Get Started
					</a>
				{/if}

				<button
					class="md:hidden p-2"
					onclick={() => (isMenuOpen = !isMenuOpen)}
				>
					<Menu class="h-5 w-5" />
				</button>
			</div>
		</div>
	</header>

	<!-- Mobile Menu -->
	{#if isMenuOpen}
		<div class="md:hidden border-b bg-white dark:bg-gray-950 p-4 space-y-4">
			{#if !isStorefront}
				<a
					href="/#features"
					class="block text-sm font-medium"
					onclick={() => (isMenuOpen = false)}>Features</a
				>
				<a
					href="/pricing"
					class="block text-sm font-medium"
					onclick={() => (isMenuOpen = false)}>Pricing</a
				>
			{:else}
				<a
					href="/shop"
					class="block text-sm font-medium"
					onclick={() => (isMenuOpen = false)}>Shop</a
				>
				<a
					href="/account"
					class="block text-sm font-medium"
					onclick={() => (isMenuOpen = false)}>Account</a
				>
			{/if}
		</div>
	{/if}

	<!-- Main Content -->
	<main class="flex-1">
		{@render children()}
	</main>

	<ChatWidget />

	<!-- Footer -->
	<footer class="border-t bg-white dark:bg-gray-950 py-6 md:py-0">
		<div
			class="container flex flex-col items-center justify-between gap-4 md:h-24 md:flex-row px-4 md:px-6"
		>
			<p
				class="text-center text-sm leading-loose text-muted-foreground md:text-left"
			>
				© 2026 Kemani. All rights reserved.
			</p>
		</div>
	</footer>
</div>
