<script lang="ts">
	import { Stethoscope, ShieldCheck, Star, Clock, MapPin, Award, Calendar, Video, ArrowLeft, Send, User } from 'lucide-svelte';
	import { goto } from '$app/navigation';

	export let data;
	$: medic = data.medic;
	$: tenant = data.tenant;
	$: brandColor = tenant?.brand_color || '#4f46e5';

	// Booking state
	let consultationType = 'general_checkup';
	let preferredDate = '';
	let preferredTime = '';
	let isBooking = false;

	const consultationTypes = [
		{ value: 'general_checkup', label: 'General Checkup', duration: '30 min', price: '₦10,000' },
		{ value: 'follow_up', label: 'Follow-up Consultation', duration: '15 min', price: '₦5,000' },
		{ value: 'prescription_renewal', label: 'Prescription Renewal', duration: '10 min', price: '₦2,500' },
		{ value: 'specialist_review', label: 'Specialist Review', duration: '45 min', price: '₦25,000' }
	];

	$: selectedConsultation = consultationTypes.find(t => t.value === consultationType);

	async function bookConsultation() {
		isBooking = true;
		
		// In a real implementation this would call an API such as POST /api/consultations/book
		// For now we'll simulate a slight delay and show a success redirect or alert.
		setTimeout(() => {
			alert(`Consultation booked successfully with ${medic.full_name || 'Dr.'} for ${preferredDate || 'soon'}.`);
			isBooking = false;
			goto('/medics');
		}, 1500);
	}
</script>

<svelte:head>
	<title>{medic?.full_name || 'Healthcare Provider'} | {tenant?.name || 'Healthcare'}</title>
</svelte:head>

<div class="min-h-screen bg-[#F8FAFC]">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-16">
		
		<!-- Breadcrumbs -->
		<div class="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-gray-400 mb-8 overflow-x-auto whitespace-nowrap">
			<a href="/medics" class="hover:text-indigo-600 transition-colors flex items-center gap-1"><ArrowLeft class="h-3 w-3" /> All Providers</a>
			<span class="mx-2 opacity-30">/</span>
			<span class="opacity-60">{medic?.type || 'Provider'}</span>
			<span class="mx-2 opacity-30">/</span>
			<span class="text-gray-900 truncate">{medic?.full_name || 'Details'}</span>
		</div>

		{#if medic}
			<div class="grid lg:grid-cols-3 gap-8 md:gap-12 items-start">
				
				<!-- Left Column: Medic Details -->
				<div class="lg:col-span-2 space-y-8">
					<!-- Profile Card -->
					<div class="bg-white rounded-[40px] p-6 sm:p-10 border border-gray-100 shadow-sm flex flex-col md:flex-row gap-8">
						<!-- Image -->
						<div class="w-24 h-24 md:w-32 md:h-32 rounded-full rounded-tr-xl flex-shrink-0 bg-gray-50 overflow-hidden relative shadow-inner">
							{#if medic.profile_photo_url}
								<img src={medic.profile_photo_url} alt={medic.full_name} class="w-full h-full object-cover" />
							{:else}
								<div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-gray-50 to-indigo-50">
									<Stethoscope class="h-16 w-16 text-gray-200" />
								</div>
							{/if}
						</div>
						
						<!-- Header Info -->
						<div class="flex-1 space-y-4 flex flex-col justify-center">
							<div>
								<div class="flex flex-wrap items-center gap-3 mb-2">
									{#if medic.type}
										<span class="px-3 py-1 bg-indigo-50 text-indigo-700 text-[10px] font-black uppercase tracking-widest rounded-full">{medic.type}</span>
									{/if}
									{#if medic.is_verified}
										<span class="px-3 py-1 bg-emerald-50 text-emerald-600 text-[10px] font-black uppercase tracking-widest rounded-full flex items-center gap-1.5"><ShieldCheck class="w-3 h-3" /> Verified</span>
									{/if}
								</div>
								
								<h1 class="text-2xl sm:text-3xl font-black text-gray-900 tracking-tight leading-none mb-2">{medic.full_name || 'Healthcare Provider'}</h1>
								{#if medic.specialization}
									<p class="text-xs font-black uppercase tracking-[0.1em] opacity-80" style="color: {brandColor};">{medic.specialization}</p>
								{/if}
							</div>
							
							<div class="flex flex-wrap gap-4 pt-2">
								{#if medic.average_rating}
									<div class="flex items-center gap-1.5">
										<div class="h-8 w-8 rounded-full bg-amber-50 flex items-center justify-center"><Star class="h-4 w-4 text-amber-500 fill-amber-500" /></div>
										<div class="flex flex-col">
											<span class="text-sm font-black text-gray-900 leading-none">{medic.average_rating}</span>
											<span class="text-[9px] text-gray-400 font-bold uppercase tracking-widest">Rating</span>
										</div>
									</div>
								{/if}
								{#if medic.years_of_experience}
									<div class="flex items-center gap-1.5">
										<div class="h-8 w-8 rounded-full bg-blue-50 flex items-center justify-center"><Clock class="h-4 w-4 text-blue-500" /></div>
										<div class="flex flex-col">
											<span class="text-sm font-black text-gray-900 leading-none">{medic.years_of_experience}+ Years</span>
											<span class="text-[9px] text-gray-400 font-bold uppercase tracking-widest">Experience</span>
										</div>
									</div>
								{/if}
								{#if medic.country}
									<div class="flex items-center gap-1.5">
										<div class="h-8 w-8 rounded-full bg-gray-50 flex items-center justify-center"><MapPin class="h-4 w-4 text-gray-500" /></div>
										<div class="flex flex-col">
											<span class="text-sm font-black text-gray-900 leading-none">{medic.country}</span>
											<span class="text-[9px] text-gray-400 font-bold uppercase tracking-widest">{medic.region || 'Location'}</span>
										</div>
									</div>
								{/if}
							</div>
						</div>
					</div>

					<!-- About Section -->
					<div class="bg-white rounded-[40px] p-6 sm:p-10 border border-gray-100 shadow-sm space-y-6">
						<h2 class="text-xs font-black uppercase tracking-[0.2em] text-gray-400 flex items-center gap-2"><User class="h-4 w-4" /> About Provider</h2>
						{#if medic.bio}
							<p class="text-gray-600 font-medium leading-relaxed text-sm">
								{medic.bio}
							</p>
						{:else}
							<p class="text-gray-400 font-medium italic">No detailed biography provided.</p>
						{/if}

						{#if medic.credentials}
							<div class="pt-6 border-t border-gray-100 mt-6">
								<h3 class="text-[10px] font-black uppercase tracking-[0.2em] text-gray-400 mb-3">Qualifications & Credentials</h3>
								<div class="inline-flex items-center gap-2 px-4 py-3 bg-gray-50 rounded-2xl text-xs font-bold text-gray-700">
									<Award class="h-4 w-4 text-indigo-500" />
									{medic.credentials}
								</div>
							</div>
						{/if}
					</div>
					
					<!-- Trust Indicators -->
					<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
						<div class="bg-emerald-50/50 rounded-3xl p-6 border border-emerald-100/50 flex flex-col gap-2">
							<ShieldCheck class="h-6 w-6 text-emerald-500" />
							<p class="text-[10px] font-black uppercase tracking-widest text-emerald-700">Verified identity & degrees</p>
						</div>
						<div class="bg-blue-50/50 rounded-3xl p-6 border border-blue-100/50 flex flex-col gap-2">
							<Video class="h-6 w-6 text-blue-500" />
							<p class="text-[10px] font-black uppercase tracking-widest text-blue-700">Secure telehealth platform</p>
						</div>
					</div>
				</div>

				<!-- Right Column: Booking Widget -->
				<div class="lg:sticky lg:top-32 space-y-6">
					<div class="bg-white rounded-[40px] p-6 border border-gray-100 shadow-2xl shadow-indigo-100/30">
						<div class="mb-6 space-y-1">
							<h3 class="text-xl font-black text-gray-900 tracking-tight">Book Consultation</h3>
							<p class="text-xs text-gray-500 font-medium">Select your requirements below to schedule an appointment.</p>
						</div>

						<form on:submit|preventDefault={bookConsultation} class="space-y-5">
							
							<!-- Consultation Type -->
							<div class="space-y-2">
								<label for="consult_type" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest">Consultation Type</label>
								<div class="relative">
									<select 
										id="consult_type" 
										bind:value={consultationType}
										class="w-full appearance-none bg-gray-50 border border-gray-100 text-gray-900 text-sm font-bold rounded-2xl px-4 py-3.5 outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all cursor-pointer"
									>
										{#each consultationTypes as type}
											<option value={type.value}>{type.label}</option>
										{/each}
									</select>
									<div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-gray-500">
										<svg class="fill-current h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><path d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z"/></svg>
									</div>
								</div>
							</div>

							<!-- Dynamic Info Box based on Selection -->
							{#if selectedConsultation}
								<div class="bg-indigo-50/50 p-4 rounded-2xl border border-indigo-100 flex justify-between items-center">
									<div class="flex flex-col">
										<span class="text-[10px] text-indigo-400 font-black uppercase tracking-widest">Duration</span>
										<span class="text-sm font-bold text-indigo-900 flex items-center gap-1"><Clock class="h-3 w-3" /> {selectedConsultation.duration}</span>
									</div>
									<div class="flex flex-col text-right">
										<span class="text-[10px] text-indigo-400 font-black uppercase tracking-widest">Fee</span>
										<span class="text-lg font-black text-indigo-900">{selectedConsultation.price}</span>
									</div>
								</div>
							{/if}

							<!-- Date & Time (Mocked for UI purposes) -->
							<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
								<div class="space-y-2">
									<label for="date" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest">Date</label>
									<input type="date" id="date" bind:value={preferredDate} class="w-full bg-gray-50 border border-gray-100 text-gray-900 text-sm font-bold rounded-2xl px-4 py-3.5 outline-none focus:ring-2 focus:ring-indigo-500 transition-all cursor-pointer" />
								</div>
								<div class="space-y-2">
									<label for="time" class="block text-[10px] font-black text-gray-400 uppercase tracking-widest">Time</label>
									<input type="time" id="time" bind:value={preferredTime} class="w-full bg-gray-50 border border-gray-100 text-gray-900 text-sm font-bold rounded-2xl px-4 py-3.5 outline-none focus:ring-2 focus:ring-indigo-500 transition-all cursor-pointer" />
								</div>
							</div>

							<button 
								type="submit" 
								disabled={isBooking}
								class="w-full h-14 mt-6 text-white font-black text-xs uppercase tracking-[0.15em] rounded-2xl shadow-xl hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-2"
								style="background: {brandColor};"
							>
								{#if isBooking}
									<div class="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
									Processing...
								{:else}
									<Calendar class="h-4 w-4" /> Schedule Visit
								{/if}
							</button>
						</form>
						
						<p class="text-center text-[9px] text-gray-400 font-bold uppercase tracking-widest mt-6 bg-gray-50 py-2 rounded-xl">
							Instant confirmation
						</p>
					</div>
				</div>
				
			</div>
		{/if}
	</div>
</div>

<style>
	:global(body) { font-family: 'Outfit', 'Inter', sans-serif; }
</style>
