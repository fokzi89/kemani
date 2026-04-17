<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Plus, Search, User, Calendar, Edit, Copy, Trash2, X } from 'lucide-svelte';
	import Modal from '$lib/components/Modal.svelte';
	import FileUpload from '$lib/components/FileUpload.svelte';

	let provider = $state(null);
	let patients = $state([]);
	let loading = $state(true);
	let searchQuery = $state('');

	// Pagination state
	let currentPage = $state(1);
	let pageSize = 10;
	let totalCount = $state(0);
	let totalPages = $derived(Math.ceil(totalCount / pageSize));

	// Modal states
	let showAddModal = $state(false);
	let showEditModal = $state(false);
	let selectedPatient = $state(null);

	// Form states
	let patientForm = $state({
		full_name: '',
		email: '',
		phone: '',
		date_of_birth: '',
		gender: ''
	});

	// Profile picture upload
	let profilePicFile = $state<File | null>(null);
	let profilePicPreview = $state('');

	// Loading states
	let savingPatient = $state(false);
	let deletingPatientId = $state<string | null>(null);

	let searchTimeout: any;
	$effect(() => {
		// Debounce search and reset to page 1
		if (searchQuery !== undefined) {
			clearTimeout(searchTimeout);
			searchTimeout = setTimeout(() => {
				currentPage = 1;
				if (provider) loadPatients(provider.id);
			}, 400);
		}
	});

	$effect(() => {
		// Load when page changes
		if (currentPage > 0 && provider) {
			loadPatients(provider.id);
		}
	});

	onMount(async () => {
		const { data } = await supabase.auth.getSession();
		const session = data?.session;

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

		if (provider) {
			await loadPatients(provider.id);
		}

		loading = false;
	});

	async function loadPatients(providerId: string, silent = false) {
		if (!silent) loading = true;

		try {
			const start = (currentPage - 1) * pageSize;
			const end = start + pageSize - 1;

			// Build query
			let query = supabase
				.from('patients')
				.select('*', { count: 'exact' })
				.eq('healthcare_provider_id', providerId)
				.eq('is_deleted', false);

			if (searchQuery) {
				query = query.or(
					`full_name.ilike.%${searchQuery}%,email.ilike.%${searchQuery}%,phone.ilike.%${searchQuery}%`
				);
			}

			const { data: patientsData, count, error: fetchError } = await query
				.order('created_at', { ascending: false })
				.range(start, end);

			if (fetchError) throw fetchError;

			totalCount = count || 0;

			// Get consultation counts for each patient
			// We use Promise.all but catch individual errors to prevent the whole page from hanging
			const patientsWithStats = await Promise.all(
				(patientsData || []).map(async (patient) => {
					try {
						const { count: consultCount } = await supabase
							.from('consultations')
							.select('*', { count: 'exact', head: true })
							.eq('healthcare_patient_id', patient.id);

						const { data: lastConsult } = await supabase
							.from('consultations')
							.select('created_at, type')
							.eq('healthcare_patient_id', patient.id)
							.order('created_at', { ascending: false })
							.limit(1)
							.maybeSingle();

						return {
							...patient,
							total_consultations: consultCount || 0,
							last_consultation: lastConsult?.created_at,
							last_consultation_type: lastConsult?.type
						};
					} catch (e) {
						console.error(`Error loading stats for patient ${patient.id}:`, e);
						return { ...patient, total_consultations: 0 };
					}
				})
			);

			patients = patientsWithStats;
		} catch (err: any) {
			console.error('Error in loadPatients:', err);
		} finally {
			loading = false;
		}
	}

	function openAddModal() {
		patientForm = {
			full_name: '',
			email: '',
			phone: '',
			date_of_birth: '',
			gender: ''
		};
		profilePicFile = null;
		profilePicPreview = '';
		showAddModal = true;
	}

	function openEditModal(patient: any) {
		selectedPatient = patient;
		patientForm = {
			full_name: patient.full_name || '',
			email: patient.email || '',
			phone: patient.phone || '',
			date_of_birth: patient.date_of_birth || '',
			gender: patient.gender || ''
		};
		profilePicFile = null;
		profilePicPreview = patient.profile_photo_url || '';
		showEditModal = true;
	}

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

	async function deleteFileFromStorage(url: string) {
		if (!url) return;

		try {
			const urlParts = url.split('/');
			const filePath = urlParts.slice(urlParts.indexOf('patient-profiles')).join('/');

			await supabase.storage
				.from('patient-profile-pictures')
				.remove([filePath]);
		} catch (err) {
			console.error('Error deleting file:', err);
		}
	}

	async function savePatient() {
		if (!provider) {
			alert('Error: Health provider profile not loaded. Please refresh the page or contact support.');
			return;
		}

		console.log('Saving patient...', patientForm);
		savingPatient = true;

		try {
			let profilePhotoUrl = '';

			// Upload profile picture if selected
			if (profilePicFile) {
				profilePhotoUrl = await uploadProfilePicture(profilePicFile);
			}

			// Create patient in the new patients table
			const { data: newPatient, error } = await supabase
				.from('patients')
				.insert({
					healthcare_provider_id: provider.id,
					full_name: patientForm.full_name,
					email: patientForm.email || null,
					phone: patientForm.phone,
					date_of_birth: patientForm.date_of_birth || null,
					gender: patientForm.gender || null,
					profile_photo_url: profilePhotoUrl || null,
					is_deleted: false
				})
				.select()
				.single();

			if (error) throw error;

			await loadPatients(provider.id);
			showAddModal = false;
			profilePicFile = null;
			alert('Patient added successfully!');
		} catch (err: any) {
			console.error('Detailed error saving patient:', err);
			alert(`Failed to add patient: ${err.message}`);
		} finally {
			savingPatient = false;
		}
	}

	async function updatePatient() {
		if (!provider || !selectedPatient) return;

		console.log('Updating patient:', selectedPatient.id);
		savingPatient = true;

		try {
			let profilePhotoUrl = selectedPatient.profile_photo_url;

			// Upload new profile picture if selected
			if (profilePicFile) {
				if (profilePhotoUrl) {
					await deleteFileFromStorage(profilePhotoUrl);
				}
				profilePhotoUrl = await uploadProfilePicture(profilePicFile);
			}

			// Update patient
			const { error: updateError } = await supabase
				.from('patients')
				.update({
					full_name: patientForm.full_name,
					email: patientForm.email || null,
					phone: patientForm.phone,
					date_of_birth: patientForm.date_of_birth || null,
					gender: patientForm.gender || null,
					profile_photo_url: profilePhotoUrl || null,
					updated_at: new Date().toISOString()
				})
				.eq('id', selectedPatient.id);

			if (updateError) throw updateError;

			// Close modal FIRST for better UI feel
			showEditModal = false;
			alert('Patient updated successfully!');
			
			// Refresh list in background
			loadPatients(provider.id, true);
			
			selectedPatient = null;
			profilePicFile = null;
		} catch (err: any) {
			console.error('Detailed error updating patient:', err);
			const msg = err.message || err.details || 'Unknown error';
			alert('Failed to update patient: ' + msg);
		} finally {
			savingPatient = false;
		}
	}

	async function copyPatientInfo(patient: any) {
		const info = `Name: ${patient.full_name}
Email: ${patient.email || 'N/A'}
Phone: ${patient.phone || 'N/A'}`;

		try {
			await navigator.clipboard.writeText(info);
			alert('Patient information copied to clipboard!');
		} catch (err) {
			console.error('Failed to copy:', err);
			alert('Failed to copy patient information');
		}
	}

	async function deletePatient(patientId: string) {
		if (!confirm('Are you sure you want to delete this patient? This action can be undone by contacting support.')) {
			return;
		}

		console.log('Deleting patient:', patientId);
		deletingPatientId = patientId;

		try {
			// Soft delete: set is_deleted to true
			const { error: deleteError } = await supabase
				.from('patients')
				.update({
					is_deleted: true,
					deleted_at: new Date().toISOString(),
					updated_at: new Date().toISOString()
				})
				.eq('id', patientId);

			if (deleteError) throw deleteError;

			alert('Patient deleted successfully!');
			
			// Refresh list
			await loadPatients(provider.id, true);
		} catch (err: any) {
			console.error('Detailed error deleting patient:', err);
			const msg = err.message || err.details || 'Unknown error';
			alert('Failed to delete patient: ' + msg);
		} finally {
			deletingPatientId = null;
		}
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'Never';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}
</script>

<div class="min-h-screen p-4 lg:p-8 max-w-full overflow-hidden">
	<div class="max-w-7xl mx-auto space-y-6 min-w-0">
		<!-- Header -->
		<div class="bg-white rounded-lg shadow p-6 border border-gray-100">
			<div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
				<div class="min-w-0">
					<h2 class="text-2xl font-bold text-gray-900 truncate">My Patients</h2>
					<p class="text-gray-600 mt-1 line-clamp-1">Manage your patient records and consultations</p>
				</div>
				<a
					href="/patients/add"
					class="px-5 py-2.5 bg-gray-900 hover:bg-black text-white rounded-xl transition-all flex items-center justify-center gap-2 shadow-sm active:scale-95 whitespace-nowrap shrink-0"
				>
					<Plus class="h-5 w-5" />
					Add Patient
				</a>
			</div>
		</div>

		<!-- Search -->
		<div class="bg-white rounded-lg shadow p-4">
			<div class="relative">
				<Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
				<input
					type="text"
					bind:value={searchQuery}
					placeholder="Search patients by name, email, or phone..."
					class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
				/>
			</div>
		</div>

		<!-- Patients Table -->
		{#if loading}
			<div class="bg-white rounded-lg shadow p-12 text-center">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
				<p class="mt-4 text-gray-600">Loading patients...</p>
			</div>
		{:else if patients.length === 0}
			<div class="bg-white rounded-lg shadow border border-gray-100 p-12 text-center">
				<User class="h-16 w-16 text-gray-300 mx-auto mb-4" />
				<h3 class="text-lg font-medium text-gray-900 mb-2">
					{searchQuery ? 'No patients found' : 'No patients yet'}
				</h3>
				<p class="text-gray-600 mb-6">
					{searchQuery
						? 'Try adjusting your search terms'
						: 'Add your first patient to get started'}
				</p>
				{#if !searchQuery}
					<a
						href="/patients/add"
						class="px-8 py-3 bg-primary-600 text-white rounded-xl hover:bg-primary-700 transition-all inline-flex items-center gap-2 shadow-md hover:shadow-lg active:scale-95"
					>
						<Plus class="h-5 w-5" />
						Add First Patient
					</a>
				{/if}
			</div>
		{:else}
			<div class="space-y-4">
				<div class="bg-white rounded-lg shadow border border-gray-200 overflow-hidden">
					<div class="overflow-x-auto scrollbar-thin scrollbar-thumb-gray-300">
						<table class="w-full min-w-[800px]">
							<thead class="bg-gray-50 border-b border-gray-200">
								<tr>
									<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Patient
									</th>
									<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Contact
									</th>
									<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Consultations
									</th>
									<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Last Visit
									</th>
									<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Added On
									</th>
									<th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
										Actions
									</th>
								</tr>
							</thead>
							<tbody class="bg-white divide-y divide-gray-200">
								{#each patients as patient}
									<tr class="hover:bg-gray-50 transition-colors">
										<td class="px-6 py-4 whitespace-nowrap">
											<div class="flex items-center gap-3">
												{#if patient.profile_photo_url}
													<img
														src={patient.profile_photo_url}
														alt={patient.full_name}
														class="h-10 w-10 rounded-full object-cover shadow-sm ring-2 ring-gray-50"
													/>
												{:else}
													<div class="h-10 w-10 rounded-full bg-primary-50 flex items-center justify-center">
														<User class="h-5 w-5 text-primary-600" />
													</div>
												{/if}
												<div>
													<div class="text-sm font-semibold text-gray-900">{patient.full_name}</div>
													{#if patient.gender}
														<div class="text-xs text-gray-500 capitalize">{patient.gender}</div>
													{/if}
												</div>
											</div>
										</td>
										<td class="px-6 py-4">
											<div class="text-sm text-gray-900 font-medium">{patient.phone || 'N/A'}</div>
											<div class="text-sm text-gray-500">{patient.email || 'No email'}</div>
										</td>
										<td class="px-6 py-4 whitespace-nowrap text-center">
											<div class="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-gray-100 text-gray-700 font-medium text-xs">
												<Calendar class="h-3 w-3" />
												{patient.total_consultations}
											</div>
										</td>
										<td class="px-6 py-4 whitespace-nowrap">
											<div class="text-sm text-gray-900 font-medium">{formatDate(patient.last_consultation)}</div>
											{#if patient.last_consultation_type}
												<div class="text-xs text-gray-400 capitalize">{patient.last_consultation_type}</div>
											{/if}
										</td>
										<td class="px-6 py-4 whitespace-nowrap">
											<div class="text-sm text-gray-600 font-medium">{formatDate(patient.created_at)}</div>
										</td>
										<td class="px-6 py-4 whitespace-nowrap text-right">
											<div class="flex items-center justify-end gap-1">
												<button
													onclick={() => openEditModal(patient)}
													class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
													title="Edit patient"
													type="button"
												>
													<Edit class="h-4 w-4" />
												</button>
												<button
													onclick={() => copyPatientInfo(patient)}
													class="p-2 text-gray-500 hover:bg-gray-100 rounded-lg transition-colors"
													title="Copy patient info"
													type="button"
												>
													<Copy class="h-4 w-4" />
												</button>
												<button
													onclick={() => deletePatient(patient.id)}
													disabled={deletingPatientId === patient.id}
													class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50"
													title="Delete patient"
													type="button"
												>
													<Trash2 class="h-4 w-4" />
												</button>
											</div>
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				</div>

				<!-- Pagination -->
				{#if totalPages > 1}
					<div class="bg-white px-4 py-3 flex items-center justify-between border border-gray-200 rounded-lg sm:px-6">
						<div class="flex-1 flex justify-between sm:hidden">
							<button
								onclick={() => currentPage = Math.max(1, currentPage - 1)}
								disabled={currentPage === 1}
								class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
							>
								Previous
							</button>
							<button
								onclick={() => currentPage = Math.min(totalPages, currentPage + 1)}
								disabled={currentPage === totalPages}
								class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
							>
								Next
							</button>
						</div>
						<div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
							<div>
								<p class="text-sm text-gray-700">
									Showing
									<span class="font-bold">{(currentPage - 1) * pageSize + 1}</span>
									to
									<span class="font-bold">{Math.min(currentPage * pageSize, totalCount)}</span>
									of
									<span class="font-bold">{totalCount}</span>
									results
								</p>
							</div>
							<div>
								<nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
									<button
										onclick={() => currentPage = Math.max(1, currentPage - 1)}
										disabled={currentPage === 1}
										class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
									>
										<span class="sr-only">Previous</span>
										<ArrowLeft class="h-5 w-5" />
									</button>
									
									{#each Array(totalPages) as _, i}
										<button
											onclick={() => currentPage = i + 1}
											class="relative inline-flex items-center px-4 py-2 border {currentPage === i + 1 ? 'z-10 bg-primary-50 border-primary-500 text-primary-600' : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'} text-sm font-medium"
										>
											{i + 1}
										</button>
									{/each}

									<button
										onclick={() => currentPage = Math.min(totalPages, currentPage + 1)}
										disabled={currentPage === totalPages}
										class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
									>
										<span class="sr-only">Next</span>
										<ArrowLeft class="h-5 w-5 rotate-180" />
									</button>
								</nav>
							</div>
						</div>
					</div>
				{/if}
			</div>
		{/if}
	</div>
</div>

<!-- Add Patient Modal -->
<Modal bind:open={showAddModal} title="Add New Patient" onClose={() => (showAddModal = false)}>
	{#snippet children()}
		<form onsubmit={(e) => { e.preventDefault(); savePatient(); }} class="space-y-4">
			<!-- Profile Picture Upload -->
			<FileUpload
				label="Profile Picture (Optional)"
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
					bind:value={patientForm.full_name}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Phone -->
			<div>
				<label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
					Phone Number *
				</label>
				<input
					id="phone"
					type="tel"
					bind:value={patientForm.phone}
					required
					placeholder="+234 XXX XXX XXXX"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Email -->
			<div>
				<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
					Email (Optional)
				</label>
				<input
					id="email"
					type="email"
					bind:value={patientForm.email}
					placeholder="patient@example.com"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>


			<!-- Date of Birth -->
			<div>
				<label for="dob" class="block text-sm font-medium text-gray-700 mb-2">
					Date of Birth (Optional)
				</label>
				<input
					id="dob"
					type="date"
					bind:value={patientForm.date_of_birth}
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Gender -->
			<div>
				<label for="gender" class="block text-sm font-medium text-gray-700 mb-2">
					Gender (Optional)
				</label>
				<select
					id="gender"
					bind:value={patientForm.gender}
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				>
					<option value="">Select gender</option>
					<option value="male">Male</option>
					<option value="female">Female</option>
				</select>
			</div>

			<!-- Actions -->
			<div class="flex gap-4 pt-4">
				<button
					type="button"
					onclick={() => (showAddModal = false)}
					class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
				>
					Cancel
				</button>
				<button
					type="submit"
					disabled={savingPatient}
					class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{savingPatient ? 'Adding...' : 'Add Patient'}
				</button>
			</div>
		</form>
	{/snippet}
</Modal>

<!-- Edit Patient Modal -->
<Modal bind:open={showEditModal} title="Edit Patient" onClose={() => (showEditModal = false)}>
	{#snippet children()}
		<form onsubmit={(e) => { e.preventDefault(); updatePatient(); }} class="space-y-4">
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
				<label for="edit_full_name" class="block text-sm font-medium text-gray-700 mb-2">
					Full Name *
				</label>
				<input
					id="edit_full_name"
					type="text"
					bind:value={patientForm.full_name}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Phone -->
			<div>
				<label for="edit_phone" class="block text-sm font-medium text-gray-700 mb-2">
					Phone Number *
				</label>
				<input
					id="edit_phone"
					type="tel"
					bind:value={patientForm.phone}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Email -->
			<div>
				<label for="edit_email" class="block text-sm font-medium text-gray-700 mb-2">
					Email (Optional)
				</label>
				<input
					id="edit_email"
					type="email"
					bind:value={patientForm.email}
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>


			<!-- Date of Birth -->
			<div>
				<label for="edit_dob" class="block text-sm font-medium text-gray-700 mb-2">
					Date of Birth (Optional)
				</label>
				<input
					id="edit_dob"
					type="date"
					bind:value={patientForm.date_of_birth}
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Gender -->
			<div>
				<label for="edit_gender" class="block text-sm font-medium text-gray-700 mb-2">
					Gender (Optional)
				</label>
				<select
					id="edit_gender"
					bind:value={patientForm.gender}
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				>
					<option value="">Select gender</option>
					<option value="male">Male</option>
					<option value="female">Female</option>
				</select>
			</div>

			<!-- Actions -->
			<div class="flex gap-4 pt-4">
				<button
					type="button"
					onclick={() => (showEditModal = false)}
					class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
				>
					Cancel
				</button>
				<button
					type="submit"
					disabled={savingPatient}
					class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{savingPatient ? 'Saving...' : 'Save Changes'}
				</button>
			</div>
		</form>
	{/snippet}
</Modal>
