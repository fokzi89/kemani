<script lang="ts">
	import { ShoppingCart, Search, User, Menu, X, ArrowRight, Instagram, Twitter, Facebook, MessageCircle, Send, ChevronDown, ShieldCheck } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, currentUser } from '$lib/stores/auth';
	import { isAuthModalOpen } from '$lib/stores/ui';
	import { supabase } from '$lib/supabase';

	export let data;

	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#4f46e5';
	$: brandColorLight = `${brandColor}15`;

	let isMenuOpen = false;
	let isScrolled = false;
	let cartCount = 0;
	let isChatOpen = false;
	let isAccountOpen = false;

	function toggleChat() { isChatOpen = !isChatOpen; }
	function toggleAccountMenu() { isAccountOpen = !isAccountOpen; }

	async function handleSignOut() {
		await supabase.auth.signOut();
		authStore.clearAuth();
		isAccountOpen = false;
		goto('/');
	}

	async function signInWithGoogle() {
		try {
			const { error } = await supabase.auth.signInWithOAuth({
				provider: 'google',
				options: {
					redirectTo: window.location.origin
				}
			});
			if (error) alert(error.message);
		} catch (err) {
			console.error('OAuth error:', err);
		}
	}

	onMount(() => {
		authStore.initialize();

		const handleScroll = () => { isScrolled = window.scrollY > 20; };
		window.addEventListener('scroll', handleScroll);

		const updateCart = () => {
			try {
				const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
				cartCount = cart.items.reduce((s: number, i: any) => s + i.quantity, 0);
			} catch { cartCount = 0; }
		};
		updateCart();
		window.addEventListener('storage', updateCart);

		return () => {
			window.removeEventListener('scroll', handleScroll);
			window.removeEventListener('storage', updateCart);
		};
	});

	function toggleMenu() { isMenuOpen = !isMenuOpen; }

	$: storeUrl = storefront?.subdomain 
		? `${storefront.subdomain}.kemani.io` 
		: `${storefront?.slug}.kemani.io`;

</script>

<svelte:head>
</svelte:head>

<div 
	class="min-h-screen flex flex-col font-body selection:bg-gray-100 selection:text-gray-900"
	style="--brand: {brandColor};"
>
	<!-- Navigation -->
	<nav 
		class="sticky top-0 z-50 transition-all duration-500 {isScrolled ? 'bg-white/80 backdrop-blur-md border-b border-gray-100 py-3' : 'bg-transparent py-6'}"
	>
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex items-center justify-between">
				<!-- Brand -->
				<a href="/" class="flex items-center gap-3 group">
					{#if storefront?.logo_url}
						<img src={storefront.logo_url} alt="logo" class="h-8 w-8 object-contain" />
					{:else}
						<div class="h-8 w-8 bg-gray-900 flex items-center justify-center text-white font-serif text-sm">
							{storefront?.name.charAt(0)}
						</div>
						{/if}
					<h1 class="font-display text-xl tracking-widest text-gray-900 uppercase font-light">{storefront?.name}</h1>
				</a>

				<!-- Desktop Menu -->
				<div class="hidden md:flex items-center gap-8">
					<a href="/" class="text-[10px] font-semibold uppercase tracking-[0.2em] transition-all hover:text-gray-400 {$page.url.pathname === '/' ? 'text-gray-900' : 'text-gray-500'}">Collection</a>
					<a href="/medics" class="text-[10px] font-semibold uppercase tracking-[0.2em] transition-all hover:text-gray-400 {$page.url.pathname === '/medics' ? 'text-gray-900' : 'text-gray-500'}">Medics</a>
					<a href="/tracking" class="text-[10px] font-semibold uppercase tracking-[0.2em] transition-all hover:text-gray-400 text-gray-500">Track Order</a>
				</div>

				<!-- Actions -->
				<div class="flex items-center gap-4">
					<button class="text-gray-600 hover:text-gray-900 transition-colors">
						<Search class="h-4 w-4" />
					</button>

					<!-- Account -->
					<div class="relative">
						{#if $isAuthenticated}
							<button on:click={toggleAccountMenu} class="flex items-center gap-1 text-[10px] font-semibold uppercase tracking-widest text-gray-600 hover:text-gray-900 transition-colors">
								<span class="max-w-[80px] truncate">{$currentUser?.user_metadata?.full_name?.split(' ')[0] || 'Account'}</span>
								<ChevronDown class="h-3 w-3 opacity-40" />
							</button>
							{#if isAccountOpen}
								<div class="absolute right-0 top-full mt-2 w-48 bg-white border border-gray-100 rounded shadow-xl z-50 py-1 text-xs animate-in fade-in slide-in-from-top-2 duration-200">
									<a href="/profile" class="block px-4 py-2 text-gray-700 hover:bg-gray-50 uppercase tracking-widest font-semibold text-[9px]">Profile</a>
									<a href="/orders" class="block px-4 py-2 text-gray-700 hover:bg-gray-50 uppercase tracking-widest font-semibold text-[9px]">Orders</a>
									<div class="border-t border-gray-100 my-1"></div>
									<button on:click={handleSignOut} class="w-full text-left px-4 py-2 text-red-600 hover:bg-red-50 uppercase tracking-widest font-semibold text-[9px]">Sign out</button>
								</div>
							{/if}
						{:else}
							<button on:click={() => isAuthModalOpen.set(true)} class="text-gray-600 hover:text-gray-900">
								<User class="h-4 w-4" />
							</button>
						{/if}
					</div>

					<a href="/cart" class="relative group">
						<ShoppingCart class="h-4 w-4 text-gray-900" />
						{#if cartCount > 0}
							<span class="absolute -top-2 -right-2 bg-gray-900 text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full border border-white">
								{cartCount}
							</span>
						{/if}
					</a>

					<button on:click={toggleMenu} class="md:hidden text-gray-600 hover:text-gray-900">
						<Menu class="h-4 w-4" />
					</button>
				</div>
			</div>
		</div>
	</nav>

	<!-- Auth Modal (Centered Overlay) -->
	{#if $isAuthModalOpen && !$isAuthenticated}
		<div class="fixed inset-0 z-[100] flex items-center justify-center p-4">
			<button 
				on:click={() => isAuthModalOpen.set(false)}
				class="absolute inset-0 bg-black/40 backdrop-blur-md transition-opacity cursor-default"
			></button>
			
			<div class="relative w-full max-w-sm bg-white rounded-lg shadow-2xl p-10 animate-in fade-in zoom-in-95 duration-300">
				<button 
					on:click={() => isAuthModalOpen.set(false)}
					class="absolute right-6 top-6 text-gray-400 hover:text-gray-900 transition-colors"
				>
					<X class="h-4 w-4" />
				</button>

				<div class="flex flex-col items-center text-center space-y-6">
					<div class="h-12 w-12 bg-gray-50 rounded-full flex items-center justify-center text-gray-900">
						<User class="h-6 w-6" />
					</div>
					
					<div class="space-y-2">
						<h3 class="font-display text-2xl">The Collection Identity</h3>
						<p class="text-[10px] text-gray-500 uppercase tracking-widest leading-relaxed max-w-xs">Authentication is required to secure your selection and rewards.</p>
					</div>
					
					<div class="w-full pt-4">
						<button 
							on:click={signInWithGoogle}
							class="w-full py-4 border border-gray-200 rounded-lg flex items-center justify-center gap-3 hover:bg-gray-50 active:scale-[0.98] transition-all text-[11px] font-bold text-gray-700 uppercase tracking-[0.15em] shadow-sm"
						>
							<img src="https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png" alt="Google" class="h-4 w-4" />
							Continue with Google
						</button>
					</div>

					<p class="text-[9px] text-gray-400 font-light leading-relaxed">By continuing, you agree to our curated terms and holistic privacy guidelines. Your identity is used exclusively for collection management.</p>
				</div>
			</div>
		</div>
	{/if}

	<!-- Main Content -->
	<main class="flex-grow">
		<slot />
	</main>

	<!-- Footer -->
	<footer class="bg-[#faf9f6]/50 border-t border-gray-100 pt-20 pb-12 mt-20">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="grid grid-cols-1 md:grid-cols-4 gap-12 pb-16">
				<div class="space-y-6 md:col-span-2">
					<h4 class="font-display text-2xl tracking-widest text-gray-900 uppercase font-light">{storefront?.name}</h4>
					<p class="text-gray-500 text-sm leading-relaxed max-w-sm font-light">
						{storefront?.description || 'Curated releases, artisan stories, and specialized healthcare solutions.'}
					</p>
					<div class="flex gap-6">
						<a href="#" class="text-gray-400 hover:text-gray-900 transition-colors"><Instagram class="h-5 w-5" /></a>
						<a href="#" class="text-gray-400 hover:text-gray-900 transition-colors"><Twitter class="h-5 w-5" /></a>
						<a href="#" class="text-gray-400 hover:text-gray-900 transition-colors"><Facebook class="h-5 w-5" /></a>
					</div>
				</div>
				
				<div class="grid grid-cols-2 gap-8 md:col-span-2">
					<div class="space-y-6">
						<h4 class="text-[10px] font-bold uppercase tracking-[0.2em] text-gray-400">Discover</h4>
						<ul class="space-y-4 text-xs font-semibold uppercase tracking-widest">
							<li><a href="/" class="text-gray-600 hover:text-gray-900 transition-colors">Collection</a></li>
							<li><a href="/medics" class="text-gray-600 hover:text-gray-900 transition-colors">Medics</a></li>
							<li><a href="/cart" class="text-gray-600 hover:text-gray-900 transition-colors">Bag</a></li>
						</ul>
					</div>
					<div class="space-y-6">
						<h4 class="text-[10px] font-bold uppercase tracking-[0.2em] text-gray-400">Newsletter</h4>
						<div class="relative">
							<input type="email" placeholder="Your email address" class="w-full bg-transparent border-b border-gray-200 py-2 text-xs outline-none focus:border-gray-900 transition-colors" />
							<button class="absolute right-0 bottom-2 text-gray-400 hover:text-gray-900 transition-colors">
								<ArrowRight class="h-4 w-4" />
							</button>
						</div>
					</div>
				</div>
			</div>
			
			<div class="pt-12 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4 text-[10px] font-bold uppercase tracking-[0.2em] text-gray-300">
				<p>© {new Date().getFullYear()} {storefront?.name}. All rights reserved.</p>
				<div class="flex gap-8">
					<a href="#" class="hover:text-gray-600 transition-colors">Privacy</a>
					<a href="#" class="hover:text-gray-600 transition-colors">Terms</a>
				</div>
			</div>
		</div>
	</footer>

	<!-- Floating Chat Icon -->
	<button 
		on:click={toggleChat}
		class="fixed bottom-8 right-8 z-[60] w-14 h-14 bg-gray-900 text-white rounded-full shadow-2xl flex items-center justify-center hover:scale-110 active:scale-95 transition-all duration-300 group"
	>
		<MessageCircle class="h-6 w-6 group-hover:rotate-12 transition-transform" />
		{#if !isChatOpen}
			<span class="absolute -right-1 -top-1 w-3 h-3 bg-red-500 rounded-full border-2 border-white animate-pulse"></span>
		{/if}
	</button>

	{#if isChatOpen}
		<div class="fixed bottom-24 right-8 z-[60] w-80 bg-white border border-gray-100 rounded-lg shadow-2xl overflow-hidden flex flex-col animate-in slide-in-from-bottom-4 duration-300">
			<!-- Chat Header -->
			<div class="bg-gray-900 p-4 flex items-center justify-between text-white">
				<div class="flex items-center gap-3">
					<div class="h-8 w-8 bg-white/10 rounded-full flex items-center justify-center"><ShieldCheck class="h-4 w-4" /></div>
					<div>
						<p class="text-[10px] font-bold uppercase tracking-widest leading-none">Support</p>
						<p class="text-[8px] opacity-60 mt-1 uppercase tracking-tighter">Response time: <span class="text-emerald-400">Under 1 min</span></p>
					</div>
				</div>
				<button on:click={toggleChat} class="hover:opacity-70 transition-opacity"><X class="h-4 w-4" /></button>
			</div>
			<!-- Chat Body -->
			<div class="h-64 p-6 bg-gray-50/50 flex flex-col justify-end items-center gap-2 text-center">
				<div class="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm mb-2"><MessageCircle class="h-6 w-6 text-gray-300" /></div>
				<p class="text-xs text-gray-900 font-medium italic">"Objects designed for permanence."</p>
				<p class="text-[10px] text-gray-500 max-w-[80%] font-light">Our curators are online and ready to assist with your collection inquiry.</p>
			</div>
			<!-- Chat Input -->
			<div class="p-4 border-t border-gray-100 flex gap-2 bg-white">
				<input type="text" placeholder="Type a message..." class="flex-1 text-xs outline-none bg-transparent" />
				<button class="text-gray-900 hover:opacity-70 transition-opacity"><Send class="h-4 w-4" /></button>
			</div>
		</div>
	{/if}
</div>

<style>
	:global(body) { 
		font-family: 'Inter', sans-serif;
		background: #faf9f6;
		overflow-x: hidden;
	}
	:global(.font-display) { font-family: 'Playfair Display', serif; }
    
    :global(a, button) { transition: all 0.2s ease-in-out; }

	.font-body { font-family: 'Inter', sans-serif; }
</style>
