<script lang="ts">
	import { Stethoscope, Star, Clock, ShieldCheck, MapPin, Tag } from 'lucide-svelte';

	export let data;

	// The layout fetches store context
	$: providers = data.providers || [];
	$: storefront = data.storefront;
	$: storeBrand = storefront?.brand_color || '#4f46e5';
</script>

<svelte:head>
	<title>Medics | {storefront?.name || 'Healthcare'} </title>
	<meta name="description" content="View our network of verified healthcare professionals." />
</svelte:head>

<div class="min-h-[80vh] bg-[#F8FAFC]">
	<!-- Medics Header -->
	<section class="bg-white border-b border-gray-100 py-12 md:py-16">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-4">
			<div class="inline-flex items-center justify-center p-3 rounded-full bg-indigo-50 mb-2">
				<Stethoscope class="w-8 h-8 opacity-80" data-brand={storeBrand} style="color: var(--brand, {storeBrand});" />
			</div>
			<h1 class="text-3xl md:text-5xl font-black text-gray-900 tracking-tight">Verified Professionals</h1>
			<p class="text-gray-500 max-w-xl mx-auto text-sm md:text-base font-medium leading-relaxed">
				Browse our network of certified healthcare providers, ready to assist you safely and accurately.
			</p>
		</div>
	</section>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
		{#if providers.length === 0}
			<div class="py-20 text-center flex flex-col items-center">
				<div class="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
					<Stethoscope class="h-8 w-8 text-gray-400" />
				</div>
				<h3 class="text-lg font-black text-gray-900 mb-1 tracking-tight">No Providers Found</h3>
				<p class="text-gray-500 text-sm font-medium">There are no active professionals currently listed in this directory.</p>
			</div>
		{:else}
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
				{#each providers as medic}
					{@const fullName = medic.full_name || 'Healthcare Provider'}
					{@const imgUrl = medic.profile_photo_url}
					<div class="bg-white rounded-3xl border border-gray-100 overflow-hidden hover:shadow-xl transition-all duration-500 group flex flex-col">
						<!-- Provider Image -->
						<div class="h-56 bg-gray-50 relative overflow-hidden">
							{#if imgUrl}
								<img src={imgUrl} alt={fullName} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" />
							{:else}
								<div class="w-full h-full flex flex-col items-center justify-center bg-gradient-to-br from-gray-50 to-indigo-50">
									<Stethoscope class="h-12 w-12 text-gray-200 mb-2" />
								</div>
							{/if}
							
							<!-- Top Badges -->
							<div class="absolute top-4 left-4 flex flex-col gap-2">
								{#if medic.is_verified}
									<span class="inline-flex items-center gap-1.5 bg-white/95 backdrop-blur-md text-[10px] font-black uppercase tracking-widest text-emerald-600 px-3 py-1.5 rounded-full shadow-sm">
										<ShieldCheck class="w-3.5 h-3.5" /> Verified
									</span>
								{/if}
								{#if medic.type}
									<span class="inline-flex items-center gap-1 bg-gray-900 text-white text-[9px] font-black uppercase tracking-widest px-3 py-1.5 rounded-full shadow-sm">
										{medic.type}
									</span>
								{/if}
							</div>
						</div>

						<!-- Details -->
						<div class="p-6 flex-1 flex flex-col">
							<div class="space-y-1 mb-4 flex-1">
								<div class="flex items-center justify-between gap-2">
									<h3 class="font-black text-lg text-gray-900 group-hover:text-indigo-600 transition-colors line-clamp-1 tracking-tight" title={fullName}>
										{fullName}
									</h3>
									{#if medic.average_rating}
										<div class="flex items-center gap-1 bg-amber-50 px-2 py-0.5 rounded-full">
											<Star class="h-3 w-3 text-amber-500 fill-amber-500" />
											<span class="text-[10px] font-black text-amber-700">{medic.average_rating}</span>
										</div>
									{/if}
								</div>
								{#if medic.specialization}
									<p class="text-xs font-black uppercase tracking-[0.15em] opacity-60 line-clamp-1" style="color: var(--brand, {storeBrand});">{medic.specialization}</p>
								{/if}
								
								{#if medic.bio}
									<p class="text-xs text-gray-500 line-clamp-2 leading-relaxed font-medium mt-3">
										{medic.bio}
									</p>
								{/if}
							</div>

							<!-- Stats Row -->
							<div class="flex items-center gap-4 pt-5 border-t border-gray-50 text-[10px] font-black uppercase tracking-widest text-gray-400">
								{#if medic.years_of_experience}
									<div class="flex items-center gap-1.5">
										<Clock class="w-3.5 h-3.5 opacity-40 shrink-0" />
										{medic.years_of_experience}y Experience
									</div>
								{/if}
								{#if medic.credentials}
									<div class="flex items-center gap-1.5 truncate flex-1">
										<ShieldCheck class="w-3.5 h-3.5 opacity-40 shrink-0" />
										{medic.credentials}
									</div>
								{/if}
							</div>

							<!-- Location Info -->
							<div class="flex items-center gap-1 text-[10px] uppercase font-black tracking-widest text-gray-300 pt-3">
								<MapPin class="h-3 w-3 shrink-0" /> 
								<span class="truncate">{medic.country} {medic.region || ''}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
