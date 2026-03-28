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
	let redirecting = $state(false);
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

	// Store the path to avoid unnecessary repeat fetches
	let lastCheckedPath = $state('');

	// Reactively check access whenever the route changes
	$effect(() => {
		const currentPath = $page.url.pathname;
		if (lastCheckedPath !== currentPath) {
			lastCheckedPath = currentPath;
			supabase.auth.getSession().then(({ data: { session } }) => {
				checkUserAccess(session, currentPath);
			});
		}
	});

	let userDataCache = $state(null);

	let initialCheckDone = $state(false);

	async function checkUserAccess(session: any, currentPath: string) {
		const isAuthPath = currentPath.startsWith('/auth');
		if (!initialCheckDone || !isAuthPath) {
			loading = true;
		}

		if (!session && !isAuthPath) {
			console.log('[Layout] No session, redirecting to login');
			redirecting = true;
			goto('/auth/login');
			return; // The next route change will clear loading
		}

		if (session) {
			user = session.user;
			console.log('[Layout] Auth valid. Fetching profile for:', user.email);

			const { data: userData, error: userError } = await supabase
				.from('users')
				.select(`
					*, 
					tenants:tenants!users_tenant_id_fkey(*)
				`)
				.eq('id', session.user.id)
				.maybeSingle();
			
			if (userError) {
				console.error('[Layout] Profile fetch error:', userError);
			}

			userDataCache = userData;

			if (userData?.onboarding_done) {
				console.log('[Layout] Full access granted.');
				// The payload returns "tenants" key when aliased this way if using aliases, 
				// but when using exclamation mark notation, it replaces the key as "tenants" or "tenants_users_tenant_id_fkey"? 
				// Supabase JS maps the exclamation mark notation directly to the top level name if it matches the table!
				tenant = Array.isArray(userData.tenants) ? userData.tenants[0] : userData.tenants;
				redirecting = false;
				
				// Re-route from auth or onboarding to dashboard if already logged in fully
				if (currentPath.startsWith('/auth') || currentPath.startsWith('/onboarding')) {
					redirecting = true;
				    goto('/');
					return;
				}
			} else {
				console.log('[Layout] Setup incomplete.');
				tenant = null;
				
				const isAuthPath = currentPath.startsWith('/auth');
				const isOnboardingPath = currentPath.startsWith('/onboarding');
				
				// Re-route them from dashboard/app to onboarding if not done
				if (!isAuthPath && !isOnboardingPath) {
					console.log('[Layout] Redirecting to onboarding.');
					redirecting = true;
					goto('/onboarding');
					return; // The next route change will clear loading
				} else if (isAuthPath) {
					// Pushing from auth page to onboarding if incomplete
					if (currentPath === '/auth/signup' || currentPath === '/auth/login') {
						console.log('[Layout] Have session, moving from auth to onboarding.');
						redirecting = true;
						goto('/onboarding');
						return; // The next route change will clear loading
					} else {
						redirecting = false;
					}
				} else {
					// We are on /onboarding
					redirecting = false;
				}
			}
		} else {
			user = null;
			tenant = null;
			userDataCache = null;
			redirecting = false;
		}
		
		
		initialCheckDone = true;
		loading = false;
	}

	onMount(() => {
		// Initial check
		supabase.auth.getSession().then(({ data: { session } }) => {
			checkUserAccess(session, window.location.pathname);
		});

		// Listen for sign-in, sign-out, or token refreshes dynamically
		const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
			console.log('[Layout] Auth Event:', event);
			if (event === 'SIGNED_IN' || event === 'SIGNED_OUT') {
				checkUserAccess(session, window.location.pathname);
			}
		});

		return () => subscription.unsubscribe();
	});

	async function handleLogout() {
		await supabase.auth.signOut();
		goto('/auth/login');
	}

	function toggleMobileMenu() {
		mobileMenuOpen = !mobileMenuOpen;
	}
</script>

{#if loading || redirecting}
	<div class="flex items-center justify-center min-h-screen bg-gray-50">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
	</div>
{:else if user && tenant && !$page.url.pathname.startsWith('/auth') && !$page.url.pathname.startsWith('/onboarding')}
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
				{tenant.name || 'Kemani POS'}
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
				<h1 class="text-xl font-bold text-gray-900">{tenant.name || 'Kemani POS'}</h1>
				<p class="text-sm text-gray-500">Business Dashboard</p>
			</div>

			<!-- Navigation -->
			<nav class="p-4 space-y-1 flex-1 overflow-y-auto">
				{#each navigation as item}
					{@const Icon = item.icon}
					<a
						href={item.href}
						class="flex items-center gap-3 px-3 py-2 rounded-md transition-colors {$page.url.pathname === item.href ? 'bg-indigo-50 text-indigo-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
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
				<h1 class="text-xl font-bold text-gray-900">{tenant.name || 'Kemani POS'}</h1>
				<p class="text-sm text-gray-500">Business Dashboard</p>
			</div>

			<nav class="p-4 space-y-1 flex-1 overflow-y-auto" style="max-height: calc(100vh - 200px);">
				{#each navigation as item}
					{@const Icon = item.icon}
					<a
						href={item.href}
						onclick={toggleMobileMenu}
						class="flex items-center gap-3 px-3 py-2 rounded-md transition-colors {$page.url.pathname === item.href ? 'bg-indigo-50 text-indigo-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
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
{:else if user && !tenant && !$page.url.pathname.startsWith('/auth') && !$page.url.pathname.startsWith('/onboarding')}
	<!-- Transition to Onboarding -->
	<div class="flex items-center justify-center min-h-screen bg-gray-50">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
	</div>
{:else}
	<!-- Auth Pages or Onboarding -->
	<slot />
{/if}
