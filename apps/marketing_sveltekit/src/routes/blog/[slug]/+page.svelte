<script lang="ts">
	import { page } from '$app/stores';
	import { Calendar, Clock, ArrowLeft, Share2 } from 'lucide-svelte';

	// In production, fetch from Supabase based on $page.params.slug
	const blogPost = {
		title: 'How to Increase Retail Sales with POS Analytics',
		author: 'Adebayo Ogunlesi',
		date: '2026-03-01',
		readTime: '5 min read',
		category: 'POS Tips',
		content: `
			<h2>Understanding Your Sales Data</h2>
			<p>Modern POS systems generate vast amounts of data every single day. From transaction times to product performance, this data holds the key to unlocking significant sales growth for your retail business.</p>

			<h2>Key Metrics to Track</h2>
			<p>Here are the most important metrics you should be monitoring:</p>
			<ul>
				<li><strong>Average Transaction Value:</strong> Track how much customers spend per visit</li>
				<li><strong>Best-Selling Products:</strong> Identify your star performers</li>
				<li><strong>Peak Sales Hours:</strong> Optimize staffing and inventory</li>
				<li><strong>Customer Purchase Frequency:</strong> Measure loyalty and retention</li>
			</ul>

			<h2>Actionable Strategies</h2>
			<h3>1. Optimize Product Placement</h3>
			<p>Use your POS data to identify which products are frequently purchased together. Place complementary items near each other to encourage bundle purchases and increase average transaction value.</p>

			<h3>2. Time-Based Promotions</h3>
			<p>Analyze your peak and slow hours. Run targeted promotions during slow periods to boost traffic, and ensure you're fully stocked during peak times.</p>

			<h3>3. Personalized Customer Engagement</h3>
			<p>Leverage customer purchase history to create personalized offers. Customers who feel understood are more likely to return and spend more.</p>

			<h2>Real Results</h2>
			<p>Businesses using Kemani's POS analytics have reported:</p>
			<ul>
				<li>30% increase in average transaction value</li>
				<li>25% reduction in slow-moving inventory</li>
				<li>40% improvement in customer retention</li>
			</ul>

			<h2>Getting Started</h2>
			<p>The good news? You don't need to be a data scientist to benefit from POS analytics. Kemani's dashboard presents all these insights in an easy-to-understand format, with actionable recommendations you can implement immediately.</p>

			<p>Start your free trial today and see how data-driven decision-making can transform your retail business.</p>
		`
	};
</script>

<svelte:head>
	<title>{blogPost.title} - Kemani Blog</title>
	<meta name="description" content={blogPost.title} />
</svelte:head>

<!-- Article Header -->
<article class="pt-32 pb-20">
	<!-- Back Button -->
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 mb-8">
		<a href="/blog" class="inline-flex items-center gap-2 theme-text-muted hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
			<ArrowLeft class="w-4 h-4" />
			<span>Back to Blog</span>
		</a>
	</div>

	<!-- Article Content -->
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
		<!-- Category & Meta -->
		<div class="flex flex-wrap items-center gap-4 mb-6">
			<span class="text-sm font-semibold px-4 py-2 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full">
				{blogPost.category}
			</span>
			<span class="text-sm theme-text-muted flex items-center gap-1">
				<Clock class="w-4 h-4" />
				{blogPost.readTime}
			</span>
			<span class="text-sm theme-text-muted flex items-center gap-1">
				<Calendar class="w-4 h-4" />
				{new Date(blogPost.date).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
			</span>
		</div>

		<!-- Title -->
		<h1 class="text-4xl md:text-5xl font-bold theme-heading mb-6">
			{blogPost.title}
		</h1>

		<!-- Author -->
		<div class="flex items-center justify-between mb-12 pb-8 border-b theme-border">
			<div class="flex items-center gap-3">
				<div class="w-12 h-12 bg-emerald-600 dark:bg-emerald-500 rounded-full flex items-center justify-center text-white font-bold">
					{blogPost.author.split(' ').map(n => n[0]).join('')}
				</div>
				<div>
					<div class="font-semibold theme-heading">{blogPost.author}</div>
					<div class="text-sm theme-text-muted">Co-Founder & CEO</div>
				</div>
			</div>

			<button class="p-3 theme-card rounded-lg hover:border-emerald-600 transition-colors">
				<Share2 class="w-5 h-5" />
			</button>
		</div>

		<!-- Featured Image Placeholder -->
		<div class="mb-12 h-96 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-2xl flex items-center justify-center">
			<span class="text-white text-6xl font-bold">
				{blogPost.title.charAt(0)}
			</span>
		</div>

		<!-- Article Body -->
		<div class="prose prose-lg dark:prose-invert max-w-none theme-text">
			{@html blogPost.content}
		</div>

		<!-- Share Section -->
		<div class="mt-16 pt-8 border-t theme-border">
			<div class="flex items-center justify-between">
				<div class="text-lg font-semibold theme-heading">Share this article</div>
				<div class="flex gap-3">
					<button class="p-3 theme-card rounded-lg hover:border-emerald-600 transition-colors">
						<span class="sr-only">Share on Twitter</span>
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
							<path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
						</svg>
					</button>
					<button class="p-3 theme-card rounded-lg hover:border-emerald-600 transition-colors">
						<span class="sr-only">Share on LinkedIn</span>
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
							<path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
						</svg>
					</button>
					<button class="p-3 theme-card rounded-lg hover:border-emerald-600 transition-colors">
						<span class="sr-only">Share on Facebook</span>
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
							<path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
						</svg>
					</button>
				</div>
			</div>
		</div>
	</div>
</article>

<!-- Related Posts -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<h2 class="text-3xl font-bold theme-heading mb-12 text-center">Related Articles</h2>
		<div class="grid md:grid-cols-3 gap-8">
			<!-- Placeholder for related posts -->
			<div class="theme-card p-6">
				<div class="text-sm font-semibold px-3 py-1 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full inline-block mb-4">
					POS Tips
				</div>
				<h3 class="text-xl font-bold theme-heading mb-3">
					<a href="#" class="hover:text-emerald-600 dark:hover:text-emerald-400">
						5 Ways to Speed Up Checkout Times
					</a>
				</h3>
				<p class="theme-text-muted text-sm">
					Reduce wait times and improve customer satisfaction with these proven strategies.
				</p>
			</div>
			<div class="theme-card p-6">
				<div class="text-sm font-semibold px-3 py-1 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full inline-block mb-4">
					Business Growth
				</div>
				<h3 class="text-xl font-bold theme-heading mb-3">
					<a href="#" class="hover:text-emerald-600 dark:hover:text-emerald-400">
						Scaling Your Retail Business
					</a>
				</h3>
				<p class="theme-text-muted text-sm">
					Essential steps to expand from one store to a multi-location empire.
				</p>
			</div>
			<div class="theme-card p-6">
				<div class="text-sm font-semibold px-3 py-1 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full inline-block mb-4">
					Inventory
				</div>
				<h3 class="text-xl font-bold theme-heading mb-3">
					<a href="#" class="hover:text-emerald-600 dark:hover:text-emerald-400">
						Preventing Stock-Outs
					</a>
				</h3>
				<p class="theme-text-muted text-sm">
					Never lose a sale again with smart inventory management techniques.
				</p>
			</div>
		</div>
	</div>
</section>

<!-- CTA -->
<section class="py-20 theme-bg">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
		<h2 class="text-3xl font-bold theme-heading mb-6">
			Ready to Put These Tips into Action?
		</h2>
		<p class="text-xl theme-text-muted mb-8">
			Start your 30-day free trial and experience the power of data-driven retail.
		</p>
		<a href="/pricing" class="inline-block px-8 py-4 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors">
			Get Started Free
		</a>
	</div>
</section>

<style>
	:global(.prose h2) {
		@apply text-2xl font-bold theme-heading mt-8 mb-4;
	}

	:global(.prose h3) {
		@apply text-xl font-semibold theme-heading mt-6 mb-3;
	}

	:global(.prose p) {
		@apply theme-text-muted mb-4 leading-relaxed;
	}

	:global(.prose ul) {
		@apply space-y-2 mb-6;
	}

	:global(.prose li) {
		@apply theme-text-muted ml-6;
		list-style-type: disc;
	}

	:global(.prose strong) {
		@apply font-semibold theme-heading;
	}
</style>
