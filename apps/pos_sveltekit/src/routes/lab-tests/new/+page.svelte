<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, AlertCircle, TestTube2, ClipboardList } from 'lucide-svelte';

	let loading = $state(false);
	let tenantId = $state('');
	let error = $state('');
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

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!form.name) { error = 'Investigation name is required'; return; }
		if (!tenantId) { error = 'User session error: Tenant ID not found. Please refresh.'; return; }
		loading = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('products').insert([{ ...form, tenant_id: tenantId }]);
			if (dbErr) throw dbErr;
			goto('/lab-tests');
		} catch (err: any) {
			error = err.message || 'Failed to save test';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>New Lab Test – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/lab-tests" class="p-2 hover:bg-gray-100 rounded-lg transition-colors">
			<ArrowLeft class="h-5 w-5 text-gray-600" />
		</a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Add New Lab Test</h1>
			<p class="text-sm text-gray-500">Fill in investigation details below</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-5">
		<!-- Basic Investigation Details -->
		<div class="bg-white rounded-xl border p-5 space-y-4">
			<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500">Basic Info</h2>
			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				<div class="sm:col-span-2">
					<label for="lab_name" class="block text-sm font-medium text-gray-700 mb-1">Investigation Name <span class="text-red-500">*</span></label>
					<input id="lab_name" type="text" bind:value={form.name} required placeholder="e.g. Full Blood Count (FBC)"
						class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
				</div>
				<div>
					<label for="lab_category" class="block text-sm font-medium text-gray-700 mb-1">Clinical Category</label>
					<select id="lab_category" bind:value={form.category}
						class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm bg-white">
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
					<label for="lab_sample" class="block text-sm font-medium text-gray-700 mb-1">Sample Requirement</label>
					<div class="relative">
						<TestTube2 class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
						<input id="lab_sample" type="text" bind:value={form.sample_type} placeholder="e.g. EDTA Blood, Urine"
							class="w-full pl-9 pr-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
				<div class="sm:col-span-2">
					<label for="lab_desc" class="block text-sm font-medium text-gray-700 mb-1">Clinical Instructions & Notes</label>
					<textarea id="lab_desc" bind:value={form.description} rows="3"
						placeholder="Patient preparation (e.g. Fasting 8hrs), specialized equipment, or additional clinician notes..."
						class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
				</div>
			</div>
		</div>

		<!-- Status Toggle -->
		<div class="bg-white rounded-xl border p-5">
			<label class="flex items-center gap-3 cursor-pointer">
				<input type="checkbox" bind:checked={form.is_active} class="w-4 h-4 text-indigo-600 rounded border-gray-300 focus:ring-indigo-500" />
				<span class="text-sm font-medium text-gray-700">Test is active and available for ordering via POS</span>
			</label>
		</div>

		<div class="flex gap-3">
			<a href="/lab-tests" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
				Cancel
			</a>
			<button type="submit" disabled={loading} class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
				<Save class="h-4 w-4" />{loading ? 'Saving...' : 'Save Lab Test'}
			</button>
		</div>
	</form>
</div>
