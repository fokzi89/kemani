<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Bike, Package, MapPin, Phone, CheckCircle2, 
		Clock, AlertCircle, ChevronRight, Navigation
	} from 'lucide-svelte';
	import { fade, slide } from 'svelte/transition';

	let loading = $state(true);
	let profile = $state<any>(null);
	let assignedOrders = $state<any[]>([]);
	let stats = $state({ pending: 0, active: 0, completed: 0 });

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) {
			window.location.href = '/auth/login';
			return;
		}

		// Fetch user profile and rider details
		const { data: userData } = await supabase
			.from('users')
			.select('*, riders(*)')
			.eq('id', session.user.id)
			.single();
		
		profile = userData;
		
		if (profile?.riders?.[0]?.id) {
			await fetchAssignedOrders();
		} else {
			// If not a rider, check if they can manage orders anyway
			const { data: membership } = await supabase
				.from('user_tenants')
				.select('role')
				.eq('user_id', session.user.id)
				.single();
			
			if (membership?.role !== 'rider' && membership?.role !== 'tenant_admin') {
				// error = "Access Denied";
			}
		}
		loading = false;
	});

	async function fetchAssignedOrders() {
		if (!profile?.riders?.[0]?.id) return;
		
		const { data, error } = await supabase
			.from('orders')
			.select(`
				*,
				customer:customers(*),
				address:customer_addresses(*)
			`)
			.eq('rider_id', profile.riders[0].id)
			.order('created_at', { ascending: false });
		
		if (error) console.error('Error fetching rider orders:', error);
		assignedOrders = data || [];
		
		stats = {
			pending: assignedOrders.filter(o => o.order_status === 'confirmed').length,
			active: assignedOrders.filter(o => o.order_status === 'preparing' || o.order_status === 'ready').length,
			completed: assignedOrders.filter(o => o.order_status === 'completed' || o.order_status === 'delivered').length
		};
	}

	async function updateStatus(orderId: string, status: string) {
		const { error } = await supabase
			.from('orders')
			.update({ order_status: status })
			.eq('id', orderId);
		
		if (!error) await fetchAssignedOrders();
	}

	function getStatusColor(status: string) {
		switch (status) {
			case 'completed':
			case 'delivered': return 'text-emerald-600 bg-emerald-50';
			case 'ready': return 'text-blue-600 bg-blue-50';
			case 'preparing': return 'text-amber-600 bg-amber-50';
			case 'cancelled': return 'text-red-600 bg-red-50';
			default: return 'text-slate-600 bg-slate-50';
		}
	}
</script>

<svelte:head><title>Rider Portal – Kemani POS</title></svelte:head>

<div class="min-h-screen bg-slate-50 p-4 md:p-8">
	<!-- Top Bar -->
	<div class="max-w-4xl mx-auto mb-8 flex items-center justify-between">
		<div class="flex items-center gap-4">
			<div class="h-12 w-12 bg-indigo-600 rounded-2xl flex items-center justify-center text-white shadow-lg shadow-indigo-100">
				<Bike class="h-6 w-6" />
			</div>
			<div>
				<h1 class="text-xl font-bold text-slate-900">Rider Portal</h1>
				<p class="text-sm text-slate-500 font-medium">Welcome back, {profile?.full_name || 'Rider'}</p>
			</div>
		</div>
		<div class="flex items-center gap-2 bg-white px-3 py-1.5 rounded-full border border-slate-200 shadow-sm">
			<div class="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></div>
			<span class="text-[10px] font-bold text-slate-600 uppercase tracking-widest">Active Duty</span>
		</div>
	</div>

	<!-- Stats Grid -->
	<div class="max-w-4xl mx-auto grid grid-cols-3 gap-4 mb-8">
		<div class="bg-white p-4 rounded-3xl border border-slate-200 shadow-sm text-center">
			<p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Assigned</p>
			<p class="text-2xl font-black text-slate-900">{stats.pending}</p>
		</div>
		<div class="bg-indigo-600 p-4 rounded-3xl shadow-xl shadow-indigo-100 text-center">
			<p class="text-[10px] font-bold text-indigo-100 uppercase tracking-widest mb-1 text-white/70">In Progress</p>
			<p class="text-2xl font-black text-white">{stats.active}</p>
		</div>
		<div class="bg-white p-4 rounded-3xl border border-slate-200 shadow-sm text-center">
			<p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Delivered</p>
			<p class="text-2xl font-black text-slate-900">{stats.completed}</p>
		</div>
	</div>

	<!-- Orders List -->
	<div class="max-w-4xl mx-auto space-y-4">
		<h2 class="text-sm font-bold text-slate-400 uppercase tracking-widest px-2 mb-4">Current Deliveries</h2>

		{#if loading}
			<div class="py-20 text-center">
				<div class="h-10 w-10 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
				<p class="text-slate-400 font-bold text-xs uppercase tracking-widest">Syncing with Station...</p>
			</div>
		{:else if assignedOrders.length === 0}
			<div class="bg-white rounded-[2.5rem] border border-slate-200 p-12 text-center shadow-sm">
				<div class="h-20 w-20 bg-slate-50 rounded-3xl flex items-center justify-center mx-auto mb-6">
					<Package class="h-10 w-10 text-slate-200" />
				</div>
				<h3 class="text-xl font-bold text-slate-900">No Orders Assigned</h3>
				<p class="text-slate-500 mt-2 font-medium">Check back soon for new delivery tasks.</p>
			</div>
		{:else}
			{#each assignedOrders as order (order.id)}
				<div 
					class="bg-white rounded-[2rem] border border-slate-200 p-6 shadow-sm hover:shadow-xl transition-all group overflow-hidden relative"
					in:fade={{ duration: 300 }}
				>
					<div class="flex flex-col md:flex-row gap-6 relative">
						<!-- Info Column -->
						<div class="flex-1 space-y-4">
							<div class="flex items-center justify-between">
								<span class="text-xs font-black text-indigo-600 uppercase tracking-widest">Order {order.order_number}</span>
								<span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest {getStatusColor(order.order_status)} ring-1 ring-inset ring-current">
									{order.order_status}
								</span>
							</div>

							<div class="space-y-3">
								<div class="flex items-start gap-3">
									<div class="h-10 w-10 bg-slate-50 rounded-xl flex items-center justify-center text-slate-400 shrink-0">
										<MapPin class="h-5 w-5" />
									</div>
									<div class="min-w-0">
										<p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Destination</p>
										<p class="text-sm font-bold text-slate-800 line-clamp-2">{order.special_instructions || 'Check shipping details'}</p>
									</div>
								</div>

								<div class="flex items-start gap-3">
									<div class="h-10 w-10 bg-slate-50 rounded-xl flex items-center justify-center text-slate-400 shrink-0">
										<Phone class="h-5 w-5" />
									</div>
									<div>
										<p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Customer</p>
										<p class="text-sm font-bold text-slate-800">{order.customer?.full_name || 'Guest'}</p>
									</div>
								</div>
							</div>
						</div>

						<!-- Action Column -->
						<div class="md:w-48 flex flex-col justify-center gap-3 border-t md:border-t-0 md:border-l border-slate-100 pt-6 md:pt-0 md:pl-6">
							{#if order.order_status === 'ready'}
								<button 
									onclick={() => updateStatus(order.id, 'picked_up')}
									class="w-full bg-amber-500 hover:bg-amber-600 text-white font-bold py-3 rounded-2xl shadow-lg shadow-amber-100 transition-all flex items-center justify-center gap-2"
								>
									<Clock class="h-4 w-4" /> Pick Up
								</button>
							{:else if order.order_status === 'picked_up'}
								<button 
									onclick={() => updateStatus(order.id, 'delivered')}
									class="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-3 rounded-2xl shadow-lg shadow-emerald-100 transition-all flex items-center justify-center gap-2"
								>
									<CheckCircle2 class="h-4 w-4" /> Delivered
								</button>
							{:else if order.order_status === 'completed' || order.order_status === 'delivered'}
								<div class="text-center py-4">
									<CheckCircle2 class="h-8 w-8 text-emerald-500 mx-auto mb-2" />
									<p class="text-[10px] font-bold text-emerald-600 uppercase tracking-widest">Completed</p>
								</div>
							{:else}
								<div class="text-center py-4 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
									<p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Waiting for Branch</p>
								</div>
							{/if}
							
							<a 
								href="/orders/{order.id}?type=online"
								class="w-full text-center text-xs font-bold text-indigo-600 hover:bg-indigo-50 py-2 rounded-xl transition-colors"
							>
								View Details
							</a>
						</div>
					</div>
				</div>
			{/each}
		{/if}
	</div>
</div>

<style>
	:global(body) {
		background-color: rgb(248 250 252);
	}
</style>
