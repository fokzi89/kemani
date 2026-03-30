<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import {
		UserPlus, MoreVertical, Edit2, ShieldOff, Shield,
		X, Building2, Mail, Phone, User, Search
	} from 'lucide-svelte';

	let staff = $state<any[]>([]);
	let branches = $state<any[]>([]);
	let tenantId = $state<string | null>(null);
	let loading = $state(true);
	let searchQuery = $state('');
	let activeDropdown = $state<string | null>(null);

	// Edit privileges modal
	let showPrivilegesModal = $state(false);
	let editingStaff = $state<any>(null);
	let savingPrivileges = $state(false);
	let privilegeForm = $state<any>({});

	const privileges = [
		{ key: 'canManagePOS', label: 'POS Access', description: 'Can process sales' },
		{ key: 'canManageProducts', label: 'Products', description: 'Can manage products' },
		{ key: 'canManageCustomers', label: 'Customers', description: 'Can manage customers' },
		{ key: 'canManageOrders', label: 'Orders', description: 'Can view/process orders' },
		{ key: 'canViewMessages', label: 'Messages', description: 'Can access messages' },
		{ key: 'canViewAnalytics', label: 'Analytics', description: 'Can view analytics' },
		{ key: 'canManageStaff', label: 'Staff Management', description: 'Can manage staff' },
		{ key: 'canManageInventory', label: 'Inventory', description: 'Can manage inventory' },
		{ key: 'canManageTransfer', label: 'Transfer Inventory', description: 'Can manage transfer' },
		{ key: 'canManageBranches', label: 'Branches', description: 'Can manage branches' },
		{ key: 'canManageRoles', label: 'Roles', description: 'Can manage roles' },
		{ key: 'canManageScrap', label: 'Scrap', description: 'Can manage scrap' },
		{ key: 'canTransferProduct', label: 'Transfer Products', description: 'Can transfer products' },
		{ key: 'canReturnProducts', label: 'Returns', description: 'Can process returns' }
	];

	let filteredStaff = $derived(
		staff.filter(s =>
			!searchQuery ||
			s.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
			s.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
			s.role?.toLowerCase().includes(searchQuery.toLowerCase())
		)
	);

	async function fetchData() {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) return;

			const { data: me } = await supabase
				.from('users')
				.select('tenant_id')
				.eq('id', session.user.id)
				.single();

			if (!me) return;
			tenantId = me.tenant_id;

			const { data: staffData, error: staffErr } = await supabase
				.from('users')
				.select(`*, branches!branch_id(name)`)
				.eq('tenant_id', tenantId)
				.is('deleted_at', null)
				.order('created_at', { ascending: false });

			if (staffErr) console.error('Staff error:', staffErr);
			staff = staffData || [];

			const { data: branchData } = await supabase
				.from('branches')
				.select('id, name')
				.eq('tenant_id', tenantId)
				.is('deleted_at', null);

			branches = branchData || [];
		} catch (e) {
			console.error('Failed to load staff data', e);
		} finally {
			loading = false;
		}
	}

	onMount(fetchData);

	function openPrivilegesModal(person: any) {
		editingStaff = person;
		privilegeForm = {
			canManagePOS: person.canManagePOS ?? false,
			canManageProducts: person.canManageProducts ?? false,
			canManageCustomers: person.canManageCustomers ?? false,
			canManageOrders: person.canManageOrders ?? false,
			canViewMessages: person.canViewMessages ?? false,
			canViewAnalytics: person.canViewAnalytics ?? false,
			canManageStaff: person.canManageStaff ?? false,
			canManageInventory: person.canManageInventory ?? false,
			canManageTransfer: person.canManageTransfer ?? false,
			canManageBranches: person.canManageBranches ?? false,
			canManageRoles: person.canManageRoles ?? false,
			canManageScrap: person.canManageScrap ?? false,
			canTransferProduct: person.canTransferProduct ?? false,
			canReturnProducts: person.canReturnProducts ?? false
		};
		showPrivilegesModal = true;
		activeDropdown = null;
	}

	async function savePrivileges(e: Event) {
		e.preventDefault();
		if (!editingStaff) return;
		savingPrivileges = true;
		try {
			const { error } = await supabase
				.from('users')
				.update({ ...privilegeForm, updated_at: new Date().toISOString() })
				.eq('id', editingStaff.id);
			if (error) throw error;
			showPrivilegesModal = false;
			await fetchData();
		} catch (err: any) {
			alert('Failed to update privileges: ' + err.message);
		} finally {
			savingPrivileges = false;
		}
	}

	async function revokeAccess(person: any) {
		if (!confirm(`Remove all access for ${person.full_name}? They will no longer be able to log in.`)) return;
		try {
			const { error } = await supabase
				.from('users')
				.update({
					canManagePOS: false, canManageProducts: false,
					canManageCustomers: false, canManageOrders: false,
					canViewMessages: false, canViewAnalytics: false,
					canManageStaff: false, canManageInventory: false,
					canManageTransfer: false, canManageBranches: false,
					canManageRoles: false, canManageScrap: false,
					canTransferProduct: false, canReturnProducts: false,
					deleted_at: new Date().toISOString()
				})
				.eq('id', person.id);
			if (error) throw error;
			staff = staff.filter(s => s.id !== person.id);
			activeDropdown = null;
		} catch (err: any) {
			alert('Failed to revoke access: ' + err.message);
		}
	}

	function getRoleBadgeClass(role: string) {
		const map: Record<string, string> = {
			tenant_admin: 'bg-purple-50 text-purple-700 border-purple-100',
			manager: 'bg-blue-50 text-blue-700 border-blue-100',
			cashier: 'bg-green-50 text-green-700 border-green-100',
			pharmacist: 'bg-amber-50 text-amber-700 border-amber-100',
			staff: 'bg-gray-50 text-gray-600 border-gray-200'
		};
		return map[role] || map.staff;
	}
</script>

<div class="p-6 md:p-8 max-w-7xl mx-auto w-full">
	<!-- Header -->
	<div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Staff Management</h1>
			<p class="text-sm text-gray-500 mt-1">Manage team members, roles and their access privileges.</p>
		</div>
		<a
			href="/staffs/new"
			class="inline-flex items-center gap-2 bg-blue-600 text-white px-5 py-2.5 rounded-lg text-sm font-bold hover:bg-blue-700 transition-colors shadow-sm shadow-blue-200 focus:ring-4 focus:ring-blue-600/20"
		>
			<UserPlus class="h-4 w-4" />
			Invite Staff
		</a>
	</div>

	<!-- Search -->
	<div class="relative mb-6 max-w-sm">
		<Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
		<input
			type="text"
			bind:value={searchQuery}
			placeholder="Search by name, email or role..."
			class="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-blue-600 focus:border-blue-600 outline-none transition-all"
		/>
	</div>

	{#if loading}
		<div class="flex justify-center items-center py-20">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
		</div>
	{:else if filteredStaff.length === 0}
		<div class="bg-white rounded-2xl border border-gray-200 shadow-sm p-14 text-center flex flex-col items-center">
			<div class="h-14 w-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-5">
				<User class="h-7 w-7" />
			</div>
			<h3 class="text-lg font-bold text-gray-900 mb-2">No Staff Found</h3>
			<p class="text-gray-500 text-sm max-w-sm">Your team is empty. Invite your first staff member to get started.</p>
			<a
				href="/staffs/new"
				class="mt-6 inline-flex items-center gap-2 bg-blue-600 text-white px-6 py-2.5 rounded-lg text-sm font-bold hover:bg-blue-700 transition-colors"
			>
				<UserPlus class="h-4 w-4" />
				Invite First Member
			</a>
		</div>
	{:else}
		<div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-visible">
			<div class="overflow-x-auto overflow-y-visible">
				<table class="w-full text-left min-w-[900px]">
					<thead>
						<tr class="bg-gray-50/80 border-b border-gray-100">
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Staff Member</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Contact</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Branch</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Role</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-center">Access</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each filteredStaff as person}
						{@const grantedCount = privileges.filter(p => person[p.key]).length}
							<tr class="hover:bg-blue-50/20 transition-colors group">
								<!-- Staff Member -->
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="flex items-center gap-3">
										<div class="h-10 w-10 rounded-full overflow-hidden bg-blue-100 border-2 border-white shadow-sm flex items-center justify-center font-bold text-blue-700 text-sm shrink-0">
											{#if person.profile_picture_url || person.avatar_url}
												<img src={person.profile_picture_url || person.avatar_url} alt="" class="h-full w-full object-cover" />
											{:else}
												{person.full_name?.charAt(0)?.toUpperCase() || 'U'}
											{/if}
										</div>
										<div>
											<p class="text-sm font-bold text-gray-900">{person.full_name}</p>
											<p class="text-[11px] text-gray-400 mt-0.5">
												Joined {new Date(person.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
											</p>
										</div>
									</div>
								</td>

								<!-- Contact -->
								<td class="px-6 py-4">
									<div class="space-y-1">
										<div class="flex items-center gap-1.5 text-xs text-gray-600">
											<Mail class="h-3.5 w-3.5 text-gray-400 shrink-0" />
											<span class="truncate max-w-[160px]">{person.email || '—'}</span>
										</div>
										<div class="flex items-center gap-1.5 text-xs text-gray-500">
											<Phone class="h-3.5 w-3.5 text-gray-400 shrink-0" />
											<span>{person.phone || '—'}</span>
										</div>
									</div>
								</td>

								<!-- Branch -->
								<td class="px-6 py-4 whitespace-nowrap">
									{#if person.branches}
										<div class="flex items-center gap-2">
											<div class="h-7 w-7 bg-gray-100 rounded-lg flex items-center justify-center shrink-0">
												<Building2 class="h-4 w-4 text-gray-500" />
											</div>
											<span class="text-sm font-medium text-gray-700">{person.branches?.name}</span>
										</div>
									{:else}
										<span class="text-xs text-gray-400 italic">Unassigned</span>
									{/if}
								</td>

								<!-- Role -->
								<td class="px-6 py-4 whitespace-nowrap">
									<span class="inline-flex px-2.5 py-1 rounded-md text-xs font-bold border {getRoleBadgeClass(person.role)} capitalize">
										{person.role?.replace('_', ' ')}
									</span>
								</td>

								<!-- Access summary -->
								<td class="px-6 py-4 text-center whitespace-nowrap">
									<div class="inline-flex items-center gap-1.5">
										<div class="flex gap-0.5">
											{#each Array(privileges.length) as _, i}
												<div class="h-1.5 w-1.5 rounded-full {i < grantedCount ? 'bg-blue-500' : 'bg-gray-200'}"></div>
											{/each}
										</div>
										<span class="text-xs font-bold text-gray-600">{grantedCount}/{privileges.length}</span>
									</div>
								</td>

								<!-- Actions -->
								<td class="px-6 py-4 whitespace-nowrap text-right relative">
									<div class="relative inline-block text-left">
										<button
											onclick={() => activeDropdown = activeDropdown === person.id ? null : person.id}
											class="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
											aria-label="Actions"
										>
											<MoreVertical class="h-5 w-5" />
										</button>

										{#if activeDropdown === person.id}
											<button
												class="fixed inset-0 z-10 bg-transparent cursor-default"
												onclick={() => activeDropdown = null}
												aria-label="Close menu"
											></button>

											<div class="absolute right-0 mt-1 w-52 bg-white rounded-2xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.12)] border border-gray-100 overflow-hidden z-20">
												<div class="py-1.5">
													<div class="px-4 py-2 text-[10px] font-black text-gray-400 uppercase tracking-widest">Actions</div>
													<button
														onclick={() => { activeDropdown = null; }}
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 flex items-center gap-3"
													>
														<Edit2 class="h-4 w-4 text-blue-500" />
														Edit Profile
													</button>
													<button
														onclick={() => openPrivilegesModal(person)}
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 flex items-center gap-3"
													>
														<Shield class="h-4 w-4 text-emerald-500" />
														Edit Privileges
													</button>
													<div class="h-px bg-gray-100 my-1 mx-3"></div>
													<button
														onclick={() => revokeAccess(person)}
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-red-600 hover:bg-red-50 flex items-center gap-3"
													>
														<ShieldOff class="h-4 w-4 text-red-500" />
														Revoke Access
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

<!-- ===== PRIVILEGES MODAL ===== -->
{#if showPrivilegesModal && editingStaff}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
		<button class="absolute inset-0 bg-slate-900/30 backdrop-blur-sm cursor-default" onclick={() => !savingPrivileges && (showPrivilegesModal = false)} aria-label="Close"></button>

		<div class="relative bg-white rounded-2xl shadow-2xl w-full overflow-hidden border border-gray-100/50 flex flex-col max-h-[90vh]" style="max-width: 460px;">
			<div class="p-6 border-b border-gray-100 flex justify-between items-center shrink-0">
				<div class="flex items-center gap-3">
					<div class="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center font-bold text-blue-700 text-sm">
						{editingStaff.full_name?.charAt(0)?.toUpperCase()}
					</div>
					<div>
						<h2 class="text-lg font-extrabold text-gray-900">{editingStaff.full_name}</h2>
						<p class="text-xs text-gray-500">Edit Access Privileges</p>
					</div>
				</div>
				<button onclick={() => showPrivilegesModal = false} disabled={savingPrivileges} class="p-2 text-gray-400 hover:text-gray-700 hover:bg-gray-50 rounded-xl transition-colors" aria-label="Close">
					<X class="h-5 w-5" />
				</button>
			</div>

			<form onsubmit={savePrivileges} class="flex flex-col min-h-0">
				<div class="p-6 space-y-2 overflow-y-auto">
					{#each privileges as priv}
						<label class="flex items-center justify-between p-3.5 rounded-xl hover:bg-gray-50 cursor-pointer transition-colors border border-transparent hover:border-gray-100 group">
							<div>
								<p class="text-sm font-bold text-gray-800">{priv.label}</p>
								<p class="text-[11px] text-gray-400">{priv.description}</p>
							</div>
							<div class="relative shrink-0 ml-4">
								<input type="checkbox" bind:checked={privilegeForm[priv.key]} class="sr-only peer" />
								<div class="w-10 h-6 bg-gray-200 peer-checked:bg-blue-600 rounded-full transition-colors"></div>
								<div class="absolute top-1 left-1 h-4 w-4 bg-white rounded-full shadow transition-all peer-checked:translate-x-4"></div>
							</div>
						</label>
					{/each}
				</div>

				<div class="px-6 py-4 border-t border-gray-100 bg-gray-50/50 flex justify-end gap-3 shrink-0">
					<button type="button" onclick={() => showPrivilegesModal = false} disabled={savingPrivileges}
						class="px-5 py-2.5 text-sm font-bold text-gray-600 bg-white border border-gray-200 hover:bg-gray-50 rounded-xl transition-colors disabled:opacity-50">
						Cancel
					</button>
					<button type="submit" disabled={savingPrivileges}
						class="px-6 py-2.5 text-sm font-bold text-white bg-blue-600 rounded-xl hover:bg-blue-700 shadow-sm shadow-blue-200 transition-all disabled:opacity-50 flex items-center gap-2">
						{#if savingPrivileges}
							<div class="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin"></div>
							Saving...
						{:else}
							<Shield class="h-4 w-4" />
							Save Privileges
						{/if}
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
