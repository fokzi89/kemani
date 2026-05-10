<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ArrowLeft, Package, Clock, User, Calendar, CheckCircle
	} from 'lucide-svelte';
	import { fade } from 'svelte/transition';

	const poId = $page.params.id;
	let loading = $state(true);
	let po = $state<any>(null);
	let receipts = $state<any[]>([]);
	let error = $state('');

	async function fetchHistory() {
		try {
			const { data: poData, error: poErr } = await supabase
				.from('purchase_orders')
				.select('po_number')
				.eq('id', poId)
				.single();
			if (poErr) throw poErr;
			po = poData;

			const { data: receiptData, error: receiptErr } = await supabase
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
			if (receiptErr) throw receiptErr;
			receipts = receiptData || [];

		} catch (err: any) {
			error = err.message;
		} finally {
			loading = false;
		}
	}

	onMount(fetchHistory);

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

<svelte:head><title>Receiving History – {po?.po_number || 'PO'}</title></svelte:head>

<div class="min-h-screen bg-gray-50/50 p-6">
	<div class="max-w-4xl mx-auto">
		<div class="flex items-center gap-4 mb-8">
			<button 
				onclick={() => goto(`/inventory/po/${poId}`)}
				class="p-2.5 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-all shadow-sm"
			>
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</button>
			<div>
				<h1 class="text-2xl font-bold text-gray-900 tracking-tight">Receiving History</h1>
				<p class="text-sm text-gray-500 font-medium">Log of all stock entries for {po?.po_number || 'Order'}</p>
			</div>
		</div>

		{#if loading}
			<div class="flex flex-col items-center justify-center py-20">
				<div class="w-10 h-10 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mb-4"></div>
				<p class="text-gray-500 font-medium italic">Fetching history logs...</p>
			</div>
		{:else if receipts.length === 0}
			<div class="bg-white rounded-3xl border border-dashed border-gray-300 p-20 text-center shadow-sm">
				<div class="bg-gray-50 w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4">
					<Package class="h-8 w-8 text-gray-300" />
				</div>
				<h3 class="text-lg font-bold text-gray-900 mb-1">No receipts found</h3>
				<p class="text-gray-500 text-sm max-w-xs mx-auto">This order hasn't had any stock items received yet.</p>
			</div>
		{:else}
			<div class="space-y-8">
				{#each receipts as receipt}
					<div class="bg-white rounded-3xl border border-gray-200 shadow-xl shadow-gray-200/40 overflow-hidden" in:fade>
						<div class="px-6 py-5 bg-gray-50/50 border-b flex flex-col sm:flex-row sm:items-center justify-between gap-4">
							<div class="flex items-center gap-4">
								<div class="bg-indigo-600 p-2 rounded-xl text-white">
									<Calendar class="h-5 w-5" />
								</div>
								<div>
									<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Received At</p>
									<p class="text-sm font-bold text-gray-900">{new Date(receipt.received_at).toLocaleString()}</p>
								</div>
							</div>
							<div class="flex items-center gap-4 sm:text-right">
								<div class="sm:order-first">
									<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Received By</p>
									<p class="text-sm font-bold text-indigo-600">{receipt.staff?.full_name || 'System'}</p>
								</div>
								<div class="bg-white p-2 rounded-xl border shadow-sm text-indigo-600">
									<User class="h-5 w-5" />
								</div>
							</div>
						</div>

						<div class="p-6">
							<div class="overflow-x-auto">
								<table class="w-full text-[11px] text-left border-separate border-spacing-0">
									<thead>
										<tr class="text-gray-400 font-black uppercase tracking-widest text-[8px]">
											<th class="pb-4 border-b">Product</th>
											<th class="pb-4 border-b text-center">Qty</th>
											<th class="pb-4 border-b text-right">Unit Cost</th>
											<th class="pb-4 border-b text-right">Expiry</th>
											<th class="pb-4 border-b text-right">Subtotal</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-50">
										{#each receipt.items as item}
											{@const expiry = getExpiryStatus(item.expiry_date)}
											<tr class="group">
												<td class="py-4 font-bold text-gray-800">
													<div class="flex flex-col">
														<span class="uppercase tracking-tight text-[11px]">{item.products?.name}</span>
														<span class="text-[8px] text-gray-400 font-medium mt-0.5">Batch: {item.batch_no || 'N/A'}</span>
													</div>
												</td>
												<td class="py-4 text-center">
													<span class="inline-flex items-center px-2 py-1 rounded-lg bg-green-50 text-green-700 font-black text-[11px]">
														+{item.quantity}
													</span>
												</td>
												<td class="py-4 text-right text-gray-600 font-mono font-medium">₦{item.unit_cost.toLocaleString()}</td>
												<td class="py-4 text-right">
													<div class="flex flex-col items-end">
														<span class="text-[9px] font-bold {expiry.color}">{item.expiry_date ? new Date(item.expiry_date).toLocaleDateString() : 'N/A'}</span>
														<span class="text-[7px] font-black uppercase tracking-tighter opacity-80 {expiry.color}">{expiry.label}</span>
													</div>
												</td>
												<td class="py-4 text-right font-black text-gray-900 tabular-nums text-[11px]">₦{(item.quantity * item.unit_cost).toLocaleString()}</td>
											</tr>
										{/each}
									</tbody>
									{#if receipt.notes}
										<tfoot>
											<tr>
												<td colspan="5" class="pt-5 mt-4">
													<div class="bg-amber-50/50 border border-amber-100 rounded-2xl p-4 flex items-start gap-3">
														<div class="bg-amber-100 p-1.5 rounded-lg text-amber-600">
															<Clock class="h-3 w-3" />
														</div>
														<div>
															<p class="text-[8px] font-black text-amber-500 uppercase tracking-widest mb-1">Reception Notes</p>
															<p class="text-[10px] text-amber-800 italic leading-relaxed">{receipt.notes}</p>
														</div>
													</div>
												</td>
											</tr>
										</tfoot>
									{/if}
								</table>
							</div>
						</div>
						
						<div class="px-6 py-4 bg-gray-50/30 border-t flex items-center justify-between">
							<span class="text-[9px] font-bold text-gray-400 uppercase tracking-widest">Total Receipt Value</span>
							<span class="text-xs font-black text-gray-900 tabular-nums">₦{receipt.items.reduce((sum, i) => sum + (i.quantity * i.unit_cost), 0).toLocaleString()}</span>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
