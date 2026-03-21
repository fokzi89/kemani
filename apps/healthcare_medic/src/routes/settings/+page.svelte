<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Settings, User, CreditCard, Bell, Shield, ArrowUpCircle, Clock, Save, DollarSign, Edit, MapPin, Briefcase, Award, FileCheck, Plus, Trash2 } from 'lucide-svelte';
	import Modal from '$lib/components/Modal.svelte';
	import FileUpload from '$lib/components/FileUpload.svelte';

	let provider = $state(null);
	let subscription = $state(null);
	let loading = $state(true);
	let savingSchedule = $state(false);
	let savingFees = $state(false);

	// Work schedule state
	let schedule = $state([
		{ day: 'Monday', enabled: false, startTime: '09:00', endTime: '17:00' },
		{ day: 'Tuesday', enabled: false, startTime: '09:00', endTime: '17:00' },
		{ day: 'Wednesday', enabled: false, startTime: '09:00', endTime: '17:00' },
		{ day: 'Thursday', enabled: false, startTime: '09:00', endTime: '17:00' },
		{ day: 'Friday', enabled: false, startTime: '09:00', endTime: '17:00' },
		{ day: 'Saturday', enabled: false, startTime: '09:00', endTime: '17:00' },
		{ day: 'Sunday', enabled: false, startTime: '09:00', endTime: '17:00' }
	]);

	// Consultation fees state
	let fees = $state({
		chat: 5000,
		video: 10000,
		audio: 8000,
		office_visit: 15000
	});

	// Calculate marked up fee (shown to customers) - adds 10%
	function calculateMarkedUpFee(baseFee: number): number {
		return Math.round(baseFee * 1.10);
	}

	// Calculate doctor's take home - deducts 10% platform fee
	function calculateTakeHome(baseFee: number): number {
		return Math.round(baseFee * 0.90);
	}

	// Derived marked up fees
	let markedUpFees = $derived({
		chat: calculateMarkedUpFee(fees.chat),
		video: calculateMarkedUpFee(fees.video),
		audio: calculateMarkedUpFee(fees.audio),
		office_visit: calculateMarkedUpFee(fees.office_visit)
	});

	// Time slot settings
	let slotDuration = $state(30); // minutes
	let bufferTime = $state(0); // minutes between appointments
	let slotSettings = $state({
		duration: 30,
		buffer: 0,
		breakTimes: [] // [{startTime: '12:00', endTime: '13:00'}]
	});
	let savingSlots = $state(false);

	// Profile editing state
	let showProfileModal = $state(false);
	let showAddressModal = $state(false);
	let showWorkExperienceModal = $state(false);
	let showCertificateModal = $state(false);
	let showLicenseModal = $state(false);

	// Profile form state
	let profileForm = $state({
		full_name: '',
		email: '',
		phone: '',
		specialization: '',
		sub_specialty: '',
		preferred_languages: ''
	});

	// Profile picture upload
	let profilePicFile = $state<File | null>(null);
	let profilePicPreview = $state('');
	let uploadingProfilePic = $state(false);

	// Address form state
	let addressForm = $state({
		country: '',
		region: '',
		city: '',
		street: ''
	});

	// Work experience state
	let workExperiences = $state([]);
	let workExpForm = $state({
		position: '',
		organization: '',
		location: '',
		start_date: '',
		end_date: '',
		is_current: false,
		description: ''
	});

	// Certificate state
	let certificates = $state([]);
	let certForm = $state({
		certificate_name: '',
		issuing_organization: '',
		issue_date: '',
		expiry_date: '',
		certificate_number: ''
	});
	let certFile = $state<File | null>(null);
	let certFilePreview = $state('');

	// License state
	let licenses = $state([]);
	let licenseForm = $state({
		license_type: '',
		license_number: '',
		issuing_authority: '',
		issue_date: '',
		expiry_date: '',
		country: '',
		state_region: ''
	});
	let licenseFile = $state<File | null>(null);
	let licenseFilePreview = $state('');

	// Loading states
	let savingProfile = $state(false);
	let savingAddress = $state(false);
	let savingWorkExp = $state(false);
	let savingCertificate = $state(false);
	let savingLicense = $state(false);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();

		if (!session) {
			goto('/auth/login');
			return;
		}

		// Get provider
		const { data: providerData } = await supabase
			.from('healthcare_providers')
			.select('*')
			.eq('user_id', session.user.id)
			.single();

		provider = providerData;

		// Load work schedule if exists
		if (provider?.work_schedule && Array.isArray(provider.work_schedule) && provider.work_schedule.length > 0) {
			schedule = provider.work_schedule;
		}

		// Load consultation fees if exists
		if (provider?.fees) {
			fees = { ...fees, ...provider.fees };
		}

		// Load time slot settings if exists
		if (provider?.slot_settings) {
			slotSettings = { ...slotSettings, ...provider.slot_settings };
			slotDuration = slotSettings.duration;
			bufferTime = slotSettings.buffer;
		}

		// Get subscription
		if (provider?.medic_subscription_id) {
			const { data: subData } = await supabase
				.from('medic_subscriptions')
				.select('*')
				.eq('id', provider.medic_subscription_id)
				.single();

			subscription = subData;
		}

		// Load work experiences
		if (provider) {
			const { data: workExpData } = await supabase
				.from('provider_work_experience')
				.select('*')
				.eq('provider_id', provider.id)
				.order('start_date', { ascending: false });

			workExperiences = workExpData || [];

			// Load certificates
			const { data: certData } = await supabase
				.from('provider_certificates')
				.select('*')
				.eq('provider_id', provider.id)
				.order('issue_date', { ascending: false });

			certificates = certData || [];

			// Load licenses
			const { data: licenseData } = await supabase
				.from('provider_licenses')
				.select('*')
				.eq('provider_id', provider.id)
				.order('issue_date', { ascending: false });

			licenses = licenseData || [];

			// Initialize profile form
			profileForm = {
				full_name: provider.full_name || '',
				email: provider.email || '',
				phone: provider.phone || '',
				specialization: provider.specialization || '',
				sub_specialty: provider.sub_specialty || '',
				preferred_languages: provider.preferred_languages?.join(', ') || ''
			};

			profilePicPreview = provider.profile_photo_url || '';

			// Initialize address form
			if (provider.clinic_address) {
				const addr = provider.clinic_address;
				addressForm = {
					country: addr.country || provider.country || '',
					region: addr.state || provider.region || '',
					city: addr.city || '',
					street: addr.street || ''
				};
			} else {
				addressForm = {
					country: provider.country || '',
					region: provider.region || '',
					city: '',
					street: ''
				};
			}
		}

		loading = false;
	});

	function getTierName(tier: string) {
		const names = { free: 'Free', growth: 'Growth', enterprise: 'Enterprise' };
		return names[tier] || 'Unknown';
	}

	async function saveSchedule() {
		if (!provider) return;

		savingSchedule = true;

		try {
			// Save schedule to provider profile
			const { error } = await supabase
				.from('healthcare_providers')
				.update({
					work_schedule: schedule
				})
				.eq('id', provider.id);

			if (error) {
				alert('Failed to save schedule: ' + error.message);
			} else {
				alert('Work schedule saved successfully!');
			}
		} catch (err) {
			console.error('Error saving schedule:', err);
			alert('An error occurred while saving schedule');
		} finally {
			savingSchedule = false;
		}
	}

	function toggleDay(index: number) {
		schedule[index].enabled = !schedule[index].enabled;
	}

	async function saveFees() {
		if (!provider) return;

		savingFees = true;

		try {
			// Save both base fees and marked up fees to provider profile
			const { error } = await supabase
				.from('healthcare_providers')
				.update({
					fees: fees,
					marked_up_fees: markedUpFees
				})
				.eq('id', provider.id);

			if (error) {
				alert('Failed to save consultation fees: ' + error.message);
			} else {
				alert('Consultation fees saved successfully!');
			}
		} catch (err) {
			console.error('Error saving fees:', err);
			alert('An error occurred while saving fees');
		} finally {
			savingFees = false;
		}
	}

	async function saveSlotSettings() {
		if (!provider) return;

		savingSlots = true;

		try {
			// Update slot settings object
			const updatedSettings = {
				duration: slotDuration,
				buffer: bufferTime,
				breakTimes: slotSettings.breakTimes
			};

			// Save slot settings to provider profile
			const { error } = await supabase
				.from('healthcare_providers')
				.update({
					slot_settings: updatedSettings
				})
				.eq('id', provider.id);

			if (error) {
				alert('Failed to save time slot settings: ' + error.message);
			} else {
				alert('Time slot settings saved successfully!');
			}
		} catch (err) {
			console.error('Error saving slot settings:', err);
			alert('An error occurred while saving slot settings');
		} finally {
			savingSlots = false;
		}
	}

	// ===== FILE UPLOAD UTILITIES =====
	async function uploadFileToStorage(
		file: File,
		bucket: string,
		folder: string
	): Promise<string | null> {
		try {
			const fileExt = file.name.split('.').pop();
			const fileName = `${folder}/${provider.id}/${Date.now()}.${fileExt}`;

			const { data, error } = await supabase.storage
				.from(bucket)
				.upload(fileName, file, {
					cacheControl: '3600',
					upsert: false
				});

			if (error) throw error;

			// Get public URL
			const { data: { publicUrl } } = supabase.storage
				.from(bucket)
				.getPublicUrl(fileName);

			return publicUrl;
		} catch (err) {
			console.error('Upload error:', err);
			return null;
		}
	}

	async function deleteFileFromStorage(url: string, bucket: string) {
		try {
			const path = url.split(`${bucket}/`)[1];
			if (!path) return;

			await supabase.storage.from(bucket).remove([path]);
		} catch (err) {
			console.error('Delete error:', err);
		}
	}

	// ===== PROFILE SAVE FUNCTIONS =====
	async function saveProfile() {
		if (!provider) return;

		savingProfile = true;

		try {
			let profilePhotoUrl = provider.profile_photo_url;

			// Upload new profile picture if selected
			if (profilePicFile) {
				// Delete old picture if exists
				if (profilePhotoUrl) {
					await deleteFileFromStorage(profilePhotoUrl, 'provider-profile-pictures');
				}

				// Upload new picture
				profilePhotoUrl = await uploadFileToStorage(
					profilePicFile,
					'provider-profile-pictures',
					'profiles'
				);
			}

			// Parse languages from comma-separated string
			const languages = profileForm.preferred_languages
				.split(',')
				.map(lang => lang.trim())
				.filter(lang => lang.length > 0);

			// Update provider profile
			const { error } = await supabase
				.from('healthcare_providers')
				.update({
					full_name: profileForm.full_name,
					email: profileForm.email,
					phone: profileForm.phone,
					specialization: profileForm.specialization,
					sub_specialty: profileForm.sub_specialty || null,
					preferred_languages: languages.length > 0 ? languages : null,
					profile_photo_url: profilePhotoUrl,
					updated_at: new Date().toISOString()
				})
				.eq('id', provider.id);

			if (error) throw error;

			// Update local state
			provider.full_name = profileForm.full_name;
			provider.email = profileForm.email;
			provider.phone = profileForm.phone;
			provider.specialization = profileForm.specialization;
			provider.sub_specialty = profileForm.sub_specialty;
			provider.preferred_languages = languages;
			provider.profile_photo_url = profilePhotoUrl;

			alert('Profile updated successfully!');
			showProfileModal = false;
			profilePicFile = null;
		} catch (err) {
			console.error('Error saving profile:', err);
			alert('Failed to save profile: ' + err.message);
		} finally {
			savingProfile = false;
		}
	}

	async function saveAddress() {
		if (!provider) return;

		savingAddress = true;

		try {
			const clinicAddress = {
				street: addressForm.street,
				city: addressForm.city,
				state: addressForm.region,
				country: addressForm.country,
				postal_code: null,
				lat: null,
				lng: null
			};

			const { error } = await supabase
				.from('healthcare_providers')
				.update({
					country: addressForm.country,
					region: addressForm.region,
					clinic_address: clinicAddress,
					updated_at: new Date().toISOString()
				})
				.eq('id', provider.id);

			if (error) throw error;

			provider.country = addressForm.country;
			provider.region = addressForm.region;
			provider.clinic_address = clinicAddress;

			alert('Address updated successfully!');
			showAddressModal = false;
		} catch (err) {
			console.error('Error saving address:', err);
			alert('Failed to save address: ' + err.message);
		} finally {
			savingAddress = false;
		}
	}

	// ===== WORK EXPERIENCE FUNCTIONS =====
	async function saveWorkExperience() {
		if (!provider) return;

		savingWorkExp = true;

		try {
			const { data, error } = await supabase
				.from('provider_work_experience')
				.insert({
					provider_id: provider.id,
					position: workExpForm.position,
					organization: workExpForm.organization,
					location: workExpForm.location || null,
					start_date: workExpForm.start_date,
					end_date: workExpForm.is_current ? null : workExpForm.end_date,
					is_current: workExpForm.is_current,
					description: workExpForm.description || null
				})
				.select()
				.single();

			if (error) throw error;

			workExperiences = [data, ...workExperiences];

			alert('Work experience added successfully!');
			showWorkExperienceModal = false;

			// Reset form
			workExpForm = {
				position: '',
				organization: '',
				location: '',
				start_date: '',
				end_date: '',
				is_current: false,
				description: ''
			};
		} catch (err) {
			console.error('Error saving work experience:', err);
			alert('Failed to save work experience: ' + err.message);
		} finally {
			savingWorkExp = false;
		}
	}

	async function deleteWorkExperience(id: string) {
		if (!confirm('Are you sure you want to delete this work experience?')) return;

		try {
			const { error } = await supabase
				.from('provider_work_experience')
				.delete()
				.eq('id', id);

			if (error) throw error;

			workExperiences = workExperiences.filter(exp => exp.id !== id);
			alert('Work experience deleted successfully!');
		} catch (err) {
			console.error('Error deleting work experience:', err);
			alert('Failed to delete work experience: ' + err.message);
		}
	}

	// ===== CERTIFICATE FUNCTIONS =====
	async function saveCertificate() {
		if (!provider || !certFile) {
			alert('Please select a certificate file');
			return;
		}

		savingCertificate = true;

		try {
			// Upload file
			const fileUrl = await uploadFileToStorage(
				certFile,
				'provider-certificates',
				'certificates'
			);

			if (!fileUrl) throw new Error('Failed to upload certificate file');

			// Save certificate record
			const { data, error } = await supabase
				.from('provider_certificates')
				.insert({
					provider_id: provider.id,
					certificate_name: certForm.certificate_name,
					issuing_organization: certForm.issuing_organization,
					issue_date: certForm.issue_date,
					expiry_date: certForm.expiry_date || null,
					certificate_number: certForm.certificate_number || null,
					file_url: fileUrl,
					file_name: certFile.name,
					file_size: certFile.size,
					file_type: certFile.type
				})
				.select()
				.single();

			if (error) throw error;

			certificates = [data, ...certificates];

			alert('Certificate added successfully!');
			showCertificateModal = false;

			// Reset form
			certForm = {
				certificate_name: '',
				issuing_organization: '',
				issue_date: '',
				expiry_date: '',
				certificate_number: ''
			};
			certFile = null;
			certFilePreview = '';
		} catch (err) {
			console.error('Error saving certificate:', err);
			alert('Failed to save certificate: ' + err.message);
		} finally {
			savingCertificate = false;
		}
	}

	async function deleteCertificate(id: string, fileUrl: string) {
		if (!confirm('Are you sure you want to delete this certificate?')) return;

		try {
			// Delete file from storage
			await deleteFileFromStorage(fileUrl, 'provider-certificates');

			// Delete record
			const { error } = await supabase
				.from('provider_certificates')
				.delete()
				.eq('id', id);

			if (error) throw error;

			certificates = certificates.filter(cert => cert.id !== id);
			alert('Certificate deleted successfully!');
		} catch (err) {
			console.error('Error deleting certificate:', err);
			alert('Failed to delete certificate: ' + err.message);
		}
	}

	// ===== LICENSE FUNCTIONS =====
	async function saveLicense() {
		if (!provider || !licenseFile) {
			alert('Please select a license file');
			return;
		}

		savingLicense = true;

		try {
			// Upload file
			const fileUrl = await uploadFileToStorage(
				licenseFile,
				'provider-licenses',
				'licenses'
			);

			if (!fileUrl) throw new Error('Failed to upload license file');

			// Save license record
			const { data, error } = await supabase
				.from('provider_licenses')
				.insert({
					provider_id: provider.id,
					license_type: licenseForm.license_type,
					license_number: licenseForm.license_number,
					issuing_authority: licenseForm.issuing_authority,
					issue_date: licenseForm.issue_date,
					expiry_date: licenseForm.expiry_date,
					country: licenseForm.country,
					state_region: licenseForm.state_region || null,
					file_url: fileUrl,
					file_name: licenseFile.name,
					file_size: licenseFile.size,
					file_type: licenseFile.type,
					status: 'active'
				})
				.select()
				.single();

			if (error) throw error;

			licenses = [data, ...licenses];

			alert('License added successfully!');
			showLicenseModal = false;

			// Reset form
			licenseForm = {
				license_type: '',
				license_number: '',
				issuing_authority: '',
				issue_date: '',
				expiry_date: '',
				country: '',
				state_region: ''
			};
			licenseFile = null;
			licenseFilePreview = '';
		} catch (err) {
			console.error('Error saving license:', err);
			alert('Failed to save license: ' + err.message);
		} finally {
			savingLicense = false;
		}
	}

	async function deleteLicense(id: string, fileUrl: string) {
		if (!confirm('Are you sure you want to delete this license?')) return;

		try {
			// Delete file from storage
			await deleteFileFromStorage(fileUrl, 'provider-licenses');

			// Delete record
			const { error } = await supabase
				.from('provider_licenses')
				.delete()
				.eq('id', id);

			if (error) throw error;

			licenses = licenses.filter(lic => lic.id !== id);
			alert('License deleted successfully!');
		} catch (err) {
			console.error('Error deleting license:', err);
			alert('Failed to delete license: ' + err.message);
		}
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-5xl mx-auto space-y-6">
		<!-- Page Header -->
		<div>
			<h1 class="text-3xl font-bold text-gray-900">Settings</h1>
			<p class="text-gray-600 mt-2">Manage your account settings and preferences</p>
		</div>

		{#if loading}
			<div class="flex items-center justify-center py-12">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
			</div>
		{:else}
			<!-- Settings Sections -->
			<div class="space-y-6">
				<!-- Profile Section -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between mb-4">
						<div class="flex items-center gap-3">
							<div class="p-2 bg-primary-100 rounded-lg">
								<User class="h-5 w-5 text-primary-600" />
							</div>
							<h2 class="text-xl font-semibold text-gray-900">Profile Information</h2>
						</div>
						<button
							onclick={() => (showProfileModal = true)}
							class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm"
						>
							<Edit class="h-4 w-4" />
							Edit Profile
						</button>
					</div>

					<!-- Profile Picture -->
					{#if provider?.profile_photo_url}
						<div class="flex items-center gap-4 mb-6 pb-6 border-b">
							<img
								src={provider.profile_photo_url}
								alt={provider.full_name}
								class="h-20 w-20 rounded-full object-cover border-2 border-gray-200"
							/>
							<div>
								<p class="text-sm font-medium text-gray-700">Profile Picture</p>
								<p class="text-xs text-gray-500">Click "Edit Profile" to change</p>
							</div>
						</div>
					{/if}
					<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
						<div>
							<label class="text-sm font-medium text-gray-700">Full Name</label>
							<p class="text-gray-900 mt-1">{provider?.full_name || 'N/A'}</p>
						</div>
						<div>
							<label class="text-sm font-medium text-gray-700">Email</label>
							<p class="text-gray-900 mt-1">{provider?.email || 'N/A'}</p>
						</div>
						<div>
							<label class="text-sm font-medium text-gray-700">Specialization</label>
							<p class="text-gray-900 mt-1">{provider?.specialization || 'N/A'}</p>
						</div>
						<div>
							<label class="text-sm font-medium text-gray-700">Sub-specialty</label>
							<p class="text-gray-900 mt-1">{provider?.sub_specialty || 'Not specified'}</p>
						</div>
						<div>
							<label class="text-sm font-medium text-gray-700">Phone</label>
							<p class="text-gray-900 mt-1">{provider?.phone || 'N/A'}</p>
						</div>
						<div>
							<label class="text-sm font-medium text-gray-700">Languages</label>
							<p class="text-gray-900 mt-1">
								{provider?.preferred_languages?.join(', ') || 'Not specified'}
							</p>
						</div>
					</div>
				</div>

				<!-- Subscription Section -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between mb-4">
						<div class="flex items-center gap-3">
							<div class="p-2 bg-primary-100 rounded-lg">
								<CreditCard class="h-5 w-5 text-primary-600" />
							</div>
							<h2 class="text-xl font-semibold text-gray-900">Subscription</h2>
						</div>
						{#if subscription && subscription.tier !== 'enterprise'}
							<a
								href="/subscription"
								class="flex items-center gap-2 px-4 py-2 bg-white hover:bg-gray-50 text-gray-900 border border-gray-900 rounded-lg text-sm font-medium transition-colors shadow-sm"
							>
								<ArrowUpCircle class="h-4 w-4" />
								Upgrade Plan
							</a>
						{/if}
					</div>

					{#if subscription}
						<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
							<div>
								<label class="text-sm font-medium text-gray-700">Current Plan</label>
								<p class="text-gray-900 mt-1 font-semibold">{getTierName(subscription.tier)}</p>
							</div>
							<div>
								<label class="text-sm font-medium text-gray-700">Monthly Fee</label>
								<p class="text-gray-900 mt-1">₦{subscription.monthly_fee.toLocaleString()}</p>
							</div>
							<div>
								<label class="text-sm font-medium text-gray-700">Status</label>
								<p class="mt-1">
									<span class="px-2 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full">
										{subscription.status}
									</span>
								</p>
							</div>
						</div>

						{#if subscription.tier !== 'free'}
							<div class="mt-4 pt-4 border-t">
								<label class="text-sm font-medium text-gray-700">Commission Rates</label>
								<div class="grid grid-cols-2 gap-4 mt-2">
									<div>
										<p class="text-xs text-gray-600">Drug Referrals</p>
										<p class="text-gray-900 font-medium">{subscription.drug_commission_rate}%</p>
									</div>
									<div>
										<p class="text-xs text-gray-600">Diagnostic Tests</p>
										<p class="text-gray-900 font-medium">{subscription.diagnostic_commission_rate}%</p>
									</div>
								</div>
							</div>
						{/if}
					{:else}
						<p class="text-gray-600">No active subscription</p>
						<a
							href="/subscription"
							class="inline-flex items-center gap-2 px-4 py-2 bg-white hover:bg-gray-50 text-gray-900 border border-gray-900 rounded-lg text-sm font-medium transition-colors shadow-sm mt-4"
						>
							Choose a Plan
						</a>
					{/if}
				</div>

				<!-- Consultation Fees Section -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between mb-4">
						<div class="flex items-center gap-3">
							<div class="p-2 bg-primary-100 rounded-lg">
								<DollarSign class="h-5 w-5 text-primary-600" />
							</div>
							<h2 class="text-xl font-semibold text-gray-900">Consultation Fees</h2>
						</div>
						<button
							onclick={saveFees}
							disabled={savingFees}
							class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
						>
							<Save class="h-4 w-4" />
							{savingFees ? 'Saving...' : 'Save Fees'}
						</button>
					</div>

					<p class="text-sm text-gray-600 mb-6">Set your consultation fees for different consultation types</p>

					<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
						<!-- Chat Consultation -->
						<div class="border border-gray-200 rounded-lg p-4">
							<label for="fee-chat" class="block text-sm font-medium text-gray-700 mb-2">
								Chat Consultation
							</label>
							<div class="relative mb-3">
								<span class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500">₦</span>
								<input
									id="fee-chat"
									type="number"
									bind:value={fees.chat}
									min="0"
									step="100"
									class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
								/>
							</div>
							<div class="space-y-2 text-xs">
								<div class="flex justify-between items-center py-2 px-3 bg-green-50 rounded">
									<span class="text-gray-600">Your Take Home (after 10% platform fee):</span>
									<span class="font-semibold text-green-700">₦{calculateTakeHome(fees.chat).toLocaleString()}</span>
								</div>
							</div>
						</div>

						<!-- Video Consultation -->
						<div class="border border-gray-200 rounded-lg p-4">
							<label for="fee-video" class="block text-sm font-medium text-gray-700 mb-2">
								Video Consultation
							</label>
							<div class="relative mb-3">
								<span class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500">₦</span>
								<input
									id="fee-video"
									type="number"
									bind:value={fees.video}
									min="0"
									step="100"
									class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
								/>
							</div>
							<div class="space-y-2 text-xs">
								<div class="flex justify-between items-center py-2 px-3 bg-green-50 rounded">
									<span class="text-gray-600">Your Take Home (after 10% platform fee):</span>
									<span class="font-semibold text-green-700">₦{calculateTakeHome(fees.video).toLocaleString()}</span>
								</div>
							</div>
						</div>

						<!-- Audio Consultation -->
						<div class="border border-gray-200 rounded-lg p-4">
							<label for="fee-audio" class="block text-sm font-medium text-gray-700 mb-2">
								Audio Consultation
							</label>
							<div class="relative mb-3">
								<span class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500">₦</span>
								<input
									id="fee-audio"
									type="number"
									bind:value={fees.audio}
									min="0"
									step="100"
									class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
								/>
							</div>
							<div class="space-y-2 text-xs">
								<div class="flex justify-between items-center py-2 px-3 bg-green-50 rounded">
									<span class="text-gray-600">Your Take Home (after 10% platform fee):</span>
									<span class="font-semibold text-green-700">₦{calculateTakeHome(fees.audio).toLocaleString()}</span>
								</div>
							</div>
						</div>

						<!-- Office Visit -->
						<div class="border border-gray-200 rounded-lg p-4">
							<label for="fee-office" class="block text-sm font-medium text-gray-700 mb-2">
								Office Visit
							</label>
							<div class="relative mb-3">
								<span class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500">₦</span>
								<input
									id="fee-office"
									type="number"
									bind:value={fees.office_visit}
									min="0"
									step="100"
									class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
								/>
							</div>
							<div class="space-y-2 text-xs">
								<div class="flex justify-between items-center py-2 px-3 bg-green-50 rounded">
									<span class="text-gray-600">Your Take Home (after 10% platform fee):</span>
									<span class="font-semibold text-green-700">₦{calculateTakeHome(fees.office_visit).toLocaleString()}</span>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Work Schedule Section -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between mb-4">
						<div class="flex items-center gap-3">
							<div class="p-2 bg-primary-100 rounded-lg">
								<Clock class="h-5 w-5 text-primary-600" />
							</div>
							<h2 class="text-xl font-semibold text-gray-900">Work Schedule</h2>
						</div>
						<button
							onclick={saveSchedule}
							disabled={savingSchedule}
							class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
						>
							<Save class="h-4 w-4" />
							{savingSchedule ? 'Saving...' : 'Save Schedule'}
						</button>
					</div>

					<p class="text-sm text-gray-600 mb-2">Set your available working hours for each day of the week</p>
					<p class="text-xs text-gray-500 mb-6">Days configured: {schedule.length}</p>

					{#if schedule && schedule.length > 0}
						<div class="space-y-4">
							{#each schedule as day, index}
							<div class="flex flex-col sm:flex-row sm:items-center gap-4 p-4 border border-gray-200 rounded-lg {day.enabled ? 'bg-gray-50' : 'bg-white'}">
								<!-- Day Toggle -->
								<div class="flex items-center gap-3 sm:w-40">
									<input
										type="checkbox"
										checked={day.enabled}
										onchange={() => toggleDay(index)}
										class="w-5 h-5 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
									/>
									<label class="text-sm font-medium text-gray-900 select-none">
										{day.day}
									</label>
								</div>

								<!-- Time Inputs -->
								{#if day.enabled}
									<div class="flex items-center gap-4 flex-1">
										<div class="flex-1">
											<label class="text-xs text-gray-600 mb-1 block">Start Time</label>
											<input
												type="time"
												bind:value={day.startTime}
												class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 text-sm"
											/>
										</div>
										<span class="text-gray-400 mt-5">—</span>
										<div class="flex-1">
											<label class="text-xs text-gray-600 mb-1 block">End Time</label>
											<input
												type="time"
												bind:value={day.endTime}
												class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 text-sm"
											/>
										</div>
									</div>
								{:else}
									<div class="flex-1 text-sm text-gray-400 italic">
										Not available
									</div>
								{/if}
							</div>
						{/each}
					</div>
				{:else}
					<p class="text-gray-500 text-sm">Loading schedule...</p>
				{/if}
				</div>

				<!-- Time Slot Settings Section -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between mb-4">
						<div class="flex items-center gap-3">
							<div class="p-2 bg-primary-100 rounded-lg">
								<Clock class="h-5 w-5 text-primary-600" />
							</div>
							<h2 class="text-xl font-semibold text-gray-900">Time Slot Settings</h2>
						</div>
						<button
							onclick={saveSlotSettings}
							disabled={savingSlots}
							class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
						>
							<Save class="h-4 w-4" />
							{savingSlots ? 'Saving...' : 'Save Settings'}
						</button>
					</div>

					<p class="text-sm text-gray-600 mb-6">Configure appointment slot duration and buffer times</p>

					<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
						<!-- Slot Duration -->
						<div>
							<label for="slot-duration" class="block text-sm font-medium text-gray-700 mb-2">
								Appointment Duration
							</label>
							<select
								id="slot-duration"
								bind:value={slotDuration}
								class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							>
								<option value={15}>15 minutes</option>
								<option value={30}>30 minutes</option>
								<option value={45}>45 minutes</option>
								<option value={60}>1 hour</option>
								<option value={90}>1.5 hours</option>
								<option value={120}>2 hours</option>
							</select>
							<p class="mt-1 text-xs text-gray-500">Default duration for each consultation slot</p>
						</div>

						<!-- Buffer Time -->
						<div>
							<label for="buffer-time" class="block text-sm font-medium text-gray-700 mb-2">
								Buffer Time Between Appointments
							</label>
							<select
								id="buffer-time"
								bind:value={bufferTime}
								class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							>
								<option value={0}>No buffer</option>
								<option value={5}>5 minutes</option>
								<option value={10}>10 minutes</option>
								<option value={15}>15 minutes</option>
								<option value={30}>30 minutes</option>
							</select>
							<p class="mt-1 text-xs text-gray-500">Time gap between consecutive appointments</p>
						</div>
					</div>

					<!-- Slot Preview -->
					<div class="mt-6 p-4 bg-gray-50 rounded-lg border border-gray-200">
						<h3 class="text-sm font-medium text-gray-700 mb-2">Slot Preview</h3>
						<p class="text-xs text-gray-600">
							With current settings, your appointment slots will be:
						</p>
						<div class="mt-3 flex flex-wrap gap-2">
							{#each Array(4) as _, i}
								{@const startMinutes = i * (slotDuration + bufferTime)}
								{@const endMinutes = startMinutes + slotDuration}
								{@const startHour = Math.floor(startMinutes / 60) + 9}
								{@const startMin = startMinutes % 60}
								{@const endHour = Math.floor(endMinutes / 60) + 9}
								{@const endMin = endMinutes % 60}
								<span class="px-3 py-1.5 bg-white border border-gray-300 rounded text-xs font-medium text-gray-700">
									{String(startHour).padStart(2, '0')}:{String(startMin).padStart(2, '0')} - {String(endHour).padStart(2, '0')}:{String(endMin).padStart(2, '0')}
								</span>
							{/each}
							<span class="text-xs text-gray-400 self-center">...</span>
						</div>
					</div>
				</div>

				<!-- Notifications Section -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center gap-3 mb-4">
						<div class="p-2 bg-primary-100 rounded-lg">
							<Bell class="h-5 w-5 text-primary-600" />
						</div>
						<h2 class="text-xl font-semibold text-gray-900">Notifications</h2>
					</div>
					<p class="text-gray-600">Notification preferences coming soon...</p>
				</div>

				<!-- Security Section -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center gap-3 mb-4">
						<div class="p-2 bg-primary-100 rounded-lg">
							<Shield class="h-5 w-5 text-primary-600" />
						</div>
						<h2 class="text-xl font-semibold text-gray-900">Security</h2>
					</div>
					<p class="text-gray-600">Password and security settings coming soon...</p>
				</div>
			</div>

			<!-- Profile Edit Modal -->
			<Modal bind:open={showProfileModal} title="Edit Profile" onClose={() => (showProfileModal = false)}>
				{#snippet children()}
					<form onsubmit={(e) => { e.preventDefault(); saveProfile(); }} class="space-y-4">
						<!-- Profile Picture Upload -->
						<FileUpload
							label="Profile Picture"
							accept="image/*"
							maxSize={2097152}
							bind:file={profilePicFile}
							bind:previewUrl={profilePicPreview}
							onFileSelect={(file) => (profilePicFile = file)}
						/>

						<!-- Full Name -->
						<div>
							<label for="full_name" class="block text-sm font-medium text-gray-700 mb-2">
								Full Name *
							</label>
							<input
								id="full_name"
								type="text"
								bind:value={profileForm.full_name}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Email -->
						<div>
							<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
								Email *
							</label>
							<input
								id="email"
								type="email"
								bind:value={profileForm.email}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Phone -->
						<div>
							<label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
								Phone *
							</label>
							<input
								id="phone"
								type="tel"
								bind:value={profileForm.phone}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Specialization -->
						<div>
							<label for="specialization" class="block text-sm font-medium text-gray-700 mb-2">
								Specialization *
							</label>
							<input
								id="specialization"
								type="text"
								bind:value={profileForm.specialization}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Sub-specialty -->
						<div>
							<label for="sub_specialty" class="block text-sm font-medium text-gray-700 mb-2">
								Sub-specialty
							</label>
							<input
								id="sub_specialty"
								type="text"
								bind:value={profileForm.sub_specialty}
								placeholder="e.g., Pediatric Cardiology"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Preferred Languages -->
						<div>
							<label for="languages" class="block text-sm font-medium text-gray-700 mb-2">
								Preferred Languages
							</label>
							<input
								id="languages"
								type="text"
								bind:value={profileForm.preferred_languages}
								placeholder="e.g., English, Yoruba, Hausa"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
							<p class="text-xs text-gray-500 mt-1">Separate multiple languages with commas</p>
						</div>

						<!-- Actions -->
						<div class="flex gap-4 pt-4">
							<button
								type="button"
								onclick={() => (showProfileModal = false)}
								class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
							>
								Cancel
							</button>
							<button
								type="submit"
								disabled={savingProfile}
								class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{savingProfile ? 'Saving...' : 'Save Changes'}
							</button>
						</div>
					</form>
				{/snippet}
			</Modal>

			<!-- Address Edit Modal -->
			<Modal bind:open={showAddressModal} title="Edit Address" onClose={() => (showAddressModal = false)}>
				{#snippet children()}
					<form onsubmit={(e) => { e.preventDefault(); saveAddress(); }} class="space-y-4">
						<!-- Country -->
						<div>
							<label for="country" class="block text-sm font-medium text-gray-700 mb-2">
								Country *
							</label>
							<input
								id="country"
								type="text"
								bind:value={addressForm.country}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Region/State -->
						<div>
							<label for="region" class="block text-sm font-medium text-gray-700 mb-2">
								State/Region *
							</label>
							<input
								id="region"
								type="text"
								bind:value={addressForm.region}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- City -->
						<div>
							<label for="city" class="block text-sm font-medium text-gray-700 mb-2">
								City *
							</label>
							<input
								id="city"
								type="text"
								bind:value={addressForm.city}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Street -->
						<div>
							<label for="street" class="block text-sm font-medium text-gray-700 mb-2">
								Street Address *
							</label>
							<textarea
								id="street"
								bind:value={addressForm.street}
								required
								rows="2"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							></textarea>
						</div>

						<!-- Actions -->
						<div class="flex gap-4 pt-4">
							<button
								type="button"
								onclick={() => (showAddressModal = false)}
								class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
							>
								Cancel
							</button>
							<button
								type="submit"
								disabled={savingAddress}
								class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{savingAddress ? 'Saving...' : 'Save Address'}
							</button>
						</div>
					</form>
				{/snippet}
			</Modal>

			<!-- Work Experience Modal -->
			<Modal bind:open={showWorkExperienceModal} title="Add Work Experience" onClose={() => (showWorkExperienceModal = false)}>
				{#snippet children()}
					<form onsubmit={(e) => { e.preventDefault(); saveWorkExperience(); }} class="space-y-4">
						<!-- Position -->
						<div>
							<label for="position" class="block text-sm font-medium text-gray-700 mb-2">
								Position/Role *
							</label>
							<input
								id="position"
								type="text"
								bind:value={workExpForm.position}
								required
								placeholder="e.g., General Practitioner"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Organization -->
						<div>
							<label for="organization" class="block text-sm font-medium text-gray-700 mb-2">
								Organization *
							</label>
							<input
								id="organization"
								type="text"
								bind:value={workExpForm.organization}
								required
								placeholder="e.g., Lagos University Teaching Hospital"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Location -->
						<div>
							<label for="location" class="block text-sm font-medium text-gray-700 mb-2">
								Location
							</label>
							<input
								id="location"
								type="text"
								bind:value={workExpForm.location}
								placeholder="e.g., Lagos, Nigeria"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Start Date -->
						<div>
							<label for="start_date" class="block text-sm font-medium text-gray-700 mb-2">
								Start Date *
							</label>
							<input
								id="start_date"
								type="date"
								bind:value={workExpForm.start_date}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Current Position Checkbox -->
						<div class="flex items-center gap-2">
							<input
								id="is_current"
								type="checkbox"
								bind:checked={workExpForm.is_current}
								class="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
							/>
							<label for="is_current" class="text-sm text-gray-700">
								I currently work here
							</label>
						</div>

						<!-- End Date -->
						{#if !workExpForm.is_current}
							<div>
								<label for="end_date" class="block text-sm font-medium text-gray-700 mb-2">
									End Date *
								</label>
								<input
									id="end_date"
									type="date"
									bind:value={workExpForm.end_date}
									required={!workExpForm.is_current}
									class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
								/>
							</div>
						{/if}

						<!-- Description -->
						<div>
							<label for="description" class="block text-sm font-medium text-gray-700 mb-2">
								Description
							</label>
							<textarea
								id="description"
								bind:value={workExpForm.description}
								rows="3"
								placeholder="Describe your responsibilities and achievements..."
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							></textarea>
						</div>

						<!-- Actions -->
						<div class="flex gap-4 pt-4">
							<button
								type="button"
								onclick={() => (showWorkExperienceModal = false)}
								class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
							>
								Cancel
							</button>
							<button
								type="submit"
								disabled={savingWorkExp}
								class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{savingWorkExp ? 'Saving...' : 'Add Experience'}
							</button>
						</div>
					</form>
				{/snippet}
			</Modal>

			<!-- Certificate Modal -->
			<Modal bind:open={showCertificateModal} title="Add Certificate" onClose={() => (showCertificateModal = false)}>
				{#snippet children()}
					<form onsubmit={(e) => { e.preventDefault(); saveCertificate(); }} class="space-y-4">
						<!-- Certificate Name -->
						<div>
							<label for="cert_name" class="block text-sm font-medium text-gray-700 mb-2">
								Certificate Name *
							</label>
							<input
								id="cert_name"
								type="text"
								bind:value={certForm.certificate_name}
								required
								placeholder="e.g., Advanced Cardiac Life Support (ACLS)"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Issuing Organization -->
						<div>
							<label for="cert_org" class="block text-sm font-medium text-gray-700 mb-2">
								Issuing Organization *
							</label>
							<input
								id="cert_org"
								type="text"
								bind:value={certForm.issuing_organization}
								required
								placeholder="e.g., American Heart Association"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Issue Date -->
						<div>
							<label for="cert_issue_date" class="block text-sm font-medium text-gray-700 mb-2">
								Issue Date *
							</label>
							<input
								id="cert_issue_date"
								type="date"
								bind:value={certForm.issue_date}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Expiry Date -->
						<div>
							<label for="cert_expiry" class="block text-sm font-medium text-gray-700 mb-2">
								Expiry Date (Optional)
							</label>
							<input
								id="cert_expiry"
								type="date"
								bind:value={certForm.expiry_date}
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Certificate Number -->
						<div>
							<label for="cert_number" class="block text-sm font-medium text-gray-700 mb-2">
								Certificate Number
							</label>
							<input
								id="cert_number"
								type="text"
								bind:value={certForm.certificate_number}
								placeholder="e.g., CERT-2024-12345"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- File Upload -->
						<FileUpload
							label="Certificate File (PDF or Image) *"
							accept="application/pdf,image/*"
							maxSize={5242880}
							preview={false}
							bind:file={certFile}
							bind:previewUrl={certFilePreview}
							onFileSelect={(file) => (certFile = file)}
						/>

						<!-- Actions -->
						<div class="flex gap-4 pt-4">
							<button
								type="button"
								onclick={() => (showCertificateModal = false)}
								class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
							>
								Cancel
							</button>
							<button
								type="submit"
								disabled={savingCertificate}
								class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{savingCertificate ? 'Uploading...' : 'Add Certificate'}
							</button>
						</div>
					</form>
				{/snippet}
			</Modal>

			<!-- License Modal -->
			<Modal bind:open={showLicenseModal} title="Add Professional License" onClose={() => (showLicenseModal = false)}>
				{#snippet children()}
					<form onsubmit={(e) => { e.preventDefault(); saveLicense(); }} class="space-y-4">
						<!-- License Type -->
						<div>
							<label for="license_type" class="block text-sm font-medium text-gray-700 mb-2">
								License Type *
							</label>
							<input
								id="license_type"
								type="text"
								bind:value={licenseForm.license_type}
								required
								placeholder="e.g., Medical Practitioner License"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- License Number -->
						<div>
							<label for="license_number" class="block text-sm font-medium text-gray-700 mb-2">
								License Number *
							</label>
							<input
								id="license_number"
								type="text"
								bind:value={licenseForm.license_number}
								required
								placeholder="e.g., MDCN/2024/12345"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Issuing Authority -->
						<div>
							<label for="issuing_authority" class="block text-sm font-medium text-gray-700 mb-2">
								Issuing Authority *
							</label>
							<input
								id="issuing_authority"
								type="text"
								bind:value={licenseForm.issuing_authority}
								required
								placeholder="e.g., Medical and Dental Council of Nigeria"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Country -->
						<div>
							<label for="license_country" class="block text-sm font-medium text-gray-700 mb-2">
								Country *
							</label>
							<input
								id="license_country"
								type="text"
								bind:value={licenseForm.country}
								required
								placeholder="e.g., Nigeria"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- State/Region -->
						<div>
							<label for="license_state" class="block text-sm font-medium text-gray-700 mb-2">
								State/Region
							</label>
							<input
								id="license_state"
								type="text"
								bind:value={licenseForm.state_region}
								placeholder="e.g., Lagos"
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Issue Date -->
						<div>
							<label for="license_issue_date" class="block text-sm font-medium text-gray-700 mb-2">
								Issue Date *
							</label>
							<input
								id="license_issue_date"
								type="date"
								bind:value={licenseForm.issue_date}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Expiry Date -->
						<div>
							<label for="license_expiry_date" class="block text-sm font-medium text-gray-700 mb-2">
								Expiry Date *
							</label>
							<input
								id="license_expiry_date"
								type="date"
								bind:value={licenseForm.expiry_date}
								required
								class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- File Upload -->
						<FileUpload
							label="License File (PDF or Image) *"
							accept="application/pdf,image/*"
							maxSize={5242880}
							preview={false}
							bind:file={licenseFile}
							bind:previewUrl={licenseFilePreview}
							onFileSelect={(file) => (licenseFile = file)}
						/>

						<!-- Actions -->
						<div class="flex gap-4 pt-4">
							<button
								type="button"
								onclick={() => (showLicenseModal = false)}
								class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
							>
								Cancel
							</button>
							<button
								type="submit"
								disabled={savingLicense}
								class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{savingLicense ? 'Uploading...' : 'Add License'}
							</button>
						</div>
					</form>
				{/snippet}
			</Modal>
		{/if}
	</div>
</div>
