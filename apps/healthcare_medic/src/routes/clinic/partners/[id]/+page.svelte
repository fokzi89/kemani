<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { 
		ArrowLeft, 
		User, 
		Mail, 
		Phone, 
		MapPin, 
		Stethoscope, 
		AlertTriangle, 
		Trash2, 
		ShieldAlert, 
		CheckCircle, 
		X,
		AlertCircle,
		Clock,
		FileCheck,
		Award
	} from 'lucide-svelte';
	import { goto } from '$app/navigation';

	const doctorId = $page.params.id;
	let doctor = $state<any>(null);
	let primaryProviderId = $state<string>('');
	let loading = $state(true);
	let saving = $state(false);
	
	// Modal states
	let showStrikeModal = $state(false);
	let strikeReason = $state('');
	let showDeleteConfirm = $state(false);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) {
			goto('/auth/login');
			return;
		}

		// Get current primary doctor
		const { data: providerData } = await supabase
			.from('healthcare_providers')
			.select('id')
			.eq('user_id', session.user.id)
			.single();
		
		if (providerData) primaryProviderId = providerData.id;

		// Fetch partner doctor details
		const { data: doctorData } = await supabase
			.from('healthcare_providers')
			.select('id, full_name, email, phone, specialization, sub_specialty, clinic_address, region, strike, is_verified, profile_photo_url, bio, credentials, years_of_experience')
			.eq('id', doctorId)
			.single();

		doctor = doctorData;
		loading = false;
	});

	async function addStrike() {
		if (!strikeReason.trim() || !primaryProviderId) return;

		saving = true;
		try {
			// Increment strike count
			const { error: updateError } = await supabase
				.from('healthcare_providers')
				.update({ strike: (doctor.strike || 0) + 1 } as any)
				.eq('id', doctorId);

			if (updateError) throw updateError;

			// Log the reason
			const { error: logError } = await supabase
				.from('doctor_strike_logs')
				.insert({
					doctor_id: doctorId,
					primary_doctor_id: primaryProviderId,
					reason: strikeReason.trim()
				});

			if (logError) throw logError;

			doctor.strike = (doctor.strike || 0) + 1;
			strikeReason = '';
			showStrikeModal = false;
			alert('Strike added and logged for moderation.');
		} catch (err: any) {
			alert('Error adding strike: ' + err.message);
		} finally {
			saving = false;
		}
	}

	async function deletePartner() {
		if (!primaryProviderId) return;

		saving = true;
		try {
			const { error } = await supabase
				.from('doctor_aliases')
				.delete()
				.eq('doctor_id', doctorId)
				.eq('primary_doctor_id', primaryProviderId);

			if (error) throw error;

			alert('Partner removed from clinic.');
			goto('/clinic');
		} catch (err: any) {
			alert('Error removing partner: ' + err.message);
		} finally {
			saving = false;
		}
	}
</script>

<div class="min-h-screen bg-gray-50/50 p-6">
	<div class="max-w-4xl mx-auto space-y-6">
		<button 
			onclick={() => goto('/clinic')} 
			class="flex items-center gap-2 text-gray-600 hover:text-black font-bold transition-colors mb-4 group"
		>
			<ArrowLeft class="h-4 w-4 group-hover:-translate-x-1 transition-transform" />
			Back to Clinic
		</button>

		{#if loading}
			<div class="bg-white rounded-3xl border border-gray-100 p-20 text-center shadow-sm">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-black mx-auto"></div>
				<p class="mt-4 text-gray-600 font-medium">Fetching doctor profile...</p>
			</div>
		{:else if !doctor}
			<div class="bg-white rounded-3xl border border-gray-100 p-20 text-center shadow-sm">
				<div class="h-20 w-20 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
					<X class="h-10 w-10 text-red-400" />
				</div>
				<h2 class="text-xl font-black text-gray-900">Doctor not found</h2>
				<p class="text-gray-500 mt-2">The doctor you are looking for does not exist or has been removed.</p>
			</div>
		{:else}
			<!-- Doctor Header Card -->
			<div class="bg-white rounded-3xl shadow-sm border border-gray-100 p-8">
				<div class="flex flex-col md:flex-row gap-8 items-start">
					<div class="h-32 w-32 bg-gray-100 rounded-3xl flex items-center justify-center flex-shrink-0 shadow-2xl overflow-hidden border-4 border-white">
						{#if doctor.profile_photo_url}
							<img src={doctor.profile_photo_url} alt={doctor.full_name} class="h-full w-full object-cover" />
						{:else}
							<User class="h-16 w-16 text-gray-300" />
						{/if}
					</div>
					<div class="flex-1 space-y-4 w-full">
						<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
							<div>
								<h1 class="text-3xl font-black text-gray-900">{doctor.full_name}</h1>
								<div class="flex items-center gap-2 mt-1">
									<span class="px-3 py-1 bg-black text-white text-[10px] uppercase font-black tracking-widest rounded-full">
										{doctor.specialization}
									</span>
									{#if doctor.sub_specialty}
										<span class="px-3 py-1 bg-gray-100 text-gray-600 text-[10px] uppercase font-black tracking-widest rounded-full">
											{doctor.sub_specialty}
										</span>
									{/if}
									{#if doctor.is_verified}
										<span class="flex items-center gap-1 text-[11px] font-bold text-green-600">
											<CheckCircle class="h-3 w-3" />
											Verified
										</span>
									{/if}
								</div>
							</div>
							<div class="flex items-center gap-3">
								<div class="text-right">
									<p class="text-xs font-bold text-gray-400 uppercase tracking-tighter">Current Strikes</p>
									<p class="text-2xl font-black {doctor.strike > 0 ? 'text-red-600' : 'text-gray-900'}">{doctor.strike || 0}</p>
								</div>
								<button 
									onclick={() => showStrikeModal = true}
									class="p-3 bg-red-50 text-red-600 rounded-2xl hover:bg-red-600 hover:text-white transition-all shadow-sm"
									title="Add Strike"
								>
									<AlertTriangle class="h-6 w-6" />
								</button>
							</div>
						</div>

						<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 pt-4 border-t border-gray-50">
							<div class="flex items-start gap-3">
								<div class="p-2 bg-gray-50 rounded-xl">
									<Mail class="h-4 w-4 text-gray-400" />
								</div>
								<div>
									<p class="text-[10px] font-bold text-gray-400 uppercase">Email</p>
									<p class="text-sm font-bold text-gray-800 truncate max-w-[120px]">{doctor.email}</p>
								</div>
							</div>
							<div class="flex items-start gap-3">
								<div class="p-2 bg-gray-50 rounded-xl">
									<Phone class="h-4 w-4 text-gray-400" />
								</div>
								<div>
									<p class="text-[10px] font-bold text-gray-400 uppercase">Phone</p>
									<p class="text-sm font-bold text-gray-800">{doctor.phone}</p>
								</div>
							</div>
							<div class="flex items-start gap-3">
								<div class="p-2 bg-gray-50 rounded-xl">
									<Clock class="h-4 w-4 text-gray-400" />
								</div>
								<div>
									<p class="text-[10px] font-bold text-gray-400 uppercase">Experience</p>
									<p class="text-sm font-bold text-gray-800">{doctor.years_of_experience || 0} Years</p>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- More Info Section -->
			<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
				<!-- Professional Bio -->
				<div class="bg-white rounded-3xl shadow-sm border border-gray-100 p-8">
					<h3 class="text-sm font-black text-gray-900 uppercase tracking-widest mb-4 flex items-center gap-2">
						<FileCheck class="h-4 w-4 text-gray-400" />
						Professional Bio
					</h3>
					<p class="text-gray-600 text-sm leading-relaxed whitespace-pre-line">
						{doctor.bio || 'No bio available for this provider.'}
					</p>
				</div>

				<!-- Qualifications -->
				<div class="bg-white rounded-3xl shadow-sm border border-gray-100 p-8">
					<h3 class="text-sm font-black text-gray-900 uppercase tracking-widest mb-4 flex items-center gap-2">
						<Award class="h-4 w-4 text-gray-400" />
						Qualifications
					</h3>
					<p class="text-gray-600 text-sm leading-relaxed whitespace-pre-line">
						{doctor.credentials || 'Qualifications not specified.'}
					</p>
				</div>
			</div>

			<!-- Danger Zone Card -->
			<div class="bg-red-50/50 rounded-3xl border border-red-100 p-8">
				<div class="flex flex-col sm:flex-row items-center justify-between gap-6">
					<div class="flex items-center gap-4 text-center sm:text-left">
						<div class="p-4 bg-red-100 text-red-600 rounded-2xl shadow-inner">
							<ShieldAlert class="h-8 w-8" />
						</div>
						<div>
							<h2 class="text-xl font-bold text-red-900">Danger Zone</h2>
							<p class="text-sm text-red-700 font-medium max-w-md">
								Removing this doctor will terminate their partnership with your clinic immediately. They will no longer be visible to your patients.
							</p>
						</div>
					</div>
					<button 
						onclick={() => showDeleteConfirm = true}
						class="w-full sm:w-auto px-8 py-4 bg-red-600 text-white font-black rounded-2xl hover:bg-red-700 shadow-xl shadow-red-200 transition-all active:scale-95 flex items-center justify-center gap-2"
					>
						<Trash2 class="h-5 w-5" />
						Delete Partner
					</button>
				</div>
			</div>
		{/if}
	</div>
</div>

<!-- Strike Modal -->
{#if showStrikeModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
		<div class="absolute inset-0 bg-black/60 backdrop-blur-sm" onclick={() => showStrikeModal = false}></div>
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-lg z-10 overflow-hidden flex flex-col border border-white/20 animate-in fade-in zoom-in-95 duration-200">
			<div class="p-6 border-b border-gray-100 bg-white">
				<div class="h-14 w-14 bg-red-50 text-red-600 rounded-2xl flex items-center justify-center mb-4">
					<AlertTriangle class="h-7 w-7" />
				</div>
				<h2 class="text-xl font-black text-gray-900">Issue a Strike</h2>
				<p class="text-xs text-gray-500 font-medium">Strikes are monitored by platform admins. Please provide a clear reason.</p>
			</div>
			
			<div class="p-6 space-y-4">
				<div>
					<label class="block text-sm font-bold text-gray-700 mb-2" for="strike-reason">Reason for Strike</label>
					<textarea 
						id="strike-reason"
						bind:value={strikeReason}
						placeholder="e.g. Poaching patients, Unprofessional behavior..."
						class="w-full h-24 px-4 py-3 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-red-100 focus:border-red-600 outline-none transition-all font-medium text-sm"
					></textarea>
				</div>
				<div class="flex items-center gap-3 p-4 bg-amber-50 rounded-2xl border border-amber-100">
					<AlertCircle class="h-5 w-5 text-amber-600" />
					<p class="text-[11px] text-amber-900 font-bold leading-tight">
						Multiple strikes can lead to permanent deactivation of this doctor's account.
					</p>
				</div>
			</div>

			<div class="p-6 border-t bg-gray-50 flex gap-4">
				<button 
					onclick={() => showStrikeModal = false}
					class="flex-1 py-4 bg-white text-gray-700 font-bold rounded-2xl border border-gray-200 hover:bg-gray-100 active:scale-95 transition-all"
				>
					Cancel
				</button>
				<button 
					onclick={addStrike}
					disabled={saving || !strikeReason.trim()}
					class="flex-1 py-4 bg-red-600 text-white font-black rounded-2xl hover:bg-red-700 shadow-xl shadow-red-200 active:scale-95 transition-all disabled:opacity-50"
				>
					{saving ? 'Processing...' : 'Confirm Strike'}
				</button>
			</div>
		</div>
	</div>
{/if}

<!-- Delete Confirmation Modal -->
{#if showDeleteConfirm}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
		<div class="absolute inset-0 bg-black/60 backdrop-blur-sm" onclick={() => showDeleteConfirm = false}></div>
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-md z-10 overflow-hidden flex flex-col border border-white/20 animate-in fade-in zoom-in-95 duration-200">
			<div class="p-8 text-center bg-white">
				<div class="h-20 w-20 bg-red-50 text-red-600 rounded-full flex items-center justify-center mx-auto mb-6">
					<Trash2 class="h-10 w-10" />
				</div>
				<h2 class="text-2xl font-black text-gray-900">Are you sure?</h2>
				<p class="text-sm text-gray-500 font-medium mt-2">
					This action will remove <span class="font-bold text-black">{doctor?.full_name}</span> from your clinic's partner list. You can invite them back later.
				</p>
			</div>
			
			<div class="p-8 bg-gray-50 flex gap-4">
				<button 
					onclick={() => showDeleteConfirm = false}
					class="flex-1 py-4 bg-white text-gray-700 font-bold rounded-2xl border border-gray-200 hover:bg-gray-100 active:scale-95 transition-all"
				>
					Keep Partner
				</button>
				<button 
					onclick={deletePartner}
					disabled={saving}
					class="flex-1 py-4 bg-red-600 text-white font-black rounded-2xl hover:bg-red-700 shadow-xl shadow-red-200 active:scale-95 transition-all disabled:opacity-50 text-sm"
				>
					{saving ? 'Removing...' : 'Yes, Remove'}
				</button>
			</div>
		</div>
	</div>
{/if}
