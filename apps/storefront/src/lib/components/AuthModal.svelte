<script lang="ts">
	import { fade, scale } from 'svelte/transition';
	import { X, Chrome, Loader2, HeartPulse } from 'lucide-svelte';
	import { isAuthModalOpen } from '$lib/stores/ui';
	import { AuthService } from '$lib/services/auth';

	let loading = false;
	let error = '';

	async function handleGoogleLogin() {
		loading = true;
		error = '';
		try {
			// Save the full storefront URL (with subdomain) as fallback
			const returnUrl = window.location.href;
			localStorage.setItem('storefront_return_url', returnUrl);

			// The callback redirectTo MUST use the base (non-subdomain) origin
			// that is whitelisted in Google Cloud Console & Supabase.
			// We determine this by stripping any subdomain from the hostname.
			const hostname = window.location.hostname; // e.g. lanre-pharmacy-yapqx.localhost
			const port = window.location.port;

			// Strip subdomain: for 'sub.localhost' or 'sub.domain.com' get the base
			let baseHost: string;
			const parts = hostname.split('.');
			if (parts.length >= 2 && hostname.endsWith('.localhost')) {
				// sub.localhost → localhost
				baseHost = `localhost${port ? ':' + port : ''}`;
			} else if (parts.length >= 3) {
				// sub.domain.com → domain.com
				baseHost = `${parts.slice(1).join('.')}${port ? ':' + port : ''}`;
			} else {
				baseHost = `${hostname}${port ? ':' + port : ''}`;
			}

			const centralHost = `${window.location.protocol}//${baseHost}`;
			await AuthService.signInWithGoogle({ next: returnUrl, centralHost });
		} catch (err: any) {
			error = err.message || 'Google sign-in failed';
			loading = false;
		}
	}

	function close() {
		isAuthModalOpen.set(false);
		error = '';
	}
</script>

{#if $isAuthModalOpen}
	<!-- Backdrop -->
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div
		class="fixed inset-0 z-[200] flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-md"
		transition:fade={{ duration: 200 }}
		onclick={close}
	>
		<!-- Modal -->
		<div
			class="relative w-full max-w-sm bg-white rounded-3xl shadow-2xl overflow-hidden border border-gray-100"
			transition:scale={{ duration: 300, start: 0.95 }}
			onclick={(e) => e.stopPropagation()}
			onkeydown={(e) => e.stopPropagation()}
			role="dialog"
			aria-modal="true"
			aria-labelledby="auth-modal-title"
			tabindex="-1"
		>
			<!-- Close -->
			<button
				onclick={close}
				class="absolute top-5 right-5 p-2 rounded-full hover:bg-gray-100 transition-colors text-gray-400 hover:text-gray-900"
				aria-label="Close"
			>
				<X class="h-4 w-4" />
			</button>

			<!-- Body -->
			<div class="px-8 pt-10 pb-8 flex flex-col items-center text-center gap-5">
				<!-- Icon -->
				<div class="w-16 h-16 rounded-2xl bg-blue-50 border border-blue-100 flex items-center justify-center">
					<HeartPulse class="h-8 w-8 text-blue-600" />
				</div>

				<div>
					<h2 id="auth-modal-title" class="text-2xl font-black text-gray-900">Sign in to continue</h2>
					<p class="mt-1.5 text-sm text-gray-500">Access RX Chat, orders, and your health history.</p>
				</div>

				{#if error}
					<div class="w-full p-3 text-xs font-bold text-rose-600 bg-rose-50 border border-rose-100 rounded-xl">
						{error}
					</div>
				{/if}

				<!-- Google Button -->
				<button
					onclick={handleGoogleLogin}
					disabled={loading}
					id="google-signin-btn"
					class="w-full flex items-center justify-center gap-3 py-3.5 bg-white border border-gray-200 rounded-2xl hover:bg-gray-50 hover:border-gray-300 transition-all active:scale-[0.98] shadow-sm disabled:opacity-60"
				>
					{#if loading}
						<Loader2 class="h-5 w-5 animate-spin text-gray-500" />
						<span class="text-sm font-bold text-gray-700">Signing in...</span>
					{:else}
						<!-- Google SVG logo -->
						<svg class="h-5 w-5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
							<path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
							<path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
							<path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
							<path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
						</svg>
						<span class="text-sm font-bold text-gray-700">Continue with Google</span>
					{/if}
				</button>

				<p class="text-xs text-gray-400">By continuing, you agree to our <a href="/terms" class="underline hover:text-gray-600">Terms</a> & <a href="/privacy" class="underline hover:text-gray-600">Privacy Policy</a>.</p>
			</div>
		</div>
	</div>
{/if}
