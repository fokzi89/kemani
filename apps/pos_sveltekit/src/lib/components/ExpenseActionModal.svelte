<script lang="ts">
	import { ExpenseService, type Expense } from '$lib/services/expense.service';
	import { 
		CheckCircle2, XCircle, Banknote, 
		X, AlertCircle, Upload, User, 
		Building, CreditCard, Info
	} from 'lucide-svelte';
	import FileUpload from './FileUpload.svelte';

	let { open = $bindable(false), expense, mode, onClose, onSave } = $props<{
		open: boolean;
		expense: Expense | null;
		mode: 'approve' | 'reject' | 'pay';
		onClose: () => void;
		onSave: () => void;
	}>();

	let loading = $state(false);
	let rejectionReason = $state('');
	let paymentCollectedBy = $state('');
	let paymentEvidence = $state<File | null>(null);

	async function handleAction() {
		if (!expense) return;
		if (mode === 'reject' && !rejectionReason) {
			alert('Please provide a reason for rejection');
			return;
		}

		loading = true;
		try {
			const status = mode === 'approve' ? 'approved' : mode === 'reject' ? 'rejected' : 'paid';
			await ExpenseService.updateStatus(expense.id, status, {
				rejection_reason: rejectionReason,
				payment_collected_by: paymentCollectedBy,
				payment_evidence_file: paymentEvidence || undefined
			});
			onSave();
			onClose();
		} catch (err: any) {
			alert('Error: ' + err.message);
		} finally {
			loading = false;
		}
	}
</script>

{#if open && expense}
	<div class="fixed inset-0 z-[110] flex items-center justify-center p-4">
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" onclick={onClose}></div>

		<div class="relative bg-white rounded-3xl shadow-2xl w-full max-w-lg overflow-hidden animate-in fade-in zoom-in duration-200">
			<!-- Header -->
			<div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
				<div class="flex items-center gap-3">
					<div class="h-10 w-10 rounded-xl flex items-center justify-center {mode === 'approve' ? 'bg-blue-100 text-blue-600' : mode === 'reject' ? 'bg-rose-100 text-rose-600' : 'bg-emerald-100 text-emerald-600'}">
						{#if mode === 'approve'}<CheckCircle2 class="h-6 w-6" />
						{:else if mode === 'reject'}<XCircle class="h-6 w-6" />
						{:else}<Banknote class="h-6 w-6" />{/if}
					</div>
					<div>
						<h2 class="text-lg font-black text-gray-900 capitalize">{mode} Expense</h2>
						<p class="text-[10px] text-gray-400 font-black uppercase tracking-widest">{expense.invoice_number || 'No Invoice'}</p>
					</div>
				</div>
				<button onclick={onClose} class="p-2 hover:bg-gray-100 rounded-xl transition-colors">
					<X class="h-5 w-5 text-gray-400" />
				</button>
			</div>

			<!-- Content -->
			<div class="p-8 space-y-6">
				<!-- Summary Info -->
				<div class="p-4 bg-gray-50 rounded-2xl border border-gray-100 grid grid-cols-2 gap-4">
					<div>
						<p class="text-[9px] font-black text-gray-400 uppercase tracking-widest">Amount</p>
						<p class="text-lg font-black text-gray-900">₦{Number(expense.amount).toLocaleString()}</p>
					</div>
					<div>
						<p class="text-[9px] font-black text-gray-400 uppercase tracking-widest">Category</p>
						<p class="text-sm font-bold text-gray-700">{(expense as any).expense_types?.name}</p>
					</div>
					<div class="col-span-2 pt-2 border-t border-gray-200/50">
						<p class="text-[9px] font-black text-gray-400 uppercase tracking-widest">Description</p>
						<p class="text-xs font-medium text-gray-600 italic leading-relaxed">"{expense.description}"</p>
					</div>
				</div>

				{#if mode === 'reject'}
					<div class="space-y-2 animate-in slide-in-from-top-2">
						<label for="reason" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest">Rejection Reason</label>
						<textarea 
							id="reason" 
							bind:value={rejectionReason} 
							rows="3" 
							placeholder="Explain why this expense was rejected..."
							class="w-full bg-rose-50/30 border-rose-100 rounded-2xl p-4 text-sm font-bold text-gray-700 focus:ring-2 focus:ring-rose-500 transition-all placeholder:text-rose-200 resize-none outline-none"
						></textarea>
					</div>
				{/if}

				{#if mode === 'pay'}
					<div class="space-y-4 animate-in slide-in-from-top-2">
						<div class="grid grid-cols-1 gap-4">
							<div>
								<label for="collector" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Payment Collected By</label>
								<div class="relative">
									<User class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-300" />
									<input 
										type="text" 
										id="collector" 
										bind:value={paymentCollectedBy} 
										placeholder="Name of recipient..."
										class="w-full pl-10 pr-4 py-3 bg-emerald-50/30 border-none rounded-xl text-sm font-bold text-gray-700 focus:ring-2 focus:ring-emerald-500 transition-all outline-none"
									/>
								</div>
							</div>
						</div>

						{#if expense.bank_account_number}
							<div class="p-3 bg-blue-50 rounded-xl border border-blue-100 flex items-start gap-3">
								<Info class="h-4 w-4 text-blue-500 mt-0.5" />
								<div>
									<p class="text-[10px] font-black text-blue-800 uppercase tracking-widest">Transfer Details</p>
									<p class="text-xs font-bold text-blue-900 mt-0.5">{expense.bank_name} • {expense.bank_account_number}</p>
								</div>
							</div>
						{/if}

						<div>
							<label for="evidence" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1.5">Payment Evidence (Receipt/Screenshot)</label>
							<FileUpload 
								onFileSelect={(file) => paymentEvidence = file}
								maxSize={5}
								accept="image/*,application/pdf"
							/>
						</div>
					</div>
				{/if}

				{#if mode === 'approve'}
					<div class="p-4 bg-blue-50 rounded-2xl border border-blue-100 flex items-start gap-3">
						<div class="h-8 w-8 rounded-lg bg-blue-100 flex items-center justify-center text-blue-600 shrink-0">
							<CheckCircle2 class="h-5 w-5" />
						</div>
						<p class="text-xs font-medium text-blue-800 leading-relaxed">
							By approving this bill, you are authorizing it for payment. It will move to the "Bills to Pay" list.
						</p>
					</div>
				{/if}
			</div>

			<!-- Footer -->
			<div class="p-6 bg-gray-50 border-t border-gray-100 flex gap-3">
				<button 
					onclick={onClose}
					class="flex-1 py-4 text-sm font-black text-gray-500 bg-white border border-gray-200 rounded-2xl hover:bg-gray-50 transition-all active:scale-95"
				>
					Cancel
				</button>
				<button 
					onclick={handleAction}
					disabled={loading}
					class="flex-1 py-4 text-sm font-black text-white rounded-2xl transition-all shadow-lg active:scale-95 disabled:opacity-50 flex items-center justify-center gap-2
					{mode === 'approve' ? 'bg-blue-600 hover:bg-blue-700 shadow-blue-100' : mode === 'reject' ? 'bg-rose-600 hover:bg-rose-700 shadow-rose-100' : 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-100'}"
				>
					{#if loading}
						<div class="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
						Processing...
					{:else}
						Confirm {mode}
					{/if}
				</button>
			</div>
		</div>
	</div>
{/if}
