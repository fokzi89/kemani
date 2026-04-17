<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { goto, afterNavigate } from '$app/navigation';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import {
		LayoutDashboard,
		Calendar,
		FileText,
		BarChart3,
		DollarSign,
		Users,
		MessageSquare,
		User,
		LogOut,
		Menu,
		X,
		Settings,
		FlaskConical,
		Home,
		Building,
		Handshake,
		Star
	} from 'lucide-svelte';

	let user = $state<any>(null);
	let provider = $state<any>(null);
	let loading = $state(true);
	let mobileDrawerOpen = $state(false);

	// Global Idle tracking
	let globalIdleTimer: ReturnType<typeof setTimeout>;
	let idleTimeoutMs = $state(30 * 60 * 1000); // 30 mins default

	$effect(() => {
		if (typeof window !== 'undefined') {
			if (provider && provider.idle_timeout_minutes) {
				idleTimeoutMs = provider.idle_timeout_minutes * 60 * 1000;
				setupGlobalIdleTracking();
			} else if (user) {
				setupGlobalIdleTracking();
			} else {
				cleanupGlobalIdleTracking();
			}
		}
		
		return () => {
			cleanupGlobalIdleTracking();
		};
	});

	function resetGlobalIdleTimer() {
		if ($page.url.pathname.startsWith('/auth')) return;
		if (!user) return;

		if (globalIdleTimer) clearTimeout(globalIdleTimer);
		globalIdleTimer = setTimeout(async () => {
			await supabase.auth.signOut();
			goto('/auth/login?reason=timeout');
		}, idleTimeoutMs);
	}

	function setupGlobalIdleTracking() {
		cleanupGlobalIdleTracking();
		resetGlobalIdleTimer();
		
		if (typeof window !== 'undefined') {
			const events = ['mousemove', 'keydown', 'scroll', 'touchstart', 'click'];
			events.forEach(evt => window.addEventListener(evt, resetGlobalIdleTimer));
		}
	}

	function cleanupGlobalIdleTracking() {
		if (globalIdleTimer) clearTimeout(globalIdleTimer);
		if (typeof window !== 'undefined') {
			const events = ['mousemove', 'keydown', 'scroll', 'touchstart', 'click'];
			events.forEach(evt => window.removeEventListener(evt, resetGlobalIdleTimer));
		}
	}

	// Full navigation for desktop sidebar and mobile drawer
	const fullNavigation = [
		{ name: 'Dashboard', href: '/', icon: LayoutDashboard },
		{ name: 'My Patients', href: '/patients', icon: Users },
		{ name: 'Consultations', href: '/consultations', icon: Calendar },
		{ name: 'Prescriptions', href: '/prescriptions', icon: FileText },
		{ name: 'Lab Requests', href: '/lab-requests', icon: FlaskConical },
		{ name: 'Messages', href: '/chats', icon: MessageSquare },
		{ name: 'Commissions', href: '/commissions', icon: DollarSign },
		{ name: 'Analytics', href: '/analytics', icon: BarChart3 },
		{ name: 'Reviews', href: '/reviews', icon: Star },
		{ name: 'Clinic', href: '/clinic', icon: Building },
		{ name: 'Partners', href: '/partners', icon: Handshake },
		{ name: 'Settings', href: '/settings', icon: Settings }
	];

	// Mobile bottom navigation (only key items)
	const mobileBottomNav = [
		{ name: 'Home', href: '/', icon: Home },
		{ name: 'Patients', href: '/patients', icon: Users },
		{ name: 'Consultations', href: '/consultations', icon: Calendar },
		{ name: 'Prescriptions', href: '/prescriptions', icon: FileText },
		{ name: 'Settings', href: '/settings', icon: Settings }
	];

	onMount(async () => {
		// Check authentication
		const { data } = await supabase.auth.getSession();
		const session = data?.session;

		if (session) {
			user = session.user;

			// Get provider profile
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();

			provider = providerData;
		}

		// Redirect to login if not authenticated and not on auth page
		if (!session) {
			if (!$page.url.pathname.startsWith('/auth')) {
				goto('/auth/login');
			}
		} else {
			// If authenticated but no provider profile, redirect to onboarding
			if (!provider && !$page.url.pathname.startsWith('/auth') && !$page.url.pathname.startsWith('/onboarding')) {
				goto('/onboarding');
			} else if (provider && !$page.url.pathname.startsWith('/onboarding') && !$page.url.pathname.startsWith('/auth')) {
				// Check if current provider has completed onboarding
				const isOnboardingComplete = provider.phone && 
					provider.specialization && 
					provider.bio && 
					provider.clinic_address;
					
				if (!isOnboardingComplete && !$page.url.pathname.startsWith('/onboarding')) {
					goto('/onboarding');
				}
			}
		}

		loading = false;

		// Listen for auth changes
		supabase.auth.onAuthStateChange(async (event, session) => {
			if (event === 'SIGNED_IN' && session) {
				user = session.user;

				// Get provider profile
				const { data: providerData } = await supabase
					.from('healthcare_providers')
					.select('*')
					.eq('user_id', session.user.id)
					.single();

				provider = providerData;

				// Only redirect if specifically on an auth page during sign-in
				if ($page.url.pathname.startsWith('/auth')) {
					if (providerData) {
						const isOnboardingComplete = providerData.phone &&
							providerData.specialization &&
							providerData.bio &&
							providerData.clinic_address;

						if (!isOnboardingComplete) {
							goto('/onboarding');
						} else {
							goto('/');
						}
					} else {
						goto('/onboarding');
					}
				}
			} else if (event === 'SIGNED_OUT') {
				user = null;
				provider = null;
				goto('/auth/login');
			}
		});
	});

	afterNavigate(async ({ from }) => {
		if (from?.url.pathname.startsWith('/onboarding') && user) {
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', user.id)
				.single();
			if (providerData) {
				provider = providerData;
			}
		}
	});

	async function handleLogout() {
		await supabase.auth.signOut();
	}

	function toggleMobileDrawer() {
		mobileDrawerOpen = !mobileDrawerOpen;
	}
</script>

{#if loading}
	<div class="min-h-screen flex items-center justify-center bg-gray-50">
		<div class="text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading...</p>
		</div>
	</div>
{:else if user && provider && !$page.url.pathname.startsWith('/onboarding') && !$page.url.pathname.startsWith('/lab-requests/add') && !$page.url.pathname.startsWith('/lab-requests/edit')}
	<!-- Provider Dashboard Layout with Sidebar -->
	<div class="min-h-screen bg-gray-50 flex">
		<!-- Desktop Sidebar - Always visible on lg+ screens -->
		<aside class="w-64 flex-shrink-0 bg-white border-r border-gray-200 h-screen sticky top-0 hidden lg:flex lg:flex-col">
			<!-- Logo/Brand -->
			<div class="p-4 border-b">
				<h1 class="text-xl font-bold text-primary-600">Healthcare Portal</h1>
			</div>
			
			<!-- Profile Section -->
			<div class="p-4 border-b">
				<div class="flex items-center gap-3">
					{#if provider?.profile_photo_url}
						<img
							src={provider.profile_photo_url}
							alt={provider.full_name}
							class="h-10 w-10 rounded-full object-cover"
						/>
					{:else}
						<div class="h-10 w-10 rounded-full bg-primary-100 flex items-center justify-center">
							<User class="h-6 w-6 text-primary-600" />
						</div>
					{/if}
					<div class="flex-1 min-w-0">
						<p class="text-sm font-semibold text-gray-900 truncate">{provider?.full_name}</p>
						<p class="text-xs text-gray-500 truncate">{provider?.specialization}</p>
					</div>
				</div>
			</div>

			<!-- Navigation -->
			<nav class="flex-1 p-4 space-y-1 overflow-y-auto">
				{#each fullNavigation as item}
					{@const Icon = item.icon}
					<a
						href={item.href}
						data-sveltekit-preload-data="hover"
						class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors {$page.url.pathname === item.href ? 'bg-primary-50 text-primary-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
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
					class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
				>
					<LogOut class="h-4 w-4" />
					Logout
				</button>
			</div>
		</aside>

		<!-- Main Content Area -->
		<div class="flex-1 flex flex-col min-w-0">
			<!-- Mobile Header -->
			<header class="lg:hidden bg-white border-b border-gray-200 h-16 flex items-center px-4 sticky top-0 z-40">
				<button
					onclick={toggleMobileDrawer}
					class="p-2 -ml-2 rounded-md text-gray-600 hover:bg-gray-100"
				>
					{#if mobileDrawerOpen}
						<X class="h-6 w-6" />
					{:else}
						<Menu class="h-6 w-6" />
					{/if}
				</button>
				<span class="ml-3 font-semibold text-gray-900">Healthcare Portal</span>
			</header>

			<!-- Main Content -->
			<main class="flex-1 overflow-y-auto overflow-x-hidden pb-20 lg:pb-0 min-w-0">
				<slot />
			</main>

			<!-- Mobile Bottom Navigation -->
			<nav class="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-40">
				<div class="flex justify-around items-center h-16">
					{#each mobileBottomNav as item}
						{@const Icon = item.icon}
						<a
							href={item.href}
							data-sveltekit-preload-data="hover"
							class="flex flex-col items-center justify-center gap-1 px-3 py-2 flex-1 transition-colors {$page.url.pathname === item.href ? 'text-primary-600' : 'text-gray-600 hover:text-primary-600'}"
						>
							<Icon class="h-6 w-6" />
							<span class="text-xs font-medium">{item.name}</span>
						</a>
					{/each}
				</div>
			</nav>
		</div>

		<!-- Mobile Drawer Overlay -->
		{#if mobileDrawerOpen}
			<div
				class="lg:hidden fixed inset-0 bg-black bg-opacity-50 z-40"
				onclick={toggleMobileDrawer}
			></div>
		{/if}

		<!-- Mobile Drawer -->
		<div
			class="lg:hidden fixed top-0 
			top-0 left-0 h-full w-72 bg-white shadow-xl z-50 transform transition-transform duration-300 {mobileDrawerOpen ? 'translate-x-0' : '-translate-x-full'}"
		>
			<!-- Drawer Header -->
			<div class="p-4 border-b">
				<h1 class="text-lg font-bold text-primary-600">Healthcare Portal</h1>
			</div>
			
			<!-- Drawer Profile -->
			<div class="p-4 border-b">
				<div class="flex items-center gap-3">
					{#if provider?.profile_photo_url}
						<img
							src={provider.profile_photo_url}
							alt={provider.full_name}
							class="h-10 w-10 rounded-full object-cover"
						/>
					{:else}
						<div class="h-10 w-10 rounded-full bg-primary-100 flex items-center justify-center">
							<User class="h-6 w-6 text-primary-600" />
						</div>
					{/if}
					<div class="flex-1 min-w-0">
						<p class="text-sm font-semibold text-gray-900 truncate">{provider?.full_name}</p>
						<p class="text-xs text-gray-500 truncate">{provider?.specialization}</p>
					</div>
				</div>
			</div>

			<!-- Drawer Navigation -->
			<nav class="p-4 space-y-1">
				{#each fullNavigation as item}
					{@const Icon = item.icon}
					<a
						href={item.href}
						onclick={(e) => { toggleMobileDrawer(); }}
						data-sveltekit-preload-data="hover"
						class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors {$page.url.pathname === item.href ? 'bg-primary-50 text-primary-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
					>
						<Icon class="h-5 w-5" />
						{item.name}
					</a>
				{/each}
			</nav>

			<!-- Drawer Logout -->
			<div class="absolute bottom-0 left-0 right-0 p-4 border-t">
				<button
					onclick={handleLogout}
					class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
				>
					<LogOut class="h-4 w-4" />
					Logout
				</button>
			</div>
		</div>
	</div>
{:else}
	<!-- Auth Pages (no sidebar) -->
	<slot />
{/if}
