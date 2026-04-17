<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, Loader2 } from 'lucide-svelte';
	import FileUpload from '$lib/components/FileUpload.svelte';

	let provider = $state<any>(null);
	let loading = $state(false);
	let initialLoading = $state(true);
	let error = $state('');

	let formData = $state({
		full_name: '',
		email: '',
		phone: '',
		date_of_birth: '',
		gender: 'male',
		blood_group: '',
		allergies: '',
		chronic_conditions: '',
		emergency_contact_name: '',
		emergency_contact_phone: ''
	});

	let profilePicFile = $state<File | null>(null);
	let profilePicPreview = $state('');

	onMount(async () => {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) {
				goto('/auth/login');
				return;
			}

			// Get provider profile
			const { data: providerData, error: providerError } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();

			if (providerError) throw providerError;
			provider = providerData;
		} catch (err: any) {
			console.error('Error initializing page:', err);
			error = 'Failed to load provider profile. Please refresh the page.';
		} finally {
			initialLoading = false;
		}
	});

	async function uploadProfilePicture(file: File): Promise<string> {
		const fileExt = file.name.split('.').pop();
		const fileName = `${Math.random().toString(36).substring(2)}-${Date.now()}.${fileExt}`;
		const filePath = `patient-profiles/${fileName}`;

		const { error: uploadError } = await supabase.storage
			.from('patient-profile-pictures')
			.upload(filePath, file);

		if (uploadError) throw uploadError;

		const { data } = supabase.storage
			.from('patient-profile-pictures')
			.getPublicUrl(filePath);

		return data.publicUrl;
	}

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!provider) {
			error = 'Provider profile not loaded. Cannot add patient.';
			return;
		}

		loading = true;
		error = '';

		try {
			let profilePhotoUrl = '';

			// Upload profile picture if selected
			if (profilePicFile) {
				profilePhotoUrl = await uploadProfilePicture(profilePicFile);
			}

			// Format allergies and chronic conditions as arrays if they have content
			const allergies = formData.allergies
				? formData.allergies.split(',').map(s => s.trim()).filter(s => s.length > 0)
				: [];
			
			const chronicConditions = formData.chronic_conditions
				? formData.chronic_conditions.split(',').map(s => s.trim()).filter(s => s.length > 0)
				: [];

			// Create patient record
			const { error: insertError } = await supabase
				.from('patients')
				.insert({
					healthcare_provider_id: provider.id,
					full_name: formData.full_name,
					email: formData.email || null,
					phone: formData.phone,
					date_of_birth: formData.date_of_birth || null,
					gender: formData.gender || null,
					blood_group: formData.blood_group || null,
					allergies: allergies,
					chronic_conditions: chronicConditions,
					emergency_contact_name: formData.emergency_contact_name || null,
					emergency_contact_phone: formData.emergency_contact_phone || null,
					profile_photo_url: profilePhotoUrl || null,
					is_deleted: false
				});

			if (insertError) throw insertError;

			console.log('Patient created successfully, redirecting...');
			await goto('/patients');
		} catch (err: any) {
			console.error('Error adding patient:', err);
			error = err.message || 'Failed to add patient. Please try again.';
		} finally {
			loading = false;
		}
	}
</script>

<div class="min-h-screen bg-gray-50 p-6 lg:p-8">
	<div class="max-w-4xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
			<div class="flex items-center gap-4">
				<a
					href="/patients"
					class="p-2 hover:bg-gray-100 rounded-xl transition-all active:scale-95"
				>
					<ArrowLeft class="h-6 w-6 text-gray-600" />
				</a>
				<div>
					<h2 class="text-2xl font-bold text-gray-900 tracking-tight">Add New Patient</h2>
					<p class="text-gray-500 font-medium mt-0.5">Create a dedicated medical record for your patient</p>
				</div>
			</div>
		</div>

		{#if initialLoading}
			<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-12 flex flex-col items-center justify-center">
				<Loader2 class="h-10 w-10 text-primary-600 animate-spin" />
				<p class="mt-4 text-gray-500 font-medium">Initializing form...</p>
			</div>
		{:else}
			<!-- Form -->
			<form onsubmit={handleSubmit} class="space-y-6">
				{#if error}
					<div class="bg-red-50 border border-red-100 text-red-700 px-6 py-4 rounded-2xl text-sm font-semibold flex items-center gap-3 animate-shake">
						<div class="h-2 w-2 rounded-full bg-red-600"></div>
						{error}
					</div>
				{/if}

				<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
					<!-- Left Column: Photo & Basic -->
					<div class="lg:col-span-1 space-y-6">
						<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
							<h3 class="text-sm font-bold text-gray-900 uppercase tracking-widest mb-6 px-1">Patient Photo</h3>
							<FileUpload
								label="Upload Photo"
								accept="image/*"
								maxSize={2097152}
								bind:file={profilePicFile}
								bind:previewUrl={profilePicPreview}
								onFileSelect={(file) => (profilePicFile = file)}
							/>
							<p class="text-[10px] text-gray-400 mt-4 text-center leading-relaxed">
								Recommended: Square image, max 2MB.<br/>Allowed types: JPG, PNG, WEBP.
							</p>
						</div>

						<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4">
							<h3 class="text-sm font-bold text-gray-900 uppercase tracking-widest mb-2 px-1">Vital Info</h3>
							
							<div>
								<label for="blood_group" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
									Blood Group
								</label>
								<select
									id="blood_group"
									bind:value={formData.blood_group}
									class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
								>
									<option value="">Unknown</option>
									<option value="A+">A+</option>
									<option value="A-">A-</option>
									<option value="B+">B+</option>
									<option value="B-">B-</option>
									<option value="AB+">AB+</option>
									<option value="AB-">AB-</option>
									<option value="O+">O+</option>
									<option value="O-">O-</option>
								</select>
							</div>

							<div>
								<label for="gender" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
									Gender
								</label>
								<div class="grid grid-cols-2 gap-2">
									<button
										type="button"
										onclick={() => formData.gender = 'male'}
										class="py-3 px-4 rounded-xl border-2 transition-all font-bold text-sm {formData.gender === 'male' ? 'border-primary-600 bg-primary-50 text-primary-700' : 'border-gray-50 bg-gray-50 text-gray-500 hover:border-gray-200'}"
									>
										Male
									</button>
									<button
										type="button"
										onclick={() => formData.gender = 'female'}
										class="py-3 px-4 rounded-xl border-2 transition-all font-bold text-sm {formData.gender === 'female' ? 'border-primary-600 bg-primary-50 text-primary-700' : 'border-gray-50 bg-gray-50 text-gray-500 hover:border-gray-200'}"
									>
										Female
									</button>
								</div>
							</div>
						</div>
					</div>

					<!-- Right Column: Full Details -->
					<div class="lg:col-span-2 space-y-6">
						<!-- Personal Details -->
						<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 space-y-6">
							<h3 class="text-sm font-bold text-gray-900 uppercase tracking-widest px-1">Personal Details</h3>
							
							<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
								<div class="md:col-span-2">
									<label for="full_name" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Full Name *
									</label>
									<input
										id="full_name"
										type="text"
										bind:value={formData.full_name}
										required
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
										placeholder="e.g. Adewale K. Johnson"
									/>
								</div>

								<div>
									<label for="phone" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Phone Number *
									</label>
									<input
										id="phone"
										type="tel"
										bind:value={formData.phone}
										required
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
										placeholder="+234 XXX XXX XXXX"
									/>
								</div>

								<div>
									<label for="email" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Email Address
									</label>
									<input
										id="email"
										type="email"
										bind:value={formData.email}
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
										placeholder="patient@example.com"
									/>
								</div>

								<div>
									<label for="date_of_birth" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Date of Birth
									</label>
									<input
										id="date_of_birth"
										type="date"
										bind:value={formData.date_of_birth}
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900 uppercase"
									/>
								</div>
							</div>
						</div>

						<!-- Medical Info -->
						<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 space-y-6">
							<h3 class="text-sm font-bold text-gray-900 uppercase tracking-widest px-1">Medical Background</h3>
							
							<div class="space-y-4">
								<div>
									<label for="allergies" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Known Allergies
									</label>
									<textarea
										id="allergies"
										bind:value={formData.allergies}
										rows="2"
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
										placeholder="e.g. Penicillin, Peanuts (Comma separated)..."
									></textarea>
								</div>

								<div>
									<label for="chronic" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Chronic Conditions
									</label>
									<textarea
										id="chronic"
										bind:value={formData.chronic_conditions}
										rows="2"
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
										placeholder="e.g. Hypertension, Asthma (Comma separated)..."
									></textarea>
								</div>
							</div>
						</div>

						<!-- Emergency Contact -->
						<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 space-y-6">
							<h3 class="text-sm font-bold text-gray-900 uppercase tracking-widest px-1">Emergency Contact</h3>
							
							<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
								<div>
									<label for="e_name" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Contact Name
									</label>
									<input
										id="e_name"
										type="text"
										bind:value={formData.emergency_contact_name}
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
										placeholder="e.g. Jane Doe"
									/>
								</div>

								<div>
									<label for="e_phone" class="block text-xs font-bold text-gray-500 uppercase mb-2 px-1">
										Contact Phone
									</label>
									<input
										id="e_phone"
										type="tel"
										bind:value={formData.emergency_contact_phone}
										class="w-full px-4 py-3 bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all font-medium text-gray-900"
										placeholder="+234 XXX XXX XXXX"
									/>
								</div>
							</div>
						</div>

						<!-- Final Action -->
						<div class="flex gap-4 pt-4 pb-12">
							<a
								href="/patients"
								class="flex-1 px-8 py-4 bg-white border-2 border-gray-100 text-gray-500 rounded-2xl hover:bg-gray-50 transition-all font-bold text-sm text-center active:scale-95"
							>
								Cancel
							</a>
							<button
								type="submit"
								disabled={loading}
								class="flex-[2] px-8 py-4 bg-gray-900 text-white rounded-2xl hover:bg-black transition-all font-bold text-sm shadow-lg shadow-gray-200 flex items-center justify-center gap-3 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{#if loading}
									<Loader2 class="h-5 w-5 animate-spin" />
									Processing...
								{:else}
									<Save class="h-5 w-5" />
									Create Medical Record
								{/if}
							</button>
						</div>
					</div>
				</div>
			</form>
		{/if}
	</div>
</div>

<style>
	@keyframes shake {
		0%, 100% { transform: translateX(0); }
		25% { transform: translateX(-4px); }
		75% { transform: translateX(4px); }
	}
	.animate-shake {
		animation: shake 0.4s ease-in-out 0s 2;
	}
</style>
