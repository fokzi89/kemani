<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { FlaskConical, Plus, Trash2, Edit, AlertCircle, Phone, User, Search, FileText } from 'lucide-svelte';

	let provider = $state<any>(null);
	let labRequests = $state<any[]>([]);
	let loading = $state(true);

	// Deletion state
	let deleteConfirmOpen = $state(false);
	let requestToDelete = $state<string | null>(null);
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
				await loadLabRequests(provider.id);
			}
		}

		loading = false;
	});

	async function loadLabRequests(providerId: string) {
		const { data, error } = await supabase
			.from('lab_requests')
			.select(`
				*,
				patients (full_name, profile_photo_url, phone),
				lab_request_items (id, diagnostic_tests (name))
			`)
			.eq('healthcare_provider_id', providerId)
			.order('created_at', { ascending: false });
		
		if (!error && data) {
			labRequests = data;
		} else if (error) {
			console.error('Error loading lab requests:', error);
		}
	}

	function confirmDelete(id: string) {
		requestToDelete = id;
		deleteConfirmOpen = true;
	}

	async function handleDelete() {
		if (!requestToDelete) return;
		deleting = true;
		
		try {
			const { error } = await supabase
				.from('lab_requests')
				.delete()
				.eq('id', requestToDelete);

			if (error) throw error;
			
			labRequests = labRequests.filter(r => r.id !== requestToDelete);
		} catch (err: any) {
			alert('Failed to delete: ' + err.message);
		} finally {
			deleting = false;
			deleteConfirmOpen = false;
			requestToDelete = null;
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

	function getStatusColor(status: string) {
		switch (status) {
			case 'completed': return 'bg-green-100 text-green-700';
			case 'pending': return 'bg-yellow-100 text-yellow-700';
			case 'cancelled': return 'bg-red-100 text-red-700';
			case 'in_progress': return 'bg-blue-100 text-blue-700';
			default: return 'bg-gray-100 text-gray-700';
		}
	}
</script>

<svelte:head>
	<title>Lab Requests History - Kemani</title>
</svelte:head>

<div class="min-h-screen p-4 sm:p-6 lg:p-8 bg-gray-50">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white rounded-xl shadow-sm p-5 border border-gray-100">
			<div>
				<h2 class="text-2xl font-bold text-gray-900 tracking-tight">Lab Request History</h2>
				<p class="text-sm text-gray-500 mt-1">Manage all your diagnostic test requests here</p>
			</div>
			
			<a
				href="/lab-requests/add"
				class="w-full sm:w-auto px-5 py-2.5 bg-gray-900 hover:bg-black text-white font-medium rounded-lg transition-colors flex justify-center items-center gap-2 shadow-sm"
			>
				<Plus class="h-5 w-5" />
				Request Test
			</a>
		</div>

		<!-- Lab Requests List -->
		{#if loading}
			<div class="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center">
				<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600 mx-auto"></div>
				<p class="mt-4 text-gray-500 text-sm">Loading history...</p>
			</div>
		{:else if labRequests.length === 0}
			<div class="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center flex flex-col items-center">
				<div class="bg-purple-50 p-4 rounded-full mb-4">
					<FlaskConical class="h-10 w-10 text-purple-600" />
				</div>
				<h3 class="text-lg font-semibold text-gray-900">No lab requests yet</h3>
				<p class="text-sm text-gray-500 max-w-sm mt-1 mb-6">You haven't requested any diagnostic tests yet. Click the button above to create one.</p>
				<a href="/lab-requests/add" class="text-purple-600 font-medium hover:underline text-sm flex items-center gap-1">
					<Plus class="h-4 w-4" /> Create First Lab Request
				</a>
			</div>
		{:else}
			<div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
				<div class="overflow-x-auto">
					<table class="w-full text-left text-sm whitespace-nowrap">
						<thead class="bg-gray-50 border-b border-gray-100 text-gray-600 text-xs uppercase tracking-wider">
							<tr>
								<th class="px-6 py-4 font-semibold">Patient Name</th>
								<th class="px-6 py-4 font-semibold">Test(s)</th>
								<th class="px-6 py-4 font-semibold text-center">Status</th>
								<th class="px-6 py-4 font-semibold">Date Requested</th>
								<th class="px-6 py-4 font-semibold text-right">Actions</th>
							</tr>
						</thead>
						<tbody class="divide-y divide-gray-50 text-gray-700">
							{#each labRequests as request}
								<tr class="hover:bg-gray-50 transition-colors">
									<!-- Patient Column -->
									<td class="px-6 py-4">
										<div class="flex items-center gap-3">
											<div class="h-10 w-10 shrink-0 bg-primary-100 rounded-full flex items-center justify-center overflow-hidden border border-primary-200">
												{#if request.patients?.profile_photo_url}
													<img src={request.patients.profile_photo_url} alt="Profile" class="h-full w-full object-cover" />
												{:else}
													<User class="h-5 w-5 text-primary-600" />
												{/if}
											</div>
											<div>
												<div class="font-medium text-gray-900">
													{request.patients?.full_name || 'Unknown Patient'}
												</div>
												<div class="text-[9px] text-gray-500 mt-1 flex items-center gap-1.5 font-mono uppercase tracking-tighter bg-gray-50 px-2 py-0.5 rounded-full border border-gray-200">
													ID: {request.id.slice(0, 8)}
												</div>
											</div>
										</div>
									</td>
									
									<!-- Tests Column -->
									<td class="px-6 py-4">
										<div class="flex flex-wrap gap-1 max-w-xs">
											{#each request.lab_request_items?.slice(0, 2) || [] as item}
												<span class="px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-[10px] font-medium border border-gray-200">
													{item.diagnostic_tests?.name || 'Unknown Test'}
												</span>
											{/each}
											{#if (request.lab_request_items?.length || 0) > 2}
												<span class="px-2 py-0.5 bg-gray-50 text-gray-400 rounded text-[10px] italic">
													+{(request.lab_request_items?.length || 0) - 2} more
												</span>
											{/if}
										</div>
									</td>

									<!-- Status Column -->
									<td class="px-6 py-4 text-center">
										<span class="inline-flex items-center justify-center px-2.5 py-1 font-bold text-[10px] uppercase tracking-wide rounded-full {getStatusColor(request.status)}">
											{request.status.replace('_', ' ')}
										</span>
									</td>

									<!-- Date Column -->
									<td class="px-6 py-4">
										<div class="text-gray-800">{formatDate(request.created_at)}</div>
									</td>

									<!-- Actions Column -->
									<td class="px-6 py-4 text-right">
										<div class="flex items-center justify-end gap-2">
											<a href="/lab-requests/edit/{request.id}" class="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="Edit">
												<Edit class="h-4 w-4" />
											</a>
											<button onclick={() => confirmDelete(request.id)} class="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="Delete">
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
				<h3 class="text-lg font-bold text-gray-900 mb-2">Delete Lab Request?</h3>
				<p class="text-sm text-gray-500 mb-6">Are you sure you want to permanently delete this lab request? This action cannot be undone.</p>
				
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
							<div class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
						{:else}
							Yes, Delete
						{/if}
					</button>
				</div>
			</div>
		</div>
	</div>
{/if}
