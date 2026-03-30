<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { Truck, Save, ArrowLeft, Building, Phone, Mail, MapPin, User, Trash2 } from 'lucide-svelte';

	let loading = $state(false);
	let supplierId = $page.params.id;
	let form = $state({
		name: '',
		contact_person: '',
		email: '',
		phone: '',
		address: ''
	});

	onMount(async () => {
		const { data, error } = await supabase.from('suppliers').select('*').eq('id', supplierId).single();
		if (data) {
			form = {
				name: data.name,
				contact_person: data.contact_person || '',
				email: data.email || '',
				phone: data.phone || '',
				address: data.address || ''
			};
		}
	});

	async function handleSave() {
		if (!form.name) return;
		loading = true;
		try {
			const { error } = await supabase.from('suppliers').update(form).eq('id', supplierId);
			if (error) throw error;
			goto('/suppliers');
		} catch (err: any) {
			alert(err.message || 'Failed to update supplier');
		} finally {
			loading = false;
		}
	}

	async function handleDelete() {
		if (!confirm('Are you sure you want to delete this supplier?')) return;
		const { error } = await supabase.from('suppliers').delete().eq('id', supplierId);
		if (error) {
			alert('Cannot delete supplier. It may be referenced by inventory.');
		} else {
			goto('/suppliers');
		}
	}
</script>

<svelte:head><title>Edit Supplier – Kemani POS</title></svelte:head>

<div class="min-h-screen bg-gray-50/50 p-6">
	<div class="max-w-3xl mx-auto space-y-6">
		<div class="flex items-center justify-between">
			<button onclick={() => goto('/suppliers')} class="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors font-medium">
				<ArrowLeft class="h-4 w-4" /> Back to Suppliers
			</button>
			<button onclick={handleDelete} class="p-2.5 bg-red-50 text-red-600 border border-red-200 rounded-xl hover:bg-red-100 shadow-sm transition-all flex items-center gap-2 font-bold text-xs uppercase">
				<Trash2 class="h-4 w-4" /> Delete Supplier
			</button>
		</div>

		<form onsubmit={(e) => { e.preventDefault(); handleSave(); }} class="space-y-6">
			<div class="bg-white rounded-2xl border shadow-sm overflow-hidden border-orange-200 shadow-orange-50/50">
				<div class="bg-orange-600 p-6 text-white flex items-center gap-5">
					<div class="h-16 w-16 bg-white/20 backdrop-blur-md rounded-2xl flex items-center justify-center border border-white/30">
						<Truck class="h-8 w-8" />
					</div>
					<div>
						<h1 class="text-2xl font-black">Edit Supplier Profile</h1>
						<p class="text-orange-100 text-sm">{form.name || 'Managing corporate details'}</p>
					</div>
				</div>
				
				<div class="p-8 space-y-8">
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<Building class="h-3 w-3" /> Basic Identity
						</h2>
						<div class="grid grid-cols-1 gap-6">
							<div>
								<label for="name" class="block text-sm font-bold text-gray-700 mb-2">Company Legal Name *</label>
								<input id="name" type="text" bind:value={form.name} required 
									class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500 outline-none transition-all font-semibold" />
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<User class="h-3 w-3" /> Contact Information
						</h2>
						<div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
							<div class="sm:col-span-2">
								<label for="contact" class="block text-sm font-bold text-gray-700 mb-2">Primary Contact Person</label>
								<div class="relative">
									<User class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
									<input id="contact" type="text" bind:value={form.contact_person} 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-orange-500/10 transition-all font-medium" />
								</div>
							</div>
							<div>
								<label for="phone" class="block text-sm font-bold text-gray-700 mb-2">Phone Number</label>
								<div class="relative">
									<Phone class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
									<input id="phone" type="text" bind:value={form.phone} 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-orange-500/10 transition-all font-medium" />
								</div>
							</div>
							<div>
								<label for="email" class="block text-sm font-bold text-gray-700 mb-2">Email Address</label>
								<div class="relative">
									<Mail class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
									<input id="email" type="email" bind:value={form.email} 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-orange-500/10 transition-all font-medium" />
								</div>
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<MapPin class="h-3 w-3" /> Warehouse / Office Location
						</h2>
						<div>
							<textarea bind:value={form.address} rows="3" 
								class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-orange-500/10 transition-all font-medium resize-none"></textarea>
						</div>
					</div>
				</div>
			</div>

			<div class="flex gap-4">
				<button type="button" onclick={() => goto('/suppliers')} class="flex-1 px-6 py-4 bg-white border border-gray-200 text-gray-600 font-bold rounded-2xl hover:bg-gray-50 transition-all uppercase tracking-widest text-xs">
					Cancel
				</button>
				<button type="submit" disabled={loading || !form.name} 
					class="flex-1 px-6 py-4 bg-orange-600 text-white font-black rounded-2xl hover:bg-orange-700 transition-all shadow-lg shadow-orange-100 uppercase tracking-widest text-xs disabled:opacity-50 flex items-center justify-center gap-2">
					<Save class="h-4 w-4" /> {loading ? 'Updating...' : 'Update Supplier Profile'}
				</button>
			</div>
		</form>
	</div>
</div>
