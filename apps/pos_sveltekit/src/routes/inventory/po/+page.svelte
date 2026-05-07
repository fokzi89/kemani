<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Plus, Search, Filter, FileText, ChevronRight, AlertCircle } from 'lucide-svelte';
	import { fade } from 'svelte/transition';

	let loading = $state(true);
	let purchaseOrders = $state<any[]>([]);
	let searchTerm = $state('');
	let statusFilter = $state('all');
	let error = $state('');

	async function fetchPurchaseOrders() {
		loading = true;
		try {
			let query = supabase
				.from('purchase_orders')
				.select(`
					*,
					branches(name),
					suppliers(name)
				`)
				.order('created_at', { ascending: false });

			if (statusFilter !== 'all') {
				query = query.eq('status', statusFilter);
			}

			const { data, error: dbErr } = await query;
			if (dbErr) throw dbErr;
			purchaseOrders = data || [];
		} catch (err: any) {
			error = err.message || 'Failed to fetch purchase orders';
		} finally {
			loading = false;
		}
	}

	onMount(fetchPurchaseOrders);

	let filteredPOs = $derived(
		purchaseOrders.filter(po => 
			(po.po_number?.toLowerCase().includes(searchTerm.toLowerCase()) || 
			 po.suppliers?.name?.toLowerCase().includes(searchTerm.toLowerCase()))
		)
	);

	const statusColors: Record<string, string> = {
		draft: 'bg-gray-100 text-gray-700',
		pending: 'bg-amber-100 text-amber-700',
		partially_received: 'bg-blue-100 text-blue-700',
		completed: 'bg-green-100 text-green-700',
		cancelled: 'bg-red-100 text-red-700'
	};
</script>

<svelte:head><title>Purchase Orders – Kemani POS</title></svelte:head>

<div class="p-6">
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Purchase Orders</h1>
			<p class="text-sm text-gray-500 mt-0.5">Manage stock procurement from suppliers</p>
		</div>
		<a href="/inventory/po/new" class="inline-flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-all shadow-lg shadow-indigo-100">
			<Plus class="h-4 w-4" /> Create PO
		</a>
	</div>

	<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
		<div class="md:col-span-2 relative">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input 
				type="text" 
				bind:value={searchTerm}
				placeholder="Search by PO number or supplier..." 
				class="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none text-sm"
			/>
		</div>
		<div class="relative">
			<Filter class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<select 
				bind:value={statusFilter}
				onchange={fetchPurchaseOrders}
				class="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none text-sm appearance-none"
			>
				<option value="all">All Statuses</option>
				<option value="draft">Draft</option>
				<option value="pending">Pending</option>
				<option value="partially_received">Partially Received</option>
				<option value="completed">Completed</option>
				<option value="cancelled">Cancelled</option>
			</select>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-xl mb-6 flex items-center gap-2">
			<AlertCircle class="h-5 w-5" />
			<p class="text-sm">{error}</p>
		</div>
	{/if}

	{#if loading}
		<div class="grid grid-cols-1 gap-4">
			{#each Array(3) as _}
				<div class="bg-white border border-gray-100 rounded-2xl p-5 animate-pulse">
					<div class="flex justify-between mb-4">
						<div class="h-5 w-32 bg-gray-100 rounded-md"></div>
						<div class="h-5 w-20 bg-gray-100 rounded-md"></div>
					</div>
					<div class="space-y-2">
						<div class="h-4 w-48 bg-gray-50 rounded-md"></div>
						<div class="h-4 w-36 bg-gray-50 rounded-md"></div>
					</div>
				</div>
			{/each}
		</div>
	{:else if filteredPOs.length === 0}
		<div class="bg-white border border-dashed border-gray-300 rounded-3xl p-12 text-center">
			<div class="bg-gray-50 h-16 w-16 rounded-2xl flex items-center justify-center mx-auto mb-4">
				<FileText class="h-8 w-8 text-gray-300" />
			</div>
			<h3 class="text-lg font-bold text-gray-900 mb-1">No purchase orders found</h3>
			<p class="text-gray-500 text-sm mb-6">Start by creating your first purchase order to restock items.</p>
			<a href="/inventory/po/new" class="inline-flex items-center gap-2 text-indigo-600 font-semibold hover:underline">
				<Plus class="h-4 w-4" /> Create PO now
			</a>
		</div>
	{:else}
		<div class="grid grid-cols-1 gap-4">
			{#each filteredPOs as po}
				<a 
					href="/inventory/po/{po.id}" 
					class="bg-white border border-gray-100 rounded-2xl p-5 hover:border-indigo-200 hover:shadow-md transition-all group"
					transition:fade
				>
					<div class="flex justify-between items-start mb-3">
						<div>
							<h3 class="font-bold text-gray-900 flex items-center gap-2">
								{po.po_number || 'Draft PO'}
								{#if !po.po_number}
									<span class="text-[10px] uppercase tracking-wider bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded">ID: {po.id.slice(0,8)}</span>
								{/if}
							</h3>
							<p class="text-sm text-gray-500 mt-0.5">{po.suppliers?.name || 'No Supplier'}</p>
						</div>
						<span class="text-xs font-bold px-2.5 py-1 rounded-full {statusColors[po.status]}">
							{po.status.replace('_', ' ').toUpperCase()}
						</span>
					</div>
					
					<div class="flex items-end justify-between">
						<div class="space-y-1">
							<p class="text-xs text-gray-400 flex items-center gap-1">
								Branch: <span class="text-gray-600 font-medium">{po.branches?.name}</span>
							</p>
							<p class="text-xs text-gray-400 flex items-center gap-1">
								Created: <span class="text-gray-600 font-medium">{new Date(po.created_at).toLocaleDateString()}</span>
							</p>
						</div>
						<div class="text-right">
							<p class="text-sm font-bold text-gray-900">{po.total_cost.toLocaleString('en-NG', { style: 'currency', currency: po.currency || 'NGN' })}</p>
							<div class="flex items-center gap-1 text-indigo-600 text-xs font-bold mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
								View Details <ChevronRight class="h-3 w-3" />
							</div>
						</div>
					</div>
				</a>
			{/each}
		</div>
	{/if}
</div>
