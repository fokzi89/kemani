<script lang="ts">
	import { Stethoscope, Star, Clock, ShieldCheck, MapPin } from 'lucide-svelte';

	export let data;

	// The layout fetches store context
	$: providers = data.providers || [];
	$: storeBrand = data.tenant?.brand_color || '#4f46e5';
</script>

<svelte:head>
	<title>Medics | {data.tenant?.name || 'Healthcare'} </title>
	<meta name="description" content="View our verified healthcare providers and medics." />
</svelte:head>

<div class="min-h-[80vh] bg-[#F8FAFC]">
	<!-- Medics Header -->
	<section class="bg-white border-b border-gray-100 py-12 md:py-16">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-4">
			<div class="inline-flex items-center justify-center p-3 rounded-full bg-indigo-50 mb-2">
				<Stethoscope class="w-8 h-8 opacity-80" style="color: {storeBrand};" />
			</div>
			<h1 class="text-3xl md:text-5xl font-black text-gray-900 tracking-tight">Our Verified Medics</h1>
			<p class="text-gray-500 max-w-xl mx-auto text-sm md:text-base font-medium">
				Browse our network of certified healthcare professionals, ready to assist you safely and accurately.
			</p>
		</div>
	</section>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
		{#if providers.length === 0}
			<div class="py-20 text-center flex flex-col items-center">
				<div class="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
					<Stethoscope class="h-8 w-8 text-gray-400" />
				</div>
				<h3 class="text-lg font-bold text-gray-900 mb-1">No Providers Found</h3>
				<p class="text-gray-500 text-sm">There are no active medics currently listed for this store.</p>
			</div>
		{:else}
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
				{#each providers as medic}
					{@const fullName = medic.name || [medic.first_name, medic.last_name].filter(Boolean).join(' ') || 'Healthcare Provider'}
					{@const imgUrl = medic.profile_image_url || medic.avatar_url}
					<div class="bg-white rounded-2xl border border-gray-200 overflow-hidden hover:shadow-lg transition-all duration-300 group">
						<!-- Provider Image -->
						<div class="h-48 bg-gray-100 relative overflow-hidden">
							{#if imgUrl}
								<img src={imgUrl} alt={fullName} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
							{:else}
								<div class="w-full h-full flex flex-col items-center justify-center bg-gradient-to-br from-indigo-50 to-blue-50">
									<Stethoscope class="h-12 w-12 text-indigo-300 mb-2" />
								</div>
							{/if}
							
							<!-- Top Badges -->
							<div class="absolute top-3 left-3 flex gap-2">
								<span class="inline-flex items-center gap-1 bg-white/90 backdrop-blur-sm text-[10px] font-bold text-emerald-600 px-2.5 py-1 rounded-full shadow-sm">
									<ShieldCheck class="w-3 h-3" /> Verified
								</span>
							</div>
						</div>

						<!-- Details -->
						<div class="p-5 space-y-4">
							<div>
								<h3 class="font-bold text-lg text-gray-900 group-hover:text-indigo-600 transition-colors line-clamp-1" title={fullName}>
									{fullName}
								</h3>
								{#if medic.specialty}
									<p class="text-sm font-semibold mt-1" style="color: {storeBrand};">{medic.specialty}</p>
								{/if}
							</div>

							<!-- Bio Snippet -->
							{#if medic.bio || medic.description}
								<p class="text-sm text-gray-500 line-clamp-2 leading-relaxed">
									{medic.bio || medic.description}
								</p>
							{/if}

							<!-- Stats Row -->
							<div class="flex items-center gap-4 pt-4 border-t border-gray-100 text-xs font-semibold text-gray-600">
								{#if medic.years_of_experience}
									<div class="flex items-center gap-1.5">
										<Clock class="w-3.5 h-3.5 opacity-60" />
										{medic.years_of_experience} Years
									</div>
								{/if}
								{#if medic.qualifications}
									<div class="flex items-center gap-1.5">
										<Star class="w-3.5 h-3.5 opacity-60" />
										{medic.qualifications}
									</div>
								{/if}
								<!-- Generic fallback if fields don't exactly match a standard medic -> ensure it prints -->
								{#if !medic.years_of_experience && !medic.qualifications}
									<div class="flex items-center gap-1.5 text-gray-400">
										<ShieldCheck class="w-3.5 h-3.5 opacity-60" />
										Licensed Professional
									</div>
								{/if}
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
