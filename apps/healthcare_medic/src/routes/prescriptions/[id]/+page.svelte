<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { 
		ArrowLeft, Plus, Search, UserPlus, Save, CheckCircle2, 
		XCircle, Pill, Trash2, Edit, X, Calendar, Activity, UploadCloud,
		Stethoscope, ClipboardList
	} from 'lucide-svelte';

	const prescriptionId = page.params.id;

	let provider = $state<any>(null);
	let loading = $state(true);
	let prescriptionCode = $state('');

	// Multi-tab State
	let activeTab = $state<'details' | 'drugs'>('details');

	// Patient Selection State (Locked during edit usually, but we can allow it)
	let patientMode = $state<'existing' | 'new'>('existing');
	let existingPatients = $state<any[]>([]);
	let filteredPatients = $state<any[]>([]);
	let searchPatientQuery = $state('');
	let selectedPatient = $state<any>(null);

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
		const { data: sessionData } = await supabase.auth.getSession();
		const session = sessionData?.session;
		if (session) {
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', session.user.id)
				.single();
			provider = providerData;

			if (provider) {
				// 1. Fetch patients for search
				const { data: patientsData } = await supabase
					.from('patients')
					.select('id, full_name, phone, profile_photo_url, gender')
					.eq('healthcare_provider_id', provider.id)
					.order('full_name');
				existingPatients = patientsData || [];
				filteredPatients = existingPatients;

				// 2. Fetch the prescription to edit
				const { data: pres, error } = await supabase
					.from('prescriptions')
					.select(`
						*,
						patients (id, full_name, phone, gender, profile_photo_url),
						prescribed_drugs (*)
					`)
					.eq('id', prescriptionId)
					.single();

				if (pres) {
					diagnosis = pres.diagnosis || '';
					notes = pres.notes || '';
					selectedPatient = pres.patients;
					prescriptionCode = pres.prescription_code || '';
					drugs = pres.prescribed_drugs || [];
				} else if (error) {
					alert('Failed to load prescription: ' + error.message);
					goto('/prescriptions');
				}
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

	async function submitPrescription(status: 'draft' | 'active') {
		if (!selectedPatient) return alert('Please select a patient first');
		if (drugs.length === 0) return alert('Please add at least one drug');

		submitting = true;
		submitProgress = [];

		try {
			// 1. Update prescription entry
			const { error: presErr } = await supabase.from('prescriptions').update({
				patient_id: selectedPatient.id,
				diagnosis: diagnosis,
				notes: notes,
				status: status,
				updated_at: new Date().toISOString()
			}).eq('id', prescriptionId);

			if (presErr) throw presErr;

			// 2. Sync drugs (Delete all and re-insert for simplicity)
			const { error: delErr } = await supabase
				.from('prescribed_drugs')
				.delete()
				.eq('prescription_id', prescriptionId);

			if (delErr) throw delErr;

			// 3. Insert drugs
			for (let i = 0; i < drugs.length; i++) {
				const d = drugs[i];
				submitProgress = [...submitProgress, { name: d.name, status: 'uploading' }];
				
				const { error: drugErr } = await supabase.from('prescribed_drugs').insert({
					prescription_id: prescriptionId,
					name: d.name,
					dispense_as: d.dispense_as,
					dispense_quantity: d.dispense_quantity ? parseInt(d.dispense_quantity.toString()) : null,
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
				alert('Prescription updated, but some drugs failed to upload.');
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
	<title>Edit Prescription - Kemani</title>
</svelte:head>

<div class="min-h-screen p-4 sm:p-6 lg:p-8 bg-gray-50 pb-32">
	<div class="max-w-4xl mx-auto space-y-6">
		<!-- Header -->
		<div class="flex items-center gap-4">
			<a href="/prescriptions" class="p-2 bg-white rounded-lg shadow-sm border border-gray-100 hover:bg-gray-50 transition-colors">
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</a>
			<div>
				<h1 class="text-2xl font-bold text-gray-900 tracking-tight">Edit Prescription</h1>
				<p class="text-sm text-gray-500">
					{prescriptionCode ? `Updating record ${prescriptionCode}` : 'Updating prescription details'}
				</p>
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

							{#if !selectedPatient}
								<div class="relative">
									<Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
									<input type="text" bind:value={searchPatientQuery} placeholder="Search by patient name or phone..." class="w-full pl-11 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary-600 transition-shadow" />
								</div>
								
								<div class="max-h-60 overflow-y-auto bg-white border border-gray-100 rounded-xl shadow-sm divide-y divide-gray-50 mt-2">
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
									<textarea bind:value={notes} rows="4" placeholder="Additional instructions..." class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-primary-500 resize-none"></textarea>
								</div>
							</div>
						</section>

						<div class="flex justify-end pt-4 pb-24 lg:pb-32">
							<button 
								onclick={() => activeTab = 'drugs'}
								class="px-8 py-3 bg-gray-900 text-white font-bold rounded-xl hover:bg-black transition-all flex items-center gap-2"
							>
								Next: Medications <ArrowLeft class="h-4 w-4 rotate-180" />
							</button>
						</div>
					</div>

				{:else if activeTab === 'drugs'}
					<div class="space-y-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
						<div class="flex items-center justify-between">
							<h2 class="text-lg font-bold text-gray-900">Medication List</h2>
							<button onclick={() => openDrugModal(null)} class="px-4 py-2 bg-primary-100 text-primary-900 hover:bg-primary-200 font-bold rounded-xl transition-colors flex items-center gap-2 text-sm shadow-sm">
								<Plus class="h-4 w-4" /> Add Medication
							</button>
						</div>

						<div class="max-h-[500px] overflow-y-auto pr-2 space-y-4 custom-scrollbar">
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
											{#if drug.dosage}<span>{drug.dosage}</span>{/if}
											{#if drug.frequency}<span>{drug.frequency}</span>{/if}
											{#if drug.duration}<span>{drug.duration}</span>{/if}
										</div>
									</div>
									<div class="flex items-center gap-2">
										<button onclick={() => openDrugModal(index)} class="p-2 text-blue-600 hover:bg-blue-50 rounded-full transition-colors"><Edit class="h-5 w-5"/></button>
										<button onclick={() => deleteDrug(index)} class="p-2 text-red-600 hover:bg-red-50 rounded-full transition-colors"><Trash2 class="h-5 w-5"/></button>
									</div>
								</div>
							{/each}
						</div>

						<div class="flex justify-between pt-4 pb-24 lg:pb-32">
							<button onclick={() => activeTab = 'details'} class="px-6 py-3 text-gray-600 font-bold rounded-xl hover:bg-gray-100 flex items-center gap-2">
								<ArrowLeft class="h-4 w-4" /> Back to Details
							</button>
						</div>
					</div>
				{/if}
			</div>

			<!-- Action Buttons -->
			<div class="fixed bottom-0 left-0 right-0 bg-white/80 backdrop-blur-md border-t p-4 z-40 border-gray-200">
				<div class="max-w-4xl mx-auto flex flex-col sm:flex-row gap-3">
					<button onclick={() => submitPrescription('draft')} disabled={submitting} class="flex-1 px-6 py-4 bg-white border-2 border-gray-200 text-gray-700 font-bold rounded-2xl hover:bg-gray-50 disabled:opacity-50">
						<Save class="h-5 w-5 mr-2 inline" /> Save as Draft
					</button>
					<button onclick={() => submitPrescription('active')} disabled={submitting} class="flex-[2] px-6 py-4 bg-primary-500 text-black font-extrabold rounded-2xl hover:bg-primary-600 shadow-lg flex items-center justify-center gap-2 disabled:opacity-50">
						<CheckCircle2 class="h-5 w-5" /> {submitting ? 'Updating...' : 'Update & Sign Prescription'}
					</button>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	.custom-scrollbar::-webkit-scrollbar { width: 6px; }
	.custom-scrollbar::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 10px; }
	.custom-scrollbar::-webkit-scrollbar-thumb { background: #d1d1d1; border-radius: 10px; }
</style>

<!-- Upload Progress Overlay -->
{#if submitting}
	<div class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-in fade-in">
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-md p-8 space-y-6">
			<div class="text-center">
				<UploadCloud class="h-10 w-10 text-primary-600 animate-pulse mx-auto mb-4" />
				<h3 class="font-bold text-gray-900 text-2xl">Updating Prescription</h3>
			</div>
			<div class="space-y-3 max-h-60 overflow-y-auto pr-2 custom-scrollbar">
				{#each submitProgress as p}
					<div class="flex items-center justify-between p-4 rounded-2xl border {p.status === 'error' ? 'bg-red-50' : 'bg-gray-50'}">
						<span class="font-bold text-sm truncate">{p.name}</span>
						{#if p.status === 'uploading'}
							<div class="h-5 w-5 rounded-full border-2 border-primary-500 border-t-transparent animate-spin"></div>
						{:else if p.status === 'success'}
							<CheckCircle2 class="h-5 w-5 text-green-500" />
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
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
			<div class="sticky top-0 bg-white border-b px-8 py-6 flex items-center justify-between z-10">
				<h3 class="text-xl font-bold">{editingDrugIndex !== null ? 'Edit Drug Details' : 'Add New Drug'}</h3>
				<button onclick={() => drugModalOpen = false} class="p-2 bg-gray-100 hover:bg-gray-200 rounded-full"><X class="h-5 w-5"/></button>
			</div>

			<div class="p-8 space-y-6">
				<div class="space-y-2">
					<label class="block text-sm font-bold text-gray-700">Drug Name *</label>
					<input type="text" bind:value={drugForm.name} required class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-2 focus:ring-primary-600" />
				</div>
				<div class="grid grid-cols-2 gap-4">
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Quantity</label>
						<input type="number" bind:value={drugForm.dispense_quantity} class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl" />
					</div>
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Type</label>
						<input type="text" bind:value={drugForm.dispense_as} class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl" />
					</div>
				</div>
				<div class="grid grid-cols-2 gap-4">
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Dosage</label>
						<input type="text" bind:value={drugForm.dosage} class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl" />
					</div>
					<div class="space-y-2">
						<label class="block text-sm font-bold text-gray-700">Frequency</label>
						<input type="text" bind:value={drugForm.frequency} class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl" />
					</div>
				</div>
				<div class="space-y-2">
					<label class="block text-sm font-bold text-gray-700">Duration</label>
					<input type="text" bind:value={drugForm.duration} class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl" />
				</div>
				<div class="space-y-2">
					<label class="block text-sm font-bold text-gray-700">Special Instructions</label>
					<textarea bind:value={drugForm.special_instructions} rows="3" class="w-full px-4 py-4 bg-gray-50 border border-gray-200 rounded-2xl resize-none"></textarea>
				</div>
			</div>

			<div class="sticky bottom-0 bg-gray-50 border-t px-8 py-6 flex gap-3 z-10">
				<button onclick={() => drugModalOpen = false} class="flex-1 px-8 py-3 bg-white border border-gray-300 rounded-2xl">Cancel</button>
				<button onclick={saveDrug} class="flex-[2] px-8 py-3 bg-primary-500 text-black font-extrabold rounded-2xl">{editingDrugIndex !== null ? 'Update' : 'Add'}</button>
			</div>
		</div>
	</div>
{/if}
