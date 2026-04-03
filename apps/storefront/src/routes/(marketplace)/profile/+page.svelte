<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		User, ShoppingBag, MapPin, Award, LogOut, 
		ChevronRight, Package, Clock, ShieldCheck, ArrowRight 
	} from 'lucide-svelte';
	import { isAuthenticated, currentUser } from '$lib/stores/auth';
	import { isAuthModalOpen } from '$lib/stores/ui';
	import { supabase } from '$lib/supabase';

	export let data: { tenant: any };
	$: storefront = data.tenant;

	type Customer = {
		id: string;
		full_name: string;
		email?: string;
		phone: string;
		loyalty_points_balance: number;
		total_orders: number;
		total_spent: number;
		created_at: string;
	};

	type Order = {
		id: string;
		order_number: string;
		status: string;
		total_amount: number;
		created_at: string;
	};

	let customer: Customer | null = null;
	let orders: Order[] = [];
	let isLoading = true;
	let activeTab: 'profile' | 'orders' | 'loyalty' = 'profile';
	let error = '';

	onMount(async () => {
		if (!$isAuthenticated) {
			isLoading = false;
			return;
		}
		await loadCustomerData();
	});

	async function loadCustomerData() {
		isLoading = true;
		try {
			// In a real app, fetch from Supabase
			customer = {
				id: $currentUser?.id || '',
				full_name: $currentUser?.user_metadata?.full_name || 'Member',
				email: $currentUser?.email,
				phone: $currentUser?.user_metadata?.phone || '',
				loyalty_points_balance: 450,
				total_orders: 12,
				total_spent: 125000,
				created_at: $currentUser?.created_at || new Date().toISOString()
			};
			
			orders = [
				{ id: '1', order_number: 'ORD-99120', status: 'delivered', total_amount: 15600, created_at: '2024-03-20T10:00:00Z' },
				{ id: '2', order_number: 'ORD-99085', status: 'processing', total_amount: 8400, created_at: '2024-04-01T14:30:00Z' }
			];
		} catch (err: any) {
			error = 'Failed to load collection data.';
		} finally {
			isLoading = false;
		}
	}

	function formatDate(dateString: string): string {
		return new Date(dateString).toLocaleDateString('en-US', {
			year: 'numeric', month: 'short', day: 'numeric'
		});
	}

	async function handleSignOut() {
		await supabase.auth.signOut();
		goto('/');
	}
</script>

<svelte:head>
	<title>Member Profile — {storefront?.name || 'Curator'}</title>
</svelte:head>

<div class="profile-page">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-20">
		
		{#if !$isAuthenticated}
			<div class="auth-gate">
				<div class="gate-icon"><User class="w-10 h-10" /></div>
				<h2 class="gate-title">Member Access</h2>
				<p class="gate-sub">Please sign in to view your personalized collection and order history.</p>
				<button 
					on:click={() => isAuthModalOpen.set(true)}
					class="btn-primary gate-btn"
				>
					Sign In to Collection
				</button>
			</div>
		{:else if isLoading}
			<div class="loading-state">
				<div class="loader-ring"></div>
				<p>Loading your profile...</p>
			</div>
		{:else}
			<div class="profile-layout">
				<!-- Sidebar Nav -->
				<aside class="profile-sidebar">
					<div class="sidebar-user">
						<div class="user-avatar">
							{customer?.full_name.charAt(0)}
						</div>
						<div class="user-info">
							<h3 class="user-name">{customer?.full_name}</h3>
							<p class="user-email">{customer?.email || customer?.phone}</p>
						</div>
					</div>

					<nav class="sidebar-nav">
						<button 
							on:click={() => activeTab = 'profile'} 
							class="nav-item {activeTab === 'profile' ? 'active' : ''}"
						>
							<User class="nav-icon" /> Overview
						</button>
						<button 
							on:click={() => activeTab = 'orders'} 
							class="nav-item {activeTab === 'orders' ? 'active' : ''}"
						>
							<ShoppingBag class="nav-icon" /> Orders
						</button>
						<button 
							on:click={() => activeTab = 'loyalty'} 
							class="nav-item {activeTab === 'loyalty' ? 'active' : ''}"
						>
							<Award class="nav-icon" /> Rewards
						</button>
						<div class="nav-sep"></div>
						<button on:click={handleSignOut} class="nav-item nav-logout text-red-500">
							<LogOut class="nav-icon" /> Sign Out
						</button>
					</nav>
				</aside>

				<!-- Main Content -->
				<main class="profile-main">
					{#if activeTab === 'profile'}
						<div class="content-view">
							<h2 class="view-title">The Overview</h2>
							
							<div class="stats-grid">
								<div class="stat-card">
									<p class="stat-label">Total Orders</p>
									<p class="stat-val">{customer?.total_orders}</p>
								</div>
								<div class="stat-card">
									<p class="stat-label">Member Points</p>
									<p class="stat-val text-accent">{customer?.loyalty_points_balance}</p>
								</div>
								<div class="stat-card">
									<p class="stat-label">Joined</p>
									<p class="stat-val text-sm">{formatDate(customer?.created_at || '')}</p>
								</div>
							</div>

							<div class="info-sections">
								<section class="info-section">
									<h4 class="section-label">Personal Content</h4>
									<div class="info-row">
										<span>Full Identity</span>
										<p>{customer?.full_name}</p>
									</div>
									<div class="info-row border-none">
										<span>Email Context</span>
										<p>{customer?.email || 'Not Provided'}</p>
									</div>
								</section>
							</div>
						</div>

					{:else if activeTab === 'orders'}
						<div class="content-view">
							<h2 class="view-title">Order History</h2>
							
							{#if orders.length === 0}
								<div class="empty-list">
									<p>No orders recorded in your collection.</p>
									<a href="/" class="btn-text">Start Shopping <ArrowRight class="w-3 h-3" /></a>
								</div>
							{:else}
								<div class="orders-list">
									{#each orders as order}
										<div class="order-row">
											<div class="order-id-wrap">
												<p class="order-num">{order.order_number}</p>
												<p class="order-date">{formatDate(order.created_at)}</p>
											</div>
											<div class="order-status">
												<span class="status-badge {order.status}">{order.status}</span>
											</div>
											<div class="order-amount">
												<p>₦{order.total_amount.toLocaleString()}</p>
											</div>
											<div class="order-action">
												<button class="btn-icon-only"><ChevronRight class="w-4 h-4" /></button>
											</div>
										</div>
									{/each}
								</div>
							{/if}
						</div>

					{:else if activeTab === 'loyalty'}
						<div class="content-view">
							<h2 class="view-title">Medics Rewards</h2>
							
							<div class="loyalty-hero">
								<div class="hero-content">
									<Award class="hero-icon" />
									<p class="hero-label">Available Points</p>
									<p class="hero-balance">{customer?.loyalty_points_balance}</p>
									<p class="hero-value">Equivalent to ₦{(customer?.loyalty_points_balance || 0) * 10} in store credit</p>
								</div>
							</div>

							<section class="reward-rules mt-12">
								<h4 class="section-label">How to Earn</h4>
								<ul class="rules-list">
									<li>Earn <span class="text-accent">1 point</span> for every ₦100 spent.</li>
									<li>Redeem points at checkout for direct discounts.</li>
									<li>Points are awarded upon successful delivery.</li>
								</ul>
							</section>
						</div>
					{/if}
				</main>
			</div>
		{/if}
	</div>
</div>

<style>
	/* ─── TOKENS ─── */
	:root {
		--font-display: 'Playfair Display', Georgia, serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #faf9f6;
		--on-surface: #1a1c1a;
		--on-surface-muted: #6b7280;
		--border: #f0eeea;
		--accent: #785a1a;
		--radius: 8px;
	}

	.profile-page {
		background: var(--surface);
		color: var(--on-surface);
		font-family: var(--font-body);
		min-height: 100vh;
	}

	/* ─── AUTH GATE ─── */
	.auth-gate { text-align: center; padding: 10rem 2rem; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); }
	.gate-icon { width: 64px; height: 64px; background: var(--surface); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 2rem; color: #d1d5db; }
	.gate-title { font-family: var(--font-display); font-size: 2.5rem; margin-bottom: 0.5rem; }
	.gate-sub { color: var(--on-surface-muted); margin-bottom: 2.5rem; font-size: 14px; max-width: 400px; margin-left: auto; margin-right: auto; line-height: 1.6; }
	.gate-btn { display: inline-flex; width: auto; padding: 1rem 3rem; }

	/* ─── LAYOUT ─── */
	.profile-layout {
		display: grid;
		grid-template-columns: 1fr;
		gap: 3rem;
	}
	@media (min-width: 1024px) {
		.profile-layout { grid-template-columns: 280px 1fr; gap: 5rem; }
	}

	/* ─── SIDEBAR ─── */
	.profile-sidebar { display: flex; flex-direction: column; gap: 2.5rem; }
	.sidebar-user { display: flex; align-items: center; gap: 1rem; padding-bottom: 2rem; border-bottom: 1px solid var(--border); }
	.user-avatar { width: 44px; height: 44px; border-radius: 50%; background: var(--on-surface); color: #fff; display: flex; align-items: center; justify-content: center; font-family: var(--font-display); font-size: 1.25rem; }
	.user-name { font-size: 14px; font-weight: 700; color: var(--on-surface); }
	.user-email { font-size: 11px; color: var(--on-surface-muted); }

	.sidebar-nav { display: flex; flex-direction: column; gap: 0.5rem; }
	.nav-item { display: flex; align-items: center; gap: 12px; padding: 12px 1rem; border-radius: 6px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); transition: all 0.2s; border: none; background: transparent; cursor: pointer; text-align: left; }
	.nav-item.active { background: #fff; color: var(--on-surface); border: 1px solid var(--border); }
	.nav-item:hover:not(.active) { color: var(--on-surface); }
	.nav-icon { width: 14px; height: 14px; opacity: 0.5; }
	.nav-sep { height: 1px; background: var(--border); margin: 1rem 0; }

	/* ─── MAIN CONTENT ─── */
	.content-view { animation: fadeIn 0.4s ease; }
	@keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }
	.view-title { font-family: var(--font-display); font-size: 2.5rem; font-weight: 500; margin-bottom: 2.5rem; }

	.stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; margin-bottom: 3rem; }
	.stat-card { padding: 2rem; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); }
	.stat-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); margin-bottom: 8px; }
	.stat-val { font-family: var(--font-display); font-size: 2rem; font-weight: 500; }
	.text-accent { color: var(--accent); }

	.section-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); margin-bottom: 1.5rem; border-bottom: 1px solid var(--border); padding-bottom: 8px; }
	.info-row { display: flex; justify-content: space-between; align-items: center; padding: 1.5rem 0; border-bottom: 1px solid var(--border); font-size: 14px; }
	.info-row span { color: var(--on-surface-muted); }
	.info-row p { font-weight: 600; }

	/* ─── ORDERS ─── */
	.orders-list { display: flex; flex-direction: column; border-top: 1px solid var(--border); }
	.order-row { display: grid; grid-template-columns: 1fr 1fr 100px 40px; gap: 1rem; align-items: center; padding: 2rem 0; border-bottom: 1px solid var(--border); }
	.order-num { font-size: 14px; font-weight: 700; color: var(--on-surface); }
	.order-date { font-size: 12px; color: var(--on-surface-muted); }
	.status-badge { font-size: 9px; font-weight: 700; text-transform: uppercase; padding: 4px 10px; border-radius: 4px; display: inline-block; }
	.status-badge.delivered { background: #f0fdf4; color: #059669; }
	.status-badge.processing { background: #fffbeb; color: #d97706; }
	.order-amount { font-size: 14px; font-weight: 600; text-align: right; }

	/* ─── LOYALTY ─── */
	.loyalty-hero { background: var(--on-surface); color: #fff; padding: 4rem 2rem; border-radius: var(--radius); text-align: center; }
	.hero-icon { width: 32px; height: 32px; color: var(--accent); margin: 0 auto 1.5rem; }
	.hero-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.2em; color: rgba(255,255,255,0.4); margin-bottom: 1rem; }
	.hero-balance { font-family: var(--font-display); font-size: 4rem; line-height: 1; margin-bottom: 1rem; color: var(--accent); }
	.hero-value { font-size: 13px; font-weight: 300; opacity: 0.6; }

	.rules-list { display: flex; flex-direction: column; gap: 1rem; font-size: 14px; }
	.rules-list li { display: flex; align-items: start; gap: 10px; color: var(--on-surface-muted); }
	.rules-list li::before { content: '→'; color: var(--accent); }

	/* ─── UTILS ─── */
	.btn-primary {
		padding: 1rem 2rem; border: none; border-radius: 6px;
		background: var(--on-surface); color: #fff;
		font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.15em;
		cursor: pointer; transition: background 0.2s;
	}
	.btn-primary:hover { background: #000; }
	.btn-text { font-size: 11px; font-weight: 700; text-transform: uppercase; color: var(--accent); display: flex; align-items: center; gap: 6px; margin-top: 1rem; }
	.loading-state { text-align: center; padding: 10rem 0; color: var(--on-surface-muted); font-size: 14px; }
	.loader-ring { width: 40px; height: 40px; border: 3px solid var(--border); border-top-color: var(--on-surface); border-radius: 50%; margin: 0 auto 1rem; animation: spin 1s linear infinite; }
	@keyframes spin { to { transform: rotate(360deg); } }
</style>
