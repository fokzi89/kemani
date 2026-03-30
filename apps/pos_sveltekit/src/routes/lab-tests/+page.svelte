<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Search, Plus, FlaskConical, Edit, Trash2, Microscope, TestTube2, AlertCircle } from 'lucide-svelte';

	let labTests = $state<any[]>([]);
	let filtered = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let tenantId = $state('');
	let categories = $state<string[]>([]);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: user } = await supabase.from('users')
			.select('tenant_id')
			.eq('id', session.user.id)
			.single();
			
		if (user?.tenant_id) { 
			tenantId = user.tenant_id; 
			await loadLabTests(); 
		}
		loading = false;
	});

	async function loadLabTests() {
		if (!tenantId) return;
		const { data, error } = await supabase.from('products')
			.select('*')
			.eq('tenant_id', tenantId)
			.eq('product_type', 'Laboratory test')
			.order('name');
		
		if (error) {
			console.error('Failed to load lab tests:', error);
			return;
		}
		labTests = data || [];
		categories = [...new Set(labTests.map(t => t.category).filter(Boolean))];
		applyFilter();
	}

	function applyFilter() {
		if (!searchQuery) {
			filtered = labTests;
		} else {
			filtered = labTests.filter(t => 
				t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
				(t.category && t.category.toLowerCase().includes(searchQuery.toLowerCase()))
			);
		}
	}

	function openAddModal() {
		goto('/lab-tests/new');
	}

	function openEditModal(test: any) {
		goto(`/lab-tests/${test.id}/edit`);
	}

	async function handleDelete(id: string) {
		if (!confirm('Are you sure you want to delete this lab test?')) return;
		const { error } = await supabase.from('products').delete().eq('id', id);
		if (error) {
			alert('Cannot delete test. It might be referenced by patient records or inventory.');
		} else {
			await loadLabTests();
		}
	}

	$effect(() => { searchQuery; applyFilter(); });
</script>

<svelte:head><title>Lab Tests – Kemani POS</title></svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Lab Test Catalog</h1>
			<p class="text-sm text-gray-500 mt-1">Manage available laboratory investigations and sample requirements</p>
		</div>
		<button 
			onclick={openAddModal}
			class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm shadow-sm hover:shadow-indigo-100"
		>
			<Plus class="h-4 w-4" /> Register New Test
		</button>
	</div>

	<!-- Stats Quick View -->
	<div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
		<div class="bg-white p-4 rounded-xl border flex items-center gap-4 shadow-sm">
			<div class="h-10 w-10 bg-indigo-50 rounded-lg flex items-center justify-center text-indigo-600"><FlaskConical class="h-5 w-5" /></div>
			<div><p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Total Investigations</p><p class="text-lg font-bold text-gray-900">{labTests.length}</p></div>
		</div>
		<div class="bg-white p-4 rounded-xl border flex items-center gap-4 shadow-sm">
			<div class="h-10 w-10 bg-purple-50 rounded-lg flex items-center justify-center text-purple-600"><Microscope class="h-5 w-5" /></div>
			<div><p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Active Services</p><p class="text-lg font-bold text-gray-900">{labTests.filter(t => t.is_active).length}</p></div>
		</div>
		<div class="bg-white p-4 rounded-xl border flex items-center gap-4 shadow-sm">
			<div class="h-10 w-10 bg-green-50 rounded-lg flex items-center justify-center text-green-600"><TestTube2 class="h-5 w-5" /></div>
			<div><p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Categories</p><p class="text-lg font-bold text-gray-900">{categories.length}</p></div>
		</div>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-xl border p-4 shadow-sm">
		<div class="relative max-w-md">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input 
				type="text" 
				bind:value={searchQuery} 
				placeholder="Search investigations by name or category..." 
				class="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 transition-all text-sm"
			/>
		</div>
	</div>

	<!-- Results Table -->
	<div class="bg-white rounded-xl border shadow-sm overflow-hidden">
		{#if loading}
			<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
		{:else if filtered.length === 0}
			<div class="p-16 text-center text-gray-400">
				<FlaskConical class="h-12 w-12 mx-auto mb-3 opacity-20" />
				<p class="font-medium text-gray-600">No laboratory investigations found</p>
				<button onclick={openAddModal} class="mt-3 text-sm text-indigo-600 hover:underline font-medium">Add your first lab test</button>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-sm">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-6 py-4 text-left font-bold text-gray-600 uppercase tracking-wider text-[10px]">Investigation Name</th>
							<th class="px-6 py-4 text-left font-bold text-gray-600 uppercase tracking-wider text-[10px]">Category</th>
							<th class="px-6 py-4 text-left font-bold text-gray-600 uppercase tracking-wider text-[10px]">Sample Requirement</th>
							<th class="px-6 py-4 text-left font-bold text-gray-600 uppercase tracking-wider text-[10px]">Status</th>
							<th class="px-6 py-4 text-right font-bold text-gray-600 uppercase tracking-wider text-[10px]">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each filtered as test}
							<tr class="hover:bg-gray-50 transition-colors group">
								<td class="px-6 py-4">
									<div class="font-semibold text-gray-900 leading-tight">{test.name}</div>
									<div class="text-[10px] text-gray-400 mt-0.5 line-clamp-1 max-w-xs">{test.description || 'No description provided'}</div>
								</td>
								<td class="px-6 py-4">
									<span class="px-2.5 py-1 bg-indigo-50 text-indigo-700 rounded-md text-[10px] font-bold uppercase">{test.category || 'General'}</span>
								</td>
								<td class="px-6 py-4 text-gray-500">
									<div class="flex items-center gap-2">
										<TestTube2 class="h-4 w-4 text-gray-400" />
										{test.sample_type || 'N/A'}
									</div>
								</td>
								<td class="px-6 py-4">
									{#if test.is_active}
										<span class="inline-flex items-center gap-1.5 px-2 py-1 bg-green-50 text-green-700 rounded-full text-[10px] font-bold">
											<div class="h-1.5 w-1.5 bg-green-500 rounded-full"></div> Available
										</span>
									{:else}
										<span class="inline-flex items-center gap-1.5 px-2 py-1 bg-red-50 text-red-700 rounded-full text-[10px] font-bold">
											<div class="h-1.5 w-1.5 bg-red-500 rounded-full"></div> Suspended
										</span>
									{/if}
								</td>
								<td class="px-6 py-4 text-right">
									<div class="flex items-center justify-end gap-1">
										<button onclick={() => openEditModal(test)} class="p-2 hover:bg-white hover:shadow-sm border border-transparent hover:border-gray-100 rounded-lg text-gray-400 hover:text-indigo-600 transition-all"><Edit class="h-4 w-4" /></button>
										<button onclick={() => handleDelete(test.id)} class="p-2 hover:bg-white hover:shadow-sm border border-transparent hover:border-gray-100 rounded-lg text-gray-400 hover:text-red-600 transition-all"><Trash2 class="h-4 w-4" /></button>
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</div>
</div>
