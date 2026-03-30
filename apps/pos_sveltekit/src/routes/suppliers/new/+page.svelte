<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Truck, Save, ArrowLeft, Building, Phone, Mail, MapPin, User } from 'lucide-svelte';

	let loading = $state(false);
	let tenantId = $state('');
	let form = $state({
		name: '',
		contact_person: '',
		email: '',
		phone: '',
		address: ''
	});

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) tenantId = user.tenant_id;
	});

	async function handleSave() {
		if (!form.name || !tenantId) return;
		loading = true;
		try {
			const { error } = await supabase.from('suppliers').insert([{ ...form, tenant_id: tenantId }]);
			if (error) throw error;
			goto('/suppliers');
		} catch (err: any) {
			alert(err.message || 'Failed to save supplier');
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>Add Supplier – Kemani POS</title></svelte:head>

<div class="min-h-screen bg-gray-50/50 p-6">
	<div class="max-w-3xl mx-auto space-y-6">
		<!-- Top Bar -->
		<div class="flex items-center justify-between">
			<button onclick={() => history.back()} class="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors font-medium">
				<ArrowLeft class="h-4 w-4" /> Back to Suppliers
			</button>
			<div class="h-10 w-10 bg-white border rounded-xl flex items-center justify-center text-indigo-600 shadow-sm">
				<Truck class="h-5 w-5" />
			</div>
		</div>

		<!-- Main Form -->
		<form onsubmit={(e) => { e.preventDefault(); handleSave(); }} class="space-y-6">
			<!-- Profile Card -->
			<div class="bg-white rounded-2xl border shadow-sm overflow-hidden">
				<div class="bg-indigo-600 p-6 text-white flex items-center gap-5">
					<div class="h-16 w-16 bg-white/20 backdrop-blur-md rounded-2xl flex items-center justify-center border border-white/30">
						<Building class="h-8 w-8" />
					</div>
					<div>
						<h1 class="text-2xl font-black">Register New Supplier</h1>
						<p class="text-indigo-100 text-sm">Add a new procurement vendor to your catalog</p>
					</div>
				</div>
				
				<div class="p-8 space-y-8">
					<!-- Company Name Section -->
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<Building class="h-3 w-3" /> Basic Identity
						</h2>
						<div class="grid grid-cols-1 gap-6">
							<div>
								<label for="name" class="block text-sm font-bold text-gray-700 mb-2">Company Legal Name *</label>
								<input id="name" type="text" bind:value={form.name} required placeholder="e.g. Shalina Healthcare Ltd" 
									class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-semibold" />
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<!-- Contact Details Section -->
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<User class="h-3 w-3" /> Contact Information
						</h2>
						<div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
							<div class="sm:col-span-2">
								<label for="contact" class="block text-sm font-bold text-gray-700 mb-2">Primary Contact Person</label>
								<div class="relative">
									<User class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
									<input id="contact" type="text" bind:value={form.contact_person} placeholder="Full Name" 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all font-medium" />
								</div>
							</div>
							<div>
								<label for="phone" class="block text-sm font-bold text-gray-700 mb-2">Phone Number</label>
								<div class="relative">
									<Phone class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
									<input id="phone" type="text" bind:value={form.phone} placeholder="+234..." 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all font-medium" />
								</div>
							</div>
							<div>
								<label for="email" class="block text-sm font-bold text-gray-700 mb-2">Email Address</label>
								<div class="relative">
									<Mail class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
									<input id="email" type="email" bind:value={form.email} placeholder="supplier@company.com" 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all font-medium" />
								</div>
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<!-- Address Section -->
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<MapPin class="h-3 w-3" /> Warehouse / Office Location
						</h2>
						<div>
							<textarea bind:value={form.address} rows="3" placeholder="Full physical street address..." 
								class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all font-medium resize-none"></textarea>
						</div>
					</div>
				</div>
			</div>

			<!-- Footer Actions -->
			<div class="flex gap-4">
				<button type="button" onclick={() => history.back()} class="flex-1 px-6 py-4 bg-white border border-gray-200 text-gray-600 font-bold rounded-2xl hover:bg-gray-50 transition-all uppercase tracking-widest text-xs">
					Cancel
				</button>
				<button type="submit" disabled={loading || !form.name} 
					class="flex-1 px-6 py-4 bg-indigo-600 text-white font-black rounded-2xl hover:bg-indigo-700 transition-all shadow-lg shadow-indigo-100 uppercase tracking-widest text-xs disabled:opacity-50 flex items-center justify-center gap-2">
					<Save class="h-4 w-4" /> {loading ? 'Registering...' : 'Register Supplier'}
				</button>
			</div>
		</form>
	</div>
</div>
