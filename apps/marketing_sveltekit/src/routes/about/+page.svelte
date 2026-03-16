<script lang="ts">
	import { Users, Target, Heart, Zap, Globe, Shield } from 'lucide-svelte';
</script>

<svelte:head>
	<title>About Us - Kemani | Empowering African Businesses</title>
	<meta name="description" content="Learn about Kemani's mission to empower African businesses with modern POS systems and healthcare telemedicine solutions." />
</svelte:head>

<!-- Hero Section -->
<section class="pt-32 pb-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center max-w-3xl mx-auto">
			<h1 class="text-4xl md:text-5xl font-bold theme-heading mb-6">
				Empowering <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">African Businesses</span>
			</h1>
			<p class="text-xl theme-text-muted mb-8">
				We're building the future of commerce and healthcare in Africa, one business at a time.
			</p>
		</div>
	</div>
</section>

<!-- Mission Section -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="grid md:grid-cols-2 gap-12 items-center">
			<div>
				<h2 class="text-3xl font-bold theme-heading mb-6">Our Mission</h2>
				<p class="text-lg theme-text-muted mb-6">
					Kemani exists to democratize access to world-class business technology for African entrepreneurs.
					We believe that every shop owner, pharmacist, and healthcare provider deserves the same tools
					that power successful businesses worldwide.
				</p>
				<p class="text-lg theme-text-muted mb-6">
					Founded in 2024, we've grown from a simple POS system to a comprehensive platform serving
					retail, healthcare, and e-commerce businesses across Nigeria and beyond.
				</p>
			</div>
			<div class="grid grid-cols-2 gap-6">
				<div class="theme-card p-6 text-center">
					<div class="text-4xl font-bold theme-accent mb-2">1000+</div>
					<div class="theme-text-muted">Active Businesses</div>
				</div>
				<div class="theme-card p-6 text-center">
					<div class="text-4xl font-bold theme-accent mb-2">50K+</div>
					<div class="theme-text-muted">Daily Transactions</div>
				</div>
				<div class="theme-card p-6 text-center">
					<div class="text-4xl font-bold theme-accent mb-2">200+</div>
					<div class="theme-text-muted">Healthcare Providers</div>
				</div>
				<div class="theme-card p-6 text-center">
					<div class="text-4xl font-bold theme-accent mb-2">24/7</div>
					<div class="theme-text-muted">Support Available</div>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- Values Section -->
<section class="py-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center mb-16">
			<h2 class="text-3xl font-bold theme-heading mb-4">Our Values</h2>
			<p class="text-lg theme-text-muted max-w-2xl mx-auto">
				These principles guide everything we do at Kemani
			</p>
		</div>

		<div class="grid md:grid-cols-3 gap-8">
			<div class="theme-card p-8">
				<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
					<Target class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-4">Customer First</h3>
				<p class="theme-text-muted">
					We obsess over customer success. Every feature we build, every decision we make,
					starts with asking: "How does this help our customers?"
				</p>
			</div>

			<div class="theme-card p-8">
				<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
					<Zap class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-4">Innovation</h3>
				<p class="theme-text-muted">
					We constantly push boundaries, experimenting with new technologies to deliver
					cutting-edge solutions that give our customers a competitive edge.
				</p>
			</div>

			<div class="theme-card p-8">
				<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
					<Heart class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-4">Empathy</h3>
				<p class="theme-text-muted">
					We deeply understand the challenges African businesses face. Our solutions are
					designed with local context, needs, and constraints in mind.
				</p>
			</div>

			<div class="theme-card p-8">
				<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
					<Shield class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-4">Reliability</h3>
				<p class="theme-text-muted">
					Business owners depend on us every single day. We take that responsibility seriously,
					ensuring 99.9% uptime and rock-solid performance.
				</p>
			</div>

			<div class="theme-card p-8">
				<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
					<Globe class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-4">Accessibility</h3>
				<p class="theme-text-muted">
					Powerful tools shouldn't be expensive. We offer flexible pricing and free tiers
					so every business can access professional-grade software.
				</p>
			</div>

			<div class="theme-card p-8">
				<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
					<Users class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-4">Community</h3>
				<p class="theme-text-muted">
					We're building more than software—we're building a community of entrepreneurs
					who support, learn from, and inspire each other.
				</p>
			</div>
		</div>
	</div>
</section>

<!-- Story Section -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center mb-16">
			<h2 class="text-3xl font-bold theme-heading mb-4">Our Story</h2>
		</div>

		<div class="space-y-12">
			<div class="flex gap-6">
				<div class="flex-shrink-0">
					<div class="w-16 h-16 bg-emerald-600 dark:bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold">
						2024
					</div>
				</div>
				<div>
					<h3 class="text-xl font-semibold theme-heading mb-2">The Beginning</h3>
					<p class="theme-text-muted">
						Kemani was born from a simple observation: while visiting a local pharmacy in Lagos,
						we watched the owner struggle with manual record-keeping and inventory management.
						We knew technology could help, but existing solutions were either too expensive or
						too complex for small businesses.
					</p>
				</div>
			</div>

			<div class="flex gap-6">
				<div class="flex-shrink-0">
					<div class="w-16 h-16 bg-emerald-600 dark:bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold">
						Q2
					</div>
				</div>
				<div>
					<h3 class="text-xl font-semibold theme-heading mb-2">First Customers</h3>
					<p class="theme-text-muted">
						We launched our MVP with 5 pilot stores. The feedback was overwhelming—shop owners
						loved the simplicity, and their sales increased by 30% on average thanks to better
						inventory tracking and data insights.
					</p>
				</div>
			</div>

			<div class="flex gap-6">
				<div class="flex-shrink-0">
					<div class="w-16 h-16 bg-emerald-600 dark:bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold">
						Q3
					</div>
				</div>
				<div>
					<h3 class="text-xl font-semibold theme-heading mb-2">Healthcare Expansion</h3>
					<p class="theme-text-muted">
						Pharmacists using our system asked: "Can we connect customers to doctors?"
						We listened and built our telemedicine platform, enabling seamless referrals from
						retail stores to healthcare providers.
					</p>
				</div>
			</div>

			<div class="flex gap-6">
				<div class="flex-shrink-0">
					<div class="w-16 h-16 bg-emerald-600 dark:bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold">
						Q4
					</div>
				</div>
				<div>
					<h3 class="text-xl font-semibold theme-heading mb-2">E-commerce Integration</h3>
					<p class="theme-text-muted">
						Our customers wanted to sell online. We built marketplace and e-commerce sync features,
						allowing physical stores to reach customers anywhere in Nigeria through their own
						branded storefronts.
					</p>
				</div>
			</div>

			<div class="flex gap-6">
				<div class="flex-shrink-0">
					<div class="w-16 h-16 bg-emerald-600 dark:bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold">
						2025
					</div>
				</div>
				<div>
					<h3 class="text-xl font-semibold theme-heading mb-2">The Future</h3>
					<p class="theme-text-muted">
						Today, Kemani powers over 1,000 businesses across Nigeria. But we're just getting started.
						Our vision is to become the operating system for African SMBs—combining POS, healthcare,
						payments, logistics, and financing into one seamless platform.
					</p>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- Team Section -->
<section class="py-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center mb-16">
			<h2 class="text-3xl font-bold theme-heading mb-4">Meet the Team</h2>
			<p class="text-lg theme-text-muted max-w-2xl mx-auto">
				We're a diverse team of engineers, designers, and business experts passionate about empowering African entrepreneurs
			</p>
		</div>

		<div class="grid md:grid-cols-3 gap-8">
			<div class="theme-card p-6 text-center">
				<div class="w-24 h-24 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-full mx-auto mb-4 flex items-center justify-center text-white text-2xl font-bold">
					AO
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-2">Adebayo Ogunlesi</h3>
				<p class="theme-accent font-medium mb-3">Co-Founder & CEO</p>
				<p class="theme-text-muted text-sm">
					Former product manager at Jumia. 10+ years building tech solutions for African markets.
				</p>
			</div>

			<div class="theme-card p-6 text-center">
				<div class="w-24 h-24 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-full mx-auto mb-4 flex items-center justify-center text-white text-2xl font-bold">
					CN
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-2">Chiamaka Nwankwo</h3>
				<p class="theme-accent font-medium mb-3">Co-Founder & CTO</p>
				<p class="theme-text-muted text-sm">
					Ex-Google engineer. Expert in distributed systems and mobile-first architecture.
				</p>
			</div>

			<div class="theme-card p-6 text-center">
				<div class="w-24 h-24 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-full mx-auto mb-4 flex items-center justify-center text-white text-2xl font-bold">
					FI
				</div>
				<h3 class="text-xl font-semibold theme-heading mb-2">Dr. Folake Ibrahim</h3>
				<p class="theme-accent font-medium mb-3">Head of Healthcare</p>
				<p class="theme-text-muted text-sm">
					Licensed physician with 8 years in telemedicine. Leading our healthcare expansion.
				</p>
			</div>
		</div>

		<div class="text-center mt-12">
			<p class="text-lg theme-text-muted mb-6">
				We're growing! Join our team of passionate builders.
			</p>
			<a href="/contact" class="inline-block px-8 py-3 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors">
				View Open Positions
			</a>
		</div>
	</div>
</section>

<!-- CTA Section -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
		<h2 class="text-3xl font-bold theme-heading mb-6">
			Ready to Join Our Mission?
		</h2>
		<p class="text-xl theme-text-muted mb-8">
			Start your 30-day free trial today. No credit card required.
		</p>
		<div class="flex flex-col sm:flex-row gap-4 justify-center">
			<a href="/pricing" class="inline-block px-8 py-4 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors">
				Get Started Free
			</a>
			<a href="/contact" class="inline-block px-8 py-4 theme-card font-semibold hover:border-emerald-600 transition-colors">
				Contact Sales
			</a>
		</div>
	</div>
</section>
