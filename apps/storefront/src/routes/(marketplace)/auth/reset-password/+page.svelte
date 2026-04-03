<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { ShieldCheck, Eye, EyeOff, AlertCircle, CheckCircle, Loader } from 'lucide-svelte';
	import { supabase } from '$lib/supabase';

	export let data: { storefront: any };
	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#131921';

	let password = '';
	let confirmPassword = '';
	let showPassword = false;
	let showConfirm = false;
	let isLoading = false;
	let errorMsg = '';
	let successMsg = '';
	let sessionReady = false;

	onMount(async () => {
		// Supabase puts the access token in the URL hash
		const { data: { session } } = await supabase.auth.getSession();
		if (session) {
			sessionReady = true;
		} else {
			errorMsg = 'This reset link is invalid or has expired. Please request a new one.';
		}
	});

	$: strength = (() => {
		if (!password) return 0;
		let s = 0;
		if (password.length >= 8) s++;
		if (/[A-Z]/.test(password)) s++;
		if (/[0-9]/.test(password)) s++;
		if (/[^A-Za-z0-9]/.test(password)) s++;
		return s;
	})();
	$: strengthLabel = ['', 'Weak', 'Fair', 'Good', 'Strong'][strength];
	$: strengthColor = ['', 'bg-red-500', 'bg-orange-400', 'bg-yellow-400', 'bg-green-500'][strength];

	async function handleReset(e: Event) {
		e.preventDefault();
		errorMsg = '';
		if (password !== confirmPassword) { errorMsg = 'Passwords do not match.'; return; }
		if (password.length < 8) { errorMsg = 'Password must be at least 8 characters.'; return; }
		isLoading = true;
		try {
			const { error } = await supabase.auth.updateUser({ password });
			if (error) {
				errorMsg = error.message;
			} else {
				successMsg = 'Your password has been updated. Redirecting to sign in...';
				setTimeout(() => goto('/auth/login'), 2500);
			}
		} catch {
			errorMsg = 'An unexpected error occurred. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>New Password — {storefront?.name || 'Store'}</title>
</svelte:head>

<div class="min-h-screen bg-[#f3f3f3] flex items-center justify-center px-4 py-12">
	<div class="w-full max-w-sm">

		<a href="/" class="flex items-center gap-2 mb-8 justify-center">
			{#if storefront?.logo_url}
				<img src={storefront.logo_url} alt={storefront.name} class="h-8 w-8 rounded object-cover" />
			{:else}
				<div class="h-8 w-8 rounded flex items-center justify-center" style="background:{brandColor}">
					<ShieldCheck class="h-4 w-4 text-white" />
				</div>
			{/if}
			<span class="text-xl font-bold text-[#131921]">{storefront?.name || 'Store'}</span>
		</a>

		<div class="bg-white border border-gray-300 rounded-lg p-6 shadow-sm">
			<h1 class="text-2xl font-medium text-[#131921] mb-1">Create new password</h1>
			<p class="text-sm text-gray-600 mb-6">Your new password must be different from previously used passwords.</p>

			{#if errorMsg}
				<div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg flex items-start gap-2 text-sm text-red-700">
					<AlertCircle class="h-4 w-4 mt-0.5 flex-shrink-0" />
					<span>{errorMsg}</span>
				</div>
			{/if}

			{#if successMsg}
				<div class="p-4 bg-green-50 border border-green-200 rounded-lg flex items-start gap-3 text-sm text-green-700">
					<CheckCircle class="h-5 w-5 mt-0.5 flex-shrink-0 text-green-500" />
					<span>{successMsg}</span>
				</div>
			{:else if sessionReady}
				<form on:submit={handleReset} class="space-y-4">
					<div>
						<label class="block text-sm font-bold text-[#131921] mb-1" for="new-password">New password</label>
						<div class="relative">
							<input
								id="new-password"
								type={showPassword ? 'text' : 'password'}
								bind:value={password}
								placeholder="At least 8 characters"
								required
								class="w-full px-3 py-2 pr-10 bg-white border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:border-[#e77600] focus:ring-2 focus:ring-[#e77600]/30 transition-all"
							/>
							<button type="button" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-700" on:click={() => showPassword = !showPassword}>
								{#if showPassword}<EyeOff class="h-4 w-4" />{:else}<Eye class="h-4 w-4" />{/if}
							</button>
						</div>
						{#if password}
							<div class="mt-2 flex items-center gap-2">
								<div class="flex-1 flex gap-1">
									{#each Array(4) as _, i}
										<div class="h-1 flex-1 rounded-full {i < strength ? strengthColor : 'bg-gray-200'} transition-all"></div>
									{/each}
								</div>
								<span class="text-xs font-medium text-gray-500">{strengthLabel}</span>
							</div>
						{/if}
					</div>

					<div>
						<label class="block text-sm font-bold text-[#131921] mb-1" for="confirm-new">Re-enter new password</label>
						<div class="relative">
							<input
								id="confirm-new"
								type={showConfirm ? 'text' : 'password'}
								bind:value={confirmPassword}
								required
								class="w-full px-3 py-2 pr-10 bg-white border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:border-[#e77600] focus:ring-2 focus:ring-[#e77600]/30 transition-all
									{confirmPassword && confirmPassword !== password ? 'border-red-400' : ''}
									{confirmPassword && confirmPassword === password ? 'border-green-400' : ''}"
							/>
							<button type="button" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-700" on:click={() => showConfirm = !showConfirm}>
								{#if showConfirm}<EyeOff class="h-4 w-4" />{:else}<Eye class="h-4 w-4" />{/if}
							</button>
						</div>
						{#if confirmPassword && confirmPassword !== password}
							<p class="text-xs text-red-500 mt-1">Passwords do not match</p>
						{/if}
					</div>

					<button
						type="submit"
						disabled={isLoading}
						class="w-full py-2 px-4 text-sm font-medium text-black bg-[#ffd814] hover:bg-[#F7CA00] border border-[#FCD200] rounded-lg shadow-sm transition-colors flex items-center justify-center gap-2 disabled:opacity-70"
					>
						{#if isLoading}
							<Loader class="h-4 w-4 animate-spin" /> Updating...
						{:else}
							Save new password
						{/if}
					</button>
				</form>
			{:else if !errorMsg}
				<div class="flex justify-center py-6">
					<Loader class="h-6 w-6 animate-spin text-gray-400" />
				</div>
			{/if}

			{#if errorMsg}
				<div class="mt-4 pt-4 border-t border-gray-200">
					<a href="/auth/forgot-password" class="text-sm text-[#007185] hover:underline">Request a new reset link →</a>
				</div>
			{/if}
		</div>
	</div>
</div>
