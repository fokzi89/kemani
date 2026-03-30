<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { FlaskConical, Save, ArrowLeft, Microscope, TestTube2, AlertCircle, Info, ClipboardList } from 'lucide-svelte';

	let loading = $state(false);
	let tenantId = $state('');
	let form = $state({
		name: '',
		category: '',
		description: '',
		sample_type: '',
		is_active: true,
		product_type: 'Laboratory test'
	});

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) tenantId = user.tenant_id;
	});

	async function handleSave() {
		if (!form.name || !tenantId) return;
		loading = true;
		try {
			const { error } = await supabase.from('products').insert([{ ...form, tenant_id: tenantId }]);
			if (error) throw error;
			goto('/lab-tests');
		} catch (err: any) {
			alert(err.message || 'Failed to save test');
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>New Lab Test – Kemani POS</title></svelte:head>

<div class="min-h-screen bg-gray-50/50 p-6">
	<div class="max-w-3xl mx-auto space-y-6">
		<!-- Top Bar -->
		<div class="flex items-center justify-between">
			<button onclick={() => history.back()} class="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors font-medium">
				<ArrowLeft class="h-4 w-4" /> Back to Investigations
			</button>
			<div class="h-10 w-10 bg-white border rounded-xl flex items-center justify-center text-purple-600 shadow-sm">
				<FlaskConical class="h-5 w-5" />
			</div>
		</div>

		<!-- Main Form -->
		<form onsubmit={(e) => { e.preventDefault(); handleSave(); }} class="space-y-6">
			<!-- Header Card -->
			<div class="bg-white rounded-2xl border shadow-sm overflow-hidden border-purple-100">
				<div class="bg-purple-700 p-6 text-white flex items-center gap-5">
					<div class="h-16 w-16 bg-white/20 backdrop-blur-md rounded-2xl flex items-center justify-center border border-white/30">
						<Microscope class="h-8 w-8" />
					</div>
					<div>
						<h1 class="text-2xl font-black text-white">Register Lab Test</h1>
						<p class="text-purple-100 text-sm">Create a new laboratory investigation for your services catalog</p>
					</div>
				</div>
				
				<div class="p-8 space-y-8">
					<!-- Primary Info -->
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<AlertCircle class="h-3 w-3" /> Basic Investigation Details
						</h2>
						<div class="grid grid-cols-1 gap-6">
							<div>
								<label for="name" class="block text-sm font-bold text-gray-700 mb-2">Investigation Name *</label>
								<input id="name" type="text" bind:value={form.name} required placeholder="e.g. Full Blood Count (FBC)" 
									class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-purple-500/10 focus:border-purple-500 outline-none transition-all font-semibold" />
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<!-- Clinical Specs -->
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<TestTube2 class="h-3 w-3" /> Sample & Clinical Specifications
						</h2>
						<div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
							<div>
								<label for="category" class="block text-sm font-bold text-gray-700 mb-2">Clinical Category</label>
								<select id="category" bind:value={form.category} class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl font-semibold outline-none focus:ring-4 focus:ring-purple-500/10 transition-all appearance-none cursor-pointer">
									<option value="">Select Department</option>
									<option value="Hematology">Hematology</option>
									<option value="Biochemistry">Biochemistry</option>
									<option value="Microbiology">Microbiology</option>
									<option value="Serology">Serology</option>
									<option value="Endocrinology">Endocrinology</option>
									<option value="Cytology">Cytology</option>
								</select>
							</div>
							<div>
								<label for="sample" class="block text-sm font-bold text-gray-700 mb-2">Sample Requirement</label>
								<div class="relative">
									<TestTube2 class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
									<input id="sample" type="text" bind:value={form.sample_type} placeholder="e.g. Whole Blood, 10ml Urine" 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-purple-500/10 transition-all font-medium" />
								</div>
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<!-- Description Section -->
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<Info class="h-3 w-3" /> Clinical Instructions & Notes
						</h2>
						<div>
							<textarea bind:value={form.description} rows="4" placeholder="Patient preparation (e.g. Fasting 8hrs), specialized equipment, or additional clinician notes..." 
								class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-purple-500/10 transition-all font-medium resize-none"></textarea>
						</div>
					</div>

					<!-- Status Toggle -->
					<label class="flex items-center gap-4 p-5 bg-purple-50 rounded-2xl cursor-pointer hover:bg-purple-100 transition-all border border-purple-100">
						<div class="h-10 w-10 bg-purple-600 rounded-xl flex items-center justify-center text-white shrink-0">
							<ClipboardList class="h-5 w-5" />
						</div>
						<div class="flex-1">
							<p class="text-sm font-bold text-purple-900 leading-tight">Test Availability Status</p>
							<p class="text-[10px] text-purple-600 font-bold uppercase tracking-wider mt-0.5">Toggle whether this test can be order via the POS</p>
						</div>
						<input type="checkbox" bind:checked={form.is_active} class="w-6 h-6 text-purple-600 rounded-lg border-purple-200 focus:ring-purple-500 bg-white" />
					</label>
				</div>
			</div>

			<!-- Footer Actions -->
			<div class="flex gap-4">
				<button type="button" onclick={() => history.back()} class="flex-1 px-6 py-4 bg-white border border-gray-200 text-gray-600 font-bold rounded-2xl hover:bg-gray-50 transition-all uppercase tracking-widest text-xs">
					Cancel
				</button>
				<button type="submit" disabled={loading || !form.name} 
					class="flex-1 px-6 py-4 bg-purple-700 text-white font-black rounded-2xl hover:bg-purple-800 transition-all shadow-lg shadow-purple-100 uppercase tracking-widest text-xs disabled:opacity-50 flex items-center justify-center gap-2">
					<Save class="h-4 w-4" /> {loading ? 'Registering...' : 'Add Investigation'}
				</button>
			</div>
		</form>
	</div>
</div>
