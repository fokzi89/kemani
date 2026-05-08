<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { 
		ArrowLeft, FileText, CheckCircle, Package, Truck, 
		Printer, AlertCircle, Clock, Trash2, Send, X, Calendar, RefreshCw
	} from 'lucide-svelte';
	import { fade } from 'svelte/transition';

	const poId = $page.params.id;
	let loading = $state(true);
	let actionLoading = $state(false);
	let po = $state<any>(null);
	let items = $state<any[]>([]);
	let error = $state('');
	let success = $state('');
	let receipts = $state<any[]>([]);
	import { goto } from '$app/navigation';

	async function fetchPODetails() {
		try {
			const { data, error: dbErr } = await supabase
				.from('purchase_orders')
				.select(`
					*,
					branches(name, address),
					suppliers(*),
					creator:users(full_name)
				`)
				.eq('id', poId)
				.single();
			if (dbErr) throw dbErr;
			po = data;

			const { data: itemsData, error: itemsErr } = await supabase
				.from('purchase_order_items')
				.select(`
					*,
					products(name, barcode)
				`)
				.eq('po_id', poId);
			if (itemsErr) throw itemsErr;
			items = itemsData || [];

			// Fetch Receipts History
			const { data: receiptData } = await supabase
				.from('purchase_order_receipts')
				.select(`
					*,
					staff:users(full_name),
					items:purchase_order_receipt_items(
						*,
						products(name)
					)
				`)
				.eq('po_id', poId)
				.order('received_at', { ascending: false });
			receipts = receiptData || [];

		} catch (err: any) {
			error = err.message;
		} finally {
			loading = false;
		}
	}

	onMount(fetchPODetails);

	async function confirmPO() {
		actionLoading = true;
		try {
			const { data, error: rpcErr } = await supabase.rpc('confirm_purchase_order', { p_po_id: poId });
			if (rpcErr) throw rpcErr;
			success = 'Purchase Order confirmed and number assigned!';
			await fetchPODetails();
		} catch (err: any) {
			error = err.message;
		} finally {
			actionLoading = false;
		}
	}



	function openReceiveModal() {
		goto(`/inventory/po/${poId}/receive`);
	}


	const statusColors: Record<string, string> = {
		draft: 'bg-gray-100 text-gray-700',
		pending: 'bg-amber-100 text-amber-700',
		partially_received: 'bg-blue-100 text-blue-700',
		completed: 'bg-green-100 text-green-700',
		cancelled: 'bg-red-100 text-red-700'
	};

	function getExpiryStatus(dateStr: string | null) {
		if (!dateStr) return { color: 'text-gray-400', label: 'No Expiry' };
		const expiry = new Date(dateStr);
		const today = new Date();
		const diffMs = expiry.getTime() - today.getTime();
		const diffMonths = diffMs / (1000 * 60 * 60 * 24 * 30);
		const diffYears = diffMs / (1000 * 60 * 60 * 24 * 365);

		if (diffMonths < 0) return { color: 'text-red-600 font-black', label: 'EXPIRED' };
		if (diffMonths <= 2) return { color: 'text-red-500 font-bold', label: 'Critical (<2m)' };
		if (diffYears <= 1) return { color: 'text-orange-500 font-bold', label: 'Moderate (<1y)' };
		return { color: 'text-green-600 font-bold', label: 'Safe (>1y)' };
	}
</script>

<svelte:head><title>{po?.po_number || 'Draft'} – PO Detail</title></svelte:head>

<div class="p-6 max-w-5xl mx-auto">
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
		<div class="flex items-center gap-3">
			<a href="/inventory/po" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
			<div>
				<h1 class="text-xl font-bold text-gray-900">{po?.po_number || 'Draft Purchase Order'}</h1>
				<div class="flex items-center gap-2 mt-0.5">
					<span class="text-xs font-bold px-2 py-0.5 rounded-full {statusColors[po?.status || 'draft']}">
						{po?.status.replace('_', ' ').toUpperCase()}
					</span>
					<span class="text-xs text-gray-500">Created {new Date(po?.created_at).toLocaleDateString()}</span>
				</div>
			</div>
		</div>

		<div class="flex items-center gap-2">
			<a 
				href="/inventory/po/{poId}/history"
				class="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-gray-700 bg-white border border-gray-300 rounded-xl hover:bg-gray-50 transition-colors"
			>
				<Clock class="h-4 w-4" /> History
			</a>
			<a 
				href="/inventory/po/{poId}/print"
				target="_blank"
				class="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-gray-700 bg-white border border-gray-300 rounded-xl hover:bg-gray-50 transition-colors"
			>
				<Printer class="h-4 w-4" /> Print
			</a>
			{#if po?.status === 'draft'}
				<button 
					onclick={confirmPO}
					disabled={actionLoading}
					class="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-indigo-600 rounded-xl hover:bg-indigo-700 transition-colors shadow-lg shadow-indigo-100"
				>
					<CheckCircle class="h-4 w-4" /> {actionLoading ? 'Confirming...' : 'Confirm & Assign PO#'}
				</button>
			{/if}
			{#if po?.status === 'pending' || po?.status === 'partially_received'}
				<button 
					onclick={openReceiveModal}
					class="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-green-600 rounded-xl hover:bg-green-700 transition-colors shadow-lg shadow-green-100"
				>
					<Package class="h-4 w-4" /> Receive Items
				</button>
			{/if}
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-xl mb-6 flex items-center gap-2" transition:fade>
			<AlertCircle class="h-5 w-5" /><p class="text-sm">{error}</p>
		</div>
	{/if}
	{#if success}
		<div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-xl mb-6 flex items-center gap-2" transition:fade>
			<CheckCircle class="h-5 w-5" /><p class="text-sm font-medium">{success}</p>
		</div>
	{/if}

	<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
		<!-- Main Content -->
		<div class="lg:col-span-2 space-y-6">
			<!-- Summary Cards -->
			<div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
				<div class="bg-white p-4 rounded-2xl border shadow-sm">
					<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Total Cost</p>
					<p class="text-lg font-bold text-gray-900">₦{po?.total_cost.toLocaleString()}</p>
				</div>
				<div class="bg-white p-4 rounded-2xl border shadow-sm">
					<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Items Count</p>
					<p class="text-lg font-bold text-gray-900">{items.length}</p>
				</div>
				<div class="bg-white p-4 rounded-2xl border shadow-sm">
					<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Received</p>
					<p class="text-lg font-bold text-green-600">{items.reduce((sum, i) => sum + (i.received_qty || 0), 0)}</p>
				</div>
				<div class="bg-white p-4 rounded-2xl border shadow-sm">
					<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Pending</p>
					<p class="text-lg font-bold text-amber-600">{items.reduce((sum, i) => sum + (i.expected_qty - (i.received_qty || 0)), 0)}</p>
				</div>
			</div>

			<!-- Items List -->
			<div class="bg-white rounded-2xl border shadow-sm overflow-hidden">
				<div class="p-4 border-b bg-gray-50">
					<h2 class="font-bold text-gray-900 text-sm uppercase tracking-wider">Purchase Items</h2>
				</div>
				<div class="overflow-x-auto">
					<table class="w-full text-sm">
						<thead class="bg-gray-50 text-gray-500 text-left">
							<tr>
								<th class="px-4 py-3 font-semibold">Product</th>
								<th class="px-4 py-3 font-semibold text-center">Expected</th>
								<th class="px-4 py-3 font-semibold text-center">Received</th>
								<th class="px-4 py-3 font-semibold text-right">Unit Cost</th>
								<th class="px-4 py-3 font-semibold text-right">Subtotal</th>
							</tr>
						</thead>
						<tbody class="divide-y divide-gray-100">
							{#each items as item}
								<tr>
									<td class="px-4 py-4">
										<p class="font-medium text-gray-900">{item.products?.name}</p>
										<p class="text-[10px] text-gray-500">BC: {item.products?.barcode || 'N/A'}</p>
									</td>
									<td class="px-4 py-4 text-center font-bold text-gray-700">{item.expected_qty}</td>
									<td class="px-4 py-4 text-center font-bold {item.received_qty >= item.expected_qty ? 'text-green-600' : 'text-amber-600'}">
										{item.received_qty || 0}
									</td>
									<td class="px-4 py-4 text-right text-gray-600">₦{item.unit_cost.toLocaleString()}</td>
									<td class="px-4 py-4 text-right font-bold text-gray-900">
										₦{(item.expected_qty * item.unit_cost).toLocaleString()}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</div>
		</div>

		<!-- Sidebar Info -->
		<div class="space-y-6">
			<!-- Supplier Info -->
			<div class="bg-white rounded-2xl border shadow-sm p-5 space-y-4">
				<h2 class="font-bold text-gray-900 text-sm uppercase tracking-wider flex items-center gap-2">
					<Truck class="h-4 w-4 text-indigo-500" /> Supplier
				</h2>
				<div>
					<p class="text-sm font-bold text-gray-900">{po?.suppliers?.name}</p>
					<p class="text-xs text-gray-500 mt-1">{po?.suppliers?.contact_person || ''}</p>
					<p class="text-xs text-gray-500">{po?.suppliers?.email || ''}</p>
					<p class="text-xs text-gray-500">{po?.suppliers?.phone || ''}</p>
				</div>
			</div>

			<!-- Delivery Info -->
			<div class="bg-white rounded-2xl border shadow-sm p-5 space-y-4">
				<h2 class="font-bold text-gray-900 text-sm uppercase tracking-wider flex items-center gap-2">
					<Clock class="h-4 w-4 text-indigo-500" /> Receiving Branch
				</h2>
				<div>
					<p class="text-sm font-bold text-gray-900">{po?.branches?.name}</p>
					<p class="text-xs text-gray-500 mt-1">{po?.branches?.address || ''}</p>
				</div>
			</div>

			<!-- Notes -->
			<div class="bg-white rounded-2xl border shadow-sm p-5">
				<h2 class="font-bold text-gray-900 text-sm uppercase tracking-wider mb-2">Notes</h2>
				<p class="text-xs text-gray-600 italic">
					{po?.notes || 'No notes provided for this order.'}
				</p>
			</div>
		</div>
	</div>

</div>
