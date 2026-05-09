<script lang="ts">
	import { onMount } from 'svelte';
	import { ExpenseService, type Expense, type ExpenseType, type RecurrenceInterval } from '$lib/services/expense.service';
	import { supabase } from '$lib/supabase';
	import { 
		X, Upload, Calendar, Hash, 
		Briefcase, User, Info, RefreshCcw,
		Search, Package, Building
	} from 'lucide-svelte';
	import FileUpload from './FileUpload.svelte';

	let { open = $bindable(false), onClose, onSave } = $props<any>();

	let loading = $state(false);
	let expenseTypes = $state<ExpenseType[]>([]);
	let suppliers = $state<any[]>([]);
	let branches = $state<any[]>([]);
	let purchaseOrders = $state<any[]>([]);
	
	let form = $state<Partial<Expense>>({
		amount: 0,
		description: '',
		expense_date: new Date().toISOString().split('T')[0],
		expense_type_id: '',
		is_recurring: false,
		recur_interval: 'none',
		bank_name: '',
		bank_account_number: '',
		payment_terms: '',
		status: 'pending'
	});

	let selectedFile = $state<File | null>(null);
	let poSearchQuery = $state('');
	let showPOSuggestions = $state(false);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;

		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		const tenantId = user?.tenant_id;

		const [types, supData, brData, poData] = await Promise.all([
			ExpenseService.getExpenseTypes(),
			supabase.from('suppliers').select('id, name').eq('tenant_id', tenantId),
			supabase.from('branches').select('id, name').eq('tenant_id', tenantId),
			supabase.from('purchase_orders').select('id, po_number, total_cost, supplier:suppliers(name)').eq('tenant_id', tenantId).not('po_number', 'is', null)
		]);

		expenseTypes = types;
		suppliers = supData.data || [];
		branches = brData.data || [];
		purchaseOrders = poData.data || [];

		if (expenseTypes.length > 0) form.expense_type_id = expenseTypes[0].id;
		if (branches.length > 0) form.branch_id = branches[0].id;
	});

	let selectedType = $derived(expenseTypes.find(t => t.id === form.expense_type_id));
	let isProductPurchase = $derived(selectedType?.name === 'Product Purchase');

	async function handleSubmit() {
		if (!form.amount || !form.description || !form.expense_type_id) {
			alert('Please fill all required fields');
			return;
		}

		loading = true;
		try {
			const { data: { session } } = await supabase.auth.getSession();
			const newExpense = {
				...form,
				raised_by: session?.user?.id,
				tenant_id: (await supabase.from('users').select('tenant_id').eq('id', session?.user?.id).single()).data?.tenant_id
			};

			if (form.is_recurring && !form.next_recur_date) {
				// Default next date to one interval away
				const date = new Date(form.expense_date!);
				if (form.recur_interval === 'monthly') date.setMonth(date.getMonth() + 1);
				else if (form.recur_interval === 'weekly') date.setDate(date.getDate() + 7);
				newExpense.next_recur_date = date.toISOString().split('T')[0];
			}

			await ExpenseService.createExpense(newExpense, selectedFile || undefined);
			onSave();
			onClose();
		} catch (err: any) {
			alert('Error creating expense: ' + err.message);
		} finally {
			loading = false;
		}
	}

	function selectPO(po: any) {
		form.po_id = po.id;
		form.amount = po.total_cost;
		form.description = `Supply payment for ${po.po_number} from ${po.supplier?.name}`;
		form.supplier_id = po.supplier_id;
		poSearchQuery = po.po_number;
		showPOSuggestions = false;
	}
</script>

{#if open}
	<div class="fixed inset-0 z-[100] flex items-center justify-center p-4">
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onclick={onClose}></div>

		<div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-2xl flex flex-col max-h-[95vh] overflow-hidden">
			<!-- Header -->
			<div class="p-6 border-b border-gray-100 flex justify-between items-center shrink-0 bg-gray-50/50">
				<div>
					<h2 class="text-xl font-black text-gray-900 flex items-center gap-2">
						<Plus class="h-5 w-5 text-indigo-600" />
						Raise New Bill
					</h2>
					<p class="text-xs text-gray-500 mt-0.5">Input expense details and attach proof of bill.</p>
				</div>
				<button onclick={onClose} class="p-2 hover:bg-gray-100 rounded-xl transition-colors">
					<X class="h-5 w-5 text-gray-400" />
				</button>
			</div>

			<!-- Body -->
			<div class="flex-1 overflow-y-auto p-6 space-y-6">
				<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
					<!-- Type & Branch -->
					<div class="space-y-4">
						<div>
							<label for="type" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Expense Category</label>
							<select id="type" bind:value={form.expense_type_id} class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm font-bold text-gray-700 focus:ring-2 focus:ring-indigo-500 transition-all">
								{#each expenseTypes as type}
									<option value={type.id}>{type.name}</option>
								{/each}
							</select>
						</div>
						<div>
							<label for="branch" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Affected Branch</label>
							<select id="branch" bind:value={form.branch_id} class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm font-bold text-gray-700 focus:ring-2 focus:ring-indigo-500 transition-all">
								{#each branches as branch}
									<option value={branch.id}>{branch.name}</option>
								{/each}
							</select>
						</div>
					</div>

					<!-- Amount & Date -->
					<div class="space-y-4">
						<div>
							<label for="amount" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Total Amount (₦)</label>
							<div class="relative">
								<span class="absolute left-4 top-1/2 -translate-y-1/2 font-black text-gray-400">₦</span>
								<input 
									type="number" 
									id="amount" 
									bind:value={form.amount} 
									placeholder="0.00"
									class="w-full pl-8 pr-4 py-3 bg-gray-50 border-none rounded-xl text-lg font-black text-gray-900 focus:ring-2 focus:ring-indigo-500 transition-all placeholder:text-gray-300" 
								/>
							</div>
						</div>
						<div>
							<label for="date" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Expense Date</label>
							<input 
								type="date" 
								id="date" 
								bind:value={form.expense_date} 
								class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm font-bold text-gray-700 focus:ring-2 focus:ring-indigo-500 transition-all" 
							/>
						</div>
					</div>
				</div>

				<!-- PO Search Integration (Product Purchase) -->
				{#if isProductPurchase}
					<div class="p-4 bg-indigo-50 rounded-2xl border border-indigo-100 space-y-4 animate-in slide-in-from-top-2 duration-300">
						<div class="flex items-center gap-2 text-indigo-700 font-black text-xs uppercase tracking-widest mb-2">
							<Package class="h-4 w-4" />
							Supply Details
						</div>
						<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
							<div class="relative">
								<label for="po" class="block text-[10px] font-black text-indigo-400 uppercase tracking-widest mb-1.5">Link Purchase Order</label>
								<div class="relative">
									<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-indigo-300" />
									<input 
										type="text" 
										bind:value={poSearchQuery} 
										placeholder="Search PO number..." 
										onfocus={() => showPOSuggestions = true}
										class="w-full pl-10 pr-4 py-2.5 bg-white border-transparent rounded-xl text-sm font-bold text-indigo-900 focus:ring-2 focus:ring-indigo-500 transition-all placeholder:text-indigo-200"
									/>
								</div>
								{#if showPOSuggestions && purchaseOrders.filter(p => p.po_number.toLowerCase().includes(poSearchQuery.toLowerCase())).length > 0}
									<div class="absolute z-10 w-full mt-1 bg-white rounded-xl shadow-xl border border-indigo-100 overflow-hidden">
										{#each purchaseOrders.filter(p => p.po_number.toLowerCase().includes(poSearchQuery.toLowerCase())) as po}
											<button 
												onclick={() => selectPO(po)}
												class="w-full text-left px-4 py-3 hover:bg-indigo-50 transition-colors flex justify-between items-center"
											>
												<div>
													<p class="text-sm font-black text-indigo-900">{po.po_number}</p>
													<p class="text-[10px] text-indigo-400">{po.supplier?.name}</p>
												</div>
												<span class="text-xs font-black text-indigo-600">₦{Number(po.total_cost).toLocaleString()}</span>
											</button>
										{/each}
									</div>
								{/if}
							</div>
							<div>
								<label for="invoice" class="block text-[10px] font-black text-indigo-400 uppercase tracking-widest mb-1.5">Invoice Number</label>
								<input type="text" bind:value={form.invoice_number} placeholder="INV-001..." class="w-full px-4 py-2.5 bg-white border-transparent rounded-xl text-sm font-bold text-indigo-900 focus:ring-2 focus:ring-indigo-500 transition-all placeholder:text-indigo-200" />
							</div>
						</div>
						<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
							<div>
								<label for="due" class="block text-[10px] font-black text-indigo-400 uppercase tracking-widest mb-1.5">Due Date</label>
								<input type="date" bind:value={form.due_date} class="w-full px-4 py-2.5 bg-white border-transparent rounded-xl text-sm font-bold text-indigo-900 focus:ring-2 focus:ring-indigo-500 transition-all" />
							</div>
							<div>
								<label for="terms" class="block text-[10px] font-black text-indigo-400 uppercase tracking-widest mb-1.5">Payment Terms</label>
								<input type="text" bind:value={form.payment_terms} placeholder="Net 30, COD..." class="w-full px-4 py-2.5 bg-white border-transparent rounded-xl text-sm font-bold text-indigo-900 focus:ring-2 focus:ring-indigo-500 transition-all placeholder:text-indigo-200" />
							</div>
						</div>
					</div>
				{/if}

				<!-- Description -->
				<div>
					<label for="desc" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Description / Purpose</label>
					<textarea 
						id="desc" 
						bind:value={form.description} 
						rows="2" 
						placeholder="What is this expense for?"
						class="w-full bg-gray-50 border-none rounded-xl p-4 text-sm font-bold text-gray-700 focus:ring-2 focus:ring-indigo-500 transition-all placeholder:text-gray-300 resize-none"
					></textarea>
				</div>

				<!-- Recurrence Settings -->
				<div class="p-4 bg-emerald-50 rounded-2xl border border-emerald-100 flex items-center justify-between">
					<div class="flex items-center gap-3">
						<div class="h-10 w-10 rounded-xl bg-emerald-100 flex items-center justify-center text-emerald-600">
							<RefreshCcw class="h-5 w-5 {form.is_recurring ? 'animate-spin-slow' : ''}" />
						</div>
						<div>
							<p class="text-sm font-black text-emerald-900">Recurrent Bill</p>
							<p class="text-[10px] text-emerald-500">Automatically generate a pending bill every cycle.</p>
						</div>
					</div>
					<div class="flex items-center gap-4">
						{#if form.is_recurring}
							<select bind:value={form.recur_interval} class="bg-white border-transparent rounded-lg py-1 px-3 text-xs font-black text-emerald-700 focus:ring-2 focus:ring-emerald-500 outline-none transition-all">
								<option value="weekly">Weekly</option>
								<option value="monthly">Monthly</option>
								<option value="quarterly">Quarterly</option>
								<option value="yearly">Yearly</option>
							</select>
						{/if}
						<label class="relative inline-flex items-center cursor-pointer">
							<input type="checkbox" bind:checked={form.is_recurring} class="sr-only peer" />
							<div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
						</label>
					</div>
				</div>

				<!-- File Upload -->
				<div>
					<label for="receipt" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Attach Bill / Receipt</label>
					<FileUpload 
						onFileSelect={(file) => selectedFile = file}
						maxSize={5}
						accept="application/pdf,image/*"
					/>
				</div>
			</div>

			<!-- Footer -->
			<div class="p-6 border-t border-gray-100 bg-gray-50/50 flex gap-3 shrink-0">
				<button 
					onclick={onClose} 
					class="flex-1 py-3.5 text-sm font-black text-gray-500 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-all active:scale-95"
				>
					Cancel
				</button>
				<button 
					onclick={handleSubmit}
					disabled={loading}
					class="flex-1 py-3.5 text-sm font-black text-white bg-indigo-600 rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-100 transition-all active:scale-95 disabled:opacity-50 flex items-center justify-center gap-2"
				>
					{#if loading}
						<div class="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
						Processing...
					{:else}
						{selectedType?.is_auto_approve ? 'Submit & Auto-Approve' : 'Submit for Approval'}
					{/if}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	:global(.animate-spin-slow) {
		animation: spin 3s linear infinite;
	}
	@keyframes spin {
		from { transform: rotate(0deg); }
		to { transform: rotate(360deg); }
	}
</style>
