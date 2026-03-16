<script lang="ts">
	import {
		ShoppingCart, Package, BarChart3, Users, Smartphone, Cloud,
		Lock, Zap, Globe, TrendingUp, MessageCircle, CreditCard,
		Calendar, FileText, Truck, Shield, Database, Wifi
	} from 'lucide-svelte';
</script>

<svelte:head>
	<title>Features - Kemani | Complete Business Management Platform</title>
	<meta name="description" content="Explore Kemani's powerful features: POS, inventory management, e-commerce, healthcare telemedicine, analytics, and more." />
</svelte:head>

<!-- Hero Section -->
<section class="pt-32 pb-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center max-w-3xl mx-auto">
			<h1 class="text-4xl md:text-5xl font-bold theme-heading mb-6">
				Everything You Need to <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">Run Your Business</span>
			</h1>
			<p class="text-xl theme-text-muted mb-8">
				Kemani combines powerful POS, inventory management, e-commerce, and healthcare features into one seamless platform.
			</p>
		</div>
	</div>
</section>

<!-- Feature Categories -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<!-- POS Features -->
		<div class="mb-20">
			<div class="text-center mb-12">
				<h2 class="text-3xl font-bold theme-heading mb-4">Point of Sale</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Lightning-fast checkout with offline support and multi-payment options
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<ShoppingCart class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Fast Checkout</h3>
					<p class="theme-text-muted mb-4">
						Process sales in seconds with barcode scanning, quick search, and keyboard shortcuts.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Barcode scanner support</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Split payment methods</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Customer lookup</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Wifi class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Offline Mode</h3>
					<p class="theme-text-muted mb-4">
						Never miss a sale. Continue working even without internet, auto-sync when back online.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Local data storage</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Automatic sync</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Conflict resolution</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<CreditCard class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Payment Options</h3>
					<p class="theme-text-muted mb-4">
						Accept cash, cards, bank transfers, and mobile money with integrated payment processing.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Multiple payment types</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Split payments</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Refund management</span>
						</li>
					</ul>
				</div>
			</div>
		</div>

		<!-- Inventory Features -->
		<div class="mb-20">
			<div class="text-center mb-12">
				<h2 class="text-3xl font-bold theme-heading mb-4">Inventory Management</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Real-time stock tracking with automated reordering and multi-branch transfers
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Package class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Stock Tracking</h3>
					<p class="theme-text-muted mb-4">
						Track stock levels in real-time across all branches with low-stock alerts.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Multi-branch inventory</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Low stock alerts</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Expiry date tracking</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Truck class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Stock Transfers</h3>
					<p class="theme-text-muted mb-4">
						Move inventory between branches seamlessly with full tracking and approval workflows.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Inter-branch transfers</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Transfer history</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Approval workflows</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<TrendingUp class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Smart Reordering</h3>
					<p class="theme-text-muted mb-4">
						Automated reorder suggestions based on sales velocity and historical data.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Reorder point alerts</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Purchase orders</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Supplier management</span>
						</li>
					</ul>
				</div>
			</div>
		</div>

		<!-- E-commerce Features -->
		<div class="mb-20">
			<div class="text-center mb-12">
				<h2 class="text-3xl font-bold theme-heading mb-4">E-Commerce & Marketplace</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Sell online with your own branded storefront and sync with WooCommerce/Shopify
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Globe class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Online Storefront</h3>
					<p class="theme-text-muted mb-4">
						Create your own branded online store with customizable themes and domain.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Custom domain support</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Mobile-responsive design</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Product catalog sync</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<MessageCircle class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">AI Chat Orders</h3>
					<p class="theme-text-muted mb-4">
						Let customers place orders via AI-powered chat on WhatsApp and your website.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>WhatsApp integration</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Natural language ordering</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Order tracking</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Smartphone class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Platform Sync</h3>
					<p class="theme-text-muted mb-4">
						Sync products and orders with WooCommerce, Shopify, and other platforms.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>WooCommerce sync</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Shopify integration</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Real-time inventory sync</span>
						</li>
					</ul>
				</div>
			</div>
		</div>

		<!-- Healthcare Features -->
		<div class="mb-20">
			<div class="text-center mb-12">
				<h2 class="text-3xl font-bold theme-heading mb-4">Healthcare & Telemedicine</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Connect customers to healthcare providers with video consultations and e-prescriptions
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Calendar class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Video Consultations</h3>
					<p class="theme-text-muted mb-4">
						Enable patients to consult with doctors via video, audio, or chat.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>HD video calls</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Appointment scheduling</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Consultation history</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<FileText class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">E-Prescriptions</h3>
					<p class="theme-text-muted mb-4">
						Digital prescriptions with automatic pharmacy routing and fulfillment.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Digital prescriptions</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Pharmacy routing</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Auto-expiration</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Users class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Provider Network</h3>
					<p class="theme-text-muted mb-4">
						Access to verified doctors, pharmacists, and specialists across Nigeria.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Verified providers</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Ratings & reviews</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Specialty filtering</span>
						</li>
					</ul>
				</div>
			</div>
		</div>

		<!-- Analytics Features -->
		<div class="mb-20">
			<div class="text-center mb-12">
				<h2 class="text-3xl font-bold theme-heading mb-4">Analytics & Reporting</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Make data-driven decisions with powerful insights and customizable reports
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<BarChart3 class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Sales Dashboard</h3>
					<p class="theme-text-muted mb-4">
						Real-time sales analytics with revenue trends, top products, and staff performance.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Revenue tracking</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Product performance</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Staff metrics</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Database class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Custom Reports</h3>
					<p class="theme-text-muted mb-4">
						Generate detailed reports for sales, inventory, staff, and customers.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Customizable filters</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Export to PDF/Excel</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Scheduled reports</span>
						</li>
					</ul>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<TrendingUp class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Predictive Insights</h3>
					<p class="theme-text-muted mb-4">
						AI-powered forecasting for sales, inventory needs, and customer behavior.
					</p>
					<ul class="space-y-2 text-sm theme-text-muted">
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Sales forecasting</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Demand prediction</span>
						</li>
						<li class="flex items-start gap-2">
							<span class="text-emerald-600 dark:text-emerald-400 mt-1">✓</span>
							<span>Trend analysis</span>
						</li>
					</ul>
				</div>
			</div>
		</div>

		<!-- Security Features -->
		<div>
			<div class="text-center mb-12">
				<h2 class="text-3xl font-bold theme-heading mb-4">Security & Compliance</h2>
				<p class="text-lg theme-text-muted max-w-2xl mx-auto">
					Enterprise-grade security with role-based access and audit logging
				</p>
			</div>

			<div class="grid md:grid-cols-3 gap-8">
				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Lock class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Data Encryption</h3>
					<p class="theme-text-muted mb-4">
						End-to-end encryption for all sensitive data with SSL/TLS protection.
					</p>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Shield class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Role-Based Access</h3>
					<p class="theme-text-muted mb-4">
						Granular permissions for tenant admins, branch managers, cashiers, and staff.
					</p>
				</div>

				<div class="theme-card p-8">
					<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center mb-6">
						<Cloud class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
					</div>
					<h3 class="text-xl font-semibold theme-heading mb-3">Cloud Backup</h3>
					<p class="theme-text-muted mb-4">
						Automatic daily backups with 99.9% uptime SLA and disaster recovery.
					</p>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- Integration Section -->
<section class="py-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center mb-12">
			<h2 class="text-3xl font-bold theme-heading mb-4">Integrations</h2>
			<p class="text-lg theme-text-muted max-w-2xl mx-auto">
				Connect Kemani with your favorite tools and platforms
			</p>
		</div>

		<div class="grid grid-cols-2 md:grid-cols-4 gap-8">
			{#each ['WooCommerce', 'Shopify', 'WhatsApp', 'Flutterwave', 'Paystack', 'Stripe', 'QuickBooks', 'Google Analytics'] as integration}
				<div class="theme-card p-6 text-center">
					<div class="font-semibold theme-heading">{integration}</div>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- CTA Section -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
		<h2 class="text-3xl font-bold theme-heading mb-6">
			Ready to See It in Action?
		</h2>
		<p class="text-xl theme-text-muted mb-8">
			Start your 30-day free trial today. No credit card required.
		</p>
		<div class="flex flex-col sm:flex-row gap-4 justify-center">
			<a href="/pricing" class="inline-block px-8 py-4 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors">
				Get Started Free
			</a>
			<a href="/contact" class="inline-block px-8 py-4 theme-card font-semibold hover:border-emerald-600 transition-colors">
				Schedule a Demo
			</a>
		</div>
	</div>
</section>
