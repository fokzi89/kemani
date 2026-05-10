<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { isAuthenticated, currentUser } from '$lib/stores/auth';
	import { 
		Package, Truck, MapPin, CheckCircle2, 
		Clock, AlertCircle, ArrowRight, ShoppingBag,
		Bike, Box, ShieldCheck, Timer
	} from 'lucide-svelte';
	import { fade, slide, fly } from 'svelte/transition';

	export let data: { tenant: any };
	$: storefront = data.tenant;

	let loading = $state(true);
	let orders = $state<any[]>([]);
	let selectedOrder = $state<any>(null);
	let deliverySteps = $state<any[]>([]);

	const STATUS_MAP = {
		'pending': { label: 'Order Received', icon: Clock, color: 'text-amber-500', desc: 'Waiting for branch confirmation' },
		'confirmed': { label: 'Confirmed', icon: ShieldCheck, color: 'text-indigo-500', desc: 'Branch has accepted your order' },
		'preparing': { label: 'Preparing', icon: Box, color: 'text-blue-500', desc: 'We are picking and packing your items' },
		'ready': { label: 'Ready for Pickup', icon: Package, color: 'text-emerald-500', desc: 'Awaiting rider pickup' },
		'picked_up': { label: 'Picked Up', icon: Bike, color: 'text-purple-500', desc: 'Rider has collected your package' },
		'in_transit': { label: 'Out for Delivery', icon: Truck, color: 'text-blue-600', desc: 'Rider is on the way to you' },
		'delivered': { label: 'Delivered', icon: CheckCircle2, color: 'text-emerald-600', desc: 'Package dropped off successfully' },
		'cancelled': { label: 'Cancelled', icon: AlertCircle, color: 'text-rose-500', desc: 'This order was cancelled' }
	};

	onMount(async () => {
		if (!$isAuthenticated) {
			loading = false;
			return;
		}

		await fetchActiveOrders();
		loading = false;
	});

	async function fetchActiveOrders() {
		const { data: oData, error } = await supabase
			.from('orders')
			.select(`
				*,
				delivery:deliveries(*)
			`)
			.eq('customer_id', $currentUser?.id)
			.order('created_at', { ascending: false });
		
		if (oData) {
			orders = oData;
			// Default to the most recent active order if available
			const active = orders.find(o => o.order_status !== 'delivered' && o.order_status !== 'cancelled');
			if (active) selectOrder(active);
		}
	}

	function selectOrder(order: any) {
		selectedOrder = order;
		generateSteps(order);
	}

	function generateSteps(order: any) {
		const statuses = ['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'in_transit', 'delivered'];
		const currentIdx = statuses.indexOf(order.order_status);
		
		deliverySteps = statuses.map((s, idx) => ({
			status: s,
			...STATUS_MAP[s],
			isCompleted: idx < currentIdx,
			isCurrent: idx === currentIdx,
			isPending: idx > currentIdx
		}));
	}

	function fmtCurrency(n: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(n);
	}
</script>

<svelte:head>
	<title>Track Your Order — {storefront?.name || 'Kemani'}</title>
</svelte:head>

<div class="min-h-screen bg-[#faf9f6] pt-24 pb-20">
	<div class="max-w-4xl mx-auto px-4">
		
		{#if !$isAuthenticated}
			<div class="text-center py-32 bg-white rounded-[2.5rem] border border-[#f0eeea] shadow-sm px-8" in:fade>
				<div class="h-20 w-20 bg-[#faf9f6] rounded-full flex items-center justify-center mx-auto mb-8 text-slate-300">
					<ShieldCheck class="h-10 w-10" />
				</div>
				<h1 class="text-3xl font-serif mb-4">Secure Tracking</h1>
				<p class="text-slate-500 max-w-sm mx-auto mb-10 leading-relaxed font-light">
					To protect your privacy, order tracking is only available to registered members. 
					Please sign in to see your active shipments.
				</p>
				<button 
					onclick={() => window.location.href = '/auth/login?redirect=/track'}
					class="bg-[#1a1c1a] text-white px-10 py-4 rounded-full font-bold text-xs uppercase tracking-[0.2em] hover:bg-black transition-all"
				>
					Sign In to Track
				</button>
			</div>
		{:else if loading}
			<div class="py-32 text-center">
				<div class="h-12 w-12 border-4 border-[#1a1c1a] border-t-transparent rounded-full animate-spin mx-auto mb-6"></div>
				<p class="font-serif italic text-slate-400">Locating your packages...</p>
			</div>
		{:else if orders.length === 0}
			<div class="text-center py-32 bg-white rounded-[2.5rem] border border-[#f0eeea] shadow-sm px-8">
				<div class="h-20 w-20 bg-[#faf9f6] rounded-full flex items-center justify-center mx-auto mb-8 text-slate-200">
					<ShoppingBag class="h-10 w-10" />
				</div>
				<h2 class="text-2xl font-serif mb-2">No Active Orders</h2>
				<p class="text-slate-500 mb-8 font-light">You don't have any orders in transit at the moment.</p>
				<a href="/" class="text-[#785a1a] font-bold text-xs uppercase tracking-widest flex items-center justify-center gap-2">
					Browse Collection <ArrowRight class="h-4 w-4" />
				</a>
			</div>
		{:else}
			<div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
				<!-- Sidebar: Order List -->
				<div class="lg:col-span-4 space-y-4">
					<h2 class="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400 px-4">Your Recent Orders</h2>
					<div class="space-y-3">
						{#each orders as order}
							<button 
								onclick={() => selectOrder(order)}
								class="w-full text-left bg-white p-5 rounded-[2rem] border transition-all {selectedOrder?.id === order.id ? 'border-[#785a1a] shadow-xl shadow-amber-50' : 'border-[#f0eeea] hover:border-slate-300'}"
							>
								<div class="flex justify-between items-start mb-2">
									<span class="text-xs font-bold text-slate-900">{order.order_number}</span>
									<span class="text-[9px] font-black uppercase text-[#785a1a]">{fmtCurrency(order.total_amount)}</span>
								</div>
								<div class="flex items-center gap-2 text-[10px] text-slate-400 font-bold uppercase tracking-wider">
									<Timer class="h-3 w-3" />
									{new Date(order.created_at).toLocaleDateString()}
								</div>
							</button>
						{/each}
					</div>
				</div>

				<!-- Main View: Tracking Details -->
				<div class="lg:col-span-8">
					{#if selectedOrder}
						<div class="bg-white rounded-[3rem] border border-[#f0eeea] shadow-2xl shadow-slate-100/50 overflow-hidden" in:fly={{ y: 20, duration: 400 }}>
							<!-- Header -->
							<div class="p-8 md:p-12 bg-slate-50/50 border-b border-[#f0eeea]">
								<div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
									<div>
										<h1 class="text-3xl font-serif mb-2">{selectedOrder.order_number}</h1>
										<p class="text-sm text-slate-400 font-medium italic">Ordered on {new Date(selectedOrder.created_at).toLocaleString()}</p>
									</div>
									<div class="flex items-center gap-3">
										<div class="h-14 w-14 bg-white rounded-2xl flex items-center justify-center shadow-sm border border-[#f0eeea]">
											{#if selectedOrder.order_status === 'delivered'}
												<CheckCircle2 class="h-7 w-7 text-emerald-500" />
											{:else}
												<Truck class="h-7 w-7 text-[#785a1a] animate-pulse" />
											{/if}
										</div>
										<div>
											<p class="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Current State</p>
											<p class="text-lg font-bold text-slate-900 capitalize">{selectedOrder.order_status.replace('_', ' ')}</p>
										</div>
									</div>
								</div>
							</div>

							<!-- Timeline -->
							<div class="p-8 md:p-12">
								<div class="relative space-y-0">
									<!-- Vertical Line -->
									<div class="absolute left-6 top-2 bottom-2 w-0.5 bg-[#f0eeea]"></div>

									{#each deliverySteps as step, i}
										<div 
											class="relative pl-16 pb-12 last:pb-0 group"
											in:fade={{ delay: i * 100 }}
										>
											<!-- Dot -->
											<div class="absolute left-4 top-1 h-4 w-4 rounded-full border-4 transition-all z-10 
												{step.isCompleted ? 'bg-emerald-500 border-emerald-100' : 
												 step.isCurrent ? 'bg-[#785a1a] border-amber-100 scale-125' : 
												 'bg-white border-[#f0eeea]'}"
											></div>

											<div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
												<div>
													<h3 class="text-sm font-bold {step.isPending ? 'text-slate-300' : 'text-slate-900'} flex items-center gap-2">
														<step.icon class="h-4 w-4" />
														{step.label}
													</h3>
													<p class="text-xs {step.isPending ? 'text-slate-200' : 'text-slate-400'} mt-1 font-medium">{step.desc}</p>
												</div>
												{#if step.isCurrent}
													<div class="inline-flex items-center gap-2 bg-slate-50 px-3 py-1.5 rounded-full" in:slide>
														<span class="h-1.5 w-1.5 rounded-full bg-[#785a1a] animate-ping"></span>
														<span class="text-[9px] font-black text-[#785a1a] uppercase tracking-widest">Active Now</span>
													</div>
												{/if}
											</div>
										</div>
									{/each}
								</div>
							</div>

							<!-- Summary Box -->
							<div class="p-8 bg-[#faf9f6] m-6 rounded-[2rem] border border-[#f0eeea]">
								<div class="flex items-start gap-4">
									<div class="h-10 w-10 bg-white rounded-xl flex items-center justify-center shrink-0 shadow-sm border border-[#f0eeea]">
										<MapPin class="h-5 w-5 text-slate-400" />
									</div>
									<div>
										<p class="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Delivery Address</p>
										<p class="text-sm text-slate-600 font-medium leading-relaxed">
											{selectedOrder.special_instructions || 'Standard Delivery to primary address'}
										</p>
									</div>
								</div>
							</div>
						</div>
					{/if}
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) {
		background-color: #faf9f6;
	}
	
	font-serif {
		font-family: 'Playfair Display', serif;
	}
</style>
