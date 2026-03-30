<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { FlaskConical, Save, ArrowLeft, Microscope, TestTube2, AlertCircle, Info, ClipboardList, Trash2 } from 'lucide-svelte';

	let loading = $state(false);
	let testId = $page.params.id;
	let form = $state({
		name: '',
		category: '',
		description: '',
		sample_type: '',
		is_active: true,
		product_type: 'Laboratory test'
	});

	onMount(async () => {
		const { data, error } = await supabase.from('products').select('*').eq('id', testId).single();
		if (data) {
			form = {
				name: data.name,
				category: data.category || '',
				description: data.description || '',
				sample_type: data.sample_type || '',
				is_active: data.is_active ?? true,
				product_type: 'Laboratory test'
			};
		}
	});

	async function handleSave() {
		if (!form.name) return;
		loading = true;
		try {
			const { error } = await supabase.from('products').update(form).eq('id', testId);
			if (error) throw error;
			goto('/lab-tests');
		} catch (err: any) {
			alert(err.message || 'Failed to update test');
		} finally {
			loading = false;
		}
	}

	async function handleDelete() {
		if (!confirm('Are you sure you want to delete this investigation?')) return;
		const { error } = await supabase.from('products').delete().eq('id', testId);
		if (error) {
			alert('Cannot delete investigation. It may be referenced by patient records.');
		} else {
			goto('/lab-tests');
		}
	}
</script>

<svelte:head><title>Edit Lab Test – Kemani POS</title></svelte:head>

<div class="min-h-screen bg-gray-50/50 p-6">
	<div class="max-w-3xl mx-auto space-y-6">
		<div class="flex items-center justify-between">
			<button onclick={() => goto('/lab-tests')} class="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors font-medium">
				<ArrowLeft class="h-4 w-4" /> Back to Catalog
			</button>
			<button onclick={handleDelete} class="p-2.5 bg-red-50 text-red-600 border border-red-200 rounded-xl hover:bg-red-100 shadow-sm transition-all flex items-center gap-2 font-bold text-xs uppercase">
				<Trash2 class="h-4 w-4" /> Terminate Test
			</button>
		</div>

		<form onsubmit={(e) => { e.preventDefault(); handleSave(); }} class="space-y-6">
			<div class="bg-white rounded-2xl border shadow-sm overflow-hidden border-indigo-100">
				<div class="bg-indigo-700 p-6 text-white flex items-center gap-5">
					<div class="h-16 w-16 bg-white/20 backdrop-blur-md rounded-2xl flex items-center justify-center border border-white/30">
						<FlaskConical class="h-8 w-8 text-white" />
					</div>
					<div>
						<h1 class="text-2xl font-black text-white">Manage Investigation</h1>
						<p class="text-indigo-100 text-sm">{form.name || 'Updating clinical parameters'}</p>
					</div>
				</div>
				
				<div class="p-8 space-y-8">
					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<AlertCircle class="h-3 w-3" /> Basic Investigation Details
						</h2>
						<div class="grid grid-cols-1 gap-6">
							<div>
								<label for="name" class="block text-sm font-bold text-gray-700 mb-2">Investigation Name *</label>
								<input id="name" type="text" bind:value={form.name} required 
									class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-semibold" />
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<TestTube2 class="h-3 w-3" /> Sample & Clinical Specifications
						</h2>
						<div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
							<div>
								<label for="category" class="block text-sm font-bold text-gray-700 mb-2">Clinical Category</label>
								<select id="category" bind:value={form.category} class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl font-semibold outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all cursor-pointer">
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
									<input id="sample" type="text" bind:value={form.sample_type} 
										class="w-full pl-12 pr-5 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all font-medium" />
								</div>
							</div>
						</div>
					</div>

					<div class="h-px bg-gray-100"></div>

					<div class="space-y-4">
						<h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
							<Info class="h-3 w-3" /> Clinical Instructions & Notes
						</h2>
						<div>
							<textarea bind:value={form.description} rows="4" 
								class="w-full px-5 py-4 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all font-medium resize-none"></textarea>
						</div>
					</div>

					<label class="flex items-center gap-4 p-5 bg-indigo-50 rounded-2xl cursor-pointer hover:bg-indigo-100 transition-all border border-indigo-100">
						<div class="h-10 w-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white shrink-0">
							<ClipboardList class="h-5 w-5" />
						</div>
						<div class="flex-1">
							<p class="text-sm font-bold text-indigo-900 leading-tight">Investigation Availability</p>
							<p class="text-[10px] text-indigo-600 font-bold uppercase tracking-wider mt-0.5">Toggle availability in ordering menus</p>
						</div>
						<input type="checkbox" bind:checked={form.is_active} class="w-6 h-6 text-indigo-600 rounded-lg border-indigo-200 focus:ring-indigo-500 bg-white" />
					</label>
				</div>
			</div>

			<div class="flex gap-4">
				<button type="button" onclick={() => goto('/lab-tests')} class="flex-1 px-6 py-4 bg-white border border-gray-200 text-gray-600 font-bold rounded-2xl hover:bg-gray-50 transition-all uppercase tracking-widest text-xs">
					Cancel
				</button>
				<button type="submit" disabled={loading || !form.name} 
					class="flex-1 px-6 py-4 bg-indigo-700 text-white font-black rounded-2xl hover:bg-indigo-800 transition-all shadow-lg shadow-indigo-100 uppercase tracking-widest text-xs disabled:opacity-50 flex items-center justify-center gap-2">
					<Save class="h-4 w-4" /> {loading ? 'Saving...' : 'Update Investigation'}
				</button>
			</div>
		</form>
	</div>
</div>
