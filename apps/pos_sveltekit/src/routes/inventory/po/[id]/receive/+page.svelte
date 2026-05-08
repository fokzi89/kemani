<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { 
		ArrowLeft, CheckCircle, Package, AlertCircle, Calendar, Info
	} from 'lucide-svelte';
	import { fade } from 'svelte/transition';

	const poId = $page.params.id;
	let loading = $state(true);
	let actionLoading = $state(false);
	let po = $state<any>(null);
	let items = $state<any[]>([]);
	let receiveItems = $state<any[]>([]);
	let receiveNotes = $state('');
	let error = $state('');
	let success = $state('');

	let branches = $state<any[]>([]);
	let selectedBranchId = $state('');

	async function fetchPODetails() {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) return;

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
			selectedBranchId = data.branch_id; // Default to PO's branch

			// Fetch all branches for the tenant to allow override
			const { data: branchesData } = await supabase
				.from('branches')
				.select('id, name')
				.eq('tenant_id', data.tenant_id)
				.is('deleted_at', null);
			branches = branchesData || [];

			const { data: itemsData, error: itemsErr } = await supabase
				.from('purchase_order_items')
				.select(`
					*,
					products(name, barcode, product_type, unit_of_measure)
				`)
				.eq('po_id', poId);
			if (itemsErr) throw itemsErr;
			items = itemsData || [];

			receiveItems = items.map(i => {
				const current = i.received_qty || 0;
				const remaining = Math.max(0, i.expected_qty - current);
				
				return {
					product_id: i.product_id,
					product_name: i.products?.name,
					product_type: i.products?.product_type,
					expected_qty: i.expected_qty,
					current_received: current,
					received_qty: remaining,
					batch_no: '',
					expiry_date: '',
					unit_cost: i.unit_cost,
					markup: 30, // Default 30%
					unit_price: i.unit_cost * 1.3,
					unit_of_measure: i.products?.unit_of_measure || 'unit',
					is_received: false
				};
			});

		} catch (err: any) {
			error = err.message;
		} finally {
			loading = false;
		}
	}

	onMount(fetchPODetails);

	async function handleReceive() {
		error = '';
		
		if (!selectedBranchId) {
			error = 'Please select a receiving branch.';
			return;
		}

		const itemsToSubmit = receiveItems.filter(i => i.is_received);

		if (itemsToSubmit.length === 0) {
			error = 'Please select at least one item to receive by checking the "Received" checkbox.';
			return;
		}

		// Validation for unit cost and expiry date
		for (const item of itemsToSubmit) {
			if (!item.unit_cost || item.unit_cost <= 0) {
				error = `Unit cost is required for ${item.product_name}`;
				return;
			}
			if (!item.expiry_date) {
				error = `Expiry date is required for ${item.product_name}`;
				return;
			}
		}

		actionLoading = true;
		try {
			const payload = itemsToSubmit.map(i => ({
				product_id: i.product_id,
				received_qty: Number(i.received_qty),
				batch_no: i.batch_no || 'PO-' + (po?.po_number || 'TEMP'),
				expiry_date: i.expiry_date,
				unit_cost: Number(i.unit_cost),
				unit_price: Number(i.unit_price),
				unit_of_measure: i.unit_of_measure,
				is_received: true
			}));

			const { data, error: rpcErr } = await supabase.rpc('receive_purchase_order', {
				p_po_id: poId,
				p_received_items: payload,
				p_notes: receiveNotes,
				p_branch_id: selectedBranchId
			});
			
			if (rpcErr) throw rpcErr;

			success = 'Inventory updated successfully!';
			setTimeout(() => {
				goto(`/inventory/po/${poId}`);
			}, 1500);
		} catch (err: any) {
			console.error('Receive error:', err);
			if (err.message === 'Failed to fetch') {
				error = 'Network error or server timeout. Please check your internet and try again.';
			} else {
				error = err.message || 'An unexpected error occurred during receipt.';
			}
		} finally {
			actionLoading = false;
		}
	}
</script>

<svelte:head><title>Receive Items – {po?.po_number || 'PO'}</title></svelte:head>

<div class="min-h-screen bg-gray-50/50 p-6">
	<div class="max-w-[1200px] mx-auto">
		<div class="flex items-center justify-between mb-8">
			<div class="flex items-center gap-4">
				<button 
					onclick={() => goto(`/inventory/po/${poId}`)}
					class="p-2.5 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-all shadow-sm"
				>
					<ArrowLeft class="h-5 w-5 text-gray-600" />
				</button>
				<div>
					<h1 class="text-2xl font-bold text-gray-900 tracking-tight">Receive Stock Items</h1>
					<p class="text-sm text-gray-500 font-medium">Log incoming inventory for {po?.po_number || 'Order'}</p>
				</div>
			</div>
			
			<div class="flex items-center gap-4">
				<div class="hidden sm:block">
					<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 px-1 text-right">Receiving Branch</p>
					<div class="relative min-w-[200px]">
						<select 
							bind:value={selectedBranchId}
							class="w-full pl-4 pr-10 py-2.5 bg-white border border-gray-200 rounded-xl appearance-none focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 transition-all outline-none font-bold text-sm text-gray-700 cursor-pointer shadow-sm"
						>
							<option value="" disabled>Select Branch</option>
							{#each branches as branch}
								<option value={branch.id}>{branch.name}</option>
							{/each}
						</select>
						<div class="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400">
							<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
						</div>
					</div>
				</div>
				<div class="hidden md:flex items-center gap-3 px-4 py-2 bg-indigo-50 border border-indigo-100 rounded-2xl text-indigo-700 h-[46px] self-end mb-0.5">
					<Info class="h-4 w-4" />
					<span class="text-xs font-bold uppercase tracking-wider whitespace-nowrap">Set Markup & UoM</span>
				</div>
			</div>
		</div>

		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-800 px-5 py-4 rounded-2xl mb-8 flex items-center gap-3 shadow-sm" transition:fade>
				<AlertCircle class="h-5 w-5 shrink-0" />
				<p class="text-sm font-semibold">{error}</p>
			</div>
		{/if}

		{#if success}
			<div class="bg-green-50 border border-green-200 text-green-800 px-5 py-4 rounded-2xl mb-8 flex items-center gap-3 shadow-sm" transition:fade>
				<CheckCircle class="h-5 w-5 shrink-0" />
				<p class="text-sm font-bold">{success}</p>
			</div>
		{/if}

		<div class="bg-white rounded-3xl border border-gray-200 shadow-xl shadow-gray-200/50 overflow-hidden mb-8">
			<div class="overflow-x-auto">
				<table class="w-full text-sm border-separate border-spacing-0">
					<thead>
						<tr class="bg-gray-50/80">
							<th class="px-4 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b text-center w-12">Rcvd</th>
							<th class="px-4 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b text-left min-w-[200px]">Product</th>
							<th class="px-2 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b w-24">Qty</th>
							<th class="px-2 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b w-28">Batch #</th>
							<th class="px-2 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b w-28">UoM</th>
							<th class="px-2 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b w-32">Expiry</th>
							<th class="px-2 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b w-28">Cost (₦)</th>
							<th class="px-2 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b w-20">Markup%</th>
							<th class="px-2 py-4 font-bold uppercase text-[10px] tracking-widest text-gray-400 border-b w-28 text-right">Selling (₦)</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each receiveItems as item}
							<tr class="hover:bg-gray-50/50 transition-colors {item.is_received ? 'bg-indigo-50/10' : ''}">
								<td class="px-4 py-5 text-center">
									<input 
										type="checkbox" 
										bind:checked={item.is_received}
										class="w-5 h-5 rounded-lg border-gray-300 text-indigo-600 focus:ring-indigo-500 cursor-pointer"
									/>
								</td>
								<td class="px-4 py-5">
									<p class="font-black text-gray-900 uppercase text-[11px] leading-tight mb-1">{item.product_name}</p>
									<span class="inline-flex items-center px-2 py-0.5 rounded-full bg-gray-100 text-[9px] font-bold text-gray-500">
										Bal: {item.expected_qty - item.current_received}
									</span>
								</td>
								<td class="px-2 py-5">
									<input 
										type="number" 
										bind:value={item.received_qty} 
										disabled={!item.is_received}
										class="w-full px-2 py-2 bg-white border border-gray-200 rounded-lg text-xs font-bold focus:ring-2 focus:ring-indigo-500 outline-none transition-all" 
									/>
								</td>
								<td class="px-2 py-5">
									<input 
										type="text" 
										bind:value={item.batch_no} 
										disabled={!item.is_received}
										placeholder="Optional"
										class="w-full px-2 py-2 bg-white border border-gray-200 rounded-lg text-xs font-bold focus:ring-2 focus:ring-indigo-500 outline-none transition-all" 
									/>
								</td>
								<td class="px-2 py-5">
									<select 
										bind:value={item.unit_of_measure}
										disabled={!item.is_received}
										class="w-full px-2 py-2 bg-white border border-gray-200 rounded-lg text-xs font-bold focus:ring-2 focus:ring-indigo-500 outline-none transition-all appearance-none"
									>
										<option value="unit">Unit</option>
										<option value="pack">Pack</option>
										<option value="sachet">Sachet</option>
									</select>
								</td>
								<td class="px-2 py-5">
									<input 
										type="date" 
										bind:value={item.expiry_date} 
										disabled={!item.is_received}
										class="w-full px-2 py-2 bg-white border border-gray-200 rounded-lg text-[10px] font-bold focus:ring-2 focus:ring-indigo-500 outline-none transition-all" 
									/>
								</td>
								<td class="px-2 py-5">
									<input 
										type="number" 
										bind:value={item.unit_cost} 
										disabled={!item.is_received}
										oninput={() => {
											item.unit_price = item.unit_cost * (1 + (item.markup / 100));
										}}
										class="w-full px-2 py-2 bg-white border border-gray-200 rounded-lg text-xs font-bold text-right focus:ring-2 focus:ring-indigo-500 outline-none transition-all" 
									/>
								</td>
								<td class="px-2 py-5">
									<input 
										type="number" 
										bind:value={item.markup} 
										disabled={!item.is_received}
										oninput={() => {
											item.unit_price = item.unit_cost * (1 + (item.markup / 100));
										}}
										class="w-full px-2 py-2 bg-white border border-gray-200 rounded-lg text-xs font-bold text-center focus:ring-2 focus:ring-indigo-500 outline-none transition-all" 
									/>
								</td>
								<td class="px-2 py-5">
									<input 
										type="number" 
										bind:value={item.unit_price} 
										disabled={!item.is_received}
										oninput={() => {
											// Recalculate markup if user manually overrides price
											if (item.unit_cost > 0) {
												item.markup = ((item.unit_price / item.unit_cost) - 1) * 100;
											}
										}}
										class="w-full px-2 py-2 bg-indigo-50 border border-indigo-100 rounded-lg text-xs font-bold text-right text-indigo-700 focus:ring-2 focus:ring-indigo-500 outline-none transition-all" 
									/>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</div>

		<div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-12">
			<div class="lg:col-span-2">
				<label class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-3 px-1">Receiving Notes / Remarks</label>
				<textarea 
					bind:value={receiveNotes}
					placeholder="Add any internal notes about this supply (e.g., damaged items, carrier details)..."
					class="w-full px-5 py-4 bg-white border border-gray-200 rounded-3xl text-sm outline-none focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 transition-all h-32 resize-none shadow-sm"
				></textarea>
			</div>
			
			<div class="bg-indigo-900 rounded-3xl p-6 text-white shadow-xl shadow-indigo-200">
				<h3 class="text-xs font-bold uppercase tracking-widest text-indigo-300 mb-6 flex items-center gap-2">
					<Package class="h-4 w-4" /> Summary
				</h3>
				
				<div class="space-y-4 mb-8">
					<div class="flex justify-between items-center">
						<span class="text-xs text-indigo-200">Selected Items</span>
						<span class="text-lg font-bold">{receiveItems.filter(i => i.is_received).length}</span>
					</div>
					<div class="flex justify-between items-center">
						<span class="text-xs text-indigo-200">Total Value</span>
						<span class="text-xl font-black tabular-nums">₦{receiveItems.filter(i => i.is_received).reduce((sum, i) => sum + (i.received_qty * i.unit_cost), 0).toLocaleString()}</span>
					</div>
				</div>
				
				<button 
					onclick={handleReceive} 
					disabled={actionLoading || receiveItems.filter(i => i.is_received).length === 0}
					class="w-full bg-white text-indigo-900 hover:bg-indigo-50 font-black px-6 py-4 rounded-2xl shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed uppercase tracking-widest text-xs flex items-center justify-center gap-2"
				>
					{actionLoading ? 'Processing...' : 'Confirm Receipt'}
				</button>
			</div>
		</div>
	</div>
</div>

<style>
	input[type="date"]::-webkit-calendar-picker-indicator {
		filter: invert(0.5);
		cursor: pointer;
	}
</style>
