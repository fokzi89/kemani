<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { FileText, Plus, Trash2, Edit, AlertCircle, Phone, User, Search } from 'lucide-svelte';

	let provider = $state<any>(null);
	let prescriptions = $state<any[]>([]);
	let loading = $state(true);

	// Deletion state
	let deleteConfirmOpen = $state(false);
	let prescriptionToDelete = $state<string | null>(null);
	let deleting = $state(false);

	onMount(async () => {
		const { data } = await supabase.auth.getSession();
		const session = data?.session;

		if (session) {
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();

			provider = providerData;

			if (provider) {
				await loadPrescriptions(provider.id);
			}
		}

		loading = false;
	});

	async function loadPrescriptions(providerId: string) {
		const { data, error } = await supabase
			.from('prescriptions')
			.select(`
				*,
				patients (full_name, profile_photo_url, phone),
				prescribed_drugs (id)
			`)
			.eq('provider_id', providerId)
			.order('created_at', { ascending: false });
		
		if (!error && data) {
			prescriptions = data;
		}
	}

	function confirmDelete(id: string) {
		prescriptionToDelete = id;
		deleteConfirmOpen = true;
	}

	async function handleDelete() {
		if (!prescriptionToDelete) return;
		deleting = true;
		
		try {
			// First, delete associated prescribed drugs (though ON DELETE CASCADE should handle this if set up correctly)
			// But just in case:
			await supabase.from('prescribed_drugs').delete().eq('prescription_id', prescriptionToDelete);
			
			const { error } = await supabase
				.from('prescriptions')
				.delete()
				.eq('id', prescriptionToDelete);

			if (error) throw error;
			
			prescriptions = prescriptions.filter(p => p.id !== prescriptionToDelete);
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
</script>

<svelte:head>
	<title>Prescriptions History - Kemani</title>
</svelte:head>

<div class="min-h-screen p-4 sm:p-6 lg:p-8 bg-gray-50">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white rounded-xl shadow-sm p-5 border border-gray-100">
			<div>
				<h2 class="text-2xl font-bold text-gray-900 tracking-tight">Prescription History</h2>
				<p class="text-sm text-gray-500 mt-1">Manage all your patient prescriptions here</p>
			</div>
			
			<a
				href="/prescriptions/add"
				class="w-full sm:w-auto px-5 py-2.5 bg-gray-900 hover:bg-black text-white font-medium rounded-lg transition-colors flex justify-center items-center gap-2 shadow-sm"
			>
				<Plus class="h-5 w-5" />
				Add Prescription
			</a>
		</div>

		<!-- Prescriptions List -->
		{#if loading}
			<div class="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center">
				<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600 mx-auto"></div>
				<p class="mt-4 text-gray-500 text-sm">Loading history...</p>
			</div>
		{:else if prescriptions.length === 0}
			<div class="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center flex flex-col items-center">
				<div class="bg-primary-50 p-4 rounded-full mb-4">
					<FileText class="h-10 w-10 text-primary-400" />
				</div>
				<h3 class="text-lg font-semibold text-gray-900">No prescriptions yet</h3>
				<p class="text-sm text-gray-500 max-w-sm mt-1 mb-6">You haven't issued any prescriptions yet. Click the button above to create one.</p>
				<a href="/prescriptions/add" class="text-primary-600 font-medium hover:underline text-sm flex items-center gap-1">
					<Plus class="h-4 w-4" /> Create First Prescription
				</a>
			</div>
		{:else}
			<div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
				<div class="overflow-x-auto">
					<table class="w-full text-left text-sm whitespace-nowrap">
						<thead class="bg-gray-50 border-b border-gray-100 text-gray-600 text-xs uppercase tracking-wider">
							<tr>
								<th class="px-6 py-4 font-semibold">Patient Name</th>
								<th class="px-6 py-4 font-semibold">Contact</th>
								<th class="px-6 py-4 font-semibold text-center">Drugs</th>
								<th class="px-6 py-4 font-semibold">Date Issued</th>
								<th class="px-6 py-4 font-semibold text-right">Actions</th>
							</tr>
						</thead>
						<tbody class="divide-y divide-gray-50 text-gray-700">
							{#each prescriptions as prescription}
								<tr class="hover:bg-gray-50 transition-colors">
									<!-- Patient Column -->
									<td class="px-6 py-4">
										<div class="flex items-center gap-3">
											<div class="h-10 w-10 shrink-0 bg-primary-100 rounded-full flex items-center justify-center overflow-hidden border border-primary-200">
												{#if prescription.patients?.profile_photo_url}
													<img src={prescription.patients.profile_photo_url} alt="Profile" class="h-full w-full object-cover" />
												{:else}
													<User class="h-5 w-5 text-primary-600" />
												{/if}
											</div>
											<div>
												<div class="font-medium text-gray-900">
													{prescription.patients?.full_name || 'Unknown Patient'}
												</div>
												<div class="text-[9px] text-gray-500 mt-1 font-mono uppercase tracking-tighter bg-gray-50 px-2 py-0.5 rounded-full border border-gray-200">
													Prescription Code: {prescription.prescription_code || prescription.id.slice(0, 8)}
												</div>
											</div>
										</div>
									</td>
									
									<!-- Contact Column -->
									<td class="px-6 py-4">
										{#if prescription.patients?.phone}
											<div class="flex items-center gap-1.5 text-gray-600">
												<Phone class="h-3.5 w-3.5" />
												<span>{prescription.patients.phone}</span>
											</div>
										{:else}
											<span class="text-gray-400 italic">No phone</span>
										{/if}
									</td>

									<!-- Drugs Count Column -->
									<td class="px-6 py-4 text-center">
										<span class="inline-flex items-center justify-center px-2.5 py-1 bg-indigo-50 text-indigo-700 font-bold text-xs rounded-full">
											{prescription.prescribed_drugs?.length || 0}
										</span>
									</td>

									<!-- Date Column -->
									<td class="px-6 py-4">
										<div class="text-gray-800">{formatDate(prescription.created_at)}</div>
									</td>

									<!-- Actions Column -->
									<td class="px-6 py-4 text-right">
										<div class="flex items-center justify-end gap-2">
											<a href="/prescriptions/edit/{prescription.id}" class="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="Edit">
												<Edit class="h-4 w-4" />
											</a>
											<button onclick={() => confirmDelete(prescription.id)} class="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="Delete">
												<Trash2 class="h-4 w-4" />
											</button>
										</div>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</div>
		{/if}
	</div>
</div>

<!-- Delete Confirmation Modal -->
{#if deleteConfirmOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-sm animate-in fade-in duration-200">
		<div class="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden animate-in zoom-in-95 duration-200">
			<div class="p-6 text-center">
				<div class="w-14 h-14 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-4">
					<AlertCircle class="h-7 w-7 text-red-600" />
				</div>
				<h3 class="text-lg font-bold text-gray-900 mb-2">Delete Prescription?</h3>
				<p class="text-sm text-gray-500 mb-6">Are you sure you want to permanently delete this prescription? All associated drugs will also be removed. This action cannot be undone.</p>
				
				<div class="flex gap-3">
					<button 
						onclick={() => deleteConfirmOpen = false} 
						disabled={deleting}
						class="flex-1 px-4 py-2.5 bg-white border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors disabled:opacity-50"
					>
						Cancel
					</button>
					<button 
						onclick={handleDelete}
						disabled={deleting}
						class="flex-1 px-4 py-2.5 bg-red-600 text-white font-medium rounded-xl hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
					>
						{#if deleting}
							<div class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div> Saving...
						{:else}
							Yes, Delete
						{/if}
					</button>
				</div>
			</div>
		</div>
	</div>
{/if}
