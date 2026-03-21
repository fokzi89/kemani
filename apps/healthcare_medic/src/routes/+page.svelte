<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Calendar, Users, FileText, DollarSign, Clock, CheckCircle, Zap, ArrowUpCircle } from 'lucide-svelte';

	let provider = $state(null);
	let subscription = $state(null);
	let stats = $state({
		todayConsultations: 0,
		upcomingConsultations: 0,
		totalPatients: 0,
		pendingPrescriptions: 0,
		monthlyEarnings: 0,
		completedConsultations: 0
	});
	let recentConsultations = $state([]);
	let loading = $state(true);

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

		if (provider) {
			// Check if onboarding is complete
			const isOnboardingComplete = provider.phone &&
				provider.specialization &&
				provider.bio &&
				provider.clinic_address;

			if (!isOnboardingComplete) {
				goto('/onboarding');
				return;
			}

			await loadDashboardData(provider.id);

			// Get subscription
			if (provider.medic_subscription_id) {
				const { data: subData } = await supabase
					.from('medic_subscriptions')
					.select('*')
					.eq('id', provider.medic_subscription_id)
					.single();

				subscription = subData;
			}
		} else {
			// No provider profile exists, redirect to onboarding
			goto('/onboarding');
			return;
		}

		loading = false;
	});

	async function loadDashboardData(providerId: string) {
		// Get today's consultations
		const today = new Date().toISOString().split('T')[0];
		const { count: todayCount } = await supabase
			.from('consultations')
			.select('*', { count: 'exact', head: true })
			.eq('provider_id', providerId)
			.gte('scheduled_time', `${today}T00:00:00`)
			.lt('scheduled_time', `${today}T23:59:59`)
			.in('status', ['pending', 'in_progress']);

		// Get upcoming consultations
		const { count: upcomingCount } = await supabase
			.from('consultations')
			.select('*', { count: 'exact', head: true })
			.eq('provider_id', providerId)
			.gte('scheduled_time', new Date().toISOString())
			.eq('status', 'pending');

		// Get total patients (unique)
		const { count: patientsCount } = await supabase
			.from('consultations')
			.select('patient_id', { count: 'exact', head: true })
			.eq('provider_id', providerId);

		// Get completed consultations this month
		const firstDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();
		const { count: completedCount } = await supabase
			.from('consultations')
			.select('*', { count: 'exact', head: true })
			.eq('provider_id', providerId)
			.eq('status', 'completed')
			.gte('created_at', firstDayOfMonth);

		// Get monthly earnings from transactions
		const { data: monthlyTransactions } = await supabase
			.from('consultation_transactions')
			.select('net_provider_amount')
			.eq('provider_id', providerId)
			.gte('created_at', firstDayOfMonth);

		const monthlyEarnings = monthlyTransactions?.reduce((sum, t) => sum + parseFloat(t.net_provider_amount || 0), 0) || 0;

		// Get recent consultations
		const { data: consultationsData } = await supabase
			.from('consultations')
			.select('*')
			.eq('provider_id', providerId)
			.order('created_at', { ascending: false })
			.limit(5);

		stats = {
			todayConsultations: todayCount || 0,
			upcomingConsultations: upcomingCount || 0,
			totalPatients: patientsCount || 0,
			pendingPrescriptions: 0,
			monthlyEarnings,
			completedConsultations: completedCount || 0
		};

		recentConsultations = consultationsData || [];
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'N/A';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function getStatusColor(status: string) {
		switch (status) {
			case 'completed': return 'bg-green-100 text-green-800';
			case 'in_progress': return 'bg-blue-100 text-blue-800';
			case 'pending': return 'bg-yellow-100 text-yellow-800';
			case 'cancelled': return 'bg-red-100 text-red-800';
			default: return 'bg-gray-100 text-gray-800';
		}
	}

	function getTimeOfDayGreeting() {
		const hour = new Date().getHours();
		if (hour < 12) return 'Good morning';
		if (hour < 17) return 'Good afternoon';
		return 'Good evening';
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Welcome Section -->
		<div class="bg-white rounded-lg shadow p-6">
			<h2 class="text-3xl font-bold text-gray-900">
				{getTimeOfDayGreeting()}, Dr. {provider?.full_name?.split(' ')[provider?.full_name?.split(' ').length - 1] || 'Doctor'}!
			</h2>
			<p class="text-gray-600 mt-2">Here's what's happening with your practice today.</p>
		</div>

		<!-- Subscription Upgrade Card -->
		{#if subscription && subscription.tier !== 'enterprise'}
			<div class="bg-gradient-to-r from-primary-500 to-primary-600 rounded-lg shadow-lg p-6 text-white">
				<div class="flex items-center justify-between">
					<div class="flex items-center gap-4">
						<div class="bg-white/20 p-3 rounded-lg">
							<Zap class="h-8 w-8" />
						</div>
						<div>
							<h3 class="text-xl font-bold">Current Plan: {subscription.tier === 'free' ? 'Free' : 'Growth'}</h3>
							<p class="text-primary-50 mt-1">
								{#if subscription.tier === 'free'}
									Upgrade to Growth to earn commissions on drug and diagnostic referrals
								{:else}
									Upgrade to Enterprise for office consultations and dedicated support
								{/if}
							</p>
						</div>
					</div>
					<a
						href="/subscription"
						class="flex items-center gap-2 px-6 py-3 bg-white text-primary-600 font-semibold rounded-lg hover:bg-primary-50 transition-colors"
					>
						<ArrowUpCircle class="h-5 w-5" />
						Upgrade Plan
					</a>
				</div>
			</div>
		{/if}

	<!-- Stats Grid -->
	{#if loading}
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
			{#each Array(6) as _}
				<div class="bg-white rounded-lg shadow p-6 animate-pulse">
					<div class="h-4 bg-gray-200 rounded w-1/2"></div>
					<div class="h-8 bg-gray-200 rounded w-1/3 mt-4"></div>
				</div>
			{/each}
		</div>
	{:else}
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
			<!-- Today's Consultations -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Today's Consultations</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{stats.todayConsultations}</p>
					</div>
					<div class="bg-blue-100 p-3 rounded-full">
						<Calendar class="h-6 w-6 text-blue-600" />
					</div>
				</div>
			</div>

			<!-- Upcoming -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Upcoming</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{stats.upcomingConsultations}</p>
					</div>
					<div class="bg-yellow-100 p-3 rounded-full">
						<Clock class="h-6 w-6 text-yellow-600" />
					</div>
				</div>
			</div>

			<!-- Total Patients -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Total Patients</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{stats.totalPatients}</p>
					</div>
					<div class="bg-green-100 p-3 rounded-full">
						<Users class="h-6 w-6 text-green-600" />
					</div>
				</div>
			</div>

			<!-- Completed This Month -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Completed This Month</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{stats.completedConsultations}</p>
					</div>
					<div class="bg-purple-100 p-3 rounded-full">
						<CheckCircle class="h-6 w-6 text-purple-600" />
					</div>
				</div>
			</div>

			<!-- Prescriptions -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Active Prescriptions</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{stats.pendingPrescriptions}</p>
					</div>
					<div class="bg-indigo-100 p-3 rounded-full">
						<FileText class="h-6 w-6 text-indigo-600" />
					</div>
				</div>
			</div>

			<!-- Monthly Earnings -->
			<a href="/commissions" class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow block">
				<div class="flex items-center justify-between mb-3">
					<div>
						<p class="text-sm font-medium text-gray-600">Monthly Earnings</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">₦{stats.monthlyEarnings.toLocaleString()}</p>
					</div>
					<div class="bg-emerald-100 p-3 rounded-full">
						<DollarSign class="h-6 w-6 text-emerald-600" />
					</div>
				</div>
				<div class="text-sm text-primary-600 hover:text-primary-700 font-medium">
					View commission history →
				</div>
			</a>
		</div>
	{/if}

	<!-- Recent Consultations -->
	<div class="bg-white rounded-lg shadow">
		<div class="p-6 border-b border-gray-200">
			<h3 class="text-lg font-semibold text-gray-900">Recent Consultations</h3>
		</div>
		<div class="overflow-x-auto">
			<table class="w-full">
				<thead class="bg-gray-50">
					<tr>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
							Patient
						</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
							Type
						</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
							Date
						</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
							Status
						</th>
						<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
							Fee
						</th>
					</tr>
				</thead>
				<tbody class="bg-white divide-y divide-gray-200">
					{#if recentConsultations.length === 0}
						<tr>
							<td colspan="5" class="px-6 py-8 text-center text-gray-500">
								No consultations yet
							</td>
						</tr>
					{:else}
						{#each recentConsultations as consultation}
							<tr class="hover:bg-gray-50">
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="text-sm font-medium text-gray-900">
										{consultation.provider_name || 'Patient'}
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="text-sm text-gray-900 capitalize">{consultation.type}</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="text-sm text-gray-900">{formatDate(consultation.scheduled_time || consultation.created_at)}</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<span class="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full {getStatusColor(consultation.status)}">
										{consultation.status}
									</span>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
									₦{consultation.consultation_fee?.toLocaleString() || '0'}
								</td>
							</tr>
						{/each}
					{/if}
				</tbody>
			</table>
		</div>
	</div>
	</div>
</div>
