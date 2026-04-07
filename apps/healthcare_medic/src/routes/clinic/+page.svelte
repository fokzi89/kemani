<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Search, Building, User, Check, X, Plus, Stethoscope, Award, Clock, UserPlus, Mail, MapPin, AlertCircle, Phone } from 'lucide-svelte';

	let provider = $state<any>(null);
	let currentUserId = $state<string>('');
	let loading = $state(true);
	let saving = $state(false);

	// Clinic details
	let clinicName = $state('');
	let clinicNameOriginal = $state('');

	// Partner list
	let partners = $state<any[]>([]);
	let existingPartnerIds = $state<Set<string>>(new Set());
	let showAddDoctorModal = $state(false);

	// Doctor search and filter (for modal)
	let searchQuery = $state('');
	let specialtyFilter = $state('');
	let allDoctors = $state<any[]>([]);
	let filteredDoctors = $state<any[]>([]);
	let selectedDoctors = $state<any[]>([]);

	// Specialties list
	const specialties = [
		'General Practice',
		'Cardiology',
		'Dermatology',
		'Neurology',
		'Orthopedics',
		'Pediatrics',
		'Gynecology',
		'Urology',
		'Ophthalmology',
		'ENT',
		'Psychiatry',
		'Internal Medicine',
		'Family Medicine',
		'Emergency Medicine',
		'Anesthesiology'
	];

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) {
			window.location.href = '/auth/login';
			return;
		}
		currentUserId = session.user.id;

		// Get current provider
		const { data: providerData } = await supabase
			.from('healthcare_providers')
			.select('*')
			.eq('user_id', session.user.id)
			.single();

		provider = providerData;

		if (provider) {
			// Database column name is clinic_name (underscored)
			const clinicNameValue = provider.clinic_name || provider.full_name;
			clinicName = clinicNameValue;
			clinicNameOriginal = clinicNameValue;

			// Load existing partners
			await loadExistingPartners(provider.id);

			// Load all doctors except current
			await loadAllDoctors(provider.id);
		}

		loading = false;
	});

	async function loadExistingPartners(providerId: string) {
		const { data: partnersData } = await supabase
			.from('doctor_aliases')
			.select(`
				id,
				doctor_id,
				alias,
				accepted,
				clinic_name,
				healthcare_providers:doctor_id (
					full_name,
					email,
					phone,
					specialization,
					clinic_address,
					region,
					strike
				)
			`)
			.eq('primary_doctor_id', providerId)
			.eq('is_active', true);

		if (partnersData) {
			partners = partnersData.map(p => {
				const hp = Array.isArray(p.healthcare_providers) ? p.healthcare_providers[0] : p.healthcare_providers;
				return {
					id: p.id,
					doctor_id: p.doctor_id,
					full_name: hp?.full_name || 'Unknown',
					email: hp?.email || 'N/A',
					phone: hp?.phone || 'N/A',
					specialization: hp?.specialization || 'N/A',
					city: hp?.clinic_address?.city || hp?.region || 'N/A',
					strike: hp?.strike || 0
				};
			});
			existingPartnerIds = new Set(partnersData.map(p => p.doctor_id));
		}
	}

	async function loadAllDoctors(excludeProviderId: string) {
		const { data: doctors } = await supabase
			.from('healthcare_providers')
			.select('id, full_name, specialization, sub_specialty, years_of_experience, average_rating, profile_photo_url, is_verified, strike, clinic_address, region')
			.neq('user_id', currentUserId)
			.eq('is_active', true)
			.eq('type', 'doctor')
			.eq('accept_invite', true)
			.order('full_name');

		allDoctors = doctors || [];
		filteredDoctors = allDoctors.filter(d => !existingPartnerIds.has(d.id));
	}

	function filterDoctors() {
		let filtered = allDoctors.filter(d => !existingPartnerIds.has(d.id));

		if (searchQuery) {
			const query = searchQuery.toLowerCase();
			filtered = filtered.filter(d => 
				d.full_name?.toLowerCase().includes(query) ||
				d.specialization?.toLowerCase().includes(query) ||
				d.sub_specialty?.toLowerCase().includes(query)
			);
		}

		if (specialtyFilter) {
			filtered = filtered.filter(d => d.specialization === specialtyFilter);
		}

		filteredDoctors = filtered;
	}

	function toggleDoctor(doctor: any) {
		const index = selectedDoctors.findIndex(d => d.id === doctor.id);
		if (index >= 0) {
			selectedDoctors = selectedDoctors.filter(d => d.id !== doctor.id);
		} else {
			selectedDoctors = [...selectedDoctors, doctor];
		}
	}

	function isSelected(doctorId: string): boolean {
		return selectedDoctors.some(d => d.id === doctorId);
	}

	function slugify(text: string) {
		return text
			.toLowerCase()
			.trim()
			.replace(/[^\w\s-]/g, '')
			.replace(/[\s_-]+/g, '-')
			.replace(/^-+|-+$/g, '');
	}

	async function saveClinicName() {
		if (!provider || !clinicName.trim()) return;

		saving = true;
		try {
			const finalClinicName = clinicName.trim();
			const newSlug = slugify(finalClinicName);

			const { error } = await supabase
				.from('healthcare_providers')
				.update({ 
					clinic_name: finalClinicName,
					slug: newSlug
				})
				.eq('id', provider.id);

			if (error) throw error;
			clinicNameOriginal = finalClinicName;
			provider.slug = newSlug;
			alert('Clinic name and slug updated!');
		} catch (err: any) {
			alert('Error saving: ' + err.message);
		} finally {
			saving = false;
		}
	}

	async function addPartnerDoctors() {
		if (!provider || selectedDoctors.length === 0) return;

		saving = true;
		try {
			const aliasesData = selectedDoctors.map(doctor => {
				const firstName = doctor.full_name.split(' ')[0];
				const lastInitial = doctor.full_name.split(' ')[1]?.charAt(0) || '';
				return {
					doctor_id: doctor.id,
					primary_doctor_id: provider.id,
					alias: `${firstName} ${lastInitial}. (${clinicNameOriginal || provider.full_name})`,
					is_active: true,
					accepted: false,
					clinic_name: clinicNameOriginal || provider.full_name
				};
			});

			const { error } = await supabase
				.from('doctor_aliases')
				.upsert(aliasesData, { onConflict: 'doctor_id,primary_doctor_id,is_active' });

			if (error) throw error;

			// Update local state
			selectedDoctors.forEach(d => existingPartnerIds.add(d.id));
			existingPartnerIds = new Set(existingPartnerIds);
			selectedDoctors = [];
			
			// Reload partners
			await loadExistingPartners(provider.id);
			
			// Reload filter
			filterDoctors();
			showAddDoctorModal = false;

			alert(`Invited ${aliasesData.length} doctor(s) successfully!`);
		} catch (err: any) {
			alert('Error adding partners: ' + err.message);
		} finally {
			saving = false;
		}
	}
</script>

<div class="min-h-screen p-6 lg:p-8 bg-gray-50/50">
	<div class="max-w-6xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
			<div class="flex items-center justify-between">
				<div class="flex items-center gap-3">
					<div class="p-2.5 bg-black rounded-xl">
						<Building class="h-6 w-6 text-white" />
					</div>
					<div>
						<h1 class="text-2xl font-bold text-gray-900">Clinic</h1>
						<p class="text-gray-600">Manage your clinic and partner doctors</p>
					</div>
				</div>
				<button
					onclick={() => showAddDoctorModal = true}
					class="px-6 py-2.5 bg-black text-white font-bold rounded-[10px] hover:bg-gray-900 flex items-center gap-2 shadow-lg active:scale-95 transition-all"
				>
					<Plus class="h-5 w-5" />
					Add Doctor
				</button>
			</div>
		</div>

		{#if loading}
			<div class="bg-white rounded-2xl border border-gray-100 p-12 text-center shadow-sm">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-black mx-auto"></div>
				<p class="mt-4 text-gray-600 font-medium tracking-tight">Loading clinic data...</p>
			</div>
		{:else}
			<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
				<!-- Clinic Info Column -->
				<div class="lg:col-span-1 space-y-6">
					<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
						<h2 class="text-lg font-bold text-gray-900 mb-4 tracking-tight">Clinic Information</h2>
						
						<div class="space-y-4">
							<div>
								<label for="clinic-name" class="block text-sm font-semibold text-gray-700 mb-2">
									Clinic Name
								</label>
								<input
									type="text"
									id="clinic-name"
									bind:value={clinicName}
									placeholder="Enter clinic name"
									class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 focus:border-black transition-all"
								/>
							</div>
							<button
								onclick={saveClinicName}
								disabled={saving || clinicName === clinicNameOriginal}
								class="w-full px-4 py-2.5 bg-black text-white font-bold rounded-[10px] hover:bg-gray-900 disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-[0.98]"
							>
								{saving ? 'Saving...' : 'Update Clinic Info'}
							</button>
							<div class="p-3 bg-amber-50 rounded-xl border border-amber-100">
								<p class="text-[11px] text-amber-800 leading-relaxed font-medium">
									Updating the name also updates your profile slug, which may change your public profile URL.
								</p>
							</div>
						</div>
					</div>
				</div>

				<!-- Partner Doctors Table Column -->
				<div class="lg:col-span-2">
					<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
						<div class="p-6 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10">
							<h2 class="text-lg font-bold text-gray-900 tracking-tight">Partner Doctors</h2>
							<span class="px-3 py-1 bg-gray-100 text-gray-900 text-[10px] uppercase tracking-widest rounded-full font-black">
								{partners.length} Total
							</span>
						</div>
						
						{#if partners.length === 0}
							<div class="p-16 text-center">
								<div class="h-20 w-20 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4 border border-gray-100">
									<User class="h-10 w-10 text-gray-300" />
								</div>
								<h3 class="text-gray-900 font-bold text-lg tracking-tight">No partner doctor</h3>
								<p class="text-gray-500 text-sm mt-1 max-w-xs mx-auto">Start by adding doctors from the global medical community to your clinic.</p>
								<button
									onclick={() => showAddDoctorModal = true}
									class="mt-6 px-8 py-2.5 border-2 border-black text-black font-bold rounded-[10px] hover:bg-black hover:text-white transition-all active:scale-95"
								>
									Add Doctor
								</button>
							</div>
						{:else}
							<div class="overflow-x-auto">
								<table class="w-full text-left border-collapse">
									<thead class="bg-gray-50/50 text-gray-500 text-[10px] uppercase tracking-widest border-b border-gray-100">
										<tr>
											<th class="px-6 py-4 font-black">Doctor</th>
											<th class="px-6 py-4 font-black text-center">Strikes</th>
											<th class="px-6 py-4 font-black text-right">Action</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-gray-100">
										{#each partners as partner}
											<tr class="hover:bg-gray-50/50 transition-colors group">
												<td class="px-6 py-4">
													<div class="flex flex-col">
														<p class="font-bold text-gray-900 group-hover:text-black transition-colors">{partner.full_name}</p>
														<p class="text-[11px] text-gray-500 font-medium uppercase tracking-tight">{partner.specialization} • {partner.city}</p>
														<div class="flex items-center gap-4 mt-1.5 opacity-60">
															<span class="text-[11px] text-gray-600 flex items-center gap-1 font-medium whitespace-nowrap">
																<Mail class="h-3 w-3" />
																{partner.email}
															</span>
															<span class="text-[11px] text-gray-600 flex items-center gap-1 font-medium whitespace-nowrap">
																<Phone class="h-3 w-3" />
																{partner.phone}
															</span>
														</div>
													</div>
												</td>
												<td class="px-6 py-4 text-center">
													{#if partner.strike > 0}
														<span class="inline-flex items-center gap-1.5 px-3 py-1 bg-red-50 text-red-700 text-xs rounded-full font-black border border-red-100">
															<AlertCircle class="h-3 w-3" />
															{partner.strike}
														</span>
													{:else}
														<span class="text-gray-300 text-xs font-bold">0</span>
													{/if}
												</td>
												<td class="px-6 py-4 text-right">
													<a 
														href="/clinic/partners/{partner.doctor_id}"
														class="inline-flex items-center gap-2 px-4 py-2 border border-gray-200 text-gray-700 font-bold text-xs rounded-xl hover:border-black hover:bg-black hover:text-white transition-all shadow-sm active:scale-[0.97]"
													>
														View Details
													</a>
												</td>
											</tr>
										{/each}
									</tbody>
								</table>
							</div>
						{/if}
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>

<!-- Add Doctor Modal (outside z-index context) -->
{#if showAddDoctorModal}
	<div class="fixed inset-0 z-[100] flex items-center justify-center p-4">
		<div class="absolute inset-0 bg-black/60 backdrop-blur-sm" role="button" tabindex="0" onclick={() => showAddDoctorModal = false} onkeydown={(e) => e.key === 'Enter' && (showAddDoctorModal = false)}></div>
		<div class="bg-white rounded-[2rem] shadow-2xl w-full max-w-2xl z-10 overflow-hidden flex flex-col max-h-[85vh] border border-white/20 animate-in fade-in zoom-in-95 duration-200">
			<div class="p-8 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10">
				<div>
					<h2 class="text-2xl font-black text-gray-900 tracking-tight">Invite Doctors</h2>
					<p class="text-sm text-gray-500 font-medium">Build your clinic's specialized medical team</p>
				</div>
				<button onclick={() => showAddDoctorModal = false} class="p-2.5 hover:bg-gray-100 rounded-full transition-colors active:scale-90">
					<X class="h-6 w-6 text-gray-400" />
				</button>
			</div>

			<div class="p-6 flex-1 overflow-y-auto space-y-6">
				<!-- Search and Filter -->
				<div class="flex flex-col sm:flex-row gap-2">
					<div class="flex-grow relative">
						<Search class="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
						<input
							type="text"
							bind:value={searchQuery}
							oninput={filterDoctors}
							placeholder="Search by name, specialty or city..."
							class="w-full pl-12 pr-4 py-3.5 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-black/5 focus:border-black outline-none transition-all font-bold text-sm bg-gray-50/50"
						/>
					</div>
					<select
						bind:value={specialtyFilter}
						onchange={filterDoctors}
						class="w-full sm:w-48 px-4 py-3.5 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-black/5 focus:border-black outline-none transition-all font-black text-sm bg-white"
					>
						<option value="">All Specialties</option>
						{#each specialties as specialty}
							<option value={specialty}>{specialty}</option>
						{/each}
					</select>
				</div>

				<!-- Available Doctors Grid -->
				<div class="grid grid-cols-1 gap-3 pb-4">
					{#if filteredDoctors.length === 0}
						<div class="text-center py-20 bg-gray-50/50 rounded-3xl border border-dashed border-gray-200">
							<div class="h-20 w-20 bg-white rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-sm">
								<Search class="h-10 w-10 text-gray-200" />
							</div>
							<p class="text-gray-500 font-black tracking-tight">No available doctors found</p>
						</div>
					{:else}
						{#each filteredDoctors as doctor}
							{@const selected = isSelected(doctor.id)}
							<div 
								class="flex items-center gap-4 p-4 rounded-2xl border transition-all cursor-pointer group {selected ? 'bg-gray-50 border-black shadow-sm ring-2 ring-black/5' : 'bg-white border-gray-100 hover:border-black/20 hover:bg-gray-50/50 shadow-sm'}"
								role="button"
								tabindex="0"
								onclick={() => toggleDoctor(doctor)}
								onkeydown={(e) => e.key === 'Enter' && toggleDoctor(doctor)}
							>
								<div class="relative flex-shrink-0">
									<input
										type="checkbox"
										checked={selected}
										onclick={(e) => { e.stopPropagation(); toggleDoctor(doctor); }}
										class="h-5 w-5 text-black border-gray-300 rounded focus:ring-black cursor-pointer"
									/>
								</div>
								
								{#if doctor.profile_photo_url}
									<img src={doctor.profile_photo_url} alt="" class="h-12 w-12 rounded-2xl object-cover" />
								{:else}
									<div class="h-12 w-12 rounded-2xl bg-gray-100 flex items-center justify-center group-hover:bg-gray-200 transition-colors">
										<User class="h-6 w-6 text-gray-400" />
									</div>
								{/if}
								
								<div class="flex-1 min-w-0">
									<p class="font-bold text-sm text-gray-900 truncate tracking-tight">{doctor.full_name}</p>
									<p class="text-[10px] sm:text-xs font-bold uppercase tracking-widest text-gray-400">{doctor.specialization}</p>
									<div class="flex items-center gap-3 mt-1.5 font-bold">
										<span class="flex items-center gap-1 text-[11px] text-gray-500">
											<MapPin class="h-3 w-3" />
											{doctor.clinic_address?.city || doctor.region || 'Unknown'}
										</span>
										{#if doctor.strike > 0}
											<span class="flex items-center gap-1 text-[11px] text-red-600 font-black">
												<AlertCircle class="h-3 w-3" />
												{doctor.strike} STRIKES
											</span>
										{/if}
									</div>
								</div>
							</div>
						{/each}
					{/if}
				</div>
			</div>

			<!-- Footer Action -->
			{#if selectedDoctors.length > 0}
				<div class="p-8 border-t border-gray-100 bg-white flex items-center justify-between sticky bottom-0 z-10 shadow-[0_-4px_20px_rgba(0,0,0,0.03)]">
					<div class="flex flex-col">
						<span class="text-base font-black text-gray-900 tracking-tight">{selectedDoctors.length} Doctors Selected</span>
						<p class="text-[10px] text-gray-500 font-bold uppercase tracking-wider">Direct invitations will be sent</p>
					</div>
					<button
						onclick={addPartnerDoctors}
						disabled={saving}
						class="px-10 py-4 bg-black text-white font-black text-sm rounded-2xl hover:bg-gray-900 disabled:opacity-50 shadow-2xl shadow-black/20 active:scale-95 transition-all flex items-center gap-2"
					>
						<UserPlus class="h-5 w-5" />
						{saving ? 'Inviting...' : 'Send Invitations'}
					</button>
				</div>
			{/if}
		</div>
	</div>
{/if}