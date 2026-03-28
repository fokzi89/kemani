<script lang="ts">
	import { onMount, tick } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { 
		ArrowLeft, Plus, Search, UserPlus, Save, CheckCircle2, 
		XCircle, Pill, Trash2, Edit, X, Calendar, Activity, UploadCloud,
		Stethoscope, ClipboardList
	} from 'lucide-svelte';

	let provider = $state<any>(null);
	let loading = $state(true);

	// Multi-tab State
	let activeTab = $state<'details' | 'drugs'>('details');

	// Patient Selection State
	let patientMode = $state<'existing' | 'new'>('existing');
	let existingPatients = $state<any[]>([]);
	let filteredPatients = $state<any[]>([]);
	let searchPatientQuery = $state('');
	let selectedPatient = $state<any>(null);

	// New Patient Draft Form
	let newPatientForm = $state({
		full_name: '', phone: '', gender: 'Male', date_of_birth: ''
	});
	let isCreatingPatient = $state(false);

	// Prescription State
	let notes = $state('');
	let diagnosis = $state('');
	
	// Drugs State (Local)
	let drugs = $state<any[]>([]);
	let drugModalOpen = $state(false);
	let editingDrugIndex = $state<number | null>(null);
	let drugForm = $state({
		name: '', dosage: '', frequency: '', duration: '',
		dispense_quantity: '', dispense_as: '', special_instructions: '',
		drug_pic_url: ''
	});

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
				const { data } = await supabase
					.from('patients')
					.select('id, full_name, phone, profile_photo_url, gender')
					.eq('healthcare_provider_id', provider.id)
					.order('full_name');
				existingPatients = data || [];
				filteredPatients = existingPatients;
			}
		}
		loading = false;
	});

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

	function openDrugModal(index: number | null = null) {
		if (index !== null) {
			editingDrugIndex = index;
			drugForm = { ...drugs[index] };
		} else {
			editingDrugIndex = null;
			drugForm = {
				name: '', dosage: '', frequency: '', duration: '',
				dispense_quantity: '', dispense_as: '', special_instructions: '', drug_pic_url: ''
			};
		}
		drugModalOpen = true;
	}

	function saveDrug() {
		if (!drugForm.name) return alert('Drug name is required');
		
		if (editingDrugIndex !== null) {
			drugs[editingDrugIndex] = { ...drugForm };
		} else {
			drugs = [...drugs, { ...drugForm }];
		}
		drugModalOpen = false;
	}

	function deleteDrug(index: number) {
		drugs = drugs.filter((_, i) => i !== index);
	}

	async function createNewPatient() {
		if (!provider) {
			alert('Provider profile not loaded yet. Please wait a moment.');
			return;
		}
		if (!newPatientForm.full_name || !newPatientForm.phone) {
			return alert('Name and phone are required');
		}
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

	function generatePrescriptionCode() {
		const prefix = (selectedPatient?.full_name || 'UNK').trim().slice(0, 3).toUpperCase();
		const now = new Date();
		const timestampStr = now.getHours().toString().padStart(2, '0') +
							 now.getMinutes().toString().padStart(2, '0') + 
							 now.getSeconds().toString().padStart(2, '0') + 
							 now.getMilliseconds().toString().padStart(3, '0');
		return `${prefix}${timestampStr}`;
	}

	async function submitPrescription(status: 'draft' | 'active') {
		if (!selectedPatient && patientMode === 'existing') return alert('Please select a patient first');
		if (drugs.length === 0) return alert('Please add at least one drug');

		submitting = true;
		submitProgress = [];

		try {
			// Generate the prescribed code
			const pCode = generatePrescriptionCode();
			
			// 1. Create prescription entry
			let currentPatientId = selectedPatient?.id;

			const { data: presData, error: presErr } = await supabase.from('prescriptions').insert({
				provider_id: provider.id,
				patient_id: currentPatientId,
				consultation_id: null,
				diagnosis: diagnosis,
				notes: notes,
				provider_name: provider?.full_name || 'Unknown Provider',
				status: status,
				issue_date: new Date().toISOString(),
				prescription_code: pCode
			}).select().single();

			if (presErr) throw presErr;

			// 2. Insert drugs
			for (let i = 0; i < drugs.length; i++) {
				const d = drugs[i];
				submitProgress = [...submitProgress, { name: d.name, status: 'uploading' }];
				
				const { error: drugErr } = await supabase.from('prescribed_drugs').insert({
					prescription_id: presData.id,
					name: d.name,
					dispense_as: d.dispense_as,
					dispense_quantity: d.dispense_quantity ? parseInt(d.dispense_quantity) : null,
					dosage: d.dosage,
					frequency: d.frequency,
					duration: d.duration,
					special_instructions: d.special_instructions,
					drug_pic_url: d.drug_pic_url
				});

				const newProg = [...submitProgress];
				if (drugErr) {
					newProg[i].status = 'error';
					newProg[i].errorMsg = drugErr.message;
				} else {
					newProg[i].status = 'success';
				}
				submitProgress = newProg;
				await new Promise(r => setTimeout(r, 400));
			}

			if (submitProgress.some(p => p.status === 'error')) {
				alert('Prescription created, but some drugs failed to upload.');
			} else {
				setTimeout(() => { goto('/prescriptions'); }, 1500);
			}

		} catch (err: any) {
			alert('Critical failure: ' + err.message);
			submitting = false;
		}
	}
</script>

<svelte:head>
	<title>Add Prescription - Kemani</title>
</svelte:head>

<div class="min-h-screen p-4 sm:p-6 lg:p-8 bg-gray-50 pb-32">
	<div class="max-w-4xl mx-auto space-y-6">
		<!-- Header -->
		<div class="flex items-center gap-4">
			<a href="/prescriptions" class="p-2 bg-white rounded-lg shadow-sm border border-gray-100 hover:bg-gray-50 transition-colors">
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</a>
			<div>
				<h1 class="text-2xl font-bold text-gray-900 tracking-tight">Create Prescription</h1>
				<p class="text-sm text-gray-500">Draft a new medication order</p>
			</div>
		</div>

		{#if loading}
			<div class="flex justify-center p-12"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div></div>
		{:else}
			<!-- Tab Navigation -->
			<div class="flex border-b border-gray-200 bg-white rounded-t-2xl px-6 pt-2">
				<button 
					onclick={() => activeTab = 'details'}
					class="flex items-center gap-2 px-6 py-4 text-sm font-bold border-b-2 transition-all {activeTab === 'details' ? 'border-primary-700 text-primary-700' : 'border-transparent text-gray-500 hover:text-gray-700'}"
				>
					<UserPlus class="h-4 w-4" /> Patient & Notes
				</button>
				<button 
					onclick={() => activeTab = 'drugs'}
					class="flex items-center gap-2 px-6 py-4 text-sm font-bold border-b-2 transition-all {activeTab === 'drugs' ? 'border-primary-700 text-primary-700' : 'border-transparent text-gray-500 hover:text-gray-700'}"
				>
					<Pill class="h-4 w-4" /> Medications ({drugs.length})
				</button>
			</div>

			<div class="bg-white rounded-b-2xl shadow-sm border border-t-0 border-gray-100 p-6 min-h-[400px]">
				{#if activeTab === 'details'}
					<div class="space-y-8 animate-in fade-in slide-in-from-bottom-2 duration-300">
						<!-- Patient Selection -->
						<section>
							<h2 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
								<Stethoscope class="h-5 w-5 text-primary-600" /> Patient Selection
							</h2>

							<div class="flex gap-2 p-1 bg-gray-100/80 rounded-xl w-fit mb-6">
								<button onclick={() => patientMode = 'existing'} class="px-5 py-2 text-sm font-semibold rounded-lg transition-all {patientMode === 'existing' ? 'bg-white text-primary-800 shadow flex items-center gap-2' : 'text-gray-500 hover:text-gray-700'}">
									<Search class="h-4 w-4" /> Existing Patient
								</button>
								<button onclick={() => patientMode = 'new'} class="px-5 py-2 text-sm font-semibold rounded-lg transition-all {patientMode === 'new' ? 'bg-white text-primary-800 shadow flex items-center gap-2' : 'text-gray-500 hover:text-gray-700'}">
									<Plus class="h-4 w-4" /> New Patient
								</button>
							</div>

							{#if patientMode === 'existing'}
								<div class="space-y-4">
									{#if !selectedPatient}
										<div class="relative">
											<Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
											<input type="text" bind:value={searchPatientQuery} placeholder="Search by patient name or phone..." class="w-full pl-11 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary-600 transition-shadow" />
										</div>
										
										<div class="max-h-60 overflow-y-auto bg-white border border-gray-100 rounded-xl shadow-sm divide-y divide-gray-50">
											{#each filteredPatients as pt}
												<button onclick={() => selectedPatient = pt} class="w-full flex items-center gap-4 p-3 hover:bg-gray-50 transition-colors text-left text-gray-900">
													<div class="h-10 w-10 bg-primary-100 rounded-full flex items-center justify-center font-bold text-primary-700 shrink-0 uppercase">
														{pt.full_name[0]}
													</div>
													<div>
														<p class="font-semibold">{pt.full_name}</p>
														<p class="text-xs text-gray-500">{pt.phone}</p>
													</div>
												</button>
											{/each}
											{#if filteredPatients.length === 0}
												<div class="p-6 text-center text-sm text-gray-500">No patients found. Create a new one.</div>
											{/if}
										</div>
									{:else}
										<div class="flex items-center justify-between p-4 bg-green-50/50 border border-green-100 rounded-xl">
											<div class="flex items-center gap-4">
												<div class="h-12 w-12 bg-green-100 rounded-full flex items-center justify-center font-bold text-green-700 border-2 border-white shadow-sm">
													<CheckCircle2 class="h-6 w-6" />
												</div>
												<div>
													<p class="font-bold text-gray-900 text-lg uppercase">{selectedPatient.full_name}</p>
													<p class="text-sm text-gray-600">{selectedPatient.phone}</p>
												</div>
											</div>
											<button onclick={() => selectedPatient = null} class="text-sm font-medium text-red-600 hover:text-red-700 px-3 py-1.5 rounded-lg hover:bg-red-50 transition-colors">
												Change Patient
											</button>
										</div>
									{/if}
								</div>
							{:else}
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-5 p-5 bg-gray-50 rounded-xl border border-gray-100">
									<div>
										<label class="block text-sm font-medium text-gray-700 mb-1.5">Full Name</label>
										<input type="text" bind:value={newPatientForm.full_name} placeholder="John Doe" class="w-full px-4 py-2.5 bg-white border border-gray-300 rounded-lg focus:ring-primary-500" />
									</div>
									<div>
										<label class="block text-sm font-medium text-gray-700 mb-1.5">Phone Number</label>
										<input type="tel" bind:value={newPatientForm.phone} placeholder="e.g. 08012345678" class="w-full px-4 py-2.5 bg-white border border-gray-300 rounded-lg focus:ring-primary-500" />
									</div>
									<div class="sm:col-span-2">
										<button onclick={createNewPatient} disabled={isCreatingPatient} class="w-full py-3 bg-gray-900 hover:bg-black text-white font-bold rounded-lg transition-colors flex justify-center items-center gap-2">
											{isCreatingPatient ? 'Creating...' : 'Save Patient Profile'}
										</button>
									</div>
								</div>
							{/if}
						</section>

						<!-- Clinical Notes -->
						<section>
							<h2 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
								<ClipboardList class="h-5 w-5 text-primary-600" /> Clinical Notes
							</h2>
							<div class="space-y-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 mb-1.5">Diagnosis (Optional)</label>
									<input type="text" bind:value={diagnosis} placeholder="E.g., Acute Pharyngitis" class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-primary-500" />
								</div>
								<div>
									<label class="block text-sm font-medium text-gray-700 mb-1.5">General Notes</label>
									<textarea bind:value={notes} rows="4" placeholder="Additional instructions or clinical presentation..." class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-primary-500 resize-none"></textarea>
								</div>
							</div>
						</section>

						<div class="flex justify-end pt-4 pb-24 lg:pb-32">
							<button 
								onclick={() => activeTab = 'drugs'}
								class="px-8 py-3 bg-gray-900 text-white font-bold rounded-xl hover:bg-black transition-all flex items-center gap-2"
							>
								Next: Add Medications <ArrowLeft class="h-4 w-4 rotate-180" />
							</button>
						</div>
					</div>

				{:else if activeTab === 'drugs'}
					<div class="space-y-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
						<div class="flex items-center justify-between">
							<div>
								<h2 class="text-lg font-bold text-gray-900">Medication List</h2>
								<div class="flex items-center gap-2">
									<p class="text-xs text-gray-500 italic">Add drugs to be included in this prescription</p>
									{#if selectedPatient}
										<span class="px-2 py-0.5 bg-gray-100 text-gray-600 text-[10px] font-bold rounded uppercase">
											Ref: {selectedPatient.full_name.slice(0,3)}...
										</span>
									{/if}
								</div>
							</div>
							<button onclick={() => openDrugModal(null)} class="px-4 py-2 bg-primary-100 text-primary-900 hover:bg-primary-200 font-bold rounded-xl transition-colors flex items-center gap-2 text-sm shadow-sm">
								<Plus class="h-4 w-4" /> Add Medication
							</button>
						</div>

						<!-- Scrollable Container for Drugs -->
						<div class="max-h-[500px] overflow-y-auto pr-2 space-y-4 custom-scrollbar">
							{#if drugs.length === 0}
								<div class="text-center py-16 bg-gray-50 border border-dashed border-gray-200 rounded-2xl">
									<Pill class="h-12 w-12 text-gray-300 mx-auto mb-3" />
									<p class="text-sm font-medium text-gray-500">No medications added yet.</p>
									<button onclick={() => openDrugModal(null)} class="mt-4 text-primary-800 font-bold text-sm hover:underline">Add your first drug</button>
								</div>
							{:else}
								{#each drugs as drug, index}
									<div class="group relative flex flex-col sm:flex-row sm:items-center justify-between p-5 bg-white border border-gray-200 rounded-2xl shadow-sm hover:border-primary-300 hover:shadow-md transition-all gap-4">
										<div class="flex-1">
											<div class="flex items-center gap-2">
												<h4 class="font-bold text-gray-900 text-lg">{drug.name}</h4>
												{#if drug.dispense_quantity}
													<span class="px-2 py-0.5 bg-primary-100 text-primary-700 text-xs font-bold rounded-full">
														{drug.dispense_quantity} {drug.dispense_as || 'units'}
													</span>
												{/if}
											</div>
											<div class="grid grid-cols-2 sm:flex sm:items-center gap-x-6 gap-y-1 text-sm text-gray-600 mt-2">
												{#if drug.dosage}<span class="flex items-center gap-1.5"><Activity class="h-3.5 w-3.5 text-gray-400" /> {drug.dosage}</span>{/if}
												{#if drug.frequency}<span class="flex items-center gap-1.5"><Calendar class="h-3.5 w-3.5 text-gray-400" /> {drug.frequency}</span>{/if}
												{#if drug.duration}<span class="flex items-center gap-1.5"><Activity class="h-3.5 w-3.5 text-gray-400" /> {drug.duration}</span>{/if}
											</div>
											{#if drug.special_instructions}
												<div class="mt-3 py-2 px-3 bg-amber-50 rounded-lg text-xs text-amber-800 font-medium">
													" {drug.special_instructions} "
												</div>
											{/if}
										</div>
										
										<div class="flex items-center gap-2 shrink-0 pt-3 sm:pt-0 border-t sm:border-t-0 border-gray-100">
											<button onclick={() => openDrugModal(index)} class="p-2 text-blue-600 hover:bg-blue-50 rounded-full transition-colors" title="Edit"><Edit class="h-5 w-5"/></button>
											<button onclick={() => deleteDrug(index)} class="p-2 text-red-600 hover:bg-red-50 rounded-full transition-colors" title="Remove"><Trash2 class="h-5 w-5"/></button>
										</div>
									</div>
								{/each}
							{/if}
						</div>

						<div class="flex justify-between pt-4 pb-24 lg:pb-32">
							<button 
								onclick={() => activeTab = 'details'}
								class="px-6 py-3 text-gray-600 font-bold rounded-xl hover:bg-gray-100 transition-all flex items-center gap-2"
							>
								<ArrowLeft class="h-4 w-4" /> Back to Patient Info
							</button>
						</div>
					</div>
				{/if}
			</div>

			<!-- Action Buttons -->
			<div class="fixed bottom-0 left-0 right-0 bg-white/80 backdrop-blur-md border-t p-4 z-40 border-gray-200">
				<div class="max-w-4xl mx-auto flex flex-col sm:flex-row gap-3">
					<button onclick={() => submitPrescription('draft')} disabled={submitting} class="flex-1 px-6 py-4 bg-white border-2 border-gray-200 text-gray-700 font-bold rounded-2xl hover:bg-gray-50 hover:border-gray-300 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
						<Save class="h-5 w-5" /> Save as Draft
					</button>
					<button onclick={() => submitPrescription('active')} disabled={submitting} class="flex-[2] px-6 py-4 bg-primary-500 text-black font-extrabold rounded-2xl hover:bg-primary-600 transition-all shadow-lg hover:shadow-primary-200 flex items-center justify-center gap-2 disabled:opacity-50">
						<CheckCircle2 class="h-5 w-5" /> {submitting ? 'Creating Prescription...' : 'Finalize & Sign Prescription'}
					</button>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	.custom-scrollbar::-webkit-scrollbar {
		width: 6px;
	}
	.custom-scrollbar::-webkit-scrollbar-track {
		background: #f1f1f1;
		border-radius: 10px;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb {
		background: #d1d1d1;
		border-radius: 10px;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb:hover {
		background: #a1a1a1;
	}
</style>

<!-- Upload Progress Overlay -->
{#if submitting}
	<div class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-in fade-in">
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-md p-8 space-y-6 animate-in zoom-in-95">
			<div class="text-center">
				<div class="h-20 w-20 bg-primary-50 rounded-full flex items-center justify-center mx-auto mb-4">
					<UploadCloud class="h-10 w-10 text-primary-600 animate-pulse" />
				</div>
				<h3 class="font-bold text-gray-900 text-2xl">Finalizing Order</h3>
				<p class="text-sm text-gray-500 mt-1">Please wait while we secure your prescription record.</p>
			</div>

			<div class="space-y-3 max-h-60 overflow-y-auto pr-2 custom-scrollbar">
				{#each submitProgress as p}
					<div class="flex items-center justify-between p-4 rounded-2xl border {p.status === 'error' ? 'bg-red-50 border-red-100' : 'bg-gray-50 border-gray-100'}">
						<span class="font-bold text-sm text-gray-800 truncate pr-4">{p.name}</span>
						{#if p.status === 'uploading'}
							<div class="h-5 w-5 rounded-full border-2 border-primary-500 border-t-transparent animate-spin shrink-0"></div>
						{:else if p.status === 'success'}
							<CheckCircle2 class="h-5 w-5 text-green-500 shrink-0" />
						{:else if p.status === 'error'}
							<XCircle class="h-5 w-5 text-red-500 shrink-0" />
						{/if}
					</div>
				{/each}
			</div>
		</div>
	</div>
{/if}

<!-- Add/Edit Drug Modal -->
{#if drugModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-sm animate-in fade-in">
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto animate-in zoom-in-95">
			<div class="sticky top-0 bg-white border-b px-8 py-6 flex items-center justify-between z-10">
				<div>
					<h3 class="text-xl font-bold text-gray-900">{editingDrugIndex !== null ? 'Edit Drug Details' : 'Add New Drug'}</h3>
					<p class="text-xs text-gray-500">Specify dosage and instructions</p>
				</div>
				<button onclick={() => drugModalOpen = false} class="p-2 bg-gray-100 hover:bg-gray-200 rounded-full transition-colors">
					<X class="h-5 w-5 text-gray-600" />
				</button>
			</div>

			<div class="p-8 space-y-6">
				<div class="space-y-2">
					<label class="block text-sm font-bold text-gray-700">Drug Name <span class="text-red-500">*</span></label>
					<input type="text" bind:value={drugForm.name} required placeholder="e.g. Paracetamol 500mg" class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-2 focus:ring-primary-600 focus:bg-white transition-all font-medium" />
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Quantity</label>
						<input type="number" bind:value={drugForm.dispense_quantity} placeholder="10" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white transition-all" />
					</div>
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Type</label>
						<input type="text" bind:value={drugForm.dispense_as} placeholder="tabs/packs" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white transition-all" />
					</div>
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Dosage</label>
						<input type="text" bind:value={drugForm.dosage} placeholder="2 tabs" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white transition-all" />
					</div>
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Frequency</label>
						<input type="text" bind:value={drugForm.frequency} placeholder="BD (Twice Daily)" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white transition-all" />
					</div>
				</div>

				<div class="space-y-2">
					<label class="block text-sm font-bold text-gray-700">Duration</label>
					<input type="text" bind:value={drugForm.duration} placeholder="5 days" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white transition-all" />
				</div>

				<div class="space-y-2">
					<label class="block text-sm font-bold text-gray-700">Special Instructions</label>
					<textarea bind:value={drugForm.special_instructions} rows="3" placeholder="Take after meals..." class="w-full px-4 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:bg-white transition-all resize-none"></textarea>
				</div>
			</div>

			<div class="sticky bottom-0 bg-gray-50 border-t px-8 py-6 flex flex-col-reverse sm:flex-row gap-3 z-10">
				<button onclick={() => drugModalOpen = false} class="w-full sm:w-auto px-8 py-3 bg-white border border-gray-300 text-gray-700 font-bold rounded-2xl hover:bg-gray-100 transition-all">
					Cancel
				</button>
				<button onclick={saveDrug} class="w-full sm:flex-1 px-8 py-3 bg-primary-500 text-black font-extrabold rounded-2xl hover:bg-primary-600 shadow-md transition-all flex items-center justify-center gap-2">
					<CheckCircle2 class="h-5 w-5" /> {editingDrugIndex !== null ? 'Update Medication' : 'Add to List'}
				</button>
			</div>
		</div>
	</div>
{/if}
