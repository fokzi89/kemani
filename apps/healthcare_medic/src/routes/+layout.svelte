<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
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
		X
	} from 'lucide-svelte';

	let user = $state(null);
	let provider = $state(null);
	let loading = $state(true);
	let mobileMenuOpen = $state(false);

	const navigation = [
		{ name: 'Dashboard', href: '/', icon: LayoutDashboard },
		{ name: 'Patients', href: '/patients', icon: Users },
		{ name: 'Consultations', href: '/consultations', icon: Calendar },
		{ name: 'Prescriptions', href: '/prescriptions', icon: FileText },
		{ name: 'Messages', href: '/chats', icon: MessageSquare },
		{ name: 'Commissions', href: '/commissions', icon: DollarSign },
		{ name: 'Analytics', href: '/analytics', icon: BarChart3 },
		{ name: 'Availability', href: '/availability', icon: Calendar }
	];

	onMount(async () => {
		// Check authentication
		const { data: { session } } = await supabase.auth.getSession();

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

		loading = false;

		// Redirect to login if not authenticated and not on auth page
		if (!session && !$page.url.pathname.startsWith('/auth')) {
			goto('/auth/login');
		}

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
				goto('/');
			} else if (event === 'SIGNED_OUT') {
				user = null;
				provider = null;
				goto('/auth/login');
			}
		});
	});

	async function handleLogout() {
		await supabase.auth.signOut();
	}

	function toggleMobileMenu() {
		mobileMenuOpen = !mobileMenuOpen;
	}
</script>

{#if loading}
	<div class="min-h-screen flex items-center justify-center bg-gray-50">
		<div class="text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading...</p>
		</div>
	</div>
{:else if user && provider}
	<!-- Provider Dashboard Layout -->
	<div class="min-h-screen bg-gray-50">
		<!-- Header -->
		<header class="bg-white shadow-sm sticky top-0 z-50">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="flex justify-between items-center h-16">
					<!-- Logo & Title -->
					<div class="flex items-center">
						<button
							onclick={toggleMobileMenu}
							class="lg:hidden p-2 rounded-md text-gray-600 hover:bg-gray-100"
						>
							{#if mobileMenuOpen}
								<X class="h-6 w-6" />
							{:else}
								<Menu class="h-6 w-6" />
							{/if}
						</button>
						<h1 class="text-xl font-bold text-primary-600 ml-2 lg:ml-0">
							Healthcare Provider Portal
						</h1>
					</div>

					<!-- User Menu -->
					<div class="flex items-center gap-4">
						<div class="hidden sm:block text-right">
							<p class="text-sm font-medium text-gray-900">{provider.full_name}</p>
							<p class="text-xs text-gray-500">{provider.specialization}</p>
						</div>
						{#if provider.profile_photo_url}
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
						<button
							onclick={handleLogout}
							class="p-2 text-gray-600 hover:bg-gray-100 rounded-md"
							title="Logout"
						>
							<LogOut class="h-5 w-5" />
						</button>
					</div>
				</div>
			</div>
		</header>

		<!-- Mobile Navigation -->
		{#if mobileMenuOpen}
			<div class="lg:hidden bg-white border-b">
				<nav class="px-4 py-2 space-y-1">
					{#each navigation as item}
						<a
							href={item.href}
							onclick={toggleMobileMenu}
							class="flex items-center gap-3 px-3 py-2 rounded-md {$page.url.pathname === item.href ? 'bg-primary-50 text-primary-700' : 'text-gray-700 hover:bg-gray-100'}"
						>
							<svelte:component this={item.icon} class="h-5 w-5" />
							{item.name}
						</a>
					{/each}
				</nav>
			</div>
		{/if}

		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
			<div class="flex gap-8">
				<!-- Desktop Sidebar -->
				<aside class="hidden lg:block w-64 flex-shrink-0">
					<nav class="space-y-1 bg-white rounded-lg shadow p-4">
						{#each navigation as item}
							<a
								href={item.href}
								class="flex items-center gap-3 px-3 py-2 rounded-md transition-colors {$page.url.pathname === item.href ? 'bg-primary-50 text-primary-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
							>
								<svelte:component this={item.icon} class="h-5 w-5" />
								{item.name}
							</a>
						{/each}
					</nav>
				</aside>

				<!-- Main Content -->
				<main class="flex-1 min-w-0">
					<slot />
				</main>
			</div>
		</div>
	</div>
{:else}
	<!-- Auth Pages -->
	<slot />
{/if}
