<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import {
		ArrowLeft, User, Shield, Calendar, ShoppingCart,
		CheckCircle, XCircle, Upload, Save, RefreshCw, AlertCircle
	} from 'lucide-svelte';

	const staffId = $page.params.id;
	let membershipId = '';  // user_tenants row id

	let staff: any = null;
	let loading = true;
	let saving = false;
	let error = '';
	let successMsg = '';
	let activeTab = 'attendance';
	let salesFilter = 'week';

	// Role change
	let selectedRole = '';
	let showLicenseUpload = false;
	let licenseFile: File | null = null;
	let uploadingLicense = false;

	// Data
	let attendanceHistory: any[] = [];
	let salesHistory: any[] = [];
	let attendanceLoading = false;
	let salesLoading = false;

	// Privileges
	const privileges = [
		{ key: 'canManagePOS', label: 'POS Access', description: 'Can process sales' },
		{ key: 'canManageProducts', label: 'Products', description: 'Can manage products' },
		{ key: 'canManageCustomers', label: 'Customers', description: 'Can manage customers' },
		{ key: 'canManageOrders', label: 'Orders', description: 'Can view/process orders' },
		{ key: 'canViewMessages', label: 'Messages', description: 'Can access messages' },
		{ key: 'canViewAnalytics', label: 'Analytics', description: 'Can view analytics' },
		{ key: 'canManageStaff', label: 'Staff Management', description: 'Can manage staff' },
		{ key: 'canManageInventory', label: 'Inventory', description: 'Can manage inventory' },
		{ key: 'canManageBranches', label: 'Branches', description: 'Can manage branches' },
		{ key: 'canManageRoles', label: 'Roles', description: 'Can manage roles' },
		{ key: 'canTransferProduct', label: 'Transfer Products', description: 'Can transfer products' },
		{ key: 'canReturnProducts', label: 'Returns', description: 'Can process returns' },
		{ key: 'canCreatePrescription', label: 'Prescribe', description: 'Can create prescriptions' },
		{ key: 'canApplyDiscount', label: 'Discounts', description: 'Can apply manual discounts' },
		{ key: 'canReferDoctor', label: 'Doctor Referrals', description: 'Can refer patients to doctors' },
		{ key: 'canManageExpenses', label: 'Expenditure', description: 'Can manage expenses' }
	];

	let privilegeForm: Record<string, boolean> = {};

	const roles = ['cashier', 'pharmacist', 'accountant', 'branch_manager', 'tenant_admin', 'staff'];

	onMount(async () => {
		await loadStaff();
	});

	async function loadStaff() {
		loading = true;
		try {
			const activeTenantId = localStorage.getItem('active_tenant_id');

			// Load identity from users
			const { data: identity, error: idErr } = await supabase
				.from('users')
				.select('id, email, phone, full_name, avatar_url, profile_picture_url, pharmacist_reg_num, pharmacist_license_url, pharmacist_verified')
				.eq('id', staffId)
				.single();
			if (idErr) throw idErr;

			// Load membership from user_tenants for the active tenant
			const { data: membership, error: memErr } = await supabase
				.from('user_tenants')
				.select('*, branches!branch_id(id, name)')
				.eq('user_id', staffId)
				.eq('tenant_id', activeTenantId)
				.maybeSingle();
			if (memErr) throw memErr;

			staff = {
				...identity,
				role: membership?.role || 'staff',
				branches: membership?.branches,
				...Object.fromEntries(privileges.map(p => [p.key, membership?.[p.key] ?? false]))
			};
			membershipId = membership?.id || '';
			selectedRole = staff.role;
			privileges.forEach(p => { privilegeForm[p.key] = staff[p.key] ?? false; });
			await loadAttendance();
		} catch (e: any) {
			error = e.message;
		} finally {
			loading = false;
		}
	}

	async function loadAttendance() {
		attendanceLoading = true;
		try {
			const { data } = await supabase
				.from('staff_attendance')
				.select('*, branch_shifts(shift_name)')
				.eq('staff_id', staffId)
				.order('shift_date', { ascending: false })
				.limit(30);
			attendanceHistory = data || [];
		} finally {
			attendanceLoading = false;
		}
	}

	async function loadSales() {
		salesLoading = true;
		try {
			const now = new Date();
			let fromDate: Date;
			if (salesFilter === 'week') {
				fromDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7);
			} else if (salesFilter === 'month') {
				fromDate = new Date(now.getFullYear(), now.getMonth(), 1);
			} else {
				fromDate = new Date(now.getFullYear(), 0, 1);
			}

			const { data } = await supabase
				.from('sales')
				.select('id, sale_number, total_amount, payment_method, status, created_at')
				.eq('cashier_id', staffId)
				.gte('created_at', fromDate.toISOString())
				.order('created_at', { ascending: false });
			salesHistory = data || [];
		} finally {
			salesLoading = false;
		}
	}

	async function saveRole() {
		saving = true;
		error = '';
		try {
			// Update role on user_tenants
			if (membershipId) {
				const { error: roleErr } = await supabase
					.from('user_tenants')
					.update({ role: selectedRole, updated_at: new Date().toISOString() })
					.eq('id', membershipId);
				if (roleErr) throw roleErr;
			}

			// If changing to pharmacist and there's a license file, upload to users
			if (selectedRole === 'pharmacist' && licenseFile) {
				uploadingLicense = true;
				const ext = licenseFile.name.split('.').pop();
				const path = `${staffId}/license.${ext}`;
				const { error: uploadErr } = await supabase.storage
					.from('provider-licenses')
					.upload(path, licenseFile, { upsert: true });
				if (uploadErr) throw uploadErr;
				const { data: urlData } = supabase.storage.from('provider-licenses').getPublicUrl(path);
				await supabase.from('users').update({ pharmacist_license_url: urlData.publicUrl }).eq('id', staffId);
				staff.pharmacist_license_url = urlData.publicUrl;
				uploadingLicense = false;
			}

			staff = { ...staff, role: selectedRole };
			successMsg = 'Role updated successfully!';
			setTimeout(() => successMsg = '', 3000);
		} catch (e: any) {
			error = e.message;
		} finally {
			saving = false;
			uploadingLicense = false;
		}
	}

	async function savePrivileges() {
		saving = true;
		error = '';
		try {
			if (!membershipId) throw new Error('No membership found for this tenant');
			const { error: saveErr } = await supabase
				.from('user_tenants')
				.update({ ...privilegeForm, updated_at: new Date().toISOString() })
				.eq('id', membershipId);
			if (saveErr) throw saveErr;
			staff = { ...staff, ...privilegeForm };
			successMsg = 'Privileges saved!';
			setTimeout(() => successMsg = '', 3000);
		} catch (e: any) {
			error = e.message;
		} finally {
			saving = false;
		}
	}

	function getRoleBadgeClass(role: string) {
		const map: Record<string, string> = {
			tenant_admin: 'bg-purple-100 text-purple-700',
			branch_manager: 'bg-blue-100 text-blue-700',
			cashier: 'bg-green-100 text-green-700',
			pharmacist: 'bg-amber-100 text-amber-700',
			accountant: 'bg-rose-100 text-rose-700',
			staff: 'bg-gray-100 text-gray-600'
		};
		return map[role] || map.staff;
	}

	$: if (activeTab === 'sales') loadSales();
	$: if (salesFilter && activeTab === 'sales') loadSales();
	$: showLicenseUpload = selectedRole === 'pharmacist';

	function totalSales() {
		return salesHistory.reduce((sum, s) => sum + (s.total_amount || 0), 0);
	}

	function formatCurrency(val: number) {
		return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(val);
	}

	function formatDuration(h: number | null) {
		if (!h) return '—';
		const hrs = Math.floor(h);
		const mins = Math.round((h - hrs) * 60);
		return `${hrs}h ${mins}m`;
	}
</script>

<div class="max-w-5xl mx-auto p-4 md:p-8 space-y-6">
	<!-- Back -->
	<a href="/staffs" class="inline-flex items-center gap-2 text-sm text-gray-500 hover:text-gray-800 transition-colors">
		<ArrowLeft class="h-4 w-4" /> Back to Staff List
	</a>

	{#if loading}
		<div class="flex items-center justify-center py-24">
			<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
		</div>
	{:else if !staff}
		<div class="text-center py-20 text-gray-500">Staff member not found.</div>
	{:else}
		<!-- Profile Header Card -->
		<div class="bg-white rounded-2xl border border-gray-200 shadow-sm p-6">
			<div class="flex flex-col sm:flex-row items-start sm:items-center gap-5">
				<!-- Avatar -->
				<div class="h-20 w-20 rounded-full bg-indigo-100 flex items-center justify-center text-3xl font-bold text-indigo-600 border-4 border-white shadow-md shrink-0 overflow-hidden">
					{#if staff.profile_picture_url || staff.avatar_url}
						<img src={staff.profile_picture_url || staff.avatar_url} alt={staff.full_name} class="h-full w-full object-cover" />
					{:else}
						{staff.full_name?.charAt(0)?.toUpperCase() || 'U'}
					{/if}
				</div>

				<!-- Info -->
				<div class="flex-1 min-w-0">
					<h1 class="text-2xl font-bold text-gray-900">{staff.full_name}</h1>
					<p class="text-sm text-gray-500 mt-0.5">{staff.email || staff.phone}</p>
					<div class="flex flex-wrap items-center gap-2 mt-2">
						<span class="text-xs font-semibold px-2.5 py-1 rounded-full {getRoleBadgeClass(staff.role)} capitalize">
							{staff.role?.replace('_', ' ')}
						</span>
						{#if staff.branches?.name}
							<span class="text-xs text-gray-500 bg-gray-100 px-2.5 py-1 rounded-full">{staff.branches.name}</span>
						{/if}
						{#if staff.role === 'pharmacist'}
							{#if staff.pharmacist_verified}
								<span class="text-xs text-green-700 bg-green-50 px-2.5 py-1 rounded-full flex items-center gap-1">
									<CheckCircle class="h-3 w-3" /> Verified
								</span>
							{:else}
								<span class="text-xs text-amber-700 bg-amber-50 px-2.5 py-1 rounded-full flex items-center gap-1">
									<AlertCircle class="h-3 w-3" /> Unverified
								</span>
							{/if}
						{/if}
					</div>
				</div>

				<!-- Role Selector -->
				<div class="sm:text-right space-y-2 shrink-0 w-full sm:w-auto">
					<label class="block text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Change Role</label>
					<select
						bind:value={selectedRole}
						class="w-full sm:w-48 rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
					>
						{#each roles as r}
							<option value={r}>{r.replace('_', ' ')}</option>
						{/each}
					</select>

					{#if showLicenseUpload}
						<div class="mt-2">
							<label class="block text-xs text-gray-500 mb-1">
								{staff.pharmacist_license_url ? 'Replace License' : 'Upload License *'}
							</label>
							<label class="cursor-pointer flex items-center gap-2 text-xs text-indigo-600 hover:text-indigo-800 bg-indigo-50 px-3 py-2 rounded-lg border border-indigo-100">
								<Upload class="h-3.5 w-3.5" />
								{licenseFile ? licenseFile.name : 'Choose file'}
								<input type="file" accept=".pdf,.jpg,.jpeg,.png" class="hidden" onchange={(e: Event) => licenseFile = (e.target as HTMLInputElement).files?.[0] ?? null} />
							</label>
							{#if staff.pharmacist_license_url}
								<a href={staff.pharmacist_license_url} target="_blank" class="text-xs text-indigo-500 hover:underline mt-1 block">View current license</a>
							{/if}
							{#if staff.pharmacist_reg_num}
								<p class="text-xs text-gray-500 mt-1">Reg#: {staff.pharmacist_reg_num}</p>
							{/if}
						</div>
					{/if}

					{#if selectedRole !== staff.role || (showLicenseUpload && licenseFile)}
						<button
							onclick={saveRole}
							disabled={saving}
							class="w-full sm:w-auto mt-1 px-4 py-2 bg-indigo-600 text-white text-sm font-semibold rounded-xl hover:bg-indigo-700 disabled:opacity-50 flex items-center gap-2 justify-center"
						>
							{#if saving}<RefreshCw class="h-4 w-4 animate-spin" />{:else}<Save class="h-4 w-4" />{/if}
							Save Role
						</button>
					{/if}
				</div>
			</div>
		</div>

		<!-- Alerts -->
		{#if error}
			<div class="bg-red-50 text-red-700 p-4 rounded-xl flex items-start gap-2 text-sm">
				<AlertCircle class="h-4 w-4 mt-0.5 shrink-0" />{error}
			</div>
		{/if}
		{#if successMsg}
			<div class="bg-green-50 text-green-700 p-4 rounded-xl flex items-center gap-2 text-sm">
				<CheckCircle class="h-4 w-4 shrink-0" />{successMsg}
			</div>
		{/if}

		<!-- Tabs -->
		<div class="border-b border-gray-200 flex gap-0">
			{#each [
				{ id: 'attendance', label: 'Attendance History', icon: Calendar },
				{ id: 'sales', label: 'Sales History', icon: ShoppingCart },
				{ id: 'privileges', label: 'Privileges', icon: Shield }
			] as tab}
				<button
					onclick={() => activeTab = tab.id}
					class="flex items-center gap-2 px-5 py-3 text-sm font-semibold border-b-2 transition-colors {activeTab === tab.id ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700'}"
				>
					<svelte:component this={tab.icon} class="h-4 w-4" />
					{tab.label}
				</button>
			{/each}
		</div>

		<!-- Tab: Attendance History -->
		{#if activeTab === 'attendance'}
			<div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
				{#if attendanceLoading}
					<div class="p-10 text-center"><div class="animate-spin inline-block rounded-full h-6 w-6 border-b-2 border-indigo-600"></div></div>
				{:else if attendanceHistory.length === 0}
					<div class="p-10 text-center text-gray-400 text-sm">No attendance records found.</div>
				{:else}
					<div class="overflow-x-auto">
						<table class="w-full text-sm text-left">
							<thead class="bg-gray-50 border-b border-gray-100">
								<tr>
									<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase">Date</th>
									<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase">Shift</th>
									<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase">Clock In</th>
									<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase">Clock Out</th>
									<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase text-right">Hours / OT</th>
								</tr>
							</thead>
							<tbody class="divide-y divide-gray-100">
								{#each attendanceHistory as rec}
									<tr class="hover:bg-gray-50">
										<td class="px-5 py-3 text-gray-800">{new Date(rec.shift_date).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}</td>
										<td class="px-5 py-3 text-gray-500">{rec.branch_shifts?.shift_name || '—'}</td>
										<td class="px-5 py-3">{rec.clock_in_at ? new Date(rec.clock_in_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—'}</td>
										<td class="px-5 py-3">
											{#if rec.clock_out_at}
												{new Date(rec.clock_out_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
											{:else}
												<span class="text-green-600 font-medium text-xs">Active</span>
											{/if}
										</td>
										<td class="px-5 py-3 text-right">
											<span class="font-medium">{formatDuration(rec.total_hours)}</span>
											{#if rec.overtime_minutes > 0}
												<span class="ml-1 text-[10px] text-orange-600 bg-orange-50 px-1.5 py-0.5 rounded font-bold">+{rec.overtime_minutes}m OT</span>
											{/if}
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{/if}
			</div>

		<!-- Tab: Sales History -->
		{:else if activeTab === 'sales'}
			<div class="space-y-4">
				<!-- Filter -->
				<div class="flex items-center gap-2">
					{#each ['week', 'month', 'year'] as f}
						<button
							onclick={() => salesFilter = f}
							class="px-4 py-2 text-sm font-semibold rounded-xl border transition-colors capitalize {salesFilter === f ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-white text-gray-600 border-gray-200 hover:border-indigo-300'}"
						>This {f}</button>
					{/each}
				</div>

				<!-- Summary -->
				{#if salesHistory.length > 0}
					<div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
						<div class="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
							<p class="text-xs text-gray-500 font-medium uppercase">Total Sales</p>
							<p class="text-xl font-bold text-gray-900 mt-1">{salesHistory.length}</p>
						</div>
						<div class="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
							<p class="text-xs text-gray-500 font-medium uppercase">Revenue</p>
							<p class="text-xl font-bold text-gray-900 mt-1">{formatCurrency(totalSales())}</p>
						</div>
						<div class="bg-white rounded-xl border border-gray-200 p-4 shadow-sm sm:col-span-1 col-span-2">
							<p class="text-xs text-gray-500 font-medium uppercase">Avg. Per Sale</p>
							<p class="text-xl font-bold text-gray-900 mt-1">{formatCurrency(salesHistory.length ? totalSales() / salesHistory.length : 0)}</p>
						</div>
					</div>
				{/if}

				<!-- Table -->
				<div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
					{#if salesLoading}
						<div class="p-10 text-center"><div class="animate-spin inline-block rounded-full h-6 w-6 border-b-2 border-indigo-600"></div></div>
					{:else if salesHistory.length === 0}
						<div class="p-10 text-center text-gray-400 text-sm">No sales found for this period.</div>
					{:else}
						<div class="overflow-x-auto">
							<table class="w-full text-sm text-left">
								<thead class="bg-gray-50 border-b border-gray-100">
									<tr>
										<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase">Sale #</th>
										<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase">Date</th>
										<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase">Method</th>
										<th class="px-5 py-3 text-xs font-semibold text-gray-500 uppercase text-right">Amount</th>
									</tr>
								</thead>
								<tbody class="divide-y divide-gray-100">
									{#each salesHistory as sale}
										<tr class="hover:bg-gray-50">
											<td class="px-5 py-3 font-mono text-xs text-gray-700">{sale.sale_number}</td>
											<td class="px-5 py-3 text-gray-500">{new Date(sale.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}</td>
											<td class="px-5 py-3 text-gray-500 capitalize">{sale.payment_method?.replace('_', ' ')}</td>
											<td class="px-5 py-3 text-right font-bold text-gray-900">{formatCurrency(sale.total_amount)}</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					{/if}
				</div>
			</div>

		<!-- Tab: Privileges -->
		{:else if activeTab === 'privileges'}
			<div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
				<div class="p-5 border-b border-gray-100 flex items-center justify-between">
					<div>
						<h2 class="text-base font-bold text-gray-900">Access Privileges</h2>
						<p class="text-xs text-gray-500 mt-0.5">Toggle which features this staff member can access</p>
					</div>
					<button
						onclick={savePrivileges}
						disabled={saving}
						class="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-semibold rounded-xl hover:bg-indigo-700 disabled:opacity-50 transition-colors"
					>
						{#if saving}<RefreshCw class="h-4 w-4 animate-spin" />{:else}<Save class="h-4 w-4" />{/if}
						Save Privileges
					</button>
				</div>
				<div class="p-5 grid grid-cols-1 sm:grid-cols-2 gap-3">
					{#each privileges as priv}
						<label class="flex items-center justify-between p-4 rounded-xl border border-gray-100 hover:border-indigo-200 hover:bg-indigo-50/40 cursor-pointer transition-all">
							<div>
								<p class="text-sm font-semibold text-gray-800">{priv.label}</p>
								<p class="text-xs text-gray-400">{priv.description}</p>
							</div>
							<div class="relative ml-4 shrink-0">
								<input type="checkbox" bind:checked={privilegeForm[priv.key]} class="sr-only peer" />
								<div class="w-10 h-6 bg-gray-200 peer-checked:bg-indigo-600 rounded-full transition-colors"></div>
								<div class="absolute top-1 left-1 h-4 w-4 bg-white rounded-full shadow transition-all peer-checked:translate-x-4"></div>
							</div>
						</label>
					{/each}
				</div>
			</div>
		{/if}
	{/if}
</div>
