<script lang="ts">
	import { Check, ArrowRight, Zap, Crown, Sparkles, Phone, Globe, Video } from 'lucide-svelte';
	import ThemeToggle from '$lib/components/ThemeToggle.svelte';

	const pricingPlans = [
		{
			name: "Free",
			icon: Zap,
			description: "Perfect for starting your telemedicine journey",
			price: "₦0",
			period: "/month",
			annual: "Forever free",
			features: [
				"List your profile on medic.kemani.com",
				"Chat consultations only",
				"Basic patient management",
				"Up to 10 consultations/month",
				"Digital prescriptions",
				"Automated pharmacy routing",
				"Email support",
				"Standard availability templates",
				"Paystack/Flutterwave integration",
				"15% platform commission on consultations"
			],
			limitations: [
				"No video/audio consultations",
				"No custom branding",
				"No custom domain",
				"Limited to 10 consultations/month",
				"No dedicated support"
			],
			cta: "Start Free Forever",
			href: "/auth/signup?plan=medic_free",
			popular: false,
			color: "gray"
		},
		{
			name: "Pro",
			icon: Crown,
			description: "For established practitioners scaling their practice",
			price: "₦25,000",
			period: "/month",
			annual: "₦275,000/year (Save ₦25,000)",
			features: [
				"Everything in Free, plus:",
				"Unlimited consultations",
				"Video consultations (Agora integration)",
				"Audio consultations (Agora integration)",
				"Office visit scheduling",
				"Advanced patient records",
				"Custom clinic branding (logo, colors)",
				"Priority listing on marketplace",
				"Enhanced profile with bio & credentials",
				"Multi-consultation type support",
				"Advanced availability management",
				"Real-time notifications",
				"Priority email support",
				"Analytics dashboard",
				"10% platform commission (reduced)"
			],
			limitations: [
				"No custom domain",
				"No white-label branding",
				"No API access",
				"No dedicated account manager"
			],
			cta: "Start 30-Day Free Trial",
			href: "/auth/signup?plan=medic_pro",
			popular: true,
			color: "emerald"
		},
		{
			name: "Enterprise Custom",
			icon: Sparkles,
			description: "White-label solution for healthcare organizations",
			price: "Custom",
			period: "pricing",
			annual: "Contact sales for quote",
			features: [
				"Everything in Pro, plus:",
				"Custom domain & SSL (clinic.yourdomain.com)",
				"Full white-label branding",
				"Remove Kemani branding entirely",
				"Custom consultation workflows",
				"Multi-provider organization support",
				"Dedicated Agora channels (enhanced quality)",
				"Custom integrations via API",
				"Dedicated account manager",
				"24/7 priority phone support",
				"Custom SLA agreements",
				"On-premise deployment option",
				"Advanced security & compliance",
				"Custom reporting & analytics",
				"5% platform commission (negotiable)"
			],
			limitations: [],
			cta: "Contact Sales",
			href: "/contact?plan=medic_enterprise",
			popular: false,
			color: "teal"
		}
	];

	const consultationFees = [
		{ type: "Chat", suggested: "₦3,000 - ₦8,000", duration: "Asynchronous" },
		{ type: "Audio", suggested: "₦5,000 - ₦12,000", duration: "15-60 min" },
		{ type: "Video", suggested: "₦8,000 - ₦20,000", duration: "15-60 min" },
		{ type: "Office Visit", suggested: "₦10,000 - ₦30,000", duration: "30-60 min" }
	];

	const agoraFeatures = [
		"HD video quality up to 1080p",
		"Low latency (< 300ms globally)",
		"99.9% uptime SLA",
		"Cross-platform support (web, mobile, desktop)",
		"Automatic bandwidth optimization",
		"Screen sharing & recording capabilities"
	];
</script>

<svelte:head>
	<title>Pricing - Kemani Medic</title>
	<meta name="description" content="Simple, transparent pricing for healthcare providers. Start free or scale with Pro/Enterprise plans. Custom domains available." />
</svelte:head>

<div class="min-h-screen theme-gradient-page transition-theme">
	<!-- Navigation -->
	<nav class="border-b theme-nav backdrop-blur-md fixed top-0 w-full z-50 transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<a href="/" class="flex items-center">
					<span class="text-2xl font-bold theme-logo transition-theme">Kemani</span>
					<span class="ml-2 text-sm theme-logo-subtitle transition-theme">Medic</span>
				</a>
				<div class="flex items-center gap-6">
					<a href="/" class="theme-nav-link transition text-sm">
						POS Platform
					</a>
					<a href="/medic" class="theme-nav-link transition text-sm">
						For Medics
					</a>
					<a href="/medic/pricing" class="theme-logo font-medium text-sm">
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
				Simple, Transparent Pricing for Healthcare Providers
			</h1>
			<p class="text-lg sm:text-xl theme-text-muted mb-6">
				Start free, upgrade when you're ready. You set the consultation fees—keep 85-95% of what you earn.
			</p>
			<div class="inline-flex items-center px-4 py-2 bg-emerald-500/20 backdrop-blur-sm theme-logo rounded-full text-sm font-medium border border-emerald-500/30">
				<Check class="h-4 w-4 mr-2" />
				Pro and Enterprise plans include a 30-day free trial
			</div>
		</div>
	</section>

	<!-- Pricing Cards -->
	<section class="pb-16 px-4 sm:px-6 lg:px-8">
		<div class="max-w-7xl mx-auto">
			<div class="grid md:grid-cols-3 gap-8">
				{#each pricingPlans as plan}
					{@const isEnterprise = plan.name === "Enterprise Custom"}
					<div
						class="relative bg-white/5 backdrop-blur-md rounded-xl shadow-lg border {plan.popular
							? 'border-emerald-500/60 ring-2 ring-emerald-500/20 md:scale-105'
							: 'border-emerald-800/30'} overflow-hidden transition hover:shadow-xl hover:shadow-emerald-500/10"
					>
						{#if plan.popular}
							<div class="absolute top-0 right-0 bg-gradient-to-r from-emerald-600 to-green-600 text-white px-3 py-1 text-xs font-semibold rounded-bl-lg">
								Most Popular
							</div>
						{/if}

						{#if isEnterprise}
							<div class="absolute top-0 left-0 bg-gradient-to-r from-teal-600 to-emerald-600 text-white px-3 py-1 text-xs font-semibold rounded-br-lg">
								Custom Domain
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
									: isEnterprise
									? 'bg-gradient-to-r from-teal-600 to-emerald-600 text-white hover:from-teal-500 hover:to-emerald-500 shadow-md shadow-teal-500/20'
									: 'bg-emerald-600 text-white hover:bg-emerald-500 shadow-md'}"
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

	<!-- Consultation Fee Guide -->
	<section class="py-16 theme-gradient-section backdrop-blur-sm transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-10">
				<h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-3">
					Suggested Consultation Fees
				</h2>
				<p class="text-sm sm:text-base theme-text-muted">
					You set your own prices. Here's what other Nigerian providers charge.
				</p>
			</div>

			<div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-6 max-w-5xl mx-auto">
				{#each consultationFees as fee}
					<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-6 text-center">
						<div class="text-2xl font-bold theme-logo mb-2">{fee.type}</div>
						<div class="text-sm theme-text-muted mb-3">{fee.duration}</div>
						<div class="text-lg font-semibold theme-heading">{fee.suggested}</div>
					</div>
				{/each}
			</div>

			<div class="mt-8 text-center">
				<p class="text-sm theme-text-muted max-w-2xl mx-auto">
					<strong class="theme-logo">You keep 85-95% of every consultation.</strong> Platform commission varies by plan: Free (15%), Pro (10%), Enterprise Custom (5% negotiable).
				</p>
			</div>
		</div>
	</section>

	<!-- Agora Video/Audio Section -->
	<section class="py-16 px-4 sm:px-6 lg:px-8">
		<div class="max-w-7xl mx-auto">
			<div class="bg-gradient-to-r from-emerald-600/20 to-green-600/20 backdrop-blur-md rounded-2xl shadow-lg border border-emerald-500/30 p-8 md:p-12">
				<div class="grid md:grid-cols-2 gap-8 items-center">
					<div>
						<div class="inline-flex items-center px-3 py-1 bg-emerald-500/30 backdrop-blur-sm theme-logo rounded-full text-xs font-medium border border-emerald-500/40 mb-4">
							<Video class="h-3 w-3 mr-2" />
							Powered by Agora
						</div>
						<h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-4">
							Enterprise-Grade Video & Audio Infrastructure
						</h2>
						<p class="theme-text-muted mb-6 leading-relaxed">
							Conduct high-quality video and audio consultations using Agora's global real-time engagement platform—the same technology trusted by companies like Tinder, Grab, and The Meet Group.
						</p>
						<div class="inline-flex items-center text-sm theme-logo font-medium">
							<Globe class="h-4 w-4 mr-2" />
							Available on Pro and Enterprise Custom plans
						</div>
					</div>
					<div>
						<ul class="space-y-3">
							{#each agoraFeatures as feature}
								<li class="flex items-start bg-white/5 backdrop-blur-sm rounded-lg p-3 border border-emerald-800/30">
									<Check class="h-5 w-5 theme-logo mr-3 flex-shrink-0 mt-0.5" />
									<span class="theme-heading font-medium">{feature}</span>
								</li>
							{/each}
						</ul>
					</div>
				</div>
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
									Pro
								</th>
								<th class="px-3 py-3 text-center text-xs font-semibold theme-heading">
									Enterprise
								</th>
							</tr>
						</thead>
						<tbody class="divide-y divide-emerald-800/20">
							{#each [
								{ feature: "Monthly Consultations", free: "10", pro: "Unlimited", enterprise: "Unlimited" },
								{ feature: "Chat Consultations", free: true, pro: true, enterprise: true },
								{ feature: "Video Consultations (Agora)", free: false, pro: true, enterprise: true },
								{ feature: "Audio Consultations (Agora)", free: false, pro: true, enterprise: true },
								{ feature: "Office Visit Scheduling", free: false, pro: true, enterprise: true },
								{ feature: "Patient Management", free: "Basic", pro: "Advanced", enterprise: "Advanced" },
								{ feature: "Digital Prescriptions", free: true, pro: true, enterprise: true },
								{ feature: "Pharmacy Routing", free: true, pro: true, enterprise: true },
								{ feature: "Custom Clinic Branding", free: false, pro: true, enterprise: true },
								{ feature: "Custom Domain", free: false, pro: false, enterprise: true },
								{ feature: "White-Label (Remove Kemani)", free: false, pro: false, enterprise: true },
								{ feature: "Priority Marketplace Listing", free: false, pro: true, enterprise: true },
								{ feature: "Analytics Dashboard", free: false, pro: true, enterprise: true },
								{ feature: "API Access", free: false, pro: false, enterprise: true },
								{ feature: "Multi-Provider Support", free: false, pro: false, enterprise: true },
								{ feature: "Platform Commission", free: "15%", pro: "10%", enterprise: "5%" },
								{ feature: "Support", free: "Email", pro: "Priority Email", enterprise: "24/7 Dedicated" }
							] as row}
								<tr class="hover:bg-white/5 transition">
									<td class="px-4 py-3 text-xs theme-heading font-medium">
										{row.feature}
									</td>
									{#each ['free', 'pro', 'enterprise'] as tier}
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
						question: "How does the platform commission work?",
						answer: "We take a small percentage of each completed consultation: 15% on the Free plan, 10% on Pro, and 5% on Enterprise Custom (negotiable). You keep the rest. For example, if you charge ₦10,000 for a video consultation on the Pro plan, you receive ₦9,000 and we take ₦1,000. All payments are processed instantly via Paystack or Flutterwave."
					},
					{
						question: "Can I set my own consultation fees?",
						answer: "Absolutely! You have complete control over your pricing for each consultation type (chat, video, audio, office visit). Our suggested fee ranges are just guidelines based on what other Nigerian providers charge."
					},
					{
						question: "What's included in the Agora video/audio integration?",
						answer: "Agora provides enterprise-grade real-time video and audio infrastructure with HD quality (up to 1080p), low latency (<300ms globally), 99.9% uptime, cross-platform support, automatic bandwidth optimization, and screen sharing capabilities. It's the same technology used by major platforms like Tinder and Grab."
					},
					{
						question: "How does the custom domain work on Enterprise Custom?",
						answer: "With the Enterprise Custom plan, you can use your own domain (e.g., clinic.yourdomain.com) instead of medic.kemani.com. We provide SSL certificates, handle DNS configuration, and offer full white-label branding—removing all Kemani branding from your clinic interface. Perfect for established practices and healthcare organizations."
					},
					{
						question: "Can I upgrade or downgrade my plan?",
						answer: "Yes! You can change plans at any time. Upgrades take effect immediately with prorated billing. Downgrades take effect at the end of your current billing cycle. Your patient data and consultation history are preserved when switching plans."
					},
					{
						question: "Is the 30-day free trial really free?",
						answer: "Yes! Pro and Enterprise Custom plans include a genuine 30-day free trial with full access to all features. No credit card required to start the trial. The Free plan is always free with no trial needed—just sign up and start consulting."
					},
					{
						question: "How do digital prescriptions work?",
						answer: "Issue NAFDAC-compliant digital prescriptions directly from the platform. Each prescription includes medication details (generic name, NAFDAC number, quantity, dosage, frequency, duration). Our automated routing system connects prescriptions to verified pharmacies nationwide for direct fulfillment. Prescriptions auto-expire after 90 days for safety."
					},
					{
						question: "What payment methods do patients use?",
						answer: "Patients can pay using Paystack or Flutterwave, which support card payments, bank transfers, USSD, and mobile money (all major Nigerian payment options). Payments are processed instantly, and you receive payouts according to your chosen schedule."
					},
					{
						question: "Can I accept office visit appointments?",
						answer: "Yes! On Pro and Enterprise Custom plans, you can schedule in-person office visits at your clinic. Patients book appointments through your availability calendar, and you receive notifications for upcoming visits. Your clinic address is displayed automatically for office visit appointments."
					},
					{
						question: "What credentials do I need to verify?",
						answer: "You'll need to verify your professional license: MDCN number for doctors, PCN number for pharmacists, or equivalent credentials for diagnosticians and specialists. Verification typically takes 24-48 hours and is required before you can start accepting consultations."
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
				Ready to Start Your Digital Practice?
			</h2>
			<p class="text-base sm:text-lg text-emerald-50/90 mb-6">
				Join Nigerian healthcare providers using Kemani Medic to expand their reach.
			</p>
			<div class="flex flex-col sm:flex-row gap-3 justify-center items-center">
				<a
					href="/auth/signup?plan=medic_free"
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
						<span class="ml-2 text-sm text-emerald-300/70">Medic</span>
					</a>
					<p class="text-sm text-gray-400">
						Telemedicine platform built for Nigerian healthcare providers.
					</p>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Product</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/medic#features" class="hover:text-emerald-400 transition">Features</a></li>
						<li><a href="/medic/pricing" class="hover:text-emerald-400 transition">Pricing</a></li>
						<li><a href="/medic#consultation-types" class="hover:text-emerald-400 transition">Consultation Types</a></li>
					</ul>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Platform</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/" class="hover:text-emerald-400 transition">POS System</a></li>
						<li><a href="/pricing" class="hover:text-emerald-400 transition">POS Pricing</a></li>
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
			</div>

			<div class="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
				<p>&copy; {new Date().getFullYear()} Kemani Medic. All rights reserved. Built for Nigerian healthcare providers.</p>
			</div>
		</div>
	</footer>
</div>
