<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { ArrowLeft, Edit, Phone, Mail, MapPin, Star, ShoppingBag } from 'lucide-svelte';

	const customerId = $page.params.id;
	let customer = $state<any>(null);
	let purchases = $state<any[]>([]);
	let loading = $state(true);

	onMount(async () => {
		const { data } = await supabase.from('customers').select('*').eq('id', customerId).single();
		customer = data;
		if (data) {
			const { data: sales } = await supabase
				.from('sales')
				.select('*')
				.eq('customer_name', data.first_name + (data.last_name ? ' ' + data.last_name : ''))
				.order('created_at', { ascending: false })
				.limit(10);
			purchases = sales || [];
		}
		loading = false;
	});
</script>

<svelte:head><title>{customer ? customer.first_name + ' ' + (customer.last_name || '') : 'Customer'} – Kemani POS</title></svelte:head>

<div class="p-6 max-w-4xl mx-auto space-y-5">
	<div class="flex items-center justify-between">
		<div class="flex items-center gap-3">
			<a href="/customers" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
			<h1 class="text-xl font-bold text-gray-900">Customer Profile</h1>
		</div>
		{#if customer}
			<a href="/customers/{customerId}/edit" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2 rounded-xl text-sm transition-colors">
				<Edit class="h-4 w-4" /> Edit
			</a>
		{/if}
	</div>

	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else if customer}
		<div class="grid grid-cols-1 md:grid-cols-3 gap-5">
			<div class="md:col-span-2 space-y-4">
				<!-- Customer Card -->
				<div class="bg-white rounded-xl border p-5">
					<div class="flex items-start gap-4">
						<div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white font-bold text-2xl flex-shrink-0">
							{(customer.first_name?.[0] || '?').toUpperCase()}
						</div>
						<div class="flex-1">
							<h2 class="text-xl font-bold text-gray-900">{customer.first_name} {customer.last_name || ''}</h2>
							<div class="mt-2 space-y-1.5">
								{#if customer.phone}
									<div class="flex items-center gap-2 text-sm text-gray-600"><Phone class="h-4 w-4 text-gray-400" />{customer.phone}</div>
								{/if}
								{#if customer.email}
									<div class="flex items-center gap-2 text-sm text-gray-600"><Mail class="h-4 w-4 text-gray-400" />{customer.email}</div>
								{/if}
								{#if customer.address}
									<div class="flex items-center gap-2 text-sm text-gray-600"><MapPin class="h-4 w-4 text-gray-400" />{customer.address}</div>
								{/if}
							</div>
						</div>
					</div>
					{#if customer.notes}
						<div class="mt-4 pt-4 border-t">
							<p class="text-sm text-gray-500 italic">"{customer.notes}"</p>
						</div>
					{/if}
				</div>

				<!-- Purchase History -->
				<div class="bg-white rounded-xl border p-5">
					<h3 class="font-semibold text-gray-900 mb-4 flex items-center gap-2">
						<ShoppingBag class="h-4 w-4 text-indigo-500" /> Purchase History
					</h3>
					{#if purchases.length === 0}
						<p class="text-sm text-gray-400 text-center py-4">No purchases recorded yet</p>
					{:else}
						<div class="space-y-2">
							{#each purchases as sale}
								<a href="/orders/{sale.id}" class="flex items-center justify-between py-2.5 px-3 rounded-lg hover:bg-gray-50 transition-colors">
									<div>
										<p class="text-sm font-medium text-gray-800">#{sale.id?.slice(-6).toUpperCase()}</p>
										<p class="text-xs text-gray-400">{new Date(sale.created_at).toLocaleDateString()} · {sale.payment_method}</p>
									</div>
									<span class="text-sm font-bold text-emerald-600">₦{parseFloat(sale.total_amount).toLocaleString()}</span>
								</a>
							{/each}
						</div>
					{/if}
				</div>
			</div>

			<!-- Stats Sidebar -->
			<div class="space-y-4">
				<div class="bg-white rounded-xl border p-5 text-center">
					<div class="w-12 h-12 bg-amber-100 rounded-xl flex items-center justify-center mx-auto mb-3">
						<Star class="h-6 w-6 text-amber-500" />
					</div>
					<p class="text-3xl font-bold text-gray-900">{customer.loyalty_points || 0}</p>
					<p class="text-sm text-gray-500 mt-1">Loyalty Points</p>
				</div>

				<div class="bg-white rounded-xl border p-5 text-center">
					<p class="text-3xl font-bold text-emerald-600">₦{parseFloat(customer.total_spent || 0).toLocaleString()}</p>
					<p class="text-sm text-gray-500 mt-1">Total Spent</p>
				</div>

				<div class="bg-white rounded-xl border p-5">
					<p class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Details</p>
					<div class="space-y-2 text-sm">
						{#if customer.date_of_birth}
							<div class="flex justify-between text-gray-600"><span>Birthday</span><span>{new Date(customer.date_of_birth).toLocaleDateString()}</span></div>
						{/if}
						<div class="flex justify-between text-gray-600"><span>Member since</span><span>{new Date(customer.created_at).toLocaleDateString()}</span></div>
					</div>
				</div>
			</div>
		</div>
	{/if}
</div>
