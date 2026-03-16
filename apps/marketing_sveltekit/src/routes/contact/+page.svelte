<script lang="ts">
	import { Mail, Phone, MapPin, MessageCircle, Send, CheckCircle } from 'lucide-svelte';

	let formData = {
		name: '',
		email: '',
		phone: '',
		company: '',
		subject: '',
		message: ''
	};

	let isSubmitting = false;
	let isSubmitted = false;
	let error = '';

	async function handleSubmit(event: Event) {
		event.preventDefault();
		isSubmitting = true;
		error = '';

		try {
			// TODO: Replace with actual Supabase integration
			// For now, simulate API call
			await new Promise(resolve => setTimeout(resolve, 1500));

			// Success
			isSubmitted = true;
			formData = { name: '', email: '', phone: '', company: '', subject: '', message: '' };

			setTimeout(() => {
				isSubmitted = false;
			}, 5000);
		} catch (err) {
			error = 'Something went wrong. Please try again or email us directly.';
		} finally {
			isSubmitting = false;
		}
	}
</script>

<svelte:head>
	<title>Contact Us - Kemani | Get in Touch</title>
	<meta name="description" content="Contact Kemani for sales inquiries, support, or partnership opportunities. We're here to help your business succeed." />
</svelte:head>

<!-- Hero Section -->
<section class="pt-32 pb-20 theme-bg">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center max-w-3xl mx-auto">
			<h1 class="text-4xl md:text-5xl font-bold theme-heading mb-6">
				Get in <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">Touch</span>
			</h1>
			<p class="text-xl theme-text-muted mb-8">
				Have questions? We'd love to hear from you. Send us a message and we'll respond as soon as possible.
			</p>
		</div>
	</div>
</section>

<!-- Contact Section -->
<section class="py-20 theme-bg-secondary">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="grid lg:grid-cols-3 gap-12">
			<!-- Contact Info -->
			<div class="lg:col-span-1">
				<h2 class="text-2xl font-bold theme-heading mb-8">Contact Information</h2>

				<div class="space-y-6">
					<div class="flex items-start gap-4">
						<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
							<Mail class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
						</div>
						<div>
							<div class="font-semibold theme-heading mb-1">Email</div>
							<a href="mailto:hello@kemani.app" class="theme-text-muted hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
								hello@kemani.app
							</a>
							<div class="text-sm theme-text-muted mt-1">For general inquiries</div>
						</div>
					</div>

					<div class="flex items-start gap-4">
						<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
							<Mail class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
						</div>
						<div>
							<div class="font-semibold theme-heading mb-1">Sales</div>
							<a href="mailto:sales@kemani.app" class="theme-text-muted hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
								sales@kemani.app
							</a>
							<div class="text-sm theme-text-muted mt-1">For business inquiries</div>
						</div>
					</div>

					<div class="flex items-start gap-4">
						<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
							<MessageCircle class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
						</div>
						<div>
							<div class="font-semibold theme-heading mb-1">Support</div>
							<a href="mailto:support@kemani.app" class="theme-text-muted hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
								support@kemani.app
							</a>
							<div class="text-sm theme-text-muted mt-1">For technical support</div>
						</div>
					</div>

					<div class="flex items-start gap-4">
						<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
							<Phone class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
						</div>
						<div>
							<div class="font-semibold theme-heading mb-1">Phone</div>
							<a href="tel:+2348012345678" class="theme-text-muted hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors">
								+234 801 234 5678
							</a>
							<div class="text-sm theme-text-muted mt-1">Mon-Fri 9am-6pm WAT</div>
						</div>
					</div>

					<div class="flex items-start gap-4">
						<div class="w-12 h-12 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
							<MapPin class="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
						</div>
						<div>
							<div class="font-semibold theme-heading mb-1">Office</div>
							<div class="theme-text-muted">
								4 Adeyemo Alakija Street<br />
								Victoria Island, Lagos<br />
								Nigeria
							</div>
						</div>
					</div>
				</div>

				<!-- Social Links -->
				<div class="mt-12">
					<div class="font-semibold theme-heading mb-4">Follow Us</div>
					<div class="flex gap-4">
						<a href="#" class="w-10 h-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center hover:bg-emerald-200 dark:hover:bg-emerald-900/50 transition-colors">
							<span class="sr-only">Twitter</span>
							<svg class="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="currentColor" viewBox="0 0 24 24">
								<path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
							</svg>
						</a>
						<a href="#" class="w-10 h-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center hover:bg-emerald-200 dark:hover:bg-emerald-900/50 transition-colors">
							<span class="sr-only">LinkedIn</span>
							<svg class="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="currentColor" viewBox="0 0 24 24">
								<path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
							</svg>
						</a>
						<a href="#" class="w-10 h-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center hover:bg-emerald-200 dark:hover:bg-emerald-900/50 transition-colors">
							<span class="sr-only">Facebook</span>
							<svg class="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="currentColor" viewBox="0 0 24 24">
								<path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
							</svg>
						</a>
					</div>
				</div>
			</div>

			<!-- Contact Form -->
			<div class="lg:col-span-2">
				<div class="theme-card p-8">
					<h2 class="text-2xl font-bold theme-heading mb-6">Send us a Message</h2>

					{#if isSubmitted}
						<div class="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800 rounded-lg p-6 flex items-start gap-4">
							<CheckCircle class="w-6 h-6 text-emerald-600 dark:text-emerald-400 flex-shrink-0 mt-0.5" />
							<div>
								<div class="font-semibold text-emerald-900 dark:text-emerald-100 mb-1">
									Message Sent Successfully!
								</div>
								<div class="text-sm text-emerald-700 dark:text-emerald-300">
									Thank you for contacting us. We'll get back to you within 24 hours.
								</div>
							</div>
						</div>
					{:else}
						<form on:submit={handleSubmit} class="space-y-6">
							<div class="grid md:grid-cols-2 gap-6">
								<div>
									<label for="name" class="block text-sm font-medium theme-heading mb-2">
										Full Name <span class="text-red-500">*</span>
									</label>
									<input
										type="text"
										id="name"
										bind:value={formData.name}
										required
										class="w-full px-4 py-3 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
										placeholder="John Doe"
									/>
								</div>

								<div>
									<label for="email" class="block text-sm font-medium theme-heading mb-2">
										Email Address <span class="text-red-500">*</span>
									</label>
									<input
										type="email"
										id="email"
										bind:value={formData.email}
										required
										class="w-full px-4 py-3 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
										placeholder="john@example.com"
									/>
								</div>
							</div>

							<div class="grid md:grid-cols-2 gap-6">
								<div>
									<label for="phone" class="block text-sm font-medium theme-heading mb-2">
										Phone Number
									</label>
									<input
										type="tel"
										id="phone"
										bind:value={formData.phone}
										class="w-full px-4 py-3 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
										placeholder="+234 801 234 5678"
									/>
								</div>

								<div>
									<label for="company" class="block text-sm font-medium theme-heading mb-2">
										Company Name
									</label>
									<input
										type="text"
										id="company"
										bind:value={formData.company}
										class="w-full px-4 py-3 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
										placeholder="Your Business"
									/>
								</div>
							</div>

							<div>
								<label for="subject" class="block text-sm font-medium theme-heading mb-2">
									Subject <span class="text-red-500">*</span>
								</label>
								<select
									id="subject"
									bind:value={formData.subject}
									required
									class="w-full px-4 py-3 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
								>
									<option value="">Select a subject</option>
									<option value="sales">Sales Inquiry</option>
									<option value="support">Technical Support</option>
									<option value="partnership">Partnership Opportunity</option>
									<option value="billing">Billing Question</option>
									<option value="feedback">Product Feedback</option>
									<option value="other">Other</option>
								</select>
							</div>

							<div>
								<label for="message" class="block text-sm font-medium theme-heading mb-2">
									Message <span class="text-red-500">*</span>
								</label>
								<textarea
									id="message"
									bind:value={formData.message}
									required
									rows="6"
									class="w-full px-4 py-3 theme-card rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400 resize-none"
									placeholder="Tell us more about how we can help..."
								></textarea>
							</div>

							{#if error}
								<div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 text-red-700 dark:text-red-300 text-sm">
									{error}
								</div>
							{/if}

							<button
								type="submit"
								disabled={isSubmitting}
								class="w-full px-8 py-4 bg-emerald-600 dark:bg-emerald-500 text-white rounded-lg font-semibold hover:bg-emerald-700 dark:hover:bg-emerald-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
							>
								{#if isSubmitting}
									<span class="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
									<span>Sending...</span>
								{:else}
									<Send class="w-5 h-5" />
									<span>Send Message</span>
								{/if}
							</button>
						</form>
					{/if}
				</div>

				<!-- Quick Support -->
				<div class="mt-8 grid md:grid-cols-2 gap-6">
					<div class="theme-card p-6">
						<h3 class="font-semibold theme-heading mb-2">Need Immediate Help?</h3>
						<p class="text-sm theme-text-muted mb-4">
							Check out our help center for instant answers to common questions.
						</p>
						<a href="/help" class="text-emerald-600 dark:text-emerald-400 hover:underline font-medium text-sm">
							Visit Help Center →
						</a>
					</div>

					<div class="theme-card p-6">
						<h3 class="font-semibold theme-heading mb-2">Schedule a Demo</h3>
						<p class="text-sm theme-text-muted mb-4">
							See Kemani in action with a personalized demo from our team.
						</p>
						<a href="#" class="text-emerald-600 dark:text-emerald-400 hover:underline font-medium text-sm">
							Book a Demo →
						</a>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- Office Hours -->
<section class="py-20 theme-bg">
	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
		<h2 class="text-2xl font-bold theme-heading mb-6">Office Hours</h2>
		<div class="grid md:grid-cols-2 gap-8">
			<div>
				<div class="font-semibold theme-heading mb-2">Sales & Support</div>
				<div class="theme-text-muted">
					Monday - Friday: 9:00 AM - 6:00 PM WAT<br />
					Saturday: 10:00 AM - 4:00 PM WAT<br />
					Sunday: Closed
				</div>
			</div>
			<div>
				<div class="font-semibold theme-heading mb-2">Emergency Support</div>
				<div class="theme-text-muted">
					24/7 for Enterprise customers<br />
					Critical issues only<br />
					Response within 1 hour
				</div>
			</div>
		</div>
	</div>
</section>
