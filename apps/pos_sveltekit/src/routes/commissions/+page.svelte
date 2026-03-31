<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Coins, TrendingUp, Calendar, ArrowUpRight, 
		Search, Filter, Download, MoreHorizontal,
		ArrowDownRight
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
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}
</script>

<div class="p-8 max-w-7xl mx-auto space-y-8 animate-in fade-in duration-700">
	<!-- Header -->
	<div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
		<div class="space-y-1">
			<div class="flex items-center gap-3">
				<div class="p-2.5 bg-amber-100 rounded-xl">
					<Coins class="h-8 w-8 text-amber-600" />
				</div>
				<h1 class="text-3xl font-black text-gray-900 tracking-tight">Commissions</h1>
			</div>
			<p class="text-gray-500 font-medium">Track your revenue shares and payout history.</p>
		</div>
		<div class="flex items-center gap-3">
			<button class="p-2.5 bg-white border border-gray-200 text-gray-700 rounded-xl hover:bg-gray-50 transition-all shadow-sm">
				<Calendar class="h-5 w-5" />
			</button>
			<button class="bg-gray-900 hover:bg-black text-white font-bold py-3 px-8 rounded-xl transition-all shadow-xl flex items-center gap-2">
				<Download class="h-5 w-5" />
				Export Report
			</button>
		</div>
	</div>

	<!-- Stats Grid -->
	<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
		<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
			<div class="absolute -right-4 -top-4 bg-indigo-50 h-24 w-24 rounded-full group-hover:scale-110 transition-transform duration-500 opacity-50"></div>
			<p class="text-xs font-bold text-gray-400 uppercase tracking-widest relative z-10">Total Earned</p>
			<h2 class="text-3xl font-black text-gray-900 mt-2 relative z-10">{formatCurrency(stats.totalEarned)}</h2>
			<div class="mt-4 flex items-center gap-1.5 text-green-600 font-bold text-sm relative z-10">
				<TrendingUp class="h-4 w-4" />
				+{stats.growth}% vs LY
			</div>
		</div>

		<div class="bg-indigo-600 p-6 rounded-3xl shadow-xl shadow-indigo-100 relative overflow-hidden group">
			<div class="absolute -right-4 -top-4 bg-white/10 h-24 w-24 rounded-full group-hover:scale-110 transition-transform duration-500"></div>
			<p class="text-xs font-bold text-indigo-100 uppercase tracking-widest relative z-10">Pending Payout</p>
			<h2 class="text-3xl font-black text-white mt-2 relative z-10">{formatCurrency(stats.pendingPayout)}</h2>
			<div class="mt-4 flex items-center gap-2 text-white/80 font-bold text-sm relative z-10">
				<div class="bg-white/20 px-3 py-1 rounded-full flex items-center gap-2">
					<ArrowUpRight class="h-4 w-4" />
					In Review
				</div>
			</div>
		</div>

		<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
			<div class="absolute -right-4 -top-4 bg-amber-50 h-24 w-24 rounded-full group-hover:scale-110 transition-transform duration-500 opacity-50"></div>
			<p class="text-xs font-bold text-gray-400 uppercase tracking-widest relative z-10">Last Month</p>
			<h2 class="text-3xl font-black text-gray-900 mt-2 relative z-10">{formatCurrency(stats.lastMonth)}</h2>
			<div class="mt-4 flex items-center gap-1.5 text-amber-600 font-bold text-sm relative z-10 italic">
				<ArrowDownRight class="h-4 w-4" />
				Calculated Monthly
			</div>
		</div>

		<div class="bg-white p-6 rounded-3xl border border-indigo-100 shadow-sm hover:shadow-md transition-shadow flex flex-col justify-center items-center text-center">
			<div class="bg-indigo-50 p-4 rounded-full mb-3 pointer-events-none group">
				<TrendingUp class="h-6 w-6 text-indigo-600 group-hover:animate-bounce" />
			</div>
			<p class="text-sm font-bold text-gray-900">Current Rate</p>
			<p class="text-2xl font-black text-indigo-600">5.0%</p>
			<p class="text-[10px] text-gray-400 font-medium">Standard Marketplace Rate</p>
		</div>
	</div>

	<!-- History Table -->
	<div class="bg-white rounded-3xl border border-gray-100 shadow-sm overflow-hidden">
		<div class="p-6 border-b border-gray-50 flex flex-col md:flex-row gap-4 items-center justify-between">
			<h3 class="text-xl font-bold text-gray-900">Commission History</h3>
			<div class="flex gap-2 w-full md:w-auto">
				<div class="relative flex-1 md:w-72">
					<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
					<input 
						type="text" 
						placeholder="Search by ID or source..."
						class="w-full pl-9 pr-4 py-2 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-indigo-500 font-medium text-sm transition-all"
					/>
				</div>
				<button class="p-2.5 bg-gray-50 text-gray-500 rounded-xl hover:bg-gray-100 transition-all border-none outline-none">
					<Filter class="h-4 w-4" />
				</button>
			</div>
		</div>

		<div class="overflow-x-auto min-h-[400px]">
			{#if loading}
				<div class="flex flex-col items-center justify-center h-[400px] text-center">
					<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div>
					<p class="text-gray-400 mt-4 font-bold text-sm tracking-widest uppercase">Calculating Shares...</p>
				</div>
			{:else}
				<table class="w-full text-left">
					<thead class="bg-gray-50/50">
						<tr>
							<th class="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Reference ID</th>
							<th class="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Source Item</th>
							<th class="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest text-right">Trans. Value</th>
							<th class="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest text-right">Commission</th>
							<th class="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest text-center">Status</th>
							<th class="px-6 py-4"></th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-50">
						{#each commissionHistory as item}
							<tr class="hover:bg-indigo-50/30 transition-colors group">
								<td class="px-6 py-5 font-black text-gray-400 text-sm">{item.id}</td>
								<td class="px-6 py-5 underline decoration-indigo-200 underline-offset-4 decoration-2 font-bold text-gray-900 group-hover:text-indigo-700 transition-colors">
									{item.source}
									<div class="text-[10px] text-gray-400 font-medium mt-1 uppercase tracking-tighter">Processed: {item.date}</div>
								</td>
								<td class="px-6 py-5 text-right font-bold text-gray-700">{formatCurrency(item.amount)}</td>
								<td class="px-6 py-5 text-right">
									<div class="text-indigo-600 font-black text-base">{formatCurrency(item.commission)}</div>
								</td>
								<td class="px-6 py-5 text-center">
									{#if item.status === 'paid'}
										<span class="inline-flex items-center px-4 py-1 rounded-full text-xs font-black bg-green-100 text-green-700 border border-green-200 shadow-sm">
											PAID
										</span>
									{:else}
										<span class="inline-flex items-center px-4 py-1 rounded-full text-xs font-black bg-amber-100 text-amber-700 border border-amber-200 shadow-sm">
											PENDING
										</span>
									{/if}
								</td>
								<td class="px-6 py-5 text-right">
									<button class="p-2 text-gray-300 hover:text-gray-900 rounded-lg transition-colors">
										<MoreHorizontal class="h-5 w-5" />
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
