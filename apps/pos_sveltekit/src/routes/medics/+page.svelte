<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Stethoscope, Search, UserPlus, MoreVertical, ShieldCheck, Mail, MapPin, Building, ChevronRight, Activity, Filter } from 'lucide-svelte';
	import { goto } from '$app/navigation';

	let medics = $state<any[]>([
		{ id: '1', full_name: 'Dr. Johnathan Walker', type: 'Dermatologist', specialization: 'Medical Aesthetics', email: 'j.walker@medical.com', region: 'Lagos', country: 'NG', total_consultations: 1250, is_active: true, is_verified: true },
		{ id: '2', full_name: 'Dr. Sarah Adewale', type: 'Pediatrician', specialization: 'Child Health', email: 's.adewale@healthcare.org', region: 'Abuja', country: 'NG', total_consultations: 850, is_active: true, is_verified: true },
		{ id: '3', full_name: 'Dr. Robert Chen', type: 'Optometrist', specialization: 'Corneal specialist', email: 'r.chen@eyeclinic.com', region: 'Kano', country: 'NG', total_consultations: 2100, is_active: false, is_verified: true },
		{ id: '4', full_name: 'Dr. Fatima Ibrahim', type: 'Generalist', specialization: 'Family Medicine', email: 'f.ibrahim@healthhub.ng', region: 'Port Harcourt', country: 'NG', total_consultations: 430, is_active: true, is_verified: false },
	]);
	let loading = $state(false);
	let searchQuery = $state('');

	let filteredMedics = $derived(
		medics.filter(m => 
			m.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
			m.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
			m.type?.toLowerCase().includes(searchQuery.toLowerCase())
		)
	);

	onMount(async () => {
		try {
			// Optional: loading = true; if you want the spinner only for network fetches
			const { data, error } = await supabase
				.from('healthcare_providers')
				.select('*')
				.order('created_at', { ascending: false });
			
			if (data && data.length > 0) {
				medics = data;
			}
		} catch (e) {
			console.error('Fetch error:', e);
		} finally {
			loading = false;
		}
	});
</script>

<svelte:head><title>Medics – Kemani POS</title></svelte:head>

<div class="p-6 space-y-6 max-w-7xl mx-auto">
	<!-- Header -->
	<div class="mb-2">
		<h1 class="text-2xl font-bold text-gray-900">Medic list</h1>
		<p class="text-sm text-gray-500 mt-1">Monitor healthcare providers and consultation metrics.</p>
	</div>

	<!-- Filters & Search -->
	<div class="flex flex-col md:flex-row gap-4 items-center">
		<div class="relative flex-1 group">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input 
				type="text" 
				bind:value={searchQuery}
				placeholder="Search by name, specialty, or region..."
				class="w-full pl-9 pr-4 py-2 bg-white border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 text-sm transition-all outline-none"
			/>
		</div>
		<button class="p-2 aspect-square bg-white border border-gray-200 text-gray-500 rounded-xl hover:bg-gray-50 shadow-sm">
			<Filter class="h-4 w-4" />
		</button>
	</div>

	<!-- Medics Table -->
	<div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden min-h-[500px]">
		<div class="p-4 border-b border-gray-50 flex flex-col md:flex-row gap-3 items-center justify-between bg-gray-50/30">
			<h3 class="font-bold text-gray-900 text-sm">Provider Directory</h3>
			<div class="flex items-center gap-2 text-xs font-bold text-indigo-500 px-3 py-1.5 bg-indigo-50 rounded-lg border border-indigo-100">
				{filteredMedics.length} Verified
			</div>
		</div>

		{#if loading}
			<div class="p-20 text-center">
				<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
				<p class="text-xs text-gray-500 mt-4 font-medium italic">Syncing medical directory...</p>
			</div>
		{:else if filteredMedics.length === 0}
			<div class="p-20 text-center">
				<div class="bg-gray-50 h-16 w-16 rounded-full flex items-center justify-center mx-auto mb-4 border border-gray-100">
					<Stethoscope class="h-8 w-8 text-gray-300" />
				</div>
				<h3 class="text-lg font-bold text-gray-900">No Providers Found</h3>
				<p class="text-gray-500 text-sm mt-1 max-w-xs mx-auto font-medium">Try adjusting your filters or checking the database.</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="bg-gray-50 border-b">
						<tr>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-widest">Medical Provider</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-widest">Specialty Type</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-widest text-center">Consultations</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-widest text-center">Status</th>
							<th class="px-6 py-4 text-right">Action</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each filteredMedics as medic}
							<tr class="hover:bg-gray-50 transition-colors group">
								<td class="px-6 py-4">
									<div class="flex items-center gap-3">
										<div class="h-10 w-10 rounded-xl bg-gradient-to-br from-indigo-50 to-purple-50 flex items-center justify-center border border-indigo-100/50 shadow-sm overflow-hidden flex-shrink-0">
											{#if medic.profile_photo_url}
												<img src={medic.profile_photo_url} alt={medic.full_name} class="h-full w-full object-cover" />
											{:else}
												<p class="text-indigo-400 font-bold">{medic.full_name?.charAt(0) || 'D'}</p>
											{/if}
										</div>
										<div class="min-w-0">
											<div class="flex items-center gap-1.5">
												<p class="font-bold text-gray-900 truncate">{medic.full_name}</p>
												{#if medic.is_verified}
													<ShieldCheck class="h-3.5 w-3.5 text-blue-500" />
												{/if}
											</div>
											<div class="flex items-center gap-2 mt-0.5">
												<div class="flex items-center gap-1 text-[10px] text-gray-400 font-medium tracking-tight">
													<MapPin class="h-3 w-3" /> {medic.region || 'Unknown'}, {medic.country || 'NG'}
												</div>
											</div>
										</div>
									</div>
								</td>
								<td class="px-6 py-4">
									<p class="font-semibold text-gray-800 capitalize leading-none">{medic.type || 'Generalist'}</p>
									<p class="text-[10px] text-gray-400 font-medium uppercase mt-1 tracking-tighter">{medic.specialization || 'Consultant'}</p>
								</td>
								<td class="px-6 py-4 text-center">
									<div class="inline-flex flex-col items-center">
										<span class="text-sm font-bold text-gray-900 leading-tight">{medic.total_consultations?.toLocaleString() || 0}</span>
										<span class="text-[9px] font-bold text-gray-400 uppercase tracking-widest">Total Sessions</span>
									</div>
								</td>
								<td class="px-6 py-4 text-center">
									{#if medic.is_active}
										<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-green-50 text-green-700 border border-green-100">
											<div class="h-1.5 w-1.5 bg-green-500 rounded-full animate-pulse"></div> ACTIVE
										</span>
									{:else}
										<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-gray-50 text-gray-500 border border-gray-100">
											OFFLINE
										</span>
									{/if}
								</td>
								<td class="px-6 py-4 text-right">
									<button 
										type="button"
										onclick={() => goto(`/medics/${medic.id}`)}
										class="px-3 py-1.5 bg-white border border-gray-200 rounded-lg text-[10px] font-bold text-gray-700 hover:bg-indigo-600 hover:text-white hover:border-indigo-600 transition-all shadow-sm uppercase tracking-widest"
									>
										View Profile
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

