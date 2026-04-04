<script lang="ts">
	import { User, ShieldCheck } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { AuthService } from '$lib/services/auth';
	import { onMount } from 'svelte';

	let authError = '';
	let isLoading = false;

	$: next = $page.url.searchParams.get('next') || `${$page.url.origin}/profile`;

	async function signInWithGoogle() {
		try {
			isLoading = true;
			authError = '';
			
			// Use the centralized AuthService logic
			const { error } = await AuthService.signInWithGoogle({ 
				next,
				centralHost: $page.url.origin 
			});
			
			if (error) {
				authError = error.message;
				isLoading = false;
			}
		} catch (err: any) {
			authError = err.message || 'An unexpected error occurred.';
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Identity Portal | Kemani</title>
</svelte:head>

<div class="min-h-screen bg-[#faf9f6] flex items-center justify-center p-6 selection:bg-gray-100 selection:text-gray-900">
	<div class="w-full max-w-sm bg-white rounded-xl shadow-2xl p-12 space-y-10 animate-in fade-in zoom-in-95 duration-500">
		<!-- Branding -->
		<div class="flex flex-col items-center text-center space-y-4">
			<div class="h-16 w-16 bg-gray-900 rounded-full flex items-center justify-center text-white shadow-xl">
				<ShieldCheck class="h-8 w-8" />
			</div>
			<div class="space-y-1">
				<h1 class="font-display text-3xl tracking-tight text-gray-900">Identity Portal</h1>
				<p class="text-[10px] text-gray-400 uppercase tracking-[0.2em] font-bold">Secure Universal Authentication</p>
			</div>
		</div>

		<!-- Action -->
		<div class="space-y-6">
			<div class="space-y-4">
				<button 
					on:click={signInWithGoogle}
					disabled={isLoading}
					class="w-full py-4 border border-gray-100 rounded-lg flex items-center justify-center gap-3 hover:bg-gray-50 active:scale-[0.98] transition-all text-[11px] font-bold text-gray-700 uppercase tracking-[0.15em] shadow-sm disabled:opacity-50 disabled:cursor-not-allowed group"
				>
					{#if isLoading}
						<div class="h-4 w-4 border-2 border-gray-200 border-t-gray-900 rounded-full animate-spin"></div>
					{:else}
						<img src="https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png" alt="Google" class="h-4 w-4 group-hover:scale-110 transition-transform" />
						Continue with Google
					{/if}
				</button>

				{#if authError}
					<div class="p-4 bg-red-50 rounded-lg border border-red-100 animate-in fade-in slide-in-from-top-2 duration-300">
						<p class="text-[9px] text-red-600 font-bold uppercase tracking-widest leading-relaxed">
							Authentication Error
						</p>
						<p class="text-[8px] text-red-400 mt-1 uppercase tracking-tighter">
							{authError}
						</p>
					</div>
				{/if}
			</div>

			<p class="text-[10px] text-gray-400 text-center leading-relaxed">
				You are logging into the **Kemani Universal Network**. Once authenticated, you will be securely redirected back to your shop.
			</p>
		</div>

		<!-- Footer -->
		<div class="pt-8 border-t border-gray-50 flex justify-center">
			<div class="flex items-center gap-2 text-[9px] text-gray-300 uppercase tracking-widest font-bold">
				<ShieldCheck class="h-3 w-3" />
				<span>Secured by Supabase Identity</span>
			</div>
		</div>
	</div>
</div>

<style>
	:global(.font-display) {
		font-family: 'Playfair Display', serif;
	}
	:global(body) {
		background-color: #faf9f6;
		margin: 0;
	}
</style>
