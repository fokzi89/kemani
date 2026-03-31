<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { supabase } from '$lib/supabase';
	import { 
		ArrowLeft, ShieldCheck, Mail, MapPin, 
		Briefcase, GraduationCap, Calendar, Clock,
		UserCircle, MessageSquare, CheckCircle2, ChevronRight, X,
		Activity, Building, Edit, ToggleLeft, ToggleRight
	} from 'lucide-svelte';
	import { goto } from '$app/navigation';

	const providerId = $derived(page.params.id);
	let provider = $state<any>(null);
	let loading = $state(true);
	let bookingOpen = $state(false);
	let bookingDate = $state('');
	let customerName = $state('');
	let notes = $state('');
	let isBooking = $state(false);
	let bookingSuccess = $state(false);
	let consultType = $state<'chat' | 'audio' | 'video' | 'office' | null>(null);
	let selectedSlot = $state<string | null>(null);

	const dummyMedics = [
		{ id: '1', full_name: 'Dr. Johnathan Walker', type: 'Dermatologist', specialization: 'Medical Aesthetics', email: 'j.walker@medical.com', region: 'Lagos', country: 'NG', total_consultations: 1250, is_active: true, is_verified: true, bio: 'Expert in dermatological procedures and aesthetic medicine with over 10 years of experience.', exp: '10+ Years', grad: 'University of Lagos' },
		{ id: '2', full_name: 'Dr. Sarah Adewale', type: 'Pediatrician', specialization: 'Child Health', email: 's.adewale@healthcare.org', region: 'Abuja', country: 'NG', total_consultations: 850, is_active: true, is_verified: true, bio: 'Focused on comprehensive neonatal care and developmental pediatrics.', exp: '8 Years', grad: 'Ibadan Medical College' },
		{ id: '3', full_name: 'Dr. Robert Chen', type: 'Optometrist', specialization: 'Corneal specialist', email: 'r.chen@eyeclinic.com', region: 'Kano', country: 'NG', total_consultations: 2100, is_active: false, is_verified: true, bio: 'Specialist in cornea-related conditions and advanced corrective surgeries.', exp: '15 Years', grad: 'International School of Optometry' },
		{ id: '4', full_name: 'Dr. Fatima Ibrahim', type: 'Generalist', specialization: 'Family Medicine', email: 'f.ibrahim@healthhub.ng', region: 'Port Harcourt', country: 'NG', total_consultations: 430, is_active: true, is_verified: false, bio: 'Dedicated family physician providing holistic care for all age groups.', exp: '5 Years', grad: 'Ahmadu Bello University' },
	];

	const consultTypes = [
		{ id: 'chat', label: 'Messaging', icon: MessageSquare, fee: 5000, desc: 'Secure text-based session' },
		{ id: 'audio', label: 'Audio Call', icon: Clock, fee: 8500, desc: 'High-quality voice call' },
		{ id: 'video', label: 'Video Meeting', icon: Activity, fee: 15000, desc: 'Face-to-face virtual consultation' },
		{ id: 'office', label: 'In-Office', icon: Building, fee: 25000, desc: 'Physical visit to clinic' },
	];

	const next7Days = Array.from({ length: 7 }, (_, i) => {
		const d = new Date();
		d.setDate(d.getDate() + i);
		return d;
	});

	const timeSlots = ['09:00 AM', '10:30 AM', '11:00 AM', '01:30 PM', '02:00 PM', '04:30 PM'];

	onMount(async () => {
		try {
			const { data, error } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('id', providerId)
				.single();
			
			if (data) {
				provider = data;
			} else {
				provider = dummyMedics.find(m => m.id === providerId);
			}
		} catch (e) {
			provider = dummyMedics.find(m => m.id === providerId);
		} finally {
			loading = false;
		}
	});

	async function handleBooking() {
		if (!customerName || !bookingDate || !consultType || !selectedSlot) return;
		isBooking = true;
		setTimeout(() => {
			isBooking = false;
			bookingSuccess = true;
			setTimeout(() => {
				bookingOpen = false;
				bookingSuccess = false;
				consultType = null;
				selectedSlot = null;
			}, 2000);
		}, 1500);
	}
</script>

<svelte:head><title>{provider?.full_name || 'Provider'} – Kemani POS</title></svelte:head>

<div class="p-6 max-w-4xl mx-auto space-y-5">
	<!-- Header Consistent with Product Detail -->
	<div class="flex items-center justify-between">
		<div class="flex items-center gap-3">
			<button onclick={() => history.back()} class="p-2 hover:bg-gray-100 rounded-lg">
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</button>
			<h1 class="text-xl font-bold text-gray-900">{provider?.full_name || 'Provider Detail'}</h1>
		</div>
	</div>

	{#if loading}
		<div class="p-12 text-center">
			<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div>
		</div>
	{:else if provider}
		<div class="grid grid-cols-1 md:grid-cols-3 gap-5">
			<!-- Left Column: Main Identity & Bio -->
			<div class="md:col-span-2 space-y-4">
				<div class="bg-white rounded-xl border p-5">
					<div class="flex items-start gap-4">
						<div class="w-20 h-20 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-xl flex items-center justify-center flex-shrink-0 relative overflow-hidden">
							{#if provider.profile_photo_url}
								<img src={provider.profile_photo_url} alt={provider.full_name} class="h-full w-full object-cover" />
							{:else}
								<p class="text-indigo-400 font-black text-2xl">{provider.full_name?.charAt(0)}</p>
							{/if}
						</div>
						<div class="flex-1 min-w-0">
							<div class="flex items-center gap-2">
								<h2 class="text-xl font-bold text-gray-900 truncate">{provider.full_name}</h2>
								{#if provider.is_verified}
									<ShieldCheck class="h-4 w-4 text-blue-500 flex-shrink-0" />
								{/if}
							</div>
							<p class="text-xs font-bold text-indigo-600 uppercase tracking-widest mt-1">
								{provider.type} &bull; {provider.specialization}
							</p>
							<div class="flex flex-wrap gap-2 mt-3">
								<span class="px-2.5 py-1 bg-gray-100 text-gray-600 text-[10px] font-bold rounded-full flex items-center gap-1">
									<Mail class="h-3 w-3" /> {provider.email}
								</span>
								<span class="px-2.5 py-1 bg-gray-100 text-gray-600 text-[10px] font-bold rounded-full flex items-center gap-1">
									<MapPin class="h-3 w-3" /> {provider.region}, {provider.country}
								</span>
							</div>
						</div>
					</div>
				</div>

				<!-- Bio & Academic -->
				<div class="bg-white rounded-xl border p-5 space-y-6">
					<div class="space-y-3">
						<h3 class="font-bold text-gray-900 text-sm flex items-center gap-2">
							<UserCircle class="h-4 w-4 text-indigo-600" /> Professional Bio
						</h3>
						<p class="text-gray-600 text-sm leading-relaxed whitespace-pre-wrap">{provider.bio || 'Professional medical practitioner dedicated to providing excellent healthcare services.'}</p>
					</div>

					<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-gray-50">
						<div class="flex items-center gap-3">
							<div class="p-2 bg-gray-50 rounded-lg"><Briefcase class="h-4 w-4 text-gray-400" /></div>
							<div>
								<p class="text-[9px] font-bold text-gray-400 uppercase tracking-widest">Experience</p>
								<p class="text-sm font-bold text-gray-900">{provider.exp || '5+ Years'}</p>
							</div>
						</div>
						<div class="flex items-center gap-3">
							<div class="p-2 bg-gray-50 rounded-lg"><GraduationCap class="h-4 w-4 text-gray-400" /></div>
							<div>
								<p class="text-[9px] font-bold text-gray-400 uppercase tracking-widest">Institution</p>
								<p class="text-sm font-bold text-gray-900 truncate">{provider.grad || 'Medical University'}</p>
							</div>
						</div>
					</div>
				</div>

				<!-- Secondary Action / Booking CTA -->
				<button 
					onclick={() => bookingOpen = true}
					class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-black py-4 rounded-xl shadow-lg transition-all active:scale-[0.98] flex items-center justify-center gap-3 text-sm"
				>
					<Calendar class="h-5 w-5" /> Reserve Consultation Slot
				</button>
			</div>

			<!-- Right Column: Quick Stats -->
			<div class="space-y-4">
				<div class="bg-white rounded-xl border p-5 space-y-4">
					<h3 class="font-semibold text-gray-900 text-xs uppercase tracking-wider text-gray-500">Partner Metrics</h3>
					<div class="space-y-3 text-sm">
						<div class="flex justify-between items-center pb-2 border-b border-gray-50 last:border-0 border-dashed">
							<span class="text-gray-500">Total Consultations</span>
							<span class="font-black text-gray-900">{provider.total_consultations.toLocaleString()}</span>
						</div>
						<div class="flex justify-between items-center pb-2 border-b border-gray-50 last:border-0 border-dashed">
							<span class="text-gray-500">Starting Fee</span>
							<span class="font-black text-indigo-600">₦5,000.00</span>
						</div>
						<div class="flex justify-between items-center pb-2 border-b border-gray-50 last:border-0 border-dashed">
							<span class="text-gray-500">Response Time</span>
							<span class="font-black text-gray-900">&lt; 2 Hours</span>
						</div>
						<div class="flex justify-between items-center pb-2 border-b border-gray-50 last:border-0 border-dashed">
							<span class="text-gray-500">Languages</span>
							<span class="font-black text-gray-900">EN, NG</span>
						</div>
					</div>
				</div>
			</div>
		</div>
	{:else}
		<div class="py-20 text-center">
			<p class="text-gray-500 font-bold">Provider not found.</p>
			<button onclick={() => history.back()} class="mt-4 text-indigo-600 font-bold">Return to List</button>
		</div>
	{/if}
</div>

<!-- ── Booking Drawer (Restored from previous step) ──────────────────────────────── -->
{#if bookingOpen}
	<div class="fixed inset-0 z-[100] flex items-center justify-end bg-gray-900/60 backdrop-blur-sm animate-in fade-in duration-200">
		<div class="fixed inset-0" onclick={() => bookingOpen = false}></div>
		<div class="relative w-full max-w-xl bg-white h-full shadow-2xl flex flex-col p-8 animate-in slide-in-from-right duration-300">
			<!-- Drawer header and steps same as previous -->
			<div class="flex items-center justify-between mb-8">
				<div>
					<h2 class="text-2xl font-black text-gray-900 flex items-center gap-3">
						<Calendar class="h-6 w-6 text-indigo-600" /> Reserve Session
					</h2>
					<p class="text-xs text-gray-400 font-bold uppercase tracking-widest mt-1">for {provider.full_name}</p>
				</div>
				<button onclick={() => bookingOpen = false} class="p-2 hover:bg-gray-100 rounded-xl transition-all"><X class="h-6 w-6 text-gray-400" /></button>
			</div>

			{#if bookingSuccess}
				<div class="flex-1 flex flex-col items-center justify-center text-center space-y-4 animate-in zoom-in-95">
					<div class="h-20 w-20 bg-green-50 rounded-full flex items-center justify-center"><CheckCircle2 class="h-10 w-10 text-green-600" /></div>
					<h3 class="text-xl font-bold text-gray-900">Session Confirmed!</h3>
					<p class="text-gray-500 max-w-xs">Added to the provider's calendar for {customerName}.</p>
				</div>
			{:else}
				<div class="flex-1 space-y-8 overflow-y-auto pr-4 scrollbar-hide">
					<!-- Booking form same as previous for feature consistency -->
					<div class="space-y-4">
						<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">Patient Details</p>
						<input type="text" bind:value={customerName} placeholder="Enter Customer/Patient Name" class="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-indigo-500 font-bold text-sm outline-none" />
					</div>
					<div class="space-y-4">
						<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">Consultation Type</p>
						<div class="grid grid-cols-2 gap-3">
							{#each consultTypes as type}
								{@const Icon = type.icon}
								<button onclick={() => consultType = type.id as any} class="flex flex-col p-4 rounded-xl border text-left transition-all {consultType === type.id ? 'border-indigo-600 bg-indigo-50/50 ring-1 ring-indigo-600 shadow-sm' : 'border-gray-100 hover:bg-gray-50'}">
									<Icon class="h-5 w-5 {consultType === type.id ? 'text-indigo-600' : 'text-gray-400'} mb-2" />
									<p class="text-xs font-bold {consultType === type.id ? 'text-indigo-900' : 'text-gray-700'}">{type.label}</p>
									<p class="text-[10px] font-bold text-indigo-600 mt-1">₦{type.fee.toLocaleString()}</p>
								</button>
							{/each}
						</div>
					</div>
					{#if consultType}
						<div class="space-y-6 animate-in fade-in slide-in-from-top-2">
							<div class="space-y-4">
								<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">Working Calendar</p>
								<div class="flex gap-2 overflow-x-auto pb-2 -mx-2 px-2 scroll-smooth">
									{#each next7Days as date}
										{@const dateStr = date.toISOString().split('T')[0]}
										<button onclick={() => bookingDate = dateStr} class="flex-shrink-0 flex flex-col items-center justify-center w-20 py-3 rounded-xl border-2 transition-all {bookingDate === dateStr ? 'bg-indigo-600 border-indigo-600 text-white shadow-lg' : 'bg-white border-gray-100 text-gray-600 hover:border-indigo-50'}">
											<span class="text-[10px] font-bold uppercase opacity-80">{date.toLocaleDateString('en', { weekday: 'short' })}</span>
											<span class="text-xl font-black">{date.getDate()}</span>
										</button>
									{/each}
								</div>
							</div>
							{#if bookingDate}
								<div class="space-y-4 animate-in fade-in zoom-in-95">
									<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">Available Slots</p>
									<div class="grid grid-cols-3 gap-2">
										{#each timeSlots as slot}
											<button onclick={() => selectedSlot = slot} class="py-2.5 rounded-lg border text-xs font-bold transition-all {selectedSlot === slot ? 'bg-indigo-600 border-indigo-600 text-white shadow-md' : 'bg-gray-50 border-transparent text-gray-600 hover:bg-gray-100'}">{slot}</button>
										{/each}
									</div>
								</div>
							{/if}
						</div>
					{/if}
				</div>
				<div class="pt-6 border-t mt-auto">
					<button onclick={handleBooking} disabled={!customerName || !bookingDate || !consultType || !selectedSlot || isBooking} class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-black py-4 rounded-xl shadow-xl transition-all active:scale-95 flex items-center justify-center gap-3 disabled:opacity-50">
						{#if isBooking}<div class="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>Finalizing...{:else}Complete Reservation {consultType ? `• ₦${consultTypes.find(t => t.id === consultType)?.fee.toLocaleString()}` : ''}{/if}
					</button>
				</div>
			{/if}
		</div>
	</div>
{/if}
