<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, AlertCircle, Plus, Image as ImageIcon } from 'lucide-svelte';
	import FileUpload from '$lib/components/FileUpload.svelte';

	let tenantId = $state('');
	let loading = $state(false);
	let error = $state('');
	let form = $state({
		product_type: 'Grocery',
		name: '', barcode: '', description: '', category: '',
		is_active: true,
		// Healthcare fields
		generic_name: '', strength: '', dosage_form: '', 
		treatment_class: '', manufacturer: '',
		test_name: '', sample_type: ''
	});
	let file = $state<File | null>(null);
	let previewUrl = $state('');
	let productNames = $state<string[]>([]);
	let showNameDropdown = $state(false);
	
	async function fetchProductNames() {
		const { data } = await supabase.from('products').select('name');
		productNames = (data || []).map(p => p.name);
	}

	let filteredNames = $derived(
		form.name.length > 1
			? productNames.filter(n => n.toLowerCase().includes(form.name.toLowerCase()) && n !== form.name)
			: []
	);

	function selectName(name: string) {
		form.name = name;
		showNameDropdown = false;
	}
	let showCategoryModal = $state(false);
	let categoryLoading = $state(false);
	let categoryForm = $state({ name: '' });
	
	let categories = $state<any[]>([]);
	let categorySearch = $state('');
	let showCategoryDropdown = $state(false);

	async function fetchCategories() {
		const { data } = await supabase.from('categories').select('id, name').order('name');
		categories = data || [];
	}

	let filteredCategories = $derived(
		categorySearch 
			? categories.filter(c => c.name.toLowerCase().includes(categorySearch.toLowerCase()))
			: categories
	);

	function selectCategory(name: string) {
		form.category = name;
		categorySearch = name;
		showCategoryDropdown = false;
	}

	function handleCategoryInput(e: any) {
		categorySearch = e.target.value;
		form.category = categorySearch;
		showCategoryDropdown = true;
	}

	async function handleAddCategory(e: Event) {
		e.preventDefault();
		if (!categoryForm.name) return;
		categoryLoading = true;
		try {
			const { data, error: dbErr } = await supabase.from('categories').insert({
				name: categoryForm.name
			}).select('name').single();

			if (dbErr) throw dbErr;
			await fetchCategories();
			selectCategory(data.name);
			categoryForm = { name: '' };
			showCategoryModal = false;
		} catch (err: any) {
			alert(err.message || 'Failed to add category');
		} finally {
			categoryLoading = false;
		}
	}

	function handleOutsideClick(e: MouseEvent) {
		const target = e.target as HTMLElement;
		if (!target.closest('.relative')) {
			showCategoryDropdown = false;
		}
	}

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) tenantId = user.tenant_id;
		
		await fetchCategories();
		await fetchProductNames();
		window.addEventListener('click', handleOutsideClick);
	});

	onDestroy(() => {
		if (typeof window !== 'undefined') {
			window.removeEventListener('click', handleOutsideClick);
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!tenantId) { error = 'User session error: Tenant ID not found. Please refresh.'; return; }
		if (!form.name) { error = 'Product name is required'; return; }
		
		loading = true; error = '';
		try {
			// Duplicate check
			const { data: existing } = await supabase.from('products')
				.select('id')
				.ilike('name', form.name)
				.single();
			
			if (existing) {
				error = `A product with the name "${form.name}" already exists in the catalog.`;
				loading = false;
				return;
			}

			const { error: dbErr } = await supabase.from('products').insert({
				name: form.name,
				barcode: form.barcode || null,
				description: form.description || form.treatment_class || null,
				category: form.category || null,
				is_active: form.is_active,
				product_type: form.product_type,
				generic_name: form.generic_name || null,
				strength: form.strength || null,
				dosage_form: form.dosage_form || null,
				sample_type: form.sample_type || null,
				manufacturer: form.manufacturer || null,
				image_url: null
			});

			if (dbErr) throw dbErr;

			// 2. Upload image if selected
			if (file) {
				const { data: productData, error: fetchErr } = await supabase.from('products').select('id').ilike('name', form.name).single();
				if (productData) {
					const fileExt = file.name.split('.').pop();
					const fileName = `${productData.id}-${Date.now()}.${fileExt}`;
					
					const { error: uploadErr } = await supabase.storage.from('product-images').upload(fileName, file);
					if (uploadErr) throw uploadErr;

					const { data: { publicUrl } } = supabase.storage.from('product-images').getPublicUrl(fileName);
					await supabase.from('products').update({ image_url: publicUrl }).eq('id', productData.id);
				}
			}
			goto('/products');
		} catch (err: any) {
			error = err.message || 'Failed to create product';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>New Product – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/products" class="p-2 hover:bg-gray-100 rounded-lg transition-colors"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Add New Product</h1>
			<p class="text-sm text-gray-500">Fill in product details below</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-5">
		<div class="bg-white rounded-xl border p-5 space-y-4">
			<div class="flex items-center justify-between">
				<h2 class="font-semibold text-gray-900 text-sm uppercase tracking-wider text-gray-500">Basic Info</h2>
				<div class="flex items-center gap-2">
					<label for="product_type_select" class="text-xs font-bold text-gray-400 uppercase tracking-widest">Type:</label>
					<select id="product_type_select" bind:value={form.product_type} class="text-xs font-bold bg-gray-50 border border-gray-200 rounded-lg px-2 py-1 outline-none focus:ring-2 focus:ring-indigo-500">
						<option value="Grocery">Grocery</option>
						<option value="Drug">Drug</option>
						<option value="Laboratory test">Laboratory test</option>
					</select>
				</div>
			</div>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				{#if form.product_type === 'Drug'}
					<!-- Drug Specific Fields -->
					<div class="sm:col-span-2 relative">
						<label for="drug_name" class="block text-sm font-medium text-gray-700 mb-1">Product Name <span class="text-red-500">*</span></label>
						<input 
							id="drug_name" 
							type="text" 
							bind:value={form.name} 
							onfocus={() => showNameDropdown = true}
							required 
							placeholder="e.g. Paracetamol 500mg" 
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" 
						/>
						{#if showNameDropdown && filteredNames.length > 0}
							<div class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-48 overflow-y-auto py-1">
								{#each filteredNames as name}
									<button 
										type="button" 
										onclick={() => selectName(name)}
										class="w-full text-left px-4 py-2 text-sm hover:bg-amber-50 transition-colors"
									>
										{name}
									</button>
								{/each}
							</div>
						{/if}
					</div>
					<div>
						<label for="generic_name" class="block text-sm font-medium text-gray-700 mb-1">Generic Name</label>
						<input id="generic_name" type="text" bind:value={form.generic_name} placeholder="e.g. Acetaminophen" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label for="strength" class="block text-sm font-medium text-gray-700 mb-1">Strength</label>
						<input id="strength" type="text" bind:value={form.strength} placeholder="e.g. 500mg" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label for="dosage_form" class="block text-sm font-medium text-gray-700 mb-1">Dosage form</label>
						<input id="dosage_form" type="text" bind:value={form.dosage_form} placeholder="e.g. Tablet, Syrup" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label for="drug_barcode" class="block text-sm font-medium text-gray-700 mb-1">Barcode</label>
						<input id="drug_barcode" type="text" bind:value={form.barcode} placeholder="e.g. PH-101" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="relative">
						<label for="drug_cat" class="block text-sm font-medium text-gray-700 mb-1">Category</label>
						<div class="flex gap-2">
							<div class="flex-1 relative">
								<input 
									id="drug_cat" 
									type="text" 
									value={categorySearch}
									oninput={handleCategoryInput}
									onfocus={() => showCategoryDropdown = true}
									placeholder="Search or select category..." 
									class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" 
								/>
								{#if showCategoryDropdown && filteredCategories.length > 0}
									<div class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-48 overflow-y-auto py-1">
										{#each filteredCategories as cat}
											<button 
												type="button"
												onclick={() => selectCategory(cat.name)}
												class="w-full text-left px-4 py-2 text-sm hover:bg-indigo-50 transition-colors"
											>
												{cat.name}
											</button>
										{/each}
									</div>
								{/if}
							</div>
							<button type="button" onclick={() => showCategoryModal = true} class="p-2.5 bg-gray-50 border border-gray-300 rounded-lg hover:bg-gray-100 transition-colors text-gray-600 self-start">
								<Plus class="h-4 w-4" />
							</button>
						</div>
					</div>
					<div class="sm:col-span-2">
						<label for="treat_class" class="block text-sm font-medium text-gray-700 mb-1">Treatment class description</label>
						<textarea id="treat_class" bind:value={form.treatment_class} rows="2" placeholder="e.g. Analgesics and antipyretics..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
					</div>

				{:else if form.product_type === 'Laboratory test'}
					<!-- Laboratory Test Fields -->
					<div class="sm:col-span-2 relative">
						<label for="test_name" class="block text-sm font-medium text-gray-700 mb-1">Test Name <span class="text-red-500">*</span></label>
						<input 
							id="test_name" 
							type="text" 
							bind:value={form.name} 
							onfocus={() => showNameDropdown = true}
							required 
							placeholder="e.g. Malaria Parasite Test" 
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" 
						/>
						{#if showNameDropdown && filteredNames.length > 0}
							<div class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-48 overflow-y-auto py-1">
								{#each filteredNames as name}
									<button 
										type="button" 
										onclick={() => selectName(name)}
										class="w-full text-left px-4 py-2 text-sm hover:bg-amber-50 transition-colors"
									>
										{name}
									</button>
								{/each}
							</div>
						{/if}
					</div>
					<div class="sm:col-span-2">
						<label for="sample_type" class="block text-sm font-medium text-gray-700 mb-1">Sample type</label>
						<input id="sample_type" type="text" bind:value={form.sample_type} placeholder="e.g. EDTA Blood, Urine" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="sm:col-span-2">
						<label for="test_desc" class="block text-sm font-medium text-gray-700 mb-1">Description</label>
						<textarea id="test_desc" bind:value={form.description} rows="2" placeholder="Clinical indication or notes..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
					</div>

				{:else}
					<!-- Standard Grocery Fields -->
					<div class="sm:col-span-2 relative">
						<label for="groc_name" class="block text-sm font-medium text-gray-700 mb-1">Product Name <span class="text-red-500">*</span></label>
						<input 
							id="groc_name" 
							type="text" 
							bind:value={form.name} 
							onfocus={() => showNameDropdown = true}
							required 
							placeholder="e.g. Whole Milk 1L" 
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" 
						/>
						{#if showNameDropdown && filteredNames.length > 0}
							<div class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-48 overflow-y-auto py-1">
								{#each filteredNames as name}
									<button 
										type="button" 
										onclick={() => selectName(name)}
										class="w-full text-left px-4 py-2 text-sm hover:bg-amber-50 transition-colors"
									>
										{name}
									</button>
								{/each}
							</div>
						{/if}
					</div>
					<div>
						<label for="groc_barcode" class="block text-sm font-medium text-gray-700 mb-1">Barcode</label>
						<input id="groc_barcode" type="text" bind:value={form.barcode} placeholder="e.g. PRD-001" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="relative">
						<label for="groc_cat" class="block text-sm font-medium text-gray-700 mb-1">Category</label>
						<div class="flex gap-2">
							<div class="flex-1 relative">
								<input 
									id="groc_cat" 
									type="text" 
									value={categorySearch}
									oninput={handleCategoryInput}
									onfocus={() => showCategoryDropdown = true}
									placeholder="Search or select category..." 
									class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" 
								/>
								{#if showCategoryDropdown && filteredCategories.length > 0}
									<div class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-48 overflow-y-auto py-1">
										{#each filteredCategories as cat}
											<button 
												type="button"
												onclick={() => selectCategory(cat.name)}
												class="w-full text-left px-4 py-2 text-sm hover:bg-indigo-50 transition-colors"
											>
												{cat.name}
											</button>
										{/each}
									</div>
								{/if}
							</div>
							<button type="button" onclick={() => showCategoryModal = true} class="p-2.5 bg-gray-50 border border-gray-300 rounded-lg hover:bg-gray-100 transition-colors text-gray-600 self-start">
								<Plus class="h-4 w-4" />
							</button>
						</div>
					</div>
					<div class="sm:col-span-2">
						<label for="groc_desc" class="block text-sm font-medium text-gray-700 mb-1">Description</label>
						<textarea id="groc_desc" bind:value={form.description} rows="2" placeholder="Optional product description..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
					</div>
				{/if}
			</div>
		</div>

		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Additional Details</h2>
			<div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
				<!-- Image Upload -->
				<div class="sm:col-span-2">
					<FileUpload 
						label="Product Image" 
						bind:file={file} 
						bind:previewUrl={previewUrl} 
						onFileSelect={() => {}} 
					/>
				</div>
				
				<div class="sm:col-span-2 relative">
					<label for="manufacturer" class="block text-sm font-medium text-gray-700 mb-1">Manufacturer / Producing Company</label>
					<input id="manufacturer" type="text" bind:value={form.manufacturer} placeholder="e.g. Pfizer, Nestle, Emzor" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
			</div>
			<div class="pt-2">
				<label class="flex items-center gap-3 cursor-pointer">
					<input type="checkbox" bind:checked={form.is_active} class="w-4 h-4 text-indigo-600 rounded border-gray-300 focus:ring-indigo-500" />
					<span class="text-sm font-medium text-gray-700">Product is active and visible in catalog</span>
				</label>
			</div>
		</div>

		<div class="flex gap-3">
			<a href="/products" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
				Cancel
			</a>
			<button type="submit" disabled={loading} class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
				<Save class="h-4 w-4" />{loading ? 'Saving...' : 'Save Product'}
			</button>
		</div>
	</form>

	{#if showCategoryModal}
		<div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto">
			<div class="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl transform transition-all">
				<div class="flex items-center justify-between mb-6">
					<div>
						<h3 class="text-lg font-bold text-gray-900">Add New Category</h3>
						<p class="text-xs text-gray-500">Create a classification for products</p>
					</div>
					<button type="button" onclick={() => showCategoryModal = false} class="p-2 hover:bg-gray-100 rounded-lg transition-colors text-gray-400">
						<Plus class="h-5 w-5 rotate-45" />
					</button>
				</div>

				<form onsubmit={handleAddCategory} class="space-y-4">
					<div>
						<label for="cat_name" class="block text-sm font-medium text-gray-700 mb-1">Category Name <span class="text-red-500">*</span></label>
						<input id="cat_name" type="text" bind:value={categoryForm.name} required placeholder="e.g. Dairy Products" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="flex gap-3 pt-2">
						<button type="button" onclick={() => showCategoryModal = false} class="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
							Cancel
						</button>
						<button type="submit" disabled={categoryLoading} class="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl shadow-lg shadow-indigo-200 transition-colors disabled:opacity-50 text-sm">
							{categoryLoading ? 'Creating...' : 'Add Category'}
						</button>
					</div>
				</form>
			</div>
		</div>
	{/if}
</div>
