<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, Trash2, AlertCircle } from 'lucide-svelte';

	const customerId = $page.params.id;
	let loading = $state(true);
	let saving = $state(false);
	let error = $state('');
	let form = $state({ first_name: '', last_name: '', email: '', phone: '', address: '', date_of_birth: '', notes: '' });

	onMount(async () => {
		const { data } = await supabase.from('customers').select('*').eq('id', customerId).single();
		if (data) {
			form = {
				first_name: data.first_name || '', last_name: data.last_name || '',
				email: data.email || '', phone: data.phone || '',
				address: data.address || '', date_of_birth: data.date_of_birth || '',
				notes: data.notes || ''
			};
		}
		loading = false;
	});

	async function handleSave(e: Event) {
		e.preventDefault();
		saving = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('customers').update({
				first_name: form.first_name, last_name: form.last_name || null,
				email: form.email || null, phone: form.phone || null,
				address: form.address || null, date_of_birth: form.date_of_birth || null,
				notes: form.notes || null
			}).eq('id', customerId);
			if (dbErr) throw dbErr;
			goto(`/customers/${customerId}`);
		} catch (err: any) {
			error = err.message || 'Failed to save';
		} finally { saving = false; }
	}

	async function handleDelete() {
		if (!confirm('Delete this customer? This cannot be undone.')) return;
		await supabase.from('customers').delete().eq('id', customerId);
		goto('/customers');
	}
</script>

<svelte:head><title>Edit Customer – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/customers/{customerId}" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
		<h1 class="text-xl font-bold text-gray-900">Edit Customer</h1>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else}
		<form onsubmit={handleSave} class="space-y-5">
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Personal Info</h2>
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">First Name *</label>
						<input type="text" bind:value={form.first_name} required class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
						<input type="text" bind:value={form.last_name} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
						<input type="tel" bind:value={form.phone} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
						<input type="email" bind:value={form.email} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Date of Birth</label>
						<input type="date" bind:value={form.date_of_birth} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="col-span-2">
						<label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
						<input type="text" bind:value={form.address} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="col-span-2">
						<label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
						<textarea bind:value={form.notes} rows="2" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
					</div>
				</div>
			</div>
			<div class="flex gap-3">
				<button type="button" onclick={handleDelete} class="flex items-center gap-2 px-4 py-2.5 border border-red-300 text-red-600 font-medium rounded-xl hover:bg-red-50 transition-colors text-sm">
					<Trash2 class="h-4 w-4" /> Delete
				</button>
				<a href="/customers/{customerId}" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">Cancel</a>
				<button type="submit" disabled={saving} class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
					<Save class="h-4 w-4" />{saving ? 'Saving...' : 'Save Changes'}
				</button>
			</div>
		</form>
	{/if}
</div>
