<script lang="ts">
	import { goto } from '$app/navigation';
	import { Mail, Lock, Eye, EyeOff, AlertCircle } from 'lucide-svelte';
	import { authStore } from '$lib/stores/auth.svelte';

	let email = $state('');
	let password = $state('');
	let showPassword = $state(false);
	let isLoading = $state(false);
	let error = $state('');

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';
		isLoading = true;

		try {
			await authStore.signIn(email, password);
			goto('/');
		} catch (err: any) {
			error = err.message || 'Failed to sign in. Please check your credentials.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Login | Kemani Health</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center px-4">
	<div class="max-w-md w-full">
		<!-- Logo/Header -->
		<div class="text-center mb-8">
			<div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl mb-4">
				<span class="text-2xl font-bold text-white">K</span>
			</div>
			<h1 class="text-3xl font-bold text-gray-900">Welcome Back</h1>
			<p class="text-gray-600 mt-2">Sign in to access your health portal</p>
		</div>

		<!-- Login Form -->
		<div class="bg-white rounded-2xl shadow-xl p-8">
			<form onsubmit={handleSubmit} class="space-y-6">
				<!-- Email -->
				<div>
					<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
						Email Address
					</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Mail class="h-5 w-5 text-gray-400" />
						</div>
						<input
							id="email"
							type="email"
							bind:value={email}
							required
							class="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
							placeholder="you@example.com"
						/>
					</div>
				</div>

				<!-- Password -->
				<div>
					<label for="password" class="block text-sm font-medium text-gray-700 mb-2">
						Password
					</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Lock class="h-5 w-5 text-gray-400" />
						</div>
						<input
							id="password"
							type={showPassword ? 'text' : 'password'}
							bind:value={password}
							required
							class="block w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
							placeholder="Enter your password"
						/>
						<button
							type="button"
							onclick={() => showPassword = !showPassword}
							class="absolute inset-y-0 right-0 pr-3 flex items-center"
						>
							{#if showPassword}
								<EyeOff class="h-5 w-5 text-gray-400" />
							{:else}
								<Eye class="h-5 w-5 text-gray-400" />
							{/if}
						</button>
					</div>
				</div>

				<!-- Error Message -->
				{#if error}
					<div class="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
						<AlertCircle class="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
						<p class="text-sm text-red-700">{error}</p>
					</div>
				{/if}

				<!-- Forgot Password -->
				<div class="flex items-center justify-between">
					<label class="flex items-center">
						<input type="checkbox" class="rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
						<span class="ml-2 text-sm text-gray-600">Remember me</span>
					</label>
					<a href="/auth/reset-password" class="text-sm text-blue-600 hover:underline">
						Forgot password?
					</a>
				</div>

				<!-- Submit Button -->
				<button
					type="submit"
					disabled={isLoading}
					class="w-full py-3 px-4 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
				>
					{#if isLoading}
						<span class="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
						<span>Signing in...</span>
					{:else}
						<span>Sign In</span>
					{/if}
				</button>
			</form>

			<!-- Sign Up Link -->
			<div class="mt-6 text-center">
				<p class="text-sm text-gray-600">
					Don't have an account?
					<a href="/auth/signup" class="text-blue-600 hover:underline font-medium">
						Create account
					</a>
				</p>
			</div>
		</div>

		<!-- Footer -->
		<p class="text-center text-sm text-gray-600 mt-8">
			By signing in, you agree to our
			<a href="/terms" class="text-blue-600 hover:underline">Terms of Service</a>
			and
			<a href="/privacy" class="text-blue-600 hover:underline">Privacy Policy</a>
		</p>
	</div>
</div>
