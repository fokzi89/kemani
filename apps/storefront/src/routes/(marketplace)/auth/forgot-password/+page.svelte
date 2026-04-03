<script lang="ts">
	import { ShieldCheck, AlertCircle, CheckCircle, Loader, ArrowLeft } from 'lucide-svelte';
	import { supabase } from '$lib/supabase';

	export let data: { storefront: any };
	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#131921';

	let email = '';
	let isLoading = false;
	let errorMsg = '';
	let successMsg = '';

	async function handleReset(e: Event) {
		e.preventDefault();
		errorMsg = '';
		successMsg = '';
		isLoading = true;
		try {
			const { error } = await supabase.auth.resetPasswordForEmail(email, {
				redirectTo: `${window.location.origin}/auth/reset-password`
			});
			if (error) {
				errorMsg = error.message;
			} else {
				successMsg = `We've sent a password reset link to ${email}. Check your inbox.`;
				email = '';
			}
		} catch {
			errorMsg = 'An unexpected error occurred. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Reset Password — {storefront?.name || 'Store'}</title>
</svelte:head>

<div class="min-h-screen bg-[#f3f3f3] flex items-center justify-center px-4 py-12">
	<div class="w-full max-w-sm">

		<!-- Logo -->
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
			<h1 class="text-2xl font-medium text-[#131921] mb-1">Password assistance</h1>
			<p class="text-sm text-gray-600 mb-6">Enter your email address and we'll send you a link to reset your password.</p>

			{#if errorMsg}
				<div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg flex items-start gap-2 text-sm text-red-700">
					<AlertCircle class="h-4 w-4 mt-0.5 flex-shrink-0" />
					<span>{errorMsg}</span>
				</div>
			{/if}

			{#if successMsg}
				<div class="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg flex items-start gap-3 text-sm text-green-700">
					<CheckCircle class="h-5 w-5 mt-0.5 flex-shrink-0 text-green-500" />
					<div>
						<p class="font-medium mb-1">Email sent!</p>
						<p>{successMsg}</p>
					</div>
				</div>
				<a href="/auth/login" class="flex items-center gap-1.5 text-sm text-[#007185] hover:underline mt-4">
					<ArrowLeft class="h-4 w-4" /> Return to sign-in
				</a>
			{:else}
				<form on:submit={handleReset} class="space-y-4">
					<div>
						<label class="block text-sm font-bold text-[#131921] mb-1" for="reset-email">Email address</label>
						<input
							id="reset-email"
							type="email"
							bind:value={email}
							required
							class="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:border-[#e77600] focus:ring-2 focus:ring-[#e77600]/30 transition-all"
						/>
					</div>

					<button
						type="submit"
						disabled={isLoading}
						class="w-full py-2 px-4 text-sm font-medium text-black bg-[#ffd814] hover:bg-[#F7CA00] border border-[#FCD200] rounded-lg shadow-sm transition-colors flex items-center justify-center gap-2 disabled:opacity-70"
					>
						{#if isLoading}
							<Loader class="h-4 w-4 animate-spin" /> Sending...
						{:else}
							Continue
						{/if}
					</button>
				</form>

				<div class="mt-5 pt-5 border-t border-gray-200 flex items-center justify-between">
					<a href="/auth/login" class="flex items-center gap-1.5 text-sm text-[#007185] hover:text-[#c7511f] hover:underline">
						<ArrowLeft class="h-4 w-4" /> Back to sign-in
					</a>
					<a href="/auth/register" class="text-sm text-[#007185] hover:text-[#c7511f] hover:underline">
						Create account
					</a>
				</div>
			{/if}
		</div>

	</div>
</div>
