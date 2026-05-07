<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { Printer, Receipt, FileText } from 'lucide-svelte';

	const poId = $page.params.id;
	let po = $state<any>(null);
	let items = $state<any[]>([]);
	let loading = $state(true);
	let tenantName = $state('');

	onMount(async () => {
		try {
			// Check session first
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) {
				console.error('No active session');
				loading = false;
				return;
			}

			const { data, error } = await supabase
				.from('purchase_orders')
				.select(`
					*,
					branches(name, address, phone),
					suppliers(*),
					creator:users(full_name)
				`)
				.eq('id', poId)
				.single();
			
			if (error) {
				console.error('Fetch error:', error);
				throw error;
			}
			po = data;

			const { data: itemsData, error: itemsError } = await supabase
				.from('purchase_order_items')
				.select(`
					*,
					products(name, barcode, unit_of_measure)
				`)
				.eq('po_id', poId);
			
			if (itemsError) throw itemsError;
			items = itemsData || [];

			// Fetch tenant name
			const { data: tData } = await supabase.from('tenants').select('name').eq('id', po.tenant_id).single();
			if (tData) tenantName = tData.name;

			// Auto trigger print after data loads
			setTimeout(() => {
				window.print();
			}, 1000);
		} catch (err) {
			console.error('Print error:', err);
		} finally {
			loading = false;
		}
	});
</script>

<svelte:head>
	<title>PO_{po?.po_number || 'DRAFT'}</title>
</svelte:head>

{#if loading}
	<div class="flex flex-col items-center justify-center min-h-screen no-print bg-gray-50">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mb-4"></div>
		<p class="text-sm font-bold text-gray-500 uppercase tracking-widest">Generating Document...</p>
	</div>
{:else if !po}
	<div class="flex flex-col items-center justify-center min-h-screen no-print bg-white p-8 text-center">
		<div class="p-4 bg-red-50 text-red-600 rounded-2xl mb-6">
			<FileText class="h-12 w-12 mx-auto mb-2 opacity-50" />
			<p class="font-black uppercase tracking-tighter text-xl">Document Error</p>
		</div>
		<p class="text-gray-500 max-w-xs mb-8">We couldn't retrieve the Purchase Order data. Please ensure you are logged in and have permission to view this document.</p>
		<button onclick={() => window.location.reload()} class="px-6 py-3 bg-gray-900 text-white font-black rounded-xl uppercase tracking-widest text-xs">
			Try Again
		</button>
	</div>
{:else if po}
	<div class="min-h-screen bg-gray-100 flex flex-col items-center p-0 sm:p-8">
		<!-- Toolbar (Hidden on Print) -->
		<div class="w-full max-w-[210mm] bg-white p-4 mb-4 rounded-2xl shadow-sm flex items-center justify-between print:hidden">
			<div class="flex items-center gap-2 text-indigo-600">
				<FileText class="h-5 w-5" />
				<span class="font-bold uppercase tracking-wider text-xs">A4 Purchase Order</span>
			</div>
			<button onclick={() => window.print()} class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-xs font-black rounded-xl hover:bg-indigo-700 transition-all active:scale-95 shadow-lg shadow-indigo-100">
				<Printer class="h-4 w-4" /> PRINT PDF
			</button>
		</div>

		<!-- A4 Document -->
		<div id="printable-receipt" class="bg-white shadow-2xl receipt-a4">
			<!-- Header -->
			<div class="text-center space-y-2 mb-10">
				<h2 class="text-3xl font-black text-gray-900 uppercase tracking-tighter">{tenantName || 'KEMANI POS'}</h2>
				<div class="inline-block px-4 py-1 bg-gray-900 text-white text-[10px] font-black uppercase tracking-[0.3em] rounded">Purchase Order</div>
				<div class="pt-4 border-t border-dashed border-gray-200 mt-4">
					<p class="text-sm text-gray-900 font-mono font-black">{po.po_number || 'DRAFT-' + po.id.slice(0,8)}</p>
					<p class="text-[10px] text-gray-400 font-bold uppercase tracking-widest">Issue Date: {new Date(po.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'long', year: 'numeric' })}</p>
				</div>
			</div>

			<!-- Addresses Grid -->
			<div class="grid grid-cols-2 gap-12 mb-10 pb-8 border-b-2 border-dashed border-gray-200">
				<div class="space-y-2">
					<h3 class="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em] mb-3">From (Vendor)</h3>
					<p class="text-sm font-black text-gray-900 uppercase">{po.suppliers?.name}</p>
					<div class="space-y-0.5">
						<p class="text-xs text-gray-600 leading-tight">{po.suppliers?.address || 'No address provided'}</p>
						<p class="text-xs text-gray-600 font-bold">{po.suppliers?.phone || ''}</p>
						<p class="text-xs text-gray-600">{po.suppliers?.email || ''}</p>
					</div>
				</div>
				<div class="space-y-2 text-right">
					<h3 class="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em] mb-3">Ship To (Branch)</h3>
					<p class="text-sm font-black text-gray-900 uppercase">{po.branches?.name}</p>
					<div class="space-y-0.5">
						<p class="text-xs text-gray-600 leading-tight">{po.branches?.address || ''}</p>
						<p class="text-xs text-gray-600 font-bold">{po.branches?.phone || ''}</p>
						<p class="text-xs text-gray-600">{po.branches?.email || ''}</p>
					</div>
				</div>
			</div>

			<!-- Items Table -->
			<div class="space-y-6 mb-12">
				<div class="border-b-2 border-gray-900 pb-3 flex justify-between text-[10px] font-black text-gray-900 uppercase tracking-[0.2em]">
					<span class="flex-1">Item Description & Specification</span>
					<span class="w-24 text-center">Qty</span>
					<span class="w-32 text-right">Unit Price</span>
					<span class="w-32 text-right">Amount</span>
				</div>
				<div class="space-y-6">
					{#each items as item}
						<div class="flex justify-between items-start gap-4">
							<div class="flex-1 min-w-0">
								<p class="text-sm font-black text-gray-900 leading-tight uppercase">{item.products?.name}</p>
								<p class="text-[10px] text-gray-400 mt-1 uppercase font-bold tracking-widest">
									Barcode: {item.products?.barcode || 'N/A'}
								</p>
							</div>
							<div class="w-24 text-center text-sm font-black text-gray-800 tabular-nums">
								{item.expected_qty} <span class="text-[9px] text-gray-400 font-bold">{item.products?.unit_of_measure}</span>
							</div>
							<div class="w-32 text-right text-sm font-bold text-gray-700 tabular-nums">
								₦{item.unit_cost.toLocaleString()}
							</div>
							<div class="w-32 text-right text-sm font-black text-gray-900 tabular-nums">
								₦{(item.expected_qty * item.unit_cost).toLocaleString()}
							</div>
						</div>
					{/each}
				</div>

				<div class="border-t-4 border-gray-900 pt-6 mt-12">
					<div class="flex justify-between items-center bg-gray-50 p-4 rounded-lg">
						<span class="text-xs font-black text-gray-900 uppercase tracking-[0.3em]">Total Purchase Value</span>
						<span class="text-2xl font-black text-indigo-600 tabular-nums font-mono">₦{po.total_cost.toLocaleString()}</span>
					</div>
				</div>
			</div>

			<!-- Footer Notes -->
			{#if po.notes}
				<div class="mb-12 p-5 bg-white border-2 border-dashed border-gray-100 rounded-xl">
					<h4 class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Special Instructions</h4>
					<p class="text-xs text-gray-600 italic leading-relaxed">{po.notes}</p>
				</div>
			{/if}

			<!-- Execution Section -->
			<div class="mt-24">
				<div class="grid grid-cols-2 gap-20">
					<div class="text-center">
						<div class="border-b-2 border-gray-900 mb-2 h-12"></div>
						<p class="text-[10px] font-black text-gray-900 uppercase tracking-widest">Authorized Signature</p>
						<p class="text-[9px] text-gray-400 font-bold mt-1">{po.creator?.full_name || 'Store Manager'}</p>
					</div>
					<div class="text-center">
						<div class="border-b-2 border-gray-900 mb-2 h-12"></div>
						<p class="text-[10px] font-black text-gray-900 uppercase tracking-widest">Supplier Acceptance (Stamp/Sign)</p>
						<p class="text-[9px] text-gray-400 font-bold mt-1">Date: ____ / ____ / 20____</p>
					</div>
				</div>
				
				<div class="mt-20 pt-8 border-t border-gray-100 text-center">
					<p class="text-[9px] font-black text-gray-300 uppercase tracking-[0.5em] mb-2">Official Procurement Document</p>
					<div class="flex items-center justify-center gap-4 text-[8px] text-gray-400 font-bold uppercase tracking-widest">
						<span>Generated: {new Date().toLocaleString()}</span>
						<span>·</span>
						<span>System: Kemani POS</span>
						<span>·</span>
						<span>www.kemani.com</span>
					</div>
				</div>
			</div>
		</div>
	</div>
{/if}

<style>
	/* ── Strictly A4 Layout ─────────────────────────────────────────────────── */
	:global(body) {
		background-color: #f3f4f6 !important;
		margin: 0;
		padding: 0;
	}

	.receipt-a4 { 
		width: 210mm; 
		min-height: 297mm;
		padding: 20mm; 
		margin: 0 auto;
		box-sizing: border-box;
		background-color: white;
	}

	/* ── Print Styles ───────────────────────────────────────────────────────── */
	@media print {
		@page { 
			size: A4;
			margin: 0; 
		}
		
		:global(body) {
			background: white !important;
			padding: 0 !important;
			margin: 0 !important;
		}

		.min-h-screen {
			background: white !important;
			padding: 0 !important;
			display: block !important;
		}

		/* Hide toolbar and other UI */
		.print\:hidden, .shadow-xl, .shadow-sm {
			display: none !important;
		}

		#printable-receipt {
			box-shadow: none !important;
			border: none !important;
			width: 100% !important;
			padding: 15mm !important;
			margin: 0 !important;
			display: block !important;
			overflow: visible !important;
			background-color: white !important;
		}

		/* Fix for Chrome background graphics */
		* {
			-webkit-print-color-adjust: exact !important;
			print-color-adjust: exact !important;
		}
	}
</style>
