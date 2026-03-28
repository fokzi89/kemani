<script lang="ts">
	import { onMount, tick } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { 
		ArrowLeft, Plus, Search, UserPlus, Save, CheckCircle2, 
		XCircle, Trash2, Edit, X, Calendar, Activity, UploadCloud,
		Stethoscope, ClipboardList, FlaskConical, Beaker
	} from 'lucide-svelte';

	let provider = $state<any>(null);
	let loading = $state(true);

	// Multi-tab State
	let activeTab = $state<'patient' | 'request'>('patient');

	// Patient Selection State
	let patientMode = $state<'existing' | 'new'>('existing');
	let existingPatients = $state<any[]>([]);
	let filteredPatients = $state<any[]>([]);
	let searchPatientQuery = $state('');
	let selectedPatient = $state<any>(null);

	// New Patient Form
	let newPatientForm = $state({
		full_name: '', phone: '', gender: 'Male', date_of_birth: ''
	});
	let isCreatingPatient = $state(false);

	// Lab Request State
	let clinicalNotes = $state('');
	let diagnosis = $state('');
	let priority = $state<'normal' | 'urgent' | 'emergency'>('normal');
	
	// Tests Selection State
	let selectedTests = $state<any[]>([]);
	let testCatalog = $state<any[]>([]);
	let searchTestQuery = $state('');
	let filteredCatalog = $state<any[]>([]);
	let testModalOpen = $state(false);

	// Submitting State
	let submitting = $state(false);
	let submitProgress = $state<any[]>([]);

	onMount(async () => {
		const { data } = await supabase.auth.getSession();
		const session = data?.session;
		if (session) {
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();
			provider = providerData;

			if (provider) {
				// Load patients
				const { data: ptData } = await supabase
					.from('patients')
					.select('id, full_name, phone, profile_photo_url, gender')
					.eq('healthcare_provider_id', provider.id)
					.order('full_name');
				existingPatients = ptData || [];
				filteredPatients = existingPatients;

				// Load diagnostic tests catalog
				const { data: testData } = await supabase
					.from('diagnostic_tests')
					.select('*')
					.eq('is_active', true)
					.order('name');
				testCatalog = testData || [];
				filteredCatalog = testCatalog;
			}
		}
		loading = false;
	});

	// Reactive filtering for patients
	$effect(() => {
		if (searchPatientQuery) {
			const q = searchPatientQuery.toLowerCase();
			filteredPatients = existingPatients.filter(p => 
				p.full_name?.toLowerCase().includes(q) || p.phone?.includes(q)
			);
		} else {
			filteredPatients = existingPatients;
		}
	});

	// Reactive filtering for tests
	$effect(() => {
		if (searchTestQuery) {
			const q = searchTestQuery.toLowerCase();
			filteredCatalog = testCatalog.filter(t => 
				t.name?.toLowerCase().includes(q) || t.code?.toLowerCase().includes(q) || t.category?.toLowerCase().includes(q)
			);
		} else {
			filteredCatalog = testCatalog;
		}
	});

	async function createNewPatient() {
		if (!provider) return alert('Provider profile not loaded');
		if (!newPatientForm.full_name || !newPatientForm.phone) return alert('Name and phone are required');
		
		isCreatingPatient = true;
		try {
			const { data, error } = await supabase.from('patients').insert({
				healthcare_provider_id: provider.id,
				full_name: newPatientForm.full_name,
				phone: newPatientForm.phone,
				gender: newPatientForm.gender,
				date_of_birth: newPatientForm.date_of_birth || null
			}).select().single();

			if (error) throw error;
			
			existingPatients = [...existingPatients, data];
			selectedPatient = data;
			patientMode = 'existing';
		} catch (err: any) {
			alert('Failed to create patient: ' + err.message);
		} finally {
			isCreatingPatient = false;
		}
	}

	function toggleTestSelection(test: any) {
		const exists = selectedTests.find(t => t.id === test.id);
		if (exists) {
			selectedTests = selectedTests.filter(t => t.id !== test.id);
		} else {
			selectedTests = [...selectedTests, test];
		}
	}

	function removeTest(testId: string) {
		selectedTests = selectedTests.filter(t => t.id !== testId);
	}

	async function submitRequest(status: 'pending' | 'draft' = 'pending') {
		if (!selectedPatient) return alert('Please select a patient first');
		if (selectedTests.length === 0) return alert('Please select at least one test');

		submitting = true;
		submitProgress = [];

		try {
			// 1. Create lab request entry
			const { data: requestData, error: requestErr } = await supabase.from('lab_requests').insert({
				healthcare_provider_id: provider.id,
				patient_id: selectedPatient.id,
				clinical_notes: clinicalNotes,
				diagnosis: diagnosis,
				priority: priority,
				status: status === 'draft' ? 'pending' : 'pending', // Currently mapping draft to pending for simplicity
				is_paid: false
			}).select().single();

			if (requestErr) throw requestErr;

			// 2. Insert request items
			for (let i = 0; i < selectedTests.length; i++) {
				const test = selectedTests[i];
				submitProgress = [...submitProgress, { name: test.name, status: 'uploading' }];
				
				const { error: itemErr } = await supabase.from('lab_request_items').insert({
					lab_request_id: requestData.id,
					diagnostic_test_id: test.id,
					status: 'pending'
				});

				const newProg = [...submitProgress];
				if (itemErr) {
					newProg[i].status = 'error';
					newProg[i].errorMsg = itemErr.message;
				} else {
					newProg[i].status = 'success';
				}
				submitProgress = newProg;
				await new Promise(r => setTimeout(r, 400));
			}

			if (submitProgress.some(p => p.status === 'error')) {
				alert('Lab request created, but some items failed to register.');
			} else {
				setTimeout(() => { goto('/lab-requests'); }, 1500);
			}

		} catch (err: any) {
			alert('Critical failure: ' + err.message);
			submitting = false;
		}
	}
</script>

<svelte:head>
	<title>Request Lab Test - Kemani</title>
</svelte:head>

<div class="min-h-screen p-4 sm:p-6 lg:p-8 bg-gray-50 pb-32">
	<div class="max-w-4xl mx-auto space-y-6">
		<!-- Header -->
		<div class="flex items-center gap-4">
			<a href="/lab-requests" class="p-2 bg-white rounded-lg shadow-sm border border-gray-100 hover:bg-gray-50 transition-colors">
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</a>
			<div>
				<h1 class="text-2xl font-bold text-gray-900 tracking-tight">Request Lab Test</h1>
				<p class="text-sm text-gray-500">Order diagnostic investigations for your patient</p>
			</div>
		</div>

		{#if loading}
			<div class="flex justify-center p-12"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div></div>
		{:else}
			<!-- Tab Navigation -->
			<div class="flex border-b border-gray-200 bg-white rounded-t-2xl px-6 pt-2 overflow-x-auto whitespace-nowrap scrollbar-hide">
				<button 
					onclick={() => activeTab = 'patient'}
					class="flex items-center gap-2 px-6 py-4 text-sm font-bold border-b-2 transition-all {activeTab === 'patient' ? 'border-purple-700 text-purple-700' : 'border-transparent text-gray-500 hover:text-gray-700'}"
				>
					<UserPlus class="h-4 w-4" /> Patient Details
				</button>
				<button 
					onclick={() => activeTab = 'request'}
					class="flex items-center gap-2 px-6 py-4 text-sm font-bold border-b-2 transition-all {activeTab === 'request' ? 'border-purple-700 text-purple-700' : 'border-transparent text-gray-500 hover:text-gray-700'}"
				>
					<FlaskConical class="h-4 w-4" /> Request Test ({selectedTests.length})
				</button>
			</div>

			<div class="bg-white rounded-b-2xl shadow-sm border border-t-0 border-gray-100 p-6 min-h-[400px]">
				{#if activeTab === 'patient'}
					<div class="space-y-8 animate-in fade-in slide-in-from-bottom-2 duration-300">
						<!-- Patient Selection -->
						<section>
							<h2 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
								<Stethoscope class="h-5 w-5 text-purple-600" /> Patient Selection
							</h2>

							<div class="flex gap-2 p-1 bg-gray-100/80 rounded-xl w-fit mb-6">
								<button onclick={() => patientMode = 'existing'} class="px-5 py-2 text-sm font-semibold rounded-lg transition-all {patientMode === 'existing' ? 'bg-white text-purple-800 shadow flex items-center gap-2' : 'text-gray-500 hover:text-gray-700'}">
									<Search class="h-4 w-4" /> Existing Patient
								</button>
								<button onclick={() => patientMode = 'new'} class="px-5 py-2 text-sm font-semibold rounded-lg transition-all {patientMode === 'new' ? 'bg-white text-purple-800 shadow flex items-center gap-2' : 'text-gray-500 hover:text-gray-700'}">
									<Plus class="h-4 w-4" /> New Patient
								</button>
							</div>

							{#if patientMode === 'existing'}
								<div class="space-y-4">
									{#if !selectedPatient}
										<div class="relative">
											<Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
											<input type="text" bind:value={searchPatientQuery} placeholder="Search by patient name or phone..." class="w-full pl-11 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-purple-600 transition-shadow" />
										</div>
										
										<div class="max-h-60 overflow-y-auto bg-white border border-gray-100 rounded-xl shadow-sm divide-y divide-gray-50">
											{#each filteredPatients as pt}
												<button onclick={() => selectedPatient = pt} class="w-full flex items-center gap-4 p-4 hover:bg-gray-50 transition-colors text-left text-gray-900">
													<div class="h-10 w-10 bg-purple-100 rounded-full flex items-center justify-center font-bold text-purple-700 shrink-0 uppercase">
														{pt.full_name[0]}
													</div>
													<div>
														<p class="font-semibold">{pt.full_name}</p>
														<p class="text-xs text-gray-500">{pt.phone}</p>
													</div>
												</button>
											{/each}
											{#if filteredPatients.length === 0}
												<div class="p-6 text-center text-sm text-gray-500 font-medium">No patients found correctly matching that query.</div>
											{/if}
										</div>
									{:else}
										<div class="flex items-center justify-between p-5 bg-purple-50/50 border border-purple-100 rounded-2xl">
											<div class="flex items-center gap-4">
												<div class="h-14 w-14 bg-purple-100 rounded-full flex items-center justify-center font-bold text-purple-700 border-4 border-white shadow-sm">
													<User class="h-7 w-7" />
												</div>
												<div>
													<p class="font-bold text-gray-900 text-lg uppercase tracking-tight">{selectedPatient.full_name}</p>
													<p class="text-sm text-gray-600">{selectedPatient.phone}</p>
												</div>
											</div>
											<button onclick={() => selectedPatient = null} class="text-sm font-bold text-red-600 hover:text-red-700 px-4 py-2 rounded-xl hover:bg-red-50 transition-colors">
												Change
											</button>
										</div>
									{/if}
								</div>
							{:else}
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-5 p-5 bg-gray-50 rounded-xl border border-gray-100">
									<div class="col-span-1">
										<label class="block text-sm font-bold text-gray-700 mb-1.5">Full Name</label>
										<input type="text" bind:value={newPatientForm.full_name} placeholder="John Doe" class="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl focus:ring-purple-500" />
									</div>
									<div class="col-span-1">
										<label class="block text-sm font-bold text-gray-700 mb-1.5">Phone Number</label>
										<input type="tel" bind:value={newPatientForm.phone} placeholder="e.g. 08012345678" class="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl focus:ring-purple-500" />
									</div>
									<div class="sm:col-span-2">
										<button onclick={createNewPatient} disabled={isCreatingPatient} class="w-full py-4 bg-purple-600 hover:bg-purple-700 text-white font-extrabold rounded-xl transition-all flex justify-center items-center gap-2 transform active:scale-[0.98]">
											{isCreatingPatient ? 'Creating Profile...' : 'Save Patient Profile'}
										</button>
									</div>
								</div>
							{/if}
						</section>

						<!-- Clinical Notes -->
						<section>
							<h2 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
								<ClipboardList class="h-5 w-5 text-purple-600" /> Clinical Context
							</h2>
							<div class="space-y-4">
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-bold text-gray-700 mb-1.5">Tentative Diagnosis</label>
										<input type="text" bind:value={diagnosis} placeholder="E.g., Fever of Unknown Origin" class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-purple-500" />
									</div>
									<div>
										<label class="block text-sm font-bold text-gray-700 mb-1.5">Priority</label>
										<select bind:value={priority} class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-purple-500 bg-white">
											<option value="normal">Normal</option>
											<option value="urgent">Urgent (STAT)</option>
											<option value="emergency">Emergency / Critical</option>
										</select>
									</div>
								</div>
								<div>
									<label class="block text-sm font-bold text-gray-700 mb-1.5">Clinical Notes / Presentations</label>
									<textarea bind:value={clinicalNotes} rows="4" placeholder="Briefly describe why this test is being requested..." class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-purple-500 resize-none"></textarea>
								</div>
							</div>
						</section>

						<div class="flex justify-end pt-4">
							<button 
								onclick={() => activeTab = 'request'}
								class="px-8 py-4 bg-purple-600 text-white font-extrabold rounded-xl hover:bg-purple-700 transition-all flex items-center gap-2 shadow-lg shadow-purple-100"
							>
								Next: Select Tests <ArrowLeft class="h-4 w-4 rotate-180" />
							</button>
						</div>
					</div>

				{:else if activeTab === 'request'}
					<div class="space-y-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
						<div class="flex items-center justify-between">
							<h2 class="text-lg font-bold text-gray-900">Select Investigations</h2>
							<button onclick={() => testModalOpen = true} class="px-5 py-2.5 bg-purple-100 text-purple-900 hover:bg-purple-200 font-extrabold rounded-xl transition-all flex items-center gap-2 text-sm shadow-sm">
								<Plus class="h-4 w-4 text-purple-700" /> Browse Catalog
							</button>
						</div>

						<!-- Selected Tests List -->
						<div class="space-y-3">
							{#if selectedTests.length === 0}
								<div class="text-center py-16 bg-gray-50 border-2 border-dashed border-gray-200 rounded-2xl">
									<FlaskConical class="h-12 w-12 text-gray-300 mx-auto mb-3" />
									<p class="text-sm font-bold text-gray-500 uppercase tracking-wider">No tests selected yet.</p>
									<button onclick={() => testModalOpen = true} class="mt-4 text-purple-700 font-extrabold text-sm hover:underline">Pick tests from catalog</button>
								</div>
							{:else}
								{#each selectedTests as test}
									<div class="flex items-center justify-between p-4 bg-white border-2 border-gray-100 rounded-2xl hover:border-purple-200 transition-all group">
										<div class="flex items-center gap-4">
											<div class="h-10 w-10 bg-purple-50 rounded-lg flex items-center justify-center text-purple-600">
												<Beaker class="h-5 w-5" />
											</div>
											<div>
												<p class="font-bold text-gray-900">{test.name}</p>
												<p class="text-xs text-gray-500 uppercase font-semibold">{test.category || 'General'}</p>
											</div>
										</div>
										<button onclick={() => removeTest(test.id)} class="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-xl transition-all">
											<Trash2 class="h-5 w-5" />
										</button>
									</div>
								{/each}
							{/if}
						</div>

						<div class="flex justify-between pt-4">
							<button 
								onclick={() => activeTab = 'patient'}
								class="px-6 py-3 text-gray-600 font-bold rounded-xl hover:bg-gray-100 transition-all flex items-center gap-2"
							>
								<ArrowLeft class="h-4 w-4" /> Back to Patient
							</button>
						</div>
					</div>
				{/if}
			</div>

			<!-- Sticky Bottom Bar -->
			<div class="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-md border-t p-4 z-40 border-gray-200">
				<div class="max-w-4xl mx-auto flex flex-col sm:flex-row gap-3">
					<button onclick={() => submitRequest('draft')} disabled={submitting} class="flex-1 px-6 py-4 bg-white border-2 border-gray-200 text-gray-700 font-bold rounded-2xl hover:bg-gray-50 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
						<Save class="h-5 w-5" /> Save as Draft
					</button>
					<button onclick={() => submitRequest('pending')} disabled={submitting} class="flex-[2] px-6 py-4 bg-purple-600 text-white font-extrabold rounded-2xl hover:bg-purple-700 transition-all shadow-xl shadow-purple-200 flex items-center justify-center gap-2 disabled:opacity-50">
						<CheckCircle2 class="h-5 w-5" /> {submitting ? 'Processing Request...' : 'Finalize & Send Request'}
					</button>
				</div>
			</div>
		{/if}
	</div>
</div>

<!-- Test Catalog Modal -->
{#if testModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-in fade-in">
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-2xl max-h-[85vh] overflow-hidden flex flex-col animate-in zoom-in-95">
			<div class="p-6 border-b flex items-center justify-between bg-white shrink-0">
				<div>
					<h3 class="text-xl font-extrabold text-gray-900 tracking-tight">Diagnostic Test Catalog</h3>
					<p class="text-xs text-gray-500">Select all tests required for this request</p>
				</div>
				<button onclick={() => testModalOpen = false} class="p-2.5 bg-gray-100 hover:bg-gray-200 rounded-2xl transition-all">
					<X class="h-5 w-5 text-gray-600" />
				</button>
			</div>

			<div class="p-6 bg-gray-50 shrink-0">
				<div class="relative">
					<Search class="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
					<input 
						type="text" 
						bind:value={searchTestQuery} 
						placeholder="Search for CBC, Widal, X-ray, MRI..." 
						class="w-full pl-12 pr-4 py-4 bg-white border-2 border-gray-200 rounded-2xl shadow-sm focus:ring-2 focus:ring-purple-500 transition-all font-medium"
					/>
				</div>
			</div>

			<div class="flex-1 overflow-y-auto p-6 space-y-2">
				{#each filteredCatalog as test}
					<button 
						onclick={() => toggleTestSelection(test)}
						class="w-full flex items-center justify-between p-4 rounded-2xl border-2 transition-all text-left {selectedTests.find(t => t.id === test.id) ? 'border-purple-600 bg-purple-50' : 'border-white bg-white hover:border-gray-100'}"
					>
						<div class="flex items-center gap-4">
							<div class="h-10 w-10 {selectedTests.find(t => t.id === test.id) ? 'bg-purple-600 text-white' : 'bg-gray-100 text-gray-500'} rounded-xl flex items-center justify-center transition-colors">
								<FlaskConical class="h-5 w-5" />
							</div>
							<div>
								<p class="font-extrabold text-gray-900">{test.name}</p>
								<div class="flex items-center gap-2 mt-0.5">
									{#if test.code}<span class="text-[10px] font-bold text-purple-600 uppercase bg-purple-100 px-1.5 py-0.5 rounded leading-none">{test.code}</span>{/if}
									<span class="text-[10px] font-semibold text-gray-400 uppercase tracking-wider">{test.category || 'General'}</span>
								</div>
							</div>
						</div>
						{#if selectedTests.find(t => t.id === test.id)}
							<CheckCircle2 class="h-6 w-6 text-purple-600" />
						{:else}
							<div class="h-6 w-6 border-2 border-gray-200 rounded-full"></div>
						{/if}
					</button>
				{/each}
				{#if filteredCatalog.length === 0}
					<div class="text-center py-12">
						<Search class="h-12 w-12 text-gray-200 mx-auto mb-3" />
						<p class="text-gray-500 font-bold">No tests found matching "{searchTestQuery}"</p>
					</div>
				{/if}
			</div>

			<div class="p-6 border-t bg-gray-50 flex justify-end shrink-0">
				<button onclick={() => testModalOpen = false} class="px-8 py-3 bg-purple-600 text-white font-extrabold rounded-2xl hover:bg-purple-700 shadow-lg shadow-purple-100 transition-all">
					Done Selecting
				</button>
			</div>
		</div>
	</div>
{/if}

<!-- Progress Overlay -->
{#if submitting}
	<div class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-in fade-in">
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-md p-8 space-y-6">
			<div class="text-center">
				<div class="h-20 w-20 bg-purple-50 rounded-full flex items-center justify-center mx-auto mb-4">
					<UploadCloud class="h-10 w-10 text-purple-600 animate-pulse" />
				</div>
				<h3 class="font-extrabold text-gray-900 text-2xl tracking-tight">Submitting Request</h3>
				<p class="text-sm text-gray-500 mt-1">Registering diagnostic orders for {selectedPatient.full_name}</p>
			</div>

			<div class="space-y-3">
				{#each submitProgress as p}
					<div class="flex items-center justify-between p-4 rounded-2xl border-2 {p.status === 'error' ? 'bg-red-50 border-red-100' : 'bg-gray-50 border-gray-100'}">
						<span class="font-bold text-sm text-gray-800 truncate pr-4">{p.name}</span>
						{#if p.status === 'uploading'}
							<div class="h-5 w-5 border-2 border-purple-500 border-t-transparent rounded-full animate-spin"></div>
						{:else if p.status === 'success'}
							<CheckCircle2 class="h-5 w-5 text-green-500" />
						{:else if p.status === 'error'}
							<XCircle class="h-5 w-5 text-red-500" />
						{/if}
					</div>
				{/each}
			</div>
		</div>
	</div>
{/if}
