<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { Building2, ArrowRight, LogOut } from 'lucide-svelte';

	let memberships: any[] = [];
	let loading = true;

	onMount(() => {
		const raw = localStorage.getItem('pending_tenant_memberships');
		if (raw) {
			try { memberships = JSON.parse(raw); } catch {}
		}
		if (memberships.length === 0) goto('/');
		loading = false;
	});

	function selectTenant(membership: any) {
		localStorage.setItem('active_tenant_id', membership.tenant_id);
		localStorage.removeItem('pending_tenant_memberships');
		// Force a full reload so layout re-syncs with the chosen tenant
		window.location.href = '/';
	}

	async function signOut() {
		localStorage.removeItem('active_tenant_id');
		localStorage.removeItem('pending_tenant_memberships');
		await supabase.auth.signOut();
		goto('/auth/login');
	}

	function getRoleBadge(role: string) {
		const map: Record<string, string> = {
			tenant_admin: 'bg-purple-100 text-purple-700',
			branch_manager: 'bg-blue-100 text-blue-700',
			pharmacist: 'bg-amber-100 text-amber-700',
			cashier: 'bg-green-100 text-green-700',
			accountant: 'bg-rose-100 text-rose-700',
			staff: 'bg-gray-100 text-gray-600'
		};
		return map[role] || map.staff;
	}
</script>

<svelte:head>
	<title>Select Workspace — Kemani POS</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-slate-50 via-indigo-50/30 to-blue-50/20 flex items-center justify-center p-4">
	<div class="w-full max-w-md">
		{#if loading}
			<div class="flex justify-center py-20">
				<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
			</div>
		{:else}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 overflow-hidden">
				<!-- Header -->
				<div class="bg-gradient-to-br from-indigo-600 to-blue-700 px-8 pt-10 pb-8 text-white">
					<div class="h-14 w-14 bg-white/20 rounded-2xl flex items-center justify-center mb-5">
						<Building2 class="h-7 w-7 text-white" />
					</div>
					<h1 class="text-2xl font-black mb-1">Select Workspace</h1>
					<p class="text-indigo-100 text-sm">You belong to multiple organisations. Choose which one to work in today.</p>
				</div>

				<!-- Memberships -->
				<div class="p-5 space-y-3">
					{#each memberships as m}
						{@const t = m.tenants}
						{@const b = m.branches}
						<button
							onclick={() => selectTenant(m)}
							class="w-full text-left p-4 rounded-2xl border border-gray-100 hover:border-indigo-300 hover:bg-indigo-50/40 transition-all group"
						>
							<div class="flex items-center gap-4">
								<div class="h-12 w-12 rounded-xl bg-indigo-100 flex items-center justify-center font-black text-indigo-700 text-lg shrink-0 overflow-hidden">
									{#if t?.logo_url}
										<img src={t.logo_url} alt="" class="h-full w-full object-cover" />
									{:else}
										{t?.name?.charAt(0)?.toUpperCase() || '?'}
									{/if}
								</div>
								<div class="flex-1 min-w-0">
									<p class="font-bold text-gray-900 truncate">{t?.name || 'Unknown'}</p>
									<div class="flex items-center gap-2 mt-1 flex-wrap">
										<span class="text-xs px-2 py-0.5 rounded-full font-semibold {getRoleBadge(m.role)} capitalize">
											{m.role?.replace('_', ' ')}
										</span>
										{#if b?.name}
											<span class="text-xs text-gray-400">{b.name}</span>
										{/if}
									</div>
								</div>
								<ArrowRight class="h-5 w-5 text-gray-300 group-hover:text-indigo-500 transition-colors shrink-0" />
							</div>
						</button>
					{/each}
				</div>

				<!-- Sign out -->
				<div class="px-5 pb-6">
					<button
						onclick={signOut}
						class="w-full flex items-center justify-center gap-2 text-sm text-gray-500 hover:text-red-600 py-2.5 rounded-xl border border-gray-100 hover:border-red-100 hover:bg-red-50 transition-all"
					>
						<LogOut class="h-4 w-4" /> Sign out
					</button>
				</div>
			</div>

			<p class="text-center text-xs text-gray-400 mt-6">Kemani POS — Multi-Workspace Support</p>
		{/if}
	</div>
</div>
