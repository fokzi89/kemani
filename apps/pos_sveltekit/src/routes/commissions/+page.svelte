<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Coins, TrendingUp, Calendar, ArrowUpRight, 
		Search, Filter, Download, MoreHorizontal,
		ArrowDownRight, CheckCircle2, Clock
	} from 'lucide-svelte';

	let loading = $state(true);
	let stats = $state({
		totalEarned: 1450250.00,
		pendingPayout: 320900.50,
		lastMonth: 480100.00,
		growth: 12.5
	});

	let commissionHistory = $state([
		{ id: 'TX-4592', date: '2024-03-28', source: 'Consultation - Dr. John Doe', amount: 45000, commission: 2250, status: 'paid' },
		{ id: 'TX-4593', date: '2024-03-29', source: 'Pharmacy Sale - 54RE Batch', amount: 120500, commission: 6025, status: 'pending' },
		{ id: 'TX-4594', date: '2024-03-30', source: 'Lab Test - Full Panel', amount: 35000, commission: 1750, status: 'paid' },
		{ id: 'TX-4595', date: '2024-03-31', source: 'Consultation - Roshal Test', amount: 50000, commission: 2500, status: 'pending' },
	]);

	onMount(async () => {
		// Simulations for now as tables might be dynamic
		setTimeout(() => {
			loading = false;
		}, 800);
	});

	function formatCurrency(val: number) {
		return new Intl.NumberFormat('en-NG', { strategy: 'currency', currency: 'NGN' }).format(val).replace('NGN', '₦');
	}
</script>

<svelte:head><title>Commissions – Kemani POS</title></svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Commissions</h1>
			<p class="text-sm text-gray-500 mt-1">Track your revenue shares and payout history.</p>
		</div>
		<div class="flex items-center gap-3">
			<button class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded-xl transition-all shadow-sm flex items-center gap-2 text-sm">
				<Download class="h-4 w-4" />
				Export CSV
			</button>
		</div>
	</div>

	<!-- Stats Grid -->
	<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
		<div class="bg-white p-5 rounded-xl border border-gray-100 shadow-sm">
			<div class="flex items-center justify-between mb-3">
				<p class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Total Earned</p>
				<div class="bg-green-50 p-2 rounded-lg"><TrendingUp class="h-4 w-4 text-green-600" /></div>
			</div>
			<div class="flex items-baseline gap-2">
				<h2 class="text-2xl font-bold text-gray-900">{formatCurrency(stats.totalEarned)}</h2>
				<span class="text-xs font-bold text-green-600">+{stats.growth}%</span>
			</div>
		</div>

		<div class="bg-white p-5 rounded-xl border border-indigo-100 shadow-sm">
			<div class="flex items-center justify-between mb-3">
				<p class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Pending Payout</p>
				<div class="bg-indigo-50 p-2 rounded-lg"><Clock class="h-4 w-4 text-indigo-600" /></div>
			</div>
			<h2 class="text-2xl font-bold text-indigo-600">{formatCurrency(stats.pendingPayout)}</h2>
		</div>

		<div class="bg-white p-5 rounded-xl border border-gray-100 shadow-sm">
			<div class="flex items-center justify-between mb-3">
				<p class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Last Month</p>
				<div class="bg-gray-50 p-2 rounded-lg"><Calendar class="h-4 w-4 text-gray-600" /></div>
			</div>
			<h2 class="text-2xl font-bold text-gray-900">{formatCurrency(stats.lastMonth)}</h2>
		</div>

		<div class="bg-white p-5 rounded-xl border border-gray-100 shadow-sm border-l-4 border-l-amber-400">
			<p class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Commission Rate</p>
			<p class="text-2xl font-bold text-gray-900">5.0%</p>
			<p class="text-xs text-gray-400 mt-1">Marketplace Standard</p>
		</div>
	</div>

	<!-- History Table -->
	<div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
		<div class="p-4 border-b border-gray-50 flex flex-col md:flex-row gap-3 items-center justify-between bg-gray-50/30">
			<h3 class="font-bold text-gray-900 text-sm">Commission History</h3>
			<div class="flex gap-2 w-full md:w-auto">
				<div class="relative w-full md:w-64">
					<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
					<input 
						type="text" 
						placeholder="Search reference..."
						class="w-full pl-9 pr-4 py-2 bg-white border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 text-xs transition-all outline-none"
					/>
				</div>
				<button class="p-2 aspect-square bg-white border border-gray-200 text-gray-500 rounded-lg hover:bg-gray-50 transition-all">
					<Filter class="h-4 w-4" />
				</button>
			</div>
		</div>

		<div class="overflow-x-auto min-h-[400px]">
			{#if loading}
				<div class="p-12 text-center">
					<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
					<p class="text-xs text-gray-500 mt-4 font-medium italic">Calculating commissions...</p>
				</div>
			{:else}
				<table class="w-full text-left text-sm">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Reference</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Source Item</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Value</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Commission</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider text-center">Status</th>
							<th class="px-4 py-3 text-right">Action</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each commissionHistory as item}
							<tr class="hover:bg-gray-50 transition-colors">
								<td class="px-4 py-4 text-xs font-mono text-gray-500">{item.id}</td>
								<td class="px-4 py-4">
									<div class="font-semibold text-gray-900 leading-none">{item.source}</div>
									<div class="text-[10px] text-gray-400 mt-1 uppercase leading-none">{item.date}</div>
								</td>
								<td class="px-4 py-4 text-right font-medium text-gray-700">{formatCurrency(item.amount)}</td>
								<td class="px-4 py-4 text-right">
									<div class="text-indigo-600 font-bold">{formatCurrency(item.commission)}</div>
								</td>
								<td class="px-4 py-4 text-center">
									{#if item.status === 'paid'}
										<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-green-50 text-green-700 border border-green-100">
											<CheckCircle2 class="h-3 w-3" /> PAID
										</span>
									{:else}
										<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-100">
											<Clock class="h-3 w-3" /> PENDING
										</span>
									{/if}
								</td>
								<td class="px-4 py-4 text-right">
									<button class="p-1.5 text-gray-400 hover:text-gray-900 rounded-lg hover:bg-white transition-all">
										<MoreHorizontal class="h-4 w-4" />
									</button>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			{/if}
		</div>
	</div>
</div>

