<script lang="ts">
	import { Check, ArrowRight, Zap, TrendingUp, Crown, Sparkles, Phone } from 'lucide-svelte';
	import ThemeToggle from '$lib/components/ThemeToggle.svelte';

	const pricingPlans = [
		{
			name: "Free",
			icon: Zap,
			description: "Get started with basic POS features",
			price: "₦0",
			period: "/month",
			annual: "Forever free",
			features: [
				"1 branch location",
				"1 staff user",
				"Up to 100 products",
				"500 transactions/month",
				"Cloud-only POS (requires internet)",
				"Basic inventory management",
				"Sales receipts with branding",
				"CSV product import",
				"Email support",
				"0% commission (no marketplace)"
			],
			limitations: [
				"No offline mode",
				"No online marketplace",
				"No AI features",
				"No WhatsApp integration",
				"No delivery management",
				"No e-commerce sync"
			],
			cta: "Start Free Forever",
			href: "/auth/signup?plan=free",
			popular: false,
			color: "gray"
		},
		{
			name: "Basic",
			icon: TrendingUp,
			description: "Perfect for small shops expanding operations",
			price: "₦5,000",
			period: "/month",
			annual: "₦55,000/year (Save ₦5,000)",
			features: [
				"Up to 3 branch locations",
				"Up to 10 staff users",
				"Unlimited products",
				"Unlimited transactions",
				"Offline-first POS (works without internet)",
				"AI chat agent for customer inquiries",
				"WhatsApp Business API integration",
				"Inter-branch inventory transfers",
				"Local & inter-city delivery management",
				"Priority email support",
				"0% commission (no e-commerce)"
			],
			limitations: [
				"No online marketplace",
				"No e-commerce platform sync",
				"No advanced analytics",
				"No API access"
			],
			cta: "Start 30-Day Free Trial",
			href: "/auth/signup?plan=basic",
			popular: false,
			color: "emerald"
		},
		{
			name: "Pro",
			icon: Crown,
			description: "For growing businesses selling online",
			price: "₦15,000",
			period: "/month",
			annual: "₦165,000/year (Save ₦15,000)",
			features: [
				"Up to 10 branch locations",
				"Up to 50 staff users",
				"Unlimited products",
				"Unlimited transactions",
				"Everything in Basic, plus:",
				"Online marketplace storefront",
				"AI-powered e-commerce chat",
				"WooCommerce & Shopify sync",
				"Advanced analytics & insights",
				"Bulk import/export",
				"API access for integrations",
				"Priority support (phone & email)",
				"1.5% commission on marketplace sales (capped at ₦500/order)"
			],
			limitations: [],
			cta: "Start 30-Day Free Trial",
			href: "/auth/signup?plan=pro",
			popular: true,
			color: "emerald"
		},
		{
			name: "Enterprise",
			icon: Sparkles,
			description: "Complete platform for established businesses",
			price: "₦50,000",
			period: "/month",
			annual: "₦550,000/year (Save ₦50,000)",
			features: [
				"Unlimited branch locations",
				"Unlimited staff users",
				"Unlimited products",
				"Unlimited transactions",
				"Everything in Pro, plus:",
				"Multi-currency support",
				"Dedicated account manager",
				"24/7 phone support",
				"Custom reporting & analytics",
				"SLA guarantees (99.9% uptime)",
				"Priority feature requests",
				"Data export capabilities",
				"1% commission on marketplace sales (capped at ₦500/order)"
			],
			limitations: [],
			cta: "Start 30-Day Free Trial",
			href: "/auth/signup?plan=enterprise",
			popular: false,
			color: "green"
		},
		{
			name: "Enterprise Custom",
			icon: Phone,
			description: "Tailored solutions for unique business needs",
			price: "Custom",
			period: "pricing",
			annual: "Contact sales for quote",
			features: [
				"Everything in Enterprise, plus:",
				"Custom domain & white-label branding",
				"Custom integrations via dedicated API",
				"On-premise deployment option",
				"Custom feature development",
				"24/7 dedicated support team",
				"Custom SLA agreements",
				"Direct engineering support",
				"Advanced security & compliance",
				"Custom data retention policies",
				"Negotiable commission (0.5% default, capped at ₦500/order)"
			],
			limitations: [],
			cta: "Contact Sales",
			href: "/contact?plan=enterprise_custom",
			popular: false,
			color: "teal"
		}
	];
</script>

<svelte:head>
	<title>Pricing - Kemani POS</title>
	<meta name="description" content="Simple, transparent pricing. Start free, upgrade when you need more. No hidden fees, no surprises." />
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
				<div class="flex items-center gap-6">
					<a href="/" class="theme-nav-link transition text-sm">
						Home
					</a>
					<a href="/#features" class="theme-nav-link transition text-sm">
						Features
					</a>
					<a href="/pricing" class="theme-logo font-medium text-sm">
						Pricing
					</a>
					<ThemeToggle />
					<a
						href="/auth/signin"
						class="px-4 py-2 theme-btn-outline border rounded-lg backdrop-blur-sm transition text-sm"
					>
						Sign In
					</a>
				</div>
			</div>
		</div>
	</nav>

	<!-- Hero -->
	<section class="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
		<div class="max-w-4xl mx-auto text-center">
			<h1 class="text-4xl sm:text-5xl md:text-6xl font-bold theme-heading mb-6">
				Simple, Transparent Pricing
			</h1>
			<p class="text-lg sm:text-xl theme-text-muted mb-6">
				Start free, upgrade when you need more. No hidden fees, no surprises.
			</p>
			<div class="inline-flex items-center px-4 py-2 bg-emerald-500/20 backdrop-blur-sm theme-logo rounded-full text-sm font-medium border border-emerald-500/30">
				<Check class="h-4 w-4 mr-2" />
				All paid plans include a 30-day free trial
			</div>
		</div>
	</section>

	<!-- Pricing Cards -->
	<section class="pb-16 px-4 sm:px-6 lg:px-8">
		<div class="max-w-7xl mx-auto">
			<!-- Main Plans -->
			<div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
				{#each pricingPlans.slice(0, 3) as plan}
					<div
						class="relative bg-white/5 backdrop-blur-md rounded-xl shadow-lg border {plan.popular
							? 'border-emerald-500/60 ring-2 ring-emerald-500/20 lg:scale-105'
							: 'border-emerald-800/30'} overflow-hidden transition hover:shadow-xl hover:shadow-emerald-500/10"
					>
						{#if plan.popular}
							<div class="absolute top-0 right-0 bg-gradient-to-r from-emerald-600 to-green-600 text-white px-3 py-1 text-xs font-semibold rounded-bl-lg">
								Most Popular
							</div>
						{/if}

						<div class="p-6">
							<!-- Header -->
							<div class="flex items-center mb-3">
								<div class="w-10 h-10 bg-emerald-500/20 rounded-lg flex items-center justify-center mr-3">
									<svelte:component this={plan.icon} class="h-5 w-5 theme-logo" />
								</div>
								<h3 class="text-xl font-bold theme-heading">{plan.name}</h3>
							</div>
							<p class="text-sm theme-text-muted mb-6">{plan.description}</p>

							<!-- Pricing -->
							<div class="mb-5">
								<div class="flex items-baseline">
									<span class="text-3xl sm:text-4xl font-bold theme-heading">{plan.price}</span>
									<span class="theme-text-muted ml-2 text-sm">{plan.period}</span>
								</div>
								<p class="text-xs mt-1 font-medium theme-logo">
									{plan.annual}
								</p>
							</div>

							<!-- CTA -->
							<a
								href={plan.href}
								class="block w-full py-2.5 px-6 text-center text-sm font-semibold rounded-lg transition {plan.popular
									? 'bg-gradient-to-r from-emerald-600 to-green-600 text-white hover:from-emerald-500 hover:to-green-500 shadow-md shadow-emerald-500/20'
									: plan.name === 'Free'
									? 'bg-emerald-600 text-white hover:bg-emerald-500 shadow-md'
									: 'bg-emerald-500/20 text-emerald-300 hover:bg-emerald-500/30 border border-emerald-500/30'}"
							>
								{plan.cta}
							</a>

							<!-- Features -->
							<div class="mt-6 space-y-3">
								<div class="text-sm font-semibold theme-heading mb-2">What's included:</div>
								<ul class="space-y-2">
									{#each plan.features as feature}
										<li class="flex items-start">
											<Check class="h-4 w-4 theme-logo mr-2 flex-shrink-0 mt-0.5" />
											<span class="theme-text-muted text-xs leading-relaxed">{feature}</span>
										</li>
									{/each}
								</ul>

								{#if plan.limitations.length > 0}
									<div class="mt-4 pt-4 border-t border-emerald-800/30">
										<div class="text-xs theme-text-muted opacity-70 space-y-1">
											<div class="font-medium mb-1">Not included:</div>
											{#each plan.limitations as limitation}
												<div>• {limitation}</div>
											{/each}
										</div>
									</div>
								{/if}
							</div>
						</div>
					</div>
				{/each}
			</div>

			<!-- Enterprise Plans -->
			<div class="grid sm:grid-cols-2 gap-6 max-w-4xl mx-auto">
				{#each pricingPlans.slice(3, 5) as plan}
					{@const isCustom = plan.name === "Enterprise Custom"}
					<div
						class="relative bg-white/5 backdrop-blur-md rounded-2xl shadow-lg border-2 {isCustom
							? 'border-teal-500/40'
							: 'border-emerald-800/30'} overflow-hidden transition hover:shadow-xl hover:shadow-emerald-500/10"
					>
						<div class="p-8">
							<!-- Header -->
							<div class="flex items-center mb-4">
								<div class="w-12 h-12 bg-emerald-500/20 rounded-lg flex items-center justify-center mr-3">
									<svelte:component this={plan.icon} class="h-6 w-6 theme-logo" />
								</div>
								<div>
									<h3 class="text-2xl font-bold theme-heading">{plan.name}</h3>
								</div>
							</div>
							<p class="theme-text-muted mb-6">{plan.description}</p>

							<!-- Pricing -->
							<div class="mb-6">
								<div class="flex items-baseline">
									<span class="text-4xl font-bold theme-heading">{plan.price}</span>
									<span class="theme-text-muted ml-2">{plan.period}</span>
								</div>
								<p class="text-sm mt-2 font-medium theme-logo">
									{plan.annual}
								</p>
							</div>

							<!-- CTA -->
							<a
								href={plan.href}
								class="block w-full py-3 px-6 text-center font-semibold rounded-lg transition {isCustom
									? 'bg-gradient-to-r from-teal-600 to-emerald-600 text-white hover:from-teal-500 hover:to-emerald-500 shadow-md shadow-teal-500/20'
									: 'bg-gradient-to-r from-green-600 to-emerald-600 text-white hover:from-green-500 hover:to-emerald-500 shadow-md shadow-green-500/20'}"
							>
								{plan.cta}
							</a>

							<!-- Features -->
							<div class="mt-6 space-y-3">
								<div class="text-sm font-semibold theme-heading mb-2">What's included:</div>
								<ul class="space-y-2">
									{#each plan.features as feature}
										<li class="flex items-start">
											<Check class="h-4 w-4 theme-logo mr-2 flex-shrink-0 mt-0.5" />
											<span class="theme-text-muted text-xs leading-relaxed">{feature}</span>
										</li>
									{/each}
								</ul>

								{#if plan.limitations.length > 0}
									<div class="mt-4 pt-4 border-t border-emerald-800/30">
										<div class="text-xs theme-text-muted opacity-70 space-y-1">
											<div class="font-medium mb-1">Not included:</div>
											{#each plan.limitations as limitation}
												<div>• {limitation}</div>
											{/each}
										</div>
									</div>
								{/if}
							</div>
						</div>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- Feature Comparison Table -->
	<section class="py-16 theme-gradient-section backdrop-blur-sm transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-10">
				<h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-3">
					Compare All Features
				</h2>
				<p class="text-sm sm:text-base theme-text-muted">
					See exactly what's included in each plan
				</p>
			</div>

			<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg overflow-hidden border border-emerald-800/30">
				<div class="overflow-x-auto">
					<table class="w-full min-w-[600px]">
						<thead class="bg-emerald-500/10 backdrop-blur-sm">
							<tr>
								<th class="px-4 py-3 text-left text-xs font-semibold theme-heading">
									Feature
								</th>
								<th class="px-3 py-3 text-center text-xs font-semibold theme-heading">
									Free
								</th>
								<th class="px-3 py-3 text-center text-xs font-semibold theme-heading">
									Basic
								</th>
								<th class="px-3 py-3 text-center text-xs font-semibold theme-heading">
									Pro
								</th>
								<th class="px-3 py-3 text-center text-xs font-semibold theme-heading">
									Enterprise
								</th>
								<th class="px-3 py-3 text-center text-xs font-semibold theme-heading">
									Custom
								</th>
							</tr>
						</thead>
						<tbody class="divide-y divide-emerald-800/20">
							{#each [
								{ feature: "Branch Locations", free: "1", basic: "3", pro: "10", enterprise: "Unlimited", custom: "Unlimited" },
								{ feature: "Staff Users", free: "1", basic: "10", pro: "50", enterprise: "Unlimited", custom: "Unlimited" },
								{ feature: "Products", free: "100", basic: "Unlimited", pro: "Unlimited", enterprise: "Unlimited", custom: "Unlimited" },
								{ feature: "Monthly Transactions", free: "500", basic: "Unlimited", pro: "Unlimited", enterprise: "Unlimited", custom: "Unlimited" },
								{ feature: "Offline-First POS", free: false, basic: true, pro: true, enterprise: true, custom: true },
								{ feature: "Inventory Management", free: true, basic: true, pro: true, enterprise: true, custom: true },
								{ feature: "CSV Import", free: true, basic: true, pro: true, enterprise: true, custom: true },
								{ feature: "AI Chat Agent", free: false, basic: true, pro: true, enterprise: true, custom: true },
								{ feature: "WhatsApp Integration", free: false, basic: true, pro: true, enterprise: true, custom: true },
								{ feature: "Delivery Management", free: false, basic: true, pro: true, enterprise: true, custom: true },
								{ feature: "Inter-Branch Transfers", free: false, basic: true, pro: true, enterprise: true, custom: true },
								{ feature: "Online Marketplace", free: false, basic: false, pro: true, enterprise: true, custom: true },
								{ feature: "E-Commerce Chat", free: false, basic: false, pro: true, enterprise: true, custom: true },
								{ feature: "WooCommerce Sync", free: false, basic: false, pro: true, enterprise: true, custom: true },
								{ feature: "Shopify Sync", free: false, basic: false, pro: true, enterprise: true, custom: true },
								{ feature: "Advanced Analytics", free: false, basic: false, pro: true, enterprise: true, custom: true },
								{ feature: "API Access", free: false, basic: false, pro: true, enterprise: true, custom: true },
								{ feature: "Multi-Currency", free: false, basic: false, pro: false, enterprise: true, custom: true },
								{ feature: "Custom Domain", free: false, basic: false, pro: false, enterprise: false, custom: true },
								{ feature: "White Label", free: false, basic: false, pro: false, enterprise: false, custom: true },
								{ feature: "Marketplace Commission", free: "0%", basic: "0%", pro: "1.5%", enterprise: "1%", custom: "0.5%" },
								{ feature: "Commission Cap", free: "N/A", basic: "N/A", pro: "₦500/order", enterprise: "₦500/order", custom: "₦500/order" },
								{ feature: "Support", free: "Email", basic: "Priority Email", pro: "Phone & Email", enterprise: "24/7 Phone", custom: "24/7 Dedicated" }
							] as row}
								<tr class="hover:bg-white/5 transition">
									<td class="px-4 py-3 text-xs theme-heading font-medium">
										{row.feature}
									</td>
									{#each ['free', 'basic', 'pro', 'enterprise', 'custom'] as tier}
										<td class="px-3 py-3 text-center text-xs">
											{#if typeof row[tier] === "boolean"}
												{#if row[tier]}
													<Check class="h-4 w-4 theme-logo mx-auto" />
												{:else}
													<span class="theme-text-muted opacity-30">—</span>
												{/if}
											{:else}
												<span class="theme-text-muted">{row[tier]}</span>
											{/if}
										</td>
									{/each}
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</section>

	<!-- FAQ -->
	<section class="py-16">
		<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-10">
				<h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-3">
					Frequently Asked Questions
				</h2>
			</div>

			<div class="space-y-4">
				{#each [
					{
						question: "What's the difference between cloud-only (Free) and offline-first (paid plans)?",
						answer: "The Free plan requires internet connection to process sales and access your data. Paid plans (Basic and above) work completely offline, storing data locally on your device and syncing automatically when internet becomes available. This means you never lose a sale due to internet issues."
					},
					{
						question: "Can I change plans later?",
						answer: "Absolutely! You can upgrade or downgrade your plan at any time. Changes take effect immediately, and we'll prorate your billing accordingly. Your data stays intact when switching plans."
					},
					{
						question: "What payment methods do you accept?",
						answer: "We accept all major payment methods through Paystack and Flutterwave including card payments, bank transfers, and mobile money. All payments are in Nigerian Naira (₦)."
					},
					{
						question: "What happens when I exceed my plan limits?",
						answer: "We'll notify you when you're approaching your limits. You can upgrade to a higher plan at any time. We'll never interrupt your business operations — you'll always have access to your existing data."
					},
					{
						question: "Is the 30-day free trial really free?",
						answer: "Yes! All paid plans include a genuine 30-day free trial with full access to all features in your chosen plan. No credit card required to start. The Free plan is always free with no trial needed."
					},
					{
						question: "How does marketplace commission work?",
						answer: "Commission only applies when customers order through your online storefront (Pro, Enterprise, and Custom plans only). In-store POS sales have zero commission. All commissions are capped at ₦500 per order, regardless of order value."
					},
					{
						question: "What's included in the commission cap?",
						answer: "The ₦500 commission cap means you'll never pay more than ₦500 per marketplace order, even on large orders. For example, a ₦100,000 order at 1.5% would normally be ₦1,500 commission, but you only pay ₦500."
					},
					{
						question: "What does 'unlimited products and transactions' mean?",
						answer: "From the Basic plan upwards, there are no limits on the number of products you can add to your inventory or the number of transactions you can process monthly. This means your business can scale without worrying about hitting usage caps."
					},
					{
						question: "Can I use Kemani without internet on the Free plan?",
						answer: "No, the Free plan requires internet connection for all operations. If you need offline functionality, upgrade to Basic or higher plans which include full offline-first POS capabilities with automatic sync."
					},
					{
						question: "Do you offer custom enterprise solutions?",
						answer: "Yes! Our Enterprise Custom plan offers white-label branding, custom domains, dedicated infrastructure, custom development, and negotiable pricing. Contact our sales team to discuss your specific requirements."
					}
				] as faq}
					<div class="bg-white/5 backdrop-blur-md rounded-lg shadow-sm p-5 border border-emerald-800/30 hover:border-emerald-700/40 transition">
						<h3 class="text-base font-semibold theme-heading mb-2">
							{faq.question}
						</h3>
						<p class="text-sm theme-text-muted leading-relaxed">
							{faq.answer}
						</p>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- CTA -->
	<section class="py-16 theme-gradient-cta backdrop-blur-sm text-white transition-theme">
		<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
			<h2 class="text-3xl sm:text-4xl font-bold mb-4">
				Ready to Transform Your Business?
			</h2>
			<p class="text-base sm:text-lg text-emerald-50/90 mb-6">
				Start free today, no credit card required. Upgrade when ready.
			</p>
			<div class="flex flex-col sm:flex-row gap-3 justify-center items-center">
				<a
					href="/auth/signup?plan=free"
					class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-3 bg-white text-emerald-600 font-semibold rounded-lg hover:bg-emerald-50 transition shadow-lg"
				>
					Start Free Forever
					<ArrowRight class="ml-2 h-5 w-5" />
				</a>
				<a
					href="/contact"
					class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-3 bg-transparent text-white font-semibold rounded-lg border-2 border-white hover:bg-white/10 backdrop-blur-sm transition"
				>
					Talk to Sales
				</a>
			</div>
			<p class="mt-4 text-sm text-emerald-100/70">
				Questions? <a href="/contact" class="underline hover:text-white">Contact our team</a>
			</p>
		</div>
	</section>

	<!-- Footer -->
	<footer class="bg-gray-900 text-gray-300 py-12 border-t border-emerald-800/30">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="grid md:grid-cols-4 gap-8">
				<div>
					<a href="/" class="flex items-center mb-4">
						<span class="text-2xl font-bold text-emerald-400">Kemani</span>
						<span class="ml-2 text-sm text-emerald-300/70">POS</span>
					</a>
					<p class="text-sm text-gray-400">
						Offline-first POS platform built for Nigerian businesses.
					</p>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Product</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/#features" class="hover:text-emerald-400 transition">Features</a></li>
						<li><a href="/pricing" class="hover:text-emerald-400 transition">Pricing</a></li>
						<li><a href="/#demo" class="hover:text-emerald-400 transition">Demo</a></li>
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
