<script lang="ts">
	import { ShoppingCart, Search, User, Menu, X, ArrowRight, Instagram, Twitter, Facebook, Stethoscope, MessageCircle, Send } from 'lucide-svelte';
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
	let isChatOpen = false;
	
	function toggleChat() {
		isChatOpen = !isChatOpen;
	}

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
					<p class="text-white text-sm leading-relaxed max-w-sm font-medium">{storefront?.description || 'Your trusted neighborhood store, now online for your convenience.'}</p>
					<div class="flex gap-4">
						<a href="#" class="h-10 w-10 rounded-xl bg-white/5 flex items-center justify-center border border-white/5 hover:brand-bg transition-colors"><Instagram class="h-4 w-4" /></a>
						<a href="#" class="h-10 w-10 rounded-xl bg-white/5 flex items-center justify-center border border-white/5 hover:brand-bg transition-colors"><Twitter class="h-4 w-4" /></a>
						<a href="#" class="h-10 w-10 rounded-xl bg-white/5 flex items-center justify-center border border-white/5 hover:brand-bg transition-colors"><Facebook class="h-4 w-4" /></a>
					</div>
				</div>
				
				<div class="grid grid-cols-2 gap-8 md:col-span-2">
					<div class="space-y-6">
						<h4 class="text-xs font-black uppercase tracking-[0.2em] text-white">Shop</h4>
						<ul class="space-y-4 text-sm font-bold">
							<li><a href="/" class="text-white hover:opacity-80 transition-opacity">Products</a></li>
							<li><a href="/medics" class="text-white hover:opacity-80 transition-opacity">Medics</a></li>
							<li><a href="/cart" class="text-white hover:opacity-80 transition-opacity">My Cart</a></li>
							<li><a href="/tracking" class="text-white hover:opacity-80 transition-opacity">Track Order</a></li>
						</ul>
					</div>
					<div class="space-y-6">
						<h4 class="text-xs font-black uppercase tracking-[0.2em] text-white">Newsletter</h4>
						<p class="text-white text-xs font-medium leading-relaxed">Subscribe to stay updated with {storefront?.name} deals.</p>
						<div class="flex gap-2">
							<input type="email" placeholder="your@email.com" class="flex-1 bg-white/10 border border-white/20 rounded-xl px-4 py-3 text-sm outline-none text-white placeholder-white/50 focus:border-white transition-colors" />
							<button class="brand-bg text-white hover:opacity-90 p-3 rounded-xl transition-opacity flex items-center justify-center"><ArrowRight class="h-4 w-4" /></button>
						</div>
					</div>
				</div>
			</div>
			
			<div class="pt-8 flex flex-col md:flex-row justify-between items-center gap-4 text-[10px] font-black uppercase tracking-[0.2em] text-white">
				<p>© {new Date().getFullYear()} {storefront?.name}. All rights reserved.</p>
				<div class="flex items-center gap-6">
					<a href="#" class="hover:opacity-80 transition-opacity">Privacy Policy</a>
					<a href="#" class="hover:opacity-80 transition-opacity">Terms of Service</a>
					<p>Powered by <span style="color:{brandColor};">Kemani OS</span></p>
				</div>
			</div>
		</div>
	</footer>

	<!-- Floating Chat Widget -->
	<div class="fixed bottom-6 right-6 z-50 flex flex-col items-end gap-4">
		{#if isChatOpen}
			<div class="w-[calc(100vw-3rem)] sm:w-80 bg-white rounded-3xl shadow-2xl border border-gray-100 overflow-hidden translate-y-0 opacity-100 transition-all duration-300 origin-bottom-right flex flex-col h-[400px]">
				<div class="h-16 brand-bg flex items-center justify-between px-5 text-white">
					<div>
						<p class="font-black tracking-tight leading-none text-sm">{storefront?.name || 'Support'}</p>
						<p class="text-[10px] font-bold tracking-widest text-white/70 uppercase mt-1">We typically reply instantly</p>
					</div>
					<button on:click={toggleChat} class="h-8 w-8 rounded-full bg-white/10 flex items-center justify-center hover:bg-white/20 transition-all"><X class="h-4 w-4" /></button>
				</div>
				<div class="flex-1 bg-[#F8FAFC] p-4 flex flex-col gap-3 overflow-y-auto">
					<div class="self-start max-w-[85%]">
						<div class="bg-white px-4 py-3 rounded-2xl rounded-tl-sm shadow-sm border border-gray-100 text-sm font-medium text-gray-700">
							Hi there! 👋 How can we help you today?
						</div>
						<p class="text-[9px] font-black uppercase text-gray-400 mt-1 ml-1">Just now</p>
					</div>
				</div>
				<div class="p-4 bg-white border-t border-gray-100 flex items-center gap-2">
					<input type="text" placeholder="Type your message..." class="flex-1 bg-gray-50 border border-gray-100 rounded-full px-4 py-3 text-sm outline-none focus:border-indigo-500 transition-all" />
					<button class="h-11 w-11 rounded-full brand-bg flex items-center justify-center text-white shadow-md hover:scale-105 transition-all outline-none">
						<Send class="h-4 w-4 ml-0.5" />
					</button>
				</div>
			</div>
		{/if}
		
		<button 
			on:click={toggleChat}
			class="h-16 w-16 brand-bg rounded-full flex items-center justify-center text-white shadow-2xl shadow-indigo-500/30 hover:scale-110 active:scale-95 transition-all group"
		>
			<MessageCircle class="h-7 w-7 group-hover:animate-pulse" />
		</button>
	</div>
</div>

<style>
	:global(body) { font-family: 'Outfit', 'Inter', sans-serif; background: #fff; }
	.brand-bg { background-color: var(--brand, #4f46e5); }
</style>
