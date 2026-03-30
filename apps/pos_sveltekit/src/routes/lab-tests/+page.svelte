<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Search, Plus, FlaskConical, Edit, Trash2, Microscope, TestTube2, AlertCircle } from 'lucide-svelte';

	let labTests = $state<any[]>([]);
	let filtered = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let tenantId = $state('');

	// Modal state
	let showModal = $state(false);
	let editingTest = $state<any>(null);
	let form = $state({
		name: '',
		category: '',
		description: '',
		sample_type: '',
		is_active: true,
		product_type: 'Laboratory test'
	});
	let saving = $state(false);
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

	function resetForm() {
		form = { 
			name: '', 
			category: '', 
			description: '', 
			sample_type: '', 
			is_active: true,
			product_type: 'Laboratory test'
		};
		editingTest = null;
	}

	function openAddModal() {
		resetForm();
		showModal = true;
	}

	function openEditModal(test: any) {
		editingTest = test;
		form = {
			name: test.name,
			category: test.category || '',
			description: test.description || '',
			sample_type: test.sample_type || '',
			is_active: test.is_active ?? true,
			product_type: 'Laboratory test'
		};
		showModal = true;
	}

	async function handleSave() {
		if (!form.name || !tenantId) return;
		saving = true;
		try {
			if (editingTest) {
				const { error } = await supabase.from('products')
					.update(form)
					.eq('id', editingTest.id);
				if (error) throw error;
			} else {
				const { error } = await supabase.from('products')
					.insert([{ ...form, tenant_id: tenantId }]);
				if (error) throw error;
			}
			await loadLabTests();
			showModal = false;
		} catch (err: any) {
			alert(err.message || 'Failed to save test');
		} finally {
			saving = false;
		}
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

<!-- Modal -->
{#if showModal}
	<div class="fixed inset-0 bg-black/40 backdrop-blur-[2px] z-50 flex items-center justify-center p-4">
		<div class="bg-white rounded-3xl w-full max-w-xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
			<div class="h-2 bg-indigo-600"></div>
			<div class="p-8">
				<div class="flex items-start justify-between mb-8">
					<div class="h-14 w-14 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm border border-indigo-100">
						<FlaskConical class="h-7 w-7" />
					</div>
					<div class="text-right">
						<h2 class="text-2xl font-black text-gray-900">{editingTest ? 'Edit Investigation' : 'New Lab Test'}</h2>
						<p class="text-sm text-gray-400">Laboratory Catalog Management</p>
					</div>
				</div>
				
				<div class="space-y-6">
					<div>
						<label class="block text-xs font-bold text-gray-500 uppercase tracking-widest mb-2">Investigation Name</label>
						<input type="text" bind:value={form.name} placeholder="e.g. Malaria Parasite (MP), Fasting Blood Sugar" 
							class="w-full px-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-semibold" />
					</div>
					
					<div class="grid grid-cols-2 gap-6">
						<div>
							<label class="block text-xs font-bold text-gray-500 uppercase tracking-widest mb-2">Category</label>
							<select bind:value={form.category} class="w-full px-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 outline-none font-semibold">
								<option value="">Select Category</option>
								<option value="Hematology">Hematology</option>
								<option value="Biochemistry">Biochemistry</option>
								<option value="Microbiology">Microbiology</option>
								<option value="Serology">Serology</option>
								<option value="Endocrinology">Endocrinology</option>
							</select>
						</div>
						<div>
							<label class="block text-xs font-bold text-gray-500 uppercase tracking-widest mb-2">Sample Required</label>
							<input type="text" bind:value={form.sample_type} placeholder="e.g. Whole Blood, Urine" 
								class="w-full px-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl font-semibold outline-none focus:ring-4 focus:ring-indigo-500/10" />
						</div>
					</div>

					<div>
						<label class="block text-xs font-bold text-gray-500 uppercase tracking-widest mb-2">Description / Notes</label>
						<textarea bind:value={form.description} rows="3" placeholder="Additional details or patient preparation instructions..." 
							class="w-full px-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl font-semibold outline-none focus:ring-4 focus:ring-indigo-500/10 resize-none"></textarea>
					</div>

					<label class="flex items-center gap-4 p-4 bg-gray-50 rounded-2xl cursor-pointer hover:bg-gray-100 transition-colors border border-gray-100">
						<input type="checkbox" bind:checked={form.is_active} class="w-5 h-5 text-indigo-600 rounded-lg border-gray-300 pointer-events-none" />
						<div class="flex-1">
							<p class="text-sm font-bold text-gray-800">Investigation is Active</p>
							<p class="text-[10px] text-gray-400 uppercase tracking-wider font-bold">Allow this test to be ordered in POS</p>
						</div>
					</label>
				</div>

				<div class="mt-8 flex gap-3">
					<button onclick={() => showModal = false} class="flex-1 py-4 bg-gray-100 hover:bg-gray-200 text-gray-600 font-black rounded-2xl transition-all uppercase tracking-widest text-xs">Cancel</button>
					<button 
						onclick={handleSave} 
						disabled={saving || !form.name} 
						class="flex-1 py-4 bg-indigo-600 hover:bg-indigo-700 text-white font-black rounded-2xl transition-all shadow-lg shadow-indigo-100 uppercase tracking-widest text-xs disabled:opacity-50"
					>
						{saving ? 'Processing...' : 'Save Investigation'}
					</button>
				</div>
			</div>
		</div>
	</div>
{/if}
