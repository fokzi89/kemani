<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { X, Search, User, Loader2, Building } from 'lucide-svelte';
	import { fade, scale } from 'svelte/transition';

	let { tenantId, onSelect, onClose } = $props<{
		tenantId: string;
		onSelect: (staff: any) => void;
		onClose: () => void;
	}>();

	let staffs = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');

	onMount(async () => {
		await loadStaffs();
	});

	async function loadStaffs() {
		loading = true;
		const { data, error } = await supabase
			.from('users')
			.select('*, branches(name)')
			.eq('tenant_id', tenantId)
			.order('full_name');
		
		if (!error) {
			staffs = data || [];
		}
		loading = false;
	}

	let filteredStaffs = $derived(
		staffs.filter(s => 
			(s.full_name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
			(s.email || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
			(s.branches?.name || '').toLowerCase().includes(searchQuery.toLowerCase())
		)
	);
</script>

<div 
	transition:fade={{ duration: 200 }}
	class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm"
>
	<div 
		transition:scale={{ start: 0.95, duration: 200 }}
		class="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden border border-gray-100"
	>
		<!-- Header -->
		<div class="p-6 border-b flex items-center justify-between bg-gray-50/50">
			<div>
				<h2 class="text-xl font-black text-gray-900">New Message</h2>
				<p class="text-xs text-gray-500 font-bold uppercase tracking-wider mt-1">Select a team member</p>
			</div>
			<button 
				onclick={onClose}
				class="p-2 hover:bg-gray-100 rounded-xl transition-colors text-gray-400 hover:text-gray-600"
			>
				<X class="h-6 w-6" />
			</button>
		</div>

		<!-- Search -->
		<div class="p-4 border-b">
			<div class="relative">
				<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input 
					type="text" 
					bind:value={searchQuery}
					placeholder="Search staff by name or branch..."
					class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 transition-all outline-none"
					autofocus
				/>
			</div>
		</div>

		<!-- List -->
		<div class="max-h-[400px] overflow-y-auto p-2">
			{#if loading}
				<div class="flex flex-col items-center justify-center py-12 text-gray-400 italic">
					<Loader2 class="h-8 w-8 animate-spin mb-4 text-indigo-600" />
					<p>Finding your teammates...</p>
				</div>
			{:else if filteredStaffs.length === 0}
				<div class="py-12 text-center">
					<p class="text-sm text-gray-500 font-bold">No staff found matching "{searchQuery}"</p>
				</div>
			{:else}
				<div class="space-y-1">
					{#each filteredStaffs as staff}
						<button 
							onclick={() => onSelect(staff)}
							class="w-full p-3 flex items-center gap-4 hover:bg-indigo-50 rounded-2xl transition-all group"
						>
							<div class="h-12 w-12 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold border-2 border-white shadow-sm shrink-0 group-hover:scale-105 transition-transform">
								{#if staff.avatar_url}
									<img src={staff.avatar_url} alt="" class="h-full w-full object-cover rounded-full" />
								{:else}
									{staff.full_name.charAt(0)}
								{/if}
							</div>
							<div class="flex-1 min-w-0 text-left">
								<p class="text-sm font-black text-gray-900 truncate group-hover:text-indigo-700 transition-colors">{staff.full_name}</p>
								<div class="flex items-center gap-2 mt-0.5">
									<span class="text-[10px] font-bold text-gray-400 uppercase">{staff.role.replace('_', ' ')}</span>
									{#if staff.branches}
										<span class="text-gray-300">•</span>
										<div class="flex items-center gap-1 text-[10px] font-bold text-indigo-500 uppercase">
											<Building class="h-3 w-3" />
											{staff.branches.name}
										</div>
									{/if}
								</div>
							</div>
						</button>
					{/each}
				</div>
			{/if}
		</div>
	</div>
</div>
