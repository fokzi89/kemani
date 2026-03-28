<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		UserPlus, MoreVertical, Edit2, ShieldOff, Shield, 
		X, Building2, Mail, Phone, User, Search, Copy, CheckCircle2, Link
	} from 'lucide-svelte';

	let staff = $state<any[]>([]);
	let branches = $state<any[]>([]);
	let tenantId = $state<string | null>(null);
	let loading = $state(true);
	let searchQuery = $state('');
	let activeDropdown = $state<string | null>(null);

	// Invite modal
	let showInviteModal = $state(false);
	let inviting = $state(false);
	let inviteSuccess = $state(false);
	let generatedInviteLink = $state('');
	let linkCopied = $state(false);
	let inviteForm = $state<any>({
		email: '',
		full_name: '',
		role: 'cashier' as string,
		branch_id: '',
		canManagePOS: false,
		canManageProducts: false,
		canManageCustomers: false,
		canManageOrders: false,
		canViewMessages: false,
		canViewAnalytics: false,
		canManageStaff: false,
		canManageInventory: false,
		canManageTransfer: false,
		canManageBranches: false,
		canManageRoles: false,
		canManageScrap: false,
		canTransferProduct: false,
		canReturnProducts: false
	});

	// Edit privileges modal
	let showPrivilegesModal = $state(false);
	let editingStaff = $state<any>(null);
	let savingPrivileges = $state(false);
	let privilegeForm = $state<any>({});

	const roles = ['manager', 'cashier', 'pharmacist', 'tenant_admin'];

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

			// Fetch all staff under this tenant
			const { data: staffData, error: staffErr } = await supabase
				.from('users')
				.select(`*, branches!branch_id(name)`)
				.eq('tenant_id', tenantId)
				.is('deleted_at', null)
				.order('created_at', { ascending: false });

			if (staffErr) console.error('Staff error:', staffErr);
			staff = staffData || [];

			// Fetch branches for assignment
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

	function openInviteModal() {
		inviteForm = {
			email: '', full_name: '', role: 'cashier', branch_id: '',
			canManagePOS: false, canManageProducts: false, canManageCustomers: false, canManageOrders: false,
			canViewMessages: false, canViewAnalytics: false, canManageStaff: false, canManageInventory: false,
			canManageTransfer: false, canManageBranches: false, canManageRoles: false, canManageScrap: false,
			canTransferProduct: false, canReturnProducts: false
		};
		inviteSuccess = false;
		generatedInviteLink = '';
		linkCopied = false;
		showInviteModal = true;
	}

	async function sendInvite(e: Event) {
		e.preventDefault();
		if (!tenantId) return;
		inviting = true;
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) throw new Error('Not authenticated');

			// Generate a unique token
			const token = crypto.randomUUID();

			// Insert into staff_invitations table
			const { error: insertError } = await supabase
				.from('staff_invitations')
				.insert({
					tenant_id: tenantId,
					invited_by: session.user.id,
					email: inviteForm.email.trim().toLowerCase(),
					full_name: inviteForm.full_name.trim(),
					role: inviteForm.role,
					branch_id: inviteForm.branch_id || null,
					invitation_token: token,
					status: 'pending',
					canManagePOS: inviteForm.canManagePOS,
					canManageProducts: inviteForm.canManageProducts,
					canManageCustomers: inviteForm.canManageCustomers,
					canManageOrders: inviteForm.canManageOrders,
					canViewMessages: inviteForm.canViewMessages,
					canViewAnalytics: inviteForm.canViewAnalytics,
					canManageStaff: inviteForm.canManageStaff,
					canManageInventory: inviteForm.canManageInventory,
					canManageTransfer: inviteForm.canManageTransfer,
					canManageBranches: inviteForm.canManageBranches,
					canManageRoles: inviteForm.canManageRoles,
					canManageScrap: inviteForm.canManageScrap,
					canTransferProduct: inviteForm.canTransferProduct,
					canReturnProducts: inviteForm.canReturnProducts
				});

			if (insertError) throw insertError;

			// Build copyable invite link
			generatedInviteLink = `${window.location.origin}/auth/accept-invite?token=${token}`;
			inviteSuccess = true;
		} catch (err: any) {
			alert('Failed to create invitation: ' + err.message);
		} finally {
			inviting = false;
		}
	}

	async function copyInviteLink() {
		try {
			await navigator.clipboard.writeText(generatedInviteLink);
			linkCopied = true;
			setTimeout(() => linkCopied = false, 2500);
		} catch {
			// Fallback for older browsers
			const el = document.createElement('textarea');
			el.value = generatedInviteLink;
			document.body.appendChild(el);
			el.select();
			document.execCommand('copy');
			document.body.removeChild(el);
			linkCopied = true;
			setTimeout(() => linkCopied = false, 2500);
		}
	}

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
		<button
			onclick={openInviteModal}
			class="inline-flex items-center gap-2 bg-blue-600 text-white px-5 py-2.5 rounded-lg text-sm font-bold hover:bg-blue-700 transition-colors shadow-sm shadow-blue-200 focus:ring-4 focus:ring-blue-600/20"
		>
			<UserPlus class="h-4 w-4" />
			Invite Staff
		</button>
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
			<button
				onclick={openInviteModal}
				class="mt-6 inline-flex items-center gap-2 bg-blue-600 text-white px-6 py-2.5 rounded-lg text-sm font-bold hover:bg-blue-700 transition-colors"
			>
				<UserPlus class="h-4 w-4" />
				Invite First Member
			</button>
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

<!-- ===== INVITE MODAL ===== -->
{#if showInviteModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
		<button class="absolute inset-0 bg-slate-900/30 backdrop-blur-sm cursor-default" onclick={() => !inviting && (showInviteModal = false)} aria-label="Close"></button>

		<div class="relative bg-white rounded-2xl shadow-2xl w-full overflow-hidden border border-gray-100/50 flex flex-col max-h-[90vh]" style="max-width: 500px;">
			<!-- Header -->
			<div class="p-6 border-b border-gray-100 flex justify-between items-start shrink-0">
				<div>
					<div class="h-12 w-12 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-4">
						<UserPlus class="h-6 w-6" />
					</div>
					<h2 class="text-xl font-extrabold text-gray-900">Invite Staff Member</h2>
					<p class="text-sm text-gray-500 mt-1">They'll receive a magic link to sign in.</p>
				</div>
				<button onclick={() => showInviteModal = false} disabled={inviting} class="p-2 text-gray-400 hover:text-gray-700 hover:bg-gray-50 rounded-xl transition-colors" aria-label="Close">
					<X class="h-5 w-5" />
				</button>
			</div>

			<!-- Success state OR form -->
			{#if inviteSuccess}
				<!-- Success Screen -->
				<div class="p-8 flex flex-col items-center text-center overflow-y-auto max-h-[85vh]">
					<div class="h-16 w-16 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center mb-5 shrink-0">
						<CheckCircle2 class="h-8 w-8" />
					</div>
					<h3 class="text-xl font-black text-gray-900 mb-1">Invite Sent!</h3>
					<p class="text-sm text-gray-500 mb-6 shrink-0">
						A magic sign-in link was emailed to <span class="font-bold text-gray-800">{inviteForm.email}</span>.
						Share the link below if they didn't receive the email.
					</p>

					<!-- Invite link box -->
					<div class="w-full bg-gray-50 border border-gray-200 rounded-2xl p-4 mb-4 shrink-0">
						<div class="flex items-center gap-2 mb-3">
							<Link class="h-3.5 w-3.5 text-gray-400 shrink-0" />
							<span class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Invite Link</span>
						</div>
						<div class="bg-white border border-gray-100 rounded-xl px-3 py-2.5 mb-3 overflow-x-auto">
							<p class="text-[11px] text-gray-600 font-mono break-all text-left whitespace-pre-wrap">{generatedInviteLink}</p>
						</div>
						<button
							type="button"
							onclick={copyInviteLink}
							class="w-full py-2.5 rounded-xl text-sm font-bold flex items-center justify-center gap-2 transition-all
								{linkCopied 
									? 'bg-emerald-50 text-emerald-700 border border-emerald-200' 
									: 'bg-blue-600 text-white hover:bg-blue-700 shadow-sm shadow-blue-200'}"
						>
							{#if linkCopied}
								<CheckCircle2 class="h-4 w-4" />
								Copied to Clipboard!
							{:else}
								<Copy class="h-4 w-4" />
								Copy Invite Link
							{/if}
						</button>
					</div>

					<button
						type="button"
						onclick={() => { showInviteModal = false; inviteSuccess = false; }}
						class="w-full py-2.5 rounded-xl text-sm font-bold text-gray-600 border border-gray-200 hover:bg-gray-50 transition-colors"
					>
						Close
					</button>
				</div>
			{:else}
				<form onsubmit={sendInvite} class="flex flex-col min-h-0">
					<div class="p-6 space-y-4 overflow-y-auto">
						<!-- Basic Info -->
						<div>
							<label for="inv-name" class="block text-xs font-bold text-gray-700 mb-1.5">Full Name <span class="text-red-500">*</span></label>
							<input id="inv-name" type="text" required bind:value={inviteForm.full_name}
								placeholder="John Doe"
								class="w-full px-3.5 py-3 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all" />
						</div>

						<div>
							<label for="inv-email" class="block text-xs font-bold text-gray-700 mb-1.5">Work Email <span class="text-red-500">*</span></label>
							<input id="inv-email" type="email" required bind:value={inviteForm.email}
								placeholder="staff@example.com"
								class="w-full px-3.5 py-3 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all" />
							<p class="text-[11px] text-gray-400 mt-1.5">Staff must sign in with this exact Google account.</p>
						</div>

						<div class="grid grid-cols-2 gap-4">
							<div>
								<label for="inv-role" class="block text-xs font-bold text-gray-700 mb-1.5">Role</label>
								<select id="inv-role" bind:value={inviteForm.role}
									class="w-full px-3.5 py-3 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all appearance-none">
									{#each roles as r}
										<option value={r}>{r.replace('_', ' ')}</option>
									{/each}
								</select>
							</div>
							<div>
								<label for="inv-branch" class="block text-xs font-bold text-gray-700 mb-1.5">Branch</label>
								<select id="inv-branch" bind:value={inviteForm.branch_id}
									class="w-full px-3.5 py-3 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all appearance-none">
									<option value="">Unassigned</option>
									{#each branches as b}
										<option value={b.id}>{b.name}</option>
									{/each}
								</select>
							</div>
						</div>

						<div class="mt-4 border-t border-gray-100 pt-4">
							<div class="flex items-center gap-2 mb-3">
								<Shield class="h-4 w-4 text-blue-500" />
								<label class="block text-xs font-bold text-gray-700">Initial Access Privileges</label>
							</div>
							<div class="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-48 overflow-y-auto pr-1">
								{#each privileges as priv}
									<label class="flex items-center justify-between p-2.5 rounded-xl border border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors group">
										<div class="overflow-hidden">
											<p class="text-xs font-bold text-gray-800 truncate">{priv.label}</p>
											<p class="text-[9px] text-gray-400 truncate">{priv.description}</p>
										</div>
										<div class="relative shrink-0 ml-2">
											<input type="checkbox" bind:checked={inviteForm[priv.key]} class="sr-only peer" />
											<div class="w-8 h-4.5 bg-gray-200 peer-checked:bg-blue-600 rounded-full transition-colors"></div>
											<div class="absolute top-[2px] left-[2px] h-3.5 w-3.5 bg-white rounded-full shadow transition-all peer-checked:translate-x-3.5"></div>
										</div>
									</label>
								{/each}
							</div>
						</div>
					</div>

					<div class="px-6 py-4 border-t border-gray-100 bg-gray-50/50 flex justify-end gap-3 shrink-0">
						<button type="button" onclick={() => showInviteModal = false} disabled={inviting}
							class="px-5 py-2.5 text-sm font-bold text-gray-600 bg-white border border-gray-200 hover:bg-gray-50 rounded-xl transition-colors disabled:opacity-50">
							Cancel
						</button>
						<button type="submit" disabled={inviting || !inviteForm.email.trim() || !inviteForm.full_name.trim()}
							class="px-6 py-2.5 text-sm font-bold text-white bg-blue-600 rounded-xl hover:bg-blue-700 shadow-sm shadow-blue-200 transition-all disabled:opacity-50 flex items-center gap-2">
							{#if inviting}
								<div class="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin"></div>
								Sending...
							{:else}
								<UserPlus class="h-4 w-4" />
								Send Invite
							{/if}
						</button>
					</div>
				</form>
			{/if}
		</div>
	</div>
{/if}

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
