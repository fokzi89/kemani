<script lang="ts">
	import { onMount } from 'svelte';
	import { Search, X, Plus, Package, Loader2, Pill } from 'lucide-svelte';
	import { supabase } from '$lib/supabase';
	import { fade, fly } from 'svelte/transition';

	let { show = false, tenantId, onClose, onSelect } = $props();

	let products = $state<any[]>([]);
	let loading = $state(false);
	let searchQuery = $state('');

	async function loadProducts() {
		if (!tenantId) return;
		loading = true;
		try {
			let query = supabase
				.from('branch_inventory')
				.select(`
					id, product_id, product_name, product_description, 
					image_url, selling_price, stock_quantity, product_type, isPOM
				`)
				.eq('tenant_id', tenantId)
				.eq('isPOM', false) // Filter out prescription-only medications for customers
				.gt('stock_quantity', 0)
				.order('product_name');

			if (searchQuery) {
				query = query.ilike('product_name', `%${searchQuery}%`);
			}

			const { data, error } = await query.limit(20);
			if (error) throw error;
			
			products = (data || []).map(row => ({
				id: row.product_id,
				inventory_id: row.id,
				name: row.product_name,
				description: row.product_description,
				image_url: row.image_url,
				unit_price: row.selling_price,
				stock_quantity: row.stock_quantity,
				category: row.product_type
			}));
		} catch (err) {
			console.error('Failed to load products:', err);
		} finally {
			loading = false;
		}
	}

	$effect(() => {
		if (show) {
			loadProducts();
		}
	});

	function handleSearch(e: Event) {
		const target = e.target as HTMLInputElement;
		searchQuery = target.value;
		loadProducts();
	}
</script>

{#if show}
	<div 
		class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm"
		transition:fade
	>
		<div 
			class="bg-white w-full max-w-lg rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[80vh]"
			transition:fly={{ y: 20 }}
		>
			<!-- Header -->
			<div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10">
				<div>
					<h3 class="text-lg font-bold text-gray-900">Add Product</h3>
					<p class="text-[10px] text-gray-400 uppercase tracking-widest font-bold">Select items to share or add to bag</p>
				</div>
				<button 
					onclick={onClose}
					class="p-2 hover:bg-gray-100 rounded-full transition-colors"
				>
					<X class="h-5 w-5 text-gray-400" />
				</button>
			</div>

			<!-- Search -->
			<div class="p-4 border-b border-gray-50 bg-gray-50/30">
				<div class="relative">
					<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
					<input 
						type="text" 
						placeholder="Search for supplements, OTC, or retail items..." 
						class="w-full pl-10 pr-4 py-2 text-sm bg-white border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary-100 focus:border-primary-500 transition-all outline-none"
						value={searchQuery}
						oninput={handleSearch}
					/>
				</div>
			</div>

			<!-- List -->
			<div class="flex-1 overflow-y-auto p-2 scroll-smooth">
				{#if loading}
					<div class="h-40 flex flex-col items-center justify-center text-gray-400 gap-2">
						<Loader2 class="h-6 w-6 animate-spin" />
						<p class="text-xs font-medium uppercase tracking-tighter">Updating Catalog...</p>
					</div>
				{:else if products.length === 0}
					<div class="h-40 flex flex-col items-center justify-center text-gray-300 gap-2">
						<Package class="h-8 w-8" />
						<p class="text-xs font-medium">No results found</p>
					</div>
				{:else}
					<div class="grid grid-cols-1 gap-1">
						{#each products as product}
							<button 
								onclick={() => onSelect(product)}
								class="flex items-center gap-4 p-3 hover:bg-gray-50 rounded-2xl transition-all text-left group border border-transparent hover:border-gray-100"
							>
								<div class="h-14 w-14 bg-gray-100 rounded-xl overflow-hidden flex-shrink-0">
									{#if product.image_url}
										<img src={product.image_url} alt={product.name} class="h-full w-full object-cover" />
									{:else}
										<div class="h-full w-full flex items-center justify-center text-gray-300">
											<Package class="h-6 w-6" />
										</div>
									{/if}
								</div>
								<div class="flex-1 min-w-0">
									<h4 class="text-sm font-bold text-gray-900 truncate uppercase tracking-tight">{product.name}</h4>
									<p class="text-[10px] text-gray-500 truncate mb-1">
										{product.category || 'Retail Product'}
									</p>
									<p class="text-xs font-black text-primary-700">₦{product.unit_price?.toLocaleString()}</p>
								</div>
								<div class="opacity-0 group-hover:opacity-100 transform translate-x-2 group-hover:translate-x-0 transition-all">
									<div class="h-8 w-8 bg-black text-white rounded-lg flex items-center justify-center shadow-lg">
										<Plus class="h-4 w-4" />
									</div>
								</div>
							</button>
						{/each}
					</div>
				{/if}
			</div>

			<!-- Footer Note -->
			<div class="p-4 bg-amber-50/50 border-t border-amber-100 flex items-center gap-3">
				<Pill class="h-4 w-4 text-amber-600 flex-shrink-0" />
				<p class="text-[9px] text-amber-800 font-medium leading-relaxed uppercase tracking-tighter">
					Prescription medications are hidden. Our pharmacist will add those to your cart during this consultation if required.
				</p>
			</div>
		</div>
	</div>
{/if}

<style>
	/* Custom scrollbar */
	div::-webkit-scrollbar {
		width: 4px;
	}
	div::-webkit-scrollbar-track {
		background: transparent;
	}
	div::-webkit-scrollbar-thumb {
		background: #e5e7eb;
		border-radius: 10px;
	}
</style>
