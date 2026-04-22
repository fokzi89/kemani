<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { ArrowLeft, RotateCcw, Package, AlertTriangle, CheckCircle, Calculator, User, AlertCircle, Ban } from 'lucide-svelte';

	let saleId = $derived($page.params.id);
	
	let loading = $state(true);
	let processing = $state(false);
	
	let sale = $state<any>(null);
	let items = $state<any[]>([]);
	let staffId = $state<string>('');

	// State for tracking return quantities. Key = sale_item_id
	let returnQuantities = $state<Record<string, number>>({});

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		staffId = session.user.id;
		
		await loadSaleData();
	});

	async function loadSaleData() {
		if (!saleId) return;
		loading = true;
		try {
			// Fetch main sale
			const { data: saleData } = await supabase.from('sales')
				.select('*, users:cashier_id(full_name)')
				.eq('id', saleId)
				.single();
			
			if (!saleData) {
				goto('/returns');
				return;
			}
			sale = saleData;

			// Fetch items
			const { data: itemsData } = await supabase.from('sale_items')
				.select('*, products(name, sku)')
				.eq('sale_id', saleId);
			
			items = itemsData || [];

			// Initialize return tracking
			const rMap: Record<string, number> = {};
			items.forEach(i => rMap[i.id] = 0);
			returnQuantities = rMap;

		} catch (err) {
			console.error('Failed to load sale info:', err);
		} finally {
			loading = false;
		}
	}

	function handleSetReturnAll(itemId: string, maxQty: number) {
		returnQuantities[itemId] = maxQty;
	}

	function handleClearReturn(itemId: string) {
		returnQuantities[itemId] = 0;
	}

	// Dynamic calculation to preview how the refund affects totals
	let totalRefundPreview = $derived(
		items.reduce((acc, item) => {
			const returning = returnQuantities[item.id] || 0;
			return acc + (returning * item.unit_price); // Tax/Discount proportional impact intentionally stripped for simplicity
		}, 0)
	);

	let hasActionableReturns = $derived(Object.values(returnQuantities).some(q => q > 0));

	async function processReturns() {
		if (!hasActionableReturns || processing) return;
		
		const confirmed = confirm(`You are about to process a refund of ${formatCurrency(totalRefundPreview)}. Returned inventory will automatically restock. \n\nContinue?`);
		if (!confirmed) return;

		processing = true;
		try {
			// Build the payload for the RPC
			const returnPayload = Object.entries(returnQuantities)
				.filter(([_, qty]) => qty > 0)
				.map(([saleItemId, returnQty]) => {
					const product = items.find(i => i.id === saleItemId);
					return {
						sale_item_id: saleItemId,
						product_id: product?.product_id,
						return_qty: returnQty
					};
				});

			if (returnPayload.length === 0) throw new Error("No items selected");

			// Call custom Postgres function
			const { error } = await supabase.rpc('process_sale_return', {
				p_sale_id: saleId,
				p_items: returnPayload,
				p_staff_id: staffId
			});

			if (error) throw error;

			alert('Return successfully processed! Inventory has been adjusted.');
			goto('/returns');
			
		} catch (err: any) {
			console.error('RPC Error processing returns:', err);
			alert(`Failed to process return: ${err.message}`);
			processing = false;
		}
	}

	function formatCurrency(val: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}
</script>

<svelte:head>
	<title>Refund Order - {sale?.sale_number || 'Loading'}</title>
</svelte:head>

<div class="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8 space-y-6">
	<!-- Header -->
	<div class="flex items-center gap-4 border-b border-gray-100 pb-4">
		<a href="/returns" class="p-2 hover:bg-gray-100 rounded-lg transition-colors text-gray-500 hover:text-gray-900 border border-gray-200 bg-white">
			<ArrowLeft class="h-6 w-6" />
		</a>
		<div>
			<h1 class="text-2xl font-black text-gray-900 flex items-center gap-2">
				Modify / Return Items
			</h1>
			<p class="text-xs text-gray-500 font-bold uppercase tracking-widest mt-0.5">
				{sale?.sale_number || 'Loading...'}
			</p>
		</div>
	</div>

	{#if loading}
		<div class="flex flex-col items-center justify-center py-32 text-gray-400">
			<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mb-4"></div>
			<p class="font-medium italic">Loading receipt items...</p>
		</div>
	{:else if !sale}
		<div class="flex flex-col items-center justify-center p-20 text-gray-500 text-center">
			<AlertTriangle class="h-10 w-10 text-amber-500 mb-4" />
			<p class="text-lg font-black text-gray-900">Sale Not Found</p>
		</div>
	{:else}
		<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
			<!-- Main Items List -->
			<div class="lg:col-span-2 space-y-4">
				{#if sale.sale_status === 'refunded'}
					<div class="bg-rose-50 border border-rose-200 p-4 rounded-2xl flex items-start gap-3">
						<Ban class="h-5 w-5 text-rose-600 shrink-0 mt-0.5" />
						<div>
							<h3 class="text-sm font-black text-rose-900">Sale Fully Refunded</h3>
							<p class="text-xs font-medium text-rose-700 mt-1">This transaction has been voided/refunded completely. Inventory adjustments have already been made.</p>
						</div>
					</div>
				{/if}

				<div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
					<div class="p-4 border-b bg-gray-50/50 flex items-center gap-2">
						<Package class="h-5 w-5 text-indigo-500" />
						<span class="font-black text-gray-900">Purchased Items</span>
					</div>
					
					<div class="divide-y divide-gray-50">
						{#each items as item}
							{@const maxAmt = item.quantity}
							{@const curReturn = returnQuantities[item.id] || 0}
							
							<div class="p-4 sm:p-5 flex flex-col sm:flex-row gap-4 justify-between items-start sm:items-center {curReturn > 0 ? 'bg-indigo-50/30' : ''} {maxAmt === 0 ? 'opacity-50 grayscale pointer-events-none' : ''}">
								<div class="flex-1">
									<p class="font-bold text-gray-900 text-sm">{item.products?.name || 'Unknown Product'}</p>
									<p class="text-[10px] text-gray-400 font-bold uppercase mt-0.5">{item.products?.sku || 'NO SKU'}</p>
									<p class="text-xs font-bold text-emerald-600 mt-1">{formatCurrency(item.unit_price)} <span class="text-gray-400 font-medium">ea</span></p>
								</div>

								<div class="flex items-center gap-6">
									<!-- Status of item sale -->
									<div class="text-center">
										<p class="text-[10px] uppercase font-black text-gray-400 mb-1">Purchased</p>
										<p class="text-lg font-black text-gray-900">{maxAmt}</p>
									</div>

									<!-- Return actions -->
									{#if maxAmt > 0 && sale.sale_status !== 'refunded' && sale.sale_status !== 'voided'}
										<div class="flex items-center gap-3 bg-gray-50 p-2 rounded-xl border border-gray-200">
											<div class="flex flex-col items-center">
												<p class="text-[10px] uppercase font-black text-indigo-400 mb-1">Return</p>
												<input 
													type="number" 
													min="0" 
													max={maxAmt}
													bind:value={returnQuantities[item.id]}
													class="w-16 h-8 text-center font-black text-indigo-700 bg-white border border-indigo-200 rounded-md focus:ring-2 focus:ring-indigo-500 outline-none"
												/>
											</div>
											<div class="flex flex-col gap-1">
												<button 
													onclick={() => handleSetReturnAll(item.id, maxAmt)}
													class="text-[9px] uppercase font-black px-2 py-1 bg-white border border-gray-200 rounded hover:bg-gray-100 hover:text-indigo-600 transition-colors"
												>
													All
												</button>
												<button 
													onclick={() => handleClearReturn(item.id)}
													class="text-[9px] uppercase font-black px-2 py-1 bg-white border border-gray-200 rounded hover:bg-gray-100 hover:text-rose-600 transition-colors"
												>
													Clear
												</button>
											</div>
										</div>
									{:else if maxAmt === 0}
										<div class="px-4 py-2 bg-gray-100 text-gray-500 text-xs font-black uppercase rounded-xl">
											Returned
										</div>
									{/if}
								</div>
							</div>
						{/each}
					</div>
				</div>
			</div>

			<!-- Sidebar Receipt Totals -->
			<div class="space-y-4">
				<div class="bg-gray-900 text-white rounded-2xl p-6 shadow-xl space-y-6 sticky top-6">
					<div class="flex items-center justify-between border-b border-gray-700 pb-4">
						<h3 class="font-black flex items-center gap-2">
							<Calculator class="h-5 w-5 text-indigo-400" />
							Refund Calculation
						</h3>
					</div>

					<div class="space-y-3 font-mono text-sm border-b border-gray-700 pb-4">
						<div class="flex justify-between text-gray-400">
							<span>Original Subtotal</span>
							<span>{formatCurrency(sale.subtotal)}</span>
						</div>
						<div class="flex justify-between text-gray-400">
							<span>Applied Tax/Discounts</span>
							<span>{formatCurrency(sale.total_amount - sale.subtotal)}</span>
						</div>
						<div class="flex justify-between font-bold text-white text-base">
							<span>Original Total</span>
							<span>{formatCurrency(sale.total_amount)}</span>
						</div>
					</div>

					<div class="pt-2">
						<div class="flex justify-between items-end mb-1">
							<span class="text-xs uppercase font-black text-rose-400 tracking-widest">Total Refund</span>
						</div>
						<p class="text-4xl text-rose-500 font-black tracking-tight border-b-2 border-rose-900/50 pb-2">
							- {formatCurrency(totalRefundPreview)}
						</p>
						<div class="flex justify-between text-gray-400 font-mono text-xs pt-3">
							<span>New Required Total</span>
							<span class="font-bold text-white">{formatCurrency(Math.max(0, sale.total_amount - totalRefundPreview))}</span>
						</div>
					</div>

					<button 
						disabled={!hasActionableReturns || processing}
						onclick={processReturns}
						class="w-full py-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl font-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-lg shadow-indigo-600/30"
					>
						{#if processing}
							<div class="h-5 w-5 border-2 border-white border-b-transparent rounded-full animate-spin"></div>
							Processing...
						{:else}
							<RotateCcw class="h-5 w-5" />
							Process Refund
						{/if}
					</button>

					{#if hasActionableReturns}
						<div class="bg-gray-800/50 p-3 rounded-xl border border-rose-900/50 flex items-start gap-2">
							<AlertCircle class="h-4 w-4 text-rose-400 mt-0.5 shrink-0" />
							<p class="text-[10px] text-gray-300 font-medium leading-relaxed">
								Processing this return will irreversibly restore branch inventory and recalculate net sales analytics.
							</p>
						</div>
					{/if}
				</div>
			</div>
		</div>
	{/if}
</div>
