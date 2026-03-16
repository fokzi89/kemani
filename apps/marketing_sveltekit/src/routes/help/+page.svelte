<script lang="ts">
	import { ChevronDown } from 'lucide-svelte';

	const faqs = [
		{
			category: 'Getting Started',
			questions: [
				{
					q: 'How do I sign up for Kemani?',
					a: 'Click the "Get Started Free" button on our homepage, enter your business information, and create your account. You\'ll get instant access to a 30-day free trial with no credit card required.'
				},
				{
					q: 'What happens after my free trial ends?',
					a: 'After 30 days, you\'ll be prompted to choose a paid plan. If you don\'t upgrade, your account will be downgraded to the Free tier with limited features. You won\'t lose any data.'
				},
				{
					q: 'How long does it take to set up?',
					a: 'Most businesses are up and running within 1-2 hours. This includes importing products, setting up branches, and training staff. Our onboarding team is available to help you get started.'
				}
			]
		},
		{
			category: 'Pricing & Billing',
			questions: [
				{
					q: 'What payment methods do you accept?',
					a: 'We accept credit/debit cards, bank transfers, and mobile money payments via Flutterwave and Paystack. All transactions are secure and encrypted.'
				},
				{
					q: 'Can I change my plan anytime?',
					a: 'Yes! You can upgrade or downgrade your plan at any time. Upgrades take effect immediately. Downgrades take effect at the end of your current billing cycle.'
				},
				{
					q: 'Do you offer refunds?',
					a: 'We offer a 14-day money-back guarantee for annual subscriptions. Monthly subscriptions are non-refundable, but you can cancel anytime.'
				},
				{
					q: 'How does commission work for marketplace orders?',
					a: 'We charge a percentage commission on marketplace orders as specified in your plan. The rate ranges from 5-12% depending on your subscription tier, with caps per transaction.'
				}
			]
		},
		{
			category: 'Features & Functionality',
			questions: [
				{
					q: 'Does Kemani work offline?',
					a: 'Yes! Our POS system works completely offline. Sales and inventory changes are saved locally and automatically sync when you reconnect to the internet.'
				},
				{
					q: 'Can I use Kemani on mobile devices?',
					a: 'Absolutely! Kemani works on smartphones, tablets, and computers. Download our mobile app for iOS and Android, or use any web browser.'
				},
				{
					q: 'How many products can I add?',
					a: 'Product limits vary by plan. Free tier allows 50 products, Basic allows 500, Pro allows 5,000, and Enterprise plans have unlimited products.'
				},
				{
					q: 'Can I manage multiple store locations?',
					a: 'Yes! Kemani is designed for multi-branch operations. Track inventory separately per location and transfer stock between branches seamlessly.'
				}
			]
		},
		{
			category: 'Healthcare Features',
			questions: [
				{
					q: 'How does the telemedicine feature work?',
					a: 'Patients can book video, audio, or chat consultations with verified healthcare providers. Doctors can issue digital prescriptions that are automatically routed to pharmacies for fulfillment.'
				},
				{
					q: 'Are healthcare providers verified?',
					a: 'Yes, all healthcare providers must submit valid licenses and credentials. Our team verifies each provider before approving their profile.'
				},
				{
					q: 'What commission do healthcare providers pay?',
					a: 'Healthcare providers pay a 15% commission on consultation fees (Pro plan). Enterprise Custom plans offer reduced rates starting at 10%.'
				}
			]
		},
		{
			category: 'Technical Support',
			questions: [
				{
					q: 'What if I need help?',
					a: 'We offer multiple support channels: email support (support@kemani.app), phone support during business hours, and live chat for Pro and Enterprise customers. Check our documentation at help.kemani.app for instant answers.'
				},
				{
					q: 'Do you provide training?',
					a: 'Yes! We offer free video tutorials, documentation, and webinars. Pro and Enterprise customers get personalized onboarding sessions with our team.'
				},
				{
					q: 'How secure is my data?',
					a: 'Very secure. We use bank-level encryption (SSL/TLS), daily backups, and industry-standard security practices. Your data is stored in secure cloud servers with 99.9% uptime SLA.'
				}
			]
		},
		{
			category: 'Integrations',
			questions: [
				{
					q: 'Does Kemani integrate with WooCommerce/Shopify?',
					a: 'Yes! Pro and Enterprise plans include e-commerce platform sync. Connect your WooCommerce or Shopify store to automatically sync products, orders, and inventory.'
				},
				{
					q: 'Can I integrate with my accounting software?',
					a: 'Yes, we offer integrations with QuickBooks, Xero, and other popular accounting platforms. You can also export reports to Excel/CSV for manual import.'
				},
				{
					q: 'Do you have an API?',
					a: 'Yes! Enterprise plans include full API access for custom integrations. Our RESTful API allows you to connect Kemani with any third-party system.'
				}
			]
		}
	];

	let openIndex: number | null = null;

	function toggleFAQ(index: number) {
		openIndex = openIndex === index ? null : index;
	}
</script>

<svelte:head>
	<title>Help & FAQ - Kemani | Get Answers to Your Questions</title>
	<meta name="description" content="Find answers to frequently asked questions about Kemani's POS, inventory management, e-commerce, and healthcare features." />
</svelte:head>

<!-- Hero Section -->
<section class="pt-32 pb-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center max-w-3xl mx-auto">
			<h1 class="text-4xl md:text-5xl font-bold theme-heading mb-6">
				How Can We <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">Help You?</span>
			</h1>
			<p class="text-xl theme-text-muted mb-8">
				Find answers to common questions about Kemani's features, pricing, and support.
			</p>

			<!-- Search Box -->
			<div class="max-w-2xl mx-auto">
				<input
					type="search"
					placeholder="Search for answers..."
					class="w-full px-6 py-4 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
				/>
			</div>
		</div>
	</div>
</section>

<!-- Quick Links -->
<section class="py-12 theme-bg-secondary border-b theme-border">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="grid grid-cols-2 md:grid-cols-4 gap-4">
			<a href="/features" class="theme-card p-6 text-center hover:border-emerald-600 transition-colors">
				<div class="text-3xl mb-2">📚</div>
				<div class="font-semibold theme-heading">Features</div>
			</a>
			<a href="/pricing" class="theme-card p-6 text-center hover:border-emerald-600 transition-colors">
				<div class="text-3xl mb-2">💰</div>
				<div class="font-semibold theme-heading">Pricing</div>
			</a>
			<a href="/contact" class="theme-card p-6 text-center hover:border-emerald-600 transition-colors">
				<div class="text-3xl mb-2">💬</div>
				<div class="font-semibold theme-heading">Contact Support</div>
			</a>
			<a href="/blog" class="theme-card p-6 text-center hover:border-emerald-600 transition-colors">
				<div class="text-3xl mb-2">📝</div>
				<div class="font-semibold theme-heading">Blog & Guides</div>
			</a>
		</div>
	</div>
</section>

<!-- FAQ Section -->
<section class="py-20 theme-bg">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center mb-12">
			<h2 class="text-3xl font-bold theme-heading mb-4">Frequently Asked Questions</h2>
			<p class="text-lg theme-text-muted">
				Can't find what you're looking for? <a href="/contact" class="text-emerald-600 dark:text-emerald-400 hover:underline">Contact our support team</a>
			</p>
		</div>

		<div class="space-y-12">
			{#each faqs as category, categoryIndex}
				<div>
					<h3 class="text-2xl font-bold theme-heading mb-6">{category.category}</h3>
					<div class="space-y-4">
						{#each category.questions as faq, questionIndex}
							{@const index = categoryIndex * 100 + questionIndex}
							<div class="theme-card overflow-hidden">
								<button
									on:click={() => toggleFAQ(index)}
									class="w-full px-6 py-4 flex items-center justify-between text-left hover:bg-emerald-50 dark:hover:bg-emerald-900/10 transition-colors"
								>
									<span class="font-semibold theme-heading pr-4">{faq.q}</span>
									<ChevronDown
										class="w-5 h-5 text-emerald-600 dark:text-emerald-400 flex-shrink-0 transition-transform {openIndex === index ? 'rotate-180' : ''}"
									/>
								</button>
								{#if openIndex === index}
									<div class="px-6 pb-4 theme-text-muted border-t theme-border pt-4">
										{faq.a}
									</div>
								{/if}
							</div>
						{/each}
					</div>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- Contact CTA -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
		<h2 class="text-3xl font-bold theme-heading mb-6">
			Still Have Questions?
		</h2>
		<p class="text-xl theme-text-muted mb-8">
			Our support team is here to help. Get in touch and we'll respond within 24 hours.
		</p>
		<div class="flex flex-col sm:flex-row gap-4 justify-center">
			<a href="/contact" class="inline-block px-8 py-4 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors">
				Contact Support
			</a>
			<a href="mailto:support@kemani.app" class="inline-block px-8 py-4 theme-card font-semibold hover:border-emerald-600 transition-colors">
				Email Us
			</a>
		</div>

		<div class="mt-12 grid md:grid-cols-3 gap-8">
			<div>
				<div class="text-3xl mb-2">📧</div>
				<div class="font-semibold theme-heading mb-1">Email</div>
				<div class="text-sm theme-text-muted">support@kemani.app</div>
			</div>
			<div>
				<div class="text-3xl mb-2">📞</div>
				<div class="font-semibold theme-heading mb-1">Phone</div>
				<div class="text-sm theme-text-muted">+234 801 234 5678</div>
			</div>
			<div>
				<div class="text-3xl mb-2">⏰</div>
				<div class="font-semibold theme-heading mb-1">Hours</div>
				<div class="text-sm theme-text-muted">Mon-Fri 9am-6pm WAT</div>
			</div>
		</div>
	</div>
</section>
