<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { TrendingUp, Users, DollarSign, Calendar, Star, Clock } from 'lucide-svelte';

	let provider = $state(null);
	let analytics = $state({
		totalConsultations: 0,
		completedConsultations: 0,
		totalRevenue: 0,
		averageRating: 0,
		totalPatients: 0,
		monthlyConsultations: 0,
		monthlyRevenue: 0,
		consultationsByType: {
			chat: 0,
			video: 0,
			audio: 0,
			office_visit: 0
		},
		consultationsByStatus: {
			pending: 0,
			in_progress: 0,
			completed: 0,
			cancelled: 0
		}
	});
	let loading = $state(true);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();

		if (session) {
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();

			provider = providerData;

			if (provider) {
				await loadAnalytics(provider.id);
			}
		}

		loading = false;
	});

	async function loadAnalytics(providerId: string) {
		// Total consultations
		const { count: totalCount } = await supabase
			.from('consultations')
			.select('*', { count: 'exact', head: true })
			.eq('provider_id', providerId);

		// Completed consultations
		const { count: completedCount } = await supabase
			.from('consultations')
			.select('*', { count: 'exact', head: true })
			.eq('provider_id', providerId)
			.eq('status', 'completed');

		// Total patients (unique)
		const { count: patientsCount } = await supabase
			.from('consultations')
			.select('patient_id', { count: 'exact', head: true })
			.eq('provider_id', providerId);

		// Monthly stats
		const firstDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();

		const { count: monthlyCount } = await supabase
			.from('consultations')
			.select('*', { count: 'exact', head: true })
			.eq('provider_id', providerId)
			.gte('created_at', firstDayOfMonth);

		// Consultations by type
		const { data: consultationsData } = await supabase
			.from('consultations')
			.select('type, consultation_fee')
			.eq('provider_id', providerId);

		const consultationsByType = {
			chat: 0,
			video: 0,
			audio: 0,
			office_visit: 0
		};

		let totalRevenue = 0;

		consultationsData?.forEach(c => {
			consultationsByType[c.type] = (consultationsByType[c.type] || 0) + 1;
			totalRevenue += c.consultation_fee || 0;
		});

		// Consultations by status
		const { data: statusData } = await supabase
			.from('consultations')
			.select('status')
			.eq('provider_id', providerId);

		const consultationsByStatus = {
			pending: 0,
			in_progress: 0,
			completed: 0,
			cancelled: 0
		};

		statusData?.forEach(c => {
			consultationsByStatus[c.status] = (consultationsByStatus[c.status] || 0) + 1;
		});

		analytics = {
			totalConsultations: totalCount || 0,
			completedConsultations: completedCount || 0,
			totalRevenue,
			averageRating: provider?.average_rating || 0,
			totalPatients: patientsCount || 0,
			monthlyConsultations: monthlyCount || 0,
			monthlyRevenue: 0, // Calculate from transactions
			consultationsByType,
			consultationsByStatus
		};
	}
</script>

<div class="space-y-6">
	<!-- Header -->
	<div class="bg-white rounded-lg shadow p-6">
		<h2 class="text-2xl font-bold text-gray-900">Analytics Dashboard</h2>
		<p class="text-gray-600 mt-1">Track your performance and earnings</p>
	</div>

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
		<!-- Key Metrics -->
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Total Consultations</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{analytics.totalConsultations}</p>
					</div>
					<div class="bg-blue-100 p-3 rounded-full">
						<Calendar class="h-6 w-6 text-blue-600" />
					</div>
				</div>
			</div>

			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Completed</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{analytics.completedConsultations}</p>
					</div>
					<div class="bg-green-100 p-3 rounded-full">
						<TrendingUp class="h-6 w-6 text-green-600" />
					</div>
				</div>
			</div>

			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Total Patients</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{analytics.totalPatients}</p>
					</div>
					<div class="bg-purple-100 p-3 rounded-full">
						<Users class="h-6 w-6 text-purple-600" />
					</div>
				</div>
			</div>

			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Total Revenue</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">₦{analytics.totalRevenue.toLocaleString()}</p>
					</div>
					<div class="bg-emerald-100 p-3 rounded-full">
						<DollarSign class="h-6 w-6 text-emerald-600" />
					</div>
				</div>
			</div>

			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Average Rating</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{analytics.averageRating.toFixed(1)}</p>
					</div>
					<div class="bg-yellow-100 p-3 rounded-full">
						<Star class="h-6 w-6 text-yellow-600" />
					</div>
				</div>
			</div>

			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">This Month</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{analytics.monthlyConsultations}</p>
					</div>
					<div class="bg-indigo-100 p-3 rounded-full">
						<Clock class="h-6 w-6 text-indigo-600" />
					</div>
				</div>
			</div>
		</div>

		<!-- Charts Section -->
		<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
			<!-- Consultations by Type -->
			<div class="bg-white rounded-lg shadow p-6">
				<h3 class="text-lg font-semibold text-gray-900 mb-4">Consultations by Type</h3>
				<div class="space-y-3">
					{#each Object.entries(analytics.consultationsByType) as [type, count]}
						<div>
							<div class="flex justify-between text-sm mb-1">
								<span class="text-gray-600 capitalize">{type.replace('_', ' ')}</span>
								<span class="font-medium text-gray-900">{count}</span>
							</div>
							<div class="w-full bg-gray-200 rounded-full h-2">
								<div
									class="bg-primary-600 h-2 rounded-full"
									style="width: {analytics.totalConsultations > 0 ? (count / analytics.totalConsultations * 100) : 0}%"
								></div>
							</div>
						</div>
					{/each}
				</div>
			</div>

			<!-- Consultations by Status -->
			<div class="bg-white rounded-lg shadow p-6">
				<h3 class="text-lg font-semibold text-gray-900 mb-4">Consultations by Status</h3>
				<div class="space-y-3">
					{#each Object.entries(analytics.consultationsByStatus) as [status, count]}
						<div>
							<div class="flex justify-between text-sm mb-1">
								<span class="text-gray-600 capitalize">{status.replace('_', ' ')}</span>
								<span class="font-medium text-gray-900">{count}</span>
							</div>
							<div class="w-full bg-gray-200 rounded-full h-2">
								<div
									class="bg-primary-600 h-2 rounded-full"
									style="width: {analytics.totalConsultations > 0 ? (count / analytics.totalConsultations * 100) : 0}%"
								></div>
							</div>
						</div>
					{/each}
				</div>
			</div>
		</div>
	{/if}
</div>
