<script lang="ts">
	import { ShoppingCart, Search, User, Menu, X, ArrowRight, Instagram, Twitter, Facebook, MessageCircle, Send, ChevronDown, ShieldCheck, Globe, Share2, Mail, Phone } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, currentUser } from '$lib/stores/auth';
	import { isAuthModalOpen, isChatOpen, chatProduct } from '$lib/stores/ui';
	import { supabase } from '$lib/supabase';
	import { AuthService } from '$lib/services/auth';
	import { activeConversationId, setActiveConversation } from '$lib/stores/chat.store';
	import { get } from 'svelte/store';
	import { PUBLIC_APP_URL } from '$env/static/public';
	import AuthModal from '$lib/components/AuthModal.svelte';

	export let data;

	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#4f46e5';
	$: brandColorLight = `${brandColor}15`;

	let isMenuOpen = false;
	let isScrolled = false;
	let cartCount = 0;
	let isAccountOpen = false;

	async function toggleChat(type: 'Customer Support' | 'Consultation' = 'Customer Support') { 
		if (!$isAuthenticated) {
			const productId = get(chatProduct)?.id;
			const redirectUrl = productId ? `/chat?productId=${productId}&type=${type}` : `/chat?type=${type}`;
			localStorage.setItem('pending_chat_redirect', redirectUrl);
			isAuthModalOpen.set(true);
			return;
		}

		const productId = get(chatProduct)?.id;
		const chatUrl = productId ? `/chat?productId=${productId}&type=${type}` : `/chat?type=${type}`;

		// Check for existing active conversation in global store
		const existingId = get(activeConversationId);
		if (existingId) {
			goto(`${chatUrl}${chatUrl.includes('?') ? '&' : '?'}id=${existingId}`);
			return;
		}

		// Create new chat
		try {
			const { data: created, error } = await supabase
				.from('chat_conversations')
				.insert({
					customer_id: $currentUser.id,
					tenant_id: storefront?.id,
					chatType: type,
					status: 'active',
					metadata: { 
						origin: type === 'Consultation' ? 'storefront_header' : 'storefront_floating',
						productId: productId
					}
				})
				.select().single();

			if (error) throw error;
			if (created) {
				setActiveConversation(created.id);
				goto(`${chatUrl}${chatUrl.includes('?') ? '&' : '?'}id=${created.id}`);
			}
		} catch (err) {
			console.error('Failed to initiate chat:', err);
			// Fallback to chat page which has its own init logic
			goto(chatUrl);
		}
	}
	function toggleAccountMenu() { isAccountOpen = !isAccountOpen; }

	async function handleSignOut() {
		await supabase.auth.signOut();
		authStore.clearAuth();
		isAccountOpen = false;
		goto('/');
	}

	let authError = '';

	async function signInWithGoogle() {
		const next = window.location.href;
		const portalUrl = `${PUBLIC_APP_URL}/auth/portal?next=${encodeURIComponent(next)}`;
		window.location.href = portalUrl;
	}

	onMount(() => {
		(async () => {
			// Sync session from hash (Auth Shuttle callback)
			if (window.location.hash) {
				const hash = window.location.hash.substring(1);
				const params = new URLSearchParams(hash);
				const access_token = params.get('access_token');
				const refresh_token = params.get('refresh_token');
				
				if (access_token && refresh_token) {
					const { error } = await supabase.auth.setSession({ access_token, refresh_token });
					if (!error) {
						window.history.replaceState(null, '', window.location.pathname + window.location.search);
					}
				}
			}

			await authStore.initialize();
		})();

		const handleScroll = () => { isScrolled = window.scrollY > 20; };
		window.addEventListener('scroll', handleScroll);

		const updateCart = () => {
			try {
				const cart = JSON.parse(localStorage.getItem('cart') || '{"items":[]}');
				cartCount = cart.items.reduce((s: number, i: any) => s + i.quantity, 0);
			} catch { cartCount = 0; }
		};

		// Sync customer record AND handle pending chat redirect whenever auth changes
		const unsubscribe = currentUser.subscribe(async (user) => {
			if (user) {
				// Ensure customer record exists
				if (storefront?.id) {
					const lastBranch = localStorage.getItem('last_branch_id') || undefined;
					await AuthService.ensureCustomerRecord(user, storefront.id, lastBranch);
				}
				// Fire pending chat redirect if set
				const pendingChat = localStorage.getItem('pending_chat_redirect');
				if (pendingChat) {
					localStorage.removeItem('pending_chat_redirect');
					isAuthModalOpen.set(false);
					goto(pendingChat);
				}
			}
		});

		updateCart();
		window.addEventListener('storage', updateCart);
		window.addEventListener('cart-updated', updateCart);

		return () => {
			window.removeEventListener('scroll', handleScroll);
			window.removeEventListener('storage', updateCart);
			window.removeEventListener('cart-updated', updateCart);
			unsubscribe();
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
	{#if $page.url.pathname !== '/profile' && !$page.url.pathname.startsWith('/chat')}
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
						<a href="/" class="text-[10px] font-semibold uppercase tracking-[0.2em] transition-all hover:text-gray-400 {$page.url.pathname === '/' ? 'text-gray-900' : 'text-gray-500'}">Products</a>
						{#if storefront?.allowDoctorPartnerShip ?? true}
							<a href="/medics" class="text-[10px] font-semibold uppercase tracking-[0.2em] transition-all hover:text-gray-400 {$page.url.pathname === '/medics' ? 'text-gray-900' : 'text-gray-500'}">Medics</a>
						{/if}
						<a href="/tracking" class="text-[10px] font-semibold uppercase tracking-[0.2em] transition-all hover:text-gray-400 text-gray-500">Track Order</a>
						<button 
							onclick={() => toggleChat('Consultation')}
							title="Pharmacist on duty"
							class="text-[10px] font-bold uppercase tracking-[0.2em] text-emerald-600 hover:text-emerald-700 flex items-center gap-1.5"
						>
							<MessageCircle class="w-3.5 h-3.5" /> Rx Chat
						</button>
					</div>

					<!-- Actions -->
					<div class="flex items-center gap-4">
						<button class="text-gray-600 hover:text-gray-900 transition-colors">
							<Search class="h-4 w-4" />
						</button>

						<!-- Account -->
						<div class="relative">
							{#if $isAuthenticated}
								<button onclick={toggleAccountMenu} class="flex items-center gap-1 text-[10px] font-semibold uppercase tracking-widest text-gray-600 hover:text-gray-900 transition-colors">
									<span class="max-w-[80px] truncate">{$currentUser?.user_metadata?.full_name?.split(' ')[0] || 'Account'}</span>
									<ChevronDown class="h-3 w-3 opacity-40" />
								</button>
								{#if isAccountOpen}
									<div class="absolute right-0 top-full mt-2 w-48 bg-white border border-gray-100 rounded shadow-xl z-50 py-1 text-xs animate-in fade-in slide-in-from-top-2 duration-200">
										<a href="/profile" class="block px-4 py-2 text-gray-700 hover:bg-gray-50 uppercase tracking-widest font-semibold text-[9px]">Profile</a>
										<a href="/orders" class="block px-4 py-2 text-gray-700 hover:bg-gray-50 uppercase tracking-widest font-semibold text-[9px]">Orders</a>
										<div class="border-t border-gray-100 my-1"></div>
										<button onclick={handleSignOut} class="w-full text-left px-4 py-2 text-red-600 hover:bg-red-50 uppercase tracking-widest font-semibold text-[9px]">Sign out</button>
									</div>
								{/if}
							{:else}
								<button onclick={() => isAuthModalOpen.set(true)} class="text-gray-600 hover:text-gray-900">
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

						<button onclick={toggleMenu} class="md:hidden text-gray-600 hover:text-gray-900">
							<Menu class="h-4 w-4" />
						</button>
					</div>
				</div>
			</div>
		</nav>
	{/if}


	<!-- Main Content -->
	<main class="flex-grow">
		<slot />
	</main>

	<!-- Footer -->
	{#if $page.url.pathname !== '/profile' && !$page.url.pathname.startsWith('/chat')}
	  <footer class="footer">
		<div class="layout-container" style="max-width: 1280px; margin: 0 auto; padding: 0 1.5rem;">
		  <div class="footer-top">
			<div class="footer-info">
			  <div class="footer-logo">
				<h4 class="font-display text-2xl tracking-widest uppercase font-bold" style="color: {brandColor};">{storefront?.name || 'Storefront'}</h4>
			  </div>
			  <p class="footer-desc">
				{storefront?.description || 'Connecting patients with the worlds leading medical specialists. Quality healthcare, just a click away.'}
			  </p>
			</div>

			<div class="footer-links-grid">
			  <div class="footer-col">
				<h4>Company</h4>
				<a href="#">About Us</a>
				<a href="#">Careers</a>
				<a href="#">Press</a>
			  </div>
			  <div class="footer-col">
				<h4>Support</h4>
				<a href="#">Help Center</a>
				<a href="#">Privacy Policy</a>
				<a href="#">Terms of Service</a>
			  </div>
			  <div class="footer-col">
				<h4>Contact</h4>
				<div class="contact-item"><Mail class="w-4 h-4" /> <span>{storefront?.email || 'support@kemani.com'}</span></div>
				<div class="contact-item"><Phone class="w-4 h-4" /> <span>{storefront?.phone || '+1 (555) 000-1234'}</span></div>
			  </div>
			</div>
		  </div>

		  <div class="footer-bottom">
			<p>© {new Date().getFullYear()} {storefront?.name || 'Healthcare Portal'} Inc. All rights reserved.</p>
			<div class="footer-actions">
			  <Globe class="w-4 h-4 cursor-pointer" />
			  <Share2 class="w-4 h-4 cursor-pointer" />
			</div>
		  </div>
		</div>
	  </footer>
	{/if}

	<!-- Floating Chat Icon -->
	{#if !$page.url.pathname.startsWith('/chat')}
	<button 
		onclick={() => toggleChat('Customer Support')}
		class="fixed bottom-8 right-8 z-[60] w-14 h-14 bg-gray-900 text-white rounded-full shadow-2xl flex items-center justify-center hover:scale-110 active:scale-95 transition-all duration-300 group"
	>
		<MessageCircle class="h-6 w-6 group-hover:rotate-12 transition-transform" />
		{#if !$isChatOpen && !$isAuthenticated}
			<span class="absolute -right-1 -top-1 w-3 h-3 bg-red-500 rounded-full border-2 border-white animate-pulse"></span>
		{/if}
	</button>

	{#if $isChatOpen}
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
				<button onclick={toggleChat} class="hover:opacity-70 transition-opacity"><X class="h-4 w-4" /></button>
			</div>
			<!-- Chat Body -->
			<div class="h-64 p-6 bg-gray-50/50 flex flex-col justify-end items-center gap-2 text-center">
				{#if $chatProduct}
					<div class="product-context p-3 bg-white border border-gray-100 rounded mb-4 w-full flex items-center gap-3">
						<img src={$chatProduct.image_url} alt="" class="h-8 w-8 object-cover rounded" />
						<div class="text-left">
							<p class="text-[10px] font-bold truncate max-w-[120px]">{$chatProduct.name}</p>
							<p class="text-[8px] text-gray-400">Ask a curator about this item</p>
						</div>
					</div>
				{:else}
					<div class="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm mb-2"><MessageCircle class="h-6 w-6 text-gray-300" /></div>
					<p class="text-xs text-gray-900 font-medium italic">"Objects designed for permanence."</p>
					<p class="text-[10px] text-gray-500 max-w-[80%] font-light">Our curators are online and ready to assist with your collection inquiry.</p>
				{/if}
			</div>
			<!-- Chat Input -->
			<div class="p-4 border-t border-gray-100 flex gap-2 bg-white">
				<input type="text" placeholder="Type a message..." class="flex-1 text-xs outline-none bg-transparent" />
				<button class="text-gray-900 hover:opacity-70 transition-opacity"><Send class="h-4 w-4" /></button>
			</div>
		</div>
	{/if}

	{/if}
 
	<AuthModal />
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

	.footer { background: #f8fafc; border-top: 1px solid #f1f5f9; padding: 3rem 0 2rem; margin-top: auto; }
	.footer-top { display: flex; flex-direction: column; gap: 2.5rem; margin-bottom: 2.5rem; }
	@media (min-width: 768px) { .footer-top { flex-direction: row; justify-content: space-between; } }
	.footer-info { max-width: 300px; }
	.footer-logo { display: flex; align-items: center; gap: 0.6rem; margin-bottom: 1rem; }
	.footer-desc { font-size: 0.8125rem; color: #475569; line-height: 1.6; }
	
	.footer-links-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; }
	@media (min-width: 640px) { .footer-links-grid { grid-template-columns: repeat(3, 1fr); } }
	.footer-col h4 { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 1.25rem; color: #0f172a; font-weight: 800; }
	.footer-col a, .contact-item { display: flex; align-items: center; gap: 0.5rem; font-size: 0.8125rem; color: #475569; margin-bottom: 0.75rem; transition: color 0.2s; font-weight: 500; text-decoration: none; }
	.footer-col a:hover { color: var(--brand, #4f46e5); }
	
	.footer-bottom { border-top: 1px solid #f1f5f9; padding-top: 2rem; display: flex; justify-content: space-between; align-items: center; font-size: 0.75rem; color: #475569; }
	.footer-actions { display: flex; gap: 1.25rem; }
</style>
