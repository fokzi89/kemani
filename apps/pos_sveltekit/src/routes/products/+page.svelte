<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Search, Plus, Package, Edit, Eye, AlertTriangle, ChevronLeft, ChevronRight, Info, Download } from 'lucide-svelte';

	let products = $state<any[]>([]);
	let totalCount = $state(0);
	let loading = $state(true);
	let searchQuery = $state('');
	let selectedCategory = $state('all');
	let productTypeFilter = $state('all');
	let categories = $state<string[]>([]);
	let suppliers = $state<any[]>([]);
	let tenantId = $state('');
	let userBranchId = $state('');
	let businessName = $state('');
	let branchName = $state('');
	let staffName = $state('');
	let page = $state(1);
	let selectedIds = $state<string[]>([]);
	let lastResult = $state<{names: string[], count: number} | null>(null);
	let lastSearch = '';
	let lastCategory = 'all';
	let lastType = 'all';

	let userRole = $state('');
	let branches = $state<any[]>([]);
	let canUpload = $derived(
		selectedIds.length > 0 && 
		selectedIds.every(id => {
			const p = products.find(prod => prod.id === id);
			if (!p) return false;
			const prov = p.provisioning;
			return prov.qty > 0 && prov.cost > 0 && prov.selling > 0 && prov.unit_of_measure;
		})
	);

	// Invoice Details Modal State
	let showInvoiceModal = $state(false);
	let invoiceForm = $state({
		invoiceNum: '',
		purchaseOrderNum: '',
		addedBy: '',
		targetBranchId: ''
	});

	const PER_PAGE = 20; 
	const BATCH_LIMIT = 50; 

	let totalPages = $derived(Math.ceil(totalCount / PER_PAGE));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		const { data: userData, error: userErr } = await supabase.from('users')
			.select('tenant_id, branch_id, full_name, role')
			.eq('id', session.user.id)
			.single();
			
		if (userErr || !userData?.tenant_id) {
			console.error('Core user data not found:', userErr);
			loading = false;
			return;
		}

		tenantId = userData.tenant_id; 
		userBranchId = userData.branch_id || '';
		userRole = userData.role || '';
		staffName = userData.full_name || '';
		invoiceForm.addedBy = staffName;
		invoiceForm.targetBranchId = userBranchId;

		await Promise.all([loadCategories(), loadSuppliers(), loadBranches()]); 
		
		// Background fetch metadata
		const { data: tnt } = await supabase.from('tenants').select('name').eq('id', tenantId).single();
		if (tnt) businessName = tnt.name;

		if (userBranchId) {
			const { data: brch } = await supabase.from('branches').select('name').eq('id', userBranchId).single();
			if (brch) branchName = brch.name;
		}
	});

	async function loadCategories() {
		const { data } = await supabase.from('products')
			.select('category')
			.eq('tenant_id', tenantId)
			.not('category', 'is', null);
		categories = [...new Set((data || []).map(p => p.category))];
	}

	async function loadBranches() {
		if (!tenantId) return;
		const { data } = await supabase.from('branches')
			.select('id, name')
			.eq('tenant_id', tenantId);
		branches = data || [];
	}

	async function loadSuppliers() {
		if (!tenantId) return;
		const { data } = await supabase.from('suppliers')
			.select('id, name')
			.eq('is_active', true)
			.order('name');
		suppliers = data || [];
	}

	async function loadProducts() {
		if (!tenantId) return;
		loading = true;
		try {
			let query = supabase.from('products')
				.select('*', { count: 'exact' })
				.eq('tenant_id', tenantId)
				.or('product_type.is.null,product_type.neq.Laboratory test');

			if (selectedCategory !== 'all') query = query.eq('category', selectedCategory);
			if (productTypeFilter !== 'all') query = query.eq('product_type', productTypeFilter);
			
			if (searchQuery) {
				const q = `%${searchQuery}%`;
				query = query.or(`name.ilike.${q},barcode.ilike.${q}`);
			}

			const { data, count, error } = await query
				.order('created_at', { ascending: false })
				.range((page - 1) * PER_PAGE, page * PER_PAGE - 1);
			
			if (error) throw error;
			
			products = (data || []).map(p => ({
				...p,
				provisioning: { qty: 0, batch: '', cost: 0, selling: 0, expiry: '', supplier_id: null, unit_of_measure: p.unit_of_measure || 'unit' }
			}));
			totalCount = count || 0;
		} catch (err) {
			console.error('Failed to load products:', err);
		} finally {
			loading = false;
		}
	}

	let debounceTimeout: any;
	$effect(() => {
		if (!tenantId) return;
		
		const p = page;
		const q = searchQuery;
		const c = selectedCategory;
		const t = productTypeFilter;

		if (q !== lastSearch || c !== lastCategory || t !== lastType) {
			lastSearch = q;
			lastCategory = c;
			lastType = t;
			if (page !== 1) {
				page = 1;
				return;
			}
		}

		clearTimeout(debounceTimeout);
		debounceTimeout = setTimeout(() => {
			loadProducts();
		}, q ? 400 : 0);
	});

	async function prepareStockProvision() {
		if (!invoiceForm.targetBranchId) { alert('No branch selected for provisioning.'); return; }
		if (selectedIds.length === 0) return;

		// Validation: Ensure all selected products have qty, cost, selling, and UOM
		for (const id of selectedIds) {
			const p = products.find(prod => prod.id === id);
			if (!p) continue;
			const prov = p.provisioning;
			if (!prov.qty || prov.qty <= 0 || !prov.cost || prov.cost <= 0 || !prov.selling || prov.selling <= 0 || !prov.unit_of_measure) {
				alert(`Incomplete details for ${p.name}. Please fill in Quantity, Cost, Price, and Unit of Measure.`);
				return;
			}
		}
		
		// Generate the next Purchase Order Number
		await generateNextPOCode();
		showInvoiceModal = true;
	}

	async function generateNextPOCode() {
		try {
			const bId = invoiceForm.targetBranchId;
			if (!bId) return;

			let { data: seq, error } = await supabase
				.from('purchase_sequences')
				.select('last_serial')
				.eq('branch_id', bId)
				.single();

			if (error && error.code === 'PGRST116') {
				await supabase.from('purchase_sequences').insert({
					tenant_id: tenantId,
					branch_id: bId,
					last_serial: 0
				});
				seq = { last_serial: 0 };
			} else if (error) throw error;

			const nextSerial = (seq?.last_serial || 0) + 1;
			const prefix = businessName.substring(0, 3).toUpperCase();
			const bItem = branches.find(b => b.id === bId);
			const bNameClean = (bItem?.name || 'BRCH').replace(/\s+/g, '').toUpperCase();
			const serialStr = String(nextSerial).padStart(6, '0');
			
			invoiceForm.purchaseOrderNum = `${prefix}-${bNameClean}-${serialStr}`;
		} catch (err) {
			console.error('Error generating PO code:', err);
			invoiceForm.purchaseOrderNum = 'AUTO-GEN-ERROR';
		}
	}

	async function handleAddToStock() {
		if (!invoiceForm.invoiceNum) { alert('Please enter Invoice Number'); return; }
		if (!invoiceForm.targetBranchId) { alert('No branch selected'); return; }
		
		showInvoiceModal = false;
		loading = true;
		try {
			// 1. Prepare batch inserts
			const inserts = selectedIds.map(id => {
				const product = products.find(p => p.id === id) || {};
				
				if ((product.provisioning?.qty || 0) <= 0 || (product.provisioning?.cost || 0) <= 0 || (product.provisioning?.selling || 0) <= 0) {
					throw new Error(`Incomplete details for ${product.name}. Qty, Cost and Selling price must be greater than 0.`);
				}

				return {
					tenant_id: tenantId,
					branch_id: invoiceForm.targetBranchId,
					product_id: id,
					product_name: product.name,
					image_url: product.image_url || null,
					stock_quantity: product.provisioning?.qty || 0,
					batch_no: product.provisioning?.batch || '',
					expiry_date: product.provisioning?.expiry || null,
					cost_price: product.provisioning?.cost || 0,
					selling_price: product.provisioning?.selling || 0,
					supplier_id: product.provisioning?.supplier_id || null,
					unit_of_measure: product.provisioning?.unit_of_measure || 'unit',
					product_type: product.product_type || null,
					barcode: product.barcode || null,
					sku: product.provisioning?.batch || null,
					purchase_invoice: invoiceForm.invoiceNum,
					purchase_code: invoiceForm.purchaseOrderNum,
					added_by: invoiceForm.addedBy
				};
			});
			
			// 2. Perform insert
			const { error: err } = await supabase.from('branch_inventory').insert(inserts);
			if (err) throw err;
			
			// 3. Increment sequence
			const currentSerialStr = invoiceForm.purchaseOrderNum.split('-').pop() || '1';
			const currentSerial = parseInt(currentSerialStr);
			await supabase.from('purchase_sequences')
				.update({ last_serial: currentSerial })
				.eq('branch_id', invoiceForm.targetBranchId);

			lastResult = { 
				names: inserts.map(i => i.product_name), 
				count: inserts.length 
			};
			selectedIds = [];
			invoiceForm.invoiceNum = '';
		} catch (err: any) {
			alert(err.message || 'Failed to add products to stock');
		} finally {
			loading = false;
		}
	}

	function toggleSelectAll() {
		const allInPageSelected = paginated.length > 0 && paginated.every(p => selectedIds.includes(p.id));
		
		if (allInPageSelected) {
			// Deselect current page items
			const pageIds = paginated.map(p => p.id);
			selectedIds = selectedIds.filter(id => !pageIds.includes(id));
		} else {
			const newInPage = paginated.filter(p => !selectedIds.includes(p.id));
			if (selectedIds.length + newInPage.length > BATCH_LIMIT) {
				selectedIds = paginated.map(p => p.id);
			} else {
				selectedIds = [...selectedIds, ...newInPage.map(p => p.id)];
			}
		}
	}

	function toggleSelect(id: string) {
		if (selectedIds.includes(id)) {
			selectedIds = selectedIds.filter(i => i !== id);
		} else {
			if (selectedIds.length >= BATCH_LIMIT) {
				alert(`Maximum limit of ${BATCH_LIMIT} products per batch reached.`);
				return;
			}
			selectedIds = [...selectedIds, id];
		}
	}

	$effect(() => { searchQuery; selectedCategory; productTypeFilter; applyFilter(); });

	function stockBadge(qty: number) {
		if (qty <= 0) return 'bg-red-100 text-red-700';
		if (qty < 10) return 'bg-orange-100 text-orange-700';
		return 'bg-green-100 text-green-700';
	}

	function getExpiryClass(expiryStr: string) {
		if (!expiryStr) return 'bg-gray-50';
		const expiry = new Date(expiryStr);
		const today = new Date();
		const diffMs = expiry.getTime() - today.getTime();
		const diffMonths = diffMs / (1000 * 60 * 60 * 24 * 30.44);

		if (diffMonths <= 0) return 'bg-red-50 text-red-700 border-red-200';
		if (diffMonths < 3) return 'bg-red-50 text-red-600 border-red-200';
		if (diffMonths < 6) return 'bg-yellow-50 text-yellow-700 border-yellow-200';
		if (diffMonths >= 12) return 'bg-green-50 text-green-700 border-green-200';
		return 'bg-gray-50';
	}

	function downloadTemplate() {
		const headers = ['name', 'product_type', 'category', 'barcode', 'description', 'generic_name', 'strength', 'dosage_form', 'manufacturer', 'sample_type'];
		const tableHeader = headers.map(h => `<th style="background-color: #4f46e5; color: white; border: 1px solid #e5e7eb;">${h}</th>`).join('');
		const tableHtml = `
			<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
			<head>
				<meta charset="UTF-8">
				<!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet><x:Name>Bulk Product Template</x:Name><x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]-->
			</head>
			<body>
				<table>
					<thead>
						<tr>${tableHeader}</tr>
					</thead>
				</table>
			</body>
			</html>`;
		
		const blob = new Blob([tableHtml], { type: 'application/vnd.ms-excel' });
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.href = url;
		link.download = 'bulk_product_template.xls';
		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);
	}

	let topScrollRef = $state<HTMLDivElement | null>(null);
	let tableScrollRef = $state<HTMLDivElement | null>(null);

	function handleTopScroll() {
		if (topScrollRef && tableScrollRef) {
			tableScrollRef.scrollLeft = topScrollRef.scrollLeft;
		}
	}

	function handleTableScroll() {
		if (topScrollRef && tableScrollRef) {
			topScrollRef.scrollLeft = tableScrollRef.scrollLeft;
		}
	}
</script>

<svelte:head><title>Products – Kemani POS</title></svelte:head>

<div class="p-6 space-y-5 max-w-7xl mx-auto">
	<!-- Bulk Upload Info -->
	<div class="bg-blue-50 border border-blue-200 rounded-xl p-4 flex flex-col sm:flex-row sm:items-center gap-4 animate-in fade-in slide-in-from-top-2 duration-500">
		<div class="flex items-center gap-3 flex-1">
			<div class="h-10 w-10 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
				<Info class="h-5 w-5 text-blue-600" />
			</div>
			<div>
				<h3 class="font-bold text-blue-900 text-sm">Bulk Product Upload</h3>
				<p class="text-xs text-blue-700 mt-0.5">To upload products in bulk, please download the template below, fill it accurately, and send it to the admin for processing.</p>
			</div>
		</div>
		<button 
			onclick={downloadTemplate}
			class="inline-flex items-center justify-center gap-2 bg-white border border-blue-200 text-blue-700 font-bold px-4 py-2.5 rounded-xl hover:bg-blue-50 transition-all text-sm shadow-sm"
		>
			<Download class="h-4 w-4" /> Download Excel Template
		</button>
	</div>

	<!-- Batch Result Notification -->
	{#if lastResult}
		<div class="bg-green-50 border border-green-200 rounded-xl p-4 flex gap-4 animate-in fade-in slide-in-from-top-2 duration-300">
			<div class="h-10 w-10 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0">
				<Package class="h-5 w-5 text-green-600" />
			</div>
			<div class="flex-1">
				<h3 class="font-bold text-green-900 text-sm">Batch Provisioning Successful!</h3>
				<p class="text-xs text-green-700 mt-0.5">Successfully added {lastResult.count} products to branch inventory:</p>
				<div class="mt-2 flex flex-wrap gap-1.5">
					{#each lastResult.names as name}
						<span class="px-2 py-0.5 bg-white/50 border border-green-200 rounded text-[10px] font-medium text-green-800">{name}</span>
					{/each}
				</div>
			</div>
			<button onclick={() => lastResult = null} class="text-green-400 hover:text-green-600 transition-colors self-start p-1"><Plus class="h-5 w-5 rotate-45" /></button>
		</div>
	{/if}

	<!-- Header -->
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Products</h1>
			<p class="text-sm text-gray-500 mt-0.5">{totalCount} product{totalCount !== 1 ? 's' : ''}</p>
		</div>
		<div class="flex items-center gap-3">
			{#if selectedIds.length > 0}
				<div class="flex items-center gap-2">
					<span class="text-xs font-medium {selectedIds.length === BATCH_LIMIT ? 'text-amber-600' : 'text-gray-500'}">
						{selectedIds.length}/{BATCH_LIMIT} selected
					</span>
					<button 
						onclick={prepareStockProvision}
						disabled={!canUpload}
						title={!canUpload ? 'Please select products and fill all fields (Qty, Cost, Selling, UOM) to upload stock' : 'Proceed to upload stock'}
						class="inline-flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm shadow-lg shadow-green-100 disabled:opacity-30 disabled:cursor-not-allowed"
					>
						<Package class="h-4 w-4" /> Upload Stock
					</button>
				</div>
			{/if}
			<a href="/products/new" class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors text-sm">
				<Plus class="h-4 w-4" /> Add Product
			</a>
		</div>
	</div>

	<!-- Filters -->
	<div class="bg-white rounded-xl border p-4 flex flex-wrap gap-3">
		<div class="relative flex-1 min-w-48">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input type="text" bind:value={searchQuery} placeholder="Search by name or barcode..." 
				class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-shadow text-sm" />
		</div>
		<select bind:value={selectedCategory} class="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-white">
			<option value="all">All Categories</option>
			{#each categories as cat}<option value={cat}>{cat}</option>{/each}
		</select>
		<select bind:value={productTypeFilter} class="px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 bg-white">
			<option value="all">All Types</option>
			<option value="Grocery">Grocery</option>
			<option value="Drug">Drug</option>
		</select>
	</div>

	<!-- Table -->
	<div class="bg-white rounded-xl border overflow-hidden flex flex-col">
		{#if !loading && products.length > 0}
			<div 
				bind:this={topScrollRef} 
				onscroll={handleTopScroll}
				class="overflow-x-auto h-3 border-b bg-gray-50/50 scrollbar-thin"
			>
				<div style="width: 1200px; height: 1px;"></div>
			</div>
		{/if}

		{#if loading}
			<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
		{:else if products.length === 0}
			<div class="p-12 text-center text-gray-400">
				<Package class="h-12 w-12 mx-auto mb-3 opacity-30" />
				<p class="font-medium">No products found</p>
				<a href="/products/new" class="mt-3 inline-block text-sm text-indigo-600 hover:underline">Add your first product</a>
			</div>
		{:else}
			<div bind:this={tableScrollRef} onscroll={handleTableScroll} class="overflow-x-auto">
				<table class="w-full text-sm min-w-[1200px]">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-4 py-3 text-left">
								<input 
									type="checkbox" 
									checked={products.length > 0 && products.every(p => selectedIds.includes(p.id))} 
									onchange={toggleSelectAll}
									class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 w-4 h-4 cursor-pointer" 
								/>
							</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Product</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Stock Qty</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Batch No</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Exp Date</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Supplier</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">UOM</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Cost Price</th>
							<th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Selling</th>
							<th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider uppercase tracking-wider">Type/Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each products as product}
							<tr class="hover:bg-gray-50 transition-colors {selectedIds.includes(product.id) ? 'bg-indigo-50/30' : ''}">
								<td class="px-4 py-3">
									<input 
										type="checkbox" 
										checked={selectedIds.includes(product.id)}
										onchange={() => toggleSelect(product.id)}
										class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 w-4 h-4 cursor-pointer" 
									/>
								</td>
								<td class="px-4 py-3">
									<div class="flex items-center gap-3">
										<div class="w-10 h-10 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-xl flex items-center justify-center flex-shrink-0 overflow-hidden border border-white shadow-sm">
											{#if product.image_url}
												<img src={product.image_url} alt={product.name} class="w-full h-full object-cover" />
											{:else}
												<Package class="h-5 w-5 text-indigo-400" />
											{/if}
										</div>
										<div>
											<p class="font-semibold text-gray-900 leading-tight">{product.name}{product.strength ? ` – ${product.strength}` : ''}</p>
											<p class="text-xs text-gray-400 mt-0.5">{product.category || 'No Category'}</p>
										</div>
									</div>
								</td>
								<td class="px-2 py-3">
									<input type="number" bind:value={product.provisioning.qty} disabled={!selectedIds.includes(product.id)} placeholder="Qty"
										class="w-20 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-2 py-3">
									<input type="text" bind:value={product.provisioning.batch} disabled={!selectedIds.includes(product.id)} placeholder="Batch"
										class="w-24 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-2 py-3">
									<input type="date" bind:value={product.provisioning.expiry} disabled={!selectedIds.includes(product.id)} 
										class="w-32 px-2 py-1.5 border border-gray-200 rounded-lg text-xs focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium {getExpiryClass(product.provisioning.expiry)}" />
								</td>
								<td class="px-2 py-3">
									<select bind:value={product.provisioning.supplier_id} disabled={!selectedIds.includes(product.id)}
										class="w-40 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium">
										<option value={null}>No Supplier</option>
										{#each suppliers as s}<option value={s.id}>{s.name}</option>{/each}
									</select>
								</td>
								<td class="px-2 py-3">
									<select bind:value={product.provisioning.unit_of_measure} disabled={!selectedIds.includes(product.id)}
										class="w-24 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium">
										<option value="unit">Unit</option>
										<option value="sachet">Sachet</option>
										<option value="pack">Pack</option>
										<option value="bottle">Bottle</option>
									</select>
								</td>
								<td class="px-2 py-3">
									<input type="number" bind:value={product.provisioning.cost} disabled={!selectedIds.includes(product.id)} placeholder="Cost"
										class="w-24 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-2 py-3">
									<input type="number" bind:value={product.provisioning.selling} disabled={!selectedIds.includes(product.id)} placeholder="Price"
										class="w-24 px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-green-500 disabled:opacity-30 transition-all font-medium" />
								</td>
								<td class="px-4 py-3">
									<div class="flex items-center justify-end gap-2">
										<span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider {product.product_type === 'Drug' ? 'bg-blue-100 text-blue-700' : product.product_type === 'Laboratory test' ? 'bg-purple-100 text-purple-700' : 'bg-gray-100 text-gray-600'}">
											{product.product_type || 'Retail'}
										</span>
										<a href="/products/{product.id}" class="p-2 rounded-xl hover:bg-white hover:shadow-md text-gray-400 hover:text-indigo-600 transition-all border border-transparent hover:border-gray-100"><Eye class="h-4 w-4" /></a>
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Pagination -->
			{#if totalPages > 1}
				<div class="px-4 py-3 border-t bg-gray-50/30 flex items-center justify-between text-sm text-gray-600">
					<p class="text-xs font-medium">
						Showing <span class="text-gray-900 font-bold">{(page-1)*PER_PAGE+1}</span> – 
						<span class="text-gray-900 font-bold">{Math.min(totalCount, page * PER_PAGE)}</span> of 
						<span class="text-gray-900 font-bold">{totalCount}</span>
					</p>
					<div class="flex items-center gap-1">
						<button onclick={() => page--} disabled={page === 1} class="p-2 border border-gray-200 rounded-lg bg-white hover:bg-gray-50 transition-colors disabled:opacity-40">
							<ChevronLeft class="h-4 w-4" />
						</button>
						
						<div class="flex items-center gap-1 px-1">
							{#if totalPages <= 5}
								{#each Array.from({length: totalPages}, (_, i) => i + 1) as p}
									<button 
										onclick={() => page = p}
										class="w-8 h-8 rounded-lg text-xs font-bold transition-all {page === p ? 'bg-indigo-600 text-white shadow-md' : 'text-gray-400 hover:text-gray-900 hover:bg-white'}"
									>
										{p}
									</button>
								{/each}
							{:else}
								{@const start = Math.max(1, Math.min(page - 2, totalPages - 4))}
								{#each Array.from({length: 5}, (_, i) => start + i) as p}
									<button 
										onclick={() => page = p}
										class="w-8 h-8 rounded-lg text-xs font-bold transition-all {page === p ? 'bg-indigo-600 text-white shadow-md' : 'text-gray-400 hover:text-gray-900 hover:bg-white'}"
									>
										{p}
									</button>
								{/each}
							{/if}
						</div>

						<button onclick={() => page++} disabled={page === totalPages} class="p-2 border border-gray-200 rounded-lg bg-white hover:bg-gray-50 transition-colors disabled:opacity-40">
							<ChevronRight class="h-4 w-4" />
						</button>
					</div>
				</div>
			{/if}
		{/if}
	</div>
</div>

<!-- Invoice Details Modal -->
{#if showInvoiceModal}
	<div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
		<div class="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in duration-200">
			<div class="p-6 border-b flex justify-between items-center">
				<div>
					<h2 class="text-lg font-extrabold text-gray-900">Provisioning Details</h2>
					<p class="text-xs text-gray-500">Confirm purchase info for {selectedIds.length} items</p>
				</div>
				<button onclick={() => showInvoiceModal = false} class="p-2 hover:bg-gray-100 rounded-lg transition-colors">
					<Plus class="h-5 w-5 rotate-45 text-gray-400" />
				</button>
			</div>

			<div class="p-6 space-y-4">
				<div>
					<label for="invoice_num" class="block text-sm font-bold text-gray-700 mb-1.5">Purchase Invoice Number <span class="text-red-500">*</span></label>
					<input id="invoice_num" type="text" bind:value={invoiceForm.invoiceNum} placeholder="Enter invoice number..."
						class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 font-medium" />
				</div>

				{#if userRole === 'tenant_admin' || userRole === 'platform_admin'}
					<div>
						<label for="target_branch" class="block text-sm font-bold text-gray-700 mb-1.5">Destination Branch <span class="text-red-500">*</span></label>
						<select 
							id="target_branch" 
							bind:value={invoiceForm.targetBranchId}
							onchange={generateNextPOCode}
							class="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 font-medium"
						>
							{#each branches as b}
								<option value={b.id}>{b.name}</option>
							{/each}
						</select>
					</div>
				{/if}

				<div>
					<div class="block text-sm font-bold text-gray-700 mb-1.5">Purchase Order Code (Auto-generated)</div>
					<div class="px-4 py-2.5 bg-indigo-50 border border-indigo-100 rounded-xl font-mono text-sm text-indigo-700 font-bold uppercase tracking-wider">
						{invoiceForm.purchaseOrderNum}
					</div>
					<p class="text-[10px] text-indigo-400 mt-1 italic">Format: [Tenant]-[Branch]-[Serial]</p>
				</div>

				<div>
					<div class="block text-sm font-bold text-gray-700 mb-1.5">Added By</div>
					<div class="px-4 py-2.5 bg-gray-100 border border-gray-200 rounded-xl text-sm text-gray-600 font-medium">
						{invoiceForm.addedBy}
					</div>
				</div>
			</div>

			<div class="p-6 bg-gray-50 border-t flex gap-3">
				<button onclick={() => showInvoiceModal = false} class="flex-1 py-3 text-sm font-bold text-gray-600 bg-white border border-gray-200 rounded-xl hover:bg-gray-100 transition-colors">
					Cancel
				</button>
				<button onclick={handleAddToStock} disabled={!invoiceForm.invoiceNum}
					class="flex-1 py-3 text-sm font-bold text-white bg-green-600 rounded-xl hover:bg-green-700 shadow-lg shadow-green-100 transition-all disabled:opacity-50">
					Confirm & Upload
				</button>
			</div>
		</div>
	</div>
{/if}
