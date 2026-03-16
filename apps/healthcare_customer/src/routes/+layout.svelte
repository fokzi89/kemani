<script lang="ts">
	import '../app.css';
	import { page } from '$app/stores';
	import { Home, Calendar, Users, User, FileText, Bell, Menu, X } from 'lucide-svelte';

	let { children } = $props();

	let mobileMenuOpen = $state(false);

	const navItems = [
		{ href: '/', label: 'Dashboard', icon: Home },
		{ href: '/consultations', label: 'Consultations', icon: Calendar },
		{ href: '/providers', label: 'Providers', icon: Users },
		{ href: '/prescriptions', label: 'Prescriptions', icon: FileText },
		{ href: '/profile', label: 'Profile', icon: User },
		{ href: '/notifications', label: 'Notifications', icon: Bell }
	];
</script>

<svelte:head>
	<title>Kemani Health - Customer Portal</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- Header -->
	<header class="bg-white shadow-sm sticky top-0 z-50">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<!-- Logo -->
				<div class="flex items-center">
					<a href="/" class="flex items-center gap-2">
						<div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center">
							<span class="text-white font-bold">K</span>
						</div>
						<span class="text-xl font-bold text-gray-900">Kemani Health</span>
					</a>
				</div>

				<!-- Desktop Navigation -->
				<nav class="hidden md:flex items-center gap-6">
					{#each navItems as item}
						<a
							href={item.href}
							class="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition {
								$page.url.pathname === item.href
									? 'bg-blue-50 text-blue-600'
									: 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
							}"
						>
							<svelte:component this={item.icon} class="w-4 h-4" />
							{item.label}
						</a>
					{/each}
				</nav>

				<!-- Mobile Menu Button -->
				<button
					class="md:hidden p-2 rounded-lg hover:bg-gray-100"
					onclick={() => mobileMenuOpen = !mobileMenuOpen}
				>
					{#if mobileMenuOpen}
						<X class="w-6 h-6" />
					{:else}
						<Menu class="w-6 h-6" />
					{/if}
				</button>
			</div>
		</div>

		<!-- Mobile Navigation -->
		{#if mobileMenuOpen}
			<div class="md:hidden border-t border-gray-200 bg-white">
				<nav class="px-4 py-4 space-y-2">
					{#each navItems as item}
						<a
							href={item.href}
							class="flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition {
								$page.url.pathname === item.href
									? 'bg-blue-50 text-blue-600'
									: 'text-gray-600 hover:bg-gray-100'
							}"
							onclick={() => mobileMenuOpen = false}
						>
							<svelte:component this={item.icon} class="w-5 h-5" />
							{item.label}
						</a>
					{/each}
				</nav>
			</div>
		{/if}
	</header>

	<!-- Main Content -->
	<main>
		{@render children()}
	</main>

	<!-- Footer (optional) -->
	<footer class="bg-white border-t border-gray-200 mt-auto">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
			<p class="text-center text-sm text-gray-500">
				&copy; {new Date().getFullYear()} Kemani Health. All rights reserved.
			</p>
		</div>
	</footer>
</div>
