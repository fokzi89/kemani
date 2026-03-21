<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Search, Plus, Users, Eye, Edit, Phone, Mail, ChevronLeft, ChevronRight } from 'lucide-svelte';

	let customers = $state<any[]>([]);
	let filtered = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let page = $state(1);
	const PER_PAGE = 20;

	let paginated = $derived(filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE));
	let totalPages = $derived(Math.ceil(filtered.length / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) {
			const { data } = await supabase.from('customers').select('*').eq('tenant_id', user.tenant_id).order('first_name');
			customers = data || [];
			filtered = customers;
		}
		loading = false;
	});

	function applyFilter() {
		const q = searchQuery.toLowerCase();
		filtered = q ? customers.filter(c =>
			(c.first_name + ' ' + c.last_name).toLowerCase().includes(q) ||
			(c.email && c.email.toLowerCase().includes(q)) ||
			(c.phone && c.phone.includes(q))
		) : customers;
		page = 1;
	}

	$effect(() => { searchQuery; applyFilter(); });
</script>

<svelte:head><title>Customers – Kemani POS</title></svelte:head>

<div class="p-6 space-y-5 max-w-7xl mx-auto">
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Customers</h1>
			<p class="text-sm text-gray-500 mt-0.5">{filtered.length} customer{filtered.length !== 1 ? 's' : ''}</p>
		</div>
		<a href="/customers/new" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm">
			<Plus class="h-4 w-4" /> Add Customer
		</a>
	</div>

	<div class="bg-white rounded-xl border p-4">
		<div class="relative">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input type="text" bind:value={searchQuery} placeholder="Search by name, email, or phone..."
				class="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
		</div>
	</div>

	<div class="bg-white rounded-xl border overflow-hidden">
		{#if loading}
			<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
		{:else if paginated.length === 0}
			<div class="p-12 text-center text-gray-400">
				<Users class="h-12 w-12 mx-auto mb-3 opacity-30" />
				<p class="font-medium">No customers found</p>
				<a href="/customers/new" class="mt-3 inline-block text-sm text-indigo-600 hover:underline">Add your first customer</a>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-sm">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Customer</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Contact</th>
							<th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">Loyalty Pts</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Total Spent</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each paginated as customer}
							<tr class="hover:bg-gray-50 transition-colors">
								<td class="px-4 py-3">
									<div class="flex items-center gap-3">
										<div class="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white font-semibold text-sm flex-shrink-0">
											{(customer.first_name?.[0] || '?').toUpperCase()}
										</div>
										<div>
											<p class="font-medium text-gray-900">{customer.first_name} {customer.last_name || ''}</p>
											{#if customer.date_of_birth}
												<p class="text-xs text-gray-400">DOB: {new Date(customer.date_of_birth).toLocaleDateString()}</p>
											{/if}
										</div>
									</div>
								</td>
								<td class="px-4 py-3">
									<div class="space-y-0.5">
										{#if customer.email}
											<div class="flex items-center gap-1.5 text-gray-500 text-xs">
												<Mail class="h-3 w-3" />{customer.email}
											</div>
										{/if}
										{#if customer.phone}
											<div class="flex items-center gap-1.5 text-gray-500 text-xs">
												<Phone class="h-3 w-3" />{customer.phone}
											</div>
										{/if}
									</div>
								</td>
								<td class="px-4 py-3 text-center">
									<span class="font-semibold text-indigo-600">{customer.loyalty_points || 0}</span>
								</td>
								<td class="px-4 py-3 text-right font-semibold text-gray-900">
									₦{parseFloat(customer.total_spent || 0).toLocaleString()}
								</td>
								<td class="px-4 py-3">
									<div class="flex items-center justify-end gap-1">
										<a href="/customers/{customer.id}" class="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"><Eye class="h-4 w-4" /></a>
										<a href="/customers/{customer.id}/edit" class="p-1.5 rounded-lg hover:bg-indigo-50 text-gray-400 hover:text-indigo-600 transition-colors"><Edit class="h-4 w-4" /></a>
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			{#if totalPages > 1}
				<div class="px-4 py-3 border-t flex items-center justify-between text-sm text-gray-600">
					<span>Showing {(page-1)*PER_PAGE+1}–{Math.min(page*PER_PAGE, filtered.length)} of {filtered.length}</span>
					<div class="flex gap-1">
						<button onclick={() => page--} disabled={page === 1} class="p-1.5 rounded hover:bg-gray-100 disabled:opacity-40"><ChevronLeft class="h-4 w-4" /></button>
						<button onclick={() => page++} disabled={page === totalPages} class="p-1.5 rounded hover:bg-gray-100 disabled:opacity-40"><ChevronRight class="h-4 w-4" /></button>
					</div>
				</div>
			{/if}
		{/if}
	</div>
</div>
