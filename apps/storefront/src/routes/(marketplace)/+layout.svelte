<script lang="ts">
	import { ShoppingCart, Search, User, Menu, X, ArrowRight, Instagram, Twitter, Facebook, Stethoscope } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { authStore } from '$lib/stores/auth';

	export let data;

	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#4f46e5';
	$: brandColorLight = `${brandColor}15`; // 8% opacity for backgrounds

	let isMenuOpen = false;
	let isScrolled = false;
	let cartCount = 0;

	onMount(() => {
		const handleScroll = () => {
			isScrolled = window.scrollY > 20;
		};
		window.addEventListener('scroll', handleScroll);
		
		// In a real app, subscribe to a cart store here
		cartCount = 2; // Demo count

		return () => window.removeEventListener('scroll', handleScroll);
	});

	function toggleMenu() {
		isMenuOpen = !isMenuOpen;
	}

	$: storeUrl = storefront?.subdomain 
		? `${storefront.subdomain}.kemani.io` 
		: `${storefront?.slug}.kemani.io`;

</script>

<div 
	class="min-h-screen flex flex-col font-sans selection:bg-indigo-100 selection:text-indigo-900"
	style="--brand: {brandColor};"
>
	<!-- Top Promo Bar -->
	<div class="h-10 flex items-center justify-center brand-bg text-white text-[10px] font-black uppercase tracking-[0.2em] px-4 text-center">
		Free delivery on all orders over ₦25,000 this week only! 🚀
	</div>

	<!-- Navigation -->
	<nav 
		class="sticky top-0 z-50 transition-all duration-500 {isScrolled ? 'bg-white/90 backdrop-blur-xl border-b border-gray-100 shadow-sm py-3' : 'bg-transparent py-5'}"
	>
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex items-center justify-between">
				<!-- Brand -->
				<a href="/" class="flex items-center gap-3 group">
					<div class="h-11 w-11 rounded-2xl brand-bg flex items-center justify-center text-white font-black text-xl shadow-lg shadow-indigo-200 group-hover:scale-105 transition-transform duration-300">
						{#if storefront?.logo_url}
							<img src={storefront.logo_url} alt="logo" class="h-full w-full object-cover rounded-2xl" />
						{:else}
							{storefront?.name.charAt(0)}
						{/if}
					</div>
					<div class="hidden sm:block">
						<h1 class="text-lg font-black text-gray-900 leading-none tracking-tight">{storefront?.name}</h1>
						<p class="text-[10px] font-black tracking-widest uppercase mt-1 opacity-40 group-hover:opacity-100 transition-opacity" style="color:{brandColor};">Verified Store</p>
					</div>
				</a>

				<!-- Desktop Menu -->
				<div class="hidden md:flex items-center gap-1">
					<a href="/" class="px-5 py-2.5 rounded-xl text-sm font-black transition-all hover:bg-gray-50 {$page.url.pathname === '/' ? 'text-gray-900 bg-gray-50' : 'text-gray-500'}">Products</a>
					<a href="/medics" class="px-5 py-2.5 rounded-xl text-sm font-black transition-all hover:bg-gray-50 {$page.url.pathname === '/medics' ? 'text-gray-900 bg-gray-50' : 'text-gray-500'}">Medics</a>
					<a href="/tracking" class="px-5 py-2.5 rounded-xl text-sm font-black transition-all hover:bg-gray-50 text-gray-500">Track Order</a>
				</div>

				<!-- Actions -->
				<div class="flex items-center gap-2">
					<button class="h-11 w-11 flex items-center justify-center rounded-2xl text-gray-600 hover:bg-gray-100 transition-colors"><Search class="h-5 w-5" /></button>
					<a href="/profile" class="h-11 w-11 flex items-center justify-center rounded-2xl text-gray-600 hover:bg-gray-100 transition-colors"><User class="h-5 w-5" /></a>
					<a href="/cart" class="h-11 px-4 flex items-center gap-3 brand-bg text-white rounded-2xl shadow-lg shadow-indigo-100 hover:scale-105 active:scale-95 transition-all">
						<ShoppingCart class="h-5 w-5" />
						<div class="w-px h-4 bg-white/20"></div>
						<span class="text-sm font-black tracking-tighter">{cartCount}</span>
					</a>
					<button on:click={toggleMenu} class="md:hidden h-11 w-11 flex items-center justify-center rounded-2xl text-gray-600 hover:bg-gray-100 transition-colors"><Menu class="h-5 w-5" /></button>
				</div>
			</div>
		</div>
	</nav>

	<!-- Main Content -->
	<main class="flex-grow">
		<slot />
	</main>

	<!-- Footer -->
	<footer class="bg-gray-950 text-white pt-20 pb-8 mt-20">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="grid grid-cols-1 md:grid-cols-4 gap-12 pb-16 border-b border-white/5">
				<div class="space-y-6 md:col-span-2">
					<div class="flex items-center gap-4">
						<div class="h-12 w-12 rounded-2xl brand-bg flex items-center justify-center text-white font-black text-xl">
							{#if storefront?.logo_url}
								<img src={storefront.logo_url} alt="logo" class="h-full w-full object-cover rounded-2xl" />
							{:else}
								{storefront?.name.charAt(0)}
							{/if}
						</div>
						<div>
							<p class="text-lg font-black tracking-tight">{storefront?.name}</p>
							<p class="text-[10px] font-black uppercase tracking-[0.2em]" style="color:{brandColor};">{storeUrl}</p>
						</div>
					</div>
					<p class="text-gray-400 text-sm leading-relaxed max-w-sm font-medium">{storefront?.description || 'Your trusted neighborhood store, now online for your convenience.'}</p>
					<div class="flex gap-4">
						<a href="#" class="h-10 w-10 rounded-xl bg-white/5 flex items-center justify-center border border-white/5 hover:brand-bg transition-colors"><Instagram class="h-4 w-4" /></a>
						<a href="#" class="h-10 w-10 rounded-xl bg-white/5 flex items-center justify-center border border-white/5 hover:brand-bg transition-colors"><Twitter class="h-4 w-4" /></a>
						<a href="#" class="h-10 w-10 rounded-xl bg-white/5 flex items-center justify-center border border-white/5 hover:brand-bg transition-colors"><Facebook class="h-4 w-4" /></a>
					</div>
				</div>
				
				<div class="grid grid-cols-2 gap-8 md:col-span-2">
					<div class="space-y-6">
						<h4 class="text-xs font-black uppercase tracking-[0.2em] text-white/40">Shop</h4>
						<ul class="space-y-4 text-sm font-bold">
							<li><a href="/" class="text-gray-400 hover:text-white transition-colors">Products</a></li>
							<li><a href="/medics" class="text-gray-400 hover:text-white transition-colors">Medics</a></li>
							<li><a href="/cart" class="text-gray-400 hover:text-white transition-colors">My Cart</a></li>
							<li><a href="/tracking" class="text-gray-400 hover:text-white transition-colors">Track Order</a></li>
						</ul>
					</div>
					<div class="space-y-6">
						<h4 class="text-xs font-black uppercase tracking-[0.2em] text-white/40">Newsletter</h4>
						<p class="text-gray-400 text-xs font-medium leading-relaxed">Subscribe to stay updated with {storefront?.name} deals.</p>
						<div class="flex gap-2">
							<input type="email" placeholder="your@email.com" class="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 transition-colors" />
							<button class="brand-bg hover:opacity-90 p-3 rounded-xl transition-opacity flex items-center justify-center"><ArrowRight class="h-4 w-4" /></button>
						</div>
					</div>
				</div>
			</div>
			
			<div class="pt-8 flex flex-col md:flex-row justify-between items-center gap-4 text-[10px] font-black uppercase tracking-[0.2em] text-gray-500">
				<p>© {new Date().getFullYear()} {storefront?.name}. All rights reserved.</p>
				<div class="flex items-center gap-6">
					<a href="#" class="hover:text-white transition-colors">Privacy Policy</a>
					<a href="#" class="hover:text-white transition-colors">Terms of Service</a>
					<p>Powered by <span style="color:{brandColor};">Kemani OS</span></p>
				</div>
			</div>
		</div>
	</footer>
</div>

<style>
	:global(body) { font-family: 'Outfit', 'Inter', sans-serif; background: #fff; }
	.brand-bg { background-color: var(--brand, #4f46e5); }
</style>
