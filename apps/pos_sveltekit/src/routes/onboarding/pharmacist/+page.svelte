<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { 
		ShieldCheck, FileText, Upload, CheckCircle2, 
		AlertCircle, Loader2, ArrowRight, LogOut 
	} from 'lucide-svelte';

	let loading = $state(false);
	let error = $state('');
	let success = $state(false);
	let currentUser = $state<any>(null);

	// Form State
	let regNum = $state('');
	let licenseFile = $state<File | null>(null);
	let uploadProgress = $state(0);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) {
			goto('/auth/login');
			return;
		}
		
		const { data: user } = await supabase
			.from('users')
			.select('*')
			.eq('id', session.user.id)
			.single();

		if (!user) {
			goto('/auth/login');
			return;
		}

		if (user.role !== 'pharmacist') {
			goto('/'); // Only for pharmacists
			return;
		}

		if (user.onboarding_done) {
			goto('/'); // Already done
			return;
		}

		currentUser = user;
	});

	async function handleFileUpload(e: Event) {
		const target = e.target as HTMLInputElement;
		if (target.files && target.files.length > 0) {
			licenseFile = target.files[0];
		}
	}

	async function handleSubmit() {
		if (!regNum) { error = 'Please enter your registration number'; return; }
		if (!licenseFile) { error = 'Please upload your license document'; return; }

		loading = true;
		error = '';

		try {
			// 1. Upload License to Supabase Storage
			const fileExt = licenseFile.name.split('.').pop();
			const fileName = `${currentUser.id}/license_${Date.now()}.${fileExt}`;
			const filePath = `${fileName}`;

			const { error: uploadError, data } = await supabase.storage
				.from('provider-licenses')
				.upload(filePath, licenseFile, {
					cacheControl: '3600',
					upsert: true
				});

			if (uploadError) throw uploadError;

			// Get Public URL (or private if bucket is private)
			const { data: urlData } = supabase.storage
				.from('provider-licenses')
				.getPublicUrl(filePath);

			const licenseUrl = urlData.publicUrl;

			// 2. Update User Record
			const { error: updateError } = await supabase
				.from('users')
				.update({
					pharmacist_reg_num: regNum,
					pharmacist_license_url: licenseUrl,
					onboarding_done: true,
					updated_at: new Date().toISOString()
				})
				.eq('id', currentUser.id);

			if (updateError) throw updateError;

			success = true;
			setTimeout(() => goto('/'), 2000);
		} catch (err: any) {
			console.error('Submission error:', err);
			error = err.message || 'Failed to submit verification details.';
		} finally {
			loading = false;
		}
	}

	async function handleLogout() {
		await supabase.auth.signOut();
		goto('/auth/login');
	}
</script>

<svelte:head>
	<title>Pharmacist Verification — Kemani POS</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 flex items-center justify-center p-6">
	<!-- Decorative Background Elements -->
	<div class="absolute top-0 right-0 w-96 h-96 bg-blue-100 rounded-full blur-3xl opacity-30 -translate-y-1/2 translate-x-1/2"></div>
	<div class="absolute bottom-0 left-0 w-96 h-96 bg-indigo-100 rounded-full blur-3xl opacity-30 translate-y-1/2 -translate-x-1/2"></div>

	<div class="w-full max-w-lg relative z-10">
		<div class="bg-white/80 backdrop-blur-xl border border-white shadow-2xl rounded-3xl overflow-hidden">
			
			{#if success}
				<div class="p-12 text-center animate-in fade-in zoom-in duration-500">
					<div class="h-20 w-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
						<CheckCircle2 class="h-10 w-10 text-emerald-600" />
					</div>
					<h2 class="text-3xl font-black text-gray-900 mb-2">Details Submitted!</h2>
					<p class="text-gray-500 font-medium">Thank you for providing your professional details. Redirecting you to the dashboard...</p>
					<div class="mt-8 flex justify-center">
						<div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
					</div>
				</div>
			{:else}
				<!-- Header Section -->
				<div class="bg-gradient-to-r from-blue-600 to-indigo-700 p-10 text-white relative">
					<div class="absolute top-4 right-4">
						<button 
							onclick={handleLogout}
							class="p-2 hover:bg-white/10 rounded-full transition-colors"
							title="Log Out"
						>
							<LogOut size={18} />
						</button>
					</div>
					<div class="h-14 w-14 bg-white/20 rounded-2xl flex items-center justify-center mb-6 backdrop-blur-md">
						<ShieldCheck size={32} class="text-white" />
					</div>
					<h1 class="text-3xl font-black mb-2">Professional Verification</h1>
					<p class="text-blue-100 font-medium leading-relaxed">
						To comply with regulations, please provide your pharmacist registration details.
					</p>
				</div>

				<!-- Form Section -->
				<div class="p-10 space-y-8">
					{#if error}
						<div class="bg-red-50 border border-red-100 text-red-700 p-4 rounded-2xl text-sm font-semibold flex items-center gap-3 animate-in shake-in">
							<AlertCircle class="h-5 w-5 shrink-0" />
							{error}
						</div>
					{/if}

					<div class="space-y-6">
						<!-- Registration Number -->
						<div class="space-y-2">
							<label for="regNum" class="text-sm font-black text-gray-700 uppercase tracking-wider">
								Pharmacist Reg. Number (PCN)
							</label>
							<div class="relative group">
								<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
									<FileText class="h-5 w-5 text-gray-400 group-focus-within:text-blue-600 transition-colors" />
								</div>
								<input 
									id="regNum"
									type="text"
									bind:value={regNum}
									placeholder="e.g. RPH/2023/1234"
									class="w-full pl-12 pr-4 py-4 bg-gray-50 border border-gray-100 rounded-2xl focus:ring-2 focus:ring-blue-600 focus:bg-white transition-all outline-none font-bold text-gray-900"
								/>
							</div>
						</div>

						<!-- License Upload -->
						<div class="space-y-2">
							<label class="text-sm font-black text-gray-700 uppercase tracking-wider">
								Professional License
							</label>
							<p class="text-[11px] text-gray-400 mb-2">
								Upload current year license or previous year's if current is not yet ready. (PDF or Image)
							</p>
							
							<div 
								class="border-2 border-dashed {licenseFile ? 'border-blue-400 bg-blue-50/30' : 'border-gray-200 bg-gray-50/50'} rounded-3xl p-8 transition-all hover:border-blue-300"
							>
								<input 
									type="file" 
									id="license" 
									accept=".pdf,image/*"
									onchange={handleFileUpload}
									class="hidden"
								/>
								<label for="license" class="cursor-pointer flex flex-col items-center text-center">
									{#if licenseFile}
										<div class="h-12 w-12 bg-blue-100 rounded-2xl flex items-center justify-center mb-3">
											<CheckCircle2 class="text-blue-600" />
										</div>
										<p class="text-sm font-bold text-gray-900 truncate max-w-xs">{licenseFile.name}</p>
										<p class="text-[10px] text-blue-600 font-black mt-1 uppercase tracking-widest">Click to change file</p>
									{:else}
										<div class="h-12 w-12 bg-gray-100 rounded-2xl flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
											<Upload class="text-gray-400" />
										</div>
										<p class="text-sm font-bold text-gray-700">Choose a file to upload</p>
										<p class="text-xs text-gray-400 mt-1">Drag and drop also supported</p>
									{/if}
								</label>
							</div>
						</div>
					</div>

					<!-- Action Button -->
					<div class="pt-4">
						<button 
							onclick={handleSubmit}
							disabled={loading}
							class="w-full bg-blue-600 hover:bg-blue-700 text-white font-black py-4 rounded-2xl shadow-xl shadow-blue-100 transition-all flex items-center justify-center gap-3 group disabled:opacity-50"
						>
							{#if loading}
								<Loader2 class="animate-spin" size={20} />
								Submitting Verification...
							{:else}
								Complete Onboarding
								<ArrowRight size={20} class="group-hover:translate-x-1 transition-transform" />
							{/if}
						</button>
					</div>
				</div>
			{/if}
		</div>

		<p class="text-center text-xs text-gray-400 mt-8 font-medium">
			Your professional details are stored securely and verified by our compliance team.
		</p>
	</div>
</div>

<style>
	@keyframes shake {
		0%, 100% { transform: translateX(0); }
		25% { transform: translateX(-4px); }
		75% { transform: translateX(4px); }
	}
	.animate-in.shake-in {
		animation: shake 0.5s ease-in-out;
	}
</style>
