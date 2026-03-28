<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { Menu, X } from 'lucide-svelte';
	import Sidebar from '$lib/components/Sidebar.svelte';

	let user = $state(null);
	let tenant = $state(null);
	let loading = $state(true);
	let redirecting = $state(false);
	let mobileMenuOpen = $state(false);



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
	let realtimeChannel = $state(null);

	async function checkUserAccess(session: any, currentPath: string) {
		const isAuthPath = currentPath.startsWith('/auth');
		if (!initialCheckDone) {
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
			if (!initialCheckDone || !userDataCache || userDataCache.id !== session.user.id) {
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

				// Subscribe to permissions dynamically
				if (!realtimeChannel) {
					realtimeChannel = supabase.channel('user-permissions')
						.on('postgres_changes', {
							event: 'UPDATE',
							schema: 'public',
							table: 'users',
							filter: `id=eq.${user.id}`
						}, (payload) => {
							console.log('Realtime updated permissions:', payload);
							if (userDataCache) {
								userDataCache = { ...userDataCache, ...payload.new };
							}
						}).subscribe();
				}
			}

			if (userDataCache?.onboarding_done) {
				console.log('[Layout] Full access granted.');
				// The payload returns "tenants" key when aliased this way if using aliases, 
				// but when using exclamation mark notation, it replaces the key as "tenants" or "tenants_users_tenant_id_fkey"? 
				// Supabase JS maps the exclamation mark notation directly to the top level name if it matches the table!
				tenant = Array.isArray(userDataCache.tenants) ? userDataCache.tenants[0] : userDataCache.tenants;
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

		return () => {
			subscription.unsubscribe();
			if (realtimeChannel) {
				supabase.removeChannel(realtimeChannel);
				realtimeChannel = null;
			}
		};
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
		<aside class="hidden lg:block w-64 flex-shrink-0 bg-white border-r border-gray-200 h-screen sticky top-0 overflow-hidden">
			<Sidebar {tenant} userData={userDataCache} email={user.email} {handleLogout} />
		</aside>

		<!-- Mobile Sidebar -->
		<div
			class="lg:hidden fixed top-0 left-0 h-full w-64 bg-white shadow-xl z-50 transform transition-all duration-300 {mobileMenuOpen ? 'translate-x-0' : '-translate-x-full'}"
		>
			<Sidebar {tenant} userData={userDataCache} email={user.email} {handleLogout} onnavclick={toggleMobileMenu} />
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
