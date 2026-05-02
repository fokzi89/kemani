<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { ArrowLeft, Receipt, CheckCircle, XCircle, Clock, Printer } from 'lucide-svelte';

	// Svelte 5: Use reactive state from stores
	let orderId = $derived($page.params.id);
	let order = $state<any>(null);
	let items = $state<any[]>([]);
	let loading = $state(true);

	onMount(async () => {
		if (!orderId) return;
		try {
			const { data, error } = await supabase.from('sales').select('*').eq('id', orderId).single();
			if (error) throw error;
			order = data;
			if (data) {
				const { data: lineItems } = await supabase.from('sale_items').select('*').eq('sale_id', orderId);
				items = lineItems || [];
			}
		} catch (e) {
			console.error('Order fetch error:', e);
		} finally {
			loading = false;
		}
	});

	function statusIcon(status: string) { return status === 'completed' ? CheckCircle : status === 'cancelled' ? XCircle : Clock; }
	function statusColor(status: string) {
		switch(status) {
			case 'completed': return 'text-green-600 bg-green-50'; case 'cancelled': return 'text-red-600 bg-red-50'; default: return 'text-yellow-600 bg-yellow-50';
		}
	}
</script>

<svelte:head><title>Order #{orderId?.slice(-6).toUpperCase()} – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center justify-between mb-6 print:hidden">
		<div class="flex items-center gap-3">
			<a href="/orders" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
			<div>
				<h1 class="text-xl font-bold text-gray-900">Order #{orderId?.slice(-8).toUpperCase()}</h1>
				{#if order}<p class="text-sm text-gray-500">{new Date(order.created_at).toLocaleString()}</p>{/if}
			</div>
		</div>
		<button onclick={() => window.print()} class="inline-flex items-center gap-2 px-3 py-2 border border-gray-300 text-gray-600 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm print:hidden">
			<Printer class="h-4 w-4" /> Print
		</button>
	</div>

	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else if order}
		{@const StatusIcon = statusIcon(order.sale_status)}
		<div class="space-y-4">
			<!-- Status + Info -->
			<div class="bg-white rounded-xl border p-5">
				<div class="flex items-center justify-between mb-4">
					<span class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-semibold capitalize {statusColor(order.sale_status)}">
						<StatusIcon class="h-4 w-4" /> {order.sale_status}
					</span>
					<span class="text-sm text-gray-500 capitalize">{order.payment_method}</span>
				</div>
				<div class="grid grid-cols-2 gap-3 text-sm">
					<div><span class="text-gray-500">Customer</span><p class="font-medium mt-0.5">{order.customer_name || 'Walk-in'}</p></div>
					<div><span class="text-gray-500">Date & Time</span><p class="font-medium mt-0.5">{new Date(order.created_at).toLocaleString()}</p></div>
					{#if order.cash_received}
						<div><span class="text-gray-500">Cash Received</span><p class="font-medium mt-0.5">₦{parseFloat(order.cash_received).toLocaleString()}</p></div>
						<div><span class="text-gray-500">Change Given</span><p class="font-medium mt-0.5">₦{parseFloat(order.change_given || 0).toLocaleString()}</p></div>
					{/if}
				</div>
			</div>

			<!-- Line Items -->
			<div class="bg-white rounded-xl border p-5">
				<h3 class="font-semibold text-gray-900 mb-4 flex items-center gap-2">
					<Receipt class="h-4 w-4 text-indigo-500" /> Items
				</h3>
				<div class="divide-y">
					{#each items as item}
						<div class="py-2.5 flex items-center justify-between">
							<div>
								<p class="text-sm font-medium text-gray-800">{item.product_name}</p>
								<p class="text-xs text-gray-400">{item.quantity} × ₦{parseFloat(item.unit_price).toLocaleString()}</p>
							</div>
							<span class="text-sm font-semibold text-gray-900">₦{parseFloat(item.subtotal).toLocaleString()}</span>
						</div>
					{/each}
				</div>
			</div>

			<!-- Totals -->
			<div class="bg-white rounded-xl border p-5">
				<div class="space-y-2 text-sm">
					<div class="flex justify-between text-gray-600"><span>Subtotal</span><span>₦{parseFloat(order.subtotal || order.total_amount).toLocaleString()}</span></div>
					{#if order.discount_amount > 0}
						<div class="flex justify-between text-green-600"><span>Discount</span><span>-₦{parseFloat(order.discount_amount).toLocaleString()}</span></div>
					{/if}
					<div class="flex justify-between text-lg font-bold text-gray-900 border-t pt-2">
						<span>Total</span><span class="text-indigo-600">₦{parseFloat(order.total_amount).toLocaleString()}</span>
					</div>
				</div>
			</div>
		</div>
	{/if}
</div>

<style>
	@media print {
		:global(body) {
			background: white !important;
			padding: 0 !important;
			margin: 0 !important;
		}
		.p-6 {
			padding: 0 !important;
			max-width: 100% !important;
		}
		.bg-white {
			border: none !important;
			padding: 0 !important;
		}
		.rounded-xl {
			border-radius: 0 !important;
		}
		.border {
			border-bottom: 1px solid #eee !important;
		}
		.shadow-sm, .shadow-md, .shadow-lg {
			box-shadow: none !important;
		}
		/* Ensure text is black for printing */
		:global(*) {
			color: black !important;
			-webkit-print-color-adjust: exact;
		}
		.text-indigo-600 {
			color: #4f46e5 !important; /* Keep brand color if possible */
		}
	}
</style>
