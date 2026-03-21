<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Mail, Lock, AlertCircle } from 'lucide-svelte';

	let email = $state('');
	let password = $state('');
	let loading = $state(false);
	let error = $state('');

	async function handleLogin(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			const { data, error: authError } = await supabase.auth.signInWithPassword({
				email,
				password
			});

			if (authError) throw authError;

			// Redirect to dashboard on success
			goto('/');
		} catch (err: any) {
			error = err.message || 'Failed to login';
		} finally {
			loading = false;
		}
	}
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-primary-100 p-4">
	<div class="max-w-md w-full bg-white rounded-2xl shadow-xl p-8">
		<!-- Logo/Header -->
		<div class="text-center mb-8">
			<h1 class="text-3xl font-bold text-gray-900">Kemani POS</h1>
			<p class="text-gray-600 mt-2">Sign in to your account</p>
		</div>

		<!-- Error Alert -->
		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-6 flex items-center gap-2">
				<AlertCircle class="h-5 w-5 flex-shrink-0" />
				<p class="text-sm">{error}</p>
			</div>
		{/if}

		<!-- Login Form -->
		<form onsubmit={handleLogin} class="space-y-6">
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
						placeholder="you@example.com"
						class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
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
						type="password"
						bind:value={password}
						required
						placeholder="••••••••"
						class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
					/>
				</div>
			</div>

			<!-- Forgot Password Link -->
			<div class="flex items-center justify-between">
				<div class="flex items-center">
					<input
						id="remember"
						type="checkbox"
						class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
					/>
					<label for="remember" class="ml-2 block text-sm text-gray-700">
						Remember me
					</label>
				</div>
				<a href="/auth/forgot-password" class="text-sm font-medium text-primary-600 hover:text-primary-700">
					Forgot password?
				</a>
			</div>

			<!-- Submit Button -->
			<button
				type="submit"
				disabled={loading}
				class="w-full bg-gray-900 hover:bg-black text-white font-medium py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
			>
				{loading ? 'Signing in...' : 'Sign in'}
			</button>
		</form>

		<!-- Sign Up Link -->
		<div class="mt-6 text-center">
			<p class="text-sm text-gray-600">
				Don't have an account?
				<a href="/auth/signup" class="font-medium text-primary-600 hover:text-primary-700">
					Sign up
				</a>
			</p>
		</div>
	</div>
</div>
