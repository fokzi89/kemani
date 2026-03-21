<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { DollarSign, TrendingUp, Clock, CheckCircle, AlertCircle, Download, Filter } from 'lucide-svelte';

	let provider = $state(null);
	let transactions = $state([]);
	let stats = $state({
		totalEarnings: 0,
		pendingPayout: 0,
		paidOut: 0,
		totalConsultations: 0,
		averageEarning: 0,
		thisMonthEarnings: 0
	});
	let loading = $state(true);
	let filter = $state('all'); // all, pending_payout, paid_out, on_hold
	let dateFilter = $state('all'); // all, today, this_week, this_month, last_month

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
				await loadCommissionData(provider.id);
			}
		}

		loading = false;
	});

	async function loadCommissionData(providerId: string) {
		// Build query for transactions
		let query = supabase
			.from('consultation_transactions')
			.select('*')
			.eq('provider_id', providerId)
			.order('created_at', { ascending: false });

		// Apply status filter
		if (filter !== 'all') {
			query = query.eq('payout_status', filter);
		}

		// Apply date filter
		if (dateFilter !== 'all') {
			const now = new Date();
			let startDate: Date;

			switch (dateFilter) {
				case 'today':
					startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
					break;
				case 'this_week':
					startDate = new Date(now.setDate(now.getDate() - now.getDay()));
					break;
				case 'this_month':
					startDate = new Date(now.getFullYear(), now.getMonth(), 1);
					break;
				case 'last_month':
					startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
					const endDate = new Date(now.getFullYear(), now.getMonth(), 0);
					query = query.gte('created_at', startDate.toISOString()).lte('created_at', endDate.toISOString());
					break;
			}

			if (dateFilter !== 'last_month') {
				query = query.gte('created_at', startDate.toISOString());
			}
		}

		const { data } = await query;
		transactions = data || [];

		// Calculate statistics
		calculateStats(providerId);
	}

	async function calculateStats(providerId: string) {
		// Get all transactions for stats
		const { data: allTransactions } = await supabase
			.from('consultation_transactions')
			.select('*')
			.eq('provider_id', providerId);

		if (allTransactions) {
			const totalEarnings = allTransactions.reduce((sum, t) => sum + parseFloat(t.net_provider_amount || 0), 0);
			const pendingPayout = allTransactions
				.filter(t => t.payout_status === 'pending_payout')
				.reduce((sum, t) => sum + parseFloat(t.net_provider_amount || 0), 0);
			const paidOut = allTransactions
				.filter(t => t.payout_status === 'paid_out')
				.reduce((sum, t) => sum + parseFloat(t.net_provider_amount || 0), 0);

			// This month earnings
			const firstDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();
			const thisMonthTransactions = allTransactions.filter(t => t.created_at >= firstDayOfMonth);
			const thisMonthEarnings = thisMonthTransactions.reduce((sum, t) => sum + parseFloat(t.net_provider_amount || 0), 0);

			stats = {
				totalEarnings,
				pendingPayout,
				paidOut,
				totalConsultations: allTransactions.length,
				averageEarning: allTransactions.length > 0 ? totalEarnings / allTransactions.length : 0,
				thisMonthEarnings
			};
		}
	}

	async function handleFilterChange() {
		if (provider) {
			loading = true;
			await loadCommissionData(provider.id);
			loading = false;
		}
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'N/A';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function formatCurrency(amount: number | string) {
		const num = typeof amount === 'string' ? parseFloat(amount) : amount;
		return `₦${num.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
	}

	function getPayoutStatusColor(status: string) {
		switch (status) {
			case 'paid_out': return 'bg-green-100 text-green-800';
			case 'pending_payout': return 'bg-yellow-100 text-yellow-800';
			case 'on_hold': return 'bg-orange-100 text-orange-800';
			case 'cancelled': return 'bg-red-100 text-red-800';
			default: return 'bg-gray-100 text-gray-800';
		}
	}

	function getPayoutStatusIcon(status: string) {
		switch (status) {
			case 'paid_out': return CheckCircle;
			case 'pending_payout': return Clock;
			case 'on_hold': return AlertCircle;
			default: return AlertCircle;
		}
	}

	function exportToCSV() {
		if (transactions.length === 0) return;

		const headers = ['Date', 'Consultation ID', 'Gross Amount', 'Commission', 'Net Amount', 'Payout Status', 'Payout Date'];
		const rows = transactions.map(t => [
			formatDate(t.created_at),
			t.consultation_id.slice(0, 8),
			t.gross_amount,
			t.commission_amount,
			t.net_provider_amount,
			t.payout_status,
			t.payout_date ? formatDate(t.payout_date) : 'Pending'
		]);

		const csvContent = [
			headers.join(','),
			...rows.map(row => row.join(','))
		].join('\n');

		const blob = new Blob([csvContent], { type: 'text/csv' });
		const url = window.URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `commission-history-${new Date().toISOString().split('T')[0]}.csv`;
		a.click();
		window.URL.revokeObjectURL(url);
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-lg shadow p-6">
		<div class="flex justify-between items-center">
			<div>
				<h2 class="text-2xl font-bold text-gray-900">Commission History & Earnings</h2>
				<p class="text-gray-600 mt-1">Track your consultation earnings and payouts</p>
			</div>
			<button
				onclick={exportToCSV}
				disabled={transactions.length === 0}
				class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
			>
				<Download class="h-5 w-5" />
				Export CSV
			</button>
		</div>
	</div>

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
			<!-- Total Earnings -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Total Earnings</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{formatCurrency(stats.totalEarnings)}</p>
					</div>
					<div class="bg-emerald-100 p-3 rounded-full">
						<DollarSign class="h-6 w-6 text-emerald-600" />
					</div>
				</div>
			</div>

			<!-- Pending Payout -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Pending Payout</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{formatCurrency(stats.pendingPayout)}</p>
					</div>
					<div class="bg-yellow-100 p-3 rounded-full">
						<Clock class="h-6 w-6 text-yellow-600" />
					</div>
				</div>
			</div>

			<!-- Paid Out -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Paid Out</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{formatCurrency(stats.paidOut)}</p>
					</div>
					<div class="bg-green-100 p-3 rounded-full">
						<CheckCircle class="h-6 w-6 text-green-600" />
					</div>
				</div>
			</div>

			<!-- This Month Earnings -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">This Month</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{formatCurrency(stats.thisMonthEarnings)}</p>
					</div>
					<div class="bg-blue-100 p-3 rounded-full">
						<TrendingUp class="h-6 w-6 text-blue-600" />
					</div>
				</div>
			</div>

			<!-- Total Consultations -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Total Consultations</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{stats.totalConsultations}</p>
					</div>
					<div class="bg-purple-100 p-3 rounded-full">
						<CheckCircle class="h-6 w-6 text-purple-600" />
					</div>
				</div>
			</div>

			<!-- Average Earning -->
			<div class="bg-white rounded-lg shadow p-6">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Average per Consultation</p>
						<p class="text-3xl font-bold text-gray-900 mt-2">{formatCurrency(stats.averageEarning)}</p>
					</div>
					<div class="bg-indigo-100 p-3 rounded-full">
						<TrendingUp class="h-6 w-6 text-indigo-600" />
					</div>
				</div>
			</div>
		</div>
	{/if}

	<!-- Filters -->
	<div class="bg-white rounded-lg shadow p-4">
		<div class="flex items-center gap-2 mb-3">
			<Filter class="h-5 w-5 text-gray-500" />
			<h3 class="font-semibold text-gray-900">Filters</h3>
		</div>
		<div class="flex flex-wrap gap-4">
			<!-- Status Filter -->
			<div>
				<label class="block text-sm font-medium text-gray-700 mb-2">Payout Status</label>
				<select
					bind:value={filter}
					onchange={handleFilterChange}
					class="px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500"
				>
					<option value="all">All Status</option>
					<option value="pending_payout">Pending Payout</option>
					<option value="paid_out">Paid Out</option>
					<option value="on_hold">On Hold</option>
					<option value="cancelled">Cancelled</option>
				</select>
			</div>

			<!-- Date Filter -->
			<div>
				<label class="block text-sm font-medium text-gray-700 mb-2">Date Range</label>
				<select
					bind:value={dateFilter}
					onchange={handleFilterChange}
					class="px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500"
				>
					<option value="all">All Time</option>
					<option value="today">Today</option>
					<option value="this_week">This Week</option>
					<option value="this_month">This Month</option>
					<option value="last_month">Last Month</option>
				</select>
			</div>
		</div>
	</div>

	<!-- Transactions Table -->
	<div class="bg-white rounded-lg shadow overflow-hidden">
		<div class="p-6 border-b border-gray-200">
			<h3 class="text-lg font-semibold text-gray-900">Transaction History</h3>
		</div>

		{#if loading}
			<div class="p-12 text-center">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
				<p class="mt-4 text-gray-600">Loading transactions...</p>
			</div>
		{:else if transactions.length === 0}
			<div class="p-12 text-center">
				<DollarSign class="h-16 w-16 text-gray-300 mx-auto mb-4" />
				<h3 class="text-lg font-medium text-gray-900 mb-2">No transactions found</h3>
				<p class="text-gray-600">
					{#if filter !== 'all' || dateFilter !== 'all'}
						Try adjusting your filters to see more results.
					{:else}
						Your commission transactions will appear here once you complete consultations.
					{/if}
				</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full">
					<thead class="bg-gray-50">
						<tr>
							<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
								Date
							</th>
							<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
								Consultation
							</th>
							<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
								Gross Amount
							</th>
							<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
								Commission
							</th>
							<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
								Your Earnings
							</th>
							<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
								Status
							</th>
							<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
								Payout Date
							</th>
						</tr>
					</thead>
					<tbody class="bg-white divide-y divide-gray-200">
						{#each transactions as transaction}
							<tr class="hover:bg-gray-50">
								<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
									{formatDate(transaction.created_at)}
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="text-sm font-medium text-gray-900">
										ID: {transaction.consultation_id.slice(0, 8)}
									</div>
									{#if transaction.referral_source !== 'direct'}
										<div class="text-xs text-gray-500">
											Referred from: {transaction.referral_source}
										</div>
									{/if}
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
									{formatCurrency(transaction.gross_amount)}
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-sm text-red-600">
									-{formatCurrency(transaction.commission_amount)}
									<div class="text-xs text-gray-500">
										({(parseFloat(transaction.commission_rate) * 100).toFixed(1)}%)
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-green-600">
									{formatCurrency(transaction.net_provider_amount)}
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<span class="px-2 py-1 inline-flex items-center gap-1 text-xs leading-5 font-semibold rounded-full {getPayoutStatusColor(transaction.payout_status)}">
										<svelte:component this={getPayoutStatusIcon(transaction.payout_status)} class="h-3 w-3" />
										{transaction.payout_status.replace('_', ' ')}
									</span>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
									{transaction.payout_date ? formatDate(transaction.payout_date) : '-'}
									{#if transaction.payout_reference}
										<div class="text-xs text-gray-500">
											Ref: {transaction.payout_reference.slice(0, 10)}
										</div>
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</div>

	<!-- Payment Information -->
	<div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
		<div class="flex items-start gap-3">
			<AlertCircle class="h-5 w-5 text-blue-600 mt-0.5 flex-shrink-0" />
			<div>
				<h3 class="font-semibold text-blue-900 mb-2">Payout Information</h3>
				<ul class="text-sm text-blue-800 space-y-1">
					<li>• Payouts are processed weekly on Fridays for all pending earnings</li>
					<li>• Platform commission: {provider?.average_rating ? '15%' : '15%'} (10% surcharge + 5% deduction)</li>
					<li>• Minimum payout threshold: ₦10,000</li>
					<li>• Funds are transferred to your registered bank account within 3-5 business days</li>
					<li>• For payout inquiries, contact support@kemani.com</li>
				</ul>
			</div>
		</div>
	</div>
	</div>
</div>
