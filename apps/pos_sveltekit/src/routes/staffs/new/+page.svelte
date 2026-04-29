<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import {
		ArrowLeft, Save, AlertCircle, UserPlus, Shield,
		CheckCircle2, Copy, Link
	} from 'lucide-svelte';

	let tenantId = $state('');
	let branches = $state<any[]>([]);
	let inviting = $state(false);
	let error = $state('');

	// Success state
	let inviteSuccess = $state(false);
	let generatedInviteLink = $state('');
	let linkCopied = $state(false);
	let invitedEmail = $state('');

	let form = $state<any>({
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
		canTransferProduct: false,
		canReturnProducts: false,
		canCreatePrescription: false,
		canApplyDiscount: false,
		canReferDoctor: true
	});

	const roles = [
		{ id: 'branch_manager', label: 'Manager' },
		{ id: 'cashier', label: 'Cashier' },
		{ id: 'pharmacist', label: 'Pharmacist' },
		{ id: 'doctor', label: 'Doctor' }
	];

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
		{ key: 'canTransferProduct', label: 'Transfer Products', description: 'Can transfer products' },
		{ key: 'canReturnProducts', label: 'Returns', description: 'Can process returns' },
		{ key: 'canCreatePrescription', label: 'Prescribe', description: 'Can create prescriptions' },
		{ key: 'canApplyDiscount', label: 'Discounts', description: 'Can apply manual discounts' },
		{ key: 'canReferDoctor', label: 'Doctor Referrals', description: 'Can refer patients to doctors' }
	];

	let allPrivilegesSelected = $derived(privileges.every(p => form[p.key]));

	function toggleAllPrivileges() {
		const targetState = !allPrivilegesSelected;
		privileges.forEach(p => form[p.key] = targetState);
	}

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) tenantId = user.tenant_id;

		const { data: branchData } = await supabase
			.from('branches')
			.select('id, name')
			.eq('tenant_id', user?.tenant_id)
			.is('deleted_at', null);
		branches = branchData || [];
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!tenantId) { error = 'User session error. Please refresh.'; return; }
		inviting = true; error = '';
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) throw new Error('Not authenticated');

			const token = crypto.randomUUID();

			const { error: insertError } = await supabase.from('staff_invitations').insert({
				tenant_id: tenantId,
				invited_by: session.user.id,
				email: form.email.trim().toLowerCase(),
				full_name: form.full_name.trim(),
				role: form.role,
				branch_id: form.branch_id || null,
				invitation_token: token,
				status: 'pending',
				canManagePOS: form.canManagePOS,
				canManageProducts: form.canManageProducts,
				canManageCustomers: form.canManageCustomers,
				canManageOrders: form.canManageOrders,
				canViewMessages: form.canViewMessages,
				canViewAnalytics: form.canViewAnalytics,
				canManageStaff: form.canManageStaff,
				canManageInventory: form.canManageInventory,
				canManageTransfer: form.canManageTransfer,
				canManageBranches: form.canManageBranches,
				canManageRoles: form.canManageRoles,
				canTransferProduct: form.canTransferProduct,
				canReturnProducts: form.canReturnProducts,
				canCreatePrescription: form.canCreatePrescription,
				canApplyDiscount: form.canApplyDiscount,
				canReferDoctor: form.canReferDoctor
			});

			if (insertError) throw insertError;

			invitedEmail = form.email.trim().toLowerCase();
			generatedInviteLink = `${window.location.origin}/auth/accept-invite?token=${token}`;
			inviteSuccess = true;
		} catch (err: any) {
			error = 'Failed to create invitation: ' + err.message;
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
</script>

<svelte:head><title>Invite Staff – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/staffs" class="p-2 hover:bg-gray-100 rounded-lg transition-colors">
			<ArrowLeft class="h-5 w-5 text-gray-600" />
		</a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Invite Staff Member</h1>
			<p class="text-sm text-gray-500">They'll receive a magic link to sign in</p>
		</div>
	</div>

	{#if inviteSuccess}
		<!-- Success State -->
		<div class="bg-white rounded-xl border p-8 text-center space-y-5">
			<div class="h-16 w-16 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center mx-auto">
				<CheckCircle2 class="h-8 w-8" />
			</div>
			<div>
				<h2 class="text-xl font-bold text-gray-900">Invite Sent!</h2>
				<p class="text-sm text-gray-500 mt-1">
					A magic sign-in link was generated for <span class="font-bold text-gray-800">{invitedEmail}</span>.
					Share the link below if they didn't receive the email.
				</p>
			</div>

			<div class="bg-gray-50 border border-gray-200 rounded-xl p-4 text-left space-y-3">
				<div class="flex items-center gap-2">
					<Link class="h-3.5 w-3.5 text-gray-400 shrink-0" />
					<span class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Invite Link</span>
				</div>
				<div class="bg-white border border-gray-100 rounded-lg px-3 py-2.5 overflow-x-auto">
					<p class="text-xs text-gray-600 font-mono break-all">{generatedInviteLink}</p>
				</div>
				<button
					type="button"
					onclick={copyInviteLink}
					class="w-full flex items-center justify-center gap-2 py-2.5 rounded-lg text-sm font-semibold transition-all
						{linkCopied
							? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
							: 'bg-indigo-600 text-white hover:bg-indigo-700'}"
				>
					{#if linkCopied}
						<CheckCircle2 class="h-4 w-4" /> Copied to Clipboard!
					{:else}
						<Copy class="h-4 w-4" /> Copy Invite Link
					{/if}
				</button>
			</div>

			<a href="/staffs" class="block w-full text-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
				Back to Staff List
			</a>
		</div>

	{:else}
		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
				<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
			</div>
		{/if}

		<form onsubmit={handleSubmit} class="space-y-5">
			<!-- Basic Info -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Staff Details</h2>
				<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
					<div class="sm:col-span-2">
						<label for="inv_name" class="block text-sm font-medium text-gray-700 mb-1">Full Name <span class="text-red-500">*</span></label>
						<input id="inv_name" type="text" required bind:value={form.full_name}
							placeholder="John Doe"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="sm:col-span-2">
						<label for="inv_email" class="block text-sm font-medium text-gray-700 mb-1">Work Email <span class="text-red-500">*</span></label>
						<input id="inv_email" type="email" required bind:value={form.email}
							placeholder="staff@example.com"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						<p class="text-xs text-gray-400 mt-1">Staff must sign in with this exact account.</p>
					</div>
					<div>
						<label for="inv_role" class="block text-sm font-medium text-gray-700 mb-1">Role</label>
						<select id="inv_role" bind:value={form.role}
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm bg-white">
							{#each roles as r}
								<option value={r.id}>{r.label}</option>
							{/each}
						</select>
					</div>
					<div>
						<label for="inv_branch" class="block text-sm font-medium text-gray-700 mb-1">Branch</label>
						<select id="inv_branch" bind:value={form.branch_id}
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm bg-white">
							<option value="">Unassigned</option>
							{#each branches as b}
								<option value={b.id}>{b.name}</option>
							{/each}
						</select>
					</div>
				</div>
			</div>

			<!-- Access Privileges -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<div class="flex items-center justify-between">
					<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500 flex items-center gap-2">
						<Shield class="h-3.5 w-3.5" /> Initial Access Privileges
					</h2>
					<button 
						type="button"
						onclick={toggleAllPrivileges}
						class="flex items-center gap-2 px-3 py-1.5 rounded-lg border border-gray-100 hover:bg-gray-50 transition-colors"
					>
						<span class="text-[10px] font-black uppercase tracking-widest {allPrivilegesSelected ? 'text-indigo-600' : 'text-gray-400'}">
							{allPrivilegesSelected ? 'Deselect All' : 'Select All'}
						</span>
						<div class="relative shrink-0 scale-75">
							<div class="w-9 h-5 {allPrivilegesSelected ? 'bg-indigo-600' : 'bg-gray-200'} rounded-full transition-colors"></div>
							<div class="absolute top-[3px] left-[3px] h-3.5 w-3.5 bg-white rounded-full shadow transition-all {allPrivilegesSelected ? 'translate-x-4' : ''}"></div>
						</div>
					</button>
				</div>
				<div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
					{#each privileges as priv}
						<label class="flex items-center justify-between p-3 rounded-lg border border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors">
							<div class="overflow-hidden mr-3">
								<p class="text-sm font-medium text-gray-800 truncate">{priv.label}</p>
								<p class="text-xs text-gray-400 truncate">{priv.description}</p>
							</div>
							<div class="relative shrink-0">
								<input type="checkbox" bind:checked={form[priv.key]} class="sr-only peer" />
								<div class="w-9 h-5 bg-gray-200 peer-checked:bg-indigo-600 rounded-full transition-colors"></div>
								<div class="absolute top-[3px] left-[3px] h-3.5 w-3.5 bg-white rounded-full shadow transition-all peer-checked:translate-x-4"></div>
							</div>
						</label>
					{/each}
				</div>
			</div>

			<div class="flex gap-3">
				<a href="/staffs" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
					Cancel
				</a>
				<button type="submit" disabled={inviting || !form.email.trim() || !form.full_name.trim()}
					class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
					<UserPlus class="h-4 w-4" />{inviting ? 'Sending...' : 'Send Invite'}
				</button>
			</div>
		</form>
	{/if}
</div>
