<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Truck, Search, Filter, Plus, Bike, Calendar, Clock, 
		MapPin, User, ChevronRight, Settings as SettingsIcon,
		CheckCircle2, AlertCircle, MoreVertical, Edit2
	} from 'lucide-svelte';
	import DeliveryTypeModal from '$lib/components/DeliveryTypeModal.svelte';

	let loading = $state(true);
	let deliveries = $state<any[]>([]);
	let deliveryTypes = $state<any[]>([]);
	let activeTab = $state('deliveries'); // 'deliveries' or 'settings'
	let searchQuery = $state('');
	let statusFilter = $state('all');
	let tenantId = $state('');

	// Modal state
	let showTypeModal = $state(false);
	let selectedType = $state<any>(null);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: userProfile } = await supabase
			.from('users')
			.select('tenant_id')
			.eq('id', session.user.id)
			.single();
			
		if (userProfile?.tenant_id) {
			tenantId = userProfile.tenant_id;
			await Promise.all([
				fetchDeliveries(),
				fetchDeliveryTypes()
			]);
		}
		loading = false;
	});

	async function fetchDeliveries() {
		const { data, error } = await supabase
			.from('deliveries')
			.select(`
				*,
				order:orders(order_number, total_amount),
				customer:customers(full_name)
			`)
			.eq('tenant_id', tenantId)
			.order('created_at', { ascending: false });
		
		if (error) console.error('Error fetching deliveries:', error);
		deliveries = data || [];
	}

	async function fetchDeliveryTypes() {
		const { data, error } = await supabase
			.from('delivery_types')
			.select('*')
			.eq('tenant_id', tenantId)
			.order('display_order', { ascending: true });
		
		if (error) console.error('Error fetching delivery types:', error);
		deliveryTypes = data || [];
	}

	let filteredDeliveries = $derived(
		deliveries.filter(d => {
			const matchesSearch = 
				d.tracking_number?.toLowerCase().includes(searchQuery.toLowerCase()) ||
				d.order?.order_number?.toLowerCase().includes(searchQuery.toLowerCase()) ||
				d.customer?.full_name?.toLowerCase().includes(searchQuery.toLowerCase());
			
			const matchesStatus = statusFilter === 'all' || d.delivery_status === statusFilter;
			
			return matchesSearch && matchesStatus;
		})
	);

	function getStatusColor(status: string) {
		switch (status) {
			case 'delivered': return 'bg-emerald-50 text-emerald-700 ring-emerald-600/20';
			case 'in_transit': return 'bg-blue-50 text-blue-700 ring-blue-600/20';
			case 'assigned': return 'bg-indigo-50 text-indigo-700 ring-indigo-600/20';
			case 'pending': return 'bg-amber-50 text-amber-700 ring-amber-600/20';
			case 'failed': return 'bg-rose-50 text-rose-700 ring-rose-600/20';
			case 'cancelled': return 'bg-slate-50 text-slate-700 ring-slate-600/20';
			default: return 'bg-slate-50 text-slate-700 ring-slate-600/20';
		}
	}

	function fmtCurrency(n: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(n);
	}

	function openAddType() {
		selectedType = null;
		showTypeModal = true;
	}

	function openEditType(type: any) {
		selectedType = type;
		showTypeModal = true;
	}
</script>

<svelte:head><title>Delivery Management – Kemani POS</title></svelte:head>

<div class="p-4 md:p-8 space-y-8 max-w-[1600px] mx-auto min-h-screen bg-slate-50/50">
	<!-- Header -->
	<div class="flex flex-col md:flex-row md:items-end justify-between gap-6">
		<div class="space-y-2">
			<div class="flex items-center gap-2 text-indigo-600 text-sm font-bold uppercase tracking-wider">
				<Truck class="h-4 w-4" />
				<span>Logistics & Fulfillment</span>
			</div>
			<h1 class="text-2xl font-bold text-slate-900 tracking-tight">Delivery Management</h1>
			<p class="text-slate-500 text-sm font-medium">Manage order dispatches, tracking, and delivery pricing.</p>
		</div>
		
		<div class="flex items-center bg-white p-1 rounded-2xl border border-slate-200 shadow-sm">
			<button 
				onclick={() => activeTab = 'deliveries'}
				class="px-5 py-2 rounded-xl text-xs font-semibold transition-all {activeTab === 'deliveries' ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-100' : 'text-slate-500 hover:bg-slate-50'}"
			>
				Orders
			</button>
			<button 
				onclick={() => activeTab = 'settings'}
				class="px-5 py-2 rounded-xl text-xs font-semibold transition-all {activeTab === 'settings' ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-100' : 'text-slate-500 hover:bg-slate-50'}"
			>
				Settings
			</button>
		</div>
	</div>

	{#if activeTab === 'deliveries'}
		<!-- Deliveries Filter Bar -->
		<div class="grid grid-cols-1 md:grid-cols-4 gap-4 bg-white p-4 rounded-3xl border border-slate-200 shadow-sm">
			<div class="md:col-span-2 relative">
				<Search class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
				<input 
					type="text" 
					bind:value={searchQuery} 
					placeholder="Search by tracking #, order #, or customer..."
					class="w-full pl-11 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-indigo-500 text-sm font-medium" 
				/>
			</div>
			<div class="relative">
				<Filter class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
				<select 
					bind:value={statusFilter} 
					class="w-full pl-11 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-indigo-500 text-sm font-medium appearance-none cursor-pointer"
				>
					<option value="all">All Statuses</option>
					<option value="pending">Pending</option>
					<option value="assigned">Assigned</option>
					<option value="in_transit">In Transit</option>
					<option value="delivered">Delivered</option>
					<option value="failed">Failed</option>
					<option value="cancelled">Cancelled</option>
				</select>
			</div>
			<div class="flex items-center justify-end">
				<button 
					onclick={() => { searchQuery = ''; statusFilter = 'all'; }}
					class="text-xs font-semibold text-indigo-600 hover:text-indigo-700 px-4"
				>
					Reset
				</button>
			</div>
		</div>

		<!-- Deliveries Table -->
		<div class="bg-white rounded-[2rem] border border-slate-200 shadow-xl overflow-hidden">
			{#if loading}
				<div class="py-32 flex flex-col items-center justify-center gap-4">
					<div class="h-12 w-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
					<p class="text-slate-400 font-bold text-xs uppercase tracking-widest">Fetching Deliveries...</p>
				</div>
			{:else if filteredDeliveries.length === 0}
				<div class="py-32 text-center">
					<div class="h-20 w-20 bg-slate-50 rounded-3xl flex items-center justify-center mx-auto mb-6">
						<Truck class="h-10 w-10 text-slate-200" />
					</div>
					<h3 class="text-xl font-bold text-slate-900">No deliveries found</h3>
					<p class="text-slate-500 mt-2 font-medium">Try adjusting your search or filters.</p>
				</div>
			{:else}
				<div class="overflow-x-auto">
					<table class="w-full border-collapse">
						<thead>
							<tr class="bg-slate-50/50 border-b border-slate-100">
								<th class="px-8 py-4 text-left text-[10px] font-bold text-slate-400 uppercase tracking-widest">Tracking / Order</th>
								<th class="px-8 py-4 text-left text-[10px] font-bold text-slate-400 uppercase tracking-widest">Customer & Address</th>
								<th class="px-8 py-4 text-center text-[10px] font-bold text-slate-400 uppercase tracking-widest">Status</th>
								<th class="px-8 py-4 text-right text-[10px] font-bold text-slate-400 uppercase tracking-widest">Value</th>
								<th class="px-8 py-4"></th>
							</tr>
						</thead>
						<tbody class="divide-y divide-slate-50">
							{#each filteredDeliveries as delivery}
								<tr class="group hover:bg-slate-50/50 transition-colors">
									<td class="px-8 py-5">
										<div class="flex flex-col">
											<span class="text-sm font-semibold text-slate-900 group-hover:text-indigo-600 transition-colors">
												{delivery.tracking_number}
											</span>
											<span class="text-[10px] font-medium text-slate-400 uppercase tracking-tight mt-0.5">
												Order {delivery.order?.order_number}
											</span>
										</div>
									</td>
									<td class="px-8 py-5">
										<div class="flex items-start gap-3">
											<div class="h-9 w-9 rounded-xl bg-slate-100 flex items-center justify-center text-slate-500 shrink-0">
												<User class="h-4 w-4" />
											</div>
											<div class="flex flex-col min-w-0">
												<span class="text-sm font-semibold text-slate-700 truncate">
													{delivery.customer?.full_name || 'Valued Customer'}
												</span>
												<span class="text-[11px] text-slate-400 truncate flex items-center gap-1 mt-0.5">
													<MapPin class="h-3 w-3" /> {delivery.customer_address}
												</span>
											</div>
										</div>
									</td>
									<td class="px-8 py-5 text-center">
										<span class="inline-flex items-center px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest ring-1 ring-inset {getStatusColor(delivery.delivery_status)}">
											{delivery.delivery_status.replace('_', ' ')}
										</span>
									</td>
									<td class="px-8 py-5 text-right">
										<span class="text-sm font-bold text-slate-900 tabular-nums">
											{fmtCurrency(delivery.order?.total_amount || 0)}
										</span>
									</td>
									<td class="px-8 py-6 text-right">
										<button class="p-2 text-slate-300 hover:text-indigo-600 transition-colors">
											<ChevronRight class="h-5 w-5" />
										</button>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</div>
	{:else}
		<!-- Settings Tab -->
		<div class="space-y-6">
			<div class="flex items-center justify-between">
				<div class="space-y-1">
					<h2 class="text-lg font-bold text-slate-900">Delivery Types & Pricing</h2>
					<p class="text-xs text-slate-500 font-medium">Configure different vehicle types and their associated fees.</p>
				</div>
				<button 
					onclick={openAddType}
					class="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-5 py-2.5 rounded-xl text-sm transition-all shadow-lg shadow-indigo-100 active:scale-95"
				>
					<Plus class="h-4 w-4" /> Add New Type
				</button>
			</div>

			<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
				{#each deliveryTypes as type}
					<div class="bg-white rounded-[2rem] border border-slate-200 p-8 shadow-sm hover:shadow-xl hover:border-indigo-100 transition-all group relative overflow-hidden">
						<!-- Background Decoration -->
						<div class="absolute -right-4 -top-4 text-slate-50/50 group-hover:text-indigo-50/50 transition-colors">
							<Bike class="h-32 w-32 rotate-12" />
						</div>

						<div class="relative flex flex-col h-full">
							<div class="flex items-start justify-between mb-6">
								<div class="flex items-center gap-4">
									<div class="h-12 w-12 rounded-xl bg-indigo-50 flex items-center justify-center text-indigo-600">
										<Bike class="h-6 w-6" />
									</div>
									<div>
										<h3 class="text-lg font-bold text-slate-900">{type.name}</h3>
										<div class="flex items-center gap-2 mt-0.5">
											{#if type.is_active}
												<span class="flex items-center gap-1 text-[9px] font-bold uppercase tracking-widest text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">Active</span>
											{:else}
												<span class="flex items-center gap-1 text-[9px] font-bold uppercase tracking-widest text-slate-400 bg-slate-50 px-1.5 py-0.5 rounded-full">Inactive</span>
											{/if}
										</div>
									</div>
								</div>
								<button 
									onclick={() => openEditType(type)}
									class="p-3 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-2xl transition-all"
								>
									<Edit2 class="h-5 w-5" />
								</button>
							</div>

							<p class="text-slate-500 text-sm font-medium mb-8 flex-1 line-clamp-2">
								{type.description || 'No description provided for this delivery type.'}
							</p>

							<div class="grid grid-cols-2 gap-4 border-t border-slate-100 pt-5">
								<div class="space-y-0.5">
									<p class="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Base Fee</p>
									<p class="text-base font-bold text-slate-900">{fmtCurrency(type.base_fee)}</p>
								</div>
								<div class="space-y-0.5 text-right">
									<p class="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Per KM Fee</p>
									<p class="text-base font-bold text-slate-900">{fmtCurrency(type.per_km_fee)}</p>
								</div>
								<div class="space-y-0.5">
									<p class="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Free Distance</p>
									<p class="text-xs font-semibold text-slate-700">{type.free_distance_km} KM</p>
								</div>
								<div class="space-y-0.5 text-right">
									<p class="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Max Distance</p>
									<p class="text-xs font-semibold text-slate-700">{type.max_distance_km || 'Unlimited'} KM</p>
								</div>
							</div>
						</div>
					</div>
				{/each}

				{#if deliveryTypes.length === 0}
					<div class="lg:col-span-2 py-24 text-center bg-white rounded-[2rem] border-2 border-dashed border-slate-200">
						<Plus class="h-12 w-12 text-slate-200 mx-auto mb-4" />
						<h3 class="text-lg font-bold text-slate-900">No delivery types configured</h3>
						<p class="text-slate-500 font-medium">Click the button above to add your first delivery option.</p>
					</div>
				{/if}
			</div>
		</div>
	{/if}
</div>

<DeliveryTypeModal 
	bind:open={showTypeModal} 
	{tenantId} 
	deliveryType={selectedType} 
	onSave={() => {
		fetchDeliveryTypes();
		showTypeModal = false;
	}}
/>

<style>
	/* Tab transitions */
	:global(.lucide) {
		stroke-width: 2.5px;
	}
</style>
