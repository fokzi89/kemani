<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Search, MapPin, Package, Check, 
		X, MoreHorizontal, ArrowRightLeft, 
		ArrowRight, Building, AlertTriangle, Plus,
		Eye
	} from 'lucide-svelte';
	import ProductDetailModal from '$lib/components/ProductDetailModal.svelte';

	let inventory = $state<any[]>([]);
	let branches = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');
	let selectedBranchId = $state('all');
	let selectedIds = $state<string[]>([]);
	let editingValues = $state<Record<string, any>>({});
	let currentTenantId = $state('');
	let userBranchId = $state('');
	let userRole = $state('');

	// Pagination
	let page = $state(1);
	const PER_PAGE = 20;

	// Transfer Modal State
	let showTransferModal = $state(false);
	let targetBranchId = $state('');
	let transferLoading = $state(false);

	// Detail Modal State
	let selectedForDetail = $state<{id: string, branchId: string, name: string} | null>(null);

	// Derived lists
	let filtered = $derived(
		inventory.filter(item => {
			const matchesSearch = item.name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
								item.sku?.toLowerCase().includes(searchQuery.toLowerCase());
			const matchesBranch = selectedBranchId === 'all' || item.branch_id === selectedBranchId;
			const hasStock = item.stock_quantity > 0;
			return matchesSearch && matchesBranch && hasStock;
		})
	);

	let paginated = $derived(filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE));
	let totalPages = $derived(Math.ceil(filtered.length / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: user } = await supabase.from('users')
			.select('tenant_id, branch_id, role')
			.eq('id', session.user.id)
			.single();
			
		if (user) {
			currentTenantId = user.tenant_id;
			userBranchId = user.branch_id || '';
			userRole = user.role;
			selectedBranchId = user.branch_id || 'all';
			await Promise.all([loadBranches(), loadInventory()]);
		}
		loading = false;
	});

	async function loadBranches() {
		const { data } = await supabase.from('branches')
			.select('id, name')
			.eq('tenant_id', currentTenantId);
		branches = data || [];
	}

	async function loadInventory() {
		// Build the query against branch_inventory directly
		let query = supabase
			.from('branch_inventory')
			.select(`
				id,
				branch_id,
				product_id,
				stock_quantity,
				reserved_quantity,
				batch_no,
				product_name,
				sku,
				image_url,
				cost_price,
				selling_price,
				expiry_date,
				updated_at
			`)
			.eq('tenant_id', currentTenantId)
			.gt('stock_quantity', 0);

		// If a specific branch is selected, filter server-side
		if (selectedBranchId && selectedBranchId !== 'all') {
			query = query.eq('branch_id', selectedBranchId);
		}

		const { data, error } = await query;

		if (error) {
			console.error('Inventory fetch error:', error);
			return;
		}

		// Map to the format expected by the table
		inventory = (data || []).map((row: any) => {
			const soon = row.expiry_date
				? (new Date(row.expiry_date).getTime() - Date.now()) < 1000 * 60 * 60 * 24 * 90
				: false;
			return {
				inv_id: row.id, // branch_inventory PK
				branch_id: row.branch_id,
				product_id: row.product_id,
				stock_quantity: row.stock_quantity,
				reserved_quantity: row.reserved_quantity || 0,
				available_stock: row.stock_quantity - (row.reserved_quantity || 0),
				expiry_date: row.expiry_date,
				batch_no: row.batch_no,
				name: row.product_name,
				sku: row.sku,
				unit_price: row.selling_price,
				cost_price: row.cost_price,
				image_url: row.image_url,
				is_expiring_soon: soon
			};
		});
	}

	function handleSelectRow(invId: string) {
		if (selectedIds.includes(invId)) {
			selectedIds = selectedIds.filter(i => i !== invId);
			const newEditing = { ...editingValues };
			delete newEditing[invId];
			editingValues = newEditing;
		} else {
			const item = inventory.find(i => i.inv_id === invId);
			if (!item) return;
			
			selectedIds = [...selectedIds, invId];
			editingValues = {
				...editingValues,
				[invId]: {
					stock_quantity: item.stock_quantity,
					unit_price: item.unit_price,
					cost_price: item.cost_price,
					expiry_date: item.expiry_date
				}
			};
		}
	}

	async function handleBatchUpdate() {
		if (selectedIds.length === 0) return;
		if (selectedIds.length > 20) {
			alert('Maximum 20 items per batch update.');
			return;
		}

		loading = true;
		try {
			for (const invId of selectedIds) {
				const vals = editingValues[invId];
				const item = inventory.find(i => i.inv_id === invId);
				if (!item) continue;
				
				// 1. Update branch_inventory (stock & expiry)
				const { error: biErr } = await supabase.from('branch_inventory')
					.update({
						stock_quantity: vals.stock_quantity,
						expiry_date: vals.expiry_date || null,
						updated_at: new Date().toISOString()
					})
					.eq('id', invId);

				if (biErr) throw biErr;

				// 2. We skip updating products directly since unit price is mapped to unit_cost in branch_inventory
				// or we just update the branch_inventory selling_price here
				const { error: biErr2 } = await supabase.from('branch_inventory')
					.update({
						selling_price: vals.unit_price,
						cost_price: vals.cost_price,
						updated_at: new Date().toISOString()
					})
					.eq('id', invId);

				if (biErr2) throw biErr2;

				// 3. Audit transaction
				await supabase.from('inventory_transactions').insert({
					tenant_id: currentTenantId,
					branch_id: item.branch_id,
					product_id: item.product_id,
					transaction_type: 'adjustment',
					quantity_delta: vals.stock_quantity - item.stock_quantity,
					previous_quantity: item.stock_quantity,
					new_quantity: vals.stock_quantity,
					staff_id: (await supabase.auth.getUser()).data.user?.id,
					notes: 'Manual adjustment from Inventory page'
				});
			}
			
			selectedIds = [];
			editingValues = {};
			await loadInventory();
			alert('Inventory updated successfully.');
		} catch (err: any) {
			console.error('Update failed:', err);
			alert(`Update error: ${err.message}`);
		} finally {
			loading = false;
		}
	}

	async function handleTransfer() {
		const sourceId = selectedBranchId === 'all' ? userBranchId : selectedBranchId;
		if (!targetBranchId || selectedIds.length === 0 || !sourceId) return;

		transferLoading = true;
		try {
			const { data: authUser } = await supabase.auth.getUser();
			const userId = authUser.user?.id;

			// 1. Create a single Transfer record for this batch
			const { data: transfer, error: tErr } = await supabase.from('inter_branch_transfers')
				.insert({
					tenant_id: currentTenantId,
					source_branch_id: sourceId,
					destination_branch_id: targetBranchId,
					status: 'completed',
					authorized_by_id: userId,
					notes: `Batch transfer from inventory page: ${selectedIds.length} items`
				})
				.select()
				.single();

			if (tErr) throw tErr;

			for (const invId of selectedIds) {
				const item = inventory.find(i => i.inv_id === invId);
				if (!item) continue;

				const amountRequested = editingValues[invId].stock_quantity; 
				
				if (amountRequested > item.stock_quantity) {
					console.warn(`Insufficient stock for ${item.name}.`);
					continue;
				}

				// 2. Create Transfer Item record
				await supabase.from('transfer_items').insert({
					transfer_id: transfer.id,
					product_id: item.product_id,
					quantity: amountRequested
				});

				// 3. Adjust Source Branch Stock
				await supabase.from('branch_inventory')
					.update({ stock_quantity: item.stock_quantity - amountRequested })
					.eq('id', invId);

				// 4. Adjust Destination Branch Stock (Upsert)
				const { data: destInv } = await supabase.from('branch_inventory')
					.select('id, stock_quantity')
					.eq('branch_id', targetBranchId)
					.eq('product_id', item.product_id)
					.eq('batch_no', item.batch_no || null)
					.maybeSingle();

				if (destInv) {
					await supabase.from('branch_inventory')
						.update({ stock_quantity: destInv.stock_quantity + amountRequested })
						.eq('id', destInv.id);
				} else {
					await supabase.from('branch_inventory').insert({
						tenant_id: currentTenantId,
						branch_id: targetBranchId,
						product_id: item.product_id,
						stock_quantity: amountRequested,
						batch_no: item.batch_no,
						product_name: item.name,
						sku: item.sku,
						cost_price: item.cost_price,
						selling_price: item.unit_price || 0
					});
				}

				// 5. Audit Log (Outbound)
				await supabase.from('inventory_transactions').insert({
					tenant_id: currentTenantId,
					branch_id: sourceId,
					product_id: item.product_id,
					transaction_type: 'transfer_out',
					quantity_delta: -amountRequested,
					previous_quantity: item.stock_quantity,
					new_quantity: item.stock_quantity - amountRequested,
					reference_id: transfer.id,
					reference_type: 'inter_branch_transfer',
					staff_id: userId
				});

				// 6. Audit Log (Inbound)
				await supabase.from('inventory_transactions').insert({
					tenant_id: currentTenantId,
					branch_id: targetBranchId,
					product_id: item.product_id,
					transaction_type: 'transfer_in',
					quantity_delta: amountRequested,
					previous_quantity: destInv?.stock_quantity || 0,
					new_quantity: (destInv?.stock_quantity || 0) + amountRequested,
					reference_id: transfer.id,
					reference_type: 'inter_branch_transfer',
					staff_id: userId
				});
			}
			
			selectedIds = [];
			editingValues = {};
			await loadInventory();
			alert('Transfer completed successfully.');
		} catch (err: any) {
			console.error('Transfer failed:', err);
			alert(`Transfer error: ${err.message}`);
		} finally {
			transferLoading = false;
			showTransferModal = false;
		}
	}

</script>

<div class="p-6 space-y-5 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900 flex items-center gap-2">
				<Package class="h-6 w-6 text-indigo-600" />
				Inventory
			</h1>
			<p class="text-sm text-gray-500 mt-0.5">{filtered.length} product{filtered.length !== 1 ? 's' : ''} in stock</p>
		</div>
		<div class="flex items-center gap-3">
			{#if selectedIds.length > 0}
				<div class="flex items-center gap-2 animate-in fade-in slide-in-from-right-2 duration-300">
					<span class="text-xs font-medium text-indigo-600">
						{selectedIds.length} selected
					</span>
					<button 
						onclick={handleBatchUpdate}
						class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm shadow-lg shadow-indigo-100"
					>
						<Save class="h-4 w-4" /> Update Stock
					</button>
					<button 
						onclick={() => showTransferModal = true}
						class="inline-flex items-center gap-2 bg-white border border-indigo-200 text-indigo-600 hover:bg-indigo-50 font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm"
					>
						<ArrowRightLeft class="h-4 w-4" /> Transfer
					</button>
					<button onclick={() => { selectedIds = []; editingValues = {}; }} class="p-2 text-gray-400 hover:text-red-500 transition-colors">
						<X class="h-5 w-5" />
					</button>
				</div>
			{/if}
		</div>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-xl border p-4 flex flex-wrap gap-3 shadow-sm">
		<div class="relative flex-1 min-w-48">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input 
				type="text" 
				bind:value={searchQuery}
				placeholder="Search by name or SKU..."
				class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all outline-none text-sm"
			/>
		</div>

		<div class="relative group min-w-48">
			<Building class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<select 
				bind:value={selectedBranchId}
				class="w-full pl-10 pr-8 py-2.5 bg-white border border-gray-200 rounded-xl appearance-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all outline-none font-medium text-sm text-gray-700 cursor-pointer"
			>
				<option value="all">All Branches</option>
				{#each branches as branch}
					<option value={branch.id}>{branch.name}</option>
				{/each}
			</select>
			<div class="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400">
				<ChevronRight class="h-4 w-4 rotate-90" />
			</div>
		</div>
	</div>

	<!-- Inventory Table -->
	<div class="bg-white rounded-xl border shadow-sm overflow-hidden">
		{#if loading}
			<div class="p-12 text-center">
				<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div>
				<p class="text-xs text-gray-500 mt-4 font-medium italic tracking-wide">Syncing product levels...</p>
			</div>
		{:else if filtered.length === 0}
			<div class="p-16 text-center">
				<div class="bg-gray-50 h-16 w-16 rounded-full flex items-center justify-center mx-auto mb-4 border border-gray-100">
					<Package class="h-8 w-8 text-gray-300" />
				</div>
				<h3 class="text-lg font-bold text-gray-900">No Inventory Found</h3>
				<p class="text-gray-500 text-sm mt-1 max-w-xs mx-auto">Try adjusting your location filter or search query.</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-sm text-left min-w-[1200px]">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-6 py-4 w-10 text-center">
								<Check class="h-4 w-4 text-gray-400 mx-auto" />
							</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Product Information</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Location</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider text-center">In Stock</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider border-l">Selling Price</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Cost Price</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider border-l">Expiry</th>
							<th class="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each paginated as item}
							{@const invId = item.inv_id}
							{@const isSelected = selectedIds.includes(invId)}
							<tr class="hover:bg-gray-50 transition-colors {isSelected ? 'bg-indigo-50/30' : ''}">
								<td class="px-6 py-4 text-center">
									<input 
										type="checkbox" 
										checked={isSelected}
										onchange={() => handleSelectRow(invId)}
										class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 h-4 w-4 cursor-pointer"
									/>
								</td>
								<td class="px-4 py-3">
									<div class="flex items-center gap-3">
										<div class="w-10 h-10 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-xl flex items-center justify-center flex-shrink-0 overflow-hidden border border-white shadow-sm">
											{#if item.image_url}
												<img src={item.image_url} alt={item.name} class="w-full h-full object-cover" />
											{:else}
												<Package class="h-5 w-5 text-indigo-400" />
											{/if}
										</div>
										<div>
											<p class="font-semibold text-gray-900 leading-tight">{item.name}</p>
											<div class="flex items-center gap-2 mt-0.5">
												<span class="text-[10px] px-1.5 py-0.5 bg-gray-100 text-gray-500 rounded font-bold uppercase tracking-tight">{item.sku || 'No SKU'}</span>
												<span class="text-[10px] text-gray-400 font-medium">• Batch: {item.batch_no || 'NA'}</span>
											</div>
										</div>
									</div>
								</td>
								<td class="px-4 py-3 whitespace-nowrap">
									<div class="flex items-center gap-2">
										<div class="h-2 w-2 rounded-full {item.available_stock > 10 ? 'bg-green-500' : 'bg-orange-500'}"></div>
										<span class="text-xs font-bold text-gray-700 capitalize tracking-tight">
											 {branches.find(b => b.id === item.branch_id)?.name || 'Central Branch'}
										</span>
									</div>
								</td>
								<td class="px-4 py-3 text-center">
									{#if isSelected}
										<div class="space-y-1">
											<input 
												type="number" 
												bind:value={editingValues[invId].stock_quantity}
												class="w-20 px-2.5 py-1.5 bg-white border border-indigo-200 rounded-lg text-center font-bold text-indigo-700 outline-none focus:ring-2 focus:ring-indigo-500 h-9 transition-all"
											/>
											<div class="text-[10px] text-gray-400">Reserved: {item.reserved_quantity}</div>
										</div>
									{:else}
										<div class="font-bold text-gray-900 text-base">
											{item.available_stock} <span class="text-[10px] font-medium text-gray-400 ml-0.5">avail</span>
										</div>
										<div class="text-[10px] text-gray-500 uppercase tracking-tighter">Total: {item.stock_quantity}</div>
									{/if}
								</td>
								<td class="px-4 py-3 border-l">
									{#if isSelected}
										<div class="relative">
											<span class="absolute left-2 top-1/2 -translate-y-1/2 text-gray-400 text-xs font-bold">₦</span>
											<input 
												type="number" 
												bind:value={editingValues[invId].unit_price}
												class="w-full pl-5 pr-2 py-1.5 bg-white border border-indigo-200 rounded-lg font-bold text-indigo-700 outline-none focus:ring-2 focus:ring-indigo-500 h-9 transition-all"
											/>
										</div>
									{:else}
										<span class="font-bold text-gray-900">₦{Number(item.unit_price).toLocaleString()}</span>
									{/if}
								</td>
								<td class="px-4 py-3">
									{#if isSelected}
										<div class="relative">
											<span class="absolute left-2 top-1/2 -translate-y-1/2 text-gray-400 text-xs font-bold">₦</span>
											<input 
												type="number" 
												bind:value={editingValues[invId].cost_price}
												class="w-full pl-5 pr-2 py-1.5 bg-white border border-indigo-200 rounded-lg font-bold text-indigo-700 outline-none focus:ring-2 focus:ring-indigo-500 h-9 transition-all"
											/>
										</div>
									{:else}
										<span class="font-medium text-gray-500 italic">₦{Number(item.cost_price || 0).toLocaleString()}</span>
									{/if}
								</td>
								<td class="px-4 py-3 border-l">
									{#if isSelected}
										<input 
											type="date" 
											bind:value={editingValues[invId].expiry_date}
											class="w-full px-2.5 py-1.5 bg-white border border-indigo-200 rounded-lg text-xs font-bold text-indigo-700 outline-none focus:ring-2 focus:ring-indigo-500 h-9 transition-all"
										/>
									{:else}
										<div class="flex items-center gap-2">
											<span class="text-xs font-medium text-gray-600 {item.is_expiring_soon ? 'text-red-600 font-bold' : ''}">
												{item.expiry_date ? new Date(item.expiry_date).toLocaleDateString() : '—'}
											</span>
											{#if item.is_expiring_soon}
												<AlertTriangle class="h-3 w-3 text-red-500" />
											{/if}
										</div>
									{/if}
								</td>
								<td class="px-4 py-3 text-right">
									<button 
										onclick={() => selectedForDetail = {id: item.product_id, branchId: item.branch_id, name: item.name}}
										class="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-all"
										title="View Audit Detail"
									>
										<Eye class="h-4 w-4" />
									</button>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Pagination -->
			{#if totalPages > 1}
				<div class="p-4 border-t bg-gray-50/30 flex items-center justify-between text-sm text-gray-600">
					<p class="text-xs font-medium">
						Showing <span class="text-gray-900 font-bold">{(page-1)*PER_PAGE+1}</span> – 
						<span class="text-gray-900 font-bold">{Math.min(filtered.length, page * PER_PAGE)}</span> of 
						<span class="text-gray-900 font-bold">{filtered.length}</span>
					</p>
					<div class="flex gap-1">
						<button 
							disabled={page === 1}
							onclick={() => page--}
							class="p-2 border border-gray-200 rounded-lg bg-white hover:bg-gray-50 transition-colors disabled:opacity-40"
						>
							<ChevronLeft class="h-4 w-4" />
						</button>
						<button 
							disabled={page === totalPages}
							onclick={() => page++}
							class="p-2 border border-gray-200 rounded-lg bg-white hover:bg-gray-50 transition-colors disabled:opacity-40"
						>
							<ChevronRight class="h-4 w-4" />
						</button>
					</div>
				</div>
			{/if}
		{/if}
	</div>
</div>

<ProductDetailModal 
	isOpen={!!selectedForDetail} 
	onClose={() => selectedForDetail = null} 
	productId={selectedForDetail?.id || ''}
	branchId={selectedForDetail?.branchId || ''}
	productName={selectedForDetail?.name || ''}
/>

<!-- Transfer Modal -->
{#if showTransferModal}
	<div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm z-[100] flex items-center justify-center p-4">
		<div class="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in duration-200">
			<div class="p-6 border-b flex justify-between items-center bg-indigo-600 text-white">
				<div>
					<h2 class="text-lg font-extrabold">Inventory Transfer</h2>
					<p class="text-xs text-indigo-100 mt-0.5">Move {selectedIds.length} items to another location</p>
				</div>
				<button onclick={() => showTransferModal = false} class="p-2 hover:bg-white/10 rounded-lg transition-colors">
					<Plus class="h-5 w-5 rotate-45" />
				</button>
			</div>
			
			<div class="p-6 space-y-5">
				<div class="space-y-2">
					<div class="block text-sm font-bold text-gray-700">Destination Branch</div>
					<div class="grid grid-cols-1 gap-2 max-h-[300px] overflow-y-auto pr-2">
						{#each branches.filter(b => b.id !== selectedBranchId) as branch}
							<button 
								onclick={() => targetBranchId = branch.id}
								class="flex items-center justify-between p-4 rounded-xl border-2 transition-all {targetBranchId === branch.id ? 'border-indigo-600 bg-indigo-50' : 'border-gray-100 bg-gray-50 hover:bg-white hover:border-gray-200'}"
							>
								<div class="flex items-center gap-3">
									<Building class="h-5 w-5 {targetBranchId === branch.id ? 'text-indigo-600' : 'text-gray-400'}" />
									<span class="font-bold text-sm text-gray-900">{branch.name}</span>
								</div>
								{#if targetBranchId === branch.id}
									<Check class="h-4 w-4 text-indigo-600" />
								{/if}
							</button>
						{/each}
					</div>
				</div>

				<div class="p-4 bg-amber-50 border border-amber-100 rounded-xl flex items-start gap-3">
					<AlertTriangle class="h-5 w-5 text-amber-500 shrink-0 mt-0.5" />
					<p class="text-[11px] text-amber-800 font-medium leading-relaxed italic">
						The quantity currently in the "In Stock" field will be transferred. Ensure values are correct before proceeding.
					</p>
				</div>
			</div>

			<div class="p-6 bg-gray-50 border-t flex gap-3">
				<button 
					onclick={() => showTransferModal = false}
					class="flex-1 py-3 text-sm font-bold text-gray-600 bg-white border border-gray-200 rounded-xl hover:bg-gray-100 transition-colors"
				>
					Cancel
				</button>
				<button 
					onclick={handleTransfer}
					disabled={!targetBranchId || transferLoading}
					class="flex-1 py-3 text-sm font-bold text-white bg-indigo-600 rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-100 transition-all disabled:opacity-50"
				>
					{transferLoading ? 'Processing...' : 'Confirm Transfer'}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	input[type="number"]::-webkit-inner-spin-button,
	input[type="number"]::-webkit-outer-spin-button {
		-webkit-appearance: none;
		margin: 0;
	}
</style>
