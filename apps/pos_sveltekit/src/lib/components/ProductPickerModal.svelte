<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { X, Search, Package, Plus, Filter, ChevronRight, Check, ChevronLeft } from 'lucide-svelte';
	import { fade, slide } from 'svelte/transition';

	let { open = $bindable(false), selectedIds = [], onSelect, onClose } = $props<{
		open: boolean;
		selectedIds: string[];
		onSelect: (product: any) => void;
		onClose: () => void;
	}>();

	let loading = $state(false);
	let products = $state<any[]>([]);
	let searchTerm = $state('');
	let selectedCategory = $state('all');
	let selectedManufacturer = $state('all');
	let selectedType = $state('all');
	
	let categories = $state<string[]>([]);
	let manufacturers = $state<string[]>([]);
	let productTypes = $state<string[]>([]);

	// Pagination
	let currentPage = $state(1);
	let pageSize = 24;
	let totalCount = $state(0);
	let totalPages = $derived(Math.ceil(totalCount / pageSize));

	async function fetchProducts() {
		loading = true;
		try {
			const from = (currentPage - 1) * pageSize;
			const to = from + pageSize - 1;

			let query = supabase
				.from('products')
				.select('*', { count: 'exact' })
				.eq('is_active', true)
				.order('name');

			if (searchTerm) {
				query = query.ilike('name', `%${searchTerm}%`);
			}

			if (selectedCategory !== 'all') {
				query = query.eq('category', selectedCategory);
			}

			if (selectedManufacturer !== 'all') {
				query = query.eq('manufacturer', selectedManufacturer);
			}

			if (selectedType !== 'all') {
				query = query.eq('product_type', selectedType);
			}

			const { data, error, count } = await query.range(from, to);
			if (error) throw error;
			products = data || [];
			totalCount = count || 0;

			// Extract filter values once
			if (categories.length === 0) {
				const { data: filterData } = await supabase
					.from('products')
					.select('category, manufacturer, product_type')
					.eq('is_active', true);
				
				categories = [...new Set(filterData?.map(c => c.category).filter(Boolean) || [])].sort() as string[];
				manufacturers = [...new Set(filterData?.map(c => c.manufacturer).filter(Boolean) || [])].sort() as string[];
				productTypes = [...new Set(filterData?.map(c => c.product_type).filter(Boolean) || [])].sort() as string[];
			}
		} catch (err) {
			console.error('Error fetching products:', err);
		} finally {
			loading = false;
		}
	}

	function changePage(p: number) {
		currentPage = p;
		fetchProducts();
	}

	function resetAndFetch() {
		currentPage = 1;
		fetchProducts();
	}

	$effect(() => {
		if (open) {
			fetchProducts();
		}
	});

	function handleSelect(product: any) {
		onSelect(product);
		// Keep open for multi-select if needed, but usually we close or show a "added" state
	}

	let debounceTimer: any;
	function handleSearch() {
		clearTimeout(debounceTimer);
		debounceTimer = setTimeout(fetchProducts, 300);
	}
</script>

{#if open}
	<div class="fixed inset-0 z-[120] flex items-center justify-center p-4">
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" onclick={onClose}></div>

		<div class="relative bg-white rounded-3xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col animate-in fade-in zoom-in duration-200">
			<!-- Header -->
			<div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
				<div class="flex items-center gap-3">
					<div class="h-10 w-10 bg-indigo-100 text-indigo-600 rounded-xl flex items-center justify-center">
						<Package class="h-6 w-6" />
					</div>
					<div>
						<h2 class="text-xl font-black text-gray-900">Select Products</h2>
						<p class="text-xs text-gray-500 font-medium">Browse and add items to your order</p>
					</div>
				</div>
				<button onclick={onClose} class="p-2 hover:bg-gray-100 rounded-xl transition-colors">
					<X class="h-5 w-5 text-gray-400" />
				</button>
			</div>

			<!-- Filters -->
			<div class="p-4 border-b border-gray-100 flex flex-wrap gap-3 bg-white sticky top-0 z-10">
				<div class="relative flex-1 min-w-[200px]">
					<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
					<input 
						type="text" 
						bind:value={searchTerm}
						oninput={() => { clearTimeout(debounceTimer); debounceTimer = setTimeout(resetAndFetch, 300); }}
						placeholder="Search catalog..."
						class="w-full pl-10 pr-4 py-2 bg-gray-50 border-transparent rounded-xl text-sm focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all outline-none"
					/>
				</div>
				<select 
					bind:value={selectedCategory}
					onchange={resetAndFetch}
					class="pl-4 pr-10 py-2 bg-gray-50 border-transparent rounded-xl text-sm focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all outline-none appearance-none font-bold text-gray-700"
				>
					<option value="all">Categories</option>
					{#each categories as cat}
						<option value={cat}>{cat}</option>
					{/each}
				</select>
				<select 
					bind:value={selectedManufacturer}
					onchange={resetAndFetch}
					class="pl-4 pr-10 py-2 bg-gray-50 border-transparent rounded-xl text-sm focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all outline-none appearance-none font-bold text-gray-700"
				>
					<option value="all">Manufacturers</option>
					{#each manufacturers as m}
						<option value={m}>{m}</option>
					{/each}
				</select>
				<select 
					bind:value={selectedType}
					onchange={resetAndFetch}
					class="pl-4 pr-10 py-2 bg-gray-50 border-transparent rounded-xl text-sm focus:bg-white focus:ring-2 focus:ring-indigo-500 transition-all outline-none appearance-none font-bold text-gray-700"
				>
					<option value="all">Types</option>
					{#each productTypes as t}
						<option value={t}>{t}</option>
					{/each}
				</select>
			</div>

			<!-- Product List -->
			<div class="flex-1 overflow-y-auto p-6 bg-gray-50/50">
				{#if loading && products.length === 0}
					<div class="flex flex-col items-center justify-center py-20">
						<div class="h-8 w-8 border-4 border-indigo-100 border-t-indigo-600 rounded-full animate-spin"></div>
						<p class="text-xs font-bold text-gray-400 mt-4 uppercase tracking-widest italic">Loading Catalog...</p>
					</div>
				{:else if products.length === 0}
					<div class="flex flex-col items-center justify-center py-20 text-center">
						<div class="h-16 w-16 bg-white rounded-2xl shadow-sm flex items-center justify-center text-gray-200 mb-4 border border-gray-100">
							<Package class="h-8 w-8" />
						</div>
						<h3 class="text-lg font-black text-gray-900">No Products Found</h3>
						<p class="text-sm text-gray-500 max-w-xs mx-auto mt-1">Try adjusting your filters or search term.</p>
					</div>
				{:else}
					<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
						{#each products as product}
							{@const isSelected = selectedIds.includes(product.id)}
							<button 
								onclick={() => handleSelect(product)}
								class="bg-white p-4 rounded-2xl border transition-all group relative overflow-hidden flex flex-col justify-between h-full
								{isSelected ? 'border-indigo-600 shadow-lg shadow-indigo-50 ring-2 ring-indigo-50' : 'border-gray-100 hover:border-indigo-300 hover:shadow-md'}"
							>
								{#if isSelected}
									<div class="absolute top-3 right-3 h-5 w-5 bg-indigo-600 text-white rounded-full flex items-center justify-center animate-in zoom-in">
										<Check class="h-3 w-3" />
									</div>
								{/if}

								<div>
									<div class="flex justify-between items-start mb-2">
										<div class="h-10 w-10 bg-gray-50 rounded-lg flex items-center justify-center text-gray-400 group-hover:bg-indigo-50 group-hover:text-indigo-500 transition-colors">
											<Package class="h-6 w-6" />
										</div>
									</div>
									<h4 class="font-black text-gray-900 line-clamp-2 text-sm">{product.name}</h4>
									<div class="flex items-center flex-wrap gap-2 mt-1.5">
										<p class="text-[9px] font-black text-gray-400 uppercase tracking-widest italic leading-none">{product.generic_name || 'No Generic'}</p>
										{#if product.strength}
											<span class="text-[9px] font-black text-indigo-600 bg-indigo-50 px-1.5 py-0.5 rounded tracking-tighter leading-none">{product.strength}</span>
										{/if}
										{#if product.isPOM}
											<span class="text-[8px] font-black bg-rose-100 text-rose-600 px-1.5 py-0.5 rounded uppercase tracking-tighter leading-none">POM</span>
										{/if}
									</div>
								</div>
								
								<div class="mt-4 pt-4 border-t border-gray-50 flex justify-between items-end">
									<div class="min-w-0">
										<p class="text-[9px] font-black text-gray-400 uppercase tracking-widest">Manufacturer</p>
										<p class="text-[10px] font-bold text-gray-700 truncate">{product.manufacturer || 'Unknown'}</p>
									</div>
									<div class="text-right shrink-0">
										<p class="text-[9px] font-black text-gray-400 uppercase tracking-widest">Unit</p>
										<p class="text-[10px] font-bold text-gray-700 uppercase">{product.unit_of_measure}</p>
									</div>
								</div>
							</button>
						{/each}
					</div>

					<!-- Pagination Controls -->
					{#if totalPages > 1}
						<div class="mt-8 flex items-center justify-center gap-4">
							<button 
								onclick={() => changePage(currentPage - 1)}
								disabled={currentPage === 1}
								class="p-2 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 disabled:opacity-50 transition-all active:scale-95 shadow-sm"
							>
								<ChevronLeft class="h-5 w-5" />
							</button>
							<div class="flex items-center gap-2">
								{#each Array.from({length: Math.min(5, totalPages)}, (_, i) => {
									if (totalPages <= 5) return i + 1;
									if (currentPage <= 3) return i + 1;
									if (currentPage >= totalPages - 2) return totalPages - 4 + i;
									return currentPage - 2 + i;
								}) as p}
									<button 
										onclick={() => changePage(p)}
										class="h-9 w-9 text-xs font-black rounded-xl transition-all active:scale-95
										{currentPage === p ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-100' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}"
									>
										{p}
									</button>
								{/each}
							</div>
							<button 
								onclick={() => changePage(currentPage + 1)}
								disabled={currentPage === totalPages}
								class="p-2 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 disabled:opacity-50 transition-all active:scale-95 shadow-sm"
							>
								<ChevronRight class="h-5 w-5" />
							</button>
						</div>
					{/if}
				{/if}
			</div>

			<!-- Footer -->
			<div class="p-6 bg-white border-t border-gray-100 flex justify-between items-center">
				<div>
					<p class="text-xs font-bold text-gray-400">Total {totalCount} products found</p>
					<p class="text-[10px] font-medium text-gray-300">Page {currentPage} of {totalPages}</p>
				</div>
				<button 
					onclick={onClose}
					class="px-8 py-3 bg-indigo-600 text-white font-black rounded-xl hover:bg-indigo-700 transition-all active:scale-95 shadow-lg shadow-indigo-100"
				>
					Done
				</button>
			</div>
		</div>
	</div>
{/if}
