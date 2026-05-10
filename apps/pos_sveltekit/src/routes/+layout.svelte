<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { Menu, X } from 'lucide-svelte';
	import Sidebar from '$lib/components/Sidebar.svelte';
	import NotificationBell from '$lib/components/NotificationBell.svelte';

	let user = $state(null);
	let tenant = $state(null);
	let loading = $state(true);
	let redirecting = $state(false);
	let mobileMenuOpen = $state(false);
	let userDataCache = $state(null);
	let initialCheckDone = $state(false);
	let realtimeChannel = $state(null);
	let lastProcessedId = $state('');
	let lastSyncTime = 0;
	let isSyncing = false;

	const INACTIVITY_LIMIT = 5 * 60 * 1000;
	let inactivityTimer: any = null;
	let lastActivity = Date.now();

	$effect(() => {
		const currentPath = $page.url.pathname;
		if (redirecting) {
			const isAuthPath = currentPath.startsWith('/auth');
			const isOnboardingPath = currentPath.startsWith('/onboarding');
			if (!user && isAuthPath) redirecting = false;
			if (user && !userDataCache?.onboarding_done && isOnboardingPath) redirecting = false;
			if (user && userDataCache?.onboarding_done && !isAuthPath && !isOnboardingPath) redirecting = false;
		}
		if (initialCheckDone) {
			supabase.auth.getSession().then(({ data: { session } }) => {
				syncAuthState(session, currentPath);
			});
		}
	});

	async function syncAuthState(session: any, currentPath: string) {
		const now = Date.now();
		const userId = session?.user?.id;

		if (isSyncing) return;
		if (userId && lastProcessedId === userId && (now - lastSyncTime < 30000)) {
			loading = false;
			initialCheckDone = true;
			redirecting = false;
			return;
		}

		isSyncing = true;
		try {
			const isAuthPath = currentPath.startsWith('/auth');
			const isOnboardingPath = currentPath.startsWith('/onboarding');
			const isSelectTenantPath = currentPath === '/auth/select-tenant';

			if (!session) {
				user = null; tenant = null; userDataCache = null;
				lastProcessedId = ''; lastSyncTime = 0;
				if (!isAuthPath) { redirecting = true; goto('/auth/login'); }
				else { redirecting = false; loading = false; }
				initialCheckDone = true;
				return;
			}

			user = session.user;

			// Try cache first
			const cachedProfile = localStorage.getItem(`pos_user_profile_${userId}`);
			if (cachedProfile) {
				try { userDataCache = JSON.parse(cachedProfile); } catch {}
			}

			const activeTenantId = localStorage.getItem('active_tenant_id');

			// Fetch identity + memberships in parallel
			const [profileResult, membershipsResult] = await Promise.all([
				supabase
					.from('users')
					.select('id, email, full_name, phone, avatar_url, profile_picture_url, gender, pharmacist_reg_num, pharmacist_license_url, pharmacist_verified')
					.eq('id', userId)
					.maybeSingle(),
				supabase
					.from('user_tenants')
					.select('*, tenants!tenant_id(id, name, logo_url, slug), branches!branch_id(id, name, city, state, country)')
					.eq('user_id', userId)
					.eq('is_active', true)
					.is('deleted_at', null)
					.order('joined_at', { ascending: true })
			]);

			const memberships: any[] = membershipsResult.data || [];

			if (profileResult.data && memberships.length > 0) {
				// Multi-tenant: redirect to picker if no active tenant chosen
				if (memberships.length > 1 && !activeTenantId && !isAuthPath && !isOnboardingPath && !isSelectTenantPath) {
					localStorage.setItem('pending_tenant_memberships', JSON.stringify(memberships));
					redirecting = true;
					goto('/auth/select-tenant');
					return;
				}

				const activeMembership = memberships.find(m => m.tenant_id === activeTenantId) || memberships[0];

				userDataCache = {
					...profileResult.data,
					tenant_id: activeMembership.tenant_id,
					branch_id: activeMembership.branch_id,
					role: activeMembership.role,
					onboarding_done: activeMembership.onboarding_done,
					tenants: activeMembership.tenants,
					branches: activeMembership.branches,
					canManagePOS: activeMembership.canManagePOS,
					canManageProducts: activeMembership.canManageProducts,
					canManageCustomers: activeMembership.canManageCustomers,
					canManageOrders: activeMembership.canManageOrders,
					canViewMessages: activeMembership.canViewMessages,
					canViewAnalytics: activeMembership.canViewAnalytics,
					canManageStaff: activeMembership.canManageStaff,
					canManageInventory: activeMembership.canManageInventory,
					canManageTransfer: activeMembership.canManageTransfer,
					canManageBranches: activeMembership.canManageBranches,
					canManageRoles: activeMembership.canManageRoles,
					canTransferProduct: activeMembership.canTransferProduct,
					canReturnProducts: activeMembership.canReturnProducts,
					canCreatePrescription: activeMembership.canCreatePrescription,
					canApplyDiscount: activeMembership.canApplyDiscount,
					canReferDoctor: activeMembership.canReferDoctor,
					canManageExpenses: activeMembership.canManageExpenses,
					all_memberships: memberships
				};

				localStorage.setItem('active_tenant_id', activeMembership.tenant_id);
				localStorage.setItem(`pos_user_profile_${userId}`, JSON.stringify(userDataCache));
				lastProcessedId = userId;
				lastSyncTime = Date.now();

				if (!realtimeChannel) {
					realtimeChannel = supabase.channel(`user-tenants-${userId}`)
						.on('postgres_changes', {
							event: 'UPDATE', schema: 'public', table: 'user_tenants',
							filter: `user_id=eq.${userId}`
						}, (payload) => {
							if (userDataCache && payload.new.tenant_id === userDataCache.tenant_id) {
								userDataCache = { ...userDataCache, ...payload.new };
							}
						}).subscribe();
				}

				const branch = activeMembership.branches
					? (Array.isArray(activeMembership.branches) ? activeMembership.branches[0] : activeMembership.branches)
					: null;
				if (branch) {
					localStorage.setItem('pos_city', branch.city || '');
					localStorage.setItem('pos_state', branch.state || '');
					localStorage.setItem('pos_country', branch.country || '');
				}
			}

			// Routing
			if (userDataCache?.onboarding_done) {
				tenant = Array.isArray(userDataCache.tenants) ? userDataCache.tenants[0] : userDataCache.tenants;
				redirecting = false;
				if (isAuthPath || isOnboardingPath) {
					redirecting = true;
					if (userDataCache.role === 'cashier') {
						if (window.location.pathname !== '/pos') goto('/pos');
					} else if (userDataCache.role === 'pharmacist') {
						if (window.location.pathname !== '/messages') goto('/messages');
					} else {
						if (window.location.pathname !== '/') goto('/');
					}
				}
			} else if (userDataCache) {
				tenant = null;
				if (!isAuthPath && !isOnboardingPath) {
					redirecting = true;
					const onboardingPath = userDataCache.role === 'pharmacist' ? '/onboarding/pharmacist' : '/onboarding';
					if (window.location.pathname !== onboardingPath) goto(onboardingPath);
				} else {
					redirecting = false;
				}
			} else {
				tenant = null;
				redirecting = true;
				if (window.location.pathname !== '/auth/login') goto('/auth/login');
			}
		} catch (err) {
			console.error('[Layout] Sync error:', err);
			loading = false;
			redirecting = false;
		} finally {
			isSyncing = false;
			initialCheckDone = true;
			loading = false;
		}
	}

	async function handleLogout() {
		localStorage.removeItem('active_tenant_id');
		localStorage.removeItem('pending_tenant_memberships');
		await supabase.auth.signOut();
		goto('/auth/login');
	}

	function resetInactivityTimer() { lastActivity = Date.now(); }
	function checkInactivity() {
		if (user && !redirecting && !loading && Date.now() - lastActivity > INACTIVITY_LIMIT) {
			handleLogout();
		}
	}

	onMount(() => {
		inactivityTimer = setInterval(checkInactivity, 10000);
		window.addEventListener('mousemove', resetInactivityTimer);
		window.addEventListener('keydown', resetInactivityTimer);
		window.addEventListener('click', resetInactivityTimer);
		window.addEventListener('scroll', resetInactivityTimer);

		if ($page.url.searchParams.get('logout') === 'true') {
			supabase.auth.signOut().then(() => { window.location.href = '/auth/login'; });
			return;
		}

		const safetyTimeout = setTimeout(() => {
			if (loading) { loading = false; redirecting = false; }
		}, 15000);

		supabase.auth.getSession().then(({ data: { session } }) => {
			syncAuthState(session, window.location.pathname);
		}).catch(() => {
			loading = false;
			initialCheckDone = true;
			redirecting = false;
		});

		const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
			const userId = session?.user?.id;
			if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || event === 'INITIAL_SESSION' ||
				(event === 'TOKEN_REFRESHED' && userId !== lastProcessedId)) {
				syncAuthState(session, window.location.pathname);
			}
		});

		return () => {
			clearTimeout(safetyTimeout);
			if (inactivityTimer) clearInterval(inactivityTimer);
			window.removeEventListener('mousemove', resetInactivityTimer);
			window.removeEventListener('keydown', resetInactivityTimer);
			window.removeEventListener('click', resetInactivityTimer);
			window.removeEventListener('scroll', resetInactivityTimer);
			subscription.unsubscribe();
			if (realtimeChannel) supabase.removeChannel(realtimeChannel);
		};
	});

	function toggleMobileMenu() { mobileMenuOpen = !mobileMenuOpen; }
</script>

{#if loading || redirecting}
	<div class="flex items-center justify-center min-h-screen bg-gray-50">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
	</div>
{:else if user && tenant && !$page.url.pathname.startsWith('/auth') && !$page.url.pathname.startsWith('/onboarding') && !$page.url.pathname.endsWith('/print')}
	<div class="min-h-screen bg-gray-50 flex">
		<div class="lg:hidden fixed top-0 left-0 right-0 bg-white shadow-sm z-50 h-16 flex items-center px-4 print:hidden">
			<button onclick={toggleMobileMenu} class="p-2 rounded-md text-gray-600 hover:text-gray-900 hover:bg-gray-100">
				{#if mobileMenuOpen}<X class="h-6 w-6" />{:else}<Menu class="h-6 w-6" />{/if}
			</button>
			<div class="flex-1 ml-3">
				<h1 class="text-lg font-bold text-gray-900 truncate">{tenant.name || 'Kemani POS'}</h1>
			</div>
			{#if tenant?.id}<NotificationBell tenantId={tenant.id} />{/if}
		</div>

		{#if mobileMenuOpen}
			<div class="lg:hidden fixed inset-0 bg-black bg-opacity-50 z-40 print:hidden" onclick={toggleMobileMenu}></div>
		{/if}

		<aside class="hidden lg:block w-64 flex-shrink-0 bg-white border-r border-gray-200 h-screen sticky top-0 z-40 print:hidden">
			<Sidebar {tenant} userData={userDataCache} email={user.email} {handleLogout} />
		</aside>

		<div class="lg:hidden fixed top-0 left-0 h-full w-64 bg-white shadow-xl z-50 transform transition-all duration-300 print:hidden {mobileMenuOpen ? 'translate-x-0' : '-translate-x-full'}">
			<Sidebar {tenant} userData={userDataCache} email={user.email} {handleLogout} onnavclick={toggleMobileMenu} />
		</div>

		<main class="flex-1 overflow-y-auto lg:pt-0 pt-16 print:pt-0">
			<slot />
		</main>
	</div>
{:else if user && tenant && !$page.url.pathname.startsWith('/auth') && !$page.url.pathname.startsWith('/onboarding') && $page.url.pathname.endsWith('/print')}
	<slot />
{:else if user && !tenant && !$page.url.pathname.startsWith('/auth') && !$page.url.pathname.startsWith('/onboarding')}
	<div class="flex items-center justify-center min-h-screen bg-gray-50">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
	</div>
{:else}
	<slot />
{/if}
