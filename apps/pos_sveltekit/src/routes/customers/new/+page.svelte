<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, AlertCircle } from 'lucide-svelte';

	let tenantId = $state('');
	let loading = $state(false);
	let error = $state('');
	let form = $state({
		first_name: '', last_name: '', email: '', phone: '',
		address: '', date_of_birth: '', notes: ''
	});

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) tenantId = user.tenant_id;
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!form.first_name) { error = 'First name is required'; return; }
		loading = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('customers').insert({
				tenant_id: tenantId,
				first_name: form.first_name, last_name: form.last_name || null,
				email: form.email || null, phone: form.phone || null,
				address: form.address || null,
				date_of_birth: form.date_of_birth || null,
				notes: form.notes || null,
				loyalty_points: 0, total_spent: 0
			});
			if (dbErr) throw dbErr;
			goto('/customers');
		} catch (err: any) {
			error = err.message || 'Failed to create customer';
		} finally { loading = false; }
	}
</script>

<svelte:head><title>New Customer – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/customers" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Add New Customer</h1>
			<p class="text-sm text-gray-500">Fill in customer details below</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-5">
		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Personal Info</h2>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">First Name <span class="text-red-500">*</span></label>
					<input type="text" bind:value={form.first_name} required placeholder="John" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
					<input type="text" bind:value={form.last_name} placeholder="Doe" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
					<input type="tel" bind:value={form.phone} placeholder="+234 800 000 0000" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
					<input type="email" bind:value={form.email} placeholder="john@example.com" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Date of Birth</label>
					<input type="date" bind:value={form.date_of_birth} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div class="col-span-2">
					<label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
					<input type="text" bind:value={form.address} placeholder="Street, City, State" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div class="col-span-2">
					<label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
					<textarea bind:value={form.notes} rows="2" placeholder="Any relevant notes..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
				</div>
			</div>
		</div>

		<div class="flex gap-3">
			<a href="/customers" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">Cancel</a>
			<button type="submit" disabled={loading} class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
				<Save class="h-4 w-4" />{loading ? 'Saving...' : 'Save Customer'}
			</button>
		</div>
	</form>
</div>
