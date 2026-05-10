<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, Plus, Trash2, Search, AlertCircle, CheckCircle, Package } from 'lucide-svelte';
	import ProductPickerModal from '$lib/components/ProductPickerModal.svelte';

	let loading = $state(false);
	let saving = $state(false);
	let error = $state('');
	let success = $state('');

	let suppliers = $state<any[]>([]);
	let branches = $state<any[]>([]);
	let showProductPicker = $state(false);

	let form = $state({
		supplier_id: '',
		branch_id: '',
		notes: '',
		items: [] as any[]
	});

	onMount(async () => {
		const [suppRes, branchRes] = await Promise.all([
			supabase.from('suppliers').select('id, name').order('name'),
			supabase.from('branches').select('id, name').order('name')
		]);
		suppliers = suppRes.data || [];
		branches = branchRes.data || [];
		
		// If only one branch, select it by default
		if (branches.length === 1) form.branch_id = branches[0].id;
	});

	function addItem(product: any) {
		const existing = form.items.find(i => i.product_id === product.id);
		if (existing) {
			existing.expected_qty += 1;
		} else {
			form.items = [...form.items, {
				product_id: product.id,
				product_name: product.name,
				product_strength: product.strength,
				expected_qty: 1,
				unit_cost: 0 // Default to 0 as it's not in the master catalog
			}];
		}
	}

	function removeItem(index: number) {
		form.items = form.items.filter((_, i) => i !== index);
	}

	let totalCost = $derived(
		form.items.reduce((sum, item) => sum + (item.expected_qty * item.unit_cost), 0)
	);

	async function handleSubmit() {
		if (!form.supplier_id || !form.branch_id || form.items.length === 0) {
			error = 'Please fill all required fields and add at least one item.';
			return;
		}

		saving = true; error = '';
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) throw new Error('User not found');
			
			let activeTenantId = localStorage.getItem('active_tenant_id');
			if (!activeTenantId) {
				const { data: membership } = await supabase.from('user_tenants').select('tenant_id').eq('user_id', user.id).eq('is_active', true).limit(1).single();
				activeTenantId = membership?.tenant_id;
			}
			if (!activeTenantId) throw new Error('Tenant data not found. Please refresh.');

			// 1. Create PO header
			const { data: po, error: poErr } = await supabase
				.from('purchase_orders')
				.insert({
					tenant_id: activeTenantId,
					branch_id: form.branch_id,
					supplier_id: form.supplier_id,
					total_cost: totalCost,
					notes: form.notes,
					status: 'draft',
					created_by: user.id
				})
				.select()
				.single();

			if (poErr) throw poErr;

			// 2. Create PO items
			const poItems = form.items.map(item => ({
				po_id: po.id,
				product_id: item.product_id,
				expected_qty: item.expected_qty,
				unit_cost: item.unit_cost
			}));

			const { error: itemsErr } = await supabase.from('purchase_order_items').insert(poItems);
			if (itemsErr) throw itemsErr;

			success = 'Purchase Order created successfully!';
			setTimeout(() => goto(`/inventory/po/${po.id}`), 1000);
		} catch (err: any) {
			error = err.message || 'Failed to create purchase order';
		} finally {
			saving = false;
		}
	}
</script>

<svelte:head><title>New PO – Kemani POS</title></svelte:head>

<div class="p-6 max-w-4xl mx-auto">
	<ProductPickerModal 
		bind:open={showProductPicker} 
		selectedIds={form.items.map(i => i.product_id)}
		onSelect={(p) => addItem(p)} 
		onClose={() => showProductPicker = false} 
	/>

	<div class="flex items-center gap-3 mb-6">
		<a href="/inventory/po" class="p-2 hover:bg-gray-100 rounded-lg"><ArrowLeft class="h-5 w-5 text-gray-600" /></a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Create Purchase Order</h1>
			<p class="text-sm text-gray-500">Add items to a new procurement request</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-6 flex items-center gap-2">
			<AlertCircle class="h-5 w-5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	{#if success}
		<div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg mb-6 flex items-center gap-2">
			<CheckCircle class="h-5 w-5" /><p class="text-sm font-medium">{success}</p>
		</div>
	{/if}

	<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
		<div class="lg:col-span-2 space-y-6">
			<!-- Items Table -->
			<div class="bg-white rounded-2xl border shadow-sm overflow-hidden">
				<div class="p-4 border-b bg-gray-50 flex items-center justify-between gap-4">
					<h2 class="font-bold text-gray-900 text-sm uppercase tracking-wider">Order Items</h2>
					<button 
						type="button" 
						onclick={() => showProductPicker = true}
						class="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-xs font-black rounded-xl hover:bg-indigo-700 transition-all shadow-lg shadow-indigo-100 active:scale-95"
					>
						<Plus class="h-4 w-4" />
						Add Product
					</button>
				</div>

				<div class="overflow-x-auto">
					<table class="w-full text-sm">
						<thead class="bg-gray-50 text-gray-500 text-left">
							<tr>
								<th class="px-4 py-3 font-semibold">Product</th>
								<th class="px-4 py-3 font-semibold w-24 text-center">Qty</th>
								<th class="px-4 py-3 font-semibold w-32">Unit Cost</th>
								<th class="px-4 py-3 font-semibold w-32 text-right">Subtotal</th>
								<th class="px-4 py-3 w-10"></th>
							</tr>
						</thead>
						<tbody class="divide-y divide-gray-100">
							{#if form.items.length === 0}
								<tr>
									<td colspan="5" class="px-4 py-12 text-center text-gray-400 italic">
										No items added yet. Search and add products above.
									</td>
								</tr>
							{:else}
								{#each form.items as item, i}
									<tr>
										<td class="px-4 py-3">
											<p class="font-medium text-gray-900">{item.product_name}</p>
											{#if item.product_strength}
												<p class="text-[10px] font-bold text-indigo-500 uppercase tracking-widest">{item.product_strength}</p>
											{/if}
										</td>
										<td class="px-4 py-3">
											<input 
												type="number" 
												bind:value={item.expected_qty} 
												min="1" 
												class="w-full px-2 py-1 border border-gray-200 rounded text-center text-sm outline-none focus:ring-1 focus:ring-indigo-500"
											/>
										</td>
										<td class="px-4 py-3">
											<div class="relative">
												<span class="absolute left-2 top-1/2 -translate-y-1/2 text-gray-400 text-[10px]">₦</span>
												<input 
													type="number" 
													bind:value={item.unit_cost} 
													step="0.01" 
													class="w-full pl-5 pr-2 py-1 border border-gray-200 rounded text-sm outline-none focus:ring-1 focus:ring-indigo-500"
												/>
											</div>
										</td>
										<td class="px-4 py-3 text-right font-medium text-gray-900">
											{(item.expected_qty * item.unit_cost).toLocaleString()}
										</td>
										<td class="px-4 py-3 text-center">
											<button type="button" onclick={() => removeItem(i)} class="p-1.5 text-gray-400 hover:text-red-500 transition-colors">
												<Trash2 class="h-4 w-4" />
											</button>
										</td>
									</tr>
								{/each}
							{/if}
						</tbody>
					</table>
				</div>
			</div>
		</div>

		<div class="space-y-6">
			<!-- PO Details -->
			<div class="bg-white rounded-2xl border shadow-sm p-5 space-y-4">
				<h2 class="font-bold text-gray-900 text-sm uppercase tracking-wider">Order Info</h2>
				
				<div>
					<label class="block text-xs font-bold text-gray-500 uppercase mb-1">Supplier <span class="text-red-500">*</span></label>
					<select bind:value={form.supplier_id} class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none bg-white">
						<option value="">Select Supplier</option>
						{#each suppliers as s}<option value={s.id}>{s.name}</option>{/each}
					</select>
				</div>

				<div>
					<label class="block text-xs font-bold text-gray-500 uppercase mb-1">Target Branch <span class="text-red-500">*</span></label>
					<select bind:value={form.branch_id} class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none bg-white">
						<option value="">Select Branch</option>
						{#each branches as b}<option value={b.id}>{b.name}</option>{/each}
					</select>
				</div>

				<div>
					<label class="block text-xs font-bold text-gray-500 uppercase mb-1">Notes</label>
					<textarea bind:value={form.notes} rows="3" placeholder="Additional instructions..." class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none resize-none"></textarea>
				</div>

				<div class="pt-4 border-t">
					<div class="flex justify-between items-center mb-1">
						<span class="text-sm text-gray-500">Total Items</span>
						<span class="text-sm font-bold text-gray-900">{form.items.length}</span>
					</div>
					<div class="flex justify-between items-center mb-4">
						<span class="text-sm text-gray-500">Grand Total</span>
						<span class="text-lg font-bold text-indigo-600">₦{totalCost.toLocaleString()}</span>
					</div>
					<button 
						type="button" 
						disabled={saving} 
						onclick={handleSubmit}
						class="w-full flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-4 py-3 rounded-xl transition-all disabled:opacity-50"
					>
						<Save class="h-4 w-4" /> {saving ? 'Creating...' : 'Create Draft PO'}
					</button>
				</div>
			</div>
		</div>
	</div>
</div>
