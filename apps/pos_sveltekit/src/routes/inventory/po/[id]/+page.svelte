<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { 
		ArrowLeft, FileText, CheckCircle, Package, Truck, 
		Printer, AlertCircle, Clock, Trash2, Send
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
	let showHistoryModal = $state(false);

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

	let receiveItems = $state<any[]>([]);
	let showReceiveModal = $state(false);

	function openReceiveModal() {
		receiveItems = items.map(i => ({
			product_id: i.product_id,
			product_name: i.products?.name,
			expected_qty: i.expected_qty,
			current_received: i.received_qty || 0,
			received_qty: i.expected_qty - (i.received_qty || 0),
			batch_no: '',
			expiry_date: '',
			unit_cost: i.unit_cost,
			unit_price: (i.unit_cost * 1.5) // Maintain unit_price in background for now
		}));
		showReceiveModal = true;
	}

	async function handleReceive() {
		actionLoading = true;
		try {
			const itemsToSubmit = receiveItems
				.filter(i => i.received_qty > 0)
				.map(i => ({
					product_id: i.product_id,
					received_qty: i.received_qty,
					batch_no: i.batch_no || 'PO-' + po.po_number,
					expiry_date: i.expiry_date || null,
					unit_cost: i.unit_cost,
					unit_price: i.unit_price
				}));

			if (itemsToSubmit.length === 0) throw new Error('No items to receive');

			const { data, error: rpcErr } = await supabase.rpc('receive_purchase_order', {
				p_po_id: poId,
				p_received_items: itemsToSubmit
			});
			if (rpcErr) throw rpcErr;

			success = 'Inventory updated and preorders fulfilled!';
			showReceiveModal = false;
			await fetchPODetails();
		} catch (err: any) {
			error = err.message;
		} finally {
			actionLoading = false;
		}
	}

	const statusColors: Record<string, string> = {
		draft: 'bg-gray-100 text-gray-700',
		pending: 'bg-amber-100 text-amber-700',
		partially_received: 'bg-blue-100 text-blue-700',
		completed: 'bg-green-100 text-green-700',
		cancelled: 'bg-red-100 text-red-700'
	};
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
			<button 
				onclick={() => showHistoryModal = true}
				class="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-gray-700 bg-white border border-gray-300 rounded-xl hover:bg-gray-50 transition-colors"
			>
				<Clock class="h-4 w-4" /> History
			</button>
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

	<!-- Receive Modal -->
	{#if showReceiveModal}
		<div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto">
			<div class="bg-white rounded-2xl max-w-4xl w-full p-6 shadow-2xl transition-all">
				<div class="flex items-center justify-between mb-6">
					<div>
						<h3 class="text-lg font-bold text-gray-900">Receive Stock Items</h3>
						<p class="text-xs text-gray-500">Log incoming inventory and fulfill preorders</p>
					</div>
					<button onclick={() => showReceiveModal = false} class="p-2 hover:bg-gray-100 rounded-lg text-gray-400">
						<ArrowLeft class="h-5 w-5 rotate-180" />
					</button>
				</div>

				<div class="overflow-x-auto mb-6">
					<table class="w-full text-sm border-separate border-spacing-0">
						<thead class="bg-gray-50 text-gray-500 text-left">
							<tr>
								<th class="px-3 py-3 font-bold uppercase text-[10px] tracking-widest border-b">Product</th>
								<th class="px-3 py-3 font-bold uppercase text-[10px] tracking-widest border-b w-32">Qty Received</th>
								<th class="px-3 py-3 font-bold uppercase text-[10px] tracking-widest border-b w-36">Batch #</th>
								<th class="px-3 py-3 font-bold uppercase text-[10px] tracking-widest border-b w-40">Expiry Date</th>
								<th class="px-3 py-3 font-bold uppercase text-[10px] tracking-widest border-b w-32 text-right">Unit Cost</th>
								<th class="px-3 py-3 font-bold uppercase text-[10px] tracking-widest border-b w-32 text-right">Subtotal</th>
							</tr>
						</thead>
						<tbody class="divide-y divide-gray-100">
							{#each receiveItems as item}
								<tr class="hover:bg-gray-50/50 transition-colors">
									<td class="px-3 py-4 font-black text-gray-900 uppercase text-[11px] leading-tight">
										{item.product_name}
										<span class="block text-[9px] text-gray-400 font-normal normal-case">Bal: {item.expected_qty - item.current_received} remaining</span>
									</td>
									<td class="px-3 py-4">
										<div class="relative">
											<input 
												type="number" 
												bind:value={item.received_qty} 
												min="0" 
												max={item.expected_qty - item.current_received}
												class="w-full px-3 py-2 bg-white border border-gray-200 rounded-xl text-sm font-bold focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all shadow-sm" 
											/>
										</div>
									</td>
									<td class="px-3 py-4">
										<input type="text" bind:value={item.batch_no} placeholder="B-2024..." class="w-full px-3 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all" />
									</td>
									<td class="px-3 py-4">
										<input type="date" bind:value={item.expiry_date} class="w-full px-3 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all" />
									</td>
									<td class="px-3 py-4">
										<div class="relative">
											<span class="absolute left-2 top-1/2 -translate-y-1/2 text-gray-400 font-bold text-xs">₦</span>
											<input type="number" bind:value={item.unit_cost} step="0.01" class="w-full pl-6 pr-3 py-2 bg-white border border-gray-200 rounded-xl text-sm font-bold text-right focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all" />
										</div>
									</td>
									<td class="px-3 py-4 text-right text-xs font-black text-gray-900 tabular-nums">
										₦{(item.received_qty * item.unit_cost).toLocaleString()}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>

				<div class="flex gap-3 pt-4 border-t">
					<button onclick={() => showReceiveModal = false} class="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
						Cancel
					</button>
					<button 
						onclick={handleReceive} 
						disabled={actionLoading}
						class="flex-1 bg-green-600 hover:bg-green-700 text-white font-bold px-4 py-2.5 rounded-xl shadow-lg shadow-green-100 transition-colors disabled:opacity-50 text-sm"
					>
						{actionLoading ? 'Processing...' : 'Confirm Receipt & Update Inventory'}
					</button>
				</div>
			</div>
		</div>
	{/if}

	<!-- History Modal -->
	{#if showHistoryModal}
		<div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto">
			<div class="bg-white rounded-2xl max-w-4xl w-full p-6 shadow-2xl transition-all" transition:fade>
				<div class="flex items-center justify-between mb-6">
					<div>
						<h3 class="text-lg font-bold text-gray-900">Receiving History</h3>
						<p class="text-xs text-gray-500">Structured log of all stock entries for this order</p>
					</div>
					<button onclick={() => showHistoryModal = false} class="p-2 hover:bg-gray-100 rounded-lg text-gray-400">
						<X class="h-5 w-5" />
					</button>
				</div>

				{#if receipts.length === 0}
					<div class="text-center py-12">
						<Package class="h-12 w-12 text-gray-200 mx-auto mb-3" />
						<p class="text-gray-500 font-medium">No receiving entries found yet.</p>
					</div>
				{:else}
					<div class="space-y-6 max-h-[60vh] overflow-y-auto pr-2">
						{#each receipts as receipt}
							<div class="border rounded-2xl overflow-hidden bg-gray-50/30">
								<div class="bg-gray-50 px-4 py-3 flex items-center justify-between border-b">
									<div>
										<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Received At</p>
										<p class="text-sm font-bold text-gray-900">{new Date(receipt.received_at).toLocaleString()}</p>
									</div>
									<div class="text-right">
										<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Staff</p>
										<p class="text-sm font-bold text-indigo-600">{receipt.staff?.full_name || 'System'}</p>
									</div>
								</div>
								<div class="p-4">
									<table class="w-full text-xs text-left border-separate border-spacing-0">
										<thead class="text-gray-400 font-black uppercase tracking-widest text-[9px]">
											<tr>
												<th class="pb-2">Product</th>
												<th class="pb-2 text-center">Qty</th>
												<th class="pb-2 text-right">Unit Cost</th>
												<th class="pb-2 text-right">Subtotal</th>
											</tr>
										</thead>
										<tbody class="divide-y divide-gray-100">
											{#each receipt.items as item}
												<tr>
													<td class="py-2 font-bold text-gray-800">{item.products?.name}</td>
													<td class="py-2 text-center font-black text-green-600">+{item.quantity}</td>
													<td class="py-2 text-right text-gray-600 font-mono">₦{item.unit_cost.toLocaleString()}</td>
													<td class="py-2 text-right font-black text-gray-900">₦{(item.quantity * item.unit_cost).toLocaleString()}</td>
												</tr>
											{/each}
										</tbody>
										{#if receipt.notes}
											<tfoot>
												<tr>
													<td colspan="4" class="pt-3 text-[10px] text-gray-400 italic border-t mt-2">
														<span class="font-black uppercase tracking-widest not-italic mr-2 text-[8px]">Notes:</span>
														{receipt.notes}
													</td>
												</tr>
											</tfoot>
										{/if}
									</table>
								</div>
							</div>
						{/each}
					</div>
				{/if}

				<div class="mt-6 pt-6 border-t">
					<button onclick={() => showHistoryModal = false} class="w-full py-3 bg-gray-900 text-white font-black rounded-xl uppercase tracking-widest text-xs hover:bg-gray-800 transition-colors">
						Close History
					</button>
				</div>
			</div>
		</div>
	{/if}
</div>
