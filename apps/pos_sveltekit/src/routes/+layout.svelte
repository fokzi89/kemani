<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import {
		LayoutDashboard,
		Package,
		Users,
		ShoppingCart,
		BarChart3,
		Settings,
		Menu,
		X,
		LogOut,
		Store
	} from 'lucide-svelte';

	let user = $state(null);
	let tenant = $state(null);
	let loading = $state(true);
	let mobileMenuOpen = $state(false);

	const navigation = [
		{ name: 'Dashboard', href: '/', icon: LayoutDashboard },
		{ name: 'POS', href: '/pos', icon: Store },
		{ name: 'Products', href: '/products', icon: Package },
		{ name: 'Customers', href: '/customers', icon: Users },
		{ name: 'Orders', href: '/orders', icon: ShoppingCart },
		{ name: 'Analytics', href: '/analytics', icon: BarChart3 },
		{ name: 'Settings', href: '/settings', icon: Settings }
	];

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();

		if (!session && !$page.url.pathname.startsWith('/auth')) {
			goto('/auth/login');
			return;
		}

		if (session) {
			user = session.user;

			// Get tenant/business info
			const { data: userData } = await supabase
				.from('users')
				.select('*, tenants(*)')
				.eq('id', session.user.id)
				.single();

			if (userData?.tenants) {
				tenant = userData.tenants;
			}
		}

		loading = false;
	});

	async function handleLogout() {
		await supabase.auth.signOut();
		goto('/auth/login');
	}

	function toggleMobileMenu() {
		mobileMenuOpen = !mobileMenuOpen;
	}
</script>

{#if loading}
	<div class="flex items-center justify-center min-h-screen bg-gray-50">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
	</div>
{:else if user && tenant && !$page.url.pathname.startsWith('/auth')}
	<!-- Main POS Dashboard Layout -->
	<div class="min-h-screen bg-gray-50 flex">
		<!-- Mobile Header -->
		<div class="lg:hidden fixed top-0 left-0 right-0 bg-white shadow-sm z-50 h-16 flex items-center px-4">
			<button
				onclick={toggleMobileMenu}
				class="p-2 rounded-md text-gray-600 hover:text-gray-900 hover:bg-gray-100"
			>
				{#if mobileMenuOpen}
					<X class="h-6 w-6" />
				{:else}
					<Menu class="h-6 w-6" />
				{/if}
			</button>
			<h1 class="text-lg font-bold text-gray-900 ml-3">
				{tenant.business_name || 'Kemani POS'}
			</h1>
		</div>

		<!-- Mobile Menu Overlay -->
		{#if mobileMenuOpen}
			<div
				class="lg:hidden fixed inset-0 bg-black bg-opacity-50 z-40"
				onclick={toggleMobileMenu}
			></div>
		{/if}

		<!-- Sidebar -->
		<aside class="hidden lg:flex lg:flex-col w-64 flex-shrink-0 bg-white border-r border-gray-200 h-screen sticky top-0">
			<!-- Brand -->
			<div class="p-4 border-b">
				<h1 class="text-xl font-bold text-gray-900">{tenant.business_name || 'Kemani POS'}</h1>
				<p class="text-sm text-gray-500">{tenant.business_type || 'Retail Store'}</p>
			</div>

			<!-- Navigation -->
			<nav class="p-4 space-y-1 flex-1 overflow-y-auto">
				{#each navigation as item}
					{@const Icon = item.icon}
					<a
						href={item.href}
						class="flex items-center gap-3 px-3 py-2 rounded-md transition-colors {$page.url.pathname === item.href ? 'bg-primary-50 text-primary-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
					>
						<Icon class="h-5 w-5" />
						{item.name}
					</a>
				{/each}
			</nav>

			<!-- Logout -->
			<div class="p-4 border-t">
				<button
					onclick={handleLogout}
					class="w-full flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-md transition-colors"
				>
					<LogOut class="h-4 w-4" />
					Logout
				</button>
			</div>
		</aside>

		<!-- Mobile Sidebar -->
		<div
			class="lg:hidden fixed top-0 left-0 h-full w-64 bg-white shadow-xl z-50 transform transition-all duration-300 {mobileMenuOpen ? 'translate-x-0' : '-translate-x-full'}"
		>
			<div class="p-4 border-b">
				<h1 class="text-xl font-bold text-gray-900">{tenant.business_name || 'Kemani POS'}</h1>
				<p class="text-sm text-gray-500">{tenant.business_type || 'Retail Store'}</p>
			</div>

			<nav class="p-4 space-y-1 flex-1 overflow-y-auto" style="max-height: calc(100vh - 200px);">
				{#each navigation as item}
					{@const Icon = item.icon}
					<a
						href={item.href}
						onclick={toggleMobileMenu}
						class="flex items-center gap-3 px-3 py-2 rounded-md transition-colors {$page.url.pathname === item.href ? 'bg-primary-50 text-primary-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
					>
						<Icon class="h-5 w-5" />
						{item.name}
					</a>
				{/each}
			</nav>

			<div class="p-4 border-t">
				<button
					onclick={handleLogout}
					class="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-md transition-colors"
				>
					<LogOut class="h-4 w-4" />
					Logout
				</button>
			</div>
		</div>

		<!-- Main Content -->
		<main class="flex-1 overflow-y-auto lg:pt-0 pt-16">
			<slot />
		</main>
	</div>
{:else}
	<!-- Auth Pages -->
	<slot />
{/if}
