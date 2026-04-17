<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { 
		FileText, Plus, Trash2, Edit, AlertCircle, Phone, 
		User, Search, ChevronLeft, ChevronRight, MoreHorizontal,
		Filter, Clock, CheckCircle2, XCircle, AlertTriangle
	} from 'lucide-svelte';

	let provider = $state<any>(null);
	let prescriptions = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');

	// Pagination state
	let currentPage = $state(1);
	let pageSize = 10;
	let totalCount = $state(0);
	let totalPages = $derived(Math.ceil(totalCount / pageSize));

	// Deletion state
	let deleteConfirmOpen = $state(false);
	let prescriptionToDelete = $state<string | null>(null);
	let deleting = $state(false);

	let searchTimeout: any;
	$effect(() => {
		// Debounce search and reset to page 1
		if (searchQuery !== undefined) {
			clearTimeout(searchTimeout);
			searchTimeout = setTimeout(() => {
				currentPage = 1;
				if (provider) loadPrescriptions(provider.id);
			}, 400);
		}
	});

	$effect(() => {
		// Load when page changes
		if (currentPage > 0 && provider) {
			loadPrescriptions(provider.id);
		}
	});

	onMount(async () => {
		const { data } = await supabase.auth.getSession();
		const session = data?.session;

		if (!session) {
			goto('/auth/login');
			return;
		}

		const { data: providerData } = await supabase
			.from('healthcare_providers')
			.select('*')
			.eq('user_id', session.user.id)
			.single();

		provider = providerData;

		if (provider) {
			await loadPrescriptions(provider.id);
		}

		loading = false;
	});

	async function loadPrescriptions(providerId: string) {
		loading = true;

		const start = (currentPage - 1) * pageSize;
		const end = start + pageSize - 1;

		let query = supabase
			.from('prescriptions')
			.select(`
				*,
				patients (full_name, profile_photo_url, phone),
				prescribed_drugs (id)
			`, { count: 'exact' })
			.eq('provider_id', providerId);
		
		if (searchQuery) {
			// Search by patient name or prescription code
			// Note: querying across joins in .or() is tricky in Supabase, 
			// so we mainly focus on prescription_code or use a simpler filter
			query = query.or(`prescription_code.ilike.%${searchQuery}%,notes.ilike.%${searchQuery}%`);
		}

		const { data, count, error } = await query
			.order('created_at', { ascending: false })
			.range(start, end);
		
		if (!error && data) {
			prescriptions = data;
			totalCount = count || 0;
		} else if (error) {
			console.error('Error loading prescriptions:', error);
		}

		loading = false;
	}

	function confirmDelete(id: string) {
		prescriptionToDelete = id;
		deleteConfirmOpen = true;
	}

	async function handleDelete() {
		if (!prescriptionToDelete) return;
		deleting = true;
		
		try {
			const { error } = await supabase
				.from('prescriptions')
				.delete()
				.eq('id', prescriptionToDelete);

			if (error) throw error;
			
			await loadPrescriptions(provider.id);
		} catch (err: any) {
			alert('Failed to delete: ' + err.message);
		} finally {
			deleting = false;
			deleteConfirmOpen = false;
			prescriptionToDelete = null;
		}
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'N/A';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}

	function getStatusConfig(status: string) {
		switch (status?.toLowerCase()) {
			case 'active':
				return { label: 'Active', color: 'bg-green-50 text-green-700 border-green-100', icon: CheckCircle2 };
			case 'fulfilled':
				return { label: 'Fulfilled', color: 'bg-blue-50 text-blue-700 border-blue-100', icon: CheckCircle2 };
			case 'expired':
				return { label: 'Expired', color: 'bg-red-50 text-red-700 border-red-100', icon: Clock };
			case 'cancelled':
				return { label: 'Cancelled', color: 'bg-gray-50 text-gray-700 border-gray-100', icon: XCircle };
			case 'draft':
				return { label: 'Draft', color: 'bg-amber-50 text-amber-700 border-amber-100', icon: AlertTriangle };
			default:
				return { label: status || 'Unknown', color: 'bg-gray-50 text-gray-600 border-gray-100', icon: AlertCircle };
		}
	}
</script>

<svelte:head>
	<title>Prescriptions History - Kemani</title>
</svelte:head>

<div class="min-h-screen p-4 sm:p-6 lg:p-8 bg-[#F8FAFC]">
	<div class="max-w-7xl mx-auto space-y-8">
		<!-- Header -->
		<div class="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
			<div>
				<h2 class="text-xl font-bold text-gray-900 tracking-tight">Prescription History</h2>
				<p class="text-gray-500 mt-2 font-medium">Manage and track all issued medical orders</p>
			</div>
			
			<div class="flex items-center gap-3">
				<a
					href="/prescriptions/add"
					class="px-6 py-3 bg-gray-900 hover:bg-black text-white font-bold rounded-2xl transition-all flex items-center gap-2 shadow-lg shadow-gray-200 active:scale-95"
				>
					<Plus class="h-5 w-5" />
					New Prescription
				</a>
			</div>
		</div>

		<!-- Search & Stats Bar -->
		<div class="grid grid-cols-1 lg:grid-cols-4 gap-4">
			<div class="lg:col-span-3 relative group">
				<Search class="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400 group-focus-within:text-gray-900 transition-colors" />
				<input
					type="text"
					bind:value={searchQuery}
					placeholder="Search by prescription code or clinical notes..."
					class="w-full pl-12 pr-4 py-4 bg-white border border-gray-200 rounded-2xl focus:ring-4 focus:ring-gray-900/5 focus:border-gray-900 transition-all shadow-sm font-medium text-gray-700"
				/>
			</div>
			<div class="bg-white border border-gray-200 rounded-2xl p-4 flex items-center justify-between shadow-sm">
				<div class="flex items-center gap-3">
					<div class="h-10 w-10 bg-gray-50 rounded-xl flex items-center justify-center">
						<FileText class="h-5 w-5 text-gray-600" />
					</div>
					<div>
						<p class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Total Records</p>
						<p class="text-lg font-black text-gray-900">{totalCount}</p>
					</div>
				</div>
				<Filter class="h-5 w-5 text-gray-300" />
			</div>
		</div>

		<!-- Main Content -->
		<div class="bg-white rounded-[2rem] shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden min-h-[500px] flex flex-col">
			{#if loading && prescriptions.length === 0}
				<div class="flex-1 flex flex-col items-center justify-center p-12">
					<div class="relative w-16 h-16">
						<div class="absolute inset-0 border-4 border-gray-100 rounded-full"></div>
						<div class="absolute inset-0 border-4 border-t-gray-900 rounded-full animate-spin"></div>
					</div>
					<p class="mt-6 text-gray-500 font-bold animate-pulse">Synchronizing clinical data...</p>
				</div>
			{:else if prescriptions.length === 0}
				<div class="flex-1 flex flex-col items-center justify-center p-12 text-center">
					<div class="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mb-6">
						<FileText class="h-12 w-12 text-gray-300" />
					</div>
					<h3 class="text-2xl font-black text-gray-900">No prescriptions found</h3>
					<p class="text-gray-500 max-w-sm mt-3 font-medium">
						{searchQuery 
							? "We couldn't find any records matching your search criteria." 
							: "Start building your clinical history by issuing your first digital prescription."}
					</p>
					{#if !searchQuery}
						<a 
							href="/prescriptions/add" 
							class="mt-8 px-8 py-3 bg-gray-900 text-white font-bold rounded-2xl hover:bg-black transition-all shadow-lg shadow-gray-200 active:scale-95"
						>
							Create First Order
						</a>
					{:else}
						<button 
							onclick={() => searchQuery = ''}
							class="mt-6 text-gray-900 font-bold hover:underline"
						>
							Clear search filters
						</button>
					{/if}
				</div>
			{:else}
				<div class="flex-1 overflow-x-auto">
					<table class="w-full text-left border-collapse">
						<thead>
							<tr class="bg-gray-50/50 border-b border-gray-100">
								<th class="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Patient Details</th>
								<th class="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Order Status</th>
								<th class="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em] text-center">Meds</th>
								<th class="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Date Issued</th>
								<th class="px-8 py-5 text-[10px] font-black text-gray-400 uppercase tracking-[0.2em] text-right">Settings</th>
							</tr>
						</thead>
						<tbody class="divide-y divide-gray-50">
							{#each prescriptions as prescription}
								{@const status = getStatusConfig(prescription.status)}
								<tr class="hover:bg-gray-50/80 transition-all group">
									<td class="px-8 py-6">
										<div class="flex items-center gap-4">
											<div class="h-12 w-12 shrink-0 bg-white rounded-2xl border border-gray-100 flex items-center justify-center overflow-hidden shadow-sm group-hover:scale-105 transition-transform duration-300">
												{#if prescription.patients?.profile_photo_url}
													<img src={prescription.patients.profile_photo_url} alt="Profile" class="h-full w-full object-cover" />
												{:else}
													<User class="h-6 w-6 text-gray-300" />
												{/if}
											</div>
											<div>
												<div class="font-bold text-gray-900 leading-tight">
													{prescription.patients?.full_name || 'Unknown Patient'}
												</div>
												<div class="flex items-center gap-2 mt-1">
													<p class="text-[10px] font-black text-gray-400 uppercase tracking-wider bg-gray-100 px-2 py-0.5 rounded-md">
														{prescription.prescription_code || prescription.id.slice(0, 8)}
													</p>
													{#if prescription.patients?.phone}
														<span class="text-gray-300">•</span>
														<p class="text-xs text-gray-500 font-medium">{prescription.patients.phone}</p>
													{/if}
												</div>
											</div>
										</div>
									</td>

									<td class="px-8 py-6">
										<div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl border {status.color} font-bold text-[10px] uppercase tracking-wider">
											<status.icon class="h-3.5 w-3.5" />
											{status.label}
										</div>
									</td>

									<td class="px-8 py-6 text-center">
										<div class="inline-flex items-center justify-center w-8 h-8 bg-gray-100 text-black rounded-xl text-xs font-black shadow-sm transition-colors">
											{prescription.prescribed_drugs?.length || 0}
										</div>
									</td>

									<td class="px-8 py-6">
										<div class="text-gray-900 font-bold">{formatDate(prescription.created_at)}</div>
										<div class="text-[10px] text-gray-400 font-medium mt-0.5 uppercase tracking-tighter">Issue Timestamp</div>
									</td>

									<td class="px-8 py-6 text-right">
										<div class="flex items-center justify-end gap-2 transition-opacity">
											<a 
												href="/prescriptions/edit/{prescription.id}" 
												class="p-2.5 bg-white border border-gray-100 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-xl transition-all shadow-sm active:scale-90"
												title="Edit Orders"
											>
												<Edit class="h-4 w-4" />
											</a>
											<button 
												onclick={() => confirmDelete(prescription.id)} 
												class="p-2.5 bg-white border border-gray-100 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-all shadow-sm active:scale-90"
												title="Archive Record"
											>
												<Trash2 class="h-4 w-4" />
											</button>
										</div>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>

				<!-- Pagination Footer -->
				<div class="px-8 py-6 bg-gray-50/50 border-t border-gray-100 flex flex-col sm:flex-row items-center justify-between gap-4">
					<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">
						Showing <span class="text-gray-900">{prescriptions.length}</span> of <span class="text-gray-900">{totalCount}</span> records
					</p>

					<div class="flex items-center gap-1 bg-white p-1 rounded-2xl border border-gray-100 shadow-sm">
						<button
							onclick={() => currentPage = Math.max(1, currentPage - 1)}
							disabled={currentPage === 1 || loading}
							class="p-2 hover:bg-gray-50 rounded-xl disabled:opacity-30 disabled:hover:bg-transparent transition-colors text-gray-600"
						>
							<ChevronLeft class="h-5 w-5" />
						</button>

						<div class="flex items-center gap-1 px-4">
							<span class="text-sm font-black text-gray-900">{currentPage}</span>
							<span class="text-[10px] font-black text-gray-400 uppercase uppercase px-1">of</span>
							<span class="text-sm font-black text-gray-900">{totalPages || 1}</span>
						</div>

						<button
							onclick={() => currentPage = Math.min(totalPages, currentPage + 1)}
							disabled={currentPage === totalPages || loading || totalPages === 0}
							class="p-2 hover:bg-gray-50 rounded-xl disabled:opacity-30 disabled:hover:bg-transparent transition-colors text-gray-600"
						>
							<ChevronRight class="h-5 w-5" />
						</button>
					</div>
				</div>
			{/if}
		</div>
	</div>
</div>

<!-- Delete Confirmation Modal -->
{#if deleteConfirmOpen}
	<div class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-md animate-in fade-in duration-300">
		<div class="bg-white rounded-[2.5rem] shadow-2xl w-full max-w-sm overflow-hidden animate-in zoom-in-95 duration-300">
			<div class="p-10 text-center">
				<div class="w-20 h-20 rounded-3xl bg-red-50 flex items-center justify-center mx-auto mb-6 transform rotate-3">
					<AlertTriangle class="h-10 w-10 text-red-600" />
				</div>
				<h3 class="text-2xl font-black text-gray-900 mb-3 tracking-tight">Archive Order?</h3>
				<p class="text-sm text-gray-500 mb-8 font-medium leading-relaxed px-2">This will permanently remove the prescription and all recorded medications from your history.</p>
				
				<div class="flex flex-col gap-3">
					<button 
						onclick={handleDelete}
						disabled={deleting}
						class="w-full py-4 bg-red-600 hover:bg-red-700 text-white font-black rounded-2xl transition-all shadow-lg shadow-red-100 active:scale-95 disabled:opacity-50 flex items-center justify-center gap-2"
					>
						{#if deleting}
							<div class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
							Finalizing...
						{:else}
							Yes, Delete Record
						{/if}
					</button>
					<button 
						onclick={() => deleteConfirmOpen = false} 
						disabled={deleting}
						class="w-full py-4 bg-gray-50 hover:bg-gray-100 text-gray-900 font-black rounded-2xl transition-all active:scale-95 disabled:opacity-50"
					>
						Cancel
					</button>
				</div>
			</div>
		</div>
	</div>
{/if}

<style>
	:global(body) {
		background-color: #F8FAFC;
	}
</style>
