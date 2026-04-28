<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { Menu, X } from 'lucide-svelte';
	import Sidebar from '$lib/components/Sidebar.svelte';

	// Core state
	let user = $state(null);
	let tenant = $state(null);
	let loading = $state(true);
	let redirecting = $state(false);
	let mobileMenuOpen = $state(false);
	let userDataCache = $state(null);
	let initialCheckDone = $state(false);
	let realtimeChannel = $state(null);
	let lastProcessedId = $state('');
	let lastSyncTime = 0; // Throttle fetches

	// Atomic check to prevent race conditions
	let isSyncing = false;

	// Reactive effect for path changes
	$effect(() => {
		const currentPath = $page.url.pathname;
		console.log('[Layout] Path changed to:', currentPath);
		
		// If we are on the page we were redirecting to, we can stop the "redirecting" spinner
		// This is a safety measure in case syncAuthState didn't catch it
		if (redirecting) {
			const isAuthPath = currentPath.startsWith('/auth');
			const isOnboardingPath = currentPath.startsWith('/onboarding');
			
			// If we are where we need to be, stop the redirecting spinner
			if (!user && isAuthPath) redirecting = false;
			if (user && !userDataCache?.onboarding_done && isOnboardingPath) redirecting = false;
			if (user && userDataCache?.onboarding_done && !isAuthPath && !isOnboardingPath) redirecting = false;
		}

		// Re-sync on navigation to ensure auth state is correct for the new path
		if (initialCheckDone) {
			supabase.auth.getSession().then(({ data: { session } }) => {
				syncAuthState(session, currentPath);
			});
		}
	});

	async function syncAuthState(session: any, currentPath: string) {
		const start = performance.now();
		const now = Date.now();
		const userId = session?.user?.id;
		
		console.log(`[Layout] Sync started for ${currentPath}`, { hasSession: !!session });

		// If we're already syncing, or if we synced THIS user less than 30s ago, skip the heavy fetch
		if (isSyncing) {
			console.log('[Layout] Sync skipped: already syncing');
			return;
		}
		
		if (userId && lastProcessedId === userId && (now - lastSyncTime < 30000)) {
			console.log('[Layout] Sync throttled (synced recently)');
			loading = false;
			initialCheckDone = true;
			redirecting = false; // Ensure we reset redirecting if we are skipping
			return;
		}

		isSyncing = true;
		try {
			const isAuthPath = currentPath.startsWith('/auth');
			const isOnboardingPath = currentPath.startsWith('/onboarding');

			// 1. Handle No Session
			if (!session) {
				user = null;
				tenant = null;
				userDataCache = null;
				lastProcessedId = '';
				lastSyncTime = 0;
				
				if (!isAuthPath) {
					console.log('[Layout] No session, redirecting to login');
					redirecting = true;
					goto('/auth/login');
				} else {
					console.log('[Layout] No session, already on auth path');
					redirecting = false; // Reset redirecting if we've arrived
					loading = false;
				}
				initialCheckDone = true;
				return;
			}

			// 2. Handle Existing Session
			user = session.user;
			console.log('[Layout] Syncing profile for:', user.email);
			
			// Add a timeout to the profile fetch to prevent infinite loading if Supabase is slow
			const profilePromise = supabase
				.from('users')
				.select('*, tenants:tenants!users_tenant_id_fkey(*), branches:branches!users_branch_id_fkey(*)')
				.eq('id', userId)
				.maybeSingle();

			const timeoutPromise = new Promise((_, reject) => 
				setTimeout(() => reject(new Error('Profile fetch timeout')), 8000)
			);

			const { data, error } = await Promise.race([profilePromise, timeoutPromise]) as any;
			const fetchEnd = performance.now();
			console.log(`[Layout] Profile fetch took ${(fetchEnd - start).toFixed(2)}ms`);

			if (error) {
				console.error('[Layout] Profile error:', error);
			} else {
				userDataCache = data;
				lastProcessedId = userId;
				lastSyncTime = Date.now();
				
				// Setup Realtime if not present
				if (!realtimeChannel && data) {
					realtimeChannel = supabase.channel(`user-${userId}`)
						.on('postgres_changes', { 
							event: 'UPDATE', 
							schema: 'public', 
							table: 'users', 
							filter: `id=eq.${userId}` 
						}, (payload) => {
							if (userDataCache) userDataCache = { ...userDataCache, ...payload.new };
						}).subscribe();
				}
			}

			// 3. Routing Logic
			if (userDataCache?.onboarding_done) {
				tenant = Array.isArray(userDataCache.tenants) ? userDataCache.tenants[0] : userDataCache.tenants;
				redirecting = false;
				
				if (isAuthPath || isOnboardingPath) {
					console.log('[Layout] Logged in and onboarded, redirecting to home');
					redirecting = true;
					if (window.location.pathname !== '/') goto('/');
				}
			} else if (userDataCache) {
				tenant = null;
				if (!isAuthPath && !isOnboardingPath) {
					console.log('[Layout] Logged in but not onboarded, redirecting to onboarding');
					redirecting = true;
					if (window.location.pathname !== '/onboarding') goto('/onboarding');
				} else {
					redirecting = false;
				}
			} else {
				// Logged in but no profile data yet (or fetch failed/timed out)
				// Allow them to stay where they are but log the issue
				console.warn('[Layout] User logged in but no profile data found');
				redirecting = false;
			}
		} catch (err) {
			console.error('[Layout] Sync fatal error:', err);
			// On error, try to at least stop the loading spinner
			loading = false;
			redirecting = false;
		} finally {
			isSyncing = false;
			initialCheckDone = true;
			loading = false;
			const end = performance.now();
			console.log(`[Layout] Full sync cycle took ${(end - start).toFixed(2)}ms`);
		}
	}

	onMount(() => {
		console.log('[Layout] onMount started');
		
		// 0. Manual logout recovery
		if ($page.url.searchParams.get('logout') === 'true') {
			console.log('[Layout] Manual logout triggered');
			supabase.auth.signOut().then(() => {
				window.location.href = '/auth/login';
			});
			return;
		}

		// Safety fallback: if we are still loading after 15 seconds, force loading to false
		const safetyTimeout = setTimeout(() => {
			if (loading) {
				console.warn('[Layout] Safety timeout reached, forcing loading = false');
				loading = false;
				redirecting = false;
			}
		}, 15000);

		// Initial sync
		console.log('[Layout] Getting initial session...');
		supabase.auth.getSession().then(({ data: { session } }) => {
			console.log('[Layout] Initial session retrieved:', !!session);
			syncAuthState(session, window.location.pathname);
		}).catch(err => {
			console.error('[Layout] Failed to get initial session:', err);
			loading = false;
			initialCheckDone = true;
			redirecting = false;
		});

		// Listen for auth changes
		const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
			console.log('[Layout] Auth Event:', event);
			// Only sync on major events or if the userId changed
			const userId = session?.user?.id;
			if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || (event === 'TOKEN_REFRESHED' && userId !== lastProcessedId) || event === 'INITIAL_SESSION') {
				syncAuthState(session, window.location.pathname);
			}
		});

		return () => {
			clearTimeout(safetyTimeout);
			subscription.unsubscribe();
			if (realtimeChannel) supabase.removeChannel(realtimeChannel);
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
