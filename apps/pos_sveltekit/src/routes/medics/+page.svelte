<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Stethoscope, Search, UserPlus, MoreVertical, ShieldCheck, Mail, MapPin } from 'lucide-svelte';

	let medics = $state<any[]>([]);
	let loading = $state(true);
	let searchQuery = $state('');

	let filteredMedics = $derived(
		medics.filter(m => 
			m.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
			m.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
			m.type?.toLowerCase().includes(searchQuery.toLowerCase())
		)
	);

	onMount(async () => {
		const { data, error } = await supabase
			.from('healthcare_providers')
			.select('*')
			.order('created_at', { ascending: false });
		
		if (data) medics = data;
		loading = false;
	});
</script>

<div class="p-8 max-w-7xl mx-auto space-y-6">
	<div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
		<div>
			<h1 class="text-3xl font-extrabold text-gray-900 tracking-tight flex items-center gap-3">
				<div class="p-2 bg-indigo-100 rounded-lg">
					<Stethoscope class="h-8 w-8 text-indigo-600" />
				</div>
				Medics
			</h1>
			<p class="text-gray-500 mt-1 font-medium">Manage and monitor health service providers.</p>
		</div>
		<button class="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2.5 px-6 rounded-xl transition-all shadow-lg shadow-indigo-200">
			<UserPlus class="h-5 w-5" />
			Add Provider
		</button>
	</div>

	<div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
		<div class="p-6 border-b border-gray-50 flex flex-col md:flex-row gap-4 items-center">
			<div class="relative flex-1">
				<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
				<input 
					type="text" 
					bind:value={searchQuery}
					placeholder="Search medics by name, email or specialty..."
					class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-indigo-500 transition-all font-medium text-sm"
				/>
			</div>
			<div class="flex items-center gap-2 text-sm font-bold text-gray-400 px-4 py-2 bg-gray-50 rounded-lg">
				{filteredMedics.length} Providers Found
			</div>
		</div>

		{#if loading}
			<div class="p-20 text-center">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
				<p class="text-gray-500 mt-4 font-medium italic">Loading healthcare professionals...</p>
			</div>
		{:else if filteredMedics.length === 0}
			<div class="p-20 text-center">
				<div class="bg-gray-50 h-20 w-20 rounded-full flex items-center justify-center mx-auto mb-6">
					<Stethoscope class="h-10 w-10 text-gray-300" />
				</div>
				<h3 class="text-xl font-bold text-gray-900">No Medics Found</h3>
				<p class="text-gray-500 mt-2 max-w-sm mx-auto font-medium">We couldn't find any healthcare providers matching your search criteria.</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left">
					<thead class="bg-gray-50/50 border-b border-gray-100">
						<tr>
							<th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Provider</th>
							<th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Type / Specialty</th>
							<th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Stats</th>
							<th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-center">Status</th>
							<th class="px-6 py-4 text-right"></th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-50">
						{#each filteredMedics as medic}
							<tr class="hover:bg-indigo-50/30 transition-colors group">
								<td class="px-6 py-5">
									<div class="flex items-center gap-4">
										<div class="h-12 w-12 rounded-xl bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center border-2 border-white shadow-sm overflow-hidden">
											{#if medic.profile_photo_url}
												<img src={medic.profile_photo_url} alt={medic.full_name} class="h-full w-full object-cover" />
											{:else}
												<span class="text-indigo-700 font-bold text-lg">{medic.full_name?.charAt(0) || 'D'}</span>
											{/if}
										</div>
										<div>
											<div class="flex items-center gap-1.5">
												<p class="font-bold text-gray-900 group-hover:text-indigo-700 transition-colors">{medic.full_name}</p>
												{#if medic.is_verified}
													<ShieldCheck class="h-4 w-4 text-blue-500" />
												{/if}
											</div>
											<div class="flex flex-col gap-0.5 mt-0.5">
												<div class="flex items-center gap-1.5 text-xs text-gray-500 font-medium">
													<Mail class="h-3 w-3" /> {medic.email}
												</div>
												<div class="flex items-center gap-1.5 text-xs text-gray-400 font-medium tracking-tight">
													<MapPin class="h-3 w-3" /> {medic.region || 'Unknown'}, {medic.country || 'NG'}
												</div>
											</div>
										</div>
									</div>
								</td>
								<td class="px-6 py-5">
									<div class="flex flex-col">
										<span class="text-sm font-bold text-gray-700 capitalize tracking-tight">{medic.type || 'Generalist'}</span>
										<span class="text-xs text-gray-400 font-medium italic mt-0.5">{medic.specialization || 'Consultant'}</span>
									</div>
								</td>
								<td class="px-6 py-5 text-center">
									<div class="inline-flex flex-col items-center">
										<span class="text-sm font-black text-gray-900">{medic.total_consultations || 0}</span>
										<span class="text-[10px] font-bold text-gray-400 uppercase tracking-tighter">Consults</span>
									</div>
								</td>
								<td class="px-6 py-5 text-center">
									{#if medic.is_active}
										<span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700 border border-green-200">
											Active
										</span>
									{:else}
										<span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-gray-100 text-gray-500 border border-gray-200">
											Offline
										</span>
									{/if}
								</td>
								<td class="px-6 py-5 text-right">
									<button class="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-all">
										<MoreVertical class="h-5 w-5" />
									</button>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</div>
</div>
