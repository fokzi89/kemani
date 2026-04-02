<script lang="ts">
	import { enhance } from '$app/forms';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { ArrowRight, ShieldCheck, Mail, Lock, Phone } from 'lucide-svelte';

	// The tenant is identified by the host (Approach 2)
	export let data: { tenant: any };
	$: tenantSlug = data.tenant.slug;
	let storefront: any = null;
	let isLoading = false;
	let authMode: 'email' | 'phone' = 'email';

	onMount(async () => {
		try {
			const res = await fetch(`/api/marketplace/info`);
			const data = await res.json();
			if (data.storefront) {
				storefront = data.storefront;
				if (!storefront.banner_url) {
					storefront.banner_url = 'https://images.unsplash.com/photo-1576091160550-217359f51f8c?q=80&w=2000&auto=format&fit=crop';
				}
			}
		} catch (e) {
			console.error('Failed to load storefront info:', e);
		}
	});

	function handleSubmit() {
		isLoading = true;
		// Simulated auth call for now
		setTimeout(() => {
			isLoading = false;
			window.location.href = `/`;
		}, 1500);
	}
</script>

<svelte:head>
	<title>Sign In - {storefront?.business_name || 'Storefront'}</title>
</svelte:head>

<div class="min-h-screen flex text-gray-900 bg-[#F8FAFC]">
	<!-- Left Side: Auth Form -->
	<div class="flex-1 flex flex-col justify-center px-4 sm:px-6 lg:px-20 xl:px-24">
		<div class="mx-auto w-full max-w-sm lg:w-96">
			<!-- Branding -->
			<div class="flex flex-col items-center sm:items-start text-center sm:text-left mb-10">
				{#if storefront}
					<div class="h-14 w-14 bg-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-indigo-100 mb-6 group hover:scale-105 transition-transform duration-300">
						<ShieldCheck class="h-8 w-8 text-white group-hover:rotate-12 transition-transform duration-300" />
					</div>
					<h2 class="text-3xl font-black tracking-tight text-gray-900 mb-2">
						Welcome Back
					</h2>
					<p class="text-sm font-medium text-gray-500">
						Sign in to your {storefront.business_name} account to manage orders, prescriptions, and loyalty points.
					</p>
				{:else}
					<div class="h-14 w-14 bg-gray-200 rounded-2xl animate-pulse mb-6"></div>
					<div class="h-8 w-48 bg-gray-200 rounded animate-pulse mb-2"></div>
					<div class="h-4 w-64 bg-gray-200 rounded animate-pulse"></div>
				{/if}
			</div>

			<!-- Auth Tabs -->
			<div class="flex p-1 bg-white border border-gray-100 rounded-2xl shadow-sm mb-8">
				<button 
					onclick={() => authMode = 'email'} 
					class="flex-1 py-2.5 text-sm font-bold rounded-xl transition-all {authMode === 'email' ? 'bg-indigo-50 text-indigo-600 shadow-sm' : 'text-gray-400 hover:text-gray-900'}"
				>
					Email
				</button>
				<button 
					onclick={() => authMode = 'phone'} 
					class="flex-1 py-2.5 text-sm font-bold rounded-xl transition-all {authMode === 'phone' ? 'bg-indigo-50 text-indigo-600 shadow-sm' : 'text-gray-400 hover:text-gray-900'}"
				>
					Phone
				</button>
			</div>

			<!-- Form -->
			<form class="space-y-6" onsubmit={(e) => { e.preventDefault(); handleSubmit(); }}>
				{#if authMode === 'email'}
					<div class="relative group">
						<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
							<Mail class="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
						</div>
						<input
							type="email"
							placeholder="Email address"
							required
							class="block w-full pl-12 pr-4 py-4 bg-white border border-gray-200 rounded-2xl text-sm font-bold text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-4 focus:ring-indigo-50 focus:border-indigo-600 transition-all shadow-sm"
						/>
					</div>
				{:else}
					<div class="relative group">
						<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
							<Phone class="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
						</div>
						<input
							type="tel"
							placeholder="Phone number"
							required
							class="block w-full pl-12 pr-4 py-4 bg-white border border-gray-200 rounded-2xl text-sm font-bold text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-4 focus:ring-indigo-50 focus:border-indigo-600 transition-all shadow-sm"
						/>
					</div>
				{/if}

				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
						<Lock class="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
					</div>
					<input
						type="password"
						placeholder="Password"
						required
						class="block w-full pl-12 pr-4 py-4 bg-white border border-gray-200 rounded-2xl text-sm font-bold text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-4 focus:ring-indigo-50 focus:border-indigo-600 transition-all shadow-sm"
					/>
				</div>

				<div class="flex items-center justify-between">
					<label class="flex items-center gap-2 cursor-pointer group">
						<input type="checkbox" class="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
						<span class="text-xs font-bold text-gray-500 group-hover:text-gray-900 transition-colors">Remember me</span>
					</label>
					<a href="/auth/forgot" class="text-xs font-black text-indigo-600 hover:text-indigo-500 transition-colors">
						Forgot password?
					</a>
				</div>

				<button
					type="submit"
					disabled={isLoading}
					class="group relative w-full flex justify-center py-4 px-4 border border-transparent text-sm font-black rounded-2xl text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-4 focus:ring-indigo-100 shadow-xl shadow-indigo-200 transition-all disabled:opacity-70 disabled:cursor-not-allowed overflow-hidden mt-6"
				>
					<span class="absolute right-0 inset-y-0 flex items-center pr-4 transform group-hover:translate-x-1 transition-transform">
						<ArrowRight class="h-5 w-5 text-indigo-300" />
					</span>
					{isLoading ? 'Signing in...' : 'Sign in to Storefront'}
				</button>
			</form>

			<div class="mt-8 text-center border-t border-gray-100 pt-8">
				<p class="text-xs font-bold text-gray-500">
					Don't have an account?
					<a href="/auth/register" class="font-black text-indigo-600 hover:text-indigo-500 transition-colors ml-1">
						Create one now
					</a>
				</p>
			</div>
		</div>
	</div>

	<!-- Right Side: Imagery Banner -->
	{#if storefront?.banner_url}
		<div class="hidden lg:block relative w-0 flex-1 bg-gray-900 overflow-hidden">
			<img
				class="absolute inset-0 h-full w-full object-cover scale-105 opacity-60"
				src={storefront.banner_url}
				alt="Storefront Banner"
			/>
			<div class="absolute inset-0 bg-gradient-to-tr from-gray-900 via-indigo-900/40 to-transparent mix-blend-multiply"></div>
			
			<div class="absolute bottom-12 left-12 right-12 text-white">
				<h3 class="text-4xl font-black mb-4 uppercase tracking-tighter leading-none">
					{storefront.business_name}
				</h3>
				<p class="text-lg font-medium text-gray-200 max-w-lg mb-8">
					{storefront.description || 'Welcome back. Experience seamless shopping, exclusive deals, and premium products.'}
				</p>
				<div class="flex items-center gap-4">
					<div class="h-12 w-12 bg-white/10 backdrop-blur-md rounded-full flex items-center justify-center border border-white/20">
						<ShieldCheck class="h-6 w-6 text-white" />
					</div>
					<div class="text-sm font-black tracking-widest uppercase">Secure Portal</div>
				</div>
			</div>
		</div>
	{/if}
</div>
