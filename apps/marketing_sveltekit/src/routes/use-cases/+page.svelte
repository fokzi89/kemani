<script lang="ts">
	import { ShoppingBag, Pill, Coffee, Store, Heart, Sparkles } from 'lucide-svelte';
</script>

<svelte:head>
	<title>Use Cases - Kemani | Solutions for Every Business Type</title>
	<meta name="description" content="Discover how Kemani helps supermarkets, pharmacies, restaurants, mini-marts, and grocery stores streamline operations and grow revenue." />
</svelte:head>

<!-- Hero Section -->
<section class="pt-32 pb-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center max-w-3xl mx-auto">
			<h1 class="text-4xl md:text-5xl font-bold theme-heading mb-6">
				Built for <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">Your Business</span>
			</h1>
			<p class="text-xl theme-text-muted mb-8">
				See how businesses like yours use Kemani to streamline operations, boost sales, and deliver exceptional customer experiences.
			</p>
		</div>
	</div>
</section>

<!-- Use Cases Grid -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="space-y-32">
			<!-- Supermarket -->
			<div class="grid lg:grid-cols-2 gap-12 items-center">
				<div>
					<div class="flex items-center gap-3 mb-6">
						<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center">
							<ShoppingBag class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
						</div>
						<h2 class="text-3xl font-bold theme-heading">Supermarkets</h2>
					</div>
					<p class="text-lg theme-text-muted mb-6">
						Manage high-volume sales with lightning-fast checkout, real-time inventory tracking across multiple aisles, and powerful analytics to optimize your product mix.
					</p>
					<div class="space-y-4">
						<div class="flex items-start gap-3">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Barcode Scanning</div>
								<p class="text-sm theme-text-muted">Rapid checkout with support for multiple barcode formats</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Multi-Location Inventory</div>
								<p class="text-sm theme-text-muted">Track stock levels across multiple stores and warehouses</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Loyalty Programs</div>
								<p class="text-sm theme-text-muted">Reward repeat customers and boost retention</p>
							</div>
						</div>
					</div>
				</div>
				<div class="theme-card p-8">
					<div class="aspect-video bg-gradient-to-br from-emerald-500 to-teal-500 rounded-lg flex items-center justify-center text-white text-4xl font-bold">
						Supermarket Demo
					</div>
				</div>
			</div>

			<!-- Pharmacy -->
			<div class="grid lg:grid-cols-2 gap-12 items-center">
				<div class="order-2 lg:order-1 theme-card p-8">
					<div class="aspect-video bg-gradient-to-br from-blue-500 to-purple-500 rounded-lg flex items-center justify-center text-white text-4xl font-bold">
						Pharmacy Demo
					</div>
				</div>
				<div class="order-1 lg:order-2">
					<div class="flex items-center gap-3 mb-6">
						<div class="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
							<Pill class="w-6 h-6 text-blue-600 dark:text-blue-400" />
						</div>
						<h2 class="text-3xl font-bold theme-heading">Pharmacies</h2>
					</div>
					<p class="text-lg theme-text-muted mb-6">
						Specialized features for pharmaceutical retail including prescription management, expiry tracking, and seamless integration with healthcare telemedicine services.
					</p>
					<div class="space-y-4">
						<div class="flex items-start gap-3">
							<span class="text-blue-600 dark:text-blue-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Prescription Tracking</div>
								<p class="text-sm theme-text-muted">Digital prescriptions with automatic validation and fulfillment</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-blue-600 dark:text-blue-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Expiry Management</div>
								<p class="text-sm theme-text-muted">Automated alerts for products approaching expiration</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-blue-600 dark:text-blue-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Telemedicine Integration</div>
								<p class="text-sm theme-text-muted">Connect customers to doctors for instant consultations</p>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Restaurant/Cafe -->
			<div class="grid lg:grid-cols-2 gap-12 items-center">
				<div>
					<div class="flex items-center gap-3 mb-6">
						<div class="w-12 h-12 bg-orange-100 dark:bg-orange-900/30 rounded-lg flex items-center justify-center">
							<Coffee class="w-6 h-6 text-orange-600 dark:text-orange-400" />
						</div>
						<h2 class="text-3xl font-bold theme-heading">Restaurants & Cafés</h2>
					</div>
					<p class="text-lg theme-text-muted mb-6">
						Streamline orders, manage kitchen operations, and accept dine-in, takeout, and delivery orders all from one platform.
					</p>
					<div class="space-y-4">
						<div class="flex items-start gap-3">
							<span class="text-orange-600 dark:text-orange-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Table Management</div>
								<p class="text-sm theme-text-muted">Track orders by table with split billing options</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-orange-600 dark:text-orange-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Kitchen Display System</div>
								<p class="text-sm theme-text-muted">Real-time order routing to kitchen staff</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-orange-600 dark:text-orange-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Online Ordering</div>
								<p class="text-sm theme-text-muted">Accept orders via WhatsApp and custom website</p>
							</div>
						</div>
					</div>
				</div>
				<div class="theme-card p-8">
					<div class="aspect-video bg-gradient-to-br from-orange-500 to-red-500 rounded-lg flex items-center justify-center text-white text-4xl font-bold">
						Restaurant Demo
					</div>
				</div>
			</div>

			<!-- Mini Mart/Convenience Store -->
			<div class="grid lg:grid-cols-2 gap-12 items-center">
				<div class="order-2 lg:order-1 theme-card p-8">
					<div class="aspect-video bg-gradient-to-br from-pink-500 to-purple-500 rounded-lg flex items-center justify-center text-white text-4xl font-bold">
						Mini Mart Demo
					</div>
				</div>
				<div class="order-1 lg:order-2">
					<div class="flex items-center gap-3 mb-6">
						<div class="w-12 h-12 bg-pink-100 dark:bg-pink-900/30 rounded-lg flex items-center justify-center">
							<Store class="w-6 h-6 text-pink-600 dark:text-pink-400" />
						</div>
						<h2 class="text-3xl font-bold theme-heading">Mini Marts & Convenience Stores</h2>
					</div>
					<p class="text-lg theme-text-muted mb-6">
						Perfect for small-format retail with easy-to-use POS, quick inventory updates, and mobile-friendly design for staff on the go.
					</p>
					<div class="space-y-4">
						<div class="flex items-start gap-3">
							<span class="text-pink-600 dark:text-pink-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Simple Interface</div>
								<p class="text-sm theme-text-muted">Intuitive design that requires minimal training</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-pink-600 dark:text-pink-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Mobile POS</div>
								<p class="text-sm theme-text-muted">Accept payments anywhere in your store with tablets/phones</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-pink-600 dark:text-pink-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Quick Restock</div>
								<p class="text-sm theme-text-muted">Fast inventory adjustments with barcode scanning</p>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Grocery Store -->
			<div class="grid lg:grid-cols-2 gap-12 items-center">
				<div>
					<div class="flex items-center gap-3 mb-6">
						<div class="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
							<Sparkles class="w-6 h-6 text-green-600 dark:text-green-400" />
						</div>
						<h2 class="text-3xl font-bold theme-heading">Grocery Stores</h2>
					</div>
					<p class="text-lg theme-text-muted mb-6">
						Manage fresh produce, perishables, and packaged goods with smart expiry tracking, supplier management, and automatic reordering.
					</p>
					<div class="space-y-4">
						<div class="flex items-start gap-3">
							<span class="text-green-600 dark:text-green-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Perishable Tracking</div>
								<p class="text-sm theme-text-muted">Monitor expiry dates and minimize waste</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-green-600 dark:text-green-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Supplier Management</div>
								<p class="text-sm theme-text-muted">Track vendors, purchase orders, and pricing history</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-green-600 dark:text-green-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Weight-Based Pricing</div>
								<p class="text-sm theme-text-muted">Support for items sold by weight or unit</p>
							</div>
						</div>
					</div>
				</div>
				<div class="theme-card p-8">
					<div class="aspect-video bg-gradient-to-br from-green-500 to-emerald-500 rounded-lg flex items-center justify-center text-white text-4xl font-bold">
						Grocery Demo
					</div>
				</div>
			</div>

			<!-- Healthcare -->
			<div class="grid lg:grid-cols-2 gap-12 items-center">
				<div class="order-2 lg:order-1 theme-card p-8">
					<div class="aspect-video bg-gradient-to-br from-red-500 to-pink-500 rounded-lg flex items-center justify-center text-white text-4xl font-bold">
						Healthcare Demo
					</div>
				</div>
				<div class="order-1 lg:order-2">
					<div class="flex items-center gap-3 mb-6">
						<div class="w-12 h-12 bg-red-100 dark:bg-red-900/30 rounded-lg flex items-center justify-center">
							<Heart class="w-6 h-6 text-red-600 dark:text-red-400" />
						</div>
						<h2 class="text-3xl font-bold theme-heading">Healthcare Providers</h2>
					</div>
					<p class="text-lg theme-text-muted mb-6">
						Build your telemedicine practice with video consultations, digital prescriptions, appointment scheduling, and patient management tools.
					</p>
					<div class="space-y-4">
						<div class="flex items-start gap-3">
							<span class="text-red-600 dark:text-red-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Video Consultations</div>
								<p class="text-sm theme-text-muted">HD video calls with secure patient communication</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-red-600 dark:text-red-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Digital Prescriptions</div>
								<p class="text-sm theme-text-muted">E-prescriptions with pharmacy routing</p>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<span class="text-red-600 dark:text-red-400 mt-1">✓</span>
							<div>
								<div class="font-semibold theme-heading">Patient Records</div>
								<p class="text-sm theme-text-muted">Secure health records and consultation history</p>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- Customer Stories CTA -->
<section class="py-20 theme-bg">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
		<h2 class="text-3xl font-bold theme-heading mb-6">
			Ready to Transform Your Business?
		</h2>
		<p class="text-xl theme-text-muted mb-8">
			Join 1,000+ businesses using Kemani to streamline operations and boost revenue.
		</p>
		<div class="flex flex-col sm:flex-row gap-4 justify-center">
			<a href="/pricing" class="inline-block px-8 py-4 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors">
				Start Free Trial
			</a>
			<a href="/contact" class="inline-block px-8 py-4 theme-card font-semibold hover:border-emerald-600 transition-colors">
				Schedule a Demo
			</a>
		</div>
	</div>
</section>
