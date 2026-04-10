<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Mail, Lock, AlertCircle, Store } from 'lucide-svelte';

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

			if (!data.user) throw new Error('Failed to retrieve user data');

			// Fetch user row to check onboarding status
			const { data: userData } = await supabase
				.from('users')
				.select('onboarding_done')
				.eq('id', data.user.id)
				.maybeSingle();

			// Route appropriately based on onboarding status
			if (userData?.onboarding_done) {
				goto('/');
			} else {
				goto('/onboarding');
			}
			
			// Note: We deliberately do not set loading = false here. 
			// We want the button to stay in the loading state until the navigation completes.
		} catch (err: any) {
			error = err.message || 'Failed to login';
			loading = false;
		}
	}
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 via-white to-blue-100 p-4">
	<div class="max-w-md w-full bg-white rounded-2xl shadow-xl p-6 sm:p-8 border border-gray-100/50">
		<!-- Logo/Header -->
		<div class="text-center mb-6">
			<div class="inline-flex items-center justify-center w-12 h-12 bg-blue-600 rounded-xl mb-3 shadow-lg shadow-blue-100">
				<Store class="h-6 w-6 text-white" />
			</div>
			<h1 class="text-2xl font-bold text-gray-900">Kemani POS</h1>
			<p class="text-gray-500 mt-1 text-sm font-medium">Welcome back! Sign in to continue</p>
		</div>

		<!-- Error Alert -->
		{#if error}
			<div class="bg-red-50 border border-red-100 text-red-600 px-4 py-3 rounded-2xl mb-6 flex items-center gap-3 animate-in shake-in">
				<AlertCircle class="h-5 w-5 flex-shrink-0" />
				<p class="text-sm font-medium">{error}</p>
			</div>
		{/if}

		<!-- Login Form -->
		<form onsubmit={handleLogin} class="space-y-5">
			<!-- Email -->
			<div>
				<label for="email" class="block text-sm font-semibold text-gray-700 mb-1">
					Email Address
				</label>
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
						<Mail class="h-4 w-4 text-gray-400 group-focus-within:text-blue-600 transition-colors" />
					</div>
					<input
						id="email"
						type="email"
						bind:value={email}
						required
						placeholder="name@company.com"
						class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-600 focus:bg-white transition-all outline-none text-sm font-medium"
					/>
				</div>
			</div>

			<!-- Password -->
			<div>
				<div class="flex items-center justify-between mb-1">
					<label for="password" class="block text-sm font-semibold text-gray-700">
						Password
					</label>
					<a href="/auth/forgot-password" class="text-xs font-semibold text-blue-600 hover:text-blue-700">
						Forgot password?
					</a>
				</div>
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
						<Lock class="h-4 w-4 text-gray-400 group-focus-within:text-blue-600 transition-colors" />
					</div>
					<input
						id="password"
						type="password"
						bind:value={password}
						required
						placeholder="••••••••"
						class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-600 focus:bg-white transition-all outline-none text-sm font-medium"
					/>
				</div>
			</div>

			<div class="flex items-center">
				<input
					id="remember"
					type="checkbox"
					class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded-md"
				/>
				<label for="remember" class="ml-2 block text-sm font-medium text-gray-600">
					Keep me signed in
				</label>
			</div>

			<!-- Submit Button -->
			<button
				type="submit"
				disabled={loading}
				class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold flex justify-center py-2.5 px-4 rounded-lg shadow-md shadow-blue-100 transition-all hover:-translate-y-px active:translate-y-px disabled:opacity-50 disabled:cursor-not-allowed mt-2"
			>
				{loading ? 'Signing in...' : 'Sign In'}
			</button>
		</form>

		<!-- Sign Up Link -->
		<div class="mt-8 text-center pt-6 border-t border-gray-100">
			<p class="text-sm text-gray-600">
				New to Kemani?
				<a href="/auth/signup" class="font-bold text-blue-600 hover:text-blue-700 ml-1">
					Create an account
				</a>
			</p>
		</div>
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
