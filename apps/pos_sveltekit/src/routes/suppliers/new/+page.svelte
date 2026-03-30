<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, AlertCircle, Building, Phone, Mail, MapPin, User } from 'lucide-svelte';

	let loading = $state(false);
	let tenantId = $state('');
	let error = $state('');
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

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!form.name) { error = 'Company name is required'; return; }
		if (!tenantId) { error = 'User session error: Tenant ID not found. Please refresh.'; return; }
		loading = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('suppliers').insert([{ ...form, tenant_id: tenantId }]);
			if (dbErr) throw dbErr;
			goto('/suppliers');
		} catch (err: any) {
			error = err.message || 'Failed to save supplier';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>Add Supplier – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/suppliers" class="p-2 hover:bg-gray-100 rounded-lg transition-colors">
			<ArrowLeft class="h-5 w-5 text-gray-600" />
		</a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Add New Supplier</h1>
			<p class="text-sm text-gray-500">Fill in supplier details below</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-5">
		<!-- Basic Identity -->
		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500 flex items-center gap-2">
				<Building class="h-3.5 w-3.5" /> Basic Identity
			</h2>
			<div>
				<label for="sup_name" class="block text-sm font-medium text-gray-700 mb-1">Company Legal Name <span class="text-red-500">*</span></label>
				<input id="sup_name" type="text" bind:value={form.name} required placeholder="e.g. Shalina Healthcare Ltd"
					class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
			</div>
		</div>

		<!-- Contact Information -->
		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500 flex items-center gap-2">
				<User class="h-3.5 w-3.5" /> Contact Information
			</h2>
			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				<div class="sm:col-span-2">
					<label for="sup_contact" class="block text-sm font-medium text-gray-700 mb-1">Primary Contact Person</label>
					<div class="relative">
						<User class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
						<input id="sup_contact" type="text" bind:value={form.contact_person} placeholder="Full Name"
							class="w-full pl-9 pr-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
				<div>
					<label for="sup_phone" class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
					<div class="relative">
						<Phone class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
						<input id="sup_phone" type="text" bind:value={form.phone} placeholder="+234..."
							class="w-full pl-9 pr-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
				<div>
					<label for="sup_email" class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
					<div class="relative">
						<Mail class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
						<input id="sup_email" type="email" bind:value={form.email} placeholder="supplier@company.com"
							class="w-full pl-9 pr-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
			</div>
		</div>

		<!-- Warehouse / Office Location -->
		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500 flex items-center gap-2">
				<MapPin class="h-3.5 w-3.5" /> Warehouse / Office Location
			</h2>
			<div>
				<label for="sup_address" class="block text-sm font-medium text-gray-700 mb-1">Physical Address</label>
				<textarea id="sup_address" bind:value={form.address} rows="3" placeholder="Full physical street address..."
					class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
			</div>
		</div>

		<div class="flex gap-3">
			<a href="/suppliers" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
				Cancel
			</a>
			<button type="submit" disabled={loading} class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
				<Save class="h-4 w-4" />{loading ? 'Saving...' : 'Save Supplier'}
			</button>
		</div>
	</form>
</div>
