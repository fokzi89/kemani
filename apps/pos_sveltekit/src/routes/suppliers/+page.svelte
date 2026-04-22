<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { Search, Plus, Truck, Edit, Trash2, Phone, Mail, MapPin } from 'lucide-svelte';

	let suppliers = $state<any[]>([]);
	let filtered = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let tenantId = $state('');

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: user } = await supabase.from('users')
			.select('tenant_id')
			.eq('id', session.user.id)
			.single();
			
		if (user?.tenant_id) { 
			tenantId = user.tenant_id; 
			await loadSuppliers(); 
		}
		loading = false;
	});

	async function loadSuppliers() {
		if (!tenantId) return;
		const { data, error } = await supabase.from('suppliers')
			.select('*')
			.eq('tenant_id', tenantId)
			.order('name');
		
		if (error) {
			console.error('Failed to load suppliers:', error);
			return;
		}
		suppliers = data || [];
		applyFilter();
	}

	function applyFilter() {
		if (!searchQuery) {
			filtered = suppliers;
		} else {
			filtered = suppliers.filter(s => 
				s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
				(s.contact_person && s.contact_person.toLowerCase().includes(searchQuery.toLowerCase()))
			);
		}
	}

	function openAddModal() {
		goto('/suppliers/new');
	}

	function openEditModal(supplier: any) {
		goto(`/suppliers/${supplier.id}/edit`);
	}

	async function handleDelete(id: string) {
		if (!confirm('Are you sure you want to delete this supplier?')) return;
		const { error } = await supabase.from('suppliers').delete().eq('id', id);
		if (error) {
			alert('Cannot delete supplier. It might be referenced by inventory records.');
		} else {
			await loadSuppliers();
		}
	}

	$effect(() => { searchQuery; applyFilter(); });
</script>

<svelte:head><title>Suppliers – Kemani POS</title></svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Suppliers</h1>
			<p class="text-sm text-gray-500 mt-1">Manage your procurement vendors and contact details</p>
		</div>
		<button 
			onclick={openAddModal}
			class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm shadow-sm"
		>
			<Plus class="h-4 w-4" /> Add Supplier
		</button>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-xl border p-4 shadow-sm">
		<div class="relative max-w-md">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input 
				type="text" 
				bind:value={searchQuery} 
				placeholder="Search suppliers by name or contact..." 
				class="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
			/>
		</div>
	</div>

	<!-- Supplier Grid -->
	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else if filtered.length === 0}
		<div class="bg-white rounded-xl border p-12 text-center text-gray-400">
			<Truck class="h-12 w-12 mx-auto mb-3 opacity-20" />
			<p class="font-medium text-gray-600">No suppliers found</p>
			<button onclick={openAddModal} class="mt-3 text-sm text-indigo-600 hover:underline">Register your first supplier</button>
		</div>
	{:else}
		<div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
			<div class="overflow-x-auto">
				<table class="w-full text-left whitespace-nowrap min-w-[800px]">
					<thead class="bg-gray-50/80 border-b border-gray-100">
						<tr>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Supplier Name</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Contact Details</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider min-w-[200px]">Address</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each filtered as supplier}
							<tr class="hover:bg-indigo-50/30 transition-colors group">
								<!-- Supplier Name & Contact Person -->
								<td class="px-6 py-4">
									<div class="flex items-center gap-3">
										<div class="h-10 w-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-600 shrink-0">
											<Truck class="h-4 w-4" />
										</div>
										<div>
											<p class="font-bold text-gray-900 text-sm">{supplier.name}</p>
											{#if supplier.contact_person}
												<p class="text-[11px] text-gray-500 font-medium uppercase mt-0.5 tracking-wider">{supplier.contact_person}</p>
											{/if}
										</div>
									</div>
								</td>

								<!-- Phone & Email -->
								<td class="px-6 py-4">
									<div class="space-y-1">
										{#if supplier.email}
											<div class="flex items-center gap-1.5 text-xs text-gray-600">
												<Mail class="h-3 w-3 text-gray-400 shrink-0" />
												<span class="truncate">{supplier.email}</span>
											</div>
										{/if}
										{#if supplier.phone}
											<div class="flex items-center gap-1.5 text-xs text-gray-500">
												<Phone class="h-3 w-3 text-gray-400 shrink-0" />
												<span>{supplier.phone}</span>
											</div>
										{/if}
										{#if !supplier.email && !supplier.phone}
											<span class="text-xs text-gray-400 italic">No contact details</span>
										{/if}
									</div>
								</td>

								<!-- Address -->
								<td class="px-6 py-4 align-top whitespace-normal">
									{#if supplier.address}
										<div class="flex items-start gap-1.5 text-xs text-gray-600 max-w-sm">
											<MapPin class="h-3.5 w-3.5 mt-0.5 text-gray-400 shrink-0" />
											<span class="line-clamp-2">{supplier.address}</span>
										</div>
									{:else}
										<span class="text-xs text-gray-400 italic">No address provided</span>
									{/if}
								</td>

								<!-- Actions -->
								<td class="px-6 py-4 text-right">
									<div class="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
										<button 
											onclick={() => openEditModal(supplier)} 
											class="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
											title="Edit Supplier"
										>
											<Edit class="h-4 w-4" />
										</button>
										<button 
											onclick={() => handleDelete(supplier.id)} 
											class="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
											title="Delete Supplier"
										>
											<Trash2 class="h-4 w-4" />
										</button>
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</div>
	{/if}
</div>
