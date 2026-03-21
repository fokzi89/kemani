<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Moon, Mail, Lock, Eye, EyeOff } from 'lucide-svelte';

	let email = $state('');
	let password = $state('');
	let loading = $state(false);
	let error = $state('');
	let showPassword = $state(false);

	async function handleLogin(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		const { data, error: authError } = await supabase.auth.signInWithPassword({
			email,
			password
		});

		if (authError) {
			error = authError.message;
			loading = false;
		} else if (data.user) {
			// Check if user has a provider profile
			const { data: providerData } = await supabase
				.from('healthcare_providers')
				.select('*')
				.eq('user_id', data.user.id)
				.single();

			if (!providerData) {
				error = 'No healthcare provider profile found. Please contact support.';
				await supabase.auth.signOut();
				loading = false;
			} else {
				goto('/');
			}
		}
	}
</script>

<div class="min-h-screen w-full flex font-sans">
	<!-- Left Side: Form Content -->
	<div class="w-full lg:w-[45%] bg-gray-50 flex flex-col items-center justify-center p-8 relative">
		<!-- Top Action Bar -->
		<div class="absolute top-8 left-8 right-8 flex justify-between items-center max-w-xl mx-auto w-[calc(100%-4rem)]">
			<a href="/" class="flex items-center text-[#111827] font-semibold text-sm hover:underline hover:text-[#000000] transition-colors">
				<ArrowLeft size={16} class="mr-2" strokeWidth={2.5} />
				Back to Home
			</a>
			<button class="text-[#111827] p-2 hover:bg-gray-200 rounded-full transition-colors">
				<Moon size={22} fill="currentColor" />
			</button>
		</div>

		<div class="w-full max-w-[400px] mt-12">
			<h1 class="text-4xl font-bold text-[#113022] mb-3 font-sans tracking-tight">Welcome Back 👋</h1>
			<p class="text-[15px] text-[#4a6357] leading-relaxed mb-8 pr-4">
				Log in to your Kemani Health account to manage consultations, prescriptions, and connect with patients.
			</p>

			{#if error}
				<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm mb-6">
					{error}
				</div>
			{/if}

			<form onsubmit={handleLogin} class="space-y-4">
				<!-- Email -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#111827] transition-colors">
						<Mail size={18} />
					</div>
					<input
						type="email"
						bind:value={email}
						required
						placeholder="Email"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#d1d5db] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#111827] focus:border-[#111827] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Password -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#111827] transition-colors">
						<Lock size={18} />
					</div>
					<input
						type={showPassword ? "text" : "password"}
						bind:value={password}
						required
						placeholder="Password"
						class="w-full pl-10 pr-12 py-3.5 bg-white border border-[#d1d5db] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#111827] focus:border-[#111827] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
					<button
						type="button"
						class="absolute inset-y-0 right-0 pr-3.5 flex items-center text-gray-400 hover:text-gray-600 transition-colors"
						onclick={() => showPassword = !showPassword}
					>
						{#if showPassword}
							<EyeOff size={18} />
						{:else}
							<Eye size={18} />
						{/if}
					</button>
				</div>

				<!-- Login Button -->
				<button
					type="submit"
					disabled={loading}
					class="w-full mt-2 bg-[#111827] hover:bg-[#000000] font-semibold text-white py-3.5 px-4 rounded-xl transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#111827] shadow-sm disabled:opacity-70 disabled:cursor-not-allowed text-[15px]"
				>
					{loading ? 'Signing in...' : 'Log in'}
				</button>
			</form>

			<p class="mt-8 text-center text-sm text-[14px] text-gray-500">
				Don't have an account?
				<a href="/auth/signup" class="font-bold text-[#111827] hover:text-[#000000] transition-colors ml-1">Sign up</a>
			</p>
		</div>
	</div>

	<!-- Right Side: Promotional/Brand Content -->
	<div class="hidden lg:flex w-[55%] bg-[#111827] flex-col justify-center px-16 xl:px-24 relative overflow-hidden">
		<!-- Brand Logo/Name -->
		<div class="absolute top-12 left-16 xl:left-24">
			<span class="text-white text-[32px] font-bold tracking-tight">Kemani Health</span>
		</div>

		<!-- Testimonial Content -->
		<div class="text-white z-10 max-w-2xl mt-12">
			<!-- Quote Icon -->
			<svg class="w-10 h-10 mb-8 text-[#6b7280]" fill="currentColor" viewBox="0 0 24 24">
				<path d="M14.017 21v-7.391c0-5.704 3.731-9.57 8.983-10.609l.995 2.151c-2.432.917-3.995 3.638-3.995 5.849h4v10h-9.983zm-14.017 0v-7.391c0-5.704 3.748-9.57 9-10.609l.996 2.151c-2.433.917-3.996 3.638-3.996 5.849h3.983v10h-9.983z"/>
			</svg>

			<p class="text-[20px] font-semibold leading-[1.6] mb-8 text-white">
				Since joining Kemani Health, my practice has flourished. The platform streamlines patient management and allows me to provide quality care remotely. It's been a game-changer for both me and my patients across Nigeria.
			</p>

			<div class="mt-8">
				<h4 class="font-bold text-lg mb-1">Dr. Fatima Ibrahim</h4>
				<p class="text-white/80 text-[14px]">Pediatrician • Abuja, Nigeria</p>
			</div>
		</div>
	</div>
</div>
