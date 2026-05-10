<script lang="ts">
	import { onMount } from 'svelte';
	import { ExpenseService, type Expense, type ExpenseType, type ExpenseStatus } from '$lib/services/expense.service';
	import { supabase } from '$lib/supabase';
	import { 
		Wallet, Plus, Filter, Search, 
		CheckCircle2, Clock, XCircle, 
		Banknote, FileText, Calendar, 
		MoreVertical, Eye, Check, X,
		ChevronRight, Download, CreditCard, Settings
	} from 'lucide-svelte';
	import { fade, slide } from 'svelte/transition';
	import ExpenseModal from '$lib/components/ExpenseModal.svelte';
	import ExpenseActionModal from '$lib/components/ExpenseActionModal.svelte';

	let expenses = $state<any[]>([]);
	let expenseTypes = $state<ExpenseType[]>([]);
	let branches = $state<any[]>([]);
	let loading = $state(true);
	let activeTab = $state<'overview' | 'pending' | 'approved' | 'paid'>('overview');
	
	// Filters
	let searchQuery = $state('');
	let selectedBranchId = $state('all');
	let dateRange = $state({ start: '', end: '' });

	let showAddModal = $state(false);
	let showActionModal = $state(false);
	let showTypeSettings = $state(false);
	let selectedExpense = $state<any>(null);
	let actionMode = $state<'approve' | 'reject' | 'pay'>('approve');

	let currentUser = $state<any>(null);
	let newTypeName = $state('');
	let isNewTypeAutoApprove = $state(false);
	let canApprove = $derived(currentUser?.role === 'tenant_admin' || currentUser?.canManageExpenses);

	let categoryTotals = $derived(
		expenseTypes.map(type => {
			const total = expenses
				.filter(e => e.expense_type_id === type.id)
				.reduce((sum, e) => sum + Number(e.amount), 0);
			return { ...type, total };
		}).sort((a, b) => b.total - a.total)
	);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;

		const cachedProfile = localStorage.getItem(`pos_user_profile_${session.user.id}`);
		if (cachedProfile) {
			currentUser = JSON.parse(cachedProfile);
		}

		if (canApprove) {
			await supabase.rpc('generate_recurring_expenses');
		}

		await Promise.all([
			loadExpenses(),
			loadExpenseTypes(),
			loadBranches()
		]);
		loading = false;
	});

	async function loadExpenses() {
		try {
			expenses = await ExpenseService.getExpenses({
				status: activeTab === 'overview' ? undefined : activeTab as ExpenseStatus,
				branch_id: selectedBranchId === 'all' ? undefined : selectedBranchId,
				startDate: dateRange.start || undefined,
				endDate: dateRange.end || undefined
			});
		} catch (err) {
			console.error('Failed to load expenses:', err);
		}
	}

	async function loadExpenseTypes() {
		expenseTypes = await ExpenseService.getExpenseTypes();
	}

	async function addExpenseType() {
		if (!newTypeName) return;
		const { error } = await supabase.from('expense_types').insert({
			tenant_id: currentUser.tenant_id,
			name: newTypeName,
			is_auto_approve: isNewTypeAutoApprove
		});
		if (error) alert(error.message);
		else {
			newTypeName = '';
			isNewTypeAutoApprove = false;
			await loadExpenseTypes();
		}
	}

	async function toggleTypeApproval(type: ExpenseType) {
		const { error } = await supabase
			.from('expense_types')
			.update({ is_auto_approve: !type.is_auto_approve })
			.eq('id', type.id);
		if (error) alert(error.message);
		else await loadExpenseTypes();
	}

	async function loadBranches() {
		const { data } = await supabase.from('branches').select('id, name').eq('tenant_id', currentUser.tenant_id);
		branches = data || [];
	}

	$effect(() => {
		if (activeTab || selectedBranchId || dateRange.start || dateRange.end) {
			loadExpenses();
		}
	});

	function getStatusColor(status: string) {
		switch (status) {
			case 'pending': return 'bg-amber-100 text-amber-700 border-amber-200';
			case 'approved': return 'bg-blue-100 text-blue-700 border-blue-200';
			case 'paid': return 'bg-emerald-100 text-emerald-700 border-emerald-200';
			case 'rejected': return 'bg-rose-100 text-rose-700 border-rose-200';
			default: return 'bg-gray-100 text-gray-700 border-gray-200';
		}
	}

	function getStatusIcon(status: string) {
		switch (status) {
			case 'pending': return Clock;
			case 'approved': return CheckCircle2;
			case 'paid': return Banknote;
			case 'rejected': return XCircle;
			default: return FileText;
		}
	}
</script>

<div class="p-6 space-y-6 max-w-7xl mx-auto min-h-screen">
	<!-- Header -->
	<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
		<div>
			<h1 class="text-lg font-bold text-gray-900 flex items-center gap-3">
				<div class="h-10 w-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white shadow-lg shadow-indigo-200">
					<Wallet class="h-6 w-6" />
				</div>
				Expenditure Tracker
			</h1>
			<p class="text-sm text-gray-500 mt-1">Manage, approve, and track business expenses and bills.</p>
		</div>
		<button 
			onclick={() => showAddModal = true}
			class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-6 py-3 rounded-xl transition-all shadow-lg shadow-indigo-100 hover:-translate-y-0.5 active:translate-y-0"
		>
			<Plus class="h-5 w-5" />
			Add New Expense
		</button>
	</div>

	{#if showAddModal}
		<ExpenseModal 
			open={showAddModal} 
			onClose={() => showAddModal = false} 
			onSave={loadExpenses} 
		/>
	{/if}

	<ExpenseActionModal 
		bind:open={showActionModal}
		expense={selectedExpense}
		mode={actionMode}
		onClose={() => { showActionModal = false; selectedExpense = null; }}
		onSave={loadExpenses}
	/>

	<!-- Stats & Tabs -->
	<div class="grid grid-cols-1 md:grid-cols-4 gap-4">
		<button 
			onclick={() => activeTab = 'overview'}
			class="p-4 rounded-2xl border-2 text-left transition-all {activeTab === 'overview' ? 'border-indigo-600 bg-white shadow-md ring-4 ring-indigo-50' : 'border-gray-100 bg-gray-50/50 hover:bg-white hover:border-gray-200'}"
		>
			<p class="text-[10px] font-semibold text-gray-400 uppercase tracking-widest">Total Overview</p>
			<p class="text-base font-bold text-gray-900 mt-1">₦{expenses.reduce((sum, e) => sum + Number(e.amount), 0).toLocaleString()}</p>
		</button>
		
		<button 
			onclick={() => activeTab = 'pending'}
			class="p-4 rounded-2xl border-2 text-left transition-all {activeTab === 'pending' ? 'border-amber-600 bg-white shadow-md ring-4 ring-amber-50' : 'border-gray-100 bg-gray-50/50 hover:bg-white hover:border-gray-200'}"
		>
			<p class="text-[10px] font-semibold text-amber-500 uppercase tracking-widest">Approval Queue</p>
			<p class="text-base font-bold text-gray-900 mt-1">{expenses.filter(e => e.status === 'pending').length} Pending</p>
		</button>

		<button 
			onclick={() => activeTab = 'approved'}
			class="p-4 rounded-2xl border-2 text-left transition-all {activeTab === 'approved' ? 'border-blue-600 bg-white shadow-md ring-4 ring-blue-50' : 'border-gray-100 bg-gray-50/50 hover:bg-white hover:border-gray-200'}"
		>
			<p class="text-[10px] font-semibold text-blue-500 uppercase tracking-widest">Bills to Pay</p>
			<p class="text-base font-bold text-gray-900 mt-1">{expenses.filter(e => e.status === 'approved').length} Approved</p>
		</button>

		<button 
			onclick={() => activeTab = 'paid'}
			class="p-4 rounded-2xl border-2 text-left transition-all {activeTab === 'paid' ? 'border-emerald-600 bg-white shadow-md ring-4 ring-emerald-50' : 'border-gray-100 bg-gray-50/50 hover:bg-white hover:border-gray-200'}"
		>
			<p class="text-[10px] font-semibold text-emerald-500 uppercase tracking-widest">Paid History</p>
			<p class="text-base font-bold text-gray-900 mt-1">{expenses.filter(e => e.status === 'paid').length} Settled</p>
		</button>
	</div>

	<!-- Category Breakdown (Conditional) -->
	{#if activeTab === 'overview' && categoryTotals.some(c => c.total > 0)}
		<div class="bg-white rounded-2xl border p-6 shadow-sm animate-in fade-in slide-in-from-bottom-2 duration-500">
			<h3 class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-4">Expense Breakdown by Category</h3>
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
				{#each categoryTotals.filter(c => c.total > 0) as cat}
					{@const percentage = (cat.total / expenses.reduce((sum, e) => sum + Number(e.amount), 0)) * 100}
					<div class="space-y-2">
						<div class="flex justify-between items-end">
							<span class="text-xs font-bold text-gray-700">{cat.name}</span>
							<span class="text-sm font-bold text-indigo-600">₦{cat.total.toLocaleString()}</span>
						</div>
						<div class="h-1.5 w-full bg-gray-100 rounded-full overflow-hidden">
							<div class="h-full bg-indigo-600 rounded-full" style="width: {percentage}%"></div>
						</div>
						<p class="text-[9px] font-bold text-gray-400 text-right">{percentage.toFixed(1)}% of total</p>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Filters Bar -->
	<div class="bg-white rounded-2xl border p-4 shadow-sm flex flex-wrap gap-4 items-center">
		<div class="flex items-center gap-2">
			{#if canApprove}
				<button 
					onclick={() => showTypeSettings = !showTypeSettings}
					class="p-3 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-all text-gray-500 shadow-sm"
					title="Configure Categories"
				>
					<Settings class="h-5 w-5" />
				</button>
			{/if}
			<div class="relative flex-1 min-w-[200px]">
				<Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input 
					type="text" 
					bind:value={searchQuery}
					placeholder="Search description, invoice..."
					class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border-transparent rounded-xl text-sm focus:bg-white focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all outline-none"
				/>
			</div>
		</div>

		{#if showTypeSettings && canApprove}
			<div class="w-full pt-4 border-t border-gray-100 animate-in slide-in-from-top-2">
				<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-3">Manage Categories & Auto-Approval</p>
				<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
					{#each expenseTypes as type}
						<div class="flex items-center justify-between p-3 bg-gray-50 rounded-xl border border-gray-100">
							<span class="text-xs font-bold text-gray-700">{type.name}</span>
							<button 
								onclick={() => toggleTypeApproval(type)}
								class="px-2 py-1 rounded-lg text-[9px] font-bold uppercase transition-all {type.is_auto_approve ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-200 text-gray-500'}"
							>
								{type.is_auto_approve ? 'Auto-Approve' : 'Manual Appr'}
							</button>
						</div>
					{/each}
					<div class="flex items-center gap-2 p-1.5 bg-indigo-50 rounded-xl border border-indigo-100">
						<input 
							type="text" 
							bind:value={newTypeName} 
							placeholder="New category..." 
							class="flex-1 bg-white border-none rounded-lg py-1.5 px-3 text-xs font-bold outline-none"
						/>
						<button 
							onclick={addExpenseType}
							class="p-1.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
						>
							<Plus class="h-4 w-4" />
						</button>
					</div>
				</div>
			</div>
		{/if}

		<div class="flex items-center gap-2">
			<Calendar class="h-4 w-4 text-gray-400" />
			<input type="date" bind:value={dateRange.start} class="text-xs font-bold bg-gray-50 border-none rounded-lg p-2 outline-none focus:ring-2 focus:ring-indigo-500" />
			<span class="text-gray-300">to</span>
			<input type="date" bind:value={dateRange.end} class="text-xs font-bold bg-gray-50 border-none rounded-lg p-2 outline-none focus:ring-2 focus:ring-indigo-500" />
		</div>

		<select 
			bind:value={selectedBranchId}
			class="bg-gray-50 border-none rounded-xl py-2.5 px-4 text-sm font-bold text-gray-700 outline-none focus:ring-2 focus:ring-indigo-500"
		>
			<option value="all">All Branches</option>
			{#each branches as branch}
				<option value={branch.id}>{branch.name}</option>
			{/each}
		</select>
	</div>

	<!-- Expenses List -->
	<div class="bg-white rounded-2xl border shadow-sm overflow-hidden min-h-[400px]">
		{#if loading}
			<div class="flex flex-col items-center justify-center py-24">
				<div class="w-10 h-10 border-4 border-indigo-100 border-t-indigo-600 rounded-full animate-spin"></div>
				<p class="text-xs font-bold text-gray-400 mt-4 uppercase tracking-widest italic">Syncing Ledger...</p>
			</div>
		{:else if expenses.length === 0}
			<div class="flex flex-col items-center justify-center py-24 text-center">
				<div class="h-16 w-16 bg-gray-50 rounded-2xl flex items-center justify-center text-gray-300 mb-4">
					<Wallet class="h-8 w-8" />
				</div>
				<h3 class="text-base font-bold text-gray-900">No Expenses Found</h3>
				<p class="text-sm text-gray-500 max-w-xs mx-auto mt-1">There are no records matching your current filters. Raise a new bill to get started.</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left border-collapse min-w-[1000px]">
					<thead class="bg-gray-50/80 border-b border-gray-100">
						<tr>
							<th class="px-6 py-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Date & Category</th>
							<th class="px-6 py-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Description</th>
							<th class="px-6 py-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Amount</th>
							<th class="px-6 py-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Status</th>
							<th class="px-6 py-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Tracking</th>
							<th class="px-6 py-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest text-right">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-50">
						{#each expenses as expense}
							{@const StatusIcon = getStatusIcon(expense.status)}
							<tr class="hover:bg-indigo-50/20 transition-colors group">
								<td class="px-6 py-4 whitespace-nowrap">
									<p class="text-sm font-bold text-gray-900">{new Date(expense.expense_date).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}</p>
									<span class="inline-flex items-center gap-1.5 text-[10px] font-bold text-indigo-600 uppercase tracking-tighter mt-1 px-2 py-0.5 bg-indigo-50 rounded-full">
										{expense.expense_types?.name || 'Uncategorized'}
									</span>
								</td>
								<td class="px-6 py-4">
									<div class="max-w-xs">
										<p class="text-sm font-bold text-gray-800 line-clamp-1">{expense.description}</p>
										{#if expense.invoice_number}
											<div class="flex items-center gap-1.5 mt-1">
												<FileText class="h-3 w-3 text-gray-300" />
												<span class="text-[10px] font-medium text-gray-400 uppercase tracking-widest">{expense.invoice_number}</span>
											</div>
										{/if}
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<p class="text-sm font-bold text-gray-900">₦{Number(expense.amount).toLocaleString()}</p>
									{#if expense.due_date}
										<p class="text-[10px] font-bold text-rose-500 mt-1">Due: {new Date(expense.due_date).toLocaleDateString()}</p>
									{/if}
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<span class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-bold border {getStatusColor(expense.status)} capitalize shadow-sm">
										<StatusIcon class="h-3.5 w-3.5" />
										{expense.status}
									</span>
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="space-y-1.5">
										<div class="flex items-center gap-2">
											<div class="h-5 w-5 rounded-full bg-gray-100 flex items-center justify-center text-[10px] font-bold text-gray-500">R</div>
											<span class="text-[11px] font-bold text-gray-600">By: {expense.raiser?.full_name}</span>
										</div>
										{#if expense.approved_by}
											<div class="flex items-center gap-2">
												<div class="h-5 w-5 rounded-full bg-blue-50 flex items-center justify-center text-[10px] font-bold text-blue-500">A</div>
												<span class="text-[11px] font-bold text-gray-600">Appr: {expense.approver?.full_name}</span>
											</div>
										{/if}
										{#if expense.paid_by}
											<div class="flex items-center gap-2">
												<div class="h-5 w-5 rounded-full bg-emerald-50 flex items-center justify-center text-[10px] font-bold text-emerald-500">P</div>
												<span class="text-[11px] font-bold text-gray-600">Paid: {expense.payer?.full_name}</span>
											</div>
										{/if}
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-right">
									<div class="flex items-center justify-end gap-2">
										<button 
											onclick={() => { selectedExpense = expense; /* open detail view if implemented */ }}
											class="p-2 text-gray-400 hover:text-indigo-600 hover:bg-white rounded-xl transition-all shadow-sm"
										>
											<Eye class="h-4 w-4" />
										</button>
										{#if expense.status === 'pending' && canApprove}
											<button 
												onclick={() => { selectedExpense = expense; actionMode = 'approve'; showActionModal = true; }}
												class="p-2 text-emerald-600 hover:bg-emerald-50 rounded-xl transition-all shadow-sm border border-transparent hover:border-emerald-100"
											>
												<Check class="h-4 w-4" />
											</button>
											<button 
												onclick={() => { selectedExpense = expense; actionMode = 'reject'; showActionModal = true; }}
												class="p-2 text-rose-600 hover:bg-rose-50 rounded-xl transition-all shadow-sm border border-transparent hover:border-rose-100"
											>
												<X class="h-4 w-4" />
											</button>
										{:else if expense.status === 'approved'}
											<button 
												onclick={() => { selectedExpense = expense; actionMode = 'pay'; showActionModal = true; }}
												class="inline-flex items-center gap-1.5 bg-emerald-600 text-white text-[10px] font-bold px-3 py-1.5 rounded-lg hover:bg-emerald-700 transition-all shadow-md shadow-emerald-100"
											>
												<CreditCard class="h-3 w-3" />
												PAY
											</button>
										{/if}
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

<style>
	:global(body) {
		background-color: #f8fafc;
	}
</style>
