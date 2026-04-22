<script lang="ts">
	import { page } from '$app/stores';
	import {
		LayoutDashboard, Package, Users, ShoppingCart, BarChart3, Settings, 
		Store, LogOut, MessageSquare, Briefcase, Building, ClipboardList,
		FlaskConical, Truck, Stethoscope, Coins
	} from 'lucide-svelte';

	let { tenant, userData, email, handleLogout, onnavclick = (e: any) => {} } = $props<any>();

	let navigation = $derived([
		{ name: 'Dashboard', href: '/', icon: LayoutDashboard, visible: true },
		{ name: 'POS', href: '/pos', icon: Store, visible: userData?.canManagePOS ?? false },
		{ name: 'Products', href: '/products', icon: Package, visible: userData?.canManageProducts ?? false },
		{ name: 'Lab Tests', href: '/lab-tests', icon: FlaskConical, visible: (userData?.canManageProducts ?? false) && (Array.isArray(userData?.branches) ? userData.branches[0]?.business_type === 'diagnostic_centre' : userData?.branches?.business_type === 'diagnostic_centre') },
		{ name: 'Suppliers', href: '/suppliers', icon: Truck, visible: userData?.canManageProducts ?? false },
		{ name: 'Medic Partners', href: '/medics', icon: Stethoscope, visible: tenant?.allowDoctorPartnerShip ?? true },
		{ name: 'Customers', href: '/customers', icon: Users, visible: userData?.['canManage Customers'] ?? false },
		{ name: 'Orders', href: '/orders', icon: ShoppingCart, visible: userData?.canManageOrders ?? false },
		{ name: 'Inventory', href: '/inventory', icon: ClipboardList, visible: userData?.canManageInventory ?? false },
		{ name: 'Staffs', href: '/staffs', icon: Briefcase, visible: userData?.canMangeStaff ?? false },
		{ name: 'Messages', href: '/messages', icon: MessageSquare, visible: true },
		{ name: 'Commissions', href: '/commissions', icon: Coins, visible: userData?.role === 'tenant_admin' },
		{ name: 'Branches', href: '/branches', icon: Building, visible: userData?.canManagebranches ?? false },
		{ name: 'Analytics', href: '/analytics', icon: BarChart3, visible: userData?.canViewAnalytics ?? false },
		{ name: 'Settings', href: '/settings', icon: Settings, visible: true }
	].filter(item => item.visible));

	function getInitial(emailStr: string | undefined): string {
		return emailStr ? emailStr.charAt(0).toUpperCase() : 'U';
	}
</script>

<div class="flex flex-col h-full bg-white">
	<!-- Brand -->
	<div class="p-4 border-b shrink-0">
		<h1 class="text-xl font-bold text-gray-900">{tenant?.name || 'Kemani POS'}</h1>
		<p class="text-sm text-gray-500">Business Dashboard</p>
	</div>

	<!-- Navigation -->
	<nav class="p-4 space-y-1 flex-1 overflow-y-auto min-h-0" style="max-height: calc(100vh - 160px);">
		{#each navigation as item}
			{@const Icon = item.icon}
			<a
				href={item.href}
				onclick={onnavclick}
				class="flex items-center gap-3 px-3 py-2 rounded-md transition-colors {$page.url.pathname === item.href ? 'bg-indigo-50 text-indigo-700 font-medium' : 'text-gray-700 hover:bg-gray-100'}"
			>
				<Icon class="h-5 w-5" />
				{item.name}
			</a>
		{/each}
	</nav>

	<!-- Profile and Logout -->
	<div class="p-4 border-t flex flex-col gap-4 shrink-0">
		<!-- User Profile -->
		<div class="flex items-center gap-3">
			{#if userData?.profile_picture_url}
				<img src={userData.profile_picture_url} alt="Profile" class="h-9 w-9 rounded-full object-cover border border-gray-200 shadow-sm" />
			{:else}
				<div class="h-9 w-9 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold border border-indigo-200">
					{getInitial(email)}
				</div>
			{/if}
			<div class="flex-1 min-w-0">
				<p class="text-sm font-bold text-gray-900 truncate">{userData?.full_name || 'User'}</p>
				<p class="text-[10px] text-gray-500 truncate">{email || ''}</p>
			</div>
		</div>

		<button
			onclick={handleLogout}
			class="w-full flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-md transition-colors"
		>
			<LogOut class="h-4 w-4" />
			Logout
		</button>
	</div>
</div>


