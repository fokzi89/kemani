<script lang="ts">
	import { Calendar, Clock, ArrowRight } from 'lucide-svelte';

	// Sample blog posts - in production, fetch from Supabase
	const blogPosts = [
		{
			slug: 'how-to-increase-retail-sales',
			title: 'How to Increase Retail Sales with POS Analytics',
			excerpt: 'Learn how data-driven insights from your POS system can help you boost sales by 30% or more.',
			author: 'Adebayo Ogunlesi',
			date: '2026-03-01',
			readTime: '5 min read',
			category: 'POS Tips',
			image: '/blog/pos-analytics.jpg'
		},
		{
			slug: 'telemedicine-africa-future',
			title: 'The Future of Healthcare in Africa: Telemedicine Revolution',
			excerpt: 'Exploring how telemedicine is transforming healthcare access across African countries.',
			author: 'Dr. Folake Ibrahim',
			date: '2026-02-25',
			readTime: '7 min read',
			category: 'Healthcare',
			image: '/blog/telemedicine.jpg'
		},
		{
			slug: 'inventory-management-best-practices',
			title: 'Inventory Management Best Practices for Small Businesses',
			excerpt: 'Master inventory control with these proven strategies that save time and reduce costs.',
			author: 'Chiamaka Nwankwo',
			date: '2026-02-20',
			readTime: '6 min read',
			category: 'Inventory',
			image: '/blog/inventory.jpg'
		},
		{
			slug: 'whatsapp-commerce-guide',
			title: 'Complete Guide to Selling on WhatsApp',
			excerpt: 'Turn WhatsApp into a powerful sales channel for your business with AI-powered ordering.',
			author: 'Adebayo Ogunlesi',
			date: '2026-02-15',
			readTime: '8 min read',
			category: 'E-Commerce',
			image: '/blog/whatsapp.jpg'
		},
		{
			slug: 'multi-branch-management',
			title: 'Managing Multiple Store Locations: A Complete Guide',
			excerpt: 'Scale your retail business across multiple branches with centralized management.',
			author: 'Chiamaka Nwankwo',
			date: '2026-02-10',
			readTime: '10 min read',
			category: 'Business Growth',
			image: '/blog/multi-branch.jpg'
		},
		{
			slug: 'customer-loyalty-programs',
			title: 'Building Customer Loyalty Programs That Actually Work',
			excerpt: 'Increase repeat purchases and customer lifetime value with effective loyalty strategies.',
			author: 'Adebayo Ogunlesi',
			date: '2026-02-05',
			readTime: '5 min read',
			category: 'Customer Success',
			image: '/blog/loyalty.jpg'
		}
	];

	const categories = ['All', 'POS Tips', 'Healthcare', 'Inventory', 'E-Commerce', 'Business Growth', 'Customer Success'];
	let selectedCategory = 'All';

	$: filteredPosts = selectedCategory === 'All'
		? blogPosts
		: blogPosts.filter(post => post.category === selectedCategory);
</script>

<svelte:head>
	<title>Blog - Kemani | Business Tips & Insights</title>
	<meta name="description" content="Get the latest tips, insights, and best practices for running a successful retail or healthcare business in Africa." />
</svelte:head>

<!-- Hero Section -->
<section class="pt-32 pb-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center max-w-3xl mx-auto">
			<h1 class="text-4xl md:text-5xl font-bold theme-heading mb-6">
				Kemani <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">Blog</span>
			</h1>
			<p class="text-xl theme-text-muted mb-8">
				Tips, insights, and stories to help you grow your business
			</p>
		</div>
	</div>
</section>

<!-- Category Filter -->
<section class="py-8 theme-bg-secondary sticky top-0 z-10 border-b theme-border">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="flex flex-wrap gap-3 justify-center">
			{#each categories as category}
				<button
					on:click={() => selectedCategory = category}
					class="px-6 py-2 rounded-full font-medium transition-all {
						selectedCategory === category
							? 'bg-emerald-600 dark:bg-emerald-500 text-white'
							: 'theme-card hover:border-emerald-600'
					}"
				>
					{category}
				</button>
			{/each}
		</div>
	</div>
</section>

<!-- Blog Posts Grid -->
<section class="py-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
			{#each filteredPosts as post}
				<article class="theme-card overflow-hidden group">
					<a href="/blog/{post.slug}">
						<!-- Image placeholder -->
						<div class="h-48 bg-gradient-to-br from-emerald-500 to-teal-500 flex items-center justify-center">
							<span class="text-white text-4xl font-bold">
								{post.title.charAt(0)}
							</span>
						</div>

						<div class="p-6">
							<div class="flex items-center gap-3 mb-3">
								<span class="text-xs font-semibold px-3 py-1 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full">
									{post.category}
								</span>
								<span class="text-sm theme-text-muted flex items-center gap-1">
									<Clock class="w-4 h-4" />
									{post.readTime}
								</span>
							</div>

							<h2 class="text-xl font-bold theme-heading mb-3 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">
								{post.title}
							</h2>

							<p class="theme-text-muted mb-4 line-clamp-2">
								{post.excerpt}
							</p>

							<div class="flex items-center justify-between">
								<div class="flex items-center gap-2">
									<div class="w-8 h-8 bg-emerald-600 dark:bg-emerald-500 rounded-full flex items-center justify-center text-white text-sm font-bold">
										{post.author.split(' ').map(n => n[0]).join('')}
									</div>
									<div>
										<div class="text-sm font-medium theme-heading">{post.author}</div>
										<div class="text-xs theme-text-muted flex items-center gap-1">
											<Calendar class="w-3 h-3" />
											{new Date(post.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
										</div>
									</div>
								</div>

								<ArrowRight class="w-5 h-5 text-emerald-600 dark:text-emerald-400 group-hover:translate-x-1 transition-transform" />
							</div>
						</div>
					</a>
				</article>
			{/each}
		</div>

		{#if filteredPosts.length === 0}
			<div class="text-center py-20">
				<p class="text-xl theme-text-muted">No posts found in this category.</p>
			</div>
		{/if}
	</div>
</section>

<!-- Newsletter CTA -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
		<h2 class="text-3xl font-bold theme-heading mb-4">
			Never Miss an Update
		</h2>
		<p class="text-lg theme-text-muted mb-8">
			Get the latest business tips and product updates delivered to your inbox weekly.
		</p>
		<form class="flex flex-col sm:flex-row gap-4">
			<input
				type="email"
				placeholder="Enter your email"
				class="flex-1 px-6 py-4 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
			/>
			<button
				type="submit"
				class="px-8 py-4 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors"
			>
				Subscribe
			</button>
		</form>
		<p class="text-sm theme-text-muted mt-4">
			No spam. Unsubscribe anytime.
		</p>
	</div>
</section>
