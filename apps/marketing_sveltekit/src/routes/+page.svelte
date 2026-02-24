<script lang="ts">
	import { ArrowRight, Zap, Smartphone, ShoppingBag, TrendingUp, MessageSquare, Shield } from 'lucide-svelte';
	import ThemeToggle from '$lib/components/ThemeToggle.svelte';
</script>

<svelte:head>
	<title>Kemani POS - Offline-First POS Platform for Nigerian Businesses</title>
	<meta name="description" content="Nigeria's first offline-first POS platform. Process sales, manage inventory, and serve customers — even when the internet doesn't cooperate." />
</svelte:head>

<div class="min-h-screen theme-gradient-page transition-theme">
	<!-- Navigation -->
	<nav class="border-b theme-nav backdrop-blur-md fixed top-0 w-full z-50 transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<a href="/" class="flex items-center">
					<span class="text-2xl font-bold theme-logo transition-theme">Kemani</span>
					<span class="ml-2 text-sm theme-logo-subtitle transition-theme">POS</span>
				</a>
				<div class="hidden md:flex items-center gap-6">
					<a href="#features" class="theme-nav-link transition text-sm">
						Features
					</a>
					<a href="#benefits" class="theme-nav-link transition text-sm">
						Benefits
					</a>
					<a href="/pricing" class="theme-nav-link transition text-sm">
						Pricing
					</a>
					<ThemeToggle />
					<a
						href="/auth/signin"
						class="px-4 py-2 theme-btn-outline border rounded-lg transition text-sm"
					>
						Sign In
					</a>
					<a
						href="/auth/signup"
						class="px-4 py-2 bg-gradient-to-r from-emerald-600 to-green-600 text-white rounded-lg hover:from-emerald-500 hover:to-green-500 transition text-sm font-medium"
					>
						Start Free
					</a>
				</div>
			</div>
		</div>
	</nav>

	<!-- Hero Section -->
	<section class="pt-24 pb-16 px-4 sm:px-6 lg:px-8">
		<div class="max-w-6xl mx-auto">
			<div class="text-center">
				<h1 class="text-4xl sm:text-5xl md:text-6xl font-bold theme-heading mb-6 leading-tight">
					Your Business Never Stops.
					<br />
					<span class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-300">
						Neither Should Your POS.
					</span>
				</h1>
				<p class="text-lg sm:text-xl theme-text-muted mb-8 max-w-3xl mx-auto leading-relaxed">
					Nigeria's first offline-first POS platform. Process sales, manage inventory, and serve customers — even when the internet doesn't cooperate.
				</p>
				<div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
					<a
						href="/auth/signup?plan=free"
						class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-3 bg-gradient-to-r from-emerald-600 to-green-600 text-white font-semibold rounded-lg hover:from-emerald-500 hover:to-green-500 transition shadow-lg"
					>
						Start Free Forever
						<ArrowRight class="ml-2 h-5 w-5" />
					</a>
					<a
						href="#features"
						class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-3 theme-btn-outline backdrop-blur-md font-semibold rounded-lg border transition"
					>
						Learn More
					</a>
				</div>
				<p class="mt-4 text-sm theme-text-muted">
					Forever free plan • No credit card required • Upgrade anytime
				</p>
			</div>

			<!-- Trust Badges -->
			<div class="mt-16 grid grid-cols-2 sm:grid-cols-4 gap-4 max-w-4xl mx-auto">
				{#each [
					{ label: "Start Free", value: "₦0" },
					{ label: "Works Offline", value: "24/7" },
					{ label: "Nigeria-First", value: "Built for You" },
					{ label: "From", value: "₦5K/mo" }
				] as badge}
					<div class="text-center bg-white/5 backdrop-blur-sm rounded-lg p-4 border border-emerald-500/20 hover:border-emerald-400/40 transition">
						<div class="text-2xl sm:text-3xl font-bold theme-logo">{badge.value}</div>
						<div class="text-xs sm:text-sm theme-text-muted mt-1">{badge.label}</div>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- Problem Statement -->
	<section class="py-20 theme-gradient-section backdrop-blur-sm transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="max-w-3xl mx-auto text-center">
				<h2 class="text-3xl md:text-4xl font-bold theme-heading mb-6">
					Tired of Losing Sales When Internet Cuts?
				</h2>
				<p class="text-lg theme-text-muted mb-8">
					Traditional POS systems fail when you need them most. Every minute of downtime costs you money.
					Your customers won't wait, and your competitors won't sleep.
				</p>
				<div class="grid md:grid-cols-3 gap-6 mt-12">
					{#each [
						{ problem: "Internet outages", impact: "Lost sales & frustrated customers" },
						{ problem: "Expensive systems", impact: "High setup costs & monthly fees" },
						{ problem: "Complex software", impact: "Hours of training & wasted time" }
					] as item}
						<div class="p-6 bg-white/5 backdrop-blur-md rounded-lg border border-red-500/30">
							<div class="text-red-600 dark:text-red-400 font-semibold mb-2">{item.problem}</div>
							<div class="theme-text-muted text-sm">{item.impact}</div>
						</div>
					{/each}
				</div>
			</div>
		</div>
	</section>

	<!-- Features Section -->
	<section id="features" class="py-16 sm:py-20">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-12">
				<h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-4">
					Everything You Need to Run Your Business
				</h2>
				<p class="text-base sm:text-lg theme-text-muted max-w-2xl mx-auto">
					From in-store sales to online orders, delivery to analytics — all in one platform.
				</p>
			</div>

			<div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
				{#each [
					{
						icon: Zap,
						title: "Offline-First POS",
						description: "Process sales and print receipts even when internet is down. Automatic sync when you're back online."
					},
					{
						icon: ShoppingBag,
						title: "Online Marketplace",
						description: "Reach nearby customers with your digital storefront. They browse, order, and pay while you fulfill."
					},
					{
						icon: Smartphone,
						title: "WhatsApp & AI Chat",
						description: "Take orders via WhatsApp and AI chat agent. Your customers shop on their phones."
					},
					{
						icon: TrendingUp,
						title: "Smart Analytics",
						description: "See what's selling, when, and who's buying. Make data-driven decisions to grow revenue."
					},
					{
						icon: MessageSquare,
						title: "Delivery Management",
						description: "Local bike delivery or inter-city shipping — we handle the logistics while you serve customers."
					},
					{
						icon: Shield,
						title: "Multi-Branch",
						description: "Manage multiple locations from one dashboard. Track inventory, sales, and staff in real-time."
					}
				] as feature}
					<div class="p-6 bg-white/5 backdrop-blur-md rounded-xl hover:bg-white/10 transition border border-emerald-500/20 hover:border-emerald-400/40 group">
						<div class="w-12 h-12 bg-emerald-500/20 rounded-lg flex items-center justify-center mb-4 group-hover:bg-emerald-500/30 transition">
							<svelte:component this={feature.icon} class="h-6 w-6 theme-logo" />
						</div>
						<h3 class="text-lg font-semibold theme-heading mb-2">{feature.title}</h3>
						<p class="text-sm theme-text-muted leading-relaxed">{feature.description}</p>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- Benefits Section -->
	<section id="benefits" class="py-20 theme-gradient-cta backdrop-blur-sm text-white transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-16">
				<h2 class="text-3xl md:text-4xl font-bold mb-4">
					Built for Nigerian Businesses, By Nigerians
				</h2>
				<p class="text-lg text-emerald-50/90 max-w-2xl mx-auto">
					We understand your challenges because we've lived them. That's why Kemani works the way Nigerian businesses actually operate.
				</p>
			</div>

			<div class="grid md:grid-cols-2 gap-12 items-center">
				<div class="space-y-6">
					{#each [
						{
							title: "Works on Low-End Devices",
							description: "Runs smoothly on affordable Android phones with 2GB RAM. No expensive hardware required."
						},
						{
							title: "Phone Number Authentication",
							description: "Sign in with your phone number and OTP. No complicated passwords to remember."
						},
						{
							title: "Naira-Native Pricing",
							description: "Pay in Naira through Paystack or Flutterwave. No hidden forex charges or surprise fees."
						},
						{
							title: "3G-Optimized Performance",
							description: "Designed to work fast even on slow internet connections. Because we know Nigerian network reality."
						}
					] as benefit}
						<div class="flex items-start">
							<div class="flex-shrink-0 w-6 h-6 bg-green-400 rounded-full flex items-center justify-center mr-4 mt-1">
								<svg class="w-4 h-4 text-green-900" fill="currentColor" viewBox="0 0 20 20">
									<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
								</svg>
							</div>
							<div>
								<h3 class="text-xl font-semibold mb-2">{benefit.title}</h3>
								<p class="text-emerald-50/80">{benefit.description}</p>
							</div>
						</div>
					{/each}
				</div>

				<div class="bg-white/10 backdrop-blur-md rounded-2xl p-8 border border-white/20">
					<h3 class="text-2xl font-bold mb-6">Real Results from Real Businesses</h3>
					<div class="space-y-6">
						<blockquote class="border-l-4 border-green-300 pl-4">
							<p class="text-emerald-50/90 mb-2">
								"We haven't lost a single sale since switching to Kemani. Even during NEPA outages, our POS just works."
							</p>
							<footer class="text-sm text-emerald-100/70">— Pharmacy Owner, Ikeja</footer>
						</blockquote>
						<blockquote class="border-l-4 border-green-300 pl-4">
							<p class="text-emerald-50/90 mb-2">
								"Our online orders tripled in 2 months. The WhatsApp integration is a game-changer."
							</p>
							<footer class="text-sm text-emerald-100/70">— Supermarket Manager, Lekki</footer>
						</blockquote>
					</div>
				</div>
			</div>
		</div>
	</section>

	<!-- Use Cases -->
	<section class="py-20">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-16">
				<h2 class="text-3xl md:text-4xl font-bold theme-heading mb-4">
					Perfect for Every Type of Business
				</h2>
			</div>

			<div class="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
				{#each [
					{ type: "Pharmacies", icon: "💊", use: "Manage prescriptions, track expiry dates, serve walk-in customers" },
					{ type: "Supermarkets", icon: "🛒", use: "Handle high transaction volumes, bulk imports, multiple cashiers" },
					{ type: "Restaurants", icon: "🍽️", use: "Table management, order tracking, delivery coordination" },
					{ type: "Mini-Marts", icon: "🏪", use: "Quick sales, inventory alerts, customer loyalty programs" }
				] as useCase}
					<div class="p-6 bg-gradient-to-br from-emerald-500/10 to-green-500/10 backdrop-blur-sm rounded-xl text-center border border-emerald-500/30 hover:border-emerald-400/50 transition">
						<div class="text-5xl mb-4">{useCase.icon}</div>
						<h3 class="text-xl font-semibold theme-heading mb-2">{useCase.type}</h3>
						<p class="theme-text-muted text-sm">{useCase.use}</p>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- CTA Section -->
	<section class="py-20 theme-gradient-cta backdrop-blur-sm text-white transition-theme">
		<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
			<h2 class="text-3xl md:text-4xl font-bold mb-6">
				Stop Losing Money to Internet Outages
			</h2>
			<p class="text-xl text-emerald-50/90 mb-8">
				Join hundreds of Nigerian businesses that never miss a sale. Start free forever — no credit card required.
			</p>
			<div class="flex flex-col sm:flex-row gap-4 justify-center">
				<a
					href="/auth/signup?plan=free"
					class="inline-flex items-center px-8 py-4 bg-white text-emerald-600 text-lg font-semibold rounded-lg hover:bg-emerald-50 transition shadow-lg hover:shadow-xl"
				>
					Start Free Forever
					<ArrowRight class="ml-2 h-5 w-5" />
				</a>
				<a
					href="/pricing"
					class="inline-flex items-center px-8 py-4 bg-transparent text-white text-lg font-semibold rounded-lg border-2 border-white hover:bg-white/10 backdrop-blur-sm transition"
				>
					View Pricing
				</a>
			</div>
			<p class="mt-6 text-sm text-emerald-100/70">
				Setup takes less than 10 minutes • Import your products via CSV • Start selling immediately
			</p>
		</div>
	</section>

	<!-- Footer -->
	<footer class="bg-gray-900 text-gray-300 py-12 border-t border-emerald-800/30">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="grid md:grid-cols-4 gap-8">
				<div>
					<div class="flex items-center mb-4">
						<span class="text-2xl font-bold text-emerald-400">Kemani</span>
						<span class="ml-2 text-sm text-emerald-300/70">POS</span>
					</div>
					<p class="text-sm text-gray-400">
						Offline-first POS platform built for Nigerian businesses.
					</p>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Product</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="#features" class="hover:text-emerald-400 transition">Features</a></li>
						<li><a href="/pricing" class="hover:text-emerald-400 transition">Pricing</a></li>
						<li><a href="#demo" class="hover:text-emerald-400 transition">Demo</a></li>
					</ul>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Support</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/docs" class="hover:text-emerald-400 transition">Documentation</a></li>
						<li><a href="/support" class="hover:text-emerald-400 transition">Help Center</a></li>
						<li><a href="/contact" class="hover:text-emerald-400 transition">Contact Us</a></li>
					</ul>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Legal</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/privacy" class="hover:text-emerald-400 transition">Privacy Policy</a></li>
						<li><a href="/terms" class="hover:text-emerald-400 transition">Terms of Service</a></li>
					</ul>
				</div>
			</div>

			<div class="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
				<p>&copy; {new Date().getFullYear()} Kemani POS. All rights reserved. Built with ❤️ for Nigerian businesses.</p>
			</div>
		</div>
	</footer>
</div>
