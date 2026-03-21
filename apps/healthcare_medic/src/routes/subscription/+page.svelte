<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Check, Zap, Star, Crown } from 'lucide-svelte';

	let provider = $state(null);
	let currentSubscription = $state(null);
	let loading = $state(true);
	let upgrading = $state(false);

	const tiers = [
		{
			id: 'free',
			name: 'Free',
			price: 0,
			icon: Zap,
			description: 'Perfect for getting started',
			features: [
				'Unlimited chat consultations',
				'Unlimited video consultations',
				'Unlimited audio consultations',
				'Basic analytics dashboard',
				'Patient management',
				'No office consultations',
				'No drug commissions',
				'No diagnostic commissions',
				'Standard support'
			],
			highlighted: false
		},
		{
			id: 'growth',
			name: 'Growth',
			price: 25000,
			icon: Star,
			description: 'Grow your practice with commissions',
			features: [
				'Everything in Free, plus:',
				'Drug referral commissions',
				'Diagnostic test commissions',
				'Custom branding',
				'Full analytics dashboard',
				'Priority email support',
				'No office consultations',
				'Commission tracking',
				'Payout management'
			],
			highlighted: true
		},
		{
			id: 'enterprise',
			name: 'Enterprise',
			price: 120000,
			icon: Crown,
			description: 'Complete healthcare practice solution',
			features: [
				'Everything in Growth, plus:',
				'Office visit consultations',
				'Unlimited consultation types',
				'Advanced analytics & insights',
				'Priority phone & email support',
				'Dedicated account manager',
				'Custom integrations',
				'API access',
				'White-label options'
			],
			highlighted: false
		}
	];

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();

		if (!session) {
			goto('/auth/login');
			return;
		}

		// Get provider
		const { data: providerData } = await supabase
			.from('healthcare_providers')
			.select('*')
			.eq('user_id', session.user.id)
			.single();

		provider = providerData;

		if (provider?.medic_subscription_id) {
			// Get current subscription
			const { data: subData } = await supabase
				.from('medic_subscriptions')
				.select('*')
				.eq('id', provider.medic_subscription_id)
				.single();

			currentSubscription = subData;
		}

		loading = false;
	});

	async function upgradePlan(tier: string) {
		if (!provider) return;

		upgrading = true;

		try {
			const tierConfig = tiers.find(t => t.id === tier);
			if (!tierConfig) {
				alert('Invalid tier selected');
				upgrading = false;
				return;
			}

			// Calculate billing cycle
			const now = new Date();
			const billingCycleEnd = new Date(now);
			billingCycleEnd.setMonth(billingCycleEnd.getMonth() + 1);

			// Update or create subscription
			if (currentSubscription) {
				// Update existing subscription
				const { error } = await supabase
					.from('medic_subscriptions')
					.update({
						tier,
						monthly_fee: tierConfig.price,
						status: 'active',
						billing_cycle_start: now.toISOString(),
						billing_cycle_end: billingCycleEnd.toISOString(),
						next_billing_date: billingCycleEnd.toISOString(),
						features: getFeatureConfig(tier),
						drug_commission_rate: tier === 'free' ? 0 : 5,
						diagnostic_commission_rate: tier === 'free' ? 0 : 5
					})
					.eq('id', currentSubscription.id);

				if (error) {
					console.error('Subscription update error:', error);
					alert('Failed to upgrade subscription: ' + error.message);
					upgrading = false;
					return;
				}
			} else {
				// Create new subscription
				const { data: newSub, error } = await supabase
					.from('medic_subscriptions')
					.insert({
						user_id: provider.user_id,
						provider_id: provider.id,
						tier,
						monthly_fee: tierConfig.price,
						status: 'active',
						billing_cycle_start: now.toISOString(),
						billing_cycle_end: billingCycleEnd.toISOString(),
						next_billing_date: billingCycleEnd.toISOString(),
						features: getFeatureConfig(tier),
						drug_commission_rate: tier === 'free' ? 0 : 5,
						diagnostic_commission_rate: tier === 'free' ? 0 : 5
					})
					.select()
					.single();

				if (error) {
					console.error('Subscription creation error:', error);
					alert('Failed to create subscription: ' + error.message);
					upgrading = false;
					return;
				}

				// Update provider with subscription ID
				await supabase
					.from('healthcare_providers')
					.update({ medic_subscription_id: newSub.id })
					.eq('id', provider.id);
			}

			alert(`Successfully upgraded to ${tierConfig.name} plan!`);
			window.location.reload();
		} catch (err) {
			console.error('Upgrade error:', err);
			alert('An error occurred during upgrade');
			upgrading = false;
		}
	}

	function getFeatureConfig(tier: string) {
		const configs = {
			free: {
				chat_consultations: true,
				video_consultations: true,
				audio_consultations: true,
				office_consultations: false,
				consultation_quota: -1,
				patient_management: true,
				drug_commission_enabled: false,
				diagnostic_commission_enabled: false,
				custom_branding: false,
				analytics_dashboard: true,
				priority_support: false
			},
			growth: {
				chat_consultations: true,
				video_consultations: true,
				audio_consultations: true,
				office_consultations: false,
				consultation_quota: -1,
				patient_management: true,
				drug_commission_enabled: true,
				diagnostic_commission_enabled: true,
				custom_branding: true,
				analytics_dashboard: true,
				priority_support: true
			},
			enterprise: {
				chat_consultations: true,
				video_consultations: true,
				audio_consultations: true,
				office_consultations: true,
				consultation_quota: -1,
				patient_management: true,
				drug_commission_enabled: true,
				diagnostic_commission_enabled: true,
				custom_branding: true,
				analytics_dashboard: true,
				priority_support: true,
				dedicated_manager: true,
				api_access: true
			}
		};

		return configs[tier] || configs.free;
	}

	function canUpgrade(tier: string) {
		if (!currentSubscription) return true;

		const tierOrder = { free: 0, growth: 1, enterprise: 2 };
		return tierOrder[tier] > tierOrder[currentSubscription.tier];
	}

	function isCurrentPlan(tier: string) {
		return currentSubscription?.tier === tier;
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-8">
		<!-- Header -->
		<div>
			<h1 class="text-3xl font-bold text-gray-900">Subscription Plans</h1>
			<p class="text-gray-600 mt-2">
				Choose the plan that best fits your practice needs
			</p>
		</div>

		{#if loading}
			<div class="flex items-center justify-center py-12">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
			</div>
		{:else}
			<!-- Current Plan Badge -->
			{#if currentSubscription}
				<div class="bg-primary-50 border border-primary-200 rounded-lg p-4">
					<div class="flex items-center gap-3">
						<div class="bg-primary-100 p-2 rounded-full">
							<Check class="h-5 w-5 text-primary-600" />
						</div>
						<div>
							<p class="text-sm font-medium text-primary-900">Current Plan</p>
							<p class="text-lg font-bold text-primary-700">
								{tiers.find(t => t.id === currentSubscription.tier)?.name || 'Unknown'} - ₦{currentSubscription.monthly_fee.toLocaleString()}/month
							</p>
						</div>
					</div>
				</div>
			{/if}

			<!-- Pricing Cards -->
			<div class="grid grid-cols-1 md:grid-cols-3 gap-8">
				{#each tiers as tier}
					<div class="relative bg-white rounded-lg shadow-lg overflow-hidden {tier.highlighted ? 'ring-2 ring-primary-500' : ''}">
						{#if tier.highlighted}
							<div class="absolute top-0 right-0 bg-primary-500 text-white text-xs font-bold px-3 py-1 rounded-bl-lg">
								POPULAR
							</div>
						{/if}

						<div class="p-6">
							<!-- Icon & Name -->
							<div class="flex items-center gap-3 mb-4">
								<div class="p-3 bg-primary-100 rounded-lg">
									<svelte:component this={tier.icon} class="h-6 w-6 text-primary-600" />
								</div>
								<h3 class="text-2xl font-bold text-gray-900">{tier.name}</h3>
							</div>

							<!-- Price -->
							<div class="mb-4">
								<div class="flex items-baseline gap-2">
									<span class="text-4xl font-bold text-gray-900">₦{tier.price.toLocaleString()}</span>
									<span class="text-gray-600">/month</span>
								</div>
								<p class="text-sm text-gray-600 mt-1">{tier.description}</p>
							</div>

							<!-- Features -->
							<ul class="space-y-3 mb-6">
								{#each tier.features as feature}
									<li class="flex items-start gap-2">
										<Check class="h-5 w-5 text-primary-600 flex-shrink-0 mt-0.5" />
										<span class="text-sm text-gray-700">{feature}</span>
									</li>
								{/each}
							</ul>

							<!-- Action Button -->
							{#if isCurrentPlan(tier.id)}
								<button
									disabled
									class="w-full py-3 px-4 bg-gray-100 text-gray-500 rounded-lg font-medium cursor-not-allowed"
								>
									Current Plan
								</button>
							{:else if !canUpgrade(tier.id)}
								<button
									disabled
									class="w-full py-3 px-4 bg-gray-100 text-gray-500 rounded-lg font-medium cursor-not-allowed"
								>
									Cannot Downgrade
								</button>
							{:else}
								<button
									onclick={() => upgradePlan(tier.id)}
									disabled={upgrading}
									class="w-full py-3 px-4 bg-primary-600 hover:bg-primary-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed {tier.highlighted ? 'shadow-lg shadow-primary-500/50' : ''}"
								>
									{upgrading ? 'Processing...' : tier.price === 0 ? 'Select Free Plan' : 'Upgrade to ' + tier.name}
								</button>
							{/if}
						</div>
					</div>
				{/each}
			</div>

			<!-- Info Section -->
			<div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
				<h3 class="text-lg font-semibold text-blue-900 mb-2">Important Information</h3>
				<ul class="space-y-2 text-sm text-blue-800">
					<li>• All plans include unlimited consultations (chat, video, audio)</li>
					<li>• Drug and diagnostic commissions are 5% on Growth and Enterprise plans</li>
					<li>• Billing cycle starts immediately upon upgrade</li>
					<li>• You can upgrade at any time, but downgrades are not supported</li>
					<li>• Enterprise plan includes dedicated support and custom integrations</li>
				</ul>
			</div>
		{/if}
	</div>
</div>
