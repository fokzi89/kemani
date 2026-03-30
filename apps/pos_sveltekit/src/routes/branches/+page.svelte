<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Plus, MoreVertical, Edit2, Trash2, Eye, Building2, MapPin } from 'lucide-svelte';

	let branches = $state<any[]>([]);
	let loading = $state(true);
	let tenantId = $state<string | null>(null);
	let activeDropdown = $state<string | null>(null);

	function toggleDropdown(id: string) {
		activeDropdown = activeDropdown === id ? null : id;
	}

	async function fetchBranches() {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) return;
			const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
			if (!user) return;
			tenantId = user.tenant_id;

			const { data, error } = await supabase
				.from('branches')
				.select(`*, users!branch_id (count)`)
				.eq('tenant_id', tenantId)
				.is('deleted_at', null)
				.order('created_at', { ascending: false });

			if (error) throw error;
			branches = (data || []).map(b => ({
				...b,
				staff_count: Array.isArray(b.users) ? b.users[0]?.count || 0 : (b.users?.count || 0)
			}));
		} catch (e) {
			console.error('Error fetching branches', e);
		} finally {
			loading = false;
		}
	}

	onMount(fetchBranches);

	const businessTypes = [
		{ id: 'pharmacy_supermarket', label: 'Pharmacy & Supermarket' },
		{ id: 'diagnostic_centre', label: 'Diagnostic Centre' },
		{ id: 'supermarket', label: 'Supermarket' },
		{ id: 'pharmacy', label: 'Pharmacy' },
		{ id: 'clinic', label: 'Clinic/Hospital' },
		{ id: 'other', label: 'Other/Retail' }
	];

	function getBusinessTypeLabel(id: string) {
		return businessTypes.find(t => t.id === id)?.label || 'Other';
	}

	async function deleteBranch(id: string) {
		if (!confirm('Are you sure you want to completely delete this branch?')) return;
		try {
			const { error } = await supabase.from('branches').update({ deleted_at: new Date().toISOString() }).eq('id', id);
			if (error) throw error;
			branches = branches.filter(b => b.id !== id);
		} catch (e) {
			console.error('Error deleting branch', e);
			alert('Failed to delete branch');
		}
	}
</script>

<div class="p-6 md:p-8 max-w-7xl mx-auto w-full">
	<div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Branch Management</h1>
			<p class="text-sm text-gray-500 mt-1">Manage all your store locations and retail branches.</p>
		</div>
		<a
			href="/branches/new"
			class="inline-flex items-center gap-2 bg-blue-600 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors shadow-sm focus:ring-4 focus:ring-blue-600/20"
		>
			<Plus class="h-4 w-4" />
			Add Branch
		</a>
	</div>

	{#if loading}
		<div class="flex justify-center items-center py-20">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
		</div>
	{:else if branches.length === 0}
		<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center flex items-center justify-center flex-col">
			<div class="h-14 w-14 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mb-5">
				<Building2 class="h-7 w-7" />
			</div>
			<h3 class="text-lg font-bold text-gray-900 mb-2">No Branches Found</h3>
			<p class="text-gray-500 text-sm max-w-sm">Get started by creating your first branch. Stores, clinics, and offices can all be managed seamlessly here.</p>
			<a
				href="/branches/new"
				class="mt-6 inline-flex items-center gap-2 bg-white text-blue-700 border border-blue-200 px-8 py-2.5 rounded-lg text-sm font-bold hover:bg-blue-50 transition-colors"
			>
				<Plus class="h-4 w-4" />
				Create First Branch
			</a>
		</div>
	{:else}
		<div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-visible">
			<div class="overflow-x-auto overflow-y-visible">
				<table class="w-full text-left border-collapse min-w-[700px]">
					<thead>
						<tr class="bg-gray-50/80 border-b border-gray-100">
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Branch Details</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Business Type</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Address & Contact</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-center">Staffs</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each branches as branch}
							<tr class="hover:bg-blue-50/30 transition-colors group">
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="flex items-center gap-3">
										<div class="h-10 w-10 rounded-lg bg-gray-100 flex items-center justify-center text-gray-500 group-hover:bg-blue-100 group-hover:text-blue-600 transition-colors">
											<Building2 class="h-5 w-5" />
										</div>
										<div>
											<p class="text-sm font-bold text-gray-900">{branch.name}</p>
											{#if branch.created_at}
												<p class="text-xs text-gray-400 mt-0.5">Added {new Date(branch.created_at).toLocaleDateString()}</p>
											{/if}
										</div>
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<span class="inline-flex px-2.5 py-1 bg-blue-50 text-blue-700/80 border border-blue-100/50 rounded-md text-xs font-semibold">
										{getBusinessTypeLabel(branch.business_type)}
									</span>
								</td>
								<td class="px-6 py-4">
									<div class="flex flex-col gap-1 w-full max-w-[250px]">
										<div class="flex items-start gap-1.5 text-sm text-gray-600">
											<MapPin class="h-4 w-4 mt-0.5 shrink-0 text-gray-400" />
											<span class="truncate" title={branch.address}>{branch.address || 'No address provided'}</span>
										</div>
										{#if branch.phone}
											<p class="text-xs text-gray-400 font-medium ml-5.5 pl-[22px]">{branch.phone}</p>
										{/if}
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-center">
									<span class="inline-flex items-center justify-center h-7 min-w-[28px] px-2 bg-gray-100 text-gray-700 rounded-full text-xs font-bold border border-gray-200">
										{branch.staff_count}
									</span>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-right relative">
									<div class="relative inline-block text-left">
										<button
											onclick={() => toggleDropdown(branch.id)}
											class="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors focus:ring-2 focus:ring-gray-200"
											aria-label="Branch actions"
										>
											<MoreVertical class="h-5 w-5" />
										</button>

										{#if activeDropdown === branch.id}
											<button
												class="fixed inset-0 h-full w-full cursor-default z-10 bg-transparent"
												onclick={() => activeDropdown = null}
												aria-label="Close menu"
											></button>

											<div class="absolute right-0 mt-1 w-48 bg-white rounded-xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.1)] border border-gray-100 overflow-hidden z-20">
												<div class="py-1">
													<a
														href="/branches/{branch.id}"
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 flex items-center gap-3"
													>
														<Eye class="h-4 w-4 text-gray-400" />
														View Details
													</a>
													<a
														href="/branches/{branch.id}/edit"
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 flex items-center gap-3"
													>
														<Edit2 class="h-4 w-4 text-blue-500" />
														Edit Branch
													</a>
													<div class="h-px bg-gray-100 my-1 w-full scale-x-90"></div>
													<button
														onclick={() => { activeDropdown = null; deleteBranch(branch.id); }}
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-red-600 hover:bg-red-50 flex items-center gap-3"
													>
														<Trash2 class="h-4 w-4 text-red-500" />
														Delete Branch
													</button>
												</div>
											</div>
										{/if}
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
