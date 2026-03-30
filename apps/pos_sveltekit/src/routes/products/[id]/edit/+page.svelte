<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, Trash2, AlertCircle, Image as ImageIcon } from 'lucide-svelte';
	import FileUpload from '$lib/components/FileUpload.svelte';

	import { Plus } from 'lucide-svelte';

	const productId = $page.params.id;
	let loading = $state(true);
	let saving = $state(false);
	let deleting = $state(false);
	let error = $state('');
	
	let form = $state({
		product_type: 'Retail',
		name: '', barcode: '', description: '', category: '', is_active: true,
		generic_name: '', strength: '', dosage_form: '', 
		treatment_class: '', manufacturer: '', sample_type: '', image_url: ''
	});
	let file = $state<File | null>(null);
	let previewUrl = $state('');

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
		if (!target.closest('.category-dropdown-container')) {
			showCategoryDropdown = false;
		}
	}

	onMount(async () => {
		const { data } = await supabase.from('products').select('*').eq('id', productId).single();
		if (data) {
			form = {
				product_type: data.product_type || 'Retail',
				name: data.name || '',
				barcode: data.barcode || '',
				description: data.description || '',
				category: data.category || '',
				is_active: data.is_active ?? true,
				generic_name: data.generic_name || '',
				strength: data.strength || '',
				dosage_form: data.dosage_form || '',
				treatment_class: data.product_type === 'Drug' ? data.description : '',
				manufacturer: data.manufacturer || '',
				sample_type: data.sample_type || '',
				image_url: data.image_url || ''
			};
			categorySearch = form.category;
			previewUrl = form.image_url;
		}
		await fetchCategories();
		window.addEventListener('click', handleOutsideClick);
		loading = false;
	});

	import { onDestroy } from 'svelte';
	onDestroy(() => {
		if (typeof window !== 'undefined') window.removeEventListener('click', handleOutsideClick);
	});

	async function handleSave(e: Event) {
		e.preventDefault();
		saving = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('products').update({
				name: form.name, 
				barcode: form.barcode || null, 
				description: form.product_type === 'Drug' ? (form.treatment_class || form.description || null) : (form.description || null),
				category: form.category || null,
				is_active: form.is_active,
				product_type: form.product_type,
				generic_name: form.generic_name || null,
				strength: form.strength || null,
				dosage_form: form.dosage_form || null,
				manufacturer: form.manufacturer || null,
				sample_type: form.sample_type || null
			}).eq('id', productId);
			if (dbErr) throw dbErr;

			// Upload image if selected
			if (file) {
				const fileExt = file.name.split('.').pop();
				const fileName = `${productId}-${Date.now()}.${fileExt}`;
				
				const { error: uploadErr } = await supabase.storage.from('product-images').upload(fileName, file);
				if (uploadErr) throw uploadErr;

				const { data: { publicUrl } } = supabase.storage.from('product-images').getPublicUrl(fileName);
				await supabase.from('products').update({ image_url: publicUrl }).eq('id', productId);
			}

			goto(`/products/${productId}`);
		} catch (err: any) {
			error = err.message || 'Failed to save';
		} finally { saving = false; }
	}
</script>

<svelte:head><title>Edit Product – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/products/{productId}" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Edit Product</h1>
			<p class="text-sm text-gray-500">Update product details</p>
		</div>
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
				<div class="flex items-center justify-between">
					<h2 class="font-semibold text-gray-900 text-sm uppercase tracking-wider text-gray-500">Basic Info</h2>
					<div class="flex items-center gap-2">
						<label for="product_type_select" class="text-xs font-bold text-gray-400 uppercase tracking-widest">Type:</label>
						<select id="product_type_select" bind:value={form.product_type} class="text-xs font-bold bg-gray-50 border border-gray-200 rounded-lg px-2 py-1 outline-none focus:ring-2 focus:ring-indigo-500">
							<option value="Grocery">Grocery</option>
							<option value="Drug">Drug</option>
							<option value="Laboratory test">Laboratory test</option>
							<option value="Retail">Retail</option>
						</select>
					</div>
				</div>

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
					
					{#if form.product_type === 'Drug'}
						<!-- Drug Specific Fields -->
						<div class="sm:col-span-2">
							<label for="drug_name" class="block text-sm font-medium text-gray-700 mb-1">Product Name <span class="text-red-500">*</span></label>
							<input id="drug_name" type="text" bind:value={form.name} required class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div>
							<label for="generic_name" class="block text-sm font-medium text-gray-700 mb-1">Generic Name</label>
							<input id="generic_name" type="text" bind:value={form.generic_name} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div>
							<label for="strength" class="block text-sm font-medium text-gray-700 mb-1">Strength</label>
							<input id="strength" type="text" bind:value={form.strength} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div>
							<label for="dosage_form" class="block text-sm font-medium text-gray-700 mb-1">Dosage form</label>
							<input id="dosage_form" type="text" bind:value={form.dosage_form} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div>
							<label for="drug_barcode" class="block text-sm font-medium text-gray-700 mb-1">Barcode</label>
							<input id="drug_barcode" type="text" bind:value={form.barcode} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div class="category-dropdown-container relative">
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
							<textarea id="treat_class" bind:value={form.treatment_class} rows="2" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
						</div>

					{:else if form.product_type === 'Laboratory test'}
						<!-- Laboratory Test Fields -->
						<div class="sm:col-span-2">
							<label for="test_name" class="block text-sm font-medium text-gray-700 mb-1">Test Name <span class="text-red-500">*</span></label>
							<input id="test_name" type="text" bind:value={form.name} required class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div class="sm:col-span-2">
							<label for="sample_type" class="block text-sm font-medium text-gray-700 mb-1">Sample type</label>
							<input id="sample_type" type="text" bind:value={form.sample_type} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div class="sm:col-span-2">
							<label for="test_desc" class="block text-sm font-medium text-gray-700 mb-1">Description</label>
							<textarea id="test_desc" bind:value={form.description} rows="2" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
						</div>

					{:else}
						<!-- Standard Fields -->
						<div class="sm:col-span-2">
							<label for="prod_name" class="block text-sm font-medium text-gray-700 mb-1">Product Name <span class="text-red-500">*</span></label>
							<input id="prod_name" type="text" bind:value={form.name} required class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div>
							<label for="prod_barcode" class="block text-sm font-medium text-gray-700 mb-1">Barcode</label>
							<input id="prod_barcode" type="text" bind:value={form.barcode} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
						<div class="category-dropdown-container relative">
							<label for="prod_cat" class="block text-sm font-medium text-gray-700 mb-1">Category</label>
							<div class="flex gap-2">
								<div class="flex-1 relative">
									<input 
										id="prod_cat" 
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
							<label for="prod_desc" class="block text-sm font-medium text-gray-700 mb-1">Description</label>
							<textarea id="prod_desc" bind:value={form.description} rows="2" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
						</div>
					{/if}
				</div>
			</div>

			{#if form.product_type !== 'Laboratory test'}
				<div class="bg-white rounded-xl border p-5 space-y-4">
					<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Additional Details</h2>
					<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
						<div class="sm:col-span-2">
							<label for="manufacturer" class="block text-sm font-medium text-gray-700 mb-1">Manufacturer</label>
							<input id="manufacturer" type="text" bind:value={form.manufacturer} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
					</div>
					<label class="flex items-center gap-3 cursor-pointer pt-2">
						<input type="checkbox" bind:checked={form.is_active} class="w-4 h-4 text-indigo-600 rounded border-gray-300" />
						<span class="text-sm font-medium text-gray-700">Product is active in catalog</span>
					</label>
				</div>
			{:else}
				<div class="bg-white rounded-xl border p-5">
					<label class="flex items-center gap-3 cursor-pointer">
						<input type="checkbox" bind:checked={form.is_active} class="w-4 h-4 text-indigo-600 rounded border-gray-300" />
						<span class="text-sm font-medium text-gray-700">Product is active in catalog</span>
					</label>
				</div>
			{/if}

			<div class="flex gap-3">
				<a href="/products/{productId}" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
					Cancel
				</a>
				<button type="submit" disabled={saving} class="flex-[2] flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
					<Save class="h-4 w-4" />{saving ? 'Saving...' : 'Save Changes'}
				</button>
			</div>
		</form>

		{#if showCategoryModal}
			<div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto w-full">
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
	{/if}
</div>
