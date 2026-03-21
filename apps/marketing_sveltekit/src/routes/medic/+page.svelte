<script lang="ts">
	import { Check, Video, MessageCircle, Phone, Calendar, FileText, Clock, Users, Shield, Zap, TrendingUp, Globe, ArrowRight } from 'lucide-svelte';
	import ThemeToggle from '$lib/components/ThemeToggle.svelte';

	const features = [
		{
			icon: MessageCircle,
			title: "Chat Consultations",
			description: "Provide instant medical advice via secure, HIPAA-compliant chat messaging with your patients."
		},
		{
			icon: Video,
			title: "Video & Audio Calls",
			description: "Conduct face-to-face consultations using integrated Agora video/audio technology."
		},
		{
			icon: Calendar,
			title: "Smart Scheduling",
			description: "Automated appointment booking with customizable availability templates and slot management."
		},
		{
			icon: FileText,
			title: "Digital Prescriptions",
			description: "Issue NAFDAC-compliant digital prescriptions with automatic pharmacy routing and 90-day expiration tracking."
		},
		{
			icon: Users,
			title: "Patient Management",
			description: "Maintain comprehensive patient records, consultation history, and medical notes in one secure platform."
		},
		{
			icon: Shield,
			title: "Secure & Compliant",
			description: "Bank-grade encryption with Row-Level Security (RLS) policies ensuring complete data privacy and HIPAA compliance."
		}
	];

	const stats = [
		{ value: "₦5,000+", label: "Average consultation fee" },
		{ value: "24/7", label: "Platform availability" },
		{ value: "4 types", label: "Consultation formats" },
		{ value: "Instant", label: "Payment processing" }
	];

	const consultationTypes = [
		{
			type: "Chat",
			icon: MessageCircle,
			description: "Asynchronous text-based consultations",
			ideal: "Quick medical advice, prescription refills, follow-ups"
		},
		{
			type: "Video",
			icon: Video,
			description: "Face-to-face virtual consultations",
			ideal: "Diagnoses, physical examinations, mental health sessions"
		},
		{
			type: "Audio",
			icon: Phone,
			description: "Voice-only consultations",
			ideal: "Low-bandwidth areas, phone-based advice"
		},
		{
			type: "Office Visit",
			icon: Calendar,
			description: "In-person clinic appointments",
			ideal: "Procedures, diagnostics, hands-on treatment"
		}
	];

	const integrations = [
		{
			name: "Agora",
			description: "Enterprise-grade video/audio infrastructure with 99.9% uptime",
			features: ["HD video quality", "Low latency", "Cross-platform support"]
		},
		{
			name: "Paystack & Flutterwave",
			description: "Seamless payment processing for Nigerian healthcare providers",
			features: ["Instant payouts", "Card & bank transfer", "Mobile money"]
		},
		{
			name: "Pharmacy Network",
			description: "Automated prescription routing to verified pharmacies nationwide",
			features: ["Smart routing", "Real-time inventory", "Direct fulfillment"]
		}
	];
</script>

<svelte:head>
	<title>Kemani Medic - Telemedicine Platform for Healthcare Providers</title>
	<meta name="description" content="Launch your digital clinic in minutes. Offer chat, video, and audio consultations with automated scheduling, digital prescriptions, and secure patient management." />
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
				<div class="hidden md:flex items-center gap-6">
					<a href="/" class="theme-nav-link transition text-sm">
						POS Platform
					</a>
					<a href="/medic" class="theme-logo font-medium text-sm">
						For Medics
					</a>
					<a href="/medic/pricing" class="theme-nav-link transition text-sm">
						Pricing
					</a>
					<a href="/about" class="theme-nav-link transition text-sm">
						About
					</a>
					<a href="/blog" class="theme-nav-link transition text-sm">
						Blog
					</a>
					<a href="/help" class="theme-nav-link transition text-sm">
						Help
					</a>
					<ThemeToggle />
					<a
						href="http://localhost:5179/auth/login"
						class="px-4 py-2 theme-btn-outline border rounded-lg transition text-sm"
					>
						Sign In
					</a>
					<a
						href="http://localhost:5179/auth/signup"
						class="px-4 py-2 bg-gradient-to-r from-emerald-600 to-green-600 text-white rounded-lg hover:from-emerald-500 hover:to-green-500 transition text-sm font-medium"
					>
						Start Free
					</a>
				</div>
			</div>
		</div>
	</nav>

	<!-- Hero Section -->
	<section class="pt-32 pb-20 px-4 sm:px-6 lg:px-8">
		<div class="max-w-7xl mx-auto">
			<div class="grid lg:grid-cols-2 gap-12 items-center">
				<div>
					<div class="inline-flex items-center px-3 py-1 bg-emerald-500/20 backdrop-blur-sm theme-logo rounded-full text-sm font-medium border border-emerald-500/30 mb-6">
						<Zap class="h-4 w-4 mr-2" />
						Launch your digital clinic in minutes
					</div>
					<h1 class="text-5xl sm:text-6xl md:text-7xl font-bold theme-heading mb-6 leading-tight">
						Healthcare,
						<span class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-green-400">
							Reimagined
						</span>
					</h1>
					<p class="text-xl theme-text-muted mb-8 leading-relaxed">
						Provide telemedicine consultations, manage patients, issue digital prescriptions, and grow your practice with Nigeria's most advanced healthcare platform.
					</p>
					<div class="flex flex-col sm:flex-row gap-4">
						<a
							href="/medic/pricing"
							class="inline-flex items-center justify-center px-8 py-4 bg-gradient-to-r from-emerald-600 to-green-600 text-white font-semibold rounded-lg hover:from-emerald-500 hover:to-green-500 transition shadow-lg shadow-emerald-500/20"
						>
							View Pricing Plans
							<ArrowRight class="ml-2 h-5 w-5" />
						</a>
						<a
							href="#features"
							class="inline-flex items-center justify-center px-8 py-4 bg-emerald-500/20 text-emerald-300 font-semibold rounded-lg hover:bg-emerald-500/30 border border-emerald-500/30 backdrop-blur-sm transition"
						>
							Explore Features
						</a>
					</div>
					<div class="mt-8 flex items-center gap-6 text-sm theme-text-muted">
						<div class="flex items-center">
							<Check class="h-4 w-4 theme-logo mr-2" />
							No credit card required
						</div>
						<div class="flex items-center">
							<Check class="h-4 w-4 theme-logo mr-2" />
							Free plan available
						</div>
					</div>
				</div>

				<!-- Stats Grid -->
				<div class="grid grid-cols-2 gap-6">
					{#each stats as stat}
						<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-6 hover:shadow-xl hover:shadow-emerald-500/10 transition">
							<div class="text-3xl font-bold theme-logo mb-2">{stat.value}</div>
							<div class="text-sm theme-text-muted">{stat.label}</div>
						</div>
					{/each}
				</div>
			</div>
		</div>
	</section>

	<!-- Consultation Types -->
	<section id="consultation-types" class="py-16 theme-gradient-section backdrop-blur-sm transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-12">
				<h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-4">
					4 Ways to Consult Your Patients
				</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Flexible consultation formats to meet your patients where they are
				</p>
			</div>

			<div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
				{#each consultationTypes as consult}
					<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-6 hover:shadow-xl hover:shadow-emerald-500/10 transition">
						<div class="w-12 h-12 bg-emerald-500/20 rounded-lg flex items-center justify-center mb-4">
							<svelte:component this={consult.icon} class="h-6 w-6 theme-logo" />
						</div>
						<h3 class="text-xl font-bold theme-heading mb-2">{consult.type}</h3>
						<p class="text-sm theme-text-muted mb-4">{consult.description}</p>
						<div class="text-xs theme-logo font-medium">
							Ideal for: {consult.ideal}
						</div>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- Core Features -->
	<section id="features" class="py-20 px-4 sm:px-6 lg:px-8">
		<div class="max-w-7xl mx-auto">
			<div class="text-center mb-16">
				<h2 class="text-4xl sm:text-5xl font-bold theme-heading mb-4">
					Everything You Need to Practice Medicine Online
				</h2>
				<p class="text-lg theme-text-muted max-w-3xl mx-auto">
					From consultations to prescriptions to payments—all in one integrated platform
				</p>
			</div>

			<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
				{#each features as feature}
					<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-8 hover:shadow-xl hover:shadow-emerald-500/10 transition">
						<div class="w-14 h-14 bg-emerald-500/20 rounded-lg flex items-center justify-center mb-4">
							<svelte:component this={feature.icon} class="h-7 w-7 theme-logo" />
						</div>
						<h3 class="text-xl font-bold theme-heading mb-3">{feature.title}</h3>
						<p class="theme-text-muted leading-relaxed">{feature.description}</p>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- Third-Party Integrations -->
	<section class="py-16 theme-gradient-section backdrop-blur-sm transition-theme">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center mb-12">
				<h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-4">
					Enterprise-Grade Integrations
				</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Built on best-in-class infrastructure trusted by healthcare providers worldwide
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				{#each integrations as integration}
					<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-8 hover:shadow-xl hover:shadow-emerald-500/10 transition">
						<div class="flex items-center mb-4">
							<div class="w-10 h-10 bg-emerald-500/20 rounded-lg flex items-center justify-center mr-3">
								<Globe class="h-5 w-5 theme-logo" />
							</div>
							<h3 class="text-xl font-bold theme-heading">{integration.name}</h3>
						</div>
						<p class="text-sm theme-text-muted mb-4">{integration.description}</p>
						<ul class="space-y-2">
							{#each integration.features as feature}
								<li class="flex items-start">
									<Check class="h-4 w-4 theme-logo mr-2 flex-shrink-0 mt-0.5" />
									<span class="theme-text-muted text-sm">{feature}</span>
								</li>
							{/each}
						</ul>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- How It Works -->
	<section class="py-20 px-4 sm:px-6 lg:px-8">
		<div class="max-w-7xl mx-auto">
			<div class="text-center mb-16">
				<h2 class="text-4xl sm:text-5xl font-bold theme-heading mb-4">
					How It Works
				</h2>
				<p class="text-lg theme-text-muted">
					From signup to your first consultation in 3 simple steps
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				<div class="relative">
					<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-8">
						<div class="w-12 h-12 bg-emerald-500/20 rounded-full flex items-center justify-center mb-4 text-2xl font-bold theme-logo">
							1
						</div>
						<h3 class="text-xl font-bold theme-heading mb-3">Create Your Profile</h3>
						<p class="theme-text-muted">
							Sign up, verify your credentials (MDCN/PCN), and set up your digital clinic with custom branding and consultation fees.
						</p>
					</div>
					<div class="hidden md:block absolute top-12 -right-4 w-8 h-0.5 bg-gradient-to-r from-emerald-500 to-transparent"></div>
				</div>

				<div class="relative">
					<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-8">
						<div class="w-12 h-12 bg-emerald-500/20 rounded-full flex items-center justify-center mb-4 text-2xl font-bold theme-logo">
							2
						</div>
						<h3 class="text-xl font-bold theme-heading mb-3">Set Your Availability</h3>
						<p class="theme-text-muted">
							Configure your consultation hours with flexible scheduling templates. Patients book slots automatically based on your availability.
						</p>
					</div>
					<div class="hidden md:block absolute top-12 -right-4 w-8 h-0.5 bg-gradient-to-r from-emerald-500 to-transparent"></div>
				</div>

				<div class="bg-white/5 backdrop-blur-md rounded-xl shadow-lg border border-emerald-800/30 p-8">
					<div class="w-12 h-12 bg-emerald-500/20 rounded-full flex items-center justify-center mb-4 text-2xl font-bold theme-logo">
						3
					</div>
					<h3 class="text-xl font-bold theme-heading mb-3">Start Consulting</h3>
					<p class="theme-text-muted">
						Patients find you through our marketplace or your custom clinic URL. Conduct consultations, issue prescriptions, and receive instant payments.
					</p>
				</div>
			</div>
		</div>
	</section>

	<!-- CTA Section -->
	<section class="py-20 theme-gradient-cta backdrop-blur-sm text-white transition-theme">
		<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
			<h2 class="text-4xl sm:text-5xl font-bold mb-6">
				Ready to Launch Your Digital Practice?
			</h2>
			<p class="text-xl text-emerald-50/90 mb-8 leading-relaxed">
				Join hundreds of Nigerian healthcare providers using Kemani Medic to expand their reach and grow their practice.
			</p>
			<div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
				<a
					href="/medic/pricing"
					class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-4 bg-white text-emerald-600 font-semibold rounded-lg hover:bg-emerald-50 transition shadow-lg"
				>
					View Pricing Plans
					<ArrowRight class="ml-2 h-5 w-5" />
				</a>
				<a
					href="/contact"
					class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-4 bg-transparent text-white font-semibold rounded-lg border-2 border-white hover:bg-white/10 backdrop-blur-sm transition"
				>
					Schedule a Demo
				</a>
			</div>
			<p class="mt-6 text-sm text-emerald-100/70">
				Free plan available. No credit card required. Start today.
			</p>
		</div>
	</section>

	<!-- Footer -->
	<footer class="bg-gray-900 text-gray-300 py-12 border-t border-emerald-800/30">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="grid md:grid-cols-5 gap-8">
				<div class="md:col-span-2">
					<a href="/" class="flex items-center mb-4">
						<span class="text-2xl font-bold text-emerald-400">Kemani</span>
						<span class="ml-2 text-sm text-emerald-300/70">Medic</span>
					</a>
					<p class="text-sm text-gray-400 mb-4">
						Nigeria's leading telemedicine platform for healthcare providers.
					</p>
					<p class="text-sm text-gray-400">
						4 Adeyemo Alakija Street<br />
						Victoria Island, Lagos, Nigeria
					</p>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Company</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/about" class="hover:text-emerald-400 transition">About Us</a></li>
						<li><a href="/blog" class="hover:text-emerald-400 transition">Blog</a></li>
						<li><a href="/contact" class="hover:text-emerald-400 transition">Contact</a></li>
					</ul>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Product</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/" class="hover:text-emerald-400 transition">POS System</a></li>
						<li><a href="/medic" class="hover:text-emerald-400 transition">For Healthcare</a></li>
						<li><a href="/use-cases" class="hover:text-emerald-400 transition">Use Cases</a></li>
						<li><a href="/pricing" class="hover:text-emerald-400 transition">Pricing</a></li>
					</ul>
				</div>

				<div>
					<h3 class="text-white font-semibold mb-4">Resources</h3>
					<ul class="space-y-2 text-sm">
						<li><a href="/help" class="hover:text-emerald-400 transition">Help Center</a></li>
						<li><a href="/terms" class="hover:text-emerald-400 transition">Terms of Service</a></li>
						<li><a href="/privacy" class="hover:text-emerald-400 transition">Privacy Policy</a></li>
						<li><a href="/cookies" class="hover:text-emerald-400 transition">Cookie Policy</a></li>
					</ul>
				</div>
			</div>

			<div class="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
				<p>&copy; {new Date().getFullYear()} Kemani Medic. All rights reserved. Built for Nigerian healthcare providers.</p>
			</div>
		</div>
	</footer>
</div>
