<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { ArrowLeft, Receipt, CheckCircle, XCircle, Clock, Printer } from 'lucide-svelte';

	// Svelte 5: Use reactive state from stores
	let orderId = $derived($page.params.id);
	let orderType = $derived($page.url.searchParams.get('type') || 'sales');
	let order = $state<any>(null);
	let items = $state<any[]>([]);
	let riders = $state<any[]>([]);
	let loading = $state(true);

	onMount(async () => {
		if (!orderId) return;
		try {
			if (orderType === 'sales') {
				const { data, error } = await supabase.from('sales').select('*').eq('id', orderId).single();
				if (error) throw error;
				order = data;
				const { data: lineItems } = await supabase.from('sale_items').select('*').eq('sale_id', orderId);
				items = lineItems || [];
			} else {
				const { data, error } = await supabase.from('orders')
					.select(`
						*,
						customer:customers(*),
						processor:users!processed_by(full_name),
						rider:riders!rider_id(id, phone, vehicle_type)
					`)
					.eq('id', orderId)
					.single();
				if (error) throw error;
				order = data;
				const { data: lineItems } = await supabase.from('order_items').select('*').eq('order_id', orderId);
				items = lineItems || [];
				
				// Fetch available riders if it's an online order
				const { data: riderData } = await supabase.from('riders').select('*').eq('is_available', true);
				riders = riderData || [];
			}
		} catch (e) {
			console.error('Order fetch error:', e);
		} finally {
			loading = false;
		}
	});

	async function claimOrder() {
		const { data: { user } } = await supabase.auth.getUser();
		if (!user) return;

		const { error } = await supabase.from('orders')
			.update({ 
				processed_by: user.id, 
				processed_at: new Date().toISOString(),
				order_status: 'preparing'
			})
			.eq('id', orderId);
		
		if (!error) window.location.reload();
	}

	async function assignRider(riderId: string) {
		const { error } = await supabase.from('orders')
			.update({ rider_id: riderId })
			.eq('id', orderId);
		
		if (!error) window.location.reload();
	}

	function statusIcon(status: string) { 
		return (status === 'completed' || status === 'delivered') ? CheckCircle : status === 'cancelled' ? XCircle : Clock; 
	}
	function statusColor(status: string) {
		switch(status) {
			case 'completed':
			case 'delivered': return 'text-green-600 bg-green-50'; 
			case 'cancelled': return 'text-red-600 bg-red-50'; 
			default: return 'text-yellow-600 bg-yellow-50';
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
		{@const StatusIcon = statusIcon(orderType === 'online' ? order.order_status : order.sale_status)}
		<div class="space-y-4">
			<!-- Online Order Actions -->
			{#if orderType === 'online'}
				<div class="bg-indigo-50 border border-indigo-100 rounded-xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
					<div>
						<h3 class="text-indigo-900 font-bold flex items-center gap-2">
							<Clock class="h-4 w-4" /> Processing Status
						</h3>
						{#if order.processor}
							<p class="text-indigo-700 text-sm mt-1 font-medium">Claimed by {order.processor.full_name}</p>
						{:else}
							<p class="text-indigo-600/70 text-sm mt-1 font-medium">No one has claimed this order yet.</p>
						{/if}
					</div>
					{#if !order.processed_by}
						<button onclick={claimOrder} class="bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-bold text-sm shadow-lg shadow-indigo-100 hover:bg-indigo-700 transition-all">
							Claim to Process
						</button>
					{/if}
				</div>

				<!-- Rider Assignment -->
				<div class="bg-white rounded-xl border p-5">
					<h3 class="font-semibold text-gray-900 mb-4 flex items-center gap-2">
						<Bike class="h-4 w-4 text-indigo-500" /> Delivery Assignment
					</h3>
					<div class="flex flex-col md:flex-row gap-4 items-end md:items-center">
						<div class="flex-1 space-y-1.5">
							<label class="text-[10px] font-bold text-gray-400 uppercase tracking-widest px-1">Select Rider</label>
							<select 
								value={order.rider_id || ''} 
								onchange={(e) => assignRider(e.currentTarget.value)}
								class="w-full bg-slate-50 border-none rounded-xl py-3 px-4 text-sm font-medium focus:ring-2 focus:ring-indigo-500"
							>
								<option value="">Unassigned</option>
								{#each riders as rider}
									<option value={rider.id}>{rider.vehicle_type} - {rider.phone}</option>
								{/each}
							</select>
						</div>
						{#if order.rider}
							<div class="bg-slate-50 px-4 py-3 rounded-xl border border-slate-100 min-w-[200px]">
								<p class="text-[9px] font-bold text-gray-400 uppercase tracking-widest mb-1">Assigned Rider</p>
								<p class="text-sm font-bold text-gray-800 flex items-center gap-2">
									<CheckCircle class="h-3 w-3 text-emerald-500" /> {order.rider.phone}
								</p>
							</div>
						{/if}
					</div>
				</div>
			{/if}

			<!-- Status + Info -->
			<div class="bg-white rounded-xl border p-5">
				<div class="flex items-center justify-between mb-4">
					<span class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-semibold capitalize {statusColor(orderType === 'online' ? order.order_status : order.sale_status)}">
						<StatusIcon class="h-4 w-4" /> {orderType === 'online' ? order.order_status : order.sale_status}
					</span>
					<span class="text-sm text-gray-500 capitalize">{order.payment_method || 'Unpaid'}</span>
				</div>
				<div class="grid grid-cols-2 gap-3 text-sm">
					<div><span class="text-gray-500">Customer</span><p class="font-medium mt-0.5">{order.customer?.full_name || order.customer_name || 'Walk-in'}</p></div>
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
